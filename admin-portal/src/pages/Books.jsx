import { useState, useEffect } from 'react';
import { Plus, Search, Camera, Image, X, Edit, Info, Tag, CheckCircle, BookOpen, User, Layers, MapPin } from 'lucide-react';
import QrReader from 'react-qr-barcode-scanner';
import api from '../services/api';
import './Books.css';

const ENGINEERING_TAGS = [
    // Computer Science & IT
    "Programming", "Coding", "SoftwareEngineering", "WebDevelopment", "Frontend", "Backend", "FullStack", "DataStructures", "Algorithms", "Python", "Java", "Cplusplus", "JavaScript", "MachineLearning", "DeepLearning", "ArtificialIntelligence", "DataScience", "CloudComputing", "DevOps", "CyberSecurity", "Blockchain", "IoT", "Database", "SQL", "NoSQL",

    // Mechanical Engineering
    "MechanicalEngineering", "Thermodynamics", "FluidMechanics", "HeatTransfer", "CAD", "CAM", "CAE", "SolidWorks", "AutoCAD", "Manufacturing", "CNC", "Robotics", "Mechatronics", "IndustrialEngineering", "MaterialsScience", "Dynamics", "Kinematics", "AutomobileEngineering",

    // Civil Engineering
    "CivilEngineering", "StructuralEngineering", "Construction", "Surveying", "GeotechnicalEngineering", "TransportationEngineering", "EnvironmentalEngineering", "AutoCADCivil", "ETABS", "STAADPro", "BuildingDesign", "ConcreteTechnology", "SmartCities", "UrbanPlanning",

    // Electrical Engineering
    "ElectricalEngineering", "PowerSystems", "ElectricalMachines", "ControlSystems", "RenewableEnergy", "SmartGrid", "PowerElectronics", "HighVoltageEngineering", "PLC", "SCADA", "EnergyManagement", "SolarEnergy", "WindEnergy",

    // Electronics & Communication
    "ElectronicsEngineering", "CommunicationSystems", "EmbeddedSystems", "VLSI", "Microcontrollers", "Microprocessors", "DigitalElectronics", "AnalogElectronics", "SignalProcessing", "DSP", "FPGA", "IoT", "WirelessCommunication", "5G", "AntennaDesign",

    // Others & General Tech
    "ArtificialIntelligence", "Automation", "Innovation", "Research", "TechSkills", "EngineeringLife", "STEM", "FutureTechnology", "SmartSystems", "Industry40", "ProblemSolving", "TechEnthusiast"
].sort((a, b) => a.localeCompare(b));



const Books = () => {
    const [books, setBooks] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [showScanner, setShowScanner] = useState(false);
    const [activeCopyIndex, setActiveCopyIndex] = useState(null);
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedBookId, setSelectedBookId] = useState(null);
    const [scannerError, setScannerError] = useState(null);

    const [modalMode, setModalMode] = useState('add'); // 'add', 'view', 'edit'
    const [selectedBook, setSelectedBook] = useState(null);

    const [formData, setFormData] = useState({
        title: '',
        author: '',
        department: '',
        tags: '',
        total_copies: 1,
        copies: [{ barcode: '', rfid: '' }],
        location: { section: '', row: 0, column: 0 }
    });

    const [selectedImage, setSelectedImage] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);
    const [tagSearch, setTagSearch] = useState('');
    const [showTagSuggestions, setShowTagSuggestions] = useState(false);

    const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5001';

    useEffect(() => {
        fetchBooks();
    }, []);

    const fetchBooks = async () => {
        try {
            const response = await api.get('/admin/books');
            if (response.data.success) {
                setBooks(response.data.books);
            }
        } catch (error) {
            console.error('Error fetching books:', error);
        } finally {
            setLoading(false);
        }
    };

    // This function is no longer used as barcode scanning is now tied to individual copies.
    // const handleBarcodeScanned = (err, result) => {
    //     if (err) {
    //         if (err.name !== 'NotFoundException' && err.name !== 'ChecksumException' && err.name !== 'FormatException') {
    //             setScannerError(err.message || 'Error accessing camera');
    //         }
    //         return;
    //     }
    //     if (result) {
    //         setFormData(prev => ({ ...prev, barcode: result.text }));
    //         setShowScanner(false);
    //         setScannerError(null);
    //     }
    // };

    const handleBookClick = (book) => {
        setSelectedBook(book);
        setSelectedBookId(book.id);
        const tagsString = Array.isArray(book.tags) ? book.tags.join(', ') : (book.tags || '');

        // Populate copies from book data
        const bookCopies = book.copies || [];

        setFormData({
            title: book.title || '',
            author: book.author || '',
            department: book.department || book.category || '',
            tags: tagsString,
            total_copies: book.total_copies || bookCopies.length || 1,
            copies: bookCopies.length > 0 ? bookCopies.map(c => ({
                barcode: c.barcode || '',
                rfid: c.rfid || ''
            })) : [{ barcode: '', rfid: '' }], // Removed book.barcode from here
            location: book.location || { section: '', row: 0, column: 0 }
        });
        setImagePreview(book.image_path ? `${API_BASE_URL}/${book.image_path}` : null);
        setModalMode('view');
        setShowModal(true);
    };

    const handleAddClick = () => {
        setModalMode('add');
        setSelectedBookId(null);
        setSelectedBook(null);
        resetForm();
        setShowModal(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        const bookData = {
            ...formData,
            tags: typeof formData.tags === 'string' ? formData.tags.split(',').map(tag => tag.trim()).filter(tag => tag) : formData.tags,
            target_department: typeof formData.target_department === 'string' ? formData.target_department.split(',').map(d => d.trim()).filter(d => d) : formData.target_department
        };

        try {
            let response;
            if (selectedBookId) {
                response = await api.put(`/admin/books/update/${selectedBookId}`, bookData);
            } else {
                response = await api.post('/admin/books/add', bookData);
            }

            if (response.data.success) {
                const bookId = selectedBookId || response.data.book_id;

                if (selectedImage) {
                    const imageFormData = new FormData();
                    imageFormData.append('image', selectedImage);
                    await api.post(`/admin/books/upload_image/${bookId}`, imageFormData, {
                        headers: { 'Content-Type': 'multipart/form-data' }
                    });
                }

                // If in Edit mode, we might need a separate endpoint for updating copies 
                // but for now, we'll assume the /update endpoint handles metadata.
                // If the user wants to update copies of an existing book, 
                // we'll need a different approach (e.g. adding single copies).
                // For this implementation, we'll focus on the 'Add' flow.

                setShowModal(false);
                fetchBooks();
                resetForm();
            }
        } catch (error) {
            console.error('Error saving book:', error);
            alert(error.response?.data?.error || 'Failed to save book');
        }
    };

    const resetForm = () => {
        setFormData({
            title: '',
            author: '',
            department: '',
            tags: '',
            total_copies: 1,
            copies: [{ barcode: '', rfid: '' }],
            location: { section: '', row: 0, column: 0 }
        });
        setSelectedImage(null);
        setImagePreview(null);
        setSelectedBookId(null);
        setSelectedBook(null);
        setScannerError(null);
        setShowScanner(false);
        setTagSearch('');
        setActiveCopyIndex(null);
    };

    const handleCopiesChange = (index, field, value) => {
        if (value && value.trim() !== "") {
            const isDuplicate = formData.copies.some((copy, i) => i !== index && copy[field] === value.trim());
            if (isDuplicate) {
                alert(`This ${field} is already entered for another copy!`);
                return;
            }
        }
        const newCopies = [...formData.copies];
        newCopies[index] = { ...newCopies[index], [field]: value };
        setFormData({ ...formData, copies: newCopies });
    };

    const handleTotalCopiesChange = (val) => {
        const newTotal = parseInt(val) || 1;
        const newCopies = [...formData.copies];

        if (newTotal > newCopies.length) {
            // Add new empty copies
            for (let i = newCopies.length; i < newTotal; i++) {
                newCopies.push({ barcode: '', rfid: '' });
            }
        } else if (newTotal < newCopies.length) {
            // Remove copies
            newCopies.splice(newTotal);
        }

        setFormData({ ...formData, total_copies: newTotal, copies: newCopies });
    };

    const filteredBooks = books.filter(book =>
        book.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        book.author.toLowerCase().includes(searchTerm.toLowerCase()) ||
        book.barcode.includes(searchTerm)
    );

    const addTag = (tagInput) => {
        if (!tagInput) return;

        const currentTags = formData.tags ? formData.tags.split(',').map(t => t.trim()) : [];
        const newTagsToAdd = tagInput.split(',')
            .map(t => t.trim())
            .filter(t => t && !currentTags.includes(t));

        if (newTagsToAdd.length > 0) {
            const newTags = [...currentTags, ...newTagsToAdd].join(', ');
            setFormData({ ...formData, tags: newTags });
        }
        setTagSearch('');
        setShowTagSuggestions(false);
    };

    const handleTagInputKeyDown = (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            addTag(tagSearch);
        }
    };

    const removeTag = (tag) => {
        const currentTags = formData.tags.split(',').map(t => t.trim());
        const newTags = currentTags.filter(t => t !== tag).join(', ');
        setFormData({ ...formData, tags: newTags });
    };

    const filteredSuggestions = ENGINEERING_TAGS.filter(tag =>
        tag.toLowerCase().includes(tagSearch.toLowerCase()) &&
        !(formData.tags ? formData.tags.split(',').map(t => t.trim()).includes(tag) : false)
    ).slice(0, 10);

    return (
        <div className="books-page">
            <div className="books-header">
                <div>
                    <h1>Books Management</h1>
                    <p className="text-muted">Manage your library collection</p>
                </div>
                <button className="btn btn-primary" onClick={handleAddClick}>
                    <Plus size={18} />
                    Add Book
                </button>
            </div>

            <div className="books-search card">
                <Search size={20} />
                <input
                    type="text"
                    className="input"
                    placeholder="Search by title, author, or barcode..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                />
            </div>

            {loading ? (
                <div className="books-loading">
                    <div className="spinner"></div>
                    <p>Loading books...</p>
                </div>
            ) : (
                <div className="books-grid">
                    {filteredBooks.map((book) => (
                        <div key={book.id} className="book-card">
                            <div className="book-card-image" onClick={() => handleBookClick(book)}>
                                {book.image_path ? (
                                    <img
                                        src={`${API_BASE_URL}/${book.image_path}?t=${new Date().getTime()}`}
                                        alt={book.title}
                                        onError={(e) => {
                                            e.target.onerror = null;
                                            e.target.style.display = 'none';
                                            e.target.parentNode.innerHTML = '<div class="image-placeholder"><div class="lucide-icon text-muted"><svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-image"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg></div></div>';
                                        }}
                                    />
                                ) : (
                                    <div className="image-placeholder">
                                        <Image size={48} className="text-muted" />
                                    </div>
                                )}
                            </div>
                            <div className="book-card-content">
                                <h3 className="book-card-title">{book.title}</h3>
                                <p className="book-card-author">by {book.author}</p>
                                <div className="book-card-stats">
                                    <span className={`availability-badge ${book.available_copies > 0 ? 'available' : 'out-of-stock'}`}>
                                        {book.available_copies} / {book.total_copies} Available
                                    </span>
                                    <span className="barcode-badge" title="Click image for details" onClick={() => handleBookClick(book)}>
                                        <Info size={14} /> Details
                                    </span>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Book Modal (Add/View/Edit) */}
            {showModal && (
                <div className="modal-overlay" onClick={() => setShowModal(false)}>
                    <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header-actions">
                            <h2>
                                {modalMode === 'add' && 'Add New Book'}
                                {modalMode === 'view' && 'Book Details'}
                                {modalMode === 'edit' && 'Edit Book'}
                            </h2>
                            <div className="header-buttons">
                                {modalMode === 'view' && (
                                    <button className="btn btn-primary btn-sm" onClick={() => setModalMode('edit')}>
                                        <Edit size={16} /> Edit
                                    </button>
                                )}
                                <button className="modal-close-btn" onClick={() => setShowModal(false)}>
                                    <X size={20} />
                                </button>
                            </div>
                        </div>

                        {modalMode === 'view' ? (
                            <div className="book-details-view">
                                <div className="details-layout">
                                    <div className="details-image-section">
                                        {selectedBook?.image_path ? (
                                            <img src={`${API_BASE_URL}/${selectedBook.image_path}`} alt={selectedBook.title} className="details-main-image" />
                                        ) : (
                                            <div className="image-placeholder details-main-image">
                                                <Image size={64} className="text-muted" />
                                            </div>
                                        )}
                                    </div>
                                    <div className="details-content-section">
                                        <div className="details-header-info">
                                            <div className="details-title-row">
                                                <BookOpen size={24} className="text-primary" />
                                                <h1>{selectedBook?.title}</h1>
                                            </div>
                                            <div className="details-author-row">
                                                <User size={18} className="text-muted" />
                                                <span>by {selectedBook?.author || 'Unknown Author'}</span>
                                            </div>
                                        </div>

                                        <div className="details-grid">
                                            <div className="detail-card">
                                                <div className="detail-card-label">
                                                    <Layers size={14} /> Department
                                                </div>
                                                <div className="detail-card-value">
                                                    {selectedBook?.department || selectedBook?.category || 'General'}
                                                </div>
                                            </div>
                                            <div className="detail-card">
                                                <div className="detail-card-label">
                                                    <MapPin size={14} /> Shelf Location
                                                </div>
                                                <div className="detail-card-value">
                                                    {selectedBook?.location?.section || 'N/A'} - R{selectedBook?.location?.row} C{selectedBook?.location?.column}
                                                </div>
                                            </div>
                                        </div>

                                        <div className="detail-section">
                                            <div className="detail-section-label">
                                                <Tag size={14} /> Engineering Tags
                                            </div>
                                            <div className="details-tags-cloud">
                                                {selectedBook?.tags && selectedBook.tags.length > 0 ? (
                                                    selectedBook.tags.map((tag, i) => (
                                                        <span key={i} className="tag-badge">{tag}</span>
                                                    ))
                                                ) : (
                                                    <span className="text-muted" style={{ fontSize: '0.9rem' }}>No tags assigned</span>
                                                )}
                                            </div>
                                        </div>

                                        <div className="detail-section physical-copies-section">
                                            <div className="detail-section-label">
                                                Physical Copies ({selectedBook?.total_copies})
                                            </div>
                                            <div className="copies-table-container">
                                                <table className="copies-table">
                                                    <thead>
                                                        <tr>
                                                            <th>Barcode</th>
                                                            <th>RFID</th>
                                                            <th>Status</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        {(selectedBook?.copies || []).map((copy, idx) => (
                                                            <tr key={idx}>
                                                                <td><code>{copy.barcode}</code></td>
                                                                <td><code>{copy.rfid}</code></td>
                                                                <td>
                                                                    <span className={`status-pill ${copy.issued_to ? 'rented' : 'available'}`}>
                                                                        {copy.issued_to ? 'Rented' : 'Available'}
                                                                    </span>
                                                                </td>
                                                            </tr>
                                                        ))}
                                                        {(!selectedBook?.copies || selectedBook.copies.length === 0) && (
                                                            <tr>
                                                                <td colSpan="3" style={{ textAlign: 'center' }}>No copies found</td>
                                                            </tr>
                                                        )}
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                            </div>
                        ) : (
                            <form onSubmit={handleSubmit} className="book-form">

                                <div className="form-group">
                                    <label>Title</label>
                                    <input
                                        type="text"
                                        className="input"
                                        value={formData.title}
                                        onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                        required
                                    />
                                </div>

                                <div className="form-group tag-input-container">
                                    <label>Engineering Tags</label>
                                    <div className="selected-tags">
                                        {formData.tags ? formData.tags.split(',').map(t => t.trim()).filter(t => t).map((tag, i) => (
                                            <span key={i} className="tag-chip">
                                                {tag}
                                                <X size={14} onClick={() => removeTag(tag)} />
                                            </span>
                                        )) : <span className="text-muted" style={{ fontSize: '0.875rem' }}>No tags selected</span>}
                                    </div>
                                    <div className="tag-suggestion-wrapper">
                                        <div className="input-with-icon">
                                            <Tag size={16} className="input-icon" />
                                            <input
                                                type="text"
                                                className="input"
                                                placeholder="Search or add custom tags..."
                                                value={tagSearch}
                                                onChange={(e) => {
                                                    setTagSearch(e.target.value);
                                                    setShowTagSuggestions(true);
                                                }}
                                                onKeyDown={handleTagInputKeyDown}
                                                onFocus={() => setShowTagSuggestions(true)}
                                            />
                                        </div>
                                        {showTagSuggestions && tagSearch && (
                                            <div className="tag-suggestions card">
                                                {filteredSuggestions.length > 0 ? (
                                                    filteredSuggestions.map((tag, i) => (
                                                        <div
                                                            key={i}
                                                            className="suggestion-item"
                                                            onClick={() => addTag(tag)}
                                                        >
                                                            {tag}
                                                        </div>
                                                    ))
                                                ) : (
                                                    <div className="suggestion-item no-match" onClick={() => addTag(tagSearch)}>
                                                        Add "{tagSearch}" as custom tag
                                                    </div>
                                                )}
                                            </div>
                                        )}
                                    </div>
                                </div>

                                <div className="form-row">
                                    <div className="form-group">
                                        <label>Author</label>
                                        <input
                                            type="text"
                                            className="input"
                                            value={formData.author}
                                            onChange={(e) => setFormData({ ...formData, author: e.target.value })}
                                        />
                                    </div>

                                    <div className="form-group">
                                        <label>Department</label>
                                        <input
                                            type="text"
                                            className="input"
                                            value={formData.department}
                                            onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                                        />
                                    </div>
                                </div>



                                <div className="form-row">
                                    <div className="form-group">
                                        <label>Location Section</label>
                                        <input
                                            type="text"
                                            className="input"
                                            value={formData.location.section}
                                            onChange={(e) => setFormData({ ...formData, location: { ...formData.location, section: e.target.value } })}
                                            placeholder="e.g. A, B, C"
                                        />
                                    </div>
                                    <div className="form-group">
                                        <label>Location Row</label>
                                        <input
                                            type="number"
                                            className="input"
                                            value={formData.location.row}
                                            onChange={(e) => setFormData({ ...formData, location: { ...formData.location, row: parseInt(e.target.value) || 0 } })}
                                            min="0"
                                        />
                                    </div>
                                    <div className="form-group">
                                        <label>Location Column</label>
                                        <input
                                            type="number"
                                            className="input"
                                            value={formData.location.column}
                                            onChange={(e) => setFormData({ ...formData, location: { ...formData.location, column: parseInt(e.target.value) || 0 } })}
                                            min="0"
                                        />
                                    </div>
                                </div>

                                <div className="form-group">
                                    <label>Total Physical Copies</label>
                                    <input
                                        type="number"
                                        className="input"
                                        value={formData.total_copies}
                                        onChange={(e) => handleTotalCopiesChange(e.target.value)}
                                        min="1"
                                        required
                                    />
                                </div>

                                <div className="copies-entry-container">
                                    <label>Manage Copies (Barcode & RFID)</label>
                                    <div className="copies-scroll-area">
                                        {formData.copies.map((copy, index) => (
                                            <div key={index}>
                                                <div className="copy-input-row">
                                                    <div className="form-group flex-1">
                                                        <div className="input-with-button">
                                                            <input
                                                                type="text"
                                                                className="input"
                                                                placeholder={`Barcode ${index + 1}`}
                                                                value={copy.barcode}
                                                                onChange={(e) => handleCopiesChange(index, 'barcode', e.target.value)}
                                                                required
                                                            />
                                                            <button
                                                                type="button"
                                                                className="btn btn-secondary btn-icon-only"
                                                                onClick={() => {
                                                                    setActiveCopyIndex(index);
                                                                    setShowScanner(true);
                                                                }}
                                                            >
                                                                <Camera size={14} />
                                                            </button>
                                                        </div>
                                                    </div>
                                                    <div className="form-group flex-1">
                                                        <input
                                                            type="text"
                                                            className="input"
                                                            placeholder={`RFID ${index + 1}`}
                                                            value={copy.rfid}
                                                            onChange={(e) => handleCopiesChange(index, 'rfid', e.target.value)}
                                                            required
                                                        />
                                                    </div>
                                                </div>

                                                {showScanner && activeCopyIndex === index && (
                                                    <div className="inline-scanner-container">
                                                        <div className="scanner-header">
                                                            <span>Scanning Copy {index + 1}</span>
                                                            <button
                                                                type="button"
                                                                className="btn-close-scanner"
                                                                onClick={() => setShowScanner(false)}
                                                            >
                                                                <X size={16} />
                                                            </button>
                                                        </div>
                                                        <div className="book-scanner-container">
                                                            {scannerError && (
                                                                <div className="alert alert-danger scanner-alert">
                                                                    {scannerError}
                                                                </div>
                                                            )}
                                                            <div className="scanner-guide">
                                                                <div className="scanner-guide-corner top-left"></div>
                                                                <div className="scanner-guide-corner top-right"></div>
                                                                <div className="scanner-guide-corner bottom-left"></div>
                                                                <div className="scanner-guide-corner bottom-right"></div>
                                                                <div className="scanner-guide-line"></div>
                                                            </div>
                                                            <QrReader
                                                                onUpdate={(err, res) => {
                                                                    if (res) {
                                                                        handleCopiesChange(index, 'barcode', res.text);
                                                                        setShowScanner(false);
                                                                        setActiveCopyIndex(null);
                                                                    }
                                                                    if (err && err.name !== 'NotFoundException') setScannerError(err.message);
                                                                }}
                                                                constraints={{ facingMode: 'environment', width: 640, height: 480 }}
                                                                containerStyle={{ width: '100%', height: '100%' }}
                                                                videoStyle={{ width: '100%', height: '100%', objectFit: 'contain' }}
                                                            />
                                                        </div>
                                                    </div>
                                                )}
                                            </div>
                                        ))}
                                    </div>
                                </div>

                                <div className="form-group">
                                    <label>Book Image</label>
                                    <div className="current-image-preview-container">
                                        {imagePreview && (
                                            <img src={imagePreview} alt="Preview" className="current-image-preview" />
                                        )}
                                        <input
                                            type="file"
                                            className="input"
                                            accept="image/*"
                                            onChange={(e) => {
                                                const file = e.target.files[0];
                                                if (file) {
                                                    setSelectedImage(file);
                                                    setImagePreview(URL.createObjectURL(file));
                                                }
                                            }}
                                        />
                                    </div>
                                </div>

                                <div className="modal-actions">
                                    <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>
                                        <X size={18} /> Cancel
                                    </button>
                                    <button type="submit" className="btn btn-primary">
                                        <CheckCircle size={18} />
                                        {modalMode === 'edit' ? 'Update Book' : 'Add Book'}
                                    </button>
                                </div>
                            </form>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
};

export default Books;

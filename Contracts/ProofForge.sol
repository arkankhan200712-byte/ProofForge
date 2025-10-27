// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ProofForge
 * @dev A decentralized document verification and timestamp system
 * @notice This contract allows users to create immutable proofs of document existence
 */
contract ProofForge {
    
    struct Proof {
        bytes32 documentHash;
        address creator;
        uint256 timestamp;
        string description;
        bool exists;
    }
    
    // Mapping from document hash to Proof
    mapping(bytes32 => Proof) private proofs;
    
    // Mapping from creator address to their document hashes
    mapping(address => bytes32[]) private creatorDocuments;
    
    // Events
    event ProofCreated(
        bytes32 indexed documentHash,
        address indexed creator,
        uint256 timestamp,
        string description
    );
    
    event ProofVerified(
        bytes32 indexed documentHash,
        address indexed verifier,
        bool isValid
    );
    
    /**
     * @dev Creates a proof of document existence
     * @param _documentHash The hash of the document to be registered
     * @param _description A brief description of the document
     * @notice The document hash must be unique and not previously registered
     */
    function createProof(bytes32 _documentHash, string memory _description) public {
        require(_documentHash != bytes32(0), "Invalid document hash");
        require(!proofs[_documentHash].exists, "Proof already exists");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        Proof memory newProof = Proof({
            documentHash: _documentHash,
            creator: msg.sender,
            timestamp: block.timestamp,
            description: _description,
            exists: true
        });
        
        proofs[_documentHash] = newProof;
        creatorDocuments[msg.sender].push(_documentHash);
        
        emit ProofCreated(_documentHash, msg.sender, block.timestamp, _description);
    }
    
    /**
     * @dev Verifies if a document proof exists and returns its details
     * @param _documentHash The hash of the document to verify
     * @return exists Whether the proof exists
     * @return creator Address of the proof creator
     * @return timestamp When the proof was created
     * @return description Description of the document
     */
    function verifyProof(bytes32 _documentHash) 
        public 
        returns (bool exists, address creator, uint256 timestamp, string memory description) 
    {
        Proof memory proof = proofs[_documentHash];
        
        emit ProofVerified(_documentHash, msg.sender, proof.exists);
        
        return (
            proof.exists,
            proof.creator,
            proof.timestamp,
            proof.description
        );
    }
    
    /**
     * @dev Retrieves all document hashes created by a specific address
     * @param _creator The address of the creator
     * @return An array of document hashes created by the address
     */
    function getCreatorDocuments(address _creator) public view returns (bytes32[] memory) {
        return creatorDocuments[_creator];
    }
    
    /**
     * @dev Returns the total number of proofs created by an address
     * @param _creator The address to check
     * @return The number of proofs created
     */
    function getProofCount(address _creator) public view returns (uint256) {
        return creatorDocuments[_creator].length;
    }
}

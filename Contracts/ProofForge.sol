// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ProofForge
 * @notice A decentralized platform for generating, storing, and validating tamper-proof
 *         digital proofs of authenticity and origin for any data or document.
 */
contract Project {
    address public admin;
    uint256 public proofCount;

    struct Proof {
        uint256 id;
        address creator;
        string dataHash;
        string description;
        uint256 timestamp;
        bool verified;
    }

    mapping(uint256 => Proof) public proofs;

    event ProofCreated(uint256 indexed id, address indexed creator, string dataHash, string description);
    event ProofVerified(uint256 indexed id, address indexed verifier);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin allowed");
        _;
    }

    modifier onlyCreator(uint256 _id) {
        require(proofs[_id].creator == msg.sender, "Not proof creator");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /**
     * @notice Create a new digital proof with a hash and description
     * @param _dataHash Unique hash representing the data/document
     * @param _description Brief description of the proof
     */
    function createProof(string memory _dataHash, string memory _description) external {
        require(bytes(_dataHash).length > 0, "Data hash required");
        require(bytes(_description).length > 0, "Description required");

        proofCount++;
        proofs[proofCount] = Proof(proofCount, msg.sender, _dataHash, _description, block.timestamp, false);

        emit ProofCreated(proofCount, msg.sender, _dataHash, _description);
    }

    /**
     * @notice Verify a proof (admin only)
     * @param _id Proof ID to be verified
     */
    function verifyProof(uint256 _id) external onlyAdmin {
        require(_id > 0 && _id <= proofCount, "Invalid proof ID");
        require(!proofs[_id].verified, "Proof already verified");

        proofs[_id].verified = true;

        emit ProofVerified(_id, msg.sender);
    }

    /**
     * @notice Change the contract administrator
     * @param _newAdmin Address of the new admin
     */
    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address");

        address oldAdmin = admin;
        admin = _newAdmin;

        emit AdminChanged(oldAdmin, _newAdmin);
    }

    /**
     * @notice View details of a specific proof
     * @param _id Proof ID
     * @return Proof struct
     */
    function getProof(uint256 _id) external view returns (Proof memory) {
        require(_id > 0 && _id <= proofCount, "Invalid proof ID");
        return proofs[_id];
    }
}
// 
End
// 

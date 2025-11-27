// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ProofForge
 * @notice A decentralized registry for creating, linking, verifying, and rejecting digital proofs.
 * @dev Can be extended to include role-based access, token rewards, and off-chain metadata.
 */
contract ProofForge {

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                               */
    /* -------------------------------------------------------------------------- */

    address public admin;
    uint256 public proofCount;

    struct Proof {
        uint256 id;
        address creator;
        string proofHash;
        string metadataURI;
        uint256 timestamp;
        bool verified;
        bool rejected;
        uint256 reputation;
        uint256[] linkedProofs;
    }

    mapping(uint256 => Proof) public proofs;
    mapping(address => uint256[]) public userProofs;
    mapping(address => uint256) public userReputation;


    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */

    error NotAdmin();
    error NotCreatorOrAdmin();
    error ProofNotFound();
    error AlreadyVerified();
    error AlreadyRejected();
    error InvalidProof();
    error CannotLinkSelf();


    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event ProofCreated(uint256 indexed id, address indexed creator, string proofHash, string metadataURI);
    event ProofLinked(uint256 indexed id1, uint256 indexed id2);
    event ProofVerified(uint256 indexed id, uint256 reputationAwarded);
    event ProofRejected(uint256 indexed id, string reason);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);


    /* -------------------------------------------------------------------------- */
    /*                                   MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    modifier proofExists(uint256 id) {
        if (id == 0 || id > proofCount) revert ProofNotFound();
        _;
    }

    modifier onlyCreatorOrAdmin(uint256 id) {
        if (msg.sender != proofs[id].creator && msg.sender != admin) revert NotCreatorOrAdmin();
        _;
    }


    /* -------------------------------------------------------------------------- */
    /*                                CONSTRUCTOR                                 */
    /* -------------------------------------------------------------------------- */

    constructor() {
        admin = msg.sender;
    }


    /* -------------------------------------------------------------------------- */
    /*                                PROOF LOGIC                                 */
    /* -------------------------------------------------------------------------- */

    function createProof(string calldata proofHash, string calldata metadataURI)
        external
        returns (uint256)
    {
        if (bytes(proofHash).length == 0) revert InvalidProof();

        proofCount++;
        Proof storage p = proofs[proofCount];

        p.id = proofCount;
        p.creator = msg.sender;
        p.proofHash = proofHash;
        p.metadataURI = metadataURI;
        p.timestamp = block.timestamp;

        userProofs[msg.sender].push(proofCount);

        emit ProofCreated(proofCount, msg.sender, proofHash, metadataURI);
        return proofCount;
    }


    /* ----------------------------- Linking Proofs ----------------------------- */

    function linkProofs(uint256 id1, uint256 id2)
        external
        proofExists(id1)
        proofExists(id2)
        onlyCreatorOrAdmin(id1)
    {
        if (id1 == id2) revert CannotLinkSelf();

        proofs[id1].linkedProofs.push(id2);
        proofs[id2].linkedProofs.push(id1);

        emit ProofLinked(id1, id2);
    }

    /* Optional unlink function */
    function unlinkProofs(uint256 id1, uint256 id2)
        external
        proofExists(id1)
        proofExists(id2)
        onlyCreatorOrAdmin(id1)
    {
        _removeLink(id1, id2);
        _removeLink(id2, id1);
    }

    function _removeLink(uint256 id1, uint256 id2) private {
        uint256[] storage arr = proofs[id1].linkedProofs;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == id2) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                return;
            }
        }
    }


    /* ------------------------------- Verification ------------------------------ */

    function verifyProof(uint256 id, uint256 reputationPoints)
        external
        onlyAdmin
        proofExists(id)
    {
        Proof storage p = proofs[id];
        if (p.verified) revert AlreadyVerified();
        if (p.rejected) revert AlreadyRejected();

        p.verified = true;
        p.reputation = reputationPoints;
        userReputation[p.creator] += reputationPoints;

        emit ProofVerified(id, reputationPoints);
    }

    function rejectProof(uint256 id, string calldata reason)
        external
        onlyAdmin
        proofExists(id)
    {
        Proof storage p = proofs[id];
        if (p.verified) revert AlreadyVerified();
        if (p.rejected) revert AlreadyRejected();

        p.rejected = true;

        emit ProofRejected(id, reason);
    }


    /* ------------------------------ Read Functions ----------------------------- */

    function getProof(uint256 id)
        external
        view
        proofExists(id)
        returns (Proof memory)
    {
        return proofs[id];
    }

    function getUserProofs(address user) external view returns (uint256[] memory) {
        return userProofs[user];
    }

    function getReputation(address user) external view returns (uint256) {
        return userReputation[user];
    }


    /* ------------------------------ Admin Controls ----------------------------- */

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "zero address");
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}

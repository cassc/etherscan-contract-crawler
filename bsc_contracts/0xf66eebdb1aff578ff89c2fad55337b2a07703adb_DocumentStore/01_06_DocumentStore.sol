// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.5;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IDocumentStoreInterface.sol";

contract DocumentStore is OwnableUpgradeable {
    string private _name;
    string private _email;
    string private _legalReference;
    string private _intentDeclaration;
    string private _host;
    uint256 private _contractExpiredTime;

    address private _ownerManager;
    address[] public publishers;
    /// uint256 constant YEAR_IN_SECONDS = 31536000;

    /// A mapping of the document hash to the block number that was issued
    mapping(bytes32 => uint256) private documentIssued;
    /// A mapping of the hash of the claim being revoked to the revocation block number
    mapping(bytes32 => uint256) private documentRevoked;
    /// A mapping of the hash of the document to the expiration date
    mapping(bytes32 => uint256) private documentExpiration;
    /// A mapping of the hash of the document to the publisher
    mapping(bytes32 => address) private documentPublisher;

    event DocumentIssued(bytes32 indexed document);
    event DocumentRevoked(bytes32 indexed document);
    event PublisherChanged(address indexed documentStore, address[] currentPublishers);
    event ContractExpired(address indexed thisContract,uint256 time);
    event ContractInfoChanged(
        string name,
        string email,
        string legalReference,
        string intentDeclaration,
        string host,
        uint256 time
    );

    function initialize(
        string memory name,
        string memory email,
        string memory legalReference,
        string memory intentDeclaration,
        string memory host,
        uint256 time,
        address owner,
        address ownerManager
    ) public initializer {
        require(time > block.timestamp, "Error: expired date has passed");
        super.__Ownable_init();
        super.transferOwnership(owner);
        publishers.push(owner);
        _name = name;
        _email = email;
        _legalReference = legalReference;
        _intentDeclaration = intentDeclaration;
        _host = host;
        _ownerManager = ownerManager;
        _contractExpiredTime = time;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        IDocumentStoreInterface(_ownerManager).setOwnerOfContract(owner(), newOwner, _name);
        _transferOwnership(newOwner);
    }

    function renounceOwnership() public override onlyOwner {
        IDocumentStoreInterface(_ownerManager).setOwnerOfContract(owner(), address(0), _name);
        _transferOwnership(address(0));
    }

    function getExpiredTime() external view returns (uint256) {
        return _contractExpiredTime;
    }

    function getName() external view returns (string memory) {
        return _name;
    }

    function getEmail() external view returns (string memory) {
        return _email;
    }

    function getLegalReference() external view returns (string memory) {
        return _legalReference;
    }

    function getIntentDeclaration() external view returns (string memory) {
        return _intentDeclaration;
    }

    function getHost() external view returns (string memory) {
        return _host;
    }

    function getPublishers() external view returns (address[] memory) {
        return publishers;
    }

    function setName(string memory name) external onlyOwner contractNotExpired{
        _name = name;
        IDocumentStoreInterface(_ownerManager).setName(
            address(this), 
            _name
        );
        emit ContractInfoChanged(
            _name,
            _email,
            _legalReference,
            _intentDeclaration,
            _host,
            _contractExpiredTime
        );
    }

    function setEmail(string memory email) external onlyOwner contractNotExpired{
        _email = email;
        IDocumentStoreInterface(_ownerManager).setEmail(
            address(this), 
            _email
        );
        emit ContractInfoChanged(
            _name,
            _email,
            _legalReference,
            _intentDeclaration,
            _host,
            _contractExpiredTime
        );
    }

    function setLegalReference(string memory legalReference) external onlyOwner contractNotExpired{
        _legalReference = legalReference;
        IDocumentStoreInterface(_ownerManager).setLegalReference(
            address(this),
            _legalReference
        );
        emit ContractInfoChanged(
            _name,
            _email,
            _legalReference,
            _intentDeclaration,
            _host,
            _contractExpiredTime
        );
    }

    function setIntentDeclaration(string memory intentDeclaration) external onlyOwner contractNotExpired{
        _intentDeclaration = intentDeclaration;
        IDocumentStoreInterface(_ownerManager).setIntentDeclaration(
            address(this),
            _intentDeclaration
        );
        emit ContractInfoChanged(
            _name,
            _email,
            _legalReference,
            _intentDeclaration,
            _host,
            _contractExpiredTime
        );
    }

    function setHost(string memory host) external onlyOwner contractNotExpired{
        _host = host;
        IDocumentStoreInterface(_ownerManager).setHost(
            address(this), 
            _host
        );
        emit ContractInfoChanged(
            _name,
            _email,
            _legalReference,
            _intentDeclaration,
            _host,
            _contractExpiredTime
        );
    }

    function setExpiredTime(uint256 time) external onlyOwner{
        IDocumentStoreInterface(_ownerManager).setExpiredTime(
            address(this), 
            time
        );
        _contractExpiredTime = time;
        emit ContractInfoChanged(
            _name,
            _email,
            _legalReference,
            _intentDeclaration,
            _host,
            _contractExpiredTime
        );
    }

    function removeAllPublishers() external onlyOwner contractNotExpired{
        while(publishers.length > 0) {
            publishers.pop();
        }
        emit PublisherChanged(address(this), publishers);
    }

    function setPublishers(address[] memory _newPublishers) external onlyOwner contractNotExpired{
        while(publishers.length > 0) {
            publishers.pop();
        }
        for (uint256 i; i < _newPublishers.length; i++) {
            if (publisherCheck(_newPublishers[i])) continue;
            publishers.push(_newPublishers[i]);
        }
        emit PublisherChanged(address(this), publishers);
    }

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) 
        public 
        view 
        onlyIssued(root) 
        onlyNotRevoked(root)
        onlyNotExpired(root)
        onlyNotRevoked(leaf)
        contractNotExpired 
        returns (bool) 
    {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b)
        internal
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    function issue(bytes32 document, uint256 expiredTime)
        public
        onlyPublisher
        onlyNotIssued(document)
        contractNotExpired
    {
        documentIssued[document] = block.number;
        documentExpiration[document] = expiredTime;
        documentPublisher[document] = msg.sender;
        emit DocumentIssued(document);
    }

    function bulkIssue(bytes32[] memory documents, uint256[] memory expiredTime)
        external
    {
        for (uint256 i = 0; i < documents.length; i++) {
            issue(documents[i], expiredTime[i]);
        }
    }

    function getIssuedBlock(bytes32 document)
        external
        view
        onlyIssued(document)
        returns (uint256)
    {
        return documentIssued[document];
    }

    function isIssued(bytes32 document) 
        public 
        view 
        returns (bool) 
    {
        return (documentIssued[document] != 0);
    }

    function isIssuedBefore(bytes32 document, uint256 blockNumber)
        public
        view
        returns (bool)
    {
        return (documentIssued[document] != 0 && documentIssued[document] <= blockNumber);
    }

    function revoke(bytes32 document)
        public
        onlyPublisher
        onlyNotRevoked(document)
        contractNotExpired
    {
        documentRevoked[document] = block.number;
        emit DocumentRevoked(document);
    }

    function bulkRevoke(bytes32[] memory documents) 
        external
    {
        for (uint256 i = 0; i < documents.length; i++) {
            revoke(documents[i]);
        }
    }

    function isRevoked(bytes32 document) 
        public
        view 
        returns (bool) 
    {
        return documentRevoked[document] != 0;
    }

    function isRevokedBefore(bytes32 document, uint256 blockNumber)
        public
        view
        returns (bool)
    {
        return (documentRevoked[document] <= blockNumber && documentRevoked[document] != 0);
    }

    function getDocExpiredTime(bytes32 document)
        external
        view
        onlyIssued(document)
        returns (uint256)
    {
        return documentExpiration[document];
    }

    function isNotExpired(bytes32 document)
        public
        view
        onlyIssued(document)
        returns (bool)
    {
        return documentExpiration[document] > block.timestamp || documentExpiration[document] == 0;
    }

    function publisherCheck(address _address) 
        public 
        view
        returns (bool check) 
    {
        check = false;
        for (uint256 i; i < publishers.length; i++) {
            if (publishers[i] == _address) {
                check = true;
                break;
            }
        }
    }

    modifier onlyNotExpired(bytes32 document) {
        require(isNotExpired(document), "Error: Document is not expired");
        _;
    }

    modifier onlyIssued(bytes32 document) {
        require(isIssued(document), "Error: Document's hash is not issued ");
        _;
    }

    modifier onlyNotIssued(bytes32 document) {
        require(!isIssued(document), "Error: Only hashes that have not been issued can be issued");
        _;
    }

    modifier onlyNotRevoked(bytes32 claim) {
        require(!isRevoked(claim), "Error: Hash has been revoked previously");
        _;
    }

    modifier onlyPublisher() {
        require(publisherCheck(msg.sender), "Error: Only Publisher can revoke or issue documents");
        _;
    }

    modifier onlyVerified(bytes32[] memory proof, bytes32 root, bytes32 leaf) {
        require(verify(proof, root, leaf), "Error: Leaf is not verified");
        _;
    }

    modifier contractNotExpired() {
        require(_contractExpiredTime > block.timestamp);
        _;
    }
}
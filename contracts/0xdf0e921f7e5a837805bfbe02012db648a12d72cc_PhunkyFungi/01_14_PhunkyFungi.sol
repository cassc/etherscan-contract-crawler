/*
The Phunky Fungi Collection
https://phunkyfungi.io
Twitter @PhunkyFungi

Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./MultiSigOwnable.sol";
import "./ERC721A.sol";

contract PhunkyFungi is ERC721A, MultisigOwnable {
    using Strings for uint256;

    address private immutable _revenueRecipient;
    
    bytes32 private _presaleMerkleRoot;
    bytes32 private _collabMerkleRoot;

    mapping(address=>uint) private _presaleClaimed;
    mapping(address=>bool) private _collabClaimed;

    string private _baseUri;
    string private _placeholderURI;
    
    bool public listsFinalized    = false;
    bool public metadataFinalized = false;
    bool public timesFinalized    = false;
    bool public airdropped        = false;
    bool public revealed          = false;

    bool private _overrideCollab  = false;
    bool private _overridePresale = false;
    bool private _overridePublic  = false;

    uint public constant PRESALE_LIMIT   = 3;
    uint public constant PUBLIC_LIMIT    = 5;
    uint public constant COLLECTION_SIZE = 9200;
    uint public constant PRESALE_PRICE   = 0.098 ether;
    uint public constant PUBLIC_PRICE    = 0.125 ether;
    uint public constant TEAM_AIRDROP_LIMIT = 100;

    uint public presaleStart = 1647097200; // 2022-03-12 10:00am EST
    uint public presaleEnd   = 1647104400; // 2022-03-12 12:00pm EST
    uint public collabStart  = 1647099000; // 2022-03-12 10:30am EST
    uint public collabEnd    = 1647104400; // 2022-03-12 12:00pm EST
    uint public publicStart  = 1647104400; // 2022-03-12 12:00pm EST

    constructor(
        address revenueRecipient,
        bytes32 presaleMerkleRoot,
        bytes32 collabMerkleRoot,
        string memory placeholderURI
    )
        ERC721A("PhunkyFungi", "PF")
    {
        _revenueRecipient  = revenueRecipient;
        _presaleMerkleRoot = presaleMerkleRoot;
        _collabMerkleRoot  = collabMerkleRoot;
        _placeholderURI    = placeholderURI;
    }

    /// @notice the initial 100 tokens will be minted to the team vault for use in giveaways and collaborations.
    function airdrop(address to, uint quantity) external onlyOwner {
        require(airdropped == false, "ALREADY_AIRDROPPED");
        require(quantity <= TEAM_AIRDROP_LIMIT, "EXCEEDS_AIRDROP_LIMIT");
        airdropped = true;
        _safeMint(to, quantity);
    }
    
    function isCollabSaleActive() public view returns(bool){
        if(_overrideCollab){
            return true;
        }
        return block.timestamp > collabStart && block.timestamp < collabEnd;
    }

    function isPresaleActive() public view returns(bool){
        if(_overridePresale){
            return true;
        }
        return block.timestamp > presaleStart && block.timestamp < presaleEnd;
    }

    function isPublicSaleActive() public view returns(bool){
        if(_overridePublic){
            return true;
        }
        return block.timestamp > publicStart;
    }

    function setPresaleMerkleRoot(bytes32 root) external onlyOwner {
        require(listsFinalized == false, "LIST_FINALIZED");
        _presaleMerkleRoot = root;
    }

    function setCollabMerkleRoot(bytes32 root) external onlyOwner {
        require(listsFinalized == false, "LIST_FINALIZED");
        _collabMerkleRoot = root;
    }

    function setPresaleTimes(
        uint _presaleStartTime,
        uint _presaleEndTime
    ) onlyOwner external {
        require(timesFinalized == false, "TIMES_FINALIZED");
        presaleStart = _presaleStartTime;
        presaleEnd   = _presaleEndTime;
    }

    function setCollabSaleTimes(
        uint _collabStartTime,
        uint _collabEndTime
    ) onlyOwner external {
        require(timesFinalized == false, "TIMES_FINALIZED");
        collabStart = _collabStartTime;
        collabEnd   = _collabEndTime;
    }

    function setPublicSaleTimes(
        uint _publicStartTime
    ) onlyOwner external {
        require(timesFinalized == false, "TIMES_FINALIZED");
        publicStart = _publicStartTime;
    }

    function toggleReveal() external onlyOwner {
        require(metadataFinalized == false, "METADATA_FINALIZED");
        revealed = !revealed;
    }

    function toggleCollab() external onlyOwner {
        require(timesFinalized == false, "TIMES_FINALIZED");
        _overrideCollab = !_overrideCollab;
    }

    function togglePresale() external onlyOwner {
        require(timesFinalized == false, "TIMES_FINALIZED");
        _overridePresale = !_overridePresale;
    }

    function togglePublic() external onlyOwner {
        require(timesFinalized == false, "TIMES_FINALIZED");
        _overridePublic = !_overridePublic;
    }

    function finalizeMetadata() external onlyOwner {
        require(metadataFinalized == false, "METADATA_FINALIZED");
        metadataFinalized = true;
    }

    function finalizeTimes() external onlyOwner {
        require(timesFinalized == false, "TIMES_FINALIZED");
        timesFinalized = true;
    }

    function finalizeLists() external onlyOwner {
        require(listsFinalized == false, "LIST_FINALIZED");
        listsFinalized = true;
    }
    
    function setBaseURI(string memory baseUri) external onlyOwner {
        require(metadataFinalized == false, "METADATA_FINALIZED");
        _baseUri = baseUri;
    }

    function setPlaceholderURI(string memory placeholderUri) external onlyOwner {
        require(metadataFinalized == false, "METADATA_FINALIZED");
        _placeholderURI = placeholderUri;
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /// @notice Withdraw's contract's balance to the withdrawal address
    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "NO_BALANCE");

        (bool success, ) = payable(_revenueRecipient).call{ value: balance }("");
        require(success, "WITHDRAW_FAILED");
    }

    function _verifyList(bytes32[] calldata _merkleProof, bytes32 root, address addr) internal view returns(bool) {
        return (MerkleProof.verify(_merkleProof, root, keccak256(abi.encodePacked(addr))) == true);
    }

    function verifyPresale(bytes32[] calldata _merkleProof, address addr) public view returns(bool) {
       return _verifyList(_merkleProof, _presaleMerkleRoot, addr);
    }

    function verifyCollab(bytes32[] calldata _merkleProof, address addr) public view returns(bool) {
       return _verifyList(_merkleProof, _collabMerkleRoot, addr);
    }
    
    /// @notice each address on the collaboration list may mint 1 token at the collab sale price
    function collabMint(bytes32[] calldata _merkleProof) external payable {
        require(isCollabSaleActive(), "COLLAB_SALE_INACTIVE");
        require(_collabClaimed[msg.sender] == false, "1_TOKEN_LIMIT");
        require(totalSupply() < COLLECTION_SIZE, "EXCEEDS_COLLECTION_SIZE");
        require(verifyCollab(_merkleProof, msg.sender), "COLLAB_NOT_VERIFIED");
        require(msg.value >= PRESALE_PRICE, "VALUE_TOO_LOW");
        _collabClaimed[msg.sender] = true;

        _safeMint(msg.sender, 1);
    }
    
    /// @notice each address on the presale list may mint up to 3 tokens at the presale price
    function presaleMint(bytes32[] calldata _merkleProof, uint quantity) external payable {
        require(isPresaleActive(), "PRESALE_INACTIVE");
        require(verifyPresale(_merkleProof, msg.sender), "PRESALE_NOT_VERIFIED");
        require(totalSupply() + quantity <= COLLECTION_SIZE, "EXCEEDS_COLLECTION_SIZE");
        require(_presaleClaimed[msg.sender] + quantity <= PRESALE_LIMIT, "3_TOKEN_LIMIT");
        uint cost;
        cost = quantity * PRESALE_PRICE;
        require(msg.value >= cost, "VALUE_TOO_LOW");
        _presaleClaimed[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    /// @notice may mint up to 5 tokens per transaction at the public sale price.
    function mint(uint quantity) external payable {
        require(isPublicSaleActive(), "PUBLIC_SALE_INACTIVE");
        require(quantity <= PUBLIC_LIMIT, "5_TOKEN_LIMIT");
        require(totalSupply() + quantity <= COLLECTION_SIZE, "EXCEEDS_COLLECTION_SIZE");
        uint cost;
        cost = quantity * PUBLIC_PRICE;
        require(msg.value >= cost, "VALUE_TOO_LOW");

        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "INVALID_ID");

        return revealed
            ? string(abi.encodePacked(_baseURI(), id.toString(), ".json"))
            : _placeholderURI;
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Elephants is ERC721AQueryable, Ownable {
    // ============ State Variables ============

    string public _baseTokenURI;
    uint256 public maxTokenIds = 7777;
    bool public _paused;
    uint256 public maxPerWallet = 3;
    string public hiddenMetadataUri;
    bool public revealed;
    uint256 public price = 0.03 ether;
    bytes32 public root;
    string private _name;
    string private _symbol;
    string public uriSuffix;
    uint256 public presaleStartTime = 1657814400;
    uint256 public presaleEndTime   = 1657836000;

    // ============ Modifiers ============

    modifier onlyWhenNotPaused() {
        require(!_paused, "Contract currently paused");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // ============ Constructor ============

    constructor(string memory __name, string memory __symbol, string memory _hiddenMetadataUri, bytes32 __root, address treasury) ERC721A(__name, __symbol) {
        _name = __name;
        _symbol = __symbol;
        hiddenMetadataUri = _hiddenMetadataUri;
        root = __root;
        _mint(treasury, 50);
    }

    // ============ Core functions ============

    function whitelistmint(uint256 quantity, bytes32[] memory proof) external payable onlyWhenNotPaused callerIsUser {
        require(block.timestamp > presaleStartTime && block.timestamp < presaleEndTime, "Not whitelisting period");
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Address not in whitelist");
        require(_nextTokenId() + quantity - 1 <= maxTokenIds, "Not enough supply");
        require(balanceOf(msg.sender) + quantity <= maxPerWallet, "Exceeding max per wallet limit");
        require(msg.value >= price * quantity, "More ETH required");
        _mint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable onlyWhenNotPaused callerIsUser {
        require(block.timestamp > presaleEndTime, "Not public sale period");
        require(_nextTokenId() + quantity - 1 <= maxTokenIds, "Not enough supply");
        require(balanceOf(msg.sender) + quantity <= maxPerWallet, "Exceeding max per wallet limit");
        require(msg.value >= price * quantity, "More ETH required");
        _mint(msg.sender, quantity);
    }

    function mintMany(address[] calldata _to, uint256[] calldata _amount) external payable onlyOwner {
        for (uint256 i; i < _to.length; ) {
             require(_nextTokenId() + _amount[i] - 1 <= maxTokenIds, "Not enough supply");
            _mint(_to[i], _amount[i]);

            unchecked {
                i++;
            }
        }
    }

    function mintForAddress(address _to, uint256 _quantity) external payable onlyOwner {
        require(_nextTokenId() + _quantity - 1 <= maxTokenIds, "Not enough supply");
        _mint(_to, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721AMetadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), uriSuffix)) : hiddenMetadataUri;
    }

    function withdraw() external onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function name() public view virtual override(IERC721A, ERC721A) returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override(IERC721A, ERC721A) returns (string memory) {
        return _symbol;
    }

    // ============ Setters (OnlyOwner) ============

    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    function setURISuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    function setNameAndSymbol(string memory __name, string memory __symbol) external onlyOwner {
        _name = __name;
        _symbol = __symbol;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setMaxPerWallet(uint256 quantity) external onlyOwner {
        maxPerWallet = quantity;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setSaleTimings(uint256 _whitelistStart, uint256 _whitelistEnd) external onlyOwner {
        presaleStartTime = _whitelistStart;
        presaleEndTime = _whitelistEnd;
    }

    // ============ Cryptographic functions ============

    function isValid(bytes32[] memory proof, bytes32 leaf) internal view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    receive() external payable {}

    fallback() external payable {}
}
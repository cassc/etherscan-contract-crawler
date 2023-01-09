// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract Fleetwood is Ownable, ERC721A, ReentrancyGuard {
    // Custom errors
    error CallerNotUser();
    error InvalidMerkleProof();
    error IncorrectValueSent();
    error ExceedsAddressBoxMintLimit();
    error ExceedsMaxSupply();
    error ExceedsBoxMintLimit();
    error InvalidBox();
    error MintingNotOpen();

    // Max supply of tokens
    uint public maxSupply = 2400;
    // Amount of tokens per box
    uint public boxSize = 2;
    // Amount of box options
    uint public numOfBoxes = 3;
    // Amount of boxes allowed to be minted per address
    uint public addressBoxMintLimit = 1;
    // Minting status
    bool public mintIsOpen = false;
    // Whitelist status
    bool public whitelistEnabled = true;
    // Merkle root for whitelist
    bytes32 public merkleRoot;

    /* 
        Boxes:
            0 = grind
            1 = raider
            2 = conqueror
    */

    // Prices for each box
    mapping(uint => uint) public boxPrices;
    // Number of boxes minted per user
    mapping(address => uint) public numOfBoxesMintedByAddress;
    // Number of boxes allowed to be minted per type
    mapping(uint => uint) public boxMintLimit;
    // Number of boxes minted per type
    mapping(uint => uint) public numOfBoxMinted;
    // Type of box minted per user
    mapping(address => uint) public lastBoxMintedByAddress;

    string private _baseTokenURI = "";

    constructor() ERC721A("FleetWood", "FW") {
        // Set box prices
        boxPrices[0] = 0.1 ether;
        boxPrices[1] = 0.2 ether;
        boxPrices[2] = 0.4 ether;

        // Set box mint limits
        boxMintLimit[0] = 454;
        boxMintLimit[1] = 398;
        boxMintLimit[2] = 284;
    }

    // Prevents contract calling
    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert CallerNotUser();
        _;
    }

    // Toggle minting
    function toggleMint() external onlyOwner {
        mintIsOpen = !mintIsOpen;
    }

    // Toggle whitelist
    function toggleWhitelist() external onlyOwner {
        whitelistEnabled = !whitelistEnabled;
    }

    // Sets the number of boxes
    function setNumOfBoxes(uint _numOfBoxes) external onlyOwner {
        numOfBoxes = _numOfBoxes;
    }

    // Sets the merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // Sets the price for a box
    function setBoxPrice(uint _box, uint _price) external onlyOwner {
        // Check if box is valid
        if (_box > numOfBoxes - 1) revert InvalidBox();
        boxPrices[_box] = _price;
    }

    // Sets the max supply
    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    // Sets the number of tokens in each box
    function setBoxSize(uint _boxSize) external onlyOwner {
        boxSize = _boxSize;
    }

    // Sets the maximum amount of boxes to be allowed to be minted by a user
    function setAddressBoxMintLimit(uint _maxMint) external onlyOwner {
        addressBoxMintLimit = _maxMint;
    }

    // Sets the maximum amount of boxes to be allowed to be minted per type
    function setBoxMintLimit(uint _box, uint _maxMint) external onlyOwner {
        // Check if box is valid
        if (_box > numOfBoxes - 1) revert InvalidBox();
        boxMintLimit[_box] = _maxMint;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    // Verifies a merkle proof
    function verifyAddress(
        bytes32[] calldata _merkleProof
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    // Mints a box with whitelist
    function FWMint(
        bytes32[] calldata _merkleProof,
        uint _box
    ) public payable callerIsUser {
        uint _boxSize = boxSize;

        // Check if whitelist is enabled and if so, verify merkle proof
        if (whitelistEnabled && !verifyAddress(_merkleProof))
            revert InvalidMerkleProof();
        // Check if minting is open
        if (!mintIsOpen) revert MintingNotOpen();
        // Check if box is valid
        if (_box > numOfBoxes - 1) revert InvalidBox();
        // Check if message value corresponds to box price
        if (msg.value != boxPrices[_box]) revert IncorrectValueSent();
        // Check if max supply has been reached
        if (totalSupply() + _boxSize > maxSupply) revert ExceedsMaxSupply();
        // Check if box mint limit has been reached
        if (numOfBoxMinted[_box] == boxMintLimit[_box])
            revert ExceedsBoxMintLimit();
        // Check if user has reached box mint limit
        if (numOfBoxesMintedByAddress[msg.sender] == addressBoxMintLimit)
            revert ExceedsAddressBoxMintLimit();

        // Increment box minted
        numOfBoxMinted[_box] += 1;
        // Set box minted by user
        lastBoxMintedByAddress[msg.sender] = _box;
        // Increment number of boxes minted by user
        numOfBoxesMintedByAddress[msg.sender] += 1;
        // Mint tokens
        _mint(msg.sender, _boxSize);
    }

    // Mass mint function
    function massMint(uint _amount) external onlyOwner {
        if (totalSupply() + _amount > maxSupply) revert ExceedsMaxSupply();
        _mint(msg.sender, _amount);
    }

    // Withdraws funds to owner
    function withDraw() external onlyOwner nonReentrant {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
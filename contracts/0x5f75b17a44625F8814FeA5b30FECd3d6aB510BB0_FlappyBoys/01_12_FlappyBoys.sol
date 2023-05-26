// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract FlappyBoys is ERC721A, Ownable {

    uint256 public immutable maxSupply;
    uint256 public immutable devSupply;
    uint256 public immutable mintPrice;
    uint256 public immutable ogMintPrice;
    uint256 public immutable maxMintPerAddress;
    uint256 public immutable ogMaxMintPerAddress;
    uint256 public ogSupply; // Unlockable supply

    mapping (address => uint256) public addressMintCount;
    bytes32 public ogMerkleRoot;
    bytes32 public wlMerkleRoot;

    bool public isSaleLive;
    bool public isPresaleLive;
    string public baseURI;

    constructor(
        uint256 _maxSupply,
        uint256 _devSupply,
        uint256 _mintPrice,
        uint256 _ogMintPrice,
        uint256 _maxMintPerAddress,
        uint256 _ogMaxMintPerAddress,
        uint256 _ogSupply
    ) ERC721A("Flappy Boys", "FlappyBoys") {
        maxSupply = _maxSupply;
        devSupply = _devSupply;
        mintPrice = _mintPrice;
        ogMintPrice = _ogMintPrice;
        maxMintPerAddress = _maxMintPerAddress;
        ogMaxMintPerAddress = _ogMaxMintPerAddress;
        ogSupply = _ogSupply;
    }

    function ogMint(uint256 quantity, bytes32[] calldata merkleProof) external payable {
        require(isPresaleLive, "Presale not live");
        require(quantity > 0 && quantity <= ogMaxMintPerAddress, "Invalid quantity");
        require(addressMintCount[msg.sender] + quantity <= ogMaxMintPerAddress, "Max mint exceeded for address");
        require(totalSupply() + quantity <= maxSupply, "Quantity exceeds max supply");
        require(msg.value >= quantity * ogMintPrice, "Not enough ETH sent");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, ogMerkleRoot, leaf), "Invalid merkle proof");

        ogSupply = quantity <= ogSupply ? ogSupply-quantity : 0;

        addressMintCount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function wlMint(uint256 quantity, bytes32[] calldata merkleProof) external payable {
        require(isPresaleLive, "Presale not live");
        require(quantity > 0 && quantity <= maxMintPerAddress, "Invalid quantity");
        require(addressMintCount[msg.sender] + quantity <= maxMintPerAddress, "Max mint exceeded for this address");
        require(totalSupply() + ogSupply + quantity <= maxSupply, "Max supply exceeded");
        require(msg.value >= quantity * mintPrice, "Not enough ETH sent");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, wlMerkleRoot, leaf), "Invalid merkle proof");

        addressMintCount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(isSaleLive, "Public sale not live");
        require(quantity > 0 && quantity <= maxMintPerAddress, "Invalid quantity");
        require(addressMintCount[msg.sender] + quantity <= maxMintPerAddress, "Max mint exceeded for this address");
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        require(msg.value >= quantity * mintPrice, "Not enough ETH sent");

        addressMintCount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Free mints for deployer, capped to devSupply amount
     * Tokens will be used for marketing, etc.
     */
    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= devSupply, "Quantity exceeds max dev supply");
        require(totalSupply() + quantity <= maxSupply, "Quantity exceeds max supply");
        _safeMint(msg.sender, quantity);
    }

    function toggleSaleStatus() external onlyOwner {
        isSaleLive = !isSaleLive;
    }

    function togglePresaleStatus() external onlyOwner {
        isPresaleLive = !isPresaleLive;
    }

    function setOGMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        ogMerkleRoot = merkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        wlMerkleRoot = merkleRoot;
    }

    function addressMintedAmount(address _address) public view returns (uint256) {
        return addressMintCount[_address];
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setOGSupply(uint256 _ogSupply) external onlyOwner {
        ogSupply = _ogSupply;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Nagomi is ERC721A, Ownable, Pausable {
    address public constant withdrawAddress = 0x445513cd8ECA1E98b0C70f1Cdc52C4d986dDC987;

    string public baseURI = "";
    string public baseExtension = ".json";

    uint256 public salesId = 1;
    uint256 public maxAmountPerMint = 2;
    uint256 public maxSupply = 2259;
    uint256 public mintCost = 0.0 ether;
    bytes32 merkleRoot;

    mapping(uint256 => mapping(address => uint256)) mintedAmountBySales;

    modifier enoughEth(uint256 amount) {
        require(msg.value >= amount * mintCost, 'Not Enough Eth');
        _;
    }
    modifier withinMaxSupply(uint256 amount) {
        require(totalSupply() + amount <= maxSupply, 'Over Max Supply');
        _;
    }
    modifier withinMaxAmountPerMint(uint256 amount) {
        require(amount <= maxAmountPerMint, 'Over Max Amount Per Mint');
        _;
    }
    modifier withinMaxAmountPerAddress(uint256 amount, uint256 allowedAmount) {
        require(mintedAmountBySales[salesId][msg.sender] + amount <= allowedAmount, 'Over Max Amount Per Address');
        _;
    }
    modifier validProof(uint256 allowedAmount, bytes32[] calldata merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, allowedAmount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");
        _;
    }

    constructor() ERC721A("Nagomi", "NGM") {
        _safeMint(0x40Af078ebE19F16d064D055881ee97E1c6D6be12, 23);
        _pause();
    }

    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }

    // Sales
    function setSalesInfo(uint256 _salesId, uint256 _maxAmountPerMint, uint256 _maxSupply, uint256 _mintCost, bytes32 _merkleRoot) public onlyOwner {
        salesId = _salesId;
        maxAmountPerMint = _maxAmountPerMint;
        maxSupply = _maxSupply;
        mintCost = _mintCost;
        merkleRoot = _merkleRoot;
    }
    function setSalesId(uint256 _value) public onlyOwner {
        salesId = _value;
    }
    function setMaxAmountPerMint(uint256 _value) public onlyOwner {
        maxAmountPerMint = _value;
    }
    function setMaxSupply(uint256 _value) public onlyOwner {
        maxSupply = _value;
    }
    function setMintCost(uint256 _value) public onlyOwner {
        mintCost = _value;
    }
    function setMerkleRoot(bytes32 _value) public onlyOwner {
        merkleRoot = _value;
    }
    function getMintedAmount(address targetAddress) view public returns(uint256) {
        return mintedAmountBySales[salesId][targetAddress];
    }
    function mint(uint256 amount, uint256 allowedAmount, bytes32[] calldata merkleProof) external payable
        whenNotPaused
        enoughEth(amount)
        withinMaxSupply(amount)
        withinMaxAmountPerMint(amount)
        withinMaxAmountPerAddress(amount, allowedAmount)
        validProof(allowedAmount, merkleProof)
    {
        mintedAmountBySales[salesId][msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    function setBaseURI(string memory _value) external onlyOwner {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) external onlyOwner {
        baseExtension = _value;
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }
}
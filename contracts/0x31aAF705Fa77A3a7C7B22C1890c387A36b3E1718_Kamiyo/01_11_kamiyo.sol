// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Kamiyo is ERC721AntiScam, Pausable {
    address public constant withdrawAddress = 0xe53f976b720a0Be0Fd60508f9E938185DfD43657;

    string public baseURI = "";
    string public baseExtension = ".json";

    uint256 public salesId = 1;
    uint256 public maxAmountPerMint = 2;
    uint256 public maxSupply = 13333;
    uint256 public mintCost = 0.001 ether;
    bytes32 merkleRoot;
    bool public isBurnMint = false;
    uint256 public maxBurnMint = 0;

    mapping(uint256 => mapping(address => uint256)) mintedAmountBySales;

    modifier isMintSale() {
        require(!isBurnMint, 'Current Sale is For Burn Mint');
        _;
    }
    modifier isBurnMintSale() {
        require(isBurnMint, 'Current Sale is For Mint');
        _;
    }
    modifier enoughEth(uint256 amount) {
        require(msg.value >= amount * mintCost, 'Not Enough Eth');
        _;
    }
    modifier withinMaxSupply(uint256 amount) {
        require(totalSupply() + amount <= maxSupply, 'Over Max Supply');
        _;
    }
    modifier withinMaxBurnMint(uint256 amount) {
        require(_totalBurned() + amount <= maxSupply, 'Over Max Burn Mint');
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

    constructor(address[] memory addresses, uint256[] memory amounts) ERC721A("Kamiyo", "KMY") {
        require (addresses.length == amounts.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
        _pause();
    }

    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }

    function setSalesInfo(uint256 _salesId, uint256 _maxAmountPerMint, uint256 _maxSupply, uint256 _mintCost, bytes32 _merkleRoot, bool _isBurnMint, uint256 _maxBurnMint) public onlyOwner {
        salesId = _salesId;
        maxAmountPerMint = _maxAmountPerMint;
        maxSupply = _maxSupply;
        mintCost = _mintCost;
        merkleRoot = _merkleRoot;
        isBurnMint = _isBurnMint;
        maxBurnMint = _maxBurnMint;
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
    function setIsBurnMint(bool _value) public onlyOwner {
        isBurnMint = _value;
    }
    function setMaxBurnMint(uint256 _value) public onlyOwner {
        maxBurnMint = _value;
    }
    function getMintedAmount(address targetAddress) view public returns(uint256) {
        return mintedAmountBySales[salesId][targetAddress];
    }
    function getTotalBurned() view public returns (uint256) {
        return _totalBurned();
    }

    function mint(uint256 amount, uint256 allowedAmount, bytes32[] calldata merkleProof) external payable
        whenNotPaused
        isMintSale()
        enoughEth(amount)
        withinMaxSupply(amount)
        withinMaxAmountPerMint(amount)
        withinMaxAmountPerAddress(amount, allowedAmount)
        validProof(allowedAmount, merkleProof)
    {
        mintedAmountBySales[salesId][msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }
    function burnMint(uint256[] memory burnTokenIds, uint256 allowedAmount, bytes32[] calldata merkleProof) external payable
        whenNotPaused
        isBurnMintSale()
        enoughEth(burnTokenIds.length)
        withinMaxBurnMint(burnTokenIds.length)
        withinMaxAmountPerMint(burnTokenIds.length)
        withinMaxAmountPerAddress(burnTokenIds.length, allowedAmount)
        validProof(allowedAmount, merkleProof)
    {
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            uint256 tokenId = burnTokenIds[i];
            require (msg.sender == ownerOf(tokenId));
            _burn(tokenId);
        }
        mintedAmountBySales[salesId][msg.sender] += burnTokenIds.length;
        _safeMint(msg.sender, burnTokenIds.length);
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
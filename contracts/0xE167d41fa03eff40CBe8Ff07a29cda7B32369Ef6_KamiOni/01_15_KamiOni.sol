// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol"; 
import { RevokableDefaultOperatorFilterer } from "./RevokableDefaultOperatorFilterer.sol";
import { RevokableOperatorFilterer } from "./RevokableOperatorFilterer.sol";
import { IOperatorFilterRegistry } from "./IOperatorFilterRegistry.sol";
import { OperatorFilterRegistryErrorsAndEvents} from "./OperatorFilterRegistryErrorsAndEvents.sol";

contract KamiOni is ERC721A, Ownable, RevokableDefaultOperatorFilterer {

    address private operatorFilterRegistryAddress = address(0);

    address private withdrawAddress = address(0);
    
    string private _tokenBaseURI = '';
    
    string private _blindTokenURI = '';

    bool private _revealed = false;

    bool public paused = true;

    bool public isPublicLive = false;

    bytes32 public merkleRoot;

    uint16 public constant maxSupply = 6666;

    uint8 public maxMintAmountPerMint = 10;

    uint8 public maxMintAmountPerWallet = 10;

    // price
    uint256 public mintPrice = 0.05 ether;

    uint256 public whitelistMintPrice = 0.038 ether;

    mapping (address => uint8) public NFTPerAddress;

    constructor(string memory name_, string memory symbol_, bytes32 _merkleRoot, string memory defaultTokenURI) 
        ERC721A(name_, symbol_)
    {
        _tokenBaseURI = defaultTokenURI;
        merkleRoot = _merkleRoot;

        // Mint genesis for owner
        _safeMint(_msgSender() , 1);
    }

    function _baseURI() internal view virtual override returns (string memory){
        return _tokenBaseURI;
    }

    function reveal(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
        _revealed = true;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if(_revealed){
            return string(abi.encodePacked(super.tokenURI(tokenId), '.json'));
        }

        return _baseURI();
    }

    function mintWhitelist(uint256 _mintAmount, bytes32[] calldata merkleProof) external payable {
        require(!paused, "The contract is paused!");
        require(_mintAmount <= maxMintAmountPerMint, "Exceeds max amount per mint.");
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        require(whitelistMintPrice * _mintAmount <= msg.value, "Not enough ETH sent for selected amount");

        uint8 nft = NFTPerAddress[msg.sender];
        require(_mintAmount + nft  <= maxMintAmountPerWallet, "Exceeds max NFT allowed per Wallet.");
        require(MerkleProof.verify(merkleProof, merkleRoot, toBytes32(msg.sender)) == true, "Invalid merkle proof");

        _safeMint(msg.sender , _mintAmount);

        NFTPerAddress[msg.sender] = uint8(_mintAmount) + nft ;
        delete totalSupply;
    }

    function mint(uint256 _mintAmount) external payable {
        require(isPublicLive, "Sale not live");
        require(!paused, "The contract is paused!");
        require(_mintAmount <= maxMintAmountPerMint, "Exceeds max amount per mint.");
        uint16 totalSupply = uint16(totalSupply());

        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        require(mintPrice * _mintAmount <= msg.value, "Not enough ETH sent for selected amount");
        uint8 nft = NFTPerAddress[msg.sender];
        require(_mintAmount + nft  <= maxMintAmountPerWallet, "Exceeds max NFT allowed per Wallet.");
        _safeMint(msg.sender , _mintAmount);

        NFTPerAddress[msg.sender] = uint8(_mintAmount) + nft ;
        delete totalSupply;
    }

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override (Ownable, RevokableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function togglePublicLive() external onlyOwner {
        isPublicLive = !isPublicLive;
    }

    function setMaxMintAmountPerWallet(uint8 _maxtx) external onlyOwner {
        maxMintAmountPerWallet = _maxtx;
    }

    function setMaxMintAmountPerMint(uint8 _maxtx) external onlyOwner {
        maxMintAmountPerMint = _maxtx;
    }

    function setWithdrawAddress(address _withdrawAddress) external onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setMerkltRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        require(withdrawAddress != address(0), "No withdraw address");
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setWhitelistMintPrice(uint256 _mintPrice) external onlyOwner {
        whitelistMintPrice = _mintPrice;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC5050.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol"; 
import { RevokableDefaultOperatorFilterer } from "./RevokableDefaultOperatorFilterer.sol";
import { RevokableOperatorFilterer } from "./RevokableOperatorFilterer.sol";
import { IOperatorFilterRegistry } from "./IOperatorFilterRegistry.sol";
import { OperatorFilterRegistryErrorsAndEvents } from "./OperatorFilterRegistryErrorsAndEvents.sol";

contract FuekiPixelverse is ERC5050, RevokableDefaultOperatorFilterer {

    address private operatorFilterRegistryAddress = address(0);

    address private withdrawAddress = address(0);
    
    string private _tokenBaseURI = '';
    
    string private _blindTokenURI = '';

    bool private _revealed = false;

    bool public paused = true;

    bytes32 public merkleRoot;

    uint16 public constant maxSupply = 8888;

    uint8 public maxMintAmountPerMint = 10;

    uint8 public maxMintAmountPerWallet = 10;

    uint256 public whitelistMintPrice = 1 ether;

    uint8 public maxWhitelistFreeMint = 2;

    uint8 public maxFreeMint = 2;

    mapping (address => uint8) public NFTPerAddress;

    event VoteCast(address voter, uint votes, uint inFavor);

    constructor(string memory name_, string memory symbol_) ERC5050(name_, symbol_){
        // Mint genesis for owner
        _safeMint(_msgSender() , 1);

        // Override presets
        isPublicLive = false;
        mintPrice = 0.001 ether;
        whitelistMintPrice = 0.001 ether;

        // Disable mintPublic from parent
        maxPerTransaction = 0;

        // Sync supply
        maxTotalSupply = maxSupply;
    }

    function initialize(bytes32 _merkleRoot, string memory defaultTokenURI) external onlyOwner {
        _tokenBaseURI = defaultTokenURI;
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return _tokenBaseURI;
    }

    function reveal(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
        _revealed = true;
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

        uint8 nft = NFTPerAddress[_msgSender()];
        uint256 _mintPrice = whitelistMintPriceFor(_mintAmount);

        require(_mintPrice <= msg.value, "Not enough ETH sent for selected amount");
        require(_mintAmount + nft  <= maxMintAmountPerWallet, "Exceeds max NFT allowed per Wallet.");
        require(MerkleProof.verify(merkleProof, merkleRoot, toBytes32(_msgSender())) == true, "Invalid merkle proof");

        // _refund(_mintAmount, whitelistMintPrice);
        _safeMint(_msgSender(), _mintAmount);

        NFTPerAddress[_msgSender()] = uint8(_mintAmount) + nft ;
        delete totalSupply;
    }

    function mint(uint256 _mintAmount) external payable {
        require(isPublicLive, "Sale not live");
        require(!paused, "The contract is paused!");
        require(_mintAmount <= maxMintAmountPerMint, "Exceeds max amount per mint.");
        uint16 totalSupply = uint16(totalSupply());
        uint256 _mintPrice = mintPriceFor(_mintAmount);
        uint8 nft = NFTPerAddress[_msgSender()];
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        require(_mintPrice <= msg.value, "Not enough ETH sent for selected amount");
        require(_mintAmount + nft  <= maxMintAmountPerWallet, "Exceeds max NFT allowed per Wallet.");

        // _refund(_mintAmount, mintPrice);
        _safeMint(_msgSender() , _mintAmount);

        NFTPerAddress[_msgSender()] = uint8(_mintAmount) + nft ;
        delete totalSupply;
    }

    function whitelistMintPriceFor(uint256 _mintAmount) internal view returns (uint256) {
        uint8 freeMintAvailable = maxWhitelistFreeMint - NFTPerAddress[_msgSender()];
        if (freeMintAvailable > 0) {
            if (_mintAmount <= freeMintAvailable) {
                return 0;
            } else {
                return (_mintAmount - freeMintAvailable) * whitelistMintPrice;
            }
        }

        return _mintAmount * whitelistMintPrice;
    }

    function mintPriceFor(uint256 _mintAmount) internal view returns (uint256) {
        uint8 freeMintAvailable = maxFreeMint - NFTPerAddress[_msgSender()];
        if (freeMintAvailable > 0) {
            if (_mintAmount <= freeMintAvailable) {
                return 0;
            } else {
                return (_mintAmount - freeMintAvailable) * mintPrice;
            }
        }

        return _mintAmount * mintPrice;
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

    function setMerkltRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintPrice(uint256 _mintPrice) external onlyOwner {
        whitelistMintPrice = _mintPrice;
    }

    function setMaxWhitelistFreeMint(uint8 val) external onlyOwner {
        maxWhitelistFreeMint = val;
    }

    function setMaxFreeMint(uint8 val) external onlyOwner {
        maxFreeMint = val;
    }

    function mintPrivate(uint256 _mintAmount, address to) external onlyOwner {
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        _safeMint(to, _mintAmount);
    }
}
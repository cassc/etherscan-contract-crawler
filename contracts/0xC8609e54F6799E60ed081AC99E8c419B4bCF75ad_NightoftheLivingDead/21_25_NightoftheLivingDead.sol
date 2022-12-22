// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { Errors } from './Errors.sol';

import "./RatKingSociety.sol";

/**
* @title NightoftheLivingDead (Free Content by RatKingSociety)
* @author Zeeshan Jan 
* @notice This contract manages the NightoftheLivingDead Movie NFTs by https://ratkingsociety.com/
*/

/// @custom:security-contact [email protected]
contract NightoftheLivingDead is ERC721, ERC721Enumerable, Pausable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Counters for Counters.Counter;

    /// Counter for Tokens
    Counters.Counter private _tokenIdCounter;
    
    /// Mappings for RatKing NFTs to trace which RatKing ID has been used to mint NightoftheLivingDead NFT.
    mapping(uint256 => bool) ratKingMinterList;

    /// Maximum Supply of NightoftheLivingDead NFTs
    uint256 MAX_MOVIE_SUPPLY = 200; 

    /// Base URI (IPFS) for NightoftheLivingDead NFTs
    string private _baseURIextended;

    /// For Unlocked Content
    string private lockedContent;

    event NightOfTheLivingDeadMinted();
    event WithdrawBalance(uint256 balance);
    event WithdrawERC20(uint256 balance);

    /// Reference instance of the RatKingSociety Smart Contract
    RatKingSociety RK;

    /// Address of the RatKingSociety Smart Contract
    address ratKingAddress;

    constructor() ERC721("NightOfTheLivingDead", "NightoftheLivingDead") {

        _baseURIextended = "ipfs://bafybeih575cfgsiso2spzbgmudqtlxht3lxiyiazz4wpym2wcqsypjwabu/";
    }

    /**
    * @notice Sets the (IPFS) URL of NightoftheLivingDead NFTs
    * @param baseURI_ is the (IPFS) URL for NightoftheLivingDead NFTs
    */
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    /**
    * @notice Gets the (IPFS) URI of NightoftheLivingDead NFTs
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
    * @notice Sets the address of the RatKingSociety Smart Contract
    * @param ratAdd is the address of RatKingSociety Smart Contract
    */
    function setRatKingAddress(address ratAdd) public onlyOwner {
        ratKingAddress = ratAdd;
        RK = RatKingSociety(ratKingAddress);
    }

    /**
    * @notice Pauses the Smart Contract
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    * @notice Resumes the Smart Contract
    */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    * @notice Minting of the NightoftheLivingDead NFTs
    * @param ratKing is the ID of RatKingSociety NFT.
    * The function checks if the msg.sender owns that RatKing, and if that RatKing has already been used to mint NightoftheLivingDead NFT.
    */
    function mintNightOfTheLivingDead(uint256 ratKing) public whenNotPaused {
        if(_tokenIdCounter.current() >= MAX_MOVIE_SUPPLY) revert Errors.MaximumPublicSupplyLimitReached();

        if(ratKingMinterList[ratKing] == true) revert Errors.RatKingHasAlreadyMintedFreeNFT();

        if(RK.ownerOf(ratKing) != msg.sender) revert Errors.NotYourRatKing();

        safeMint(msg.sender);
        ratKingMinterList[ratKing] = true;
    }

    /**
    * @notice Checks if a RatKing ID has been used to mint NightoftheLivingDead
    * @param ratKing is the ID of RatKing
    */
    function checkNightOfTheLivingDeadMinted(uint256 ratKing) public view returns (bool) {
        return ratKingMinterList[ratKing];
    }

    function safeMint(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        emit NightOfTheLivingDeadMinted();
    }

    /**
    * @notice Sets lockedContent's IPFS URI
    * @param lockedContentURI is the ID of RatKing
    */
    function setLockedContent(string memory lockedContentURI) public onlyOwner {
        lockedContent = lockedContentURI;
    }

    /**
    * @notice Gets lockedContent's IPFS URI
    */
    function unlockContent() public view returns (string memory) {
        if (balanceOf(msg.sender) < 1) revert Errors.NoFreeContentNFTOwned();
        return lockedContent;
    }

    /**
    * @notice Function required to override by DefaultOperatorFilterer
    */
    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
    * @notice Function required to override by DefaultOperatorFilterer
    */
    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
    * @notice Function required to override by DefaultOperatorFilterer
    */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
    * @notice Function required to override by DefaultOperatorFilterer
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable) 
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @notice allows owner to withdraw funds from minting
    */
    function withdraw() public onlyOwner nonReentrant {

        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success,"Transfer failed!");
        emit WithdrawBalance(address(this).balance);
    }

    /**
    * @notice allows owner to withdraw any ERC20 token from contract's balances
    * @param erc20TokenContract The contract address of an ERC20 token
    */
    
    function withdrawERC20(address erc20TokenContract) public onlyOwner nonReentrant{
        IERC20 tokenContract = IERC20(erc20TokenContract);
        //tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));

        (bool success, ) = payable(owner()).call{value: tokenContract.balanceOf(address(this))}('');
        require(success,"Transfer failed!");
        emit WithdrawERC20(address(this).balance);
    }
    
}
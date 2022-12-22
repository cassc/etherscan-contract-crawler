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

/**
* @title RatKingSociety (InfinityPass)
* @author Zeeshan Jan
* @notice This contract manages the RatKing NFTs by https://ratkingsociety.com/
*/

/// @custom:security-contact [email protected]
contract RatKingSociety is ERC721, ERC721Enumerable, Pausable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Counters for Counters.Counter;

    /// Counter for Tokens
    Counters.Counter private _tokenIdCounter;

    ///Counter for public minted tokens
    Counters.Counter private _publicMintCounter;

    ///Counter for tokens gifted by the owner
    Counters.Counter private _giftCounter;

    mapping(address => bool) public minterList;

    uint256 MAX_SUPPLY = 275; // hard cap
    
    /// Public mint supply (maximum)
    uint256 MAX_PUBLIC_SUPPLY = 250;

    /// Gift supply (maximum)
    uint256 MAX_GIFT_SUPPLY = 25; 

    /// An array for free content NFTs provided by RatKingSociety
    address[] listContentNFT;

    // Base URI of RatKing NFTs
    string private _baseURIextended;

    event RatKingMinted();
    event RatKingGifted();
    event WithdrawBalance(uint256 balance);
    event WithdrawERC20(uint256 balance);

    constructor() ERC721("RatKing", "RatKing") {

        _baseURIextended = "ipfs://bafybeifibgdydklbkw6odo3lmq6oaxhxx3lda6aaexeywkg327y3ozpnwq/";

    }

    /**
    * @notice Sets the (IPFS) URI of RatKing NFTs
    * @param baseURI_ is the (IPFS) URI for RatKing NFTs
    */
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    /**
    * @notice Gets the (IPFS) URL of RatKing NFTs
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
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
    * @notice Minting of the RatKing NFTs
    */
    function mintRatKing() public whenNotPaused {
        //require(minterList[msg.sender] == false, Errors.RatKingAlreadyMinted());
        if (minterList[msg.sender] == true) revert Errors.RatKingAlreadyMinted();
        //require(_publicMintCounter.current() < MAX_PUBLIC_SUPPLY, "Public Mint Limit reached" );
        if (_publicMintCounter.current() >= MAX_PUBLIC_SUPPLY) revert Errors.MaximumPublicSupplyLimitReached();
        safeMint(msg.sender);
        minterList[msg.sender] = true;
        _publicMintCounter.increment();

        emit RatKingMinted();

    }

    /**
    * @notice Minting (airdropping) of the RatKing NFTs by the owner
    * @param to is an array of address to be airdropped with RatKing NFTs
    */
    function giftRatKing(address[] memory to) public onlyOwner {

        //require(to.length + _giftCounter.current() <= MAX_GIFT_SUPPLY, "Limit reached.");
        if (to.length + _giftCounter.current() >= MAX_GIFT_SUPPLY) revert Errors.MaximumGiftSupplyLimitReached();
        for(uint i=0; i<to.length; i++) {
            safeMint(to[i]);
            minterList[to[i]] = true;
            _giftCounter.increment();
        }
        emit RatKingGifted();
    }


    function safeMint(address to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /**
    * @notice Adds the address of the free content NFTs provided by RatKingSociety
    * @param contentNFT is an array of address of free content NFTs.
    */
    function addContentNFT(address[] memory contentNFT) public onlyOwner {
        for(uint i=0; i<contentNFT.length; i++) {
            listContentNFT.push(contentNFT[i]);
        }
    }

    /**
    * @notice Gets the array of addresses of the free content NFTs provided by RatKingSociety
    */
    function getContentNFTList() public view returns (address[] memory) {
        return listContentNFT;
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

    /**
    * @notice Function required to override by DefaultOperatorFilterer
    */
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
    
    function withdrawERC20(address erc20TokenContract) public onlyOwner nonReentrant {
        IERC20 tokenContract = IERC20(erc20TokenContract);
        //tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));

        (bool success, ) = payable(owner()).call{value: tokenContract.balanceOf(address(this))}('');
        require(success,"Transfer failed!");

        emit WithdrawERC20(address(this).balance);
    }
    
}
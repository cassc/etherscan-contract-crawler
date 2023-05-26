// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721EnumerableLemon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

/**
 *
 * ###############################################################################
 * ###############################################################################
 * #############################(,...............)################################
 * #######################*,,,............................########################
 * ###################,,,,,..................................#####################
 * ################*,,,,.......................................(##################
 * ###############,,,,...........................................(################
 * #############,,,,,..............................................###############
 * ###########/,,,,...................LITTLE.........................#############
 * ##########,,,,,,......................................................#########
 * ######,,,,,,,,,.....................LEMON................................(#####
 * ####,,,,,,,,,,.............................................................####
 * ###,,,,,,,,,,,.....................FRIENDS................................#####
 * ####,,,,,,,,,,,.........................................................#######
 * #########(,,,,,....................ADOPTION..........................(#########
 * ###########*,,,,...................................................############
 * #############,,,,...................CENTER........................#############
 * ##############(,,,,.............................................###############
 * ################,,,,,.........................................,################
 * ###################,,,,......................................(#################
 * #####################,,,,,................................,####################
 * #######################(,,,...........................#########################
 * #############################(.................)###############################
 * ###############################################################################
 *                              created by sonirious
 *
 * @title Little Lemon Friends ERC-721 Smart Contract
 */

abstract contract CollectionContract {
   function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract LittleLemonFriends is ERC721EnumerableLemon, Ownable, Pausable, ReentrancyGuard {

    string public LITTLELEMONFRIENDS_PROVENANCE = "";
    string private baseURI;
    uint256 public numTokensMinted = 0;
    uint256 public numBurnedTokens = 0;
    uint256 public constant MAX_MINTS_PER_WALLET = 15;
    uint256 public constant MAX_TOKENS = 9999;

    // PUBLIC MINT
    uint256 public constant MAX_TOKENS_PUBLIC_MINT = 9799; 
    uint256 public constant TOKEN_PRICE = 25000000000000000; // 0.025 ETH
    uint256 public constant MAX_TOKENS_PURCHASE = 5;
    bool public mintIsActive = false;

    // WALLET BASED PRESALE MINT
    bool public presaleIsActive = false;
    mapping (address => bool) public presaleWalletList;

    // COLLECTIONS PRESALE
    CollectionContract private coolcats = CollectionContract(0x1A92f7381B9F03921564a437210bB9396471050C);
    CollectionContract private toyboogers = CollectionContract(0xBF662A0e4069b58dFB9bceBEBaE99A6f13e06f5a);
    uint256 public constant MAX_TOKENS_PURCHASE_PRESALE = 2;
    uint256 public collectionPresaleNumTokenMinted = 0;
    uint256 public constant MAX_COLLECTION_PRESALE_TOKENS = 4000;
    bool public collectionPresaleIsActive = false;
    mapping (address => bool) public collectionWalletsMinted;

    constructor() ERC721("Little Lemon Friends", "LEMON") {}

    // PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function mintLemons(uint256 numberOfTokens) external payable nonReentrant{
        require(mintIsActive, "Mint is not active");
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_MINTS_PER_WALLET, 
            "You can only mint 15 total lemons per wallet."
        );
        require(
            numberOfTokens <= MAX_TOKENS_PURCHASE, 
            "You went over max tokens per transaction"
        );
        require(
            numTokensMinted + numberOfTokens <= MAX_TOKENS_PUBLIC_MINT, 
            "Not enough tokens left to mint that many"
        );
        require(
            TOKEN_PRICE * numberOfTokens <= msg.value, 
            "You sent the incorrect amount of ETH"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            if (numTokensMinted < MAX_TOKENS_PUBLIC_MINT) {
                numTokensMinted++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // WALLET BASED PRESALE
    function flipPresaleState() external onlyOwner {
	    presaleIsActive = !presaleIsActive;
    }

    function initPresaleWalletList(address[] memory walletList) external onlyOwner {
	    for (uint256 i = 0; i < walletList.length; i++) {
		    presaleWalletList[walletList[i]] = true;
	    }
    }

    function mintPresale(uint256 numberOfTokens) external payable nonReentrant{
        require(presaleIsActive, "Presale is not active");
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_MINTS_PER_WALLET, 
            "You can only mint 15 total lemons per wallet."
        );
	    require(
            presaleWalletList[msg.sender] == true, 
            "You are not on the presale wallet list or have already minted"
        );
	    require(
            numberOfTokens <= MAX_TOKENS_PURCHASE, 
            "You went over max tokens per transaction"
        );
	    require(
            numTokensMinted + numberOfTokens <= MAX_TOKENS_PUBLIC_MINT, 
            "Not enough tokens left to mint that many"
        );
	    require(
            TOKEN_PRICE * numberOfTokens <= msg.value, 
            "You sent the incorrect amount of ETH"
        );

	    for (uint256 i = 0; i < numberOfTokens; i++) {
		    uint256 mintIndex = numTokensMinted;
		    if (numTokensMinted < MAX_TOKENS_PUBLIC_MINT) {
			    numTokensMinted++;
			    _safeMint(msg.sender, mintIndex);
		    }
	    }

	    presaleWalletList[msg.sender] = false;
    }

    // NFT COLLECTION PRESALE
    function flipCollectionPresaleMintState() external onlyOwner {
        collectionPresaleIsActive = !collectionPresaleIsActive;
    }

    function qualifyForCollectionPresaleMint(address _owner) external view returns (bool) {
        return coolcats.balanceOf(_owner) > 0 || toyboogers.balanceOf(msg.sender) > 0;
    }

    function mintCollectionPresale(uint256 numberOfTokens) external payable nonReentrant{
        require(collectionPresaleIsActive, "NFT Collection Mint is not active");
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_MINTS_PER_WALLET, 
            "You can only mint 15 total lemons per wallet."
        );
        require(collectionWalletsMinted[msg.sender] == false, "You have already minted!");
        require(
            coolcats.balanceOf(msg.sender) > 0 || toyboogers.balanceOf(msg.sender) > 0, 
            "You are not a member of Coolcats or ToyBoogers!"
        );
        require(
            numberOfTokens <= MAX_TOKENS_PURCHASE_PRESALE,
            "You went over max tokens per transaction"
        );
	    require(
            collectionPresaleNumTokenMinted + numberOfTokens <= MAX_COLLECTION_PRESALE_TOKENS, 
            "Collection Presale is over"
        );
        require(
            numTokensMinted + numberOfTokens <= MAX_TOKENS_PUBLIC_MINT, 
            "Not enough tokens left to mint that many"
        );
        require(
            TOKEN_PRICE * numberOfTokens <= msg.value, 
            "You sent the incorrect amount of ETH."
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
		    uint256 mintIndex = numTokensMinted;
		    if (numTokensMinted < MAX_TOKENS_PUBLIC_MINT) {
			    numTokensMinted++;
                collectionPresaleNumTokenMinted++;
			    _safeMint(msg.sender, mintIndex);
		    }
	    }

        collectionWalletsMinted[msg.sender] = true;
    }

    // BURN IT 
    function burn(uint256 tokenId) external virtual {
	    require(
            _isApprovedOrOwner(_msgSender(), tokenId), 
            "ERC721Burnable: caller is not owner nor approved"
        );
        numBurnedTokens++;
	    _burn(tokenId);
    }

    // TOTAL SUPPLY
    function totalSupply() external view returns (uint) { 
        return numTokensMinted - numBurnedTokens;
    }

    // OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function reserveTokens(uint256 numberOfTokens) external onlyOwner {
        require(
            numTokensMinted + numberOfTokens <= MAX_TOKENS, 
            "Not enough tokens left to mint that many"
        );
	
         for (uint256 i = 0; i < numberOfTokens; i++) {
		    uint256 mintIndex = numTokensMinted;
		    numTokensMinted++;
		    _safeMint(msg.sender, mintIndex);
	    }
    }

    function setPaused(bool _setPaused) external onlyOwner {
	    return (_setPaused) ? _pause() : _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        LITTLELEMONFRIENDS_PROVENANCE = provenanceHash;
    }

    // Toggle this function if pausing should suspend transfers
    function _beforeTokenTransfer(
	    address from,
	    address to,
	    uint256 tokenId
    ) internal virtual override(ERC721EnumerableLemon) {
	    require(!paused(), "Pausable: paused");
	    super._beforeTokenTransfer(from, to, tokenId);
    }
}
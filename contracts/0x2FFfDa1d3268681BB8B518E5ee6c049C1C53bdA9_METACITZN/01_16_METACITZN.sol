// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

//        __  __ ______ _______       _____ _____ _______ _______   _ 
//       |  \/  |  ____|__   __|/\   / ____|_   _|__   __|___  / \ | |
//       | \  / | |__     | |  /  \ | |      | |    | |     / /|  \| |
//       | |\/| |  __|    | | / /\ \| |      | |    | |    / / | . ` |
//       | |  | | |____   | |/ ____ \ |____ _| |_   | |   / /__| |\  |
//       |_|  |_|______|  |_/_/    \_\_____|_____|  |_|  /_____|_| \_|
//   ______                                                           
//  |______|                                                          

/**
 * @title _METACITZN ERC-721 Smart Contract
 */

contract METACITZN is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {

    string public METACITZN_PROVENANCE = "";
    string private baseURI;

    // IDs 0 - 8499: CITZN Coin
    // IDs 8500 - 9999: CITZN_x Coin
    // IDs 10000 - 10499: CITZ_k Coin

    // CITZN Token
    uint256 public cITZNTokenPrice = 200000000000000000;
    uint256 public cITZNTokenMintIndex = 0;
    uint256 public constant MAX_CITZN_TOKENS = 8500;
    uint256 public segmentMaxCITZN = 1700;
    uint256 public burnedCITZNTokens = 0;

    // CITZN X Token
    uint256 public cITZNXTokenPrice = 360000000000000000;
    uint256 public cITZNXTokenMintIndex = 8500;
    uint256 public constant MAX_CITZNX_TOKENS = 10000;
    uint256 public segmentMaxCITZNX = 8800;
    uint256 public burnedCITZNXTokens = 0;
  
    // CITZNX K Token
    uint256 public cITZNKTokenMintIndex = 10000;
    uint256 public constant MAX_CITZNK_TOKENS = 10500;
    uint256 public burnedCITZNKTokens = 0;

    // PUBLIC MINT
    uint256 public maxTokensPurchase = 3;
    uint256 public totalAllowedToMint = 12;
    bool public mintIsActive = false;

    // WALLET BASED PRESALE MINT
    bool public presaleIsActive = false;
    enum PresaleMintStatus { NotUsed, NotMinted, MintedCITZN, MintedCITZNX, MintedBoth}
    mapping (address => PresaleMintStatus) public presaleWalletList;

    constructor() ERC721("CITZN", "CITZN") {}


    // PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    // CITZN PUBLIC MINT
    function mintCITZN(uint256 numberOfTokens) external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
        require(mintIsActive, "Mint is not active.");
        require(balanceOf(msg.sender) <= totalAllowedToMint, "Wallets are restricted to the amount of tokens they can mint");
        require(numberOfTokens <= maxTokensPurchase, "You went over max tokens per transaction.");
        require(cITZNTokenMintIndex + numberOfTokens <= segmentMaxCITZN, "Not enough tokens left to mint in this segment");
        require(cITZNTokenMintIndex + numberOfTokens <= MAX_CITZN_TOKENS, "Not enough tokens left to mint that many");
        require(cITZNTokenPrice * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = cITZNTokenMintIndex;
            if (mintIndex < MAX_CITZN_TOKENS) {
                cITZNTokenMintIndex++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // CITZN_x PUBLIC MINT
    function mintCITZNX(uint256 numberOfTokens) external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
        require(mintIsActive, "Mint is not active.");
        require(balanceOf(msg.sender) <= totalAllowedToMint, "Wallets are restricted to the amount of tokens they can mint");
        require(numberOfTokens <= maxTokensPurchase, "You went over max tokens per transaction.");
        require(cITZNXTokenMintIndex + numberOfTokens <= segmentMaxCITZNX, "Not enough tokens left to mint in this segment");
        require(cITZNXTokenMintIndex + numberOfTokens <= MAX_CITZNX_TOKENS, "Not enough tokens left to mint that many");
        require(cITZNXTokenPrice * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = cITZNXTokenMintIndex;
            if (mintIndex < MAX_CITZNX_TOKENS) {
                cITZNXTokenMintIndex++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // WALLET BASED PRESALE

    function flipPresaleState() external onlyOwner {
	    presaleIsActive = !presaleIsActive;
    }

    // add wallets to presale wallet list
    function initPresaleWalletList(address[] memory walletList) external onlyOwner {
	    for (uint i; i < walletList.length; i++) {
		    presaleWalletList[walletList[i]] = PresaleMintStatus.NotMinted;
	    }
    }

    // CITZN PRESALE
    function mintPresaleOneCITZN() external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
	    require(presaleIsActive, "Presale is not active");
	    require(
            presaleWalletList[msg.sender] == PresaleMintStatus.NotMinted || presaleWalletList[msg.sender] == PresaleMintStatus.MintedCITZNX, 
            "You are not on the presale wallet list or have already minted"
        );
	    require(cITZNTokenMintIndex < segmentMaxCITZN, "Not enough tokens left to mint in this segment");
        require(cITZNTokenMintIndex < MAX_CITZN_TOKENS, "Not enough tokens left to mint");
	    require(cITZNTokenPrice <= msg.value, "You sent the incorrect amount of ETH.");

        uint256 mintIndex = cITZNTokenMintIndex;
        cITZNTokenMintIndex++;
        _safeMint(msg.sender, mintIndex);

	    if (presaleWalletList[msg.sender] == PresaleMintStatus.NotMinted) {
            presaleWalletList[msg.sender] = PresaleMintStatus.MintedCITZN;
        } else {
            presaleWalletList[msg.sender] = PresaleMintStatus.MintedBoth;
        }
    }

    // CITZN_x PRESALE
    function mintPresaleOneCITZNX() external payable nonReentrant{
        require(!paused(), "Pausable: paused"); // Toggle if pausing should suspend minting
	    require(presaleIsActive, "Presale is not active");
	    require(
            presaleWalletList[msg.sender] == PresaleMintStatus.NotMinted || presaleWalletList[msg.sender] == PresaleMintStatus.MintedCITZN, 
            "You are not on the presale wallet list or have already minted"
        );
	    require(cITZNXTokenMintIndex < segmentMaxCITZNX, "Not enough tokens left to mint in this segment");
	    require(cITZNXTokenMintIndex < MAX_CITZNX_TOKENS, "Not enough tokens left to mint");
	    require(cITZNXTokenPrice <= msg.value, "You sent the incorrect amount of ETH.");

        uint256 mintIndex = cITZNXTokenMintIndex;
        cITZNXTokenMintIndex++;
        _safeMint(msg.sender, mintIndex);

        if (presaleWalletList[msg.sender] == PresaleMintStatus.NotMinted) {
            presaleWalletList[msg.sender] = PresaleMintStatus.MintedCITZNX;
        } else {
            presaleWalletList[msg.sender] = PresaleMintStatus.MintedBoth;
        }
    }

    // RESERVE MINT

    // CITZN RESERVE MINT
    function reserveMintCITZN(uint256 numberOfTokens) external onlyOwner {
        require(cITZNTokenMintIndex + numberOfTokens <= MAX_CITZN_TOKENS, "Not enough tokens left to mint that many");
	
        uint256 mintIndex = cITZNTokenMintIndex;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            cITZNTokenMintIndex++;
            _safeMint(msg.sender, mintIndex + i);
        }
    }

    // CITZN_x RESERVE MINT
    function reserveMintCITZNX(uint256 numberOfTokens) external onlyOwner {
        require(cITZNXTokenMintIndex + numberOfTokens <= MAX_CITZNX_TOKENS, "Not enough tokens left to mint that many");

        uint256 mintIndex = cITZNXTokenMintIndex;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            cITZNXTokenMintIndex++;
            _safeMint(msg.sender, mintIndex + i);
        }
    }

    // CITZN_k RESERVE MINT
     function reserveMintCITZNK(uint256 numberOfTokens) external onlyOwner {
        require(cITZNKTokenMintIndex + numberOfTokens <= MAX_CITZNK_TOKENS, "Not enough tokens left to mint that many");
	
        uint256 mintIndex = cITZNKTokenMintIndex;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            cITZNKTokenMintIndex++;
            _safeMint(msg.sender, mintIndex + i);
        }
    }

    // BURN IT 
    function burn(uint256 tokenId) external virtual {
	    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        require(tokenId >= 0 && tokenId < MAX_CITZNK_TOKENS, "Not a valid token ID");

        if (tokenId <  MAX_CITZN_TOKENS) {
            burnedCITZNTokens++;
        } else if (tokenId < MAX_CITZNX_TOKENS) {
            burnedCITZNXTokens++;
        } else {
            burnedCITZNKTokens++;
        }

	    _burn(tokenId);
    }

    // IDENTIFY TOKEN TYPE
     function getTokenType(uint256 tokenId) external pure returns (string memory) { 
        require(tokenId >= 0 && tokenId < MAX_CITZNK_TOKENS, "Not a valid token ID");
        if (tokenId <  MAX_CITZN_TOKENS) {
            return "CITZN";
        } else if (tokenId < MAX_CITZNX_TOKENS) {
            return "CITZNX";
        } else {
            return "CITZNK";
        }
    }

    // Get Total Supply of Tokens
    function getTotalSupplyCITZNToken() external view returns (uint256) {
        return cITZNTokenMintIndex - burnedCITZNTokens;
    }

    function getTotalSupplyCITZNXToken() external view returns (uint256) {
        return cITZNXTokenMintIndex - MAX_CITZN_TOKENS - burnedCITZNXTokens;
    }

    function getTotalSupplyCITZNKToken() external view returns (uint256) {
        return cITZNKTokenMintIndex - MAX_CITZNX_TOKENS - burnedCITZNKTokens;
    }

    // OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function setMintSegments(uint256 segmentCITZN, uint256 segmentCITZNX) external onlyOwner {
        require(segmentCITZN > 0, "Must be greater then zer0");
        require(segmentCITZNX > 0, "Must be greater then zer0");

        segmentMaxCITZN = segmentCITZN;
        segmentMaxCITZNX = segmentCITZNX;
    }

    function setCITZNTokenPrice(uint256 tokenPrice) external onlyOwner {
        require(tokenPrice >= 0, "Must be greater then zer0");
        cITZNTokenPrice = tokenPrice;
    }

    function setCITZNXTokenPrice(uint256 tokenPrice) external onlyOwner {
        require(tokenPrice >= 0, "Must be greater then zer0");
        cITZNXTokenPrice = tokenPrice;
    }

    function setTotalAllowedToMint(uint256 numAllowed) external onlyOwner {
        totalAllowedToMint = numAllowed;
    }

    function setMaxTokensPurchase(uint256 maxNum) external onlyOwner {
        maxTokensPurchase = maxNum;
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
        METACITZN_PROVENANCE = provenanceHash;
    }

    // Toggle this function if pausing should suspend transfers
    function _beforeTokenTransfer(
	    address from,
	    address to,
	    uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
	    require(!paused(), "Pausable: paused");
	    super._beforeTokenTransfer(from, to, tokenId);
    }
}
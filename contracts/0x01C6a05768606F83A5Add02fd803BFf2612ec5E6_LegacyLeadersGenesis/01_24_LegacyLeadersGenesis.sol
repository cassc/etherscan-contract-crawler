// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@paperxyz/contracts/verification/PaperVerification.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./ERC721EnumerableChaos.sol";

/**
 * @title Legacy Leaders Genesis ERC-721 Smart Contract
 */

contract LegacyLeadersGenesis is ERC721EnumerableChaos, Ownable, ReentrancyGuard, PaperVerification, PaymentSplitter {

    uint128 public constant MAX_TOKENS_PURCHASE = 3;
    uint128 public constant MAX_TOKENS_PURCHASE_PRESALE = 2;
    uint256 public constant MAX_TOKENS = 1111;
    uint256 public numTokensMinted = 0;
    uint256 public tokenPrice = 500000000000000000;
    uint256 public tokenPricePresale = 400000000000000000;
    bool public mintIsActive = false;
    bool public mintIsActivePresale = false;
    mapping (address => uint256) public presaleMerkleWalletList;
    bytes32 public presaleMerkleRoot;
    string public LEGACYLEADERSGENESIS_PROVENANCE = "";
    string private baseURI;

    constructor(address _paperKey, address[] memory _payees, uint256[] memory _shares) 
        ERC721("Legacy Leaders Genesis", "LLG") 
        PaperVerification(_paperKey)
        PaymentSplitter(_payees, _shares) {}

    // PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    /*
    *  @notice public mint function
    */
    function mintGenesis(uint256 numberOfTokens) external payable nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActive, "Mint is not active");
        require(
            numberOfTokens <= MAX_TOKENS_PURCHASE, 
            "You went over max tokens per transaction"
        );
        require(
            numTokensMinted + numberOfTokens <= MAX_TOKENS, 
            "Not enough tokens left to mint that many"
        );
        require(
            tokenPrice * numberOfTokens == msg.value, 
            "You sent the incorrect amount of ETH"
        );
        mint(msg.sender, numberOfTokens);
    }

    // PRESALE WALLET MERKLE MINT

    /*
     * @notice view function to check if a merkleProof is valid before sending presale mint function
     */
    function isOnPresaleMerkle(bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf);
    }

    /*
     * @notice Turn on/off presale wallet mint
     */
    function flipPresaleMintState() external onlyOwner {
        mintIsActivePresale = !mintIsActivePresale;
    }

    /*
     * @notice reset a list of addresses to be able to presale mint again. 
     */
    function initPresaleMerkleWalletList(address[] memory walletList) external onlyOwner {
	    for (uint i; i < walletList.length; i++) {
		    presaleMerkleWalletList[walletList[i]] = 0;
	    }
    }

    /*
     * @notice check if address is on presale list
     */
    function checkAddressOnPresaleMerkleWalletList(address wallet) public view returns (uint256) {
	    return presaleMerkleWalletList[wallet];
    }

    /*
     * @notice presale wallet list mint 
     */
    function mintPresaleMerkle(uint256 numberOfTokens, bytes32[] calldata _merkleProof) external payable nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActivePresale, "Presale mint is not active");
        require(
            numberOfTokens <= MAX_TOKENS_PURCHASE_PRESALE, 
            "You went over max tokens per transaction"
        );
        require(
            tokenPricePresale * numberOfTokens == msg.value, 
            "You sent the incorrect amount of ETH"
        );
        require(
            presaleMerkleWalletList[msg.sender] + numberOfTokens <= MAX_TOKENS_PURCHASE_PRESALE, 
            "You can't mint that many tokens."
        );
        require(
            numTokensMinted + numberOfTokens <= MAX_TOKENS, 
            "Not enough tokens left to mint that many"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf), "Invalid Proof");       
        presaleMerkleWalletList[msg.sender] += numberOfTokens;

        mint(msg.sender, numberOfTokens);
    }

    /*
    *  @notice get token ids by wallet
    */
    function tokenIdsByWallet(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    /*
    *  @notice get total supply
    */
    function totalSupply() external view returns (uint) { 
        return numTokensMinted;
    }

    /*
     * @notice internal mint function
     */
    function mint(address to, uint256 qty) private {
        for (uint256 i = 0; i < qty; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(to, mintIndex);
        }
    } 

    // OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /*
    *  @notice reserve mint n number of tokens
    */
    function mintReserveTokens(uint256 numberOfTokens) public onlyOwner {       
        require(numTokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");

        mint(msg.sender, numberOfTokens);
    }

    /*
    *  @notice reserve mint a token to a wallet
    */
    function mintTokenToWallet(address toWallet, uint256 numberOfTokens) public onlyOwner {
        require(numTokensMinted + numberOfTokens <= MAX_TOKENS, "Not enough tokens left to mint that many");

        mint(toWallet, numberOfTokens);
    }

    /*
    *  @notice get base URI of tokens
    */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
   
    /* 
    *  @notice set base URI of tokens
    */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        LEGACYLEADERSGENESIS_PROVENANCE = provenanceHash;
    }

    /*
    *  @notice set token price of sale - tokenPrice
    */
    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        require(_tokenPrice >= 0, "Must be greater or equal then zer0");
        tokenPrice = _tokenPrice;
    }

    /*
    *  @notice set token presale price - tokenPricePresale
    */
    function setTokenPricePresale(uint256 _tokenPrice) external onlyOwner {
        require(_tokenPrice >= 0, "Must be greater or equal then zer0");
        tokenPricePresale = _tokenPrice;
    }

    /*
    * @notice set Merkle Root for presale
    */
    function setMerkleRoot(bytes32 _presaleMerkleRoot) public onlyOwner {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

    /*
    *  @notice withdraw eth from contract by wallet
    */
    function releaseETH(address payable account) public {
        require(msg.sender == account || msg.sender == owner(), "Release: no permission");

        release(account);
    }

    // Paper.xyz Mint
    /*
    * @dev Used after a user completes a fiat or cross chain crypto payment by paper's backend to mint a new token for user.
    * Should _not_ have price check if you intend to off ramp in Fiat or if you want dynamic pricing.
    * Enables custom metadata to be passed to the contract for whitelist, custom params, etc. via bytes data
    * @param _mintData Contains information on the tokenId, quantity, recipient and more.
    */
    function paperMint(PaperMintData.MintData calldata _mintData)
        external
        payable
        onlyPaper(_mintData)
        nonReentrant
    {
        require(mintIsActive, "Mint is not active");
        require(_mintData.quantity <= MAX_TOKENS_PURCHASE, "You went over max tokens per transaction");
        require(numTokensMinted + _mintData.quantity <= MAX_TOKENS, "Not enough tokens left to mint that many");
        mint(_mintData.recipient, _mintData.quantity);
    }
    /*
    * @dev used for native minting on Paper platform.
    * Also used if you don't intend to take advantage of the Fiat or Cross Chain Crypto features in the paperMint method.
    * @param _recipient address of the recipient
    * @param _quantity quantity of the token to mint
    */
    function claimTo(address _recipient, uint256 _quantity)
        external
        payable
        nonReentrant
    {
        require(mintIsActive, "Mint is not active");
        require(_quantity <= MAX_TOKENS_PURCHASE, "You went over max tokens per transaction");
        require(numTokensMinted +_quantity <= MAX_TOKENS, "Not enough tokens left to mint that many");
        require(tokenPrice * _quantity <= msg.value, "You sent the incorrect amount of ETH");

        mint(_recipient, _quantity);
    }

    /*
    * @dev  Paper platform required function
    */
    function getClaimIneligibilityReason(address _userWallet, uint256 _quantity)
        external
        view
        returns (string memory)
    {
        // todo: add your error reasons here.
        if (!mintIsActive) {
            return "Not live yet";
        } else if (_quantity > MAX_TOKENS_PURCHASE) {
            return "max mint amount per transaction exceeded";
        } else if (numTokensMinted + _quantity > MAX_TOKENS) {
            return "not enough supply";
        }
        return "";
    }

    /* @notice Checks the price of the NFT
    *
    * @return uint256 The price of a single NFT in Wei
    */
    function price() public view returns (uint256) {
        return tokenPrice;
    }

    /*
    * @dev  Paper platform required function
    */
    function unclaimedSupply() external view returns (uint256) {
        return MAX_TOKENS - numTokensMinted;
    }

    /*
    * @dev  Paper platform required function
    */
    function setPaperKey(address _paperKey) external onlyOwner {
        _setPaperKey(_paperKey);
    }
}
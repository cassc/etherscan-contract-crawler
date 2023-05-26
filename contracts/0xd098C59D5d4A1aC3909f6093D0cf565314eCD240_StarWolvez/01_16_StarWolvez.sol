// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721EnumerableChaos.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'~~~     ~~~`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@'                     `@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@'                           `@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@'                               `@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@'                                   `@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@'                                     `@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@'                                       `@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@'                                         `@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@                     _/ | _                @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@                    /'  `'/                @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@a                 <~    .'                [email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@                 .'    |                 @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@a              _/      |                [email protected]@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@a           _/      `.`.              [email protected]@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@a     ____/ '   \__ | |______       [email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@a__/___/      /__\ \ \     \[email protected]@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@/  (___.'\_______)\_|_|        \@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@|\________                       ~~~~~\@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@||       |\___________________________/|@/~~~~~~~~~~~\@@@
 */

/**
 * @title Star Wolvez ERC-721 Smart Contract
 */

contract StarWolvez is ERC721EnumerableChaos, Ownable, Pausable, ReentrancyGuard {

    string public STARWOLVEZ_PROVENANCE = "";
    string private baseURI;
    uint256 public constant MAX_TOKENS = 8980 + 2; // 8980 max tokens +2 is for gas optimization
    uint256 public mintingTokenIndex = 101;
    uint256 public numTokensMinted = 0;
    uint256 public numTokensBurned = 0;
    uint256 public tokenPrice = 0.0888 ether; 

    // PUBLIC MINT
    uint256 public constant MAX_TOKENS_PURCHASE = 4; // 3 max per transaction +1 is for gas optimization
    bool public mintIsActive = false;

    // PRESALE MERKLE MINT
    uint256 public maxTokensPurchasePresale = 6; // 5 max per transaction +1 is for gas optimization
    bool public mintIsActivePresale = false;
    mapping (address => bool) public presaleMerkleWalletList;
    bytes32 public presaleMerkleRoot;

    constructor() ERC721("Star Wolvez", "SW") {}

    // @title PUBLIC MINT
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    /**
    *  @notice public mint function
    */
    function mint(uint256 numberOfTokens) external payable nonReentrant{
        require(tx.origin == msg.sender);
        require(!paused(), "Pausable: paused"); 
        require(mintIsActive, "Mint is not active");
        require(
            numberOfTokens < MAX_TOKENS_PURCHASE, 
            "You went over max tokens per transaction"
        );
        require(
            mintingTokenIndex + numberOfTokens < MAX_TOKENS, 
            "Not enough tokens left to mint that many"
        );
        require(
            msg.value >= tokenPrice * numberOfTokens, 
            "You sent the incorrect amount of ETH"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = mintingTokenIndex;
            mintingTokenIndex++;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    //  @title PRESALE WALLET MERKLE MINT

    /**
     * @notice view function to check if a merkleProof is valid before sending presale mint function
     */
    function isOnPresaleMerkle(bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf);
    }

    /**
     * @notice Turn on/off presale wallet mint
     */
    function flipPresaleMintState() external onlyOwner {
        mintIsActivePresale = !mintIsActivePresale;
    }

    /**
     * @notice reset a list of addresses to be able to presale mint again. 
     */
    function initPresaleMerkleWalletList(address[] memory walletList) external onlyOwner {
	    for (uint i = 0; i < walletList.length; i++) {
		    presaleMerkleWalletList[walletList[i]] = false;
	    }
    }

    /**
     * @notice check status of wallet on presale list: true = wallet minted
     */
    function checkAddressOnPresaleMerkleWalletList(address wallet) public view returns (bool) {
	    return presaleMerkleWalletList[wallet];
    }

    /**
     * @notice Presale wallet list mint 
     */
    function mintPresaleMerkle(uint256 numberOfTokens, bytes32[] calldata _merkleProof) external payable nonReentrant{
        require(tx.origin == msg.sender);
        require(mintIsActivePresale, "Presale mint is not active");
        require(
            numberOfTokens < maxTokensPurchasePresale, 
            "You went over max tokens allowed to mint"
        );
        require(
	        msg.value >= tokenPrice * numberOfTokens,
            "You sent the incorrect amount of ETH"
        );
        require(
            presaleMerkleWalletList[msg.sender] == false, 
            "You are not on the presale wallet list or have already minted"
        );
        require(
            mintingTokenIndex + numberOfTokens < MAX_TOKENS, 
            "Not enough tokens left to mint that many"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf), "Invalid Proof");
        presaleMerkleWalletList[msg.sender] = true;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = mintingTokenIndex;
            mintingTokenIndex++;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
    *  @notice  burn token id
    */
    function burn(uint256 tokenId) public virtual {
	    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
	    numTokensBurned++;
        _burn(tokenId);
    }

    /**
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

    /**
    *  @notice get total supply
    */
    function totalSupply() external view returns (uint) { 
        return numTokensMinted - numTokensBurned;
    }

    // @title OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /**
    *  @notice reserve mint x number of tokens
    */
    function mintReserveTokens(uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = mintingTokenIndex;
            mintingTokenIndex++;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
    *  @notice mint a token to a wallet
    */
    function mintTokenToWallet(address toWallet, uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = mintingTokenIndex;
            mintingTokenIndex++;
            numTokensMinted++;
            _safeMint(toWallet, mintIndex);
        }
    }

    /**
    *  @notice mint a genesis token id to a wallet
    */
    function mintTokenIdToWallet(address toWallet, uint256 tokenId) public onlyOwner { 
        require(tokenId < 101, "Not a genesis token id");
        numTokensMinted++;
        _safeMint(toWallet, tokenId);
    }

    /**
    *  @notice get base URI of tokens
    */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // @title SETTER FUNCTIONS

    function setPaused(bool _setPaused) external onlyOwner {
	    return (_setPaused) ? _pause() : _unpause();
    }

    /** 
    *  @notice set base URI of tokens
    */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        STARWOLVEZ_PROVENANCE = provenanceHash;
    }

    /**
    *  @notice Set token price of public sale - tokenPrice
    */
    function setTokenPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    /**
    *  @notice Set max tokens per transaction for presale - maxTokensPurchasePresale 
    */
    function setMaxTokensPurchasePresale(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount");
        maxTokensPurchasePresale = amount;
    }

    /**
    * @notice sets Merkle Root and Max Allowed to mint for presale wave - Add +1 to amount
    */
    function setPresaleWave(bytes32 _presaleMerkleRoot, uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount");   
        presaleMerkleRoot = _presaleMerkleRoot;
        maxTokensPurchasePresale = amount;
    }

    /**
     * @notice sets Merkle Root for presale
     */
    function setMerkleRoot(bytes32 _presaleMerkleRoot) public onlyOwner {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

    // Toggle this function if pausing should suspend transfers
    function _beforeTokenTransfer(
	    address from,
	    address to,
	    uint256 tokenId
    ) internal virtual override(ERC721EnumerableChaos) {
	    require(!paused(), "Pausable: paused");
	    super._beforeTokenTransfer(from, to, tokenId);
    }
}
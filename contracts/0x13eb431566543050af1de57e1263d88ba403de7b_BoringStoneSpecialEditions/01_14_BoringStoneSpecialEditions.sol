// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title BoringStone Special Editions ERC1155 Smart Contract
 * @dev Extends ERC1155 
 */

contract BoringStoneSpecialEditions is ERC1155, ERC1155Supply, ERC1155Burnable, Ownable, ReentrancyGuard {
    string private _contractURI;
    address public minterAddress;
    string _name = "BS Special Editions";
    string _symbol = "BSSE";
    uint256 public mintingTokenID = 0;
    uint256 public numberMintedTotal = 0;
    uint256 public maxTokens = 1000;

    /// PUBLIC MINT
    uint256 public tokenPricePublic = 0.00 ether;
    bool public mintIsActivePublic = false;
    uint256 public maxTokensPerTransactionPublic = 1;
    uint256 public numberMintedPublic = 0;
    uint256 public maxTokensPublic  = 2;

    // PRESALE MINT
    uint256 public tokenPricePresale = 0.00 ether;
    bool public mintIsActivePresale = false;
    uint256 public maxTokensPerTransactionPresale = 1;
    uint256 public numberMintedPresale = 0;
    uint256 public maxTokensPresale = 1000;

    // FREE WALLET BASED MINT
    bool public mintIsActiveFree = false;
    uint256 public numberFreeToMint = 1;
    mapping (address => bool) public freeWalletList;

    // PRESALE MERKLE MINT
    mapping (uint256 => mapping (address => bool) ) public presaleMerkleWalletList;
    bytes32 public presaleMerkleRoot;


    constructor() ERC1155("") {}

    // PUBLIC MINT

    /**
     * @notice turn on/off public mint
     */
    function flipMintStatePublic() external onlyOwner {
        mintIsActivePublic = !mintIsActivePublic;
    }

    /**
     * @notice Public mint function
     */
    function mint(uint256 numberOfTokens) external payable nonReentrant {
        require(mintIsActivePublic, "Public mint is not active");
        require(
            numberOfTokens <= maxTokensPerTransactionPublic, 
            "You went over max tokens per transaction"
        );
        require(
	        msg.value >= tokenPricePublic * numberOfTokens,
            "You sent the incorrect amount of ETH"
        );
        require(
            numberMintedPublic + numberOfTokens <= maxTokensPublic, 
            "Not enough tokens left to mint that many"
        );
        require(
            numberMintedTotal + numberOfTokens <= maxTokens, 
            "Not enough tokens left to mint that many"
        );

        numberMintedPublic += numberOfTokens;
        numberMintedTotal += numberOfTokens;
        _mint(msg.sender, mintingTokenID, numberOfTokens, "");
    }

    //  PRESALE WALLET MERKLE MINT

    /**
    * @notice sets Merkle Root for presale
    */
    function setMerkleRoot(bytes32 _presaleMerkleRoot) public onlyOwner {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

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
     * @notice deprecated - but useful to reset a list of addresses to be able to presale mint again. 
     */
    function initPresaleMerkleWalletList(address[] memory walletList) external onlyOwner {
	    for (uint i; i < walletList.length; i++) {
		    presaleMerkleWalletList[mintingTokenID][walletList[i]] = false;
	    }
    }

    /**
     * @notice check if address is on presale list
     */
    function checkAddressOnPresaleMerkleWalletList(uint256 tokenId, address wallet) public view returns (bool) {
	    return presaleMerkleWalletList[tokenId][wallet];
    }

    /**
     * @notice Presale wallet list mint 
     */
    function mintPresale(uint256 numberOfTokens, bytes32[] calldata _merkleProof) external payable nonReentrant{
        require(mintIsActivePresale, "Presale mint is not active");
        require(
            numberOfTokens <= maxTokensPerTransactionPresale, 
            "You went over max tokens per transaction"
        );
        require(
	        msg.value >= tokenPricePresale * numberOfTokens,
            "You sent the incorrect amount of ETH"
        );
        require(
            !presaleMerkleWalletList[mintingTokenID][msg.sender], 
            "You are not on the presale wallet list or have already minted"
        );
        require(
            numberMintedPresale + numberOfTokens <= maxTokensPresale, 
            "Not enough tokens left to mint that many"
        );
        require(
            numberMintedTotal + numberOfTokens <= maxTokens, 
            "Not enough tokens left to mint that many"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf), "Invalid Proof");
        numberMintedPresale += numberOfTokens;
        numberMintedTotal += numberOfTokens;
        presaleMerkleWalletList[mintingTokenID][msg.sender] = true;

        _mint(msg.sender, mintingTokenID, numberOfTokens, "");
    }

    // Free Wallet Mint

    /**
     * @notice turn on/off free wallet mint
     */
    function flipFreeWalletState() external onlyOwner {
	    mintIsActiveFree = !mintIsActiveFree;
    }

    /**
     * @notice data structure for uploading free mint wallets
     */
    function initFreeWalletList(address[] memory walletList) external onlyOwner {
	    for (uint256 i = 0; i < walletList.length; i++) {
		    freeWalletList[walletList[i]] = true;
	    }
    }

    /**
     * @notice Free mint for wallets in freeWalletList
     */
    function mintFreeWalletList() external nonReentrant {
        require(mintIsActiveFree, "Free mint is not active");
        require(
            numberMintedTotal + numberFreeToMint <= maxTokens, 
            "Not enough tokens left to mint that many"
        );
	    require(
            freeWalletList[msg.sender] == true, 
            "You are not on the free wallet list or have already minted"
        );

        numberMintedTotal += numberFreeToMint;
        freeWalletList[msg.sender] = false;
        _mint(msg.sender, mintingTokenID, numberFreeToMint, "");
    }


    /**
    *  @notice set address of minter for airdrops
    */
    function setMinterAddress(address minter) public onlyOwner {
	    minterAddress = minter;
    }

    modifier onlyMinter {
	    require(minterAddress == msg.sender || owner() == msg.sender, "You must have the Minter role");
	    _;
    }

     /**
    *  @notice mint a collection
    */
    function mintReserve(uint256 amount) public onlyOwner {
        _mint(msg.sender, mintingTokenID, amount, "");
    }

    /**
    *  @notice mint a batch of token collections
    */
    function mintBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyMinter {
        _mintBatch(msg.sender, ids, amounts, "");
    }

    /**
    * @notice airdrop a specific token to a list of addresses
    */

    function airdrop(address[] calldata addresses, uint id, uint amt_each) public onlyMinter {
        for (uint i=0; i < addresses.length; i++) {
            _mint(addresses[i], id, amt_each, "");
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function contractURI() public view returns (string memory) {
	    return _contractURI;
    }


    //  SETTER FUNCTIONS

    /**
    *  @notice set token base uri
    */
    function setURI(string memory baseURI) public onlyMinter {
        _setURI(baseURI);
    }

    /**
    *  @notice set contract uri https://docs.opensea.io/docs/contract-level-metadata
    */
    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }
    
    /**
    *  @notice Set token price of presale - tokenPricePublic
    */
    function setTokenPricePublic(uint256 tokenPrice) external onlyOwner {
        require(tokenPrice >= 0, "Must be greater or equal then zer0");
        tokenPricePublic = tokenPrice;
    }

    /**
    *  @notice Set max tokens allowed minted in public sale - maxTokensPublic
    */
    function setMaxTokens (uint256 amount) external onlyOwner {
        require(amount >= 0, "Must be greater or equal than zer0");
        maxTokens = amount;
    }

    /**
    *  @notice Set total number of tokens minted in public sale - numberMintedPublic
    */
    function setNumberMintedTotal(uint256 amount) external onlyOwner {
        require(amount >= 0, "Must be greater or equal than zer0");
        numberMintedTotal = amount;
    }

    /**
    *  @notice Set max tokens allowed minted in public sale - maxTokensPublic
    */
    function setMaxTokensPublic (uint256 amount) external onlyOwner {
        require(amount >= 0, "Must be greater or equal than zer0");
        maxTokensPublic = amount;
    }

    /**
    *  @notice Set total number of tokens minted in public sale - numberMintedPublic
    */
    function setNumberMintedPublic(uint256 amount) external onlyOwner {
        require(amount >= 0, "Must be greater or equal than zer0");
        numberMintedPublic = amount;
    }

    /**
    *  @notice Set max tokens per transaction for public sale - maxTokensPerTransactionPublic 
    */
    function setMaxTokensPerTransactionPublic(uint256 amount) external onlyOwner {
        require(amount >= 0, "Invalid amount");
        maxTokensPerTransactionPublic = amount;
    }

    /**
    *  @notice Set token price of presale - tokenPricePresale
    */
    function setTokenPricePresale(uint256 tokenPrice) external onlyOwner {
        require(tokenPrice >= 0, "Must be greater or equal than zer0");
        tokenPricePresale = tokenPrice;
    }

    /**
    *  @notice Set max tokens allowed minted in presale - maxTokensPresale
    */
    function setMaxTokensPresale(uint256 amount) external onlyOwner {
        require(amount >= 0, "Invalid amount");
        maxTokensPresale = amount;
    }

    /**
    *  @notice Set total number of tokens minted in presale - numberMintedPresale
    */
    function setNumberMintedPresale(uint256 amount) external onlyOwner {
        require(amount >= 0, "Invalid amount");
        numberMintedPresale = amount;
    }

    /**
    *  @notice Set max tokens per transaction for presale - maxTokensPerTransactionPresale 
    */
    function setMaxTokensPerTransactionPresale(uint256 amount) external onlyOwner {
        require(amount >= 0, "Invalid amount");
        maxTokensPerTransactionPresale = amount;
    }

    /**
    *  @notice Set the current token ID minting - mintingTokenID
    */
    function setMintingTokenID(uint256 tokenID) external onlyOwner {
        require(tokenID >= 0, "Invalid token id");
        mintingTokenID = tokenID;
    }

    /**
    *  @notice Set the current token ID minting and reset all counters and active mints to 0 and false respectively
    */
    function setMintingTokenIdAndResetState(uint256 tokenID) external onlyOwner {
	    require(tokenID >= 0, "Invalid token id");
	    mintingTokenID = tokenID;

	    mintIsActivePublic = false;
	    mintIsActivePresale = false;
	    mintIsActiveFree = false;

        numberMintedTotal = 0;
	    numberMintedPresale = 0;
	    numberMintedPublic = 0;
    }

    /**
     * @notice Withdraw ETH in contract to ownership wallet
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}
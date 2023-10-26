// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/**
 *              _____            ___ _____        _____  __   _____  ___    __
 *   /\/\ /\_/\/__   \/\  /\    /   \\_   \/\   /\\_   \/ _\  \_   \/___\/\ \ \
 *  /    \\_ _/  / /\/ /_/ /   / /\ / / /\/\ \ / / / /\/\ \    / /\//  //  \/ /
 * / /\/\ \/ \  / / / __  /   / /_//\/ /_   \ V /\/ /_  _\ \/\/ /_/ \_// /\  /
 * \/    \/\_/  \/  \/ /_/   /___,'\____/    \_/\____/  \__/\____/\___/\_\ \/
 *
 *     _                        _                      _
 *    / \   _ __ ___   ___ _ __(_) ___ __ _ _ __      / \   _ __   ___
 *   / _ \ | '_ ` _ \ / _ \ '__| |/ __/ _` | '_ \    / _ \ | '_ \ / _ \
 *  / ___ \| | | | | |  __/ |  | | (_| (_| | | | |  / ___ \| |_) |  __/
 * /_/   \_\_| |_| |_|\___|_|  |_|\___\__,_|_| |_| /_/   \_\ .__/ \___|
 *                                                         |_|
 * @title Myth Division American Ape ERC1155 Smart Contract
 * @dev Extends ERC1155 
 */

contract MythDivisionAmericanApe is ERC1155, ERC1155Supply, ERC1155Burnable, Ownable, PaymentSplitter {
    string private _contractURI;
    string _name = "Myth Division American Ape";
    string _symbol = "MDAPE";
    address public minterAddress;
    uint256 public mintingTokenID = 0;
    uint256 public numberMintedTotal = 0;
    uint256 public maxTokens = 500;

    /// PUBLIC MINT
    uint256 public tokenPricePublic = 0.5636 ether;
    bool public mintIsActivePublic = false;
    uint256 public maxTokensPerTransactionPublic = 5;
    uint256 public numberMintedPublic = 0;
    uint256 public maxTokensPublic = 500;

    /// PRESALE MINT
    uint256 public tokenPricePresale = 0.222 ether;
    bool public mintIsActivePresale = false;
    mapping (address => bool) public presaleWalletList;
    uint256 public maxTokensPerTransactionPresale = 1;
    uint256 public numberMintedPresale = 0;
    uint256 public maxTokensPresale = 500;

    /// FREE WALLET BASED MINT
    bool public mintIsActiveFree = false;
    mapping (address => bool) public freeWalletList;

    constructor(address[] memory _payees, uint256[] memory _shares) ERC1155("") PaymentSplitter(_payees, _shares) payable {}

    /// @title PUBLIC MINT

    /**
     * @notice turn on/off public mint
     */
    function flipMintStatePublic() external onlyOwner {
        mintIsActivePublic = !mintIsActivePublic;
    }

    /**
     * @notice Public mint function
     */
    function mint(uint256 numberOfTokens) external payable {
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

        _mint(msg.sender, mintingTokenID, numberOfTokens, "");
        numberMintedPublic += numberOfTokens;
        numberMintedTotal += numberOfTokens;
    }

    /// @title PRESALE WALLET MINT

    /**
     * @notice Turn on/off presale wallet mint
     */
    function flipPresaleMintState() external onlyOwner {
        mintIsActivePresale = !mintIsActivePresale;
    }

    /**
     * @notice Add wallets to presale wallet list
     */
    function initPresaleWalletList(address[] memory walletList) external onlyOwner {
	    for (uint i; i < walletList.length; i++) {
		    presaleWalletList[walletList[i]] = true;
	    }
    }

    /**
     * @notice Presale wallet list mint 
     */
    function mintPresale(uint256 numberOfTokens) external payable {
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
            presaleWalletList[msg.sender] == true, 
            "You are not on the presale wallet list or have already minted"
        );
        require(
            numberMintedPresale + numberOfTokens <= maxTokensPublic, 
            "Not enough tokens left to mint that many"
        );
        require(
            numberMintedTotal + numberOfTokens <= maxTokens, 
            "Not enough tokens left to mint that many"
        );

        _mint(msg.sender, mintingTokenID, numberOfTokens, "");
        numberMintedPresale += numberOfTokens;
        numberMintedTotal += numberOfTokens;

        presaleWalletList[msg.sender] = false;
    }


    /// @title Free Wallet Mint

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
    function mintFreeWalletList() external {
        require(mintIsActiveFree, "Free mint is not active");
	    require(
            freeWalletList[msg.sender] == true, 
            "You are not on the free wallet list or have already minted"
        );

        _mint(msg.sender, mintingTokenID, 1, "");
        numberMintedTotal += 1;

	    freeWalletList[msg.sender] = false;
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
    *  @notice reserver mint a collection
    */
    function mintReserve(uint256 amount) public onlyOwner {
        _mint(msg.sender, mintingTokenID, amount, "");
    }

    /**
    *  @notice reserve mint a batch of token collections
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

    /**
    * @notice get name of token
    */
    function name() public view returns (string memory) {
        return _name;
    }


    /**
    * @notice get symbol of token
    */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function contractURI() public view returns (string memory) {
	    return _contractURI;
    }


    // @title SETTER FUNCTIONS

    /**
    *  @dev set token base uri
    */
    function setURI(string memory baseURI) public onlyMinter {
        _setURI(baseURI);
    }

    /**
    *  @dev set contract uri https://docs.opensea.io/docs/contract-level-metadata
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

	    numberMintedPresale = 0;
	    numberMintedPublic = 0;
        numberMintedTotal = 0;
    }


    /**
    *  @notice Withdraw eth from contract by wallet
    */
    function release(address payable account) public override {
        require(msg.sender == account || msg.sender == owner(), "Release: no permission");

        super.release(account);
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
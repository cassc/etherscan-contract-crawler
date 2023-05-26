// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "../../../interfaces/IRFOXFactory.sol";

/**
 * @dev Base Contract of RFOX NFT, which extend ERC721A
 * @dev All function stated here will become the global function which can be used by any version of RFOX NFT
 */
contract BaseRFOXNFT is
    ERC721A,
    Pausable,
    Ownable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Override token name
    string private _name;
    // Override token symbol
    string private _symbol;
    // Override the base token URI
    string private _baseURIPrefix;
    // How many NFTs can buy per transaction
    uint256 public maxTokensPerTransaction;
    // NFTs Price
    uint256 public TOKEN_PRICE;
    // Max total supply of NFTs
    uint256 public MAX_NFT;
    // NFTs sale's currency
    IERC20 public saleToken;
    // NFT Factory
    IRFOXFactory public factory;
    // NFTs can not min exceed MAX_NFT

    // Timestamp of selling started for whitelisted addresses
    uint256 public saleStartTime;

    // Timestamp of selling ended for both public & whitelisted addresses
    uint256 public saleEndTime;

    event UpdateTokenPrice(
        address indexed sender,
        uint256 oldTokenPrice,
        uint256 newTokenPrice
    );
    event UpdateURI(address indexed sender, string oldURI, string newURI);
    event Withdraw(
        address indexed sender,
        address saleToken,
        uint256 totalWithdrawn
    );
    event MaxTokensPerTransaction(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );

    /**
     * @dev Check if the caller is an EOA, will revert if called by contract.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller must be EOA");
        _;
    }

    /**
     * @dev Check if the total mint target will exceed the total suply of NFT.
     *
     * @param totalMintTarget total token that will be minted.
     */
    modifier tokenInSupply(uint256 totalMintTarget) {
        require(totalSupply().add(totalMintTarget) <= MAX_NFT,
            "Exceeded Max NFTs"
        );
        _;
    }

    /**
     * @dev Check if total mint NFT exceed the limit or not.
     *
     * @param tokensNumber total token that will be minted.
     */
    modifier maxPurchasePerTx(uint256 tokensNumber) {
      require(
        tokensNumber <= maxTokensPerTransaction,
        "Max purchase per one transaction exceeded"
      );
      _;
    }

    /**
     * @dev Check if the public sale is opened or not.
     * This modifier will can be overwritten.
     * In this case, it's overwritten in the presale contract,
     * since the starting time between public & presale is different.
     */
    modifier authorizePublicSale() virtual {
        require(
            block.timestamp >= saleStartTime,
            "Sale has not been started"
        );
        _;
    }

    constructor() ERC721A("", "") {
        factory = IRFOXFactory(msg.sender);
    }

    /**
     * @dev Initialize function to setup initial value of several settings.
     *
     * @param name_ NFT Name.
     * @param symbol_ NFT Symbol.
     * @param baseURI_ NFT Base URI.
     * @param token Token address for the payment, Zero address will be considered as the native token (ETH, BNB, MATIC, etc).
     * @param price Price per token for the payment.
     * @param maxNft Max total supply of the NFT
     * @param maxTokensPerTransaction_ Max total token per purchased.
     * @param saleStartTime_ In the standard sale, this is the starting time of public sale. In the whitelist / presale, this is the starting time of the private sale.
     * @param saleEndTime_ The end time of the sale (public and presale). Can be 0 if we don't want to have expiration time.
     * @param ownership The owner of the NFT.
     */
    function initializeBase(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        IERC20 token,
        uint256 price,
        uint256 maxNft,
        uint256 maxTokensPerTransaction_, /// Max NFT per transaction
        uint256 saleStartTime_,
        uint256 saleEndTime_,
        address ownership
    ) internal {
        require(saleStartTime_ > 0, "Invalid start time");
        require(maxTokensPerTransaction_ > 0, "Max tokens per tx cannot be 0");

        _name = name_;
        _symbol = symbol_;
        _baseURIPrefix = baseURI_;
        saleToken = token;
        TOKEN_PRICE = price;
        MAX_NFT = maxNft;
        maxTokensPerTransaction = maxTokensPerTransaction_;
        saleStartTime = saleStartTime_;
        saleEndTime = saleEndTime_;
        transferOwnership(ownership);
    }

    /**
     * @dev Getter for the NFT name.
     *
     * @return NFT name.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Getter for the NFT symbol.
     *
     * @return NFT symbol
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Only owner can migrate base URI
     *
     * @param newBaseURIPrefix string prefix of start URI
     */
    
    function setBaseURI(string memory newBaseURIPrefix) external onlyOwner {
        string memory _oldUri = _baseURIPrefix;
        _baseURIPrefix = newBaseURIPrefix;
        emit UpdateURI(msg.sender, _oldUri, _baseURIPrefix);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    /**
     * @dev Getter for the base URI.
     *
     * @return Base URI of the NFT.
     */
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Update the value for max purchased token per tx.
     *
     * @param newMaxTokensPerTransaction new max token per purchased.
     */
    function setMaxTokensPerTransaction(uint256 newMaxTokensPerTransaction)
        external
        onlyOwner
    {
        require(newMaxTokensPerTransaction > 0, "INVALID_ZERO_VALUE");
        uint256 _oldMaxTokensPerTransaction = maxTokensPerTransaction;
        maxTokensPerTransaction = newMaxTokensPerTransaction;

        emit MaxTokensPerTransaction(
            msg.sender,
            _oldMaxTokensPerTransaction,
            maxTokensPerTransaction
        );
    }

    /**
     * @dev Owner can safe mint to address.
     * Limited to only 1 token per minting.
     *
     * @param to Receiver address.
     */
    
    /// @param to Address of receiver
    function safeMint(address to) external onlyOwner tokenInSupply(1) {
        _safeMint(to, 1);
    }

    /**
     * @dev Owner can pause the contract in emergency
     */
    
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Owner can unpause the contract in emergency
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev getter for the spesific token's URI -- ID of NFTs.
     *
     * @param tokenId NFT ID.
     *
     * @return Return the token URL link.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Owner withdraw revenue from Sales
     */
    function withdraw() external onlyOwner {
        uint256 balance;
        if (address(saleToken) == address(0)) {
            balance = address(this).balance;
            (bool succeed,) = msg.sender.call{value: balance}(
                ""
            );
            require(succeed, "Failed to withdraw Ether");
        } else {
            balance = saleToken.balanceOf(address(this));
            saleToken.safeTransfer(msg.sender, balance);
        }

        emit Withdraw(msg.sender, address(saleToken), balance);
    }

    /**
     * @dev The base function for purchasing.
     * Check if the token still in supply.
     * Check the end of sale time.
     *
     * @notice Every contract that implement this function responsible to check the starting sale time
     * and any other conditional check.
     *
     * @param tokensNumber total purchased token.
     */
    function _buyNFTs(uint256 tokensNumber) internal tokenInSupply(tokensNumber) {
        if (saleEndTime > 0)
            require(block.timestamp <= saleEndTime, "Sale has been finished");

        if (address(saleToken) == address(0)) {
            require(
                msg.value == TOKEN_PRICE.mul(tokensNumber),
                "Invalid eth for purchasing"
            );
        } else {
            require(msg.value == 0, "ETH_NOT_ALLOWED");

            saleToken.safeTransferFrom(
                msg.sender,
                address(this),
                TOKEN_PRICE.mul(tokensNumber)
            );
        }

        _safeMint(msg.sender, tokensNumber);
    }

    /**
     * @dev Update the token price.
     *
     * @param newTokenPrice The new token price.
     */
    function setTokenPrice(uint256 newTokenPrice) external onlyOwner {
        uint256 oldTokenPrice = TOKEN_PRICE;
        TOKEN_PRICE = newTokenPrice;
        emit UpdateTokenPrice(msg.sender, oldTokenPrice, TOKEN_PRICE);
    }
}
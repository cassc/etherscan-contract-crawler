// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Peeps Passport
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://peeps.club
/// Your gateway into the World of Peeps.

import "./ERC1155Single.sol";
import "./IPeepsPassport.sol";
import "./Payable.sol";
import "./Signable.sol";

contract PeepsPassport is ERC1155Single, Payable, Signable, IPeepsPassport {
    address public immutable peepsClubAddr;

    // Global sale details
    struct GeneralInfo {
        uint32 totalMinted;
        uint32 totalSupply;
        uint32 txLimitPlusOne;
        bool paused;
    }
    GeneralInfo private generalInfo;

    // Public sale details
    struct PublicSaleInfo {
        uint32 maxMintPlusOne;
        uint64 endTimestamp;
        uint128 tokenPrice;
    }
    PublicSaleInfo private publicSaleInfo;

    // Server sale details
    mapping(address => uint16) public utilityNonce; // Prevent replay attacks

    constructor(address peepsClubAddr_) ERC1155Single("https://my.peeps.club/passport/passport.json") Payable(1000) {
        peepsClubAddr = peepsClubAddr_;
        generalInfo = GeneralInfo(0, 0, 6, false);
    }

    //
    // Modifiers
    //

    /**
     * Do not allow calls from other contracts.
     */
    modifier noBots() {
        require(msg.sender == tx.origin, "PeepsPassport: No bots");
        _;
    }

    /**
     * Contract cannot be paused.
     */
    modifier notPaused() {
        require(!generalInfo.paused, "PeepsPassport: Contract is paused");
        _;
    }

    /**
     * Respect transaction limit.
     */
    modifier withinTxLimit(uint32 quantity) {
        require(quantity < generalInfo.txLimitPlusOne, "PeepsPassport: Exceeds transaction limit");
        _;
    }

    /**
     * Ensure correct amount of Ether present in transaction.
     */
    modifier correctValue(uint256 expectedValue) {
        require(expectedValue == msg.value, "PeepsPassport: Ether value incorrect");
        _;
    }

    /**
     * Checks for a valid nonce against the account, and increments it after the call.
     * @param account The caller.
     * @param nonce The expected nonce.
     */
    modifier useNonce(address account, uint32 nonce) {
        require(utilityNonce[account] == nonce, "PeepsPassport: Nonce not valid");
        _;
        utilityNonce[account]++;
    }

    //
    // Mint
    //

    /**
     * Public mint.
     * @param to Address to mint to.
     * @param quantity Amount of tokens to mint.
     */
    function mintPublic(address to, uint32 quantity)
        external
        payable
        noBots
        notPaused
        withinTxLimit(quantity)
        correctValue(publicSaleInfo.tokenPrice * quantity)
    {
        require(publicSaleInfo.endTimestamp > block.timestamp, "PeepsPassport: Public sale inactive");
        require(
            (generalInfo.totalMinted + quantity) < publicSaleInfo.maxMintPlusOne,
            "PeepsPassport: Exceeds available tokens"
        );
        _safeMint(to, quantity);
    }

    /**
     * Mint tokens when authorised by server.
     * @param price The total price.
     * @param quantity The number of tokens to mint.
     * @param expiry The latest time the signature can be used.
     * @param nonce A one time use number to prevent replay attacks.
     * @param signature A signed validation from the server.
     * @dev This increased the total mint count but is unlimited.
     */
    function mintSigned(
        uint256 price,
        uint32 quantity,
        uint64 expiry,
        uint32 nonce,
        bytes calldata signature
    )
        external
        payable
        notPaused
        withinTxLimit(quantity)
        correctValue(price)
        useNonce(msg.sender, nonce)
        signed(abi.encodePacked(msg.sender, nonce, quantity, expiry, price), signature)
    {
        require(expiry > block.timestamp, "PeepsPassport: Signature expired");
        _safeMint(msg.sender, quantity);
    }

    /**
     * Airdrop tokens.
     * @param to Address to mint to.
     * @param quantity Amount of tokens to mint.
     */
    function airdrop(address to, uint32 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }

    /**
     * Airdrop tokens.
     * @param to Address to mint to.
     * @param quantity Amount of tokens to mint.
     */
    function airdropBatch(address[] calldata to, uint8[] calldata quantity) external onlyOwner {
        require(to.length == quantity.length, "PeepsPassport: Array lengths do not match");
        uint16 totalQuantity = 0;
        for (uint256 i = 0; i < to.length; i++) {
            totalQuantity += quantity[i];
            _mint(to[i], quantity[i]);
        }
        generalInfo.totalMinted += totalQuantity;
        generalInfo.totalSupply += totalQuantity;
    }

    /**
     * Mint the tokens and increment the total supply counter.
     * @param to Address to mint to.
     * @param quantity Amount of tokens to mint.
     */
    function _safeMint(address to, uint32 quantity) private {
        generalInfo.totalMinted += quantity;
        generalInfo.totalSupply += quantity;
        _mint(to, quantity);
    }

    //
    // Admin
    //

    /**
     * Update maximum number of tokens per transaction in public sale.
     * @param txLimit The new transaction limit.
     */
    function setTxLimit(uint32 txLimit) external onlyOwner {
        generalInfo.txLimitPlusOne = txLimit + 1;
    }

    /**
     * Set the public sale information.
     * @param maxMint The maximum number of tokens that can be minted.
     * @param endTimestamp The timestamp at which the sale ends.
     * @param tokenPrice The token price for this sale.
     * @notice This method will automatically enable the public sale.
     * @dev The mint counter includes tokens minted by all mint functions.
     */
    function setPublicSaleInfo(
        uint32 maxMint,
        uint64 endTimestamp,
        uint128 tokenPrice
    ) external onlyOwner {
        publicSaleInfo = PublicSaleInfo(maxMint + 1, endTimestamp, tokenPrice);
    }

    /**
     * Update URI.
     */
    function setUri(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    /**
     * Update the contract paused state.
     * @param paused_ The new paused state.
     */
    function setPaused(bool paused_) external onlyOwner {
        generalInfo.paused = paused_;
    }

    //
    // Utility
    //

    /**
     * Burn passports.
     * @dev This method is only callable by the Peeps Contract.
     * @param owner The owner of the passports to burn.
     * @param quantity The number of passports to burn.
     */
    function burn(address owner, uint32 quantity) external notPaused {
        require(msg.sender == peepsClubAddr, "PeepsPassport: Not called by Peeps Club");
        generalInfo.totalSupply -= quantity;
        _burn(owner, quantity);
    }

    //
    // Views
    //

    /**
     * Return sale info.
     * @return
     * saleInfo[0]: maxMint (maximum number of tokens that can be minted during public sale)
     * saleInfo[1]: endTimestamp (timestamp for when public sale ends)
     * saleInfo[2]: totalMinted
     * saleInfo[3]: tokenPrice
     * saleInfo[4]: txLimit (maximum number of tokens per transaction)
     */
    function saleInfo() public view virtual returns (uint256[5] memory) {
        return [
            publicSaleInfo.maxMintPlusOne - 1,
            publicSaleInfo.endTimestamp,
            generalInfo.totalMinted,
            uint256(publicSaleInfo.tokenPrice),
            generalInfo.txLimitPlusOne - 1
        ];
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Single, ERC2981) returns (bool) {
        return ERC1155Single.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Return the total supply of Peeps Passports.
     * @param tokenId Must be 0.
     * @return totalSupply The total supply of passports.
     */
    function totalSupply(uint256 tokenId) public view returns (uint256) {
        if (tokenId != 0) {
            return 0;
        }
        return generalInfo.totalSupply;
    }
}
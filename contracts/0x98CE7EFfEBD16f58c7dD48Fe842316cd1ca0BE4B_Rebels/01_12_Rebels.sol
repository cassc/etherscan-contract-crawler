// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * The Rebels NFT contract
 */
contract Rebels is ERC721, Ownable {

    using ECDSA for bytes32;

    // Maximum supply of tokens
    uint public immutable MAX_SUPPLY;

    // Maximum amount of tokens that can be reserved by the owner
    uint public immutable MAX_OWNER_RESERVE;

    // Maximum number of tokens that can be minted in a single transaction
    uint public constant MAX_MINT_NUMBER = 10;

    // Maximum number of tokens per address in a whitelisted sale
    uint public constant MAX_WHITELISTED_SALE_TOKENS = 6;

    // SHA256 hash of the concatenated list of token image SHA256 hashes
    string public provenanceHash;

    // Number of tokens issued for sale
    uint public issuedTotal;

    // Number of minted tokens (includes reserve mints)
    uint public mintedTotal;

    // Number of tokens minted from reserve by the owner
    uint public reserveMintedTotal;

    // Single token price in wei
    uint public price;

    // Base URI of the token metadata
    string public baseUri;

    // Address used for whitelisted sale signatures
    address public whitelistSigner;

    // True if the public token sale is enabled
    bool public publicSaleEnabled;

    // True if the token sale is enabled for whitelisted addresses
    bool public whitelistedSaleEnabled;

    // Maps addresses to total number of tokens bought during whitelisted sale
    mapping(address => uint) public whitelistedSales;

    /**
     * @dev Throws if the given number of tokens can't be bought by current transaction
     * @param number Requested number of tokens
     *
     * Requirements:
     * - There should be enough issued unsold tokens
     * - Transaction value should be equal or bigger than the total price
     * - The given number of tokens shouldn't exceed MAX_MINT_NUMBER
     */
    modifier canBuy(uint number) {
        require(number <= remainingUnsoldSupply(), "Not enough issued tokens left");
        require(msg.value >= price * number, "Transaction value too low");
        require(number <= MAX_MINT_NUMBER, "Can't mint that many tokens at once");
        _;
    }

    /**
     * @param price_ Single token price
     * @param maxSupply Max amount of tokens that can be minted
     * @param maxOwnerReserve Number of tokens reserved for the owner
     *
     * Requirements:
     * - Reserved token amount must be equal or smaller than the total supply
     */
    constructor(uint price_, uint maxSupply, uint maxOwnerReserve) ERC721("The Rebels", "RBLS") {
        require(maxOwnerReserve <= maxSupply, "Can't reserve more than the total supply");
        MAX_SUPPLY = maxSupply;
        MAX_OWNER_RESERVE = maxOwnerReserve;
        price = price_;
    }

    /**
     * @dev Issues given number of tokens for sale
     * @param number Number of tokens to issue
     *
     * Requirements:
     * - There should be enough supply remaining
     */
    function issue(uint number) external onlyOwner {
        require(number <= remainingUnissuedSupply(), "Not enough remaining tokens");
        issuedTotal += number;
    }

    /**
     * @dev Public sale mint
     * @param number Number of tokens to mint
     *
     * Requirements:
     * - Public sale should be enabled
     * - All requirements of the canBuy modifier must be satisfied
     */
    function mint(uint number) external payable canBuy(number) {
        require(publicSaleEnabled, "Public sale disabled");
        _batchMint(number);
    }

    /**
     * @dev Whitelisted sale mint
     * @param number Number of tokens to mint
     * @param signature Sender address's sha3 hash signed by the whitelist signer
     *
     * Requirements:
     * - Whitelisted sale should be enabled
     * - Address can't buy more than MAX_WHITELISTED_SALE_TOKENS in a whitelisted sale
     * - All requirements of the canBuy modifier must be satisfied
     */
    function whitelistedMint(uint number, bytes memory signature) external payable canBuy(number) {
        require(whitelistedSaleEnabled, "Whitelisted sale disabled");

        address recovered = keccak256(abi.encodePacked(msg.sender))
            .toEthSignedMessageHash()
            .recover(signature);
        require(recovered == whitelistSigner, "Invalid whitelist signature");

        require(
            whitelistedSales[msg.sender] + number <= MAX_WHITELISTED_SALE_TOKENS,
            "Whitelisted sale limit exceeded"
        );
        whitelistedSales[msg.sender] += number;

        _batchMint(number);
    }

    /**
     * @dev Mints tokens reserved for the owner
     * @param number Number of tokens to mint
     *
     * Requirements:
     * - There should be enough tokens in the reserve
     */
    function reserveMint(uint number) external onlyOwner {
        require(number <= remainingOwnerReserve(), "Not enough reserved tokens left");
        reserveMintedTotal += number;
        _batchMint(number);
    }

    /**
     * @dev Enables minting for whitelisted addresses
     */
    function enableWhitelistedSale() external onlyOwner {
        whitelistedSaleEnabled = true;
    }

    /**
     * @dev Disables minting for whitelisted addresses
     */
    function disableWhitelistedSale() external onlyOwner {
        whitelistedSaleEnabled = false;
    }

    /**
     * @dev Enables minting for non-whitelisted addresses
     */
    function enablePublicSale() external onlyOwner {
        publicSaleEnabled = true;
    }

    /**
     * @dev Disables minting for non-whitelisted addresses
     */
    function disablePublicSale() external onlyOwner {
        publicSaleEnabled = false;
    }

    /**
     * @dev Sets the price of a single token
     * @param price_ Price in wei
     */
    function setPrice(uint price_) external onlyOwner {
        price = price_;
    }

    /**
     * @dev Sets the address that generates signatures for whitelisted mint
     * @param whitelistSigner_ Signing address
     *
     * Note that whitelist signatures signed with the old address won't be accepted after changing
     * the signer address.
     */
    function setWhitelistSigner(address whitelistSigner_) external onlyOwner {
        whitelistSigner = whitelistSigner_;
    }

    /**
     * @dev Sets base URI for the metadata
     * @param baseUri_ Base URI, where the token's ID could be appended at the end of it
     */
    function setBaseUri(string memory baseUri_) external onlyOwner {
        baseUri = baseUri_;
    }

    /**
     * @dev Sets provenance hash
     * @param hash SHA256 hash of the concatenated list of token image SHA256 hashes
     *
     * Requirements:
     * - Hash can only be set (or changed) before the first mint
     */
    function setProvenanceHash(string memory hash) external onlyOwner {
        require(mintedTotal == 0, "Hash can only be set before first mint");
        provenanceHash = hash;
    }

    /**
     * @dev Sends contract's balance to the owner's wallet
     */
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Mints new tokens
     * @param number Number of tokens to mint
     */
    function _batchMint(uint number) private {
        uint lastTokenId = mintedTotal;
        mintedTotal += number;
        for (uint i = 1; i <= number; i++) {
            _safeMint(msg.sender, lastTokenId + i);
        }
    }

    /**
     * @dev Overwrites parent to provide actual base URI
     * @return Base URI of the token metadata
     */
    function _baseURI() override internal view returns (string memory) {
        return baseUri;
    }

    /**
     * @dev Checks if the given token exists (has been minted)
     * @param tokenId Token ID
     * @return True, if token is minted
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Returns total number of minted tokens
     * @return Total number of minted tokens
     *
     * Note: Partially implements IERC721Enumerable
     */
    function totalSupply() external view returns (uint256) {
        return mintedTotal;
    }

    /**
     * @dev Returns the number of tokens than could still be minted
     * @return Number of tokens
     */
    function remainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - mintedTotal;
    }

    /**
     * @dev Returns the number of tokens that could still be issued for sale
     * @return Number of tokens
     */
    function remainingUnissuedSupply() public view returns (uint256) {
        return MAX_SUPPLY - MAX_OWNER_RESERVE - issuedTotal;
    }

    /**
     * @dev Returns the number of issued tokens that could still be minted
     * @return Number of tokens
     */
    function remainingUnsoldSupply() public view returns (uint256) {
        return issuedTotal - (mintedTotal - reserveMintedTotal);
    }

    /**
     * @dev Returns the number of tokens that could still be reserve minted by the owner
     * @return Numer of tokens
     */
    function remainingOwnerReserve() public view returns (uint256) {
        return MAX_OWNER_RESERVE - reserveMintedTotal;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// Interfaces
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "./interfaces/IVerifier.sol";
import "./interfaces/IToken.sol";

contract Presale is Ownable, ERC721Enumerable
{
    /**
     * Verifier contract.
     */
    IVerifier private _verifier;

    /**
     * Payment contract.
     */
    IERC20Metadata public paymentToken;

    /**
     * Fur token contract.
     */
    IToken public furToken;

    /**
     * Treasury address.
     */
    address public treasury;

    /**
     * Token id tracker.
     */
    uint256 private _tokenIdTracker;

    /**
     * Token URI (same for all tokens).
     */
    string private _tokenUri = 'ipfs://Qme28bzD3z119fAqBPXgpDb9Z79bqEheQjkejWsefcd4Gj/1';

    /**
     * Token values.
     */
    mapping(uint256 => uint256) public tokenValue;

    /**
     * Salt buys.
     * @dev Map salt to number of purchases by address.
     */
    mapping(address => mapping(string => uint256)) private _buys;

    /**
     * Salt totals.
     * @dev Map salt to total number of purchases.
     */
    mapping(string => uint256) private _totals;

    /**
     * Claimed tokens.
     */
    mapping(uint256 => bool) public claimed;

    /**
     * Events.
     */
    event NftPurchased(address buyer_, uint256 tokenId_, uint256 price_, uint256 value_);
    event NftClaimed(address claimer_, uint256 tokenId_, uint256 value_);

    /**
     * Constructor.
     */
    constructor() ERC721("Furio Presale NFT", "$FURPRESALE") {}

    /**
     * -------------------------------------------------------------------------
     * USER FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Buy an NFT.
     * @param signature_ Verification signature.
     * @param quantity_ The quantity to buy.
     * @param max_ The max available to buy.
     * @param price_ The price per NFT.
     * @param value_ The value per NFT.
     * @param total_ The total NFTs available.
     * @param expiration_ The expiration date of the verification signature.
     * @return bool True if successful.
     * @dev This buy method uses a signature comprised of the max, price
     * and value values which is then verified by the verifier contract. This
     * allows a much slimmer NFT contract and we can control presale elements
     * server side.
     */
    function buy(
        bytes memory signature_,
        uint256 quantity_,
        uint256 max_,
        uint256 price_,
        uint256 value_,
        uint256 total_,
        uint256 expiration_
    ) external returns (bool)
    {
        // Make sure the verifier contract is set.
        require(address(_verifier) != address(0), "Verifier not set");
        // Make sure the payment token is set.
        require(address(paymentToken) != address(0), "Payment token not set");
        // Make sure the treasury address is set.
        require(treasury != address(0), "Treasury not set");
        // Make sure the signature isn't expired.
        require(expiration_ >= block.timestamp, "Signature expired");
        // Make sure quantity is less than max.
        require(quantity_ <= max_, "Quantity is too high");
        require(sold(max_, price_, value_, total_) + quantity_ <= total_, "Quantity is too high");
        require(quantity_ <= available(msg.sender, max_, price_, value_, total_), "Quantity is too high");
        // Re-create the signature salt using max, price, & value.
        string memory _salt_ = _salt(max_, price_, value_, total_);
        // Verify the signature is valid.
        require(_verifier.verify(signature_, msg.sender, _salt_, expiration_), "Invalid signature");
        // Get payment token decimals.
        uint256 _decimals_ = paymentToken.decimals();
        // Get a payment from the user.
        require(paymentToken.transferFrom(msg.sender, treasury, (price_ * (10 ** _decimals_)) * quantity_), "Payment failed");
        // Loop through quantity, minting tokens.
        for(uint256 i = 1; i <= quantity_; i ++) {
            // Increment token id.
            _tokenIdTracker ++;
            // Add the value to the tokenValue mapping.
            tokenValue[_tokenIdTracker] = value_;
            // Increment the signature quantity.
            _buys[msg.sender][_salt_] ++;
            _totals[_salt_] ++;
            // Finally, mint the token.
            _mint(msg.sender, _tokenIdTracker);
            emit NftPurchased(msg.sender, _tokenIdTracker, price_, value_);
        }
        // Success!
        return true;
    }

    /**
     * Claim!
     * @dev Burn all of your NFTs and get $FUR tokens! FIRE!
     */
    function claim() external
    {
        // Make sure Fur token contract exists and is not paused
        require(address(furToken) != address(0), "Fur token not set");
        require(!furToken.paused(), "Fur token is paused");
        uint256 _value_ = 0;
        for(uint256 i = 0; i < balanceOf(msg.sender); i ++) {
            uint256 _tokenId_ = tokenOfOwnerByIndex(msg.sender, i);
            if(claimed[_tokenId_]) {
                continue;
            }
            _value_ += tokenValue[_tokenId_];
            claimed[_tokenId_] = true;
            emit NftClaimed(msg.sender, _tokenId_, tokenValue[_tokenId_]);
        }
        require(_value_ > 0, "No claimable tokens");
        uint256 _decimals_ = furToken.decimals();
        furToken.mint(msg.sender, _value_ * (10 ** _decimals_));
    }

    /**
     * Value.
     * @param owner_ Owner of presale tokens.
     * @dev Returns the total value of all NFTs owned by an address.
     */
    function value(address owner_) external view returns (uint256)
    {
        uint256 _value_ = 0;
        for(uint256 i = 0; i < balanceOf(owner_); i ++) {
            uint256 _tokenId_ = tokenOfOwnerByIndex(owner_, i);
            if(claimed[_tokenId_]) {
                continue;
            }
            _value_ += tokenValue[_tokenId_];
        }
        return _value_;
    }

    /**
     * Get available to purchase.
     * @param buyer_ Address of buyer.
     * @param max_ Max NFTs available.
     * @param price_ Price of each NFT.
     * @param value_ Value of each NFT.
     * @param total_ Total NFTs available.
     * @return uint256 Number of NFTs available.
     * @dev Calculates the remaining number of NFTs available for a user.
     */
    function available(address buyer_, uint256 max_, uint256 price_, uint256 value_, uint256 total_) public view returns (uint256)
    {
        string memory _salt_ = _salt(max_, price_, value_, total_);
        uint256 _remaining_ = total_ - _totals[_salt_];
        uint256 _available_ = max_ - _buys[buyer_][_salt_];
        if(_available_ <= _remaining_) return _available_;
        return _remaining_;
    }

    /**
     * Sold.
     * @param max_ Max per person.
     * @param price_ Price per NFT.
     * @param value_ Value per NFT.
     * @param total_ Total NFTs available.
     * @return uint256 Number of NFTs sold with this salt.
     */
    function sold(uint256 max_, uint256 price_, uint256 value_, uint256 total_) public view returns (uint256)
    {
        return _totals[_salt(max_, price_, value_, total_)];
    }

    /**
     * Token URI.
     * @param tokenId_ Id of the token.
     * @dev This just returns the same URI for all tokens in this contract.
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory)
    {
        require(_exists(tokenId_), "Token does not exist");
        return _tokenUri;
    }

    /**
     * -------------------------------------------------------------------------
     * INTERNAL FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Make salt.
     * @param max_ Max NFTs per person.
     * @param price_ Price per NFT.
     * @param value_ Value per NFT.
     * @param total_ Total NFTs available.
     * @return string Salt.
     */
    function _salt(uint256 max_, uint256 price_, uint256 value_, uint256 total_) internal pure returns (string memory)
    {
        return string(abi.encodePacked(
            'max', Strings.toString(max_),
            'price', Strings.toString(price_),
            'value', Strings.toString(value_),
            'total', Strings.toString(total_)
        ));
    }

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Set verifier contract.
     * @param verifier_ Address of verifier contract.
     * @dev This contract verifies signatures to validate users.
     */
    function setVerifier(address verifier_) external onlyOwner
    {
        _verifier = IVerifier(verifier_);
    }

    /**
     * Set payment token.
     * @param paymentToken_ Address of the payment token.
     * @dev This will be the USDC address used to buy NFTs.
     */
    function setPaymentToken(address paymentToken_) external onlyOwner
    {
        paymentToken = IERC20Metadata(paymentToken_);
    }

    /**
     * Set treasury.
     * @param treasury_ Address of the treasury contract.
     * @dev This is the multisig wallet where we will store funds until
     * it's time to create the liquidity pool.
     */
    function setTreasury(address treasury_) external onlyOwner
    {
        treasury = treasury_;
    }

    /**
     * Set fur token.
     * @param furToken_ Address of the $FUR token contract.
     * @dev This sets the address for the $FUR token.
     */
    function setFurToken(address furToken_) external onlyOwner
    {
        furToken = IToken(furToken_);
    }

    /**
     * Set token URI.
     * @param uri_ Address of the token metadata.
     * @dev This updates the token URI of the contract. This will probably
     * never get updated unless we screwed up somewhere.
     */
    function setTokenUri(string memory uri_) external onlyOwner
    {
        _tokenUri = uri_;
    }
}
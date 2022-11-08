// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./chainlink/AggregatorV3Interface.sol";

import "./ERC2981.sol";
import "./MintpassValidator.sol";
import "./LibMintpass.sol";

/**
 * @dev This is a ERC721 Contract.
 * The minting process is processed in a public and an allow list sale
 * sale. Learn more about this project on https://nft.arcticbluebeverages.com/.
 * Access your holder benefits on https://holders.arcticbluebeverages.com/.
 */

contract ABBLegacy is MintpassValidator, ERC721A, ERC2981, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    AggregatorV3Interface internal priceFeed;

    // Token Limit and Mint Limits
    // Maximum amount of mintable tokens
    uint256 public immutable TOKEN_LIMIT = 3000;
    // Maximum amount of mintable tokens
    uint256 public immutable mintLimitPerWallet = 10;
    // Maximum amount of mintable tokens in allow list sale
    uint256 public immutable mintAllowlistLimitPerWallet = 3;
    // List of redeemed tokens
    mapping(uint256 => address) public redeemedBottles;
    // List of allowlist minted tokens per wallet
    mapping(address => uint256) public boughtAllowlistAmounts;
    // List of public minted tokens per wallet
    mapping(address => uint256) public boughtPublicAmounts;

    // Sale Stages Enabled / Disabled
    bool public redeemingEnabled = true;
    bool public allowlistMintEnabled = false;
    bool public publicMintEnabled = false;

    // Mint Price
    int256 public immutable mintUSDPrice = 150000000000; // = 1,500 USD
    int256 public immutable discountMintUSDPrice = 130000000000; // = 1,300 USD
    int256 public redeemUSDPrice = 500000000; // = 5 USD

    // Available free mints for owner
    int256 internal availableOwnerFreeMints = 200;

    string public _baseTokenURI;

    // mapping of beneficiary shares
    mapping(address => uint256) public shares;
    // share for A beneficiary
    uint256 internal immutable shareA = 1000;
    // share for B beneficiary
    uint256 internal immutable shareB = 700;
    // share for C beneficiary
    uint256 internal immutable shareC = 300;

    address internal immutable shareABeneficiary =
        0x212BCFE60f8e71AEcBd490c141Eb6973e7b6B251;
    address internal immutable shareBBeneficiary =
        0xC88C655C62E55dE376561FC9154dF9548d761F45;
    address internal immutable shareCBeneficiary =
        0x7520573d4Cb32F5e094200Dd598D1893176C841d;

    /**
    @dev Emitted when bottle was Redeemed
     */
    event Redeemed(uint256 indexed tokenId, address owner, bool redeemed);

    /**
     * @dev ERC721A Constructor
     */
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {
        _setDefaultRoyalty(msg.sender, 500);
        SIGNER_WALLET = 0xdf8D2B9c6ED300Edc38F24133A2E1Ac150FF7F17;
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // Chainlink ETH/USD
        );
    }

    /**
     * @dev Withrawal all Funds sent to the contract to Owner
     *
     * Requirements:
     * - `msg.sender` needs to be Beneficiary and payable
     */
    function withdraw() external onlyBeneficiary {
        require(
            shares[msg.sender] > 0,
            "ABB Legacy: Beneficiary has nothing to withdraw"
        );
        require(payable(msg.sender).send(shares[msg.sender]));
        shares[msg.sender] = 0;
    }

    /**
     * @dev Overwrite Token ID Start to skip Token with ID 0
     *
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Public Mint Function.
     *
     * @param minter user that should receive the token
     * @param quantity amount of tokens to be minted
     *
     * Requirements:
     * - public minting is enabled
     * - payable amount is correct
     * - tokens are not sold out
     * - user has not minted too many tokens
     */
    function mint(address minter, uint256 quantity) public payable {
        require(
            publicMintEnabled == true,
            "ABB Legacy: Public Minting is not Enabled"
        );

        require(
            msg.value >= (mintPrice() * quantity * 199) / 200, // 0.5% treshold due to conversion rate swings
            "ABB Legacy: Insufficient Amount"
        );

        require(
            TOKEN_LIMIT >= totalSupply() + quantity,
            "ABB Legacy: Token Limit reached"
        );
        require(
            boughtPublicAmounts[minter] + quantity <= mintLimitPerWallet,
            "ABB Legacy: Maximum Amount per Wallet reached"
        );

        _mint(minter, quantity);
        boughtPublicAmounts[minter] += quantity;

        accountShares(msg.value);
    }

    /**
     * @dev Owner Free Mint.
     *
     * @param minter user that should receive the token
     * @param quantity amount of tokens to be minted
     *
     * Requirements:
     * - caller is owner
     * - tokens are not sold out
     * - owner has not minted too many tokens
     */
    function ownerMint(address minter, uint256 quantity) public onlyOwner {
        require(
            TOKEN_LIMIT >= totalSupply() + quantity,
            "ABB Legacy: Token Limit reached"
        );
        require(
            availableOwnerFreeMints - int256(quantity) >= 0,
            "ABB Legacy: No Freemints left"
        );

        _mint(minter, quantity);
        availableOwnerFreeMints -= int256(quantity);
    }

    /**
     * @dev Redeem Bottle Function.
     * In theory anyone can pay for the redemption. However,
     * only the current token owner receives the physical bottle.
     * @param tokenId token that should be redeemed
     *
     * Requirements:
     * - redeeming is enabled
     * - payable amount is correct
     * - token is not redeemed yet
     */
    function redeemBottle(uint256 tokenId) public payable {
        require(
            redeemingEnabled == true,
            "ABB Legacy: Bottle Redeeming is currently not enabled"
        );

        require(
            msg.value >= (redeemPrice() * 199) / 200, // 0.5% treshold due to conversion rate swings
            "ABB Legacy: Insufficient Amount"
        );

        require(
            redeemedBottles[tokenId] == address(0),
            "ABB Legacy: Bottle already redeemed"
        );

        redeemedBottles[tokenId] = ownerOf(tokenId);
        emit Redeemed(tokenId, ownerOf(tokenId), true);
        // Redemption Payments go entirely to the owner.
        shares[owner()] += msg.value;
    }

    /**
     * @dev Reset Bottle Redemption Status
     * This function should only be called if for example a Bottle could not be delivered
     * or the owner wants to revert his redemption BEFORE the bottle was shipped
     * @param tokenId token that should resetted
     *
     * Requirements:
     * - caller is owner
     * - token is redeemed
     */
    function resetBottleRedemption(uint256 tokenId) public virtual onlyOwner {
        require(
            redeemedBottles[tokenId] != address(0),
            "ABB Legacy: Bottle not redeemed yet"
        );
        delete redeemedBottles[tokenId];
        emit Redeemed(tokenId, ownerOf(tokenId), false);
    }

    /**
     * @dev Function to mint Tokens during Allowlist Sale. This function is
     * should only be called on minting app to ensure signature validity.
     * Depending on MintTier a discount may apply.
     *
     * @param quantity amount of tokens to be minted
     * @param mintpass issued by the minting app
     * @param mintpassSignature issued by minting app and signed by SIGNER_WALLET
     *
     * Requirements:
     * - quantity can't be higher than {mintLimitPerWallet}
     * - payble amount is correct
     * - tokens are not sold out
     * - mintpass needs to match the signature contents
     * - mintpassSignature needs to be obtained from minting app and signed by SIGNER_WALLET
     */
    function allowlistMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) public payable {
        require(
            allowlistMintEnabled == true,
            "ABB Legacy: Allowlist Minting is not Enabled"
        );

        if (mintpass.tier == 2) {
            require(
                msg.value >= (discountMintPrice() * quantity * 199) / 200, // 0.5% treshold due to conversion rate swings
                "ABB Legacy: Insufficient Amount"
            );
        } else {
            require(
                msg.value >= (mintPrice() * quantity * 199) / 200, // 0.5% treshold due to conversion rate swings
                "ABB Legacy: Insufficient Amount"
            );
        }

        require(
            TOKEN_LIMIT >= totalSupply() + quantity,
            "ABB Legacy: All Tokens minted"
        );

        require(
            boughtAllowlistAmounts[mintpass.wallet] + quantity <=
                mintAllowlistLimitPerWallet,
            "ABB Legacy: Maximum Amount per Wallet reached"
        );

        validateMintpass(mintpass, mintpassSignature);
        _mint(mintpass.wallet, quantity);
        boughtAllowlistAmounts[mintpass.wallet] += quantity;
        accountShares(msg.value);
    }

    /**
     * @dev Helper to get current ether price of a token
     */
    function mintPrice() public view returns (uint256) {
        return convertFiatToEth(mintUSDPrice);
    }

    /**
     * @dev Helper to get current ether price of a discount token
     */
    function discountMintPrice() public view returns (uint256) {
        return convertFiatToEth(discountMintUSDPrice);
    }

    /**
     * @dev Helper to get current ether price of a token redemption
     */
    function redeemPrice() public view returns (uint256) {
        return convertFiatToEth(redeemUSDPrice);
    }

    /**
     * @dev Returns the latest price
     */
    function convertFiatToEth(int256 fiatPrice)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return
            uint256(
                (((fiatPrice * 1000000000) / price) * 1000000000) * (1 wei)
            );
    }

    /**
     * @dev Adds shares to the beneficiary accounts
     */
    function accountShares(uint256 totalReceived) internal {
        uint256 shareAPayout = (totalReceived * shareA) / 10000;
        uint256 shareBPayout = (totalReceived * shareB) / 10000;
        uint256 shareCPayout = (totalReceived * shareC) / 10000;
        uint256 ownerPayout = totalReceived -
            shareAPayout -
            shareBPayout -
            shareCPayout;
        shares[shareABeneficiary] += shareAPayout;
        shares[shareBBeneficiary] += shareBPayout;
        shares[shareCBeneficiary] += shareCPayout;
        shares[owner()] += ownerPayout;
    }

    /**
     * @dev Function to be called by contract owner to enable / disable
     * different mint stages
     *
     * @param _allowlistMintEnabled true/false
     * @param _publicMintEnabled true/false
     */
    function setMintingEnabled(
        bool _allowlistMintEnabled,
        bool _publicMintEnabled
    ) public virtual onlyOwner {
        allowlistMintEnabled = _allowlistMintEnabled;
        publicMintEnabled = _publicMintEnabled;
    }

    /**
     * @dev Function to be called by contract owner to enable / disable
     * bottle redemption
     *
     * @param _redeemingEnabled true/false
     */
    function setRedemptionEnabled(bool _redeemingEnabled)
        public
        virtual
        onlyOwner
    {
        redeemingEnabled = _redeemingEnabled;
    }

    /**
     * @dev Function to be called by contract owner to change the price for Redepmtion.
     *
     * @param _redeemUSDPrice new USD price
     */
    function setRedemptionUSDPrice(int256 _redeemUSDPrice)
        public
        virtual
        onlyOwner
    {
        redeemUSDPrice = _redeemUSDPrice;
    }

    /**
     * @dev Function to change the signer Wallet
     *
     * @param _signerWallet address
     */
    function setSignerWallet(address _signerWallet) public virtual onlyOwner {
        SIGNER_WALLET = _signerWallet;
    }

    /**
     * @dev Helper to replace _baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (bytes(_baseTokenURI).length > 0) {
            return _baseTokenURI;
        }
        return
            string(
                abi.encodePacked(
                    "https://metadata.bowline.app/",
                    Strings.toHexString(uint256(uint160(address(this))), 20),
                    "/"
                )
            );
    }

    /**
     * @dev Can be called by owner to change base URI. This is recommend to be used
     * after tokens are revealed to freeze metadata on IPFS or similar.
     *
     * @param permanentBaseURI URI to be prefixed before tokenId
     */
    function setBaseURI(string memory permanentBaseURI)
        public
        virtual
        onlyOwner
    {
        _baseTokenURI = permanentBaseURI;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        virtual
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Throws if caller is not a Beneficiary
     */
    modifier onlyBeneficiary() {
        require(
            owner() == _msgSender() ||
                shareABeneficiary == _msgSender() ||
                shareBBeneficiary == _msgSender() ||
                shareCBeneficiary == _msgSender(),
            "ABB Legacy: Caller is not a Beneficiary"
        );
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}

/** created with bowline.app **/
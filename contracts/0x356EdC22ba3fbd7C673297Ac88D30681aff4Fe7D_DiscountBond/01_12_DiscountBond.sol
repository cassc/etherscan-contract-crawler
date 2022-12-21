// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IBond.sol";
import "./interfaces/IBondFactory.sol";

contract DiscountBond is ERC20Upgradeable, ReentrancyGuardUpgradeable, IBond {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    string public constant kind = "Discount";
    IBondFactory public factory;
    IERC20MetadataUpgradeable public underlyingToken;
    uint256 public maturity;
    string public series;
    uint256 public inventoryAmount;
    uint256 public redeemedAmount;
    string public isin;

    event BondMinted(address indexed account, uint256 bondAmount, uint256 underlyingAmount);
    event BondSold(address indexed account, uint256 bondAmount, uint256 underlyingAmount);
    event BondRedeemed(address indexed account, uint256 amount);
    event BondGranted(uint256 amount, uint256 inventoryAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory series_,
        address factory_,
        IERC20MetadataUpgradeable underlyingToken_,
        uint256 maturity_,
        string memory isin_
    ) external initializer {
        __ERC20_init(name_, symbol_);
        __ReentrancyGuard_init();
        require(
            maturity_ > block.timestamp && maturity_ <= block.timestamp + (20 * 365 days),
            "DiscountBond: INVALID_MATURITY"
        );
        series = series_;
        underlyingToken = underlyingToken_;
        factory = IBondFactory(factory_);
        maturity = maturity_;
        isin = isin_;
    }

    modifier beforeMaturity() {
        require(block.timestamp < maturity, "DiscountBond: MUST_BEFORE_MATURITY");
        _;
    }

    modifier afterMaturity() {
        require(block.timestamp >= maturity, "DiscountBond: MUST_AFTER_MATURITY");
        _;
    }

    modifier tradingGuard() {
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == address(factory), "DiscountBond: UNAUTHORIZED");
        _;
    }

    function decimals() public view virtual override(ERC20Upgradeable, IERC20MetadataUpgradeable) returns (uint8) {
        return underlyingToken.decimals();
    }

    /**
     * @dev grant specific amount of bond for user mint.
     */
    function grant(uint256 amount_) external onlyFactory {
        inventoryAmount += amount_;
        emit BondGranted(amount_, inventoryAmount);
    }

    function minTradingAmount() public view returns (uint256) {
        return 10**(underlyingToken.decimals() - 4);
    }

    function getPrice() public view returns (IBondFactory.BondPrice memory price) {
        price = factory.getPrice(address(this));
        uint256 priceFactor = factory.priceFactor();
        uint256 minPrice = 8 * (priceFactor / 10);
        uint256 maxPrice = 12 * (priceFactor / 10);
        require(
            price.price >= minPrice &&
                price.price <= maxPrice &&
                price.ask >= minPrice &&
                price.ask <= maxPrice &&
                price.bid >= minPrice &&
                price.bid <= maxPrice,
            "DiscountBond: INVALID_PRICE"
        );
        return price;
    }

    function mintByUnderlyingAmount(address account_, uint256 underlyingAmount_)
        external
        beforeMaturity
        nonReentrant
        returns (uint256 bondAmount)
    {
        underlyingToken.safeTransferFrom(msg.sender, address(this), underlyingAmount_);
        bondAmount = previewMintByUnderlyingAmount(underlyingAmount_);
        inventoryAmount -= bondAmount;
        _mint(account_, bondAmount);
        emit BondMinted(account_, bondAmount, underlyingAmount_);
    }

    function previewMintByUnderlyingAmount(uint256 underlyingAmount_)
        public
        view
        beforeMaturity
        tradingGuard
        returns (uint256 bondAmount)
    {
        require(underlyingAmount_ >= minTradingAmount(), "DiscountBond: AMOUNT_TOO_LOW");
        bondAmount = (underlyingAmount_ * factory.priceFactor()) / getPrice().ask;
        require(inventoryAmount >= bondAmount, "DiscountBond: INSUFFICIENT_LIQUIDITY");
    }

    function mintByBondAmount(address account_, uint256 bondAmount_)
        external
        nonReentrant
        beforeMaturity
        returns (uint256 underlyingAmount)
    {
        underlyingAmount = previewMintByBondAmount(bondAmount_);
        underlyingToken.safeTransferFrom(msg.sender, address(this), underlyingAmount);
        inventoryAmount -= bondAmount_;
        _mint(account_, bondAmount_);
        emit BondMinted(account_, bondAmount_, underlyingAmount);
    }

    function previewMintByBondAmount(uint256 bondAmount_)
        public
        view
        beforeMaturity
        tradingGuard
        returns (uint256 underlyingAmount)
    {
        require(bondAmount_ >= minTradingAmount(), "DiscountBond: AMOUNT_TOO_LOW");
        require(inventoryAmount >= bondAmount_, "DiscountBond: INSUFFICIENT_LIQUIDITY");
        underlyingAmount = (bondAmount_ * getPrice().ask) / factory.priceFactor();
    }

    function sellByBondAmount(uint256 bondAmount_)
        public
        beforeMaturity
        nonReentrant
        tradingGuard
        returns (uint256 underlyingAmount)
    {
        underlyingAmount = previewSellByBondAmount(bondAmount_);
        _burn(msg.sender, bondAmount_);
        inventoryAmount += bondAmount_;
        underlyingToken.safeTransfer(msg.sender, underlyingAmount);
        emit BondSold(msg.sender, bondAmount_, underlyingAmount);
    }

    function previewSellByBondAmount(uint256 bondAmount_)
        public
        view
        beforeMaturity
        tradingGuard
        returns (uint256 underlyingAmount)
    {
        require(bondAmount_ >= minTradingAmount(), "DiscountBond: AMOUNT_TOO_LOW");
        require(balanceOf(msg.sender) >= bondAmount_, "DiscountBond: EXCEEDS_BALANCE");
        underlyingAmount = (bondAmount_ * getPrice().bid) / factory.priceFactor();
        require(underlyingToken.balanceOf(address(this)) >= underlyingAmount, "DiscountBond: INSUFFICIENT_LIQUIDITY");
    }

    function redeem(uint256 bondAmount_) public {
        redeemFor(msg.sender, bondAmount_);
    }

    function faceValue(uint256 bondAmount_) public view returns (uint256) {
        return bondAmount_;
    }

    function amountToUnderlying(uint256 bondAmount_) public view returns (uint256) {
        if (block.timestamp >= maturity) {
            return faceValue(bondAmount_);
        }
        return (bondAmount_ * getPrice().price) / factory.priceFactor();
    }

    function redeemFor(address account_, uint256 bondAmount_) public afterMaturity nonReentrant {
        require(balanceOf(msg.sender) >= bondAmount_, "DiscountBond: EXCEEDS_BALANCE");
        _burn(msg.sender, bondAmount_);
        redeemedAmount += bondAmount_;
        underlyingToken.safeTransfer(account_, bondAmount_);
        emit BondRedeemed(account_, bondAmount_);
    }

    /**
     * @notice
     */
    function underlyingOut(uint256 amount_, address to_) external onlyFactory {
        underlyingToken.safeTransfer(to_, amount_);
    }

    function emergencyWithdraw(
        IERC20MetadataUpgradeable token_,
        address to_,
        uint256 amount_
    ) external onlyFactory {
        token_.safeTransfer(to_, amount_);
    }
}
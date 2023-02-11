//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IPancakePair.sol";
import "hardhat/console.sol";

contract CrowdSale is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // The token being sold
    IERC20Upgradeable public kelpToken;
    // Address where funds are collected
    address payable public wallet;
    // Airdrop address where transfers tokens from
    address public airdrop;
    // Amount of wei raised
    uint256 public weiRaised;
    // WBNB/BUSD PancakePair
    address public constant PANCAKE_PAIR_ADDRESS =
        0x1B96B92314C44b159149f7E0303511fB2Fc4774f;
    struct SaleInfo {
        uint256 rate;
        uint256 startTime;
        uint256 limitPerAccount;
        uint256 totalLimit;
        bool paused;
    }
    /**
     * Sales array
     * 0 -> privateSale
     * 1 -> preSale
     */
    SaleInfo[] public sales;
    mapping(uint256 => mapping(address => uint256)) public purchases;
    mapping(uint256 => uint256) public totalSales;

    /** For token purchase in BUSD */

    // Amount of BUSD raised
    uint256 public usdRaised;
    // BUSD address
    address public constant BUSD_ADDRESS =
        0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    // -----------------------------------------
    // Crowdsale Events
    // -----------------------------------------

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );
    /**
     * Event for adding new sale
     * @param rate The rate for token sale
     * @param startTime The token sale start time
     * @param limitPerAccount The limit per account for token sale
     * @param totalLimit The limit of total token sale
     * @param paused The status of token sale
     */
    event SaleAdded(
        uint256 rate,
        uint256 startTime,
        uint256 limitPerAccount,
        uint256 totalLimit,
        bool paused
    );
    /**
     * Event for adding new sale
     * @param saleType The token sale type
     * @param rate The rate for token sale
     * @param startTime The token sale start time
     * @param limitPerAccount The limit per account for token sale
     * @param totalLimit The limit of total token sale
     * @param paused The status of token sale
     */
    event SaleUpdated(
        uint256 saleType,
        uint256 rate,
        uint256 startTime,
        uint256 limitPerAccount,
        uint256 totalLimit,
        bool paused
    );
    /**
     * Event for updating wallet address
     * @param oldWallet Old wallet address
     * @param newWallet New wallet address
     */
    event WalletUpdated(address oldWallet, address newWallet);
    /**
     * Event for updating wallet address
     * @param oldKelpToken Old wallet address
     * @param newKelpToken New wallet address
     */
    event KelpTokenUpdated(address oldKelpToken, address newKelpToken);
    /**
     * Event for updating airdrop address
     * @param oldAirdrop Old airdrop address
     * @param newAirdrop New airdrop address
     */
    event AirdropUpdated(address oldAirdrop, address newAirdrop);

    // -----------------------------------------
    // Crowdsale Initializer
    // -----------------------------------------

    /**
     * @dev Initializer function
     * @param _kelpToken The Kelp token
     */
    function initialize(
        IERC20Upgradeable _kelpToken,
        address payable _wallet,
        address _airdrop
    ) external initializer {
        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        require(address(_kelpToken) != address(0), "invalid kelp address");
        require(_wallet != address(0), "invalid kelp address");
        require(_airdrop != address(0), "invalid airdrop address");

        kelpToken = _kelpToken;
        wallet = _wallet;
        airdrop = _airdrop;
    }

    // -----------------------------------------
    // Crowdsale Owner Setters
    // -----------------------------------------
    /**
     * @dev add new sale info
     * @param _rate The rate of token sale
     * @param _startTime The sale start time
     * @param _limtPerAccount The limit of token sale per account
     * @param _totalLimit The total limit of token sale
     * @param _paused The status of token sale
     */
    function addSaleInfo(
        uint256 _rate,
        uint256 _startTime,
        uint256 _limtPerAccount,
        uint256 _totalLimit,
        bool _paused
    ) external onlyOwner {
        require(_rate != 0, "invalid rate");
        require(
            _startTime >= block.timestamp,
            "can't set startTime in the past"
        );
        require(_totalLimit != 0, "invalid total limit");

        SaleInfo memory newSaleInfo = SaleInfo(
            _rate,
            _startTime,
            _limtPerAccount,
            _totalLimit,
            _paused
        );
        // add sale info
        sales.push(newSaleInfo);
        emit SaleAdded(
            _rate,
            _startTime,
            _limtPerAccount,
            _totalLimit,
            _paused
        );
    }

    /**
     * @dev update sale info
     * @param _type The type of sale
     * @param _rate The rate of token sale
     * @param _startTime The sale start time
     * @param _limtPerAccount The limit of token sale per account
     * @param _totalLimit The total limit of token sale
     * @param _paused The status of token sale
     */
    function updateSaleInfo(
        uint256 _type,
        uint256 _rate,
        uint256 _startTime,
        uint256 _limtPerAccount,
        uint256 _totalLimit,
        bool _paused
    ) external onlyOwner {
        require(_rate != 0, "invalid rate");
        require(
            _startTime >= block.timestamp,
            "can't set startTime in the past"
        );
        require(_totalLimit != 0, "invalid total limit");

        SaleInfo memory newSaleInfo = SaleInfo(
            _rate,
            _startTime,
            _limtPerAccount,
            _totalLimit,
            _paused
        );
        // update sale info
        sales[_type] = newSaleInfo;
        emit SaleUpdated(
            _type,
            _rate,
            _startTime,
            _limtPerAccount,
            _totalLimit,
            _paused
        );
    }

    /**
     * @dev update wallet address
     * @param _wallet The type of sale
     */
    function updateWallet(address payable _wallet) external onlyOwner {
        require(_wallet != address(0), "invalid address");
        address oldWallet = wallet;
        wallet = _wallet;

        emit WalletUpdated(oldWallet, wallet);
    }

    /**
     * @dev update kelp token address
     * @param _kelpToken The kelp token address
     */
    function updateKelpToken(IERC20Upgradeable _kelpToken) external onlyOwner {
        require(address(_kelpToken) != address(0), "invalid address");

        IERC20Upgradeable oldToken = kelpToken;
        kelpToken = _kelpToken;

        emit KelpTokenUpdated(address(oldToken), address(kelpToken));
    }

    /**
     * @dev update airdrop address
     * @param _airdrop The kelp token address
     */
    function updateAirdrop(address _airdrop) external onlyOwner {
        require(address(_airdrop) != address(0), "invalid address");

        address oldAirdrop = airdrop;
        airdrop = _airdrop;

        emit AirdropUpdated(oldAirdrop, airdrop);
    }

    /**
     * @dev update sale info
     * @param _type The type of sale
     * @param _paused The status of token sale
     */
    function pauseSale(uint256 _type, bool _paused) external onlyOwner {
        require(_type < sales.length, "invalid type");

        SaleInfo storage sale = sales[_type];
        // update sale info
        sale.paused = _paused;
    }

    // -----------------------------------------
    // Crowdsale external getters
    // -----------------------------------------
    /**
     * @dev return token sale rate
     * @param _type The type of sale
     */
    function getRate(uint256 _type) external view returns (uint256) {
        require(_type < sales.length, "invalid type");
        return sales[_type].rate;
    }

    /**
     * @dev return token sale limit per account
     * @param _type The type of sale
     */
    function getStartTime(uint256 _type) external view returns (uint256) {
        require(_type < sales.length, "invalid type");
        return sales[_type].startTime;
    }

    /**
     * @dev return token sale limit per account
     * @param _type The type of sale
     */
    function getLimitPerAccount(uint256 _type) external view returns (uint256) {
        require(_type < sales.length, "invalid type");
        return sales[_type].limitPerAccount;
    }

    /**
     * @dev return token sale limit per account
     * @param _type The type of sale
     */
    function getTotalLimit(uint256 _type) external view returns (uint256) {
        require(_type < sales.length, "invalid type");
        return sales[_type].totalLimit;
    }

    /**
     * @dev return token sale pause status
     * @param _type The type of sale
     */
    function isPaused(uint256 _type) external view returns (bool) {
        require(_type < sales.length, "invalid type");
        return sales[_type].paused;
    }

    /**
     * @dev return BNB price in USD
     */
    function getBNBPrice() external view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = _getBNBPrice();
        uint256 bnbPrice = reserve1.mul(10**18).div(reserve0);
        return bnbPrice;
    }

    /**
     * @dev get private sale token amount
     * @param _weiAmount Amount of wei to purchase
     * @param _type The type of token sale
     */
    function getTokenAmount(uint256 _weiAmount, uint256 _type)
        public
        view
        returns (uint256, uint256)
    {
        (uint256 reserve0, uint256 reserve1, ) = _getBNBPrice();
        uint256 bnbPrice = reserve1.mul(10**18).div(reserve0);
        return (
            _weiAmount.mul(bnbPrice).mul(10**6).div(sales[_type].rate).div(
                10**18
            ),
            bnbPrice
        );
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    fallback() external payable {
        buyActiveSaleTokensBNB(msg.sender);
    }

    /**
     * @dev receive function ***DO NOT OVERRIDE***
     */
    receive() external payable {
        buyActiveSaleTokensBNB(msg.sender);
    }

    /**
     * @dev buy tokens for current active sale
     * @param _beneficiary Address performing the token purchase
     */
    function buyActiveSaleTokensBNB(address _beneficiary) public payable {
        uint256 activeSaleType = _getActiveSaleType();
        require(activeSaleType < sales.length, "no active sales");

        buyTokensBNB(_beneficiary, activeSaleType);
    }

    /**
     * @dev buy tokens for current active sale
     * @param _beneficiary Address performing the token purchase
     * @param _amount BUSD amount
     */
    function buyActiveSaleTokensBUSD(address _beneficiary, uint256 _amount)
        public
    {
        uint256 activeSaleType = _getActiveSaleType();
        require(activeSaleType < sales.length, "no active sales");

        buyTokensBUSD(_beneficiary, activeSaleType, _amount);
    }

    /**
     * @dev low level private token purchase with BNB ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     * @param _type Type of sale
     */
    function buyTokensBNB(address _beneficiary, uint256 _type)
        public
        payable
        returns (uint256)
    {
        uint256 weiAmount = msg.value;

        require(_type < sales.length, "invalid sale");
        require(_beneficiary != address(0), "invalid address");
        require(weiAmount > 0, "insufficient amount");
        require(!sales[_type].paused, "sale is paused");
        require(
            block.timestamp >= sales[_type].startTime,
            "sale is not started yet"
        );

        // calculate sale token amount to be transferred
        (uint256 tokens, uint256 bnbPrice) = getTokenAmount(weiAmount, _type);
        // update total sales
        totalSales[_type] = totalSales[_type].add(tokens);
        require(
            totalSales[_type] <= sales[_type].totalLimit,
            "Total Sale limit exceeds"
        );
        // update personal purchased amount
        purchases[_type][_beneficiary] = purchases[_type][_beneficiary].add(
            tokens
        );
        require(
            sales[_type].limitPerAccount == 0 ||
                purchases[_type][_beneficiary] <= sales[_type].limitPerAccount,
            "Purchase limit exceeds"
        );
        // update wei raised state
        weiRaised = weiRaised.add(weiAmount);
        // deliver tokens
        _deliverTokens(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _forwardFunds();

        return bnbPrice;
    }

    /**
     * @dev low level private token purchase with BUSD ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     * @param _type Type of sale
     * @param _amount BUSD amount
     */
    function buyTokensBUSD(
        address _beneficiary,
        uint256 _type,
        uint256 _amount
    ) public {
        require(_type < sales.length, "invalid sale");
        require(_beneficiary != address(0), "invalid address");
        require(_amount > 0, "insufficient amount");
        require(!sales[_type].paused, "sale is paused");
        require(
            block.timestamp >= sales[_type].startTime,
            "sale is not started yet"
        );

        // transfer BUSD from user to treasury wallet
        IERC20(BUSD_ADDRESS).transferFrom(msg.sender, wallet, _amount);
        // calculate sale token amount to be transferred
        uint256 tokens = _amount.mul(10**6).div(sales[_type].rate);
        // update total sales
        totalSales[_type] = totalSales[_type].add(tokens);
        require(
            totalSales[_type] <= sales[_type].totalLimit,
            "Total Sale limit exceeds"
        );
        // update personal purchased amount
        purchases[_type][_beneficiary] = purchases[_type][_beneficiary].add(
            tokens
        );
        require(
            sales[_type].limitPerAccount == 0 ||
                purchases[_type][_beneficiary] <= sales[_type].limitPerAccount,
            "Purchase limit exceeds"
        );
        // update wei raised state
        usdRaised = usdRaised.add(_amount);
        // deliver tokens
        _deliverTokens(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, _amount, tokens);
    }

    // -----------------------------------------
    // Crowdsale internal interface
    // -----------------------------------------

    /**
     * @dev Source of tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        kelpToken.transferFrom(airdrop, _beneficiary, _tokenAmount);
    }

    /**
     * @dev get active sale
     */
    function _getActiveSaleType() internal view returns (uint256) {
        for (uint256 i = 0; i < sales.length; i++) {
            if (!sales[i].paused) {
                return i;
            }
        }

        return sales.length - 1;
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    /**
     * @dev return BNB price in USD
     */
    function _getBNBPrice()
        internal
        view
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        return IPancakePair(PANCAKE_PAIR_ADDRESS).getReserves();
    }
}
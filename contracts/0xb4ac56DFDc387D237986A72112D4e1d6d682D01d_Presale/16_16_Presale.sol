// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IPreIDOBase.sol";

contract Presale is IPreIDOBase, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    struct TokenInfo {
        address priceFeed;
        int256 rate;
        uint8 decimals;
        uint256 raisedAmount; // how many tokens has been raised so far
    }
    struct OrderInfo {
        address beneficiary;
        uint256 amount;
        uint256 releaseOnBlock;
        bool claimed;
    }

    // uint256 private constant MIN_LOCK = 365 days; // 1 year;
    // / @dev discountsLock[rate] = durationInSeconds
    // mapping(uint8 => uint256) public discountsLock;
    /// @dev supportedTokens[tokenAddress] = TokenInfo
    mapping(address => TokenInfo) public supportedTokens;
    /// @dev balanceOf[investor] = balance
    mapping(address => uint256) public override balanceOf;
    /// @dev orderIds[investor] = array of order ids
    mapping(address => uint256[]) private orderIds;
    /// @dev orders[orderId] = OrderInfo
    mapping(uint256 => OrderInfo) public override orders;
    /// @dev The latest order id for tracking order info
    uint256 private latestOrderId = 0;
    /// @notice The total amount of tokens had been distributed
    uint256 public totalDistributed;
    /// @notice The minimum investment funds for purchasing tokens in USD
    uint256 public minInvestment;
    /// @notice The initial token price in USD
    uint256 public tokenPrice;
    /// @notice The token used for pre-sale
    IERC20Metadata public immutable override token;
    /// @dev The price feed address of native token
    AggregatorV2V3Interface internal immutable priceFeed;
    /// @notice The block timestamp before starting the presale purchasing
    // uint256 public immutable notBeforeBlock;
    /// @notice The block timestamp after ending the presale purchasing
    // uint256 public immutable notAfterBlock;

    constructor(
        address _token,
        address _priceFeed
        // uint256 _notBeforeBlock,
        // uint256 _notAfterBlock
    ) {
        require(
            _token != address(0) && _priceFeed != address(0),
            "invalid contract address"
        ); // ICA
        // require(
        //     _notBeforeBlock >= block.timestamp &&
        //         _notAfterBlock > _notBeforeBlock,
        //     "invalid presale schedule"
        // ); // IPS
        token = IERC20Metadata(_token);
        priceFeed = AggregatorV2V3Interface(_priceFeed);
        // notBeforeBlock = _notBeforeBlock;
        // notAfterBlock = _notAfterBlock;
        tokenPrice = 10;

        // initialize discounts rate lock duration
        // discountsLock[10] = MIN_LOCK;
        // discountsLock[20] = 2 * MIN_LOCK;
        // discountsLock[30] = 3 * MIN_LOCK;
    }

    receive() external payable {
        int256 price = getPrice();
        _order(msg.value, 18, price, priceFeed.decimals(), 10); // default to 10% discount rate
    }

    function investorOrderIds(address investor)
        external
        view
        override
        returns (uint256[] memory ids)
    {
        uint256[] memory arr = orderIds[investor];
        return arr;
    }

    function order(uint8 discountsRate) external payable {
        int256 price = getPrice();
        _order(msg.value, 18, price, priceFeed.decimals(), discountsRate);
    }

    function orderToken(
        address fundsAddress,
        uint256 fundsAmount,
        uint8 discountsRate
    ) external {
        TokenInfo storage tokenInfo = supportedTokens[fundsAddress];
        require(fundsAmount > 0, "invalid token amount value"); // ITA
        require(
            tokenInfo.priceFeed != address(0),
            "purchasing of tokens was not supported"
        ); // TNS

        tokenInfo.rate = getPriceToken(fundsAddress);
        IERC20(fundsAddress).safeTransferFrom(
            msg.sender,
            address(this),
            fundsAmount
        );
        tokenInfo.raisedAmount = tokenInfo.raisedAmount.add(fundsAmount);
        _order(
            fundsAmount,
            IERC20Metadata(fundsAddress).decimals(),
            tokenInfo.rate,
            tokenInfo.decimals,
            discountsRate
        );
    }

    function _order(
        uint256 amount,
        uint8 _amountDecimals,
        int256 price,
        uint8 _priceDecimals,
        uint8 discountsRate
    ) internal {
        require(
            amount.mul(uint256(price)).div(
                10**(_amountDecimals + _priceDecimals)
            ) >= minInvestment,
            "the investment amount does not reach the minimum amount required"
        ); // LMI

        // uint256 lockDuration = discountsLock[discountsRate];
        // require(
        //     lockDuration >= MIN_LOCK,
        //     "the lock duration does not reach the minimum duration required"
        // ); // NDR

        // uint256 releaseOnBlock = block.timestamp.add(lockDuration);
        uint256 tokenPriceX4 = (tokenPrice * 10000 * (100 - discountsRate)) / 100;
        uint256 distributeAmount = amount.mul(uint256(price)).div(tokenPriceX4);
        uint8 upperPow = token.decimals() + 4; // 4(token price decimals) => 10^4 = 22
        uint8 lowerPow = _amountDecimals + _priceDecimals;
        if (upperPow >= lowerPow) {
            distributeAmount = distributeAmount.mul(10**(upperPow - lowerPow));
        } else {
            distributeAmount = distributeAmount.div(10**(lowerPow - upperPow));
        }
        require(
            totalDistributed + distributeAmount <=
                token.balanceOf(address(this)),
            "there is not enough supply token to be distributed"
        ); // NET

        orders[++latestOrderId] = OrderInfo(
            msg.sender,
            distributeAmount,
            0,
            false
        );
        totalDistributed = totalDistributed.add(distributeAmount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(distributeAmount);
        orderIds[msg.sender].push(latestOrderId);

        emit LockTokens(
            msg.sender,
            latestOrderId,
            distributeAmount,
            block.timestamp,
            0
        );
    }

    function redeem(uint256 orderId) external {
        require(orderId <= latestOrderId, "the order ID is incorrect"); // IOI

        OrderInfo storage orderInfo = orders[orderId];
        require(msg.sender == orderInfo.beneficiary, "not order beneficiary"); // NOO
        require(orderInfo.amount > 0, "insufficient redeemable tokens"); // ITA
        // require(
        //     block.timestamp >= orderInfo.releaseOnBlock,
        //     "tokens are being locked"
        // ); // TIL
        // require(!orderInfo.claimed, "tokens are ready to be claimed"); // TAC

        uint256 amount = safeTransferToken(
            orderInfo.beneficiary,
            orderInfo.amount
        );
        orderInfo.claimed = true;
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);

        emit UnlockTokens(orderInfo.beneficiary, orderId, amount);
    }

    function getPrice() public view returns (int256 price) {
        price = priceFeed.latestAnswer();
    }

    function getPriceToken(address fundAddress)
        public
        view
        returns (int256 price)
    {
        price = AggregatorV2V3Interface(supportedTokens[fundAddress].priceFeed)
            .latestAnswer();
    }

    function remainingTokens() public view returns (uint256 remainingToken) {
        remainingToken = token.balanceOf(address(this)) - totalDistributed;
    }

    function collectFunds(address fundsAddress) external onlyOwner {
        uint256 amount = IERC20(fundsAddress).balanceOf(address(this));
        require(amount > 0, "insufficient funds for collection"); // NEC
        IERC20(fundsAddress).transfer(msg.sender, amount);
    }

    function collect() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "insufficient funds for collection"); // NEC
        payable(msg.sender).transfer(amount);
    }

    function setMinInvestment(uint256 _minInvestment) external onlyOwner {
        require(_minInvestment > 0, "Invalid input value"); // IIV
        minInvestment = _minInvestment;
    }

    function setTokenPriceInUSD(uint256 _usd) external onlyOwner {
        require(_usd > 0, "Invalid input value"); // IIV
        tokenPrice = _usd;
    }

    function setSupportedToken(address _token, address _priceFeed)
        external
        onlyOwner
    {
        require(_token != address(0), "invalid token address"); // ITA
        require(_priceFeed != address(0), "invalid oracle price feed address"); // IOPA

        supportedTokens[_token].priceFeed = _priceFeed;
        supportedTokens[_token].decimals = AggregatorV2V3Interface(_priceFeed)
            .decimals();
        supportedTokens[_token].rate = AggregatorV2V3Interface(_priceFeed)
            .latestAnswer();
    }

    function safeTransferToken(address _to, uint256 _amount)
        internal
        returns (uint256 amount)
    {
        uint256 bal = token.balanceOf(address(this));
        if (bal < _amount) {
            token.safeTransfer(_to, bal);
            amount = bal;
        } else {
            token.safeTransfer(_to, _amount);
            amount = _amount;
        }
    }

    // modifier inPresalePeriod() {
    //     require(
    //         block.timestamp > notBeforeBlock,
    //         "Pre-sale has not been started"
    //     ); // PNS
    //     require(block.timestamp < notAfterBlock, "Pre-sale has already ended"); // PEN
    //     _;
    // }

    // modifier afterPresalePeriod() {
    //     require(block.timestamp > notAfterBlock, "Pre-sale is still ongoing"); // PNE
    //     _;
    // }

    // modifier beforePresaleEnd() {
    //     require(block.timestamp < notAfterBlock, "Pre-sale has already ended"); // PEN
    //     _;
    // }
}
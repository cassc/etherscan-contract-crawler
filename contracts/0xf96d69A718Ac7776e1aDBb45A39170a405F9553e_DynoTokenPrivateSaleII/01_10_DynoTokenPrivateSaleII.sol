// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

interface IPreIDOEvents {
  /// @notice Emitted when tokens is locked in the pre-IDO contract
  /// @param sender The sender address whose the locked tokens belong
  /// @param id The order ID used to tracking order information
  /// @param amount The amount of tokens to be locked
  /// @param lockOnBlock The block timestamp when tokens locked inside the pre-IDO
  /// @param releaseOnBlock The block timestamp when tokens can be redeem or claimed from the time-locked contract
  event LockTokens(address indexed sender, uint256 indexed id, uint256 amount, uint256 lockOnBlock, uint256 releaseOnBlock);   

  /// @notice Emitted when tokens is unlocked or claimed by `receiver` from the time-locked contract
  /// @param receiver The receiver address where the tokens to be distributed to
  /// @param id The order ID used to tracking order information
  /// @param amount The amount of tokens has been distributed
  event UnlockTokens(address indexed receiver, uint256 indexed id, uint256 amount);
}


interface IPreIDOImmutables {
  /// @notice The token contract that used to distribute to investors when those tokens is unlocked
  /// @return The token contract
  function token() external view returns(IERC20MetadataUpgradeable);
}

interface IPreIDOState {
  /// @notice Look up information about a specific order in the pre-IDO contract
  /// @param id The order ID to look up
  /// @return beneficiary The investor address whose `amount` of tokens in this order belong to,
  /// amount The amount of tokens has been locked in this order,
  /// releaseOnBlock The block timestamp when tokens can be redeem or claimed from the time-locked contract,
  /// claimed The status of this order whether it's claimed or not.
  function orders(uint256 id) external view returns(
    address beneficiary,
    uint256 amount,
    uint256 releaseOnBlock,
    bool claimed
  );

  /// @notice Look up all order IDs that a specific `investor` address has been order in the pre-IDO contract
  /// @param investor The investor address to look up
  /// @return ids All order IDs that the `investor` has been order
  function investorOrderIds(address investor) external view returns(uint256[] memory ids);

  /// @notice Look up locked-balance of a specific `investor` address in the pre-IDO contract
  /// @param investor The investor address to look up
  /// @return balance The locked-balance of the `investor`
  function balanceOf(address investor) external view returns(uint256 balance);
}

interface IPreIDOBase is IPreIDOImmutables, IPreIDOState, IPreIDOEvents {

}

contract DynoTokenPrivateSaleII is IPreIDOBase, Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using AddressUpgradeable for address;

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

    uint256 public MIN_LOCK; // 1 month;
    /// @dev discountsLock[rate] = durationInSeconds
    mapping(uint8 => uint256) public discountsLock;
    /// @dev supportedTokens[tokenAddress] = TokenInfo
    mapping(address => TokenInfo) public supportedTokens;
    /// @dev balanceOf[investor] = balance
    mapping(address => uint256) public override balanceOf;
    /// @dev orderIds[investor] = array of order ids
    mapping(address => uint256[]) private orderIds;
    /// @dev orders[orderId] = OrderInfo
    mapping(uint256 => OrderInfo) public override orders;
    /// @dev The latest order id for tracking order info
    uint256 private latestOrderId;
    /// @notice The total amount of tokens had been distributed
    uint256 public totalDistributed;
    /// @notice The minimum investment funds for purchasing tokens in USD
    uint256 public minInvestment;
    /// @notice The token used for pre-sale
    IERC20MetadataUpgradeable public override token;
    /// @dev The price feed address of native token
    AggregatorV2V3Interface internal priceFeed;
    /// @notice The block timestamp before starting the presale purchasing
    uint256 public notBeforeBlock;
    /// @notice The block timestamp after ending the presale purchasing
    uint256 public notAfterBlock;

    uint256 public tokenSalePrice;

    function initialize (
        address _token,
        address _priceFeed,
        uint256 _notBeforeBlock,
        uint256 _notAfterBlock
    ) public initializer{
        require(
            _token != address(0) && _priceFeed != address(0),
            "invalid contract address"
        ); // ICA
        require(
                _notAfterBlock > _notBeforeBlock,
            "invalid presale schedule"
        ); // IPS

        __Ownable_init();
        token = IERC20MetadataUpgradeable(_token);
        priceFeed = AggregatorV2V3Interface(_priceFeed);
        notBeforeBlock = _notBeforeBlock;
        notAfterBlock = _notAfterBlock;

        // initialize discounts rate lock duration
        MIN_LOCK = 30 days; // 1 month;

        discountsLock[5] = MIN_LOCK;
        discountsLock[10] = 2 * MIN_LOCK;
        discountsLock[15] = 3 * MIN_LOCK;

        minInvestment = 100;
        latestOrderId = 0;
        tokenSalePrice = 15000000000000000000;
    }

    receive() external payable inPresalePeriod {
        int256 price = getPrice();
        _order(msg.value, 18, price, priceFeed.decimals(), 5); // default to 5% discount rate
    }


    function setMinLockPeriod(uint256 _seconds) public onlyOwner{
        require(
                _seconds > 0,
            "time must be greater than zero"
        ); // IPS
        MIN_LOCK = _seconds;
    }


    function setTokenPrice(uint256 _pricesale) public onlyOwner{
        require(
                _pricesale > 0,
            "price must be greater than zero"
        ); // IPS
        tokenSalePrice = _pricesale;
    }


    function setTokenAddress(address _token) public onlyOwner{
        require(
                _token != address(0),
            "zero address not valid"
        ); // IPS
        token = IERC20MetadataUpgradeable(_token);
    }


    function setSaleTime(uint256 _starttime , uint256 _endtime) public onlyOwner{
        require(
                _endtime > _starttime,
            "invalid presale schedule"
        ); // IPS
        notBeforeBlock = _starttime;
        notAfterBlock = _endtime;
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

    function order(uint8 discountsRate) external payable inPresalePeriod {
        int256 price = getPrice();
        _order(msg.value, 18, price, priceFeed.decimals(), discountsRate);
    }

    function countGetToken(address _tokenAddress ,uint256 _amount , uint8 _discountsRate  ) public view returns(uint256){
        require(_tokenAddress != address(0) , "Invalid Fund Address");
        require(_amount > 0 , "Invalid Amount Enter");
        uint8 _priceDecimals =  priceFeed.decimals();
        uint8 _amountDecimals = 18;
        int256 price = getPrice();
        if(_tokenAddress != address(0)){
            TokenInfo storage tokenInfo = supportedTokens[_tokenAddress];
            require(
            tokenInfo.priceFeed != address(0),
            "purchasing of tokens was not supported"
        ); // TNS
           _priceDecimals = IERC20MetadataUpgradeable(_tokenAddress).decimals();
           _amountDecimals = tokenInfo.decimals;
           price = getPriceToken(_tokenAddress);
        }
        
        uint256 tokenPriceX4 = (tokenSalePrice.div(10**14) * (100 - _discountsRate)) / 100; // 300 = 0.03(default price) * 10^4
        uint256 distributeAmount = _amount.mul(uint256(price)).div(tokenPriceX4);
        uint8 upperPow = token.decimals() + 4; // 4(token price decimals) => 10^4 = 22
        uint8 lowerPow = _amountDecimals + _priceDecimals;
        if (upperPow >= lowerPow) {
            distributeAmount = distributeAmount.mul(10**(upperPow - lowerPow));
        } else {
            distributeAmount = distributeAmount.div(10**(lowerPow - upperPow));
        }

        return distributeAmount;
    }

    function orderToken(
        address fundsAddress,
        uint256 fundsAmount,
        uint8 discountsRate
    ) external inPresalePeriod {
        TokenInfo storage tokenInfo = supportedTokens[fundsAddress];
        require(fundsAmount > 0, "invalid token amount value"); // ITA
        require(
            tokenInfo.priceFeed != address(0),
            "purchasing of tokens was not supported"
        ); // TNS

        tokenInfo.rate = getPriceToken(fundsAddress);
        IERC20Upgradeable(fundsAddress).safeTransferFrom(
            msg.sender,
            address(this),
            fundsAmount
        );
        tokenInfo.raisedAmount = tokenInfo.raisedAmount.add(fundsAmount);
        _order(
            fundsAmount,
            IERC20MetadataUpgradeable(fundsAddress).decimals(),
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

        uint256 lockDuration = discountsLock[discountsRate];
        require(
            lockDuration >= MIN_LOCK,
            "the lock duration does not reach the minimum duration required"
        ); // NDR

        uint256 releaseOnBlock = notAfterBlock + lockDuration;
        uint256 tokenPriceX4 = (tokenSalePrice.div(10**14) * (100 - discountsRate)) / 100; // 300 = 0.03(default price) * 10^4
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
            releaseOnBlock,
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
            releaseOnBlock
        );
    }

    function redeem(uint256 orderId) external {
        require(orderId <= latestOrderId, "the order ID is incorrect"); // IOI

        OrderInfo storage orderInfo = orders[orderId];
        require(msg.sender == orderInfo.beneficiary, "not order beneficiary"); // NOO
        require(orderInfo.amount > 0, "insufficient redeemable tokens"); // ITA
        require(
            block.timestamp >= orderInfo.releaseOnBlock,
            "tokens are being locked"
        ); // TIL
        require(!orderInfo.claimed, "tokens are ready to be claimed"); // TAC

        uint256 amount = safeTransferToken(
            orderInfo.beneficiary,
            orderInfo.amount
        );
        orderInfo.claimed = true;
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);

        emit UnlockTokens(orderInfo.beneficiary, orderId, amount);
    }

    function fixDiscountsLock(uint256 _duration) external onlyOwner
    {
        discountsLock[5] = _duration;
        discountsLock[10] = 2 * _duration;
        discountsLock[15] = 3 * _duration;
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

    function remainingTokens()
        public
        view
        inPresalePeriod
        returns (uint256 remainingToken)
    {
        remainingToken = token.balanceOf(address(this)) - totalDistributed;
    }

    function getRaisedFunds(address fundsAddress)
        external
        view
        returns (uint256 raisedFunds)   
    {
        int256 price = AggregatorV2V3Interface(supportedTokens[fundsAddress].priceFeed)
            .latestAnswer();
        uint256 amount = supportedTokens[fundsAddress].raisedAmount;

        raisedFunds = amount.mul(uint256(price)).mul(1000).div(10**(IERC20MetadataUpgradeable(fundsAddress).decimals() + supportedTokens[fundsAddress].decimals));
    }

    function collectFunds(address fundsAddress)
        external
        onlyOwner
        afterPresalePeriod
    {
        uint256 amount = IERC20Upgradeable(fundsAddress).balanceOf(address(this));
        require(amount > 0, "insufficient funds for collection"); // NEC
        IERC20Upgradeable(fundsAddress).transfer(msg.sender, amount);
    }

    function collect() external onlyOwner afterPresalePeriod {
        uint256 amount = address(this).balance;
        require(amount > 0, "insufficient funds for collection"); // NEC
        payable(msg.sender).transfer(amount);
    }

    function setMinInvestment(uint256 _minInvestment)
        external
        onlyOwner
        beforePresaleEnd
    {
        require(_minInvestment > 0, "Invalid input value"); // IIV
        minInvestment = _minInvestment;
    }

    function setSupportedToken(address _token, address _priceFeed)
        external
        onlyOwner
        beforePresaleEnd
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

    modifier inPresalePeriod() {
        require(
            block.timestamp > notBeforeBlock,
            "Pre-sale has not been started "
        ); // PNS
        require(block.timestamp < notAfterBlock, "Pre-sale has already ended "); // PEN
        _;
    }

    modifier afterPresalePeriod() {
        require(block.timestamp > notAfterBlock, "Pre-sale is still ongoing"); // PNE
        _;
    }

    modifier beforePresaleEnd() {
        require(block.timestamp < notAfterBlock, "Pre-sale has already ended"); // PEN
        _;
    }
}
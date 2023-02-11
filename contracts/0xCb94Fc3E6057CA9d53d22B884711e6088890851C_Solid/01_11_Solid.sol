//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.0;

/// @title A Payment Manager
/// @author Blokku-Chan

/// @notice Used to calculate and fetch 1hr TWAP prices for non-stablecoin payment
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

/// @notice Used to fetch Uniswap pool data
interface IUniswapV3Factory {
  function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

/// @notice Used to handle transfers
interface TOKEN {
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function decimals() external view returns (uint8);
}

/// @notice You can use this contract to create or subscribe to payment plans
/// @dev Uint packing is used for a number of variables
contract Solid {
  uint256 constant gasCommit = 21000 + 396;
  
  /// @dev Stored to convert decimal points when using alternative stablecoins
  uint256 public mainStableDecimals;

  /// @notice Uniswap V3 Factory address
  address public immutable uniV3Factory;
  
  /// @notice The chains wrapped native token address
  address public immutable wrappedNativeToken;
  
  /// @notice Owner of the contract is able to manage accepted tokens
  address public owner;
  
  /// @notice Main stable is the most popular/accessible stablecoin on the chain
  address public mainStable;

  /// @notice Stablecoin addresses in here are accepted by the contract
  mapping(address => uint256) public stableIsAllowed;
  
  /// @notice Token addresses in here are accepted by the contract
  mapping(address => uint256) public tokenIsAllowed;
  
  /// @notice Plan details are stored in here, this includes: Price, Billing frequency, Bulk discounts, and timestamp of most recent change
  /// @dev The plan mapping key is a packing of the uint160 vendors address and a plan id, because it is cheaper than a nested mapping
  /// @dev The plan values are packed instead of stored as structs, they are: uint40 price, uint48 billingPeriod, uint48 timestamp, uint120 discount
  mapping(uint256 => uint256) public plan;
  
  /// @notice Last payment contains the timestamp of a users last payment to a chosen vendors plan, it also has the number of billing periods paid for in bulk
  /// @dev The lastPayment mapping key is a nested mapping of a plan key => users address
  /// @dev The lastPayment values are packed as well, they are: uint48 timestamp and uint208 periods (the number of billing periods purchased in bulk)
  mapping(uint256 => mapping(address => uint256)) public lastPayment;

  /// @notice used to verify attestation chain of origin
  uint256 public chainId;

  event Payment(address indexed user, address indexed vendor, uint256 indexed plan, address token, uint256 amount, uint256 periods, bool firstTime, uint256 timestamp);
  event Unsubscription(address indexed user, address indexed vendor, uint256 plan, uint256 timestamp);
  event PlanSet(address indexed vendor, uint256 planId);
  event NewStable(address stable);
  event NewToken(address token);
  event NewOwner(address token);

  /// @notice This defines the owner, the address of the Uniswap V3 Factory and the address of the wrapped native token
  constructor(uint256 _chainId, address _uniV3Factory, address _wrappedNativeToken) payable {
    require((_uniV3Factory != address(0)) && (_wrappedNativeToken != address(0)), "That is the zero address");
    chainId = _chainId;
    owner = msg.sender;
    uniV3Factory = _uniV3Factory;
    wrappedNativeToken = _wrappedNativeToken;
  }

  receive() external payable {}

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner");
    _;
  }

  /// @dev Different checks to ensure fairness in plan creation, billingPeriods set to low allow for too frequent payment collections, and so cannot be allowed
  modifier validPlan(uint256 _billingPeriod, uint256 _price, uint256 _discount) {
    uint256 decimals = mainStableDecimals;
    require(_price >= 10 * 10**decimals && _price <= 1000000 * 10**decimals, "Price < 10 or > 1M");
    require(_billingPeriod >= 86400 && _billingPeriod < 281474976710656, "Billing < 1 day or not 48bit");
    require(_discount <= 5000, "Discount greater than 50%");
    _;
  }
  
  /// @dev Used to guard against tokens that are not accepted
  modifier allowedToken(address _token) {
    require(stableIsAllowed[_token] == 1 || tokenIsAllowed[_token] == 1, "Token not allowed");
    _;
  }

  /// @dev Used to prevent free subscriptions not initiated by the vendor
  modifier checkPeriods(uint256 _periods) {
    require(_periods != 0, "Select a number of periods");
    _;
  }

  function setOwner(address _owner) external onlyOwner {
    require(_owner != address(0), "That is the zero address");
    owner = _owner;
    emit NewOwner(_owner);
  }
  
  /// @notice Ownership is intended to be temporary, once contracts can run by themselves ownership will be removed
  function removeOwnership() external onlyOwner {
    owner = address(0);
    emit NewOwner(address(0));
  }
  
  /// @notice The main stablecoin is used to check for prices on Uniswap V3 Pools
  function setMainStable(address _mainStable) external onlyOwner {
    require(_mainStable != address(0), "That is the zero address");
    mainStable = _mainStable;
    stableIsAllowed[_mainStable] = 1;
    mainStableDecimals = TOKEN(_mainStable).decimals();
    emit NewStable(_mainStable);
  }

  /// @param _stables: An array of stablecoin addresses to add to the allow list
  function addStables(address[] memory _stables) external onlyOwner {
    for (uint256 x; x < _stables.length; ++x) {
      require(_stables[x] != address(0), "That is the zero address");
      stableIsAllowed[_stables[x]] = 1;
      emit NewStable(_stables[x]);
    }
  }
  
  /// @param _stables: An array of stablecoin addresses to remove from the allow list
  function removeStables(address[] memory _stables) external onlyOwner {
    for (uint256 x; x < _stables.length; ++x) {
      delete stableIsAllowed[_stables[x]];
    }
  }

  /// @param _tokens: An array of token addresses to add to the allow list
  function addTokens(address[] memory _tokens) external onlyOwner {
    for (uint256 x; x < _tokens.length; ++x) {
      require(_tokens[x] != address(0), "That is the zero address");
      tokenIsAllowed[_tokens[x]] = 1;
      emit NewToken(_tokens[x]);
    }
  }
  
  /// @param _tokens: An array of token addresses to remove from the allow list
  function removeTokens(address[] memory _tokens) external onlyOwner {
    for (uint256 x; x < _tokens.length; ++x) {
      delete tokenIsAllowed[_tokens[x]];
    }
  }

  /// @notice Sends accrued fees, primarily to be used to pay for subscription automation, to a recipient
  function withdrawNative(uint256 _amount, address _recipient) external onlyOwner {
    require(_recipient != address(0), "That is the zero address");
    payable(_recipient).transfer(_amount);
  }

  function withdrawToken(uint256 _amount, address _recipient, address _token) external onlyOwner {
    require(_recipient != address(0), "That is the zero address");
    require(TOKEN(_token).transfer(_recipient, _amount), "Error with token transfer");
  }

  /// @return price: the amount of the main stablecoin accepted for a plan, per period
  /// @return billingPeriod: the number of seconds to wait before user is expected to pay again
  /// @return timestamp: the last time the plan details were edited, users must resubscribe if plan details are edited
  /// @return discount: The maximum discount given for buying multiple billing periods at once, up to a year
  function getPlan(address _vendor, uint256 _planId) external view returns(uint256, uint256, uint256, uint256) {
    return _getPlan(_vendor, _planId);
  }

  function _getPlan(address _vendor, uint256 _planId) internal view returns(uint256, uint256, uint256, uint256) {
    uint256 _planUint = plan[_getPlanKey(_vendor, _planId)];
    uint256 price = uint256(uint80(_planUint));
    uint256 billingPeriod = uint256(uint48(_planUint>>128));
    uint256 timestamp = uint256(uint48(_planUint>>176));
    uint256 discount = uint256(uint16(_planUint>>224));
    
    return (price, billingPeriod, timestamp, discount);
  }
  
  /// @return planKey: the vendor address and plan id are packed into a uint and returned
  function _getPlanKey(address _vendor, uint256 _planId) internal pure returns (uint256) {
    uint256 _planKey = uint256(_vendor);
    return _planKey |= _planId<<160;
  }

  /// @dev Unpacks the values in the lastPayment uint
  /// @return timestamp: the last time the user paid for a vendors plan
  /// @return periods: the number of periods bought in bulk
  function getLastPayment(address _vendor, uint256 _planId, address _user) external view returns (uint256, uint256) {
    uint256 _planKey = _getPlanKey(_vendor, _planId);
    return _getLastPayment(_planKey, _user);
  }

  function _getLastPayment(uint256 _planKey, address _user) internal view returns (uint256, uint256) {
    uint256 _lastPayment = lastPayment[_planKey][_user];

    return (uint256(uint48(_lastPayment)), uint256(uint8(_lastPayment>>48)));
  }

  /// @notice Checks wnativeer the user has paid for a plan, and allows for a maximum 2 week buffer depending on length of billing period to allow for late payments
  /// @return bool: true if user is a valid subscriber
  function isValidSubscriber(address _vendor, address _user, uint256 _planId) external view returns (bool) {
    return _isValidSubscriber(_vendor, _user, _planId);
  }
  
  function _isValidSubscriber(address _vendor, address _user, uint256 _planId) internal view returns (bool) {
    uint256 planKey = _getPlanKey(_vendor, _planId);
    (, uint256 billingPeriod, uint256 timestamp,) = _getPlan(_vendor, _planId);
    uint256 buffer = billingPeriod / 4;
    (uint256 _lastPayment,) = _getLastPayment(planKey, _user);
    uint256 elapsedTime = block.timestamp - _lastPayment;

    if (elapsedTime > block.timestamp) elapsedTime = 0;

    if (timestamp > _lastPayment || (elapsedTime > billingPeriod + buffer && elapsedTime > billingPeriod + 1209600)) return false;
    else return true;
  }

  /// @notice Handles plan creation and updating
  /// @param _price: the amount of the main stablecoin a vendor will accept for a plan, per period
  /// @param _billingPeriod: the number of seconds to wait before user is expected to pay again
  /// @param _planId: the id of the selected plan
  /// @param _discount: The maximum discount given for buying multiple billing periods at once, up to a year
  function setPlan(uint256 _price, uint256 _billingPeriod, uint256 _planId, uint256 _discount) external validPlan(_billingPeriod, _price, _discount) {
    _setPlan(_price, _billingPeriod, _planId, _discount);
  }

  function _setPlan(uint256 _price, uint256 _billingPeriod, uint256 _planId, uint256 _discount) internal {
    uint256 _plan = _price;
    _plan |= _billingPeriod<<128;
    _plan |= block.timestamp<<176;
    _plan |= _discount<<224;

    plan[_getPlanKey(msg.sender, _planId)] = _plan;

    emit PlanSet(msg.sender, _planId);
  }
  
  /// @param _planId: the id of the plan to be deleted
  function deletePlan(uint256 _planId) external {
    _deletePlan(_planId);
  }
  
  function _deletePlan(uint256 _planId) internal {
    delete plan[_getPlanKey(msg.sender, _planId)];
  }

  /// @notice Vendors can add a free subscriber
  /// @dev Subscriber is given a timestamp so far ahead, it will likely never be called to charge for payment
  function addSubscriber(address _user, uint256 _planId) external {
    uint256 planKey = _getPlanKey(msg.sender, _planId);
    uint256 maxTimeStamp = 281474976710655;
    
    lastPayment[planKey][_user] = maxTimeStamp |= 1<<48;

    emit Payment(_user, msg.sender, _planId, address(0), 0, 0, true, block.timestamp);
  }

  /// @notice Vendors can remove a subscriber
  function removeSubscriber(address _user, uint256 _planId) external {
    uint256 planKey = _getPlanKey(msg.sender, _planId);

    delete lastPayment[planKey][_user];
    
    emit Unsubscription(_user, msg.sender, _planId, block.timestamp);
  }
  
  /// @return bulkDiscountPrice this discount is calculated by accounting for the max discount allowed and the number of cycles being purchased
  function _getDiscountPrice(uint256 _price, uint256  _periods, uint256 _cycleLength, uint256 _discount) internal pure returns (uint256) {
    // if only one cycle is selected, no discount is applied
    if (_periods == 1) return _price;

    // gets the number of periods in a year for a given period length, rounding odd number edgecases
    // e.g, max periods for 1 month + 1 day period length is shown as 11, instead of 11.6
    uint256 maxPeriods = (31556952 - (31556952 % _cycleLength)) / _cycleLength;
    
    // multiplier is the discount applied per period
    uint256 multiplier = _discount * 10**5 / maxPeriods;

    // discount based on the number of periods selected
    uint256 derivedDiscount = multiplier * _periods;
    
    // the natural bulk price when mulitplied by selected periods
    uint256 bulkPrice = _price * _periods;
    
    // disocunt applied to the bulk price
    uint256 bulkDiscountPrice = bulkPrice - (bulkPrice * derivedDiscount) / 10**9;

    return bulkDiscountPrice;
  }

  /// @return twapAmount amount of alternative tokens accepted based on a 1hr TWAP price
  function getTwapAmount(address _token, uint256 _amountIn) external view returns (uint256) {
    return _getTwapAmount(_token, _amountIn);
  }

  function _getTwapAmount(address _token, uint256 _amountIn) internal view returns (uint256) {
    // finds the Uniswap v3 pool address using the main stablecoin
    address pool = IUniswapV3Factory(uniV3Factory).getPool(mainStable, _token, 3000);

    // defines the 1 hr TWAP
    uint32 secondsAgo = 3600;
    uint32[] memory secondsAgos = new uint32[](2);
    
    secondsAgos[0] = secondsAgo;
    secondsAgos[1] = 0;
    
    // tick twap math n' magic
    (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);
    int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
    int24 tick = int24(tickCumulativesDelta / secondsAgo);

    if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) tick--;
    
    return OracleLibrary.getQuoteAtTick(tick, uint128(_amountIn), mainStable, _token);
  }
  
  /// @dev executes transfers and collects fees
  function _transferToken(address _token, address _vendor, address _user, uint256 amount, uint256 _gasAtStart, uint256 _price, uint256 _decimalsDiff) internal {
    uint256 gasSpent = _gasAtStart - gasleft() + 50000;
    uint256 gas = gasSpent * tx.gasprice;
    uint256 nativeAmount = _getTwapAmount(wrappedNativeToken, (_price / 10**_decimalsDiff));
    uint256 refund = (gas * _price) / nativeAmount;

    require(TOKEN(_token).transferFrom(_user, _vendor, amount - refund) && TOKEN(_token).transferFrom(_user, msg.sender, refund), "Error with token transfer");
  }

  /// @dev handles most of the state updates for user payments
  function _confirmation(address _subscriber, address _vendor, uint256 _planId, uint256 _periods, address _token, uint256 _amount) internal {
    uint256 planKey = _getPlanKey(_vendor, _planId);
    uint256 _lastPayment = lastPayment[planKey][_subscriber];
    bool firstTime;

    if (_lastPayment == 0) {
      _lastPayment = block.timestamp;
      firstTime = true;
    } 

    uint256 timestamp = _lastPayment * _periods;
    
    // timestamp and periods packed here to save as last payment
    uint256 confirmation = timestamp |= _periods<<48;

    lastPayment[planKey][_subscriber] = confirmation;

    emit Payment(_subscriber, _vendor, _planId, _token, _amount, _periods, firstTime, block.timestamp);
  }

  /// @dev handles most of the state updates for user payments
  /// @return formattedPrice scales the decimals appropriately
  /// @return decimalsDiff the difference in decimals
  function _fixDecimals(address _token, uint256 price) internal view returns (uint256, uint256) {
    uint256 decimalsDiff = TOKEN(_token).decimals() - mainStableDecimals;
    return (price * 10**decimalsDiff, decimalsDiff);
  }
  
  function _split (bytes memory _sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
    require(_sig.length == 65, "invalid signature length");
    
    assembly {
      r := mload(add(_sig, 32)) 
      s:= mload (add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    
    return (r, s, v);
  }

  /// @notice Allows users to subscribe to a plan via signature to avoid gas fees with accepted tokens
  function subscribeWithAttestation(bytes memory _signature, address _vendor, uint256 _planId, uint256 _periods, address _token) external {
    bytes32 eip712Domain = keccak256(abi.encode(
      keccak256("EIP712Domain(uint256 chainId,address verifyingContract)"),
      chainId,
      address(this)
    ));
    bytes32 attestation = keccak256(abi.encode(
      keccak256("Attestation(address vendor,uint256 planId,uint256 periods,address token)"),
      _vendor,
      _planId,
      _periods,
      _token
    ));

    bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19\x01", eip712Domain, attestation));
    (bytes32 r, bytes32 s, uint8 v) = _split(_signature);

    address subscriber = ecrecover(ethSignedHash, v, r, s);
    require(_isValidSubscriber(_vendor, subscriber, _planId) == false, "User is already subscribed");
    
    (uint256 price, uint256 billingPeriod,, uint256 discount) = _getPlan(_vendor, _planId);
    
    if (stableIsAllowed[_token] == 1) {
      _subscribeStable(subscriber, _vendor, _planId, _periods, _token, price, billingPeriod, discount);
    } else {
      _subscribeToken(subscriber, _vendor, _planId, _periods, _token, price, billingPeriod, discount);
    }
  }

  function subscribeStable(address _vendor, uint256 _planId, uint256 _periods, address _stable) external {
    (uint256 price, uint256 billingPeriod,, uint256 discount) = _getPlan(_vendor, _planId);

   _subscribeStable(msg.sender, _vendor, _planId, _periods, _stable, price, billingPeriod, discount);
  }

  function _subscribeStable(address _subscriber, address _vendor, uint256 _planId, uint256 _periods, address _stable, uint256 _price, uint256 _billingPeriod, uint256 _discount) internal checkPeriods(_periods) {
    uint256 gasAtStart = gasleft() + gasCommit;

    require(stableIsAllowed[_stable] == 1, "Stablecoin not allowed");

    _price = _getDiscountPrice(_price, _periods, _billingPeriod, _discount);

    uint256 decimalsDiff;

    if (_stable != mainStable) (_price, decimalsDiff) = _fixDecimals(_stable, _price);

    _confirmation(_subscriber, _vendor, _planId, _periods, _stable, _price);
    _transferToken(_stable, _vendor, _subscriber, _price, gasAtStart, _price, decimalsDiff);
  }

  /// @notice Allows users to subscribe to a plan with accepted tokens
  function subscribeToken(address _vendor, uint256 _planId, uint256 _periods, address _token) external {
    (uint256 price, uint256 billingPeriod,, uint256 discount) = _getPlan(_vendor, _planId);

    _subscribeToken(msg.sender, _vendor, _planId, _periods, _token, price, billingPeriod, discount);
  }
  
  function _subscribeToken(address _subscriber, address _vendor, uint256 _planId, uint256 _periods, address _token, uint256 _price, uint256 _billingPeriod, uint256 _discount) internal checkPeriods(_periods) {
    uint256 gasAtStart = gasleft() + gasCommit;
    
    require(tokenIsAllowed[_token] == 1 || _token == wrappedNativeToken, "Token not allowed");

    _price = _getDiscountPrice(_price, _periods, _billingPeriod, _discount);

    uint256 amount = _getTwapAmount(_token, _price);
    uint256 decimalsDiff;

    (_price, decimalsDiff) = _fixDecimals(_token, _price);

    _confirmation(_subscriber, _vendor, _planId, _periods, _token, amount);
    _transferToken(_token, _vendor, _subscriber, amount, gasAtStart, _price, decimalsDiff);
  }

  /// @notice Allows users to subscribe to a plan with native token, this doesn't allow for automatic payment collection unless users subscribe with wrapped version
  function subscribeNative(address _vendor, uint256 _planId, uint256 _periods) external payable {
    (uint256 price, uint256 billingPeriod,, uint256 discount) = _getPlan(_vendor, _planId);
    
    _subscribeNative(_vendor, _planId, _periods, price, billingPeriod, discount);
  }
  
  function _subscribeNative(address _vendor, uint256 _planId, uint256 _periods, uint256 _price, uint256 _billingPeriod, uint256 _discount) internal checkPeriods(_periods) {
    uint256 gasAtStart = gasleft() + gasCommit;

    _price = _getDiscountPrice(_price, _periods, _billingPeriod, _discount);
    
    uint256 amount = _getTwapAmount(wrappedNativeToken, _price);

    _confirmation(msg.sender, _vendor, _planId, _periods, address(0), amount);
    
    if (msg.value > amount) payable(msg.sender).transfer(msg.value - amount);
    
    uint256 gasSpent = gasAtStart - gasleft() + 23000;
    uint256 gas = gasSpent * tx.gasprice;
    
    payable(_vendor).transfer(amount - gas);
    payable(msg.sender).transfer(gas);
  }

  /// @notice users can opt-out of subscription plans
  function unsubscribe(address _vendor, uint256 _planId) external {
    _unsubscribe(_vendor, _planId);
  }
  
  function _unsubscribe(address _vendor, uint256 _planId) internal {
    uint256 planKey = _getPlanKey(_vendor, _planId);
    delete lastPayment[planKey][msg.sender];
    
    emit Unsubscription(msg.sender, _vendor, _planId, block.timestamp);
  }
  
  /// @notice users can change to a different plan with a discounted price dependent on how long they are into their current billing period
  function changePlan(address _vendor, uint256 _oldPlanId, uint256 _newPlanId, uint256 _periods, address _token) external payable {
    uint256 nativeSent = msg.value;
    uint256 _stableIsAllowed = stableIsAllowed[_token];
    uint256 _tokenIsAllowed = tokenIsAllowed[_token];

    require(nativeSent != 0 || _stableIsAllowed == 1 || _tokenIsAllowed == 1, "Token not allowed");

    uint256 planKey = _getPlanKey(_vendor, _oldPlanId);
    (uint256 price, uint256 billingPeriod,, uint256 discount) = _getPlan(_vendor, _newPlanId);
    (uint256 _lastPayment,) = _getLastPayment(planKey, msg.sender);
    uint256 reducedPrice = (block.timestamp - _lastPayment) * price / billingPeriod;

    reducedPrice = _getDiscountPrice(price, _periods, billingPeriod, discount) - reducedPrice;

    _unsubscribe(_vendor, _oldPlanId);

    if (nativeSent != 0) _subscribeNative(_vendor, _newPlanId, _periods, reducedPrice, billingPeriod, discount);
    else if (_stableIsAllowed == 1) _subscribeStable(msg.sender, _vendor, _newPlanId, _periods, _token, reducedPrice, billingPeriod, discount);
    else _subscribeToken(msg.sender, _vendor, _newPlanId, _periods, _token, reducedPrice, billingPeriod, discount);
  }
  
  struct Misc {
    uint256 planKey;
    uint256 decimalsDiff;
    uint256 gasAtStart;
  }

  /// @notice to be triggered whenever it is time to collect payment from user
  function collectPayment(address _user, address _vendor, uint256 _planId, address _token) allowedToken(_token) external {
    require(_isValidSubscriber(_vendor, _user, _planId), "Not a subscriber");
    
    Misc memory misc;
    misc.planKey = _getPlanKey(_vendor, _planId);
    misc.gasAtStart = gasleft() + gasCommit;

    (uint256 _lastPayment, uint256 _periods) = _getLastPayment(misc.planKey, _user);
    (uint256 price, uint256 billingPeriod,, uint256 discount) = _getPlan(_vendor, _planId);

    require(price != 0, "Deleted plan");
    require((block.timestamp - _lastPayment) * _lastPayment > (billingPeriod * _lastPayment), "Not time to pay");

    price = _getDiscountPrice(price, _periods, billingPeriod, discount);
    
    uint256 timestamp = _lastPayment + billingPeriod * _periods;

    lastPayment[misc.planKey][_user] = timestamp |= _periods<<48;
    
    if (stableIsAllowed[_token] == 1) {
      if (_token != mainStable) (price, misc.decimalsDiff) = _fixDecimals(_token, price);
      
      _transferToken(_token, _vendor, _user, price, misc.gasAtStart, price, misc.decimalsDiff);
      
      emit Payment(_user, _vendor, _planId, _token, price, _periods, false, block.timestamp);
    } 
    else {
      uint256 amount = _getTwapAmount(_token, price);

      (, misc.decimalsDiff) = _fixDecimals(_token, price);

      _transferToken(_token, _vendor, _user, amount, misc.gasAtStart, price, misc.decimalsDiff);
      
      emit Payment(_user, _vendor, _planId, _token, amount, _periods, false, block.timestamp);
    }
  }
}
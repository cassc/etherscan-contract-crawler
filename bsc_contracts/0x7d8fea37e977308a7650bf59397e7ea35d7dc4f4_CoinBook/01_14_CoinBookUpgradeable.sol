// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { ReentrancyGuardUpgradeable } 
    from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20, IERC20Upgradeable as IERC20 } 
    from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { StringsUpgradeable as Strings } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { ICoinBook } from "./interfaces/ICoinBook.sol";
import { IWETH } from "./interfaces/IWETH.sol";
import { IPriceFeed } from "./interfaces/IPriceFeed.sol";

contract CoinBook is ICoinBook, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    IPriceFeed public priceFeed;

    address public wETH;
    uint256 public listingFeeUSD;
    uint256 public cancelFeeUSD;
    uint256 private maxPriceAge;

    mapping(uint256 => Order) private orderId;
    mapping(address => uint256[]) public userOrders;
    mapping(address => uint256) public activeUserOrders;
    mapping(IERC20 => bool) public restrictedTokens;
    mapping(address => bool) public restrictedUsers;
    mapping(address => bool) private updaters;

    uint256 private currentId;
    uint256 public activeOrderCount;

    uint16 public tax;
    address payable public taxWallet;

    bool public isPaused;

    uint256[48] private __gap;

    modifier notPaused() {
        require(!isPaused, "Contract is Paused to new orders");
        _;
    }

    modifier notRestrictedUser() {
        require(!restrictedUsers[msg.sender], "User is blocked from CoinBook");
        _;
    }

    modifier notRestrictedTokensA(IERC20 sellToken, IERC20[] memory buyTokens) {
        require(!restrictedTokens[sellToken], "Sell token is restricted");
        for(uint i = 0; i < buyTokens.length; i++) {
            require(!restrictedTokens[buyTokens[i]], "Buy token is restricted");
            require(sellToken != buyTokens[i], "Tokens can not match");
        }
        _;
    }

    modifier notRestrictedTokensB(IERC20[] memory buyTokens) {
        for(uint i = 0; i < buyTokens.length; i++) {
            require(!restrictedTokens[buyTokens[i]], "Buy token is restricted");
            require(IERC20(wETH) != buyTokens[i], "Tokens can not match");
        }
        _;
    }

    modifier onlyUpdaters() {
        require(updaters[msg.sender], "Only updaters allowed");
        _;
    }

    /**
     * @notice Initialize the CoinBook contract and populate configuration values.
     * @dev This function can only be called once.
     */
    function initialize(
        address _multiSig, 
        address _weth,
        address _priceFeed,
        uint256 _fees,
        address payable _taxWallet, 
        uint16 _tax
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _transferOwnership(_multiSig);
        wETH = _weth;
        priceFeed = IPriceFeed(_priceFeed);
        listingFeeUSD = _fees;
        cancelFeeUSD = _fees;
        taxWallet = _taxWallet;
        tax = _tax;
        currentId = 1;
        maxPriceAge = 1800;

        emit ListingFeeUpdated(_fees, 0, block.timestamp);
        emit CancelFeeUpdated(_fees, 0, block.timestamp);
        
    }

    receive() external override payable {
        emit Received(msg.sender, msg.value);
    }

    // Order Creation and Management Functions

    /**
     * @notice Creates an order to sell an ERC20 token.
     * @dev For orders selling ETH use createOrderEth()
     * @param _sellToken The ERC20 token to be sold
     * @param _sellAmount The amount of _sellToken to be sold
     * @param _buyTokens The ERC20 token(s) to accept as payment. Can use wETH for ETH
     * @param _buyAmounts The token amount(s) required to buy
     * @param _allOrNone Whether to allow buyers to purchase partial amounts of the sell order
     */
    function createOrderERC20(
        IERC20 _sellToken, 
        uint256 _sellAmount, 
        IERC20[] calldata _buyTokens, 
        uint256[] calldata _buyAmounts, 
        bool _allOrNone,
        bool _allowTokenFee,
        uint80 r
    ) external override payable notPaused notRestrictedUser notRestrictedTokensA(_sellToken, _buyTokens) nonReentrant {
        require(_sellAmount > 0, "Must sell more than 0 tokens");
        uint256 listingFeeETH = getListingFee(r);
        require(msg.value == listingFeeETH, "Listing Fee not covered");
        uint32 _startTime = uint32(block.timestamp);
        uint32 _endTime = type(uint32).max;
        uint256 _orderId = currentId++;
        uint256 tokenFee;

        uint256 balanceBefore = _sellToken.balanceOf(address(this));
        _sellToken.safeTransferFrom(msg.sender, address(this), _sellAmount);
        if (!_allowTokenFee) {
            require(_sellToken.balanceOf(address(this)) == balanceBefore + _sellAmount, "Sell Token has transfer fees");
        } else {
            uint256 amountReceived = _sellToken.balanceOf(address(this)) - balanceBefore;
            tokenFee = 10000 - ((amountReceived * 10000) / _sellAmount);
            _sellAmount = amountReceived;
        }

        orderId[_orderId].lister = payable(msg.sender);
        orderId[_orderId].sellToken = _sellToken;
        orderId[_orderId].sellAmount = _sellAmount;
        orderId[_orderId].sellTokenFee = uint16(tokenFee);
        orderId[_orderId].buyTokens = _buyTokens;
        orderId[_orderId].buyAmounts = _buyAmounts;
        orderId[_orderId].allOrNone = _allOrNone;
        orderId[_orderId].startTime = _startTime;
        orderId[_orderId].endTime = _endTime;
        orderId[_orderId].tax = tax;

        activeOrderCount++;
        userOrders[msg.sender].push(_orderId);
        activeUserOrders[msg.sender]++;

        if(_sellToken == IERC20(wETH)) {
            IWETH(wETH).withdraw(_sellAmount);
        }
        _safeTransferETHWithFallback(taxWallet, listingFeeETH);

        emit OrderCreated(
            _orderId, 
            _startTime, 
            _endTime, 
            _sellToken, 
            _sellAmount, 
            tokenFee > 0, 
            tokenFee, 
            _buyTokens, 
            _buyAmounts
        );
    }

    /**
     * @notice Creates an order to sell ETH for ERC20 token(s).
     * @dev For orders selling ERC20 tokens use createOrderERC20()
     * @param _sellAmount The amount of ETH to be sold
     * @param _buyTokens The ERC20 token(s) to accept as payment
     * @param _buyAmounts The token amount(s) required to buy
     * @param _allOrNone Whether to allow buyers to purchase partial amounts of the sell order
     */
    function createOrderEth(
        uint256 _sellAmount, 
        IERC20[] calldata _buyTokens, 
        uint256[] calldata _buyAmounts, 
        bool _allOrNone,
        uint80 r
    ) external override payable notPaused notRestrictedUser notRestrictedTokensB(_buyTokens) nonReentrant {
        uint256 listingFeeETH = getListingFee(r);
        require(_sellAmount + listingFeeETH == msg.value, "Wrong ETH amount sent");
        require(_sellAmount > 0, "Must sell more than 0 tokens");
        uint32 _startTime = uint32(block.timestamp);
        uint32 _endTime = type(uint32).max;
        uint256 _orderId = currentId++;

        orderId[_orderId].lister = payable(msg.sender);
        orderId[_orderId].sellToken = IERC20(wETH);
        orderId[_orderId].sellAmount = _sellAmount;
        orderId[_orderId].sellTokenFee = 0;
        orderId[_orderId].buyTokens = _buyTokens;
        orderId[_orderId].buyAmounts = _buyAmounts;
        orderId[_orderId].allOrNone = _allOrNone;
        orderId[_orderId].startTime = _startTime;
        orderId[_orderId].endTime = _endTime;
        orderId[_orderId].tax = tax;

        activeOrderCount++;
        userOrders[msg.sender].push(_orderId);
        activeUserOrders[msg.sender]++;

        _safeTransferETHWithFallback(taxWallet, listingFeeETH);

        emit OrderCreated(_orderId, _startTime, _endTime, IERC20(wETH), _sellAmount, false, 0, _buyTokens, _buyAmounts);
    }

    /**
     * @notice Edit _buyAmounts for all _buyTokens in an existing order.
     * @dev Only callable by Lister
     * @dev _buyToken Array must match array in storage
     * @param _id The OrderId to be updated 
     * @param _buyTokens The ERC20 token(s) that exist in the order
     * @param _buyAmounts The new token amount(s) required to buy
     */
    function editOrderPricesAll(
        uint256 _id, 
        IERC20[] calldata _buyTokens, 
        uint256[] calldata _buyAmounts
    ) external override notPaused nonReentrant {
        require(msg.sender == orderId[_id].lister, "Only Lister can edit");
        require(_orderStatus(_id) == 1, "Order is not active");
        uint256 lt = _buyTokens.length;
        uint256 la = _buyAmounts.length;
        require(lt == la && la == orderId[_id].buyTokens.length, "Must update all prices");

        uint256 _oldBuyAmount;
        for(uint i = 0; i < lt; i++) {
            require(_buyTokens[i] == orderId[_id].buyTokens[i], "Tokens misordered");
            _oldBuyAmount = orderId[_id].buyAmounts[i];
            orderId[_id].buyAmounts[i] = _buyAmounts[i];
            emit OrderSinglePriceEdited(_id, _buyTokens[i], _oldBuyAmount, _buyAmounts[i]);
        }
    }

    /**
     * @notice Edit _buyAmounts for a single _buyToken in an existing order.
     * @dev Only callable by Lister
     * @dev The _buyToken must exist at specified _index
     * @param _id The OrderId to be updated
     * @param _index The index that the _buyToken is at in storage 
     * @param _buyToken The ERC20 token that exists in the order
     * @param _buyAmount The new token amount required to buy
     */
    function editOrderPriceSingle(
        uint256 _id, 
        uint256 _index, 
        IERC20 _buyToken, 
        uint256 _buyAmount
    ) external override notPaused nonReentrant {
        require(msg.sender == orderId[_id].lister, "Only Lister can edit");
        require(_orderStatus(_id) == 1, "Order is not active");
        require(_buyToken == orderId[_id].buyTokens[_index], "Token does not exist at index");

        uint256 _oldBuyAmount = orderId[_id].buyAmounts[_index];
        orderId[_id].buyAmounts[_index] = _buyAmount;

        emit OrderSinglePriceEdited(_id, _buyToken, _oldBuyAmount, _buyAmount);
    }

    /**
     * @notice Claim refund on an expired sell order.
     * @dev Only callable by Lister
     * @param _id The OrderId to be refunded
     */
    function claimRefundOnExpire(uint256 _id) external override nonReentrant {
        address lister = orderId[_id].lister;
        require(msg.sender == lister || updaters[msg.sender], "Only Lister caan initiate refund");
        require(_orderStatus(_id) == 3, "Order has not expired");
        require(!orderId[_id].failed && !orderId[_id].canceled, "Refund already claimed");
        orderId[_id].failed = true;
        activeOrderCount--;
        activeUserOrders[lister]--;
        IERC20 token = orderId[_id].sellToken;
        if(token == IERC20(wETH)) {
            _safeTransferETHWithFallback(lister, orderId[_id].sellAmount);
        } else {
            token.safeTransfer(lister, orderId[_id].sellAmount);
        }
        

        emit OrderRefunded(_id, lister, token, orderId[_id].sellAmount, msg.sender);
    }

    /**
     * @notice Cancel an active order.
     * @dev Only callable by Lister
     * @param _id The OrderId to be canceled
     */
    function cancelOrder(uint256 _id, uint80 r) external override payable nonReentrant {
        uint256 cancelFeeETH = getCancelFee(r);
        require(msg.value == cancelFeeETH, "Cancel Fee not covered");
        address payable _lister = orderId[_id].lister;
        require(msg.sender == _lister, "Only Lister can cancel");
        require(_orderStatus(_id) == 1, "Order is not active");
        orderId[_id].canceled = true;

        activeOrderCount--;
        activeUserOrders[_lister]--;

        IERC20 _token = orderId[_id].sellToken;

        uint256 _amount = orderId[_id].sellAmount;
        
        if(address(_token) == wETH) {
            _safeTransferETHWithFallback(_lister, _amount);
        } else {
            _token.safeTransfer(_lister, _amount);
        }

        _safeTransferETHWithFallback(taxWallet, cancelFeeETH);

        emit OrderCanceled(_id, _lister, _token, _amount, msg.sender, block.timestamp);
    }

    // Order Fulfillment Functions

    /**
     * @notice Buy tokens from an order with an ERC20 token.
     * @dev Matches the buyToken to the provided index
     * @param _id The OrderId to be executed
     * @param index The index of the buyToken
     * @param _token the ERC20 token to be used for the execution
     * @param _id The amount of _token to be spent on the order
     */
    function executeOrderERC20(
        uint256 _id, 
        uint256 index, 
        IERC20 _token, 
        uint256 _amount
    ) external override notRestrictedUser nonReentrant {
        require(_orderStatus(_id) == 1 && !orderId[_id].settled, "Order has settled or canceled");
        require(block.timestamp <= orderId[_id].endTime, "Order has expired");
        require(_token == orderId[_id].buyTokens[index] && !restrictedTokens[_token], "Invalid Token");

        uint256 orderBuyAmount = orderId[_id].buyAmounts[index];
        if(_amount == orderBuyAmount) {
            _fulfillFullOrderERC20(msg.sender, _id, _token, _amount);
        } else {
            require(!orderId[_id].allOrNone, "Order is All or None");
            require(_amount < orderBuyAmount, "Invalid Amount");
            _fulfillPartialOrderERC20(msg.sender, _id, index, _token, _amount);
        }
    }

    /**
     * @notice Buy tokens from an order with ETH.
     * @dev Matches ETH to the provided index
     * @dev msg.value is the amount of ETH to be spent on the order
     * @param _id The OrderId to be executed
     * @param index The index of ETH
     */
    function executeOrderEth(uint256 _id, uint256 index) external override payable notRestrictedUser nonReentrant {
        require(_orderStatus(_id) == 1 && !orderId[_id].settled, "Order has settled or canceled");
        require(block.timestamp <= orderId[_id].endTime, "Order has expired");
        IERC20 _token = IERC20(wETH);
        require(_token == orderId[_id].buyTokens[index], "Invalid Token");

        uint256 _amount = msg.value;
        uint256 orderBuyAmount = orderId[_id].buyAmounts[index];
        if(_amount == orderBuyAmount) {
            _fulfillFullOrderEth(msg.sender, _id, _token, _amount);
        } else {
            require(!orderId[_id].allOrNone, "Order is All or None");
            require(_amount < orderBuyAmount, "Invalid Amount");
            _fulfillPartialOrderEth(msg.sender, _id, index, _token, _amount);
        }
    }

    // Admin Functions

    /**
     * @notice Set the isPaused status to restrict new orders.
     * @dev Only callable by owner
     * @param _flag Whether should be paused
     */
    function setPaused(bool _flag) external override onlyOwner {
        isPaused = _flag;
    }

    /**
     * @notice Set an address as an updated.
     * @dev Only callable by owner
     * @param _updater Address to grant/revoke privelege for
     * @param _flag Whether _updater should be allowed permission
     */
    function setUpdater(address _updater, bool _flag) external override onlyOwner {
        updaters[_updater] = _flag;
    }

    /**
     * @notice Set the restricted status of a token.
     * @dev Only callable by owner
     * @param token Address of the token to be updated
     * @param flag Whether token should be restricted
     */
    function setRestrictedToken(IERC20 token, bool flag) external override onlyUpdaters {
        restrictedTokens[token] = flag;
        emit TokenRestrictionUpdated(token, flag, block.timestamp);
    }

    /**
     * @notice Set the restricted status of a user.
     * @dev Only callable by owner
     * @param user Address of the user to be updated
     * @param flag Whether user should be restricted
     */
    function setRestrictedUser(address user, bool flag) external override onlyUpdaters {
        restrictedUsers[user] = flag;
        emit UserRestrictionUpdated(user, flag, block.timestamp);
    }

    /**
     * @notice Update the price feed to fetch current ETH/USD Price.
     * @dev Only callable by owner
     * @param newPriceFeed The new price feed contract address
     */
    function updatePriceFeed(address newPriceFeed) external override onlyOwner {
        priceFeed = IPriceFeed(newPriceFeed);
    }

    /**
     * @notice Update the listingFeeUSD.
     * @dev Only callable by owner
     * @param newFee The updated fee in USD adjusted to 10**8
     */
    function updateListingFee(uint256 newFee) external override onlyOwner {
        uint256 oldFee = listingFeeUSD;
        listingFeeUSD = newFee;
        emit ListingFeeUpdated(newFee, oldFee, block.timestamp);
    }

    /**
     * @notice Update the cancelFeeUSD.
     * @dev Only callable by owner
     * @param newFee The updated fee in USD adjusted to 10**8
     */
    function updateCancelFee(uint256 newFee) external override onlyOwner {
        uint256 oldFee = cancelFeeUSD;
        cancelFeeUSD = newFee;
        emit CancelFeeUpdated(newFee, oldFee, block.timestamp);
    }

    /**
     * @notice Update the maxPriceAge.
     * @dev Only callable by owner
     * @param newMaxAge The updated maxPriceAge in seconds
     */
    function updateMaxPriceAge(uint256 newMaxAge) external override onlyOwner {
        maxPriceAge = newMaxAge;
    }

    /**
     * @notice Update the default tax percentage and taxWallet.
     * @dev Only callable by owner
     * @param _taxWallet The new wallet that tax and fees are sent to
     * @param _tax The new tax percent adjusted to 10**4
     */
    function updateTax(address payable _taxWallet, uint16 _tax) external override onlyOwner {
        taxWallet = _taxWallet;
        tax = _tax;
    }

    /**
     * @notice Emergency cancel an order by DEV, only to be used in emergencies.
     * @dev Only callable by owner
     * @param _id The orderId of the order to be cancelled
     */
    function emergencyCancelOrder(uint256 _id) external override nonReentrant onlyOwner {
        require(_orderStatus(_id) == 1, "Order is not active");
        orderId[_id].canceled = true;

        address lister = orderId[_id].lister;

        activeOrderCount--;
        activeUserOrders[lister]--;

        IERC20 token = orderId[_id].sellToken;
        if(token == IERC20(wETH)) {
            _safeTransferETHWithFallback(lister, orderId[_id].sellAmount);
        } else {
            token.safeTransfer(lister, orderId[_id].sellAmount);
        }

        emit OrderCanceled(_id, lister, token, orderId[_id].sellAmount, msg.sender, block.timestamp);
    }

    // Getter Functions

    /**
     * @notice Returns the order status for a given order.
     * @param _id The OrderId to be checked
     * @return The order status code
     */
    function orderStatus(uint256 _id) external override view returns (uint8) {
        return _orderStatus(_id);
    }

    /**
     * @notice Returns all active orders.
     * @return _activeOrders An array of all active OrderIds
     */
    function getAllActiveOrders() external override view returns (uint256[] memory _activeOrders) {
        uint256 length = activeOrderCount;
        _activeOrders = new uint256[](length);
        uint256 z = 0;
        for(uint256 i = 1; i <= currentId; i++) {
            if(_orderStatus(i) == 1) {
                _activeOrders[z] = i;
                z++;
            } else {
                continue;
            }
        }
    }

    /**
     * @notice Returns all orders and their statuses.
     * @return orders An array of all OrderIds
     * @return status An array of all statuses
     */
    function getAllOrders() external override view returns (uint256[] memory orders, uint8[] memory status) {
        orders = new uint256[](currentId - 1);
        status = new uint8[](currentId - 1);
        for(uint256 i = 1; i < currentId; i++) {
            orders[i - 1] = i;
            status[i - 1] = _orderStatus(i);
        }
    }

    /**
     * @notice Returns all active orders for a given User.
     * @param user The user address to get orders for
     * @return _activeOrders An array of all active OrderIds for the given user
     */
    function getAllActiveOrdersForUser(address user) external override view returns (uint256[] memory _activeOrders) { 
        uint256 a = activeUserOrders[user];
        uint256[] memory _orders = userOrders[user];
        uint256 m = _orders.length;
        _activeOrders = new uint256[](a);
        uint256 z = 0;
        for(uint256 i = 0; i < m; i++) {
            if(_orderStatus(_orders[i]) == 1) {
                _activeOrders[z] = _orders[i];
                z++;
            } else {
                continue;
            }
        }
    }

    /**
     * @notice Returns all orders and statuses for a user.
     * @param user The user address to get orders for
     * @return orders An array of all OrderIds for the given user
     * @return status An array of all statuses for the given user
     */
    function getAllOrdersForUser(
        address user
    ) external override view returns (
        uint256[] memory orders, 
        uint8[] memory status
    ) {
        orders = userOrders[user];
        uint256 length = orders.length;
        status = new uint8[](length);
        for(uint256 i = 0; i < length; i++) {
            status[i] = _orderStatus(orders[i]);
        }
    }

    /**
     * @notice Returns all buyTokens and buyAmounts for a given order.
     * @param _id The orderId to return the BuyOptions for.
     * @return buyTokens An array of all buyTokens for the given orderId
     * @return buyAmounts An array of all buyAmounts for the given orderId
     */
    function getOrderBuyOptions(
        uint256 _id
    ) external override view returns (
        IERC20[] memory buyTokens, 
        uint256[] memory buyAmounts
    ) {
        buyTokens = orderId[_id].buyTokens;
        buyAmounts = orderId[_id].buyAmounts;
    }

    /**
     * @notice Returns all buyTokens and buyAmounts for a given order.
     * @param _id The orderId to return the BuyOptions for.
     */
    function getOrderInfo(
        uint256 _id
    ) external override view returns (
        address lister,
        uint32 startTime,
        uint32 endTime,
        bool allOrNone,
        uint16 orderTax,
        uint16 sellTokenFee,
        bool settled,
        bool canceled,
        bool failed,
        IERC20 sellToken,
        uint256 sellAmount,
        IERC20[] memory buyTokens, 
        uint256[] memory buyAmounts
    ) {
        lister = orderId[_id].lister;
        startTime = orderId[_id].startTime;
        endTime = orderId[_id].endTime;
        allOrNone = orderId[_id].allOrNone;
        orderTax = orderId[_id].tax;
        sellTokenFee = orderId[_id].sellTokenFee;
        settled = orderId[_id].settled;
        canceled = orderId[_id].canceled;
        failed = orderId[_id].failed;
        sellToken = orderId[_id].sellToken;
        sellAmount = orderId[_id].sellAmount;
        buyTokens = orderId[_id].buyTokens;
        buyAmounts = orderId[_id].buyAmounts;
    }

    /**
     * @notice Returns the current listing fee in ETH.
     * @return listingFeeETH The amount of ETH needed to create an order
     * @return round The roundId that the price was fetched from
     */
    function getCurrentListingFee() external override view returns (uint256 listingFeeETH, uint80 round) {
        (uint80 r,int256 ethPrice,,,) = priceFeed.latestRoundData();
        round = r;
        listingFeeETH = ((listingFeeUSD * 10**18) / uint256(ethPrice));
    }

    /**
     * @notice Returns the current cancel fee in ETH.
     * @return cancelFeeETH The amount of ETH needed to create an order
     * @return round The roundId that the price was fetched from
     */
    function getCurrentCancelFee() public override view returns (uint256 cancelFeeETH, uint80 round) {
        (uint80 r,int256 ethPrice,,,) = priceFeed.latestRoundData();
        round = r;
        cancelFeeETH = ((cancelFeeUSD * 10**18) / uint256(ethPrice));
    }

    /**
     * @notice Returns the current USD price of ETH.
     * @return ethPrice The amount of USD price of ETH
     * @return round The roundId that the price was fetched from
     */
    function getCurrentEthPrice() external override view returns (int256 ethPrice, uint80 round) {
        (round,ethPrice,,,) = priceFeed.latestRoundData();
    }

    // Internal Helper Functions

    function _orderStatus(uint256 _id) internal view returns (uint8) {
        if (orderId[_id].canceled) {
        return 3; // CANCELED - Lister canceled
        }
        if ((block.timestamp > orderId[_id].endTime) && !orderId[_id].settled) {
        return 3; // FAILED - not sold by end time
        }
        if (orderId[_id].settled) {
        return 2; // SUCCESS - Full order was filled
        }
        if ((block.timestamp <= orderId[_id].endTime) && !orderId[_id].settled) {
        return 1; // ACTIVE - Order is eligible for buys
        }
        return 0; // QUEUED - awaiting start time
    }

    function getListingFee(uint80 r) internal view returns (uint256 listingFeeETH) {
        (,int256 ethPrice,,uint256 roundTime,) = priceFeed.getRoundData(r);
        require(block.timestamp - roundTime <= maxPriceAge, "Price too old");
        return ((listingFeeUSD * 10**18) / uint256(ethPrice));
    }

    function getCancelFee(uint80 r) internal view returns (uint256 cancelFeeETH) {
        (,int256 ethPrice,,uint256 roundTime,) = priceFeed.getRoundData(r);
        require(block.timestamp - roundTime <= maxPriceAge, "Price too old");
        return ((cancelFeeUSD * 10**18) / uint256(ethPrice));
    }

    function _fulfillFullOrderERC20(address _taker, uint256 _id, IERC20 _token, uint256 _amount) internal {
        uint16 _tax = orderId[_id].tax > tax ? tax : orderId[_id].tax;

        uint256 taxAmount1 = _amount * _tax / 10000;
        uint256 finalAmount1 = _amount - taxAmount1;

        IERC20 sellToken = orderId[_id].sellToken;
        uint256 sellAmount = orderId[_id].sellAmount;
        uint256 taxAmount2 = sellAmount * _tax / 10000;
        uint256 finalAmount2 = sellAmount - taxAmount2;

        address lister = orderId[_id].lister;

        if (_token == IERC20(wETH)) {
            _token.safeTransferFrom(_taker, address(this), sellAmount);
            IWETH(wETH).withdraw(sellAmount);
            _safeTransferETHWithFallback(taxWallet, taxAmount1);
            _safeTransferETHWithFallback(lister, finalAmount1);
        } else {
            _token.safeTransferFrom(_taker, taxWallet, taxAmount1);
            _token.safeTransferFrom(_taker, lister, finalAmount1);
        }
        if (sellToken == IERC20(wETH)) {
            _safeTransferETHWithFallback(taxWallet, taxAmount2);
            _safeTransferETHWithFallback(_taker, finalAmount2);
        } else {
            sellToken.safeTransfer(taxWallet, taxAmount2);
            sellToken.safeTransfer(_taker, finalAmount2);
        }

        orderId[_id].settled = true;
        activeOrderCount--;
        activeUserOrders[lister]--;

        emit OrderFulfilledFull(_id, _taker, lister, _token, _amount, sellToken, sellAmount, taxAmount1, taxAmount2);
    }

    function _fulfillPartialOrderERC20(
        address _taker, 
        uint256 _id, 
        uint256 index, 
        IERC20 _token, 
        uint256 _amount
    ) internal {
        uint256 _fullSellAmount = orderId[_id].sellAmount;
        uint256 _fullBuyAmount = orderId[_id].buyAmounts[index];
        uint256 adjuster = ((_amount * 10**18) / _fullBuyAmount);
        uint256 _partialSellAmount = ((_fullSellAmount * adjuster) / 10**18);
        orderId[_id].sellAmount -= _partialSellAmount;

        uint256 length = orderId[_id].buyTokens.length;
        uint256 b;
        uint256 n;
        for(uint i = 0; i < length; i++) {
            b = orderId[_id].buyAmounts[i];
            n = (b - ((b * adjuster) / 10**18));
            orderId[_id].buyAmounts[i] = n;
            emit OrderSinglePriceEdited(_id, orderId[_id].buyTokens[i], b, n);
        }

        uint16 _tax = orderId[_id].tax > tax ? tax : orderId[_id].tax;

        uint256 taxAmount1 = _amount * _tax / 10000;
        uint256 finalAmount1 = _amount - taxAmount1;

        IERC20 sellToken = orderId[_id].sellToken;
        uint256 taxAmount2 = _partialSellAmount * _tax / 10000;
        uint256 finalAmount2 = _partialSellAmount - taxAmount2;

        if (_token == IERC20(wETH)) {
            _token.safeTransferFrom(_taker, address(this), _partialSellAmount);
            IWETH(wETH).withdraw(_partialSellAmount);
            _safeTransferETHWithFallback(taxWallet, taxAmount1);
            _safeTransferETHWithFallback(orderId[_id].lister, finalAmount1);
        } else {
            _token.safeTransferFrom(_taker, taxWallet, taxAmount1);
            _token.safeTransferFrom(_taker, orderId[_id].lister, finalAmount1);
        }
        if (sellToken == IERC20(wETH)) {
            _safeTransferETHWithFallback(taxWallet, taxAmount2);
            _safeTransferETHWithFallback(_taker, finalAmount2);
        } else {
            sellToken.safeTransfer(taxWallet, taxAmount2);
            sellToken.safeTransfer(_taker, finalAmount2);
        }

        emit OrderFulfilledPartial(
            _id, 
            _taker, 
            orderId[_id].lister, 
            _token, 
            _amount, 
            sellToken, 
            _partialSellAmount, 
            taxAmount1, 
            taxAmount2, 
            orderId[_id].sellAmount
        );
    }

    function _fulfillFullOrderEth(address _taker, uint256 _id, IERC20 _token, uint256 _amount) internal {
        uint16 _tax = orderId[_id].tax > tax ? tax : orderId[_id].tax;

        uint256 taxAmount1 = _amount * _tax / 10000;
        uint256 finalAmount1 = _amount - taxAmount1;

        IERC20 sellToken = orderId[_id].sellToken;
        uint256 sellAmount = orderId[_id].sellAmount;
        uint256 taxAmount2 = sellAmount * _tax / 10000;
        uint256 finalAmount2 = sellAmount - taxAmount2;

        address lister = orderId[_id].lister;

        _safeTransferETHWithFallback(taxWallet, taxAmount1);
        _safeTransferETHWithFallback(lister, finalAmount1);
        sellToken.safeTransfer(taxWallet, taxAmount2);
        sellToken.safeTransfer(_taker, finalAmount2);

        orderId[_id].settled = true;
        activeOrderCount--;
        activeUserOrders[lister]--;

        emit OrderFulfilledFull(_id, _taker, lister, _token, _amount, sellToken, sellAmount, taxAmount1, taxAmount2);
    }

    function _fulfillPartialOrderEth(
        address _taker, 
        uint256 _id, 
        uint256 index, 
        IERC20 _token, 
        uint256 _amount
    ) internal {
        uint256 _fullSellAmount = orderId[_id].sellAmount;
        uint256 _fullBuyAmount = orderId[_id].buyAmounts[index];
        uint256 adjuster = ((_amount * 10**18) / _fullBuyAmount);
        uint256 _partialSellAmount = ((_fullSellAmount * adjuster) / 10**18);
        orderId[_id].sellAmount -= _partialSellAmount;

        uint256 length = orderId[_id].buyTokens.length;
        uint256 b;
        uint256 n;
        for(uint i = 0; i < length; i++) {
            b = orderId[_id].buyAmounts[i];
            n = (b - ((b * adjuster) / 10**18));
            orderId[_id].buyAmounts[i] = n;
            emit OrderSinglePriceEdited(_id, orderId[_id].buyTokens[i], b, n);
        }

        uint16 _tax = orderId[_id].tax > tax ? tax : orderId[_id].tax;

        uint256 taxAmount1 = _amount * _tax / 10000;
        uint256 finalAmount1 = _amount - taxAmount1;

        IERC20 sellToken = orderId[_id].sellToken;
        uint256 taxAmount2 = _partialSellAmount * _tax / 10000;
        uint256 finalAmount2 = _partialSellAmount - taxAmount2;

        _safeTransferETHWithFallback(taxWallet, taxAmount1);
        _safeTransferETHWithFallback(orderId[_id].lister, finalAmount1);
        sellToken.safeTransfer(taxWallet, taxAmount2);
        sellToken.safeTransfer(_taker, finalAmount2);

        emit OrderFulfilledPartial(
            _id, 
            _taker, 
            orderId[_id].lister, 
            _token, 
            _amount, 
            sellToken, 
            _partialSellAmount, 
            taxAmount1, 
            taxAmount2, 
            orderId[_id].sellAmount
        );
    }
    
    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(wETH).deposit{ value: amount }();
            IERC20(wETH).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address recip, uint256 amount) internal returns (bool) {
        (bool success, ) = recip.call{ value: amount, gas: 30_000 }("");
        return success;
    }   
}
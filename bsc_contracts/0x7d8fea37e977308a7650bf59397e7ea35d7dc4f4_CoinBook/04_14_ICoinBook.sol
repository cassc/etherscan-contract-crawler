// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICoinBook {

    event OrderCreated(
        uint256 indexed orderId, 
        uint256 startTime, 
        uint256 endTime, 
        IERC20 sellToken, 
        uint256 sellAmount, 
        bool sellTokenHasFee, 
        uint256 sellTokenFee, 
        IERC20[] buyTokens, 
        uint256[] buyAmounts
    );
    
    event OrderFulfilledFull(
        uint256 indexed orderId, 
        address buyer, 
        address seller, 
        IERC20 buyToken, 
        uint256 buyAmount, 
        IERC20 sellToken, 
        uint256 sellAmount, 
        uint256 taxAmount1, 
        uint256 taxAmount2
    );
    
    event OrderFulfilledPartial(
        uint256 indexed orderId, 
        address buyer, 
        address seller, 
        IERC20 buyToken, 
        uint256 buyAmount, 
        IERC20 sellToken, 
        uint256 sellAmount, 
        uint256 taxAmount1, 
        uint256 taxAmount2, 
        uint256 sellAmountRemaining
    );
    
    event OrderRefunded(
        uint256 indexed orderId, 
        address lister, 
        IERC20 sellToken, 
        uint256 sellAmountRefunded, 
        address caller
    );
    
    event OrderCanceled(
        uint256 indexed orderId, 
        address lister, 
        IERC20 sellToken, 
        uint256 sellAmountRefunded, 
        address caller, 
        uint256 timeStamp
    );

    event OrderSinglePriceEdited(uint256 indexed orderId, IERC20 buyToken, uint256 oldbuyAmount, uint256 newbuyAmount);
    
    event ListingFeeUpdated(uint256 newFee, uint256 oldFee, uint256 updateTime);
    
    event CancelFeeUpdated(uint256 newFee, uint256 oldFee, uint256 updateTime);
    
    event TokenRestrictionUpdated(IERC20 indexed token, bool restricted, uint256 timeStamp);
    
    event UserRestrictionUpdated(address indexed user, bool restricted, uint256 timeStamp);
    
    event Received(address indexed from, uint256 amount);
    
    struct Order {
        address payable lister;
        uint32 startTime;
        uint32 endTime;
        bool allOrNone;
        uint16 tax;
        uint16 sellTokenFee;
        bool settled;
        bool canceled;
        bool failed;
        IERC20 sellToken;
        uint256 sellAmount;
        IERC20[] buyTokens;
        uint256[] buyAmounts;
    }

    receive() external payable;

    function createOrderERC20(
        IERC20 _sellToken, 
        uint256 _sellAmount, 
        IERC20[] calldata _buyTokens, 
        uint256[] calldata _buyAmounts, 
        bool _allOrNone, 
        bool _allowTokenFee,
        uint80 r
    ) external payable;

    function createOrderEth(
        uint256 _sellAmount, 
        IERC20[] calldata _buyTokens, 
        uint256[] calldata _buyAmounts, 
        bool _allOrNone,
        uint80 r
    ) external payable;

    function cancelOrder(uint256 _id, uint80 r) external payable;

    function editOrderPricesAll(uint256 _id, IERC20[] calldata _buyTokens, uint256[] calldata _buyAmounts) external;

    function editOrderPriceSingle(uint256 _id, uint256 _index, IERC20 _buyToken, uint256 _buyAmount) external;

    function executeOrderERC20(uint256 _id, uint256 index, IERC20 _token, uint256 _amount) external;

    function executeOrderEth(uint256 _id, uint256 index) external payable;

    function claimRefundOnExpire(uint256 _id) external;

    function emergencyCancelOrder(uint256 _id) external;

    function orderStatus(uint256 _id) external view returns (uint8);

    function getAllActiveOrders() external view returns (uint256[] memory _activeOrders);

    function getAllOrders() external view returns (uint256[] memory orders, uint8[] memory status);

    function getAllActiveOrdersForUser(address user) external view returns (uint256[] memory _activeOrders);

    function getAllOrdersForUser(address user) external view returns (uint256[] memory orders, uint8[] memory status);

    function getOrderBuyOptions(
        uint256 _id
    ) external view returns (
        IERC20[] memory buyTokens, 
        uint256[] memory buyAmounts
    );

    function getOrderInfo(
        uint256 _id
    ) external view returns (
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
    );
    
    function getCurrentListingFee() external view returns (uint256 listingFeeETH, uint80 round);
    
    function getCurrentCancelFee() external view returns (uint256 cancelFeeETH, uint80 round);

    function getCurrentEthPrice() external view returns (int256 ethPrice, uint80 round);

    function setPaused(bool _flag) external;
    
    function setUpdater(address _updater, bool _flag) external;

    function setRestrictedToken(IERC20 token, bool flag) external;

    function setRestrictedUser(address user, bool flag) external;

    function updatePriceFeed(address newPriceFeed) external;

    function updateListingFee(uint256 newFee) external;

    function updateMaxPriceAge(uint256 newMaxAge) external;

    function updateCancelFee(uint256 newFee) external;

    function updateTax(address payable _taxWallet, uint16 _tax) external;
}
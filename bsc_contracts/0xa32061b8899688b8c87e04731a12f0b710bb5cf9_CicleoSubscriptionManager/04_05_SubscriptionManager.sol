//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './Interfaces/IERC20.sol';

interface ISubscriptionFactory {
    function botAddress() external view returns (address);
    function taxPercent() external view returns (uint256);
    function taxAccount() external view returns (address);
    function router() external view returns (IRouter);
    function executor() external view returns (IAggregationExecutor);
}

interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable;  // 0x4b64e492
}

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
}

interface IRouter {
    function swap (
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) payable external returns (uint[] memory amounts);
}

contract CicleoSubscriptionManager is Ownable {
    event PaymentSubscription(address indexed user, uint256 indexed subscrptionType, uint256 price);
    event Cancel(address indexed user);
    event ApproveSubscription(address indexed user, uint256 amountPerMonth);
    event SubscriptionEdited(address indexed user, uint256 indexed subscrptionId, uint256 price, bool isActive);
    event TreasuryEdited(address indexed user, address newTreasury);
    event NameEdited(address indexed user, string newName);

    struct SubscriptionStruct {
        uint256 price;
        bool isActive;
        string name;
    }

    struct UserData {
        uint256 subscriptionEndDate;
        uint256 subscriptionId;
        uint256 approval;
        uint256 lastPayment;
        bool canceled;
    }

    mapping (uint256 => SubscriptionStruct) public subscriptions;
    mapping (address => UserData) public users;

    IERC20 public token;
    address public treasury;
    ISubscriptionFactory public factory;
    string public name;
    uint256 public subscriptionNumber;

    constructor (address _factory, string memory _name, address _token, address _treasury) {
        factory = ISubscriptionFactory(_factory);
        name = _name;
        token = IERC20(_token);
        treasury = _treasury;

        emit TreasuryEdited(msg.sender, _treasury);
        emit NameEdited(msg.sender, _name);
    }

    function approveSubscription(uint256 amountMaxPerMonth) external {
        users[msg.sender].approval = amountMaxPerMonth;

        emit ApproveSubscription(msg.sender, amountMaxPerMonth);
    }

    function payFunction(address user, uint256 subscrptionType) internal {
        require(subscrptionType > 0 && subscrptionType <= subscriptionNumber, "Wrong sub type");
        require(subscriptions[subscrptionType].isActive, "Subscription is disabled");

        uint256 price = subscriptions[subscrptionType].price;

        require(users[user].approval >= price, "You need to approve our contract to spend this amount of tokens");

        uint256 tax = price * factory.taxPercent() / 1000;

        token.transferFrom(user, treasury, price - tax);
        token.transferFrom(user, factory.taxAccount(), tax);

        users[user].subscriptionEndDate = block.timestamp + 30 days;
        users[user].subscriptionId = subscrptionType;
        users[user].lastPayment = block.timestamp;
        users[user].canceled = false;

        emit PaymentSubscription(user, subscrptionType, price);
    }

    function subscriptionRenew(address user) external {
        require(msg.sender == factory.botAddress(), "Not allowed to");
        
        UserData memory userData = users[user];
        
        require(block.timestamp - userData.lastPayment >= 30 days, "You can't renew subscription before 30 days");
        require(userData.subscriptionId != 0, "No subscription for this user");
        require(userData.canceled == false, "Subscription is canceled");

        if (token.allowance(user, address(this)) < subscriptions[userData.subscriptionId].price || token.balanceOf(user) < subscriptions[userData.subscriptionId].price || userData.approval < subscriptions[userData.subscriptionId].price) {
            userData.canceled = true;
        } else {
            payFunction(user, userData.subscriptionId);
        }
    }

    function payment(uint8 id) external {
        payFunction(msg.sender, id);
    }

    function _execute(
        IAggregationExecutor executor,
        address srcTokenOwner,
        uint256 inputAmount,
        bytes calldata data
    ) private {
        bytes4 executeSelector = executor.execute.selector;
        /// @solidity memory-safe-assembly
        assembly {  // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            mstore(ptr, executeSelector)
            mstore(add(ptr, 0x04), srcTokenOwner)
            calldatacopy(add(ptr, 0x24), data.offset, data.length)
            mstore(add(add(ptr, 0x24), data.length), inputAmount)

            if iszero(call(gas(), executor, callvalue(), ptr, add(0x44, data.length), 0, 0)) {
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }

    function swap(
        IAggregationExecutor executor,
        SwapDescription memory desc,
        bytes memory permit,
        bytes calldata data
    )
        private
        returns (
            uint256 returnAmount,
            uint256 spentAmount
        )
    {
        IERC20 srcToken = desc.srcToken;
        IERC20 dstToken = desc.dstToken;

        srcToken.transferFrom(msg.sender, desc.srcReceiver, desc.amount);

        _execute(executor, msg.sender, desc.amount, data);

        spentAmount = desc.amount;
        // we leave 1 wei on the router for gas optimisations reasons
        returnAmount = dstToken.balanceOf(address(this));

        unchecked { returnAmount--; }

        address payable dstReceiver = (desc.dstReceiver == address(0)) ? payable(msg.sender) : desc.dstReceiver;
        dstToken.transfer(dstReceiver, returnAmount);
    }

    function paymentWithSwap(uint8 id, SwapDescription memory desc, bytes calldata data, address executor) external {
        require(id > 0 && id <= subscriptionNumber, "Wrong sub type");
        require(subscriptions[id].isActive, "Subscription is disabled");
        
        uint256 price = subscriptions[id].price;

        desc.minReturnAmount = price;
        
        require(users[msg.sender].approval >= price, "You need to approve our contract to spend this amount of tokens");

        uint256 balanceBefore = token.balanceOf(address(this));

        IERC20(desc.srcToken).transferFrom(msg.sender, address(this), desc.amount);

        //1inch swap
        swap(
            IAggregationExecutor(executor),
            desc,
            bytes(""),
            data
        );

        //Verify if the token have a transfer fees or if the swap goes okay

        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter - balanceBefore >= price, "Swap failed");

        uint256 tax = price * factory.taxPercent() / 1000;

        token.transfer(treasury, price - tax);
        token.transfer(factory.taxAccount(), balanceAfter - price - tax);

        users[msg.sender].subscriptionEndDate = block.timestamp + 30 days;
        users[msg.sender].subscriptionId = id;
        users[msg.sender].lastPayment = block.timestamp;
        users[msg.sender].canceled = false;

        emit PaymentSubscription(msg.sender, id, price);
    }

    function cancel() external {
        users[msg.sender].canceled = true;

        emit Cancel(msg.sender);
    }



    //Get functions

    function getSubscriptionStatus(address user) external view returns (uint256 subscriptionId, bool isActive) {
        UserData memory userData = users[user];
        return (userData.subscriptionId, userData.subscriptionEndDate > block.timestamp);
    }

    function getSubscriptions() external view returns (SubscriptionStruct[] memory) {
        SubscriptionStruct[] memory result = new SubscriptionStruct[](subscriptionNumber);

        for (uint256 i = 0; i < subscriptionNumber; i++) {
            result[i] = subscriptions[i + 1];
        }

        return result;
    }

    function getActiveSubscriptionCount() external view returns (uint256 count) {
        for (uint256 i = 0; i < subscriptionNumber; i++) {
            if (subscriptions[i + 1].isActive) count+= 1;
        }

        return count;
    }

    function getDecimals() external view returns (uint8) {
        return token.decimals();
    }

    function getSymbol() external view returns (string memory) {
        return token.symbol();
    }


    //Admin functions

    function newSubscription(uint256 _subscriptionPrice, string memory _name) external onlyOwner {
        subscriptionNumber += 1;
        
        subscriptions[subscriptionNumber] = SubscriptionStruct(
            _subscriptionPrice,
            true,
            _name
        );
        
        emit SubscriptionEdited(msg.sender, subscriptionNumber, _subscriptionPrice, true);
    }

    function editSubscription(uint256 id, uint256 _subscriptionPrice, string memory _name, bool isActive) external onlyOwner {
        subscriptions[id] = SubscriptionStruct(
            _subscriptionPrice,
            isActive,
            _name
        );

        emit SubscriptionEdited(msg.sender, id, _subscriptionPrice, isActive);
    }

    function setName(string memory _name) external onlyOwner {
        name = _name;

        emit NameEdited(msg.sender, _name);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        
        emit TreasuryEdited(msg.sender, _treasury);
    }

    function editAccount(address user, uint256 subscriptionEndDate, uint256 subscriptionId) external onlyOwner {
        UserData memory _user = users[user];

        users[user] = UserData(
            subscriptionEndDate,
            subscriptionId,
            _user.approval,
            _user.lastPayment,
            _user.canceled
        );
    }
}
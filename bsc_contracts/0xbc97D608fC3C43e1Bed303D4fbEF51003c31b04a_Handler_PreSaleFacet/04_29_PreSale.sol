// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Owners.sol";
import "./EmergencyMode.sol";

/**
 * @dev An item available to pre-order.
 */
struct Item {
    string name;
    uint256 priceRegular;
    uint256 priceWhitelisted;
}

/**
 * @dev Used by burner contracts, this is the interface that will be used to
 * consume pre-ordered items.
 */
interface IPreSaleBurnable {
    function burnItemTypeFrom(address user, uint256 itemType)
        external
        returns (
            uint256 tokenAmount,
            uint256 itemAmount,
            string memory itemName
        );
}

struct PreOrderCountItem {
    uint256 regular;
    uint256 whitelisted;
}

library PreOrderCountItemLib {
    function total(PreOrderCountItem storage item)
        internal
        view
        returns (uint256)
    {
        return item.regular + item.whitelisted;
    }

    function add(
        PreOrderCountItem storage item,
        bool isWhitelisted,
        uint256 val
    ) internal {
        if (isWhitelisted) {
            item.whitelisted += val;
        } else {
            item.regular += val;
        }
    }

    function sub(
        PreOrderCountItem storage item,
        bool isWhitelisted,
        uint256 val
    ) internal {
        if (isWhitelisted) {
            item.whitelisted -= val;
        } else {
            item.regular -= val;
        }
    }
}

struct PlacedOrder {
    uint256 amountAsRegular;
    uint256 amountAsWhitelisted;
    uint256 totalPaidAsRegular;
    uint256 totalPaidAsWhitelisted;
}

library PlacedOrderLib {
    function totalAmount(PlacedOrder storage order)
        internal
        view
        returns (uint256)
    {
        return order.amountAsRegular + order.amountAsWhitelisted;
    }

    function addAmount(
        PlacedOrder storage order,
        bool isWhitelisted,
        uint256 amount
    ) internal {
        if (isWhitelisted) {
            order.amountAsWhitelisted += amount;
        } else {
            order.amountAsRegular += amount;
        }
    }

    function subAmount(
        PlacedOrder storage order,
        bool isWhitelisted,
        uint256 amount
    ) internal {
        if (isWhitelisted) {
            order.amountAsWhitelisted -= amount;
        } else {
            order.amountAsRegular -= amount;
        }
    }

    function addTotalPaid(
        PlacedOrder storage order,
        bool isWhitelisted,
        uint256 amount
    ) internal {
        if (isWhitelisted) {
            order.totalPaidAsWhitelisted += amount;
        } else {
            order.totalPaidAsRegular += amount;
        }
    }

    function totalPaid(PlacedOrder storage order)
        internal
        view
        returns (uint256)
    {
        return order.totalPaidAsRegular + order.totalPaidAsWhitelisted;
    }

    function subTotalPaid(
        PlacedOrder storage order,
        bool isWhitelisted,
        uint256 amount
    ) internal {
        if (isWhitelisted) {
            order.totalPaidAsWhitelisted -= amount;
        } else {
            order.totalPaidAsRegular -= amount;
        }
    }

    function reset(PlacedOrder storage order)
        internal
        returns (uint256 amount, uint256 paid)
    {
        amount = order.amountAsRegular + order.amountAsWhitelisted;
        paid = order.totalPaidAsRegular + order.totalPaidAsWhitelisted;

        order.amountAsRegular = 0;
        order.amountAsWhitelisted = 0;
        order.totalPaidAsRegular = 0;
        order.totalPaidAsWhitelisted = 0;
    }
}

/**
 * @notice Locks an ERC20 token in exchange of the future right to buy an item.
 * @dev The actual item can be anything and is therefore only identified by a
 * `string`. The `burner` contract will be responsible to bind the registered
 * item name to the type of asset issued.
 */
contract PreSale is Owners, EmergencyMode, IPreSaleBurnable {
    event PreOrder(
        address user,
        uint256 itemType,
        uint256 itemAmount,
        uint256 tokenAmount
    );

    event OrderBurned(
        address user,
        uint256 itemType,
        uint256 itemAmount,
        uint256 tokenAmount
    );

    using SafeERC20 for IERC20;
    using PreOrderCountItemLib for PreOrderCountItem;
    using PlacedOrderLib for PlacedOrder;

    IERC20 public immutable paymentToken;
    Item[] public items;
    PreOrderCountItem[] public amountByItemIdx;
    PreOrderCountItem[] public tvlByItemIdx;

    mapping(address => bool) public whitelist;
    mapping(address => mapping(uint256 => PlacedOrder))
        internal userToItemIdxToAmount;

    address internal burner;
    bool public openPreOrderToRegular = false;
    bool public openPreOrderToWhitelist = false;
    bool public openToBurn = false;

    address public immutable multisig;

    uint256 public maxTVLPerRegularUser;
    uint256 public maxTVLPerWhitelistedUser;

    /**
     * @param _paymentToken Address to the token on which the orders will be
     * accepted.
     * @param itemNames Names of the items to pre-order.
     * @param itemRegularPrices Prices of the items for regular users.
     * @param itemWLPrices Prices of the items for whitelisted users.
     * @param _multisig Address of the multisig wallet allowed to access funds
     * locked in the contract.
     * @param _maxTVLs Tuple of the max TVL by user, index 0 for regular users
     * and index 1 for whitelisted users.
     */
    constructor(
        IERC20 _paymentToken,
        string[] memory itemNames,
        uint256[] memory itemRegularPrices,
        uint256[] memory itemWLPrices,
        address _multisig,
        uint256[] memory _maxTVLs
    ) {
        require(
            itemNames.length == itemRegularPrices.length &&
                itemRegularPrices.length == itemWLPrices.length,
            "Arrays must have the same length"
        );

        require(_maxTVLs.length == 2, "Invalid argument length");

        require(_multisig != address(0), "Multisig can't be the zero address");

        for (uint256 i = 0; i < itemNames.length; i++) {
            items.push(
                Item({
                    name: itemNames[i],
                    priceRegular: itemRegularPrices[i],
                    priceWhitelisted: itemWLPrices[i]
                })
            );
        }

        paymentToken = _paymentToken;
        multisig = _multisig;

        for (uint256 i = 0; i < items.length; i++) {
            amountByItemIdx.push(
                PreOrderCountItem({regular: 0, whitelisted: 0})
            );
            tvlByItemIdx.push(PreOrderCountItem({regular: 0, whitelisted: 0}));
        }

        paymentToken.safeApprove(multisig, type(uint256).max);

        maxTVLPerRegularUser = _maxTVLs[0];
        maxTVLPerWhitelistedUser = _maxTVLs[1];
    }

    //========== User-facing interface

    /**
     * @notice Places a pre-order on a given item.
     *
     * @param itemIdx The index of the pre-ordered item.
     * @param amount How many items to pre-order.
     */
    function preOrder(uint256 itemIdx, uint256 amount)
        external
        onlySafeMode
    {
        bool isWhitelisted = _isWhitelisted(msg.sender);
        require(
            (isWhitelisted && openPreOrderToWhitelist) ||
            (!isWhitelisted && openPreOrderToRegular),
            "PreSale: Pre-order is closed"
        );
        require(itemIdx < items.length, "PreSale: index out of bounds");
        require(amount > 0, "PreSale: amount can't be zero");

        Item memory item = items[itemIdx];
        uint256 maxTVL;
        uint256 tokenAmountToTransfer = amount;

        if (isWhitelisted) {
            maxTVL = maxTVLPerWhitelistedUser;
            tokenAmountToTransfer *= item.priceWhitelisted;
        } else {
            maxTVL = maxTVLPerRegularUser;
            tokenAmountToTransfer *= item.priceRegular;
        }

        require(
            tokenAmountToTransfer + getTotalValueLockedByUser(msg.sender) <=
                maxTVL,
            "PreSale: Maximum TVL reached"
        );

        _createPreOrder(msg.sender, itemIdx, amount, tokenAmountToTransfer);

        paymentToken.safeTransferFrom(
            msg.sender,
            address(this),
            tokenAmountToTransfer
        );

        emit PreOrder(msg.sender, itemIdx, amount, tokenAmountToTransfer);
    }

    /**
     * @notice Used in case of emergency, will allow users to get back their
     * all of their locked funds.
     */
    function emergencyRedeem() external onlyEmergencyMode {
        uint256 deposited = _burnAllPreOrdersForUser(msg.sender);
        require(deposited > 0, "PreSale Emergency: no deposits");
        paymentToken.safeTransfer(msg.sender, deposited);
    }

    /**
     * @notice Used in case of emergency, will allow users to get back their
     * locked funds, by item type.
     * @dev To be used if the item list is too long to be iterated on a single
     * transaction by `emergencyRedeem`. Use `getItemsSize` to iterate over all
     * the items.
     *
     * @param itemIdx The item index to redeem.
     */
    function emergencyRedeemByItem(uint256 itemIdx) public onlyEmergencyMode {
        require(itemIdx < items.length, "PreSale Emergency: out of bounds");
        (, uint256 deposited) = _burnPreOrderForUser(msg.sender, itemIdx);
        require(deposited > 0, "PreSale Emergency: no deposits");

        paymentToken.safeTransfer(msg.sender, deposited);
    }

    //========== Burner-only interface =======================================//

    /**
     * @notice Burns orders of a given user for a given item type.
     * @dev Caller must iterate manually on the item types in order to avoid
     * gas fees explosion if there is too many item types.
     *
     * @param user The user whose orders must be burned.
     * @param itemIdx The item type index of the orders to be burned.
     *
     * @return tokenAmount Amount of token that is transferred to the burner.
     * @return itemAmount How many items were ordered by the user.
     */
    function burnItemTypeFrom(address user, uint256 itemIdx)
        external
        onlySafeMode
        returns (
            uint256 tokenAmount,
            uint256 itemAmount,
            string memory itemName
        )
    {
        require(openToBurn, "PreSale: not open to burn");
        require(msg.sender == burner, "PreSale: only by Burner");
        require(user != address(0), "PreSale: null address");
        require(itemIdx < items.length, "PreSale: itemIdx out of bounds");

        itemName = items[itemIdx].name;
        (itemAmount, tokenAmount) = _burnPreOrderForUser(user, itemIdx);

        emit OrderBurned(user, itemIdx, itemAmount, tokenAmount);
    }

    //========== Multisig-only interface =====================================//

    function resetAllowance() external {
        require(msg.sender == multisig, "PreSale: only multisig");
        _resetAllowance();
    }

    function whithdraw() external {
        require(msg.sender == multisig, "PreSale: only multisig");
        paymentToken.safeTransfer(multisig, paymentToken.balanceOf(address(this)));
    }

    function refill() external {
        require(msg.sender == multisig, "PreSale: only multisig");
        uint256 thisBalance = paymentToken.balanceOf(address(this));
        uint256 neededBalance = getTotalValueLocked();

        if (thisBalance < neededBalance) {
            paymentToken.safeTransferFrom(
                multisig,
                address(this),
                neededBalance - thisBalance
            );
        }
    }

    //========== Owners-only interface =======================================//

    function setWhitelist(address[] calldata users, bool isWhitelisted)
        external
        onlyOwners
    {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = isWhitelisted;
        }
    }

    function setOpenPreOrderForAll(bool isOpen) external onlyOwners {
        openPreOrderToRegular = isOpen;
        openPreOrderToWhitelist = isOpen;
    }

    function setOpenPreOrderForRegular(bool isOpen) external onlyOwners {
        openPreOrderToRegular = isOpen;
    }

    function setOpenPreOrderForWhitelist(bool isOpen) external onlyOwners {
        openPreOrderToWhitelist = isOpen;
    }

    function setOpenToBurn(bool isOpen) external onlyOwners {
        openToBurn = isOpen;
    }

    function setBurner(address _burner) external onlyOwners {
        burner = _burner;
    }

    function setMaxTVLByRegularUser(uint256 maxTVL) external onlyOwners {
        maxTVLPerRegularUser = maxTVL;
    }

    function setMaxTVLByWhitelistedUser(uint256 maxTVL) external onlyOwners {
        maxTVLPerWhitelistedUser = maxTVL;
    }

    //========= Getters =======================================================/

    function getItemsSize() public view returns (uint256) {
        return items.length;
    }

    struct ItemView {
        string name;
        uint256 priceRegular;
        uint256 priceWhitelisted;
        uint256 amountCreated;
        uint256 tvl;
    }

    function getItems() public view returns (ItemView[] memory) {
        ItemView[] memory viewItems = new ItemView[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            viewItems[i] = ItemView({
                name: items[i].name,
                priceRegular: items[i].priceRegular,
                priceWhitelisted: items[i].priceWhitelisted,
                amountCreated: amountByItemIdx[i].total(),
                tvl: tvlByItemIdx[i].total()
            });
        }

        return viewItems;
    }

    struct PreOrderView {
        string itemName;
        uint256 amount;
        uint256 lockedValue;
    }

    function getPreOrdersByUser(address user)
        public
        view
        returns (PreOrderView[] memory)
    {
        PreOrderView[] memory orders = new PreOrderView[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            orders[i].itemName = items[i].name;
            orders[i].amount = userToItemIdxToAmount[user][i].totalAmount();
            orders[i].lockedValue = userToItemIdxToAmount[user][i].totalPaid();
        }

        return orders;
    }

    function getTotalValueLocked() public view returns (uint256 total) {
        for (uint256 i = 0; i < tvlByItemIdx.length; i++) {
            total += tvlByItemIdx[i].total();
        }
    }

    function getTotalValueLockedByUser(address user)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < items.length; i++) {
            amount += userToItemIdxToAmount[user][i].totalPaidAsRegular;
            amount += userToItemIdxToAmount[user][i].totalPaidAsWhitelisted;
        }
    }

    function getTotalValueLockedForRegularUsers()
        public
        view
        returns (uint256 total)
    {
        for (uint256 i = 0; i < tvlByItemIdx.length; i++) {
            total += tvlByItemIdx[i].regular;
        }
    }

    function getTotalValueLockedForWhitelistedUsers()
        public
        view
        returns (uint256 total)
    {
        for (uint256 i = 0; i < tvlByItemIdx.length; i++) {
            total += tvlByItemIdx[i].whitelisted;
        }
    }

    function getTotalPreOrderedItems() public view returns (uint256 total) {
        for (uint256 i = 0; i < amountByItemIdx.length; i++) {
            total += amountByItemIdx[i].total();
        }
    }

    function getTotalPreOrdersByItem(uint256 itemIdx)
        public
        view
        returns (uint256 total)
    {
        require(itemIdx < items.length, "PreSale: out of bounds");
        total = amountByItemIdx[itemIdx].total();
    }

    function getTotalPreOrderedItemsByUser(address user)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < items.length; i++) {
            amount += userToItemIdxToAmount[user][i].amountAsRegular;
            amount += userToItemIdxToAmount[user][i].amountAsWhitelisted;
        }
    }

    function getTotalPreOrderedItemsForRegularUsers()
        public
        view
        returns (uint256 total)
    {
        for (uint256 i = 0; i < amountByItemIdx.length; i++) {
            total += amountByItemIdx[i].regular;
        }
    }

    function getTotalPreOrderedItemsForWhitelistedUsers()
        public
        view
        returns (uint256 total)
    {
        for (uint256 i = 0; i < amountByItemIdx.length; i++) {
            total += amountByItemIdx[i].whitelisted;
        }
    }

    //========== Internal API ================================================//

    function _isWhitelisted(address user) internal view returns (bool) {
        return whitelist[user];
    }

    function _createPreOrder(
        address user,
        uint256 itemIdx,
        uint256 amount,
        uint256 totalPrice
    ) internal {
        bool isWhitelisted = _isWhitelisted(user);

        userToItemIdxToAmount[user][itemIdx].addAmount(isWhitelisted, amount);
        userToItemIdxToAmount[user][itemIdx].addTotalPaid(
            isWhitelisted,
            totalPrice
        );

        amountByItemIdx[itemIdx].add(isWhitelisted, amount);
        tvlByItemIdx[itemIdx].add(isWhitelisted, totalPrice);
    }

    function _burnPreOrderForUser(address user, uint256 itemIdx)
        internal
        returns (uint256 amount, uint256 totalPaid)
    {
        PlacedOrder storage order = userToItemIdxToAmount[user][itemIdx];

        amountByItemIdx[itemIdx].sub(true, order.amountAsWhitelisted);
        amountByItemIdx[itemIdx].sub(false, order.amountAsRegular);
        tvlByItemIdx[itemIdx].sub(true, order.totalPaidAsWhitelisted);
        tvlByItemIdx[itemIdx].sub(false, order.totalPaidAsRegular);

        (amount, totalPaid) = userToItemIdxToAmount[user][itemIdx].reset();
    }

    function _burnAllPreOrdersForUser(address user)
        internal
        returns (uint256 deposited)
    {
        deposited = 0;
        for (uint256 i = 0; i < items.length; i++) {
            PlacedOrder storage order = userToItemIdxToAmount[user][i];

            amountByItemIdx[i].sub(true, order.amountAsWhitelisted);
            amountByItemIdx[i].sub(false, order.amountAsRegular);
            tvlByItemIdx[i].sub(true, order.totalPaidAsWhitelisted);
            tvlByItemIdx[i].sub(false, order.totalPaidAsRegular);

            (, uint256 totalPaid) = order.reset();
            deposited += totalPaid;
        }
    }

    function _resetAllowance() internal {
        paymentToken.safeIncreaseAllowance(
            multisig,
            type(uint256).max -
                paymentToken.allowance(address(this), msg.sender)
        );
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Subscriptions is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    /// @notice revert when a caller is not EoA.
    error OnlyEoA();
    /// @notice revert when a pack, count, mount or price are invalid.
    error InvalidPack();
    /// @notice revert when a try to subscribe with Invalid ETH Amount.
    error InvalidETHAmount();
    /// @notice revert when a try to subscribe to a Inactive pack.
    error PackInactive();
    /// @notice revert when try to set or update an Invalid address.
    error InvalidTreasury();
    /// @notice revert when try to tranfer to a contrat that not implement receive.
    error WithdrawalFailed();
    /// @notice revert when subscritions are paused, and someone try to get one.
    error SubscriptionPaused();

    struct Subscription {
        uint256 packId;
        address subscriber;
        uint256 deadline;
    }

    struct Pack {
        uint256 count;
        uint256 months;
        uint256 price;
        bool active;
    }

    /// @notice Toggle for pause/unpause subscriptions
    bool private subscriptionPaused;
    /// @notice Count of subscription
    /// @dev Start on 0
    uint256 private nextSubscriptionId;
    /// @notice Count of pack
    /// @dev Start on 0
    uint256 private nextPackId;
   /// @notice Treasury
   /// @dev must be a contract. 
    address private treasury;

    /// @notice Registry of packs
    mapping(uint256 => Pack) public packs;
    /// @notice Registry of subscriptions
    mapping(uint256 => Subscription) private subscriptions;

    /// @notice Emitted new Subscribed
    /// @dev Explain to a developer any extra details
    /// @param subscriber  the address that get the subsciption.
    /// @param subscriptionId the subsciption ID.
    /// @param pack the pack of the subsciption.
    /// @param deadline the date until the subsciption is active.
    event Subscribed(
        address indexed subscriber,
        uint256 subscriptionId,
        uint256 pack,
        uint256 deadline
    );

    /// @notice Emitted when treasure change
    /// @dev must be a contract
    /// @param sender  the owner of contract that change the treasure
    /// @param oldTreasury old address of treasury
    /// @param newTreasury new address of treasury
    event TreasuryChanged(
        address indexed sender,
        address oldTreasury,
        address newTreasury
    );

    /// @notice Emitted when Pack edited.
    /// @param sender  the owner of contract that edit the pack
    /// @param packId pack ti edit
    /// @param count new count
    /// @param months new count of months
    /// @param price new price of pack
    /// @param active pause/unpause pack
    event PackEdited(
        address indexed sender,
        uint256 packId,
        uint256 count,
        uint256 months,
        uint256 price,
        bool active
    );

    /// @notice Emitted when Pack added.
    /// @param sender  the owner of contract that edit the pack
    /// @param packId pack to add
    /// @param count the count
    /// @param months count of months
    /// @param price price of pack
    /// @param active pause/unpause pack
    event PackAdded(
        address indexed sender,
        uint256 packId,
        uint256 count,
        uint256 months,
        uint256 price,
        bool active
    );

    /// @notice Emitted when Pack Paused.
    /// @param sender  the owner of contract that pause the pack
    /// @param packId pack to add to pause
    event PackPaused(address indexed sender, uint256 packId);

    /// @notice Emitted when Pack unpaused.
    /// @param sender  the owner of contract that unpause the pack
    /// @param packId pack to add to unpause
    event PackUnpaused(address indexed sender, uint256 packId);

    /// @notice Emitted when Subscription status change.
    /// @param sender  the owner of contract that change the status
    /// @param toggleSubscription status change
    event ToggleSubscription(address indexed sender, bool toggleSubscription);
    
    /// @notice Emitted when withdrawal.
    /// @param sender the address that call Withdrawal
    /// @param treasuryAddress the address transfer to
    /// @param value the amount withdrawal
    event Withdrawal(
        address indexed sender,
        address treasuryAddress,
        uint256 value
    );

    function initialize(address _treasury) public initializer onlyInitializing {
        __UUPSUpgradeable_init_unchained();
        __Ownable_init_unchained();
        if (_treasury == address(0)) revert InvalidTreasury();
        if (_treasury.code.length == 0) revert InvalidTreasury();
        subscriptionPaused = true;
        treasury = _treasury;
    }

    function subscribe(uint256 pack) external payable {
        if(subscriptionPaused) revert SubscriptionPaused();
        if (msg.sender.code.length > 0) revert OnlyEoA();
        if (nextPackId > 0 && pack > nextPackId - 1) revert InvalidPack();
        if (!packs[pack].active) revert PackInactive();
        if (packs[pack].price != msg.value) revert InvalidETHAmount();
        uint256 deadline = block.timestamp + (30 days * packs[pack].months); // solhint-disable-line not-rely-on-time
        subscriptions[nextSubscriptionId] = Subscription(
            pack,
            msg.sender,
            deadline
        );

        emit Subscribed(msg.sender, nextSubscriptionId++, pack, deadline);
    }

    function editPack(
        uint256 pack,
        uint256 count,
        uint256 months,
        uint256 price,
        bool active
    ) external onlyOwner {
        if (nextPackId == 0) revert InvalidPack();
        if (pack > nextPackId - 1) revert InvalidPack();
        if (count == 0) revert InvalidPack();
        if (price == 0) revert InvalidPack();
        if (months == 0) revert InvalidPack();
        packs[pack] = Pack(count, months, price, active);

        emit PackEdited(msg.sender, pack, count, months, price, active);
    }

    function addPack(
        uint256 count,
        uint256 months,
        uint256 price,
        bool active
    ) external onlyOwner {
        if (count == 0) revert InvalidPack();
        if (price == 0) revert InvalidPack();
        if (months == 0) revert InvalidPack();

        packs[nextPackId] = Pack(count, months, price, active);

        emit PackAdded(msg.sender, nextPackId++, count, months, price, active);
    }

    function pausePack(uint256 pack) external onlyOwner {
        if (pack > nextPackId - 1) revert InvalidPack();
        packs[pack].active = false;

        emit PackPaused(msg.sender, pack);
    }

    function unpausePack(uint256 pack) external onlyOwner {
        if (pack > nextPackId - 1) revert InvalidPack();
        packs[pack].active = true;

        emit PackUnpaused(msg.sender, pack);
    }

    function togglesubscription() external onlyOwner {
        subscriptionPaused = !subscriptionPaused;

        emit ToggleSubscription(msg.sender, subscriptionPaused);
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert InvalidTreasury();
        if (_treasury == address(this)) revert InvalidTreasury();
        if (_treasury.code.length == 0) revert InvalidTreasury();
        address oldTreasury = treasury;
        treasury = _treasury;

        emit TreasuryChanged(msg.sender, oldTreasury, treasury);
    }

    function withdraw() external {
        uint256 balance = address(this).balance; 
        (bool success, ) = payable(treasury).call{value: balance}(""); // solhint-disable-line avoid-low-level-calls
        if (!success) revert WithdrawalFailed();

        emit Withdrawal(msg.sender, treasury, balance);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {} // solhint-disable-line no-empty-blocks
}
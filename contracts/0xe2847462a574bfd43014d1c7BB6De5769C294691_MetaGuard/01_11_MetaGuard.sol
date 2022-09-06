// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;
pragma abicoder v1;

import "@gnosis.pm/zodiac/contracts/interfaces/IAvatar.sol";
import "@gnosis.pm/zodiac/contracts/guard/BaseGuard.sol";
import "@gnosis.pm/zodiac/contracts/factory/FactoryFriendly.sol";

contract MetaGuard is FactoryFriendly, BaseGuard {
    address internal constant SENTINEL_GUARDS = address(0x1);

    address public avatar;
    uint256 public maxGuard;
    uint256 public totalGuard;
    mapping(address => address) internal guards;

    /// `guard` is invalid.
    error InvalidGuard(address guard);

    /// `guard` is unknown.
    error UnknownGuard(address guard);

    /// `guard` is already added.
    error AlreadyAddedGuard(address guard);

    /// `guard` is already reach max
    error ExceedMaxGuard(address guard);

    event AddedGuard(address guard);
    event RemovedGuard(address guard);
    event MetaGuardSetup(
        address indexed initiator,
        address owner,
        address avatar,
        uint256 maxGuard,
        address[] guards
    );
    event AvatarSet(address avatar);
    event MaxGuardSet(uint256 maxGuard);

    constructor(
        address _owner,
        address _avatar,
        uint256 _maxGuard,
        address[] memory _guards
    ) {
        bytes memory initializeParams = abi.encode(
            _owner,
            _avatar,
            _maxGuard,
            _guards
        );
        setUp(initializeParams);
    }

    function setUp(bytes memory initParams) public override initializer {
        __Ownable_init();
        (
            address _owner,
            address _avatar,
            uint256 _maxGuard,
            address[] memory _guards
        ) = abi.decode(initParams, (address, address, uint256, address[]));

        avatar = _avatar;
        maxGuard = _maxGuard;
        setupGuards();
        transferOwnership(_owner);

        for (uint256 i = 0; i < _guards.length; i++) {
            addGuard(_guards[i]);
        }

        emit MetaGuardSetup(msg.sender, _owner, _avatar, _maxGuard, _guards);
    }

    function setupGuards() internal {
        require(
            guards[SENTINEL_GUARDS] == address(0),
            "setupGuards has already been called"
        );
        guards[SENTINEL_GUARDS] = SENTINEL_GUARDS;
    }

    function setAvatar(address _avatar) public onlyOwner {
        avatar = _avatar;
        emit AvatarSet(avatar);
    }

    function setMaxGuard(uint256 _maxGuard) public onlyOwner {
        maxGuard = _maxGuard;
        emit MaxGuardSet(maxGuard);
    }

    /// @dev Guard transactions only use the first four parameters: to, value, data, and operation.
    /// Guard.sol hardcodes the remaining parameters as 0 since they are not used for guard transactions.
    /// @notice This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external override {
        address currentGuard = guards[SENTINEL_GUARDS];
        while (currentGuard != SENTINEL_GUARDS) {
            IGuard(currentGuard).checkTransaction(
                to,
                value,
                data,
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                signatures,
                msgSender
            );
            currentGuard = guards[currentGuard];
        }
    }

    function checkAfterExecution(bytes32 txHash, bool success)
        external
        override
    {
        address currentGuard = guards[SENTINEL_GUARDS];
        while (currentGuard != SENTINEL_GUARDS) {
            IGuard(currentGuard).checkAfterExecution(txHash, success);
            currentGuard = guards[currentGuard];
        }
    }

    /// @dev Removes a guard on meta guard.
    /// @notice This can only be called by the owner.
    /// @param prevGuard Guard that pointed to the guard to be removed in the linked list.
    /// @param guard Guard to be removed.
    function removeGuard(address prevGuard, address guard) public onlyOwner {
        if (guard == address(0) || guard == SENTINEL_GUARDS)
            revert InvalidGuard(guard);
        if (guards[prevGuard] != guard) revert UnknownGuard(guard);
        guards[prevGuard] = guards[guard];
        guards[guard] = address(0);
        totalGuard -= 1;
        emit RemovedGuard(guard);
    }

    /// @dev Adds a guard on meta guard.
    /// @param guard Address of the guard to be addd.
    /// @notice This can only be called by the owner.
    function addGuard(address guard) public onlyOwner {
        if (maxGuard > 0 && maxGuard <= totalGuard) //0 means no maximum
            revert ExceedMaxGuard(guard);
        if (guard == address(0) || guard == SENTINEL_GUARDS)
            revert InvalidGuard(guard);
        if (guards[guard] != address(0)) revert AlreadyAddedGuard(guard);
        guards[guard] = guards[SENTINEL_GUARDS];
        guards[SENTINEL_GUARDS] = guard;
        totalGuard += 1;
        emit AddedGuard(guard);
    }

    /// @dev Returns if an guard is added
    /// @return True if the guard is added
    function isGuardAdded(address _guard) public view returns (bool) {
        return SENTINEL_GUARDS != _guard && guards[_guard] != address(0);
    }

    /// @dev Returns array of guards.
    /// @return guards Array of guards.
    function getAllGuards() external view returns (address[] memory) {
        /// Init array with max total guard.
        address[] memory array = new address[](totalGuard);

        /// Populate return array.
        uint256 guardCount = 0;
        address currentGuard = guards[SENTINEL_GUARDS];
        while (
            currentGuard != address(0x0) && currentGuard != SENTINEL_GUARDS
        ) {
            array[guardCount] = currentGuard;
            currentGuard = guards[currentGuard];
            guardCount++;
        }

        return array;
    }

    // solhint-disallow-next-line payable-fallback
    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }
}
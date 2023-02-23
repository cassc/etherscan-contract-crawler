// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IRewardsEscrowV1.sol";

contract RewardsEscrow is IRewardsEscrowV1, Initializable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event IncreaseAllowance(address indexed caller, address indexed token, address indexed spender, uint256 amount);
    event DecreaseAllowance(address indexed caller, address indexed token, address indexed spender, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address roleAdmin) public initializer {
        __RewardsEscrow_init(roleAdmin);
    }

    function __RewardsEscrow_init(address roleAdmin) internal onlyInitializing {
        __AccessControl_init();

        __RewardsEscrow_init_unchained(roleAdmin);
    }

    function __RewardsEscrow_init_unchained(address roleAdmin) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, roleAdmin);
        _grantRole(MANAGER_ROLE, roleAdmin);
    }

    function increaseAllowance(
        address _token,
        address spender,
        uint256 amount,
        address fundsSource
    ) public {
        require(hasRole(MANAGER_ROLE, msg.sender), "RewardsEscrow: caller does not have manager role");

        IERC20Upgradeable token = IERC20Upgradeable(_token);

        token.safeTransferFrom(fundsSource, address(this), amount);
        token.safeIncreaseAllowance(spender, amount);

        emit IncreaseAllowance(msg.sender, _token, spender, amount);
    }

    function decreaseAllowance(
        address _token,
        address spender,
        uint256 amount,
        address fundsDestination
    ) public {
        require(hasRole(MANAGER_ROLE, msg.sender), "RewardsEscrow: caller does not have manager role");

        IERC20Upgradeable token = IERC20Upgradeable(_token);

        token.safeDecreaseAllowance(spender, amount);
        token.safeTransfer(fundsDestination, amount);

        emit DecreaseAllowance(msg.sender, _token, spender, amount);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
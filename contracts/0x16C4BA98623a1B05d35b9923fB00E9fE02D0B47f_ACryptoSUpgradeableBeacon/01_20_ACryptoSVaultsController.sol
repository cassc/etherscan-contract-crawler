//          .8.              ,o888888o.    8 888888888o.   `8.`8888.      ,8' 8 888888888o   8888888 8888888888     ,o888888o.        d888888o.
//         .888.            8888     `88.  8 8888    `88.   `8.`8888.    ,8'  8 8888    `88.       8 8888        . 8888     `88.    .`8888:' `88.
//        :88888.        ,8 8888       `8. 8 8888     `88    `8.`8888.  ,8'   8 8888     `88       8 8888       ,8 8888       `8b   8.`8888.   Y8
//       . `88888.       88 8888           8 8888     ,88     `8.`8888.,8'    8 8888     ,88       8 8888       88 8888        `8b  `8.`8888.
//      .8. `88888.      88 8888           8 8888.   ,88'      `8.`88888'     8 8888.   ,88'       8 8888       88 8888         88   `8.`8888.
//     .8`8. `88888.     88 8888           8 888888888P'        `8. 8888      8 888888888P'        8 8888       88 8888         88    `8.`8888.
//    .8' `8. `88888.    88 8888           8 8888`8b             `8 8888      8 8888               8 8888       88 8888        ,8P     `8.`8888.
//   .8'   `8. `88888.   `8 8888       .8' 8 8888 `8b.            8 8888      8 8888               8 8888       `8 8888       ,8P  8b   `8.`8888.
//  .888888888. `88888.     8888     ,88'  8 8888   `8b.          8 8888      8 8888               8 8888        ` 8888     ,88'   `8b.  ;8.`8888
// .8'       `8. `88888.     `8888888P'    8 8888     `88.        8 8888      8 8888               8 8888           `8888888P'      `Y8888P ,88P'

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

// Using @openzeppelin/[email protected]
import "openzeppelin-contracts-upgradeable-4.7.3/access/AccessControlEnumerableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable-4.7.3/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable-4.7.3/proxy/utils/UUPSUpgradeable.sol";

contract ACryptoSVaultsController is
    Initializable,
    UUPSUpgradeable,
    AccessControlEnumerableUpgradeable
{
    address public strategist;
    address public feesTo;
    uint256 public withdrawalFee;
    uint256 public performanceFee;
    uint256 public strategistReward;

    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _governance,
        address _strategist,
        address _feesTo,
        uint256 _withdrawalFee,
        uint256 _performanceFee,
        uint256 _strategistReward
    ) public initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _governance);
        _setupRole(STRATEGIST_ROLE, _strategist);

        strategist = _strategist;
        feesTo = _feesTo;
        withdrawalFee = _withdrawalFee;
        performanceFee = _performanceFee;
        strategistReward = _strategistReward;
        _validateFees();
    }

    function setStrategist(address _strategist) external onlyGovernance {
        strategist = _strategist;
    }

    function setFeesTo(address _feesTo) external onlyGovernance {
        feesTo = _feesTo;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external onlyGovernance {
        withdrawalFee = _withdrawalFee;
        _validateFees();
    }

    function setPerformanceFee(
        uint256 _performanceFee
    ) external onlyStrategist {
        performanceFee = _performanceFee;
        _validateFees();
    }

    function setStrategistReward(
        uint256 _strategistReward
    ) external onlyStrategist {
        strategistReward = _strategistReward;
        _validateFees();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyGovernance {}

    function _validateFees() internal view {
        require(performanceFee + strategistReward < 1e18, "!fees");
    }

    modifier onlyGovernance() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "!governance");
        _;
    }

    modifier onlyStrategist() {
        require(
            hasRole(STRATEGIST_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "!strategist"
        );
        _;
    }
}
// SPDX-License-Identifier: MIT

/***
 *      ______             _______   __
 *     /      \           |       \ |  \
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *
 *
 *
 */

pragma solidity ^0.8.4;

import {Hyperfied} from "./Hyperfied.sol";
import {IHyperLPoolStorage} from "../interfaces/IHyperStorage.sol";

import {OwnableUninitialized} from "./OwnableUninitialized.sol";
import {
    IUniswapV3Pool
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// solhint-disable max-line-length
import {
    ERC20PermitUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

import {SafeUniswapV3Pool} from "../utils/SafeUniswapV3Pool.sol";

/// @dev Single Global upgradeable state var storage base: APPEND ONLY
/// @dev Add all inherited contracts with state vars here: APPEND ONLY
/// @dev ERC20Upgradable Includes Initialize
// solhint-disable-next-line max-states-count
abstract contract HyperLPoolStorage is
    ERC20PermitUpgradeable, /* XXXX DONT MODIFY ORDERING XXXX */
    ReentrancyGuardUpgradeable,
    OwnableUninitialized,
    Hyperfied,
    IHyperLPoolStorage
{
    using SafeUniswapV3Pool for IUniswapV3Pool;

    // solhint-disable-next-line const-name-snakecase
    string public constant version = "1.0.0";
    // solhint-disable-next-line const-name-snakecase
    uint16 public constant hyperpoolsFeeBPS = 250;
    /// @dev "restricted mint enabled" toggle value must be a number
    // above 10000 to safely avoid collisions for repurposed state var
    uint16 public constant RESTRICTED_MINT_ENABLED = 11111;

    address public immutable hyperpoolsTreasury;

    // XXXXXXXX DO NOT MODIFY ORDERING XXXXXXXX
    int24 public override lowerTick;
    int24 public override upperTick;

    uint16 public hyperpoolsRebalanceBPS;
    uint16 public restrictedMintToggle;
    uint16 public hyperpoolsSlippageBPS;
    uint32 public hyperpoolsSlippageInterval;

    uint16 public managerFeeBPS;
    address public managerTreasury;

    uint256 public managerBalance0;
    uint256 public managerBalance1;
    uint256 public hyperpoolsBalance0;
    uint256 public hyperpoolsBalance1;

    IUniswapV3Pool public override pool;
    IERC20 public override token0;
    IERC20 public override token1;

    bool public whiteListEnabled;
    mapping(address => bool) public whiteList;

    uint128 public restrictedLiquidity;
    bool public rebalanceEnabled;

    event UpdateManagerParams(
        uint16 managerFeeBPS,
        address managerTreasury,
        uint16 hyperpoolsRebalanceBPS,
        uint16 hyperpoolsSlippageBPS,
        uint32 hyperpoolsSlippageInterval
    );

    event ToggleRestrictMint(address, uint16);
    event SetWhiteList(address, address[], bool);
    event RestrictLiquidity(address, uint128);

    // solhint-disable-next-line max-line-length
    constructor(address payable _hyperpools, address _hyperpoolsTreasury)
        Hyperfied(_hyperpools)
    {
        hyperpoolsTreasury = _hyperpoolsTreasury;
    }

    /// @notice initialize storage variables on a new HyperLP pool, only called once
    /// @param _name name of HyperLP token
    /// @param _symbol symbol of HyperLP token
    /// @param _pool address of Uniswap V3 pool
    /// @param _managerFeeBPS proportion of fees earned that go to manager treasury
    /// note that the 4 above params are NOT UPDATEABLE AFTER INILIALIZATION
    /// @param _lowerTick initial lowerTick (only changeable with executiveRebalance)
    /// @param _lowerTick initial upperTick (only changeable with executiveRebalance)
    /// @param _manager_ address of manager (ownership can be transferred)
    function initialize(
        string memory _name,
        string memory _symbol,
        address _pool,
        uint16 _managerFeeBPS,
        int24 _lowerTick,
        int24 _upperTick,
        address _manager_
    ) external override initializer {
        require(_managerFeeBPS <= 10000 - hyperpoolsFeeBPS, "mBPS");

        // these variables are immutable after initialization
        pool = IUniswapV3Pool(_pool);
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());
        managerFeeBPS = _managerFeeBPS; // if set to 0 here manager can still initialize later

        rebalanceEnabled = true;
        whiteListEnabled = false;

        // these variables can be udpated by the manager
        hyperpoolsSlippageInterval = 5 minutes; // default: last five minutes;
        hyperpoolsSlippageBPS = 500; // default: 5% slippage
        hyperpoolsRebalanceBPS = 200; // default: only rebalance if tx fee is lt 2% reinvested
        managerTreasury = _manager_; // default: treasury is admin
        lowerTick = _lowerTick;
        upperTick = _upperTick;
        _manager = _manager_;

        // e.g. "HyperPools Cake V3 USDC/DAI LP" and "HyperLP"
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        __ReentrancyGuard_init();
    }

    /// @notice change configurable hyperpools parameters, only manager can call
    /// @param newManagerFeeBPS Basis Points of fees earned credited to manager (negative to ignore)
    /// @param newManagerTreasury address that collects manager fees (Zero address to ignore)
    /// @param newRebalanceBPS threshold fees earned for hyper pools rebalances (negative to ignore)
    /// @param newSlippageBPS frontrun protection parameter (negative to ignore)
    /// @param newSlippageInterval frontrun protection parameter (negative to ignore)
    // solhint-disable-next-line code-complexity
    function updateManagerParams(
        int16 newManagerFeeBPS,
        address newManagerTreasury,
        int16 newRebalanceBPS,
        int16 newSlippageBPS,
        int32 newSlippageInterval
    ) external onlyManager {
        require(newRebalanceBPS <= 10000, "BPS");
        require(newSlippageBPS <= 10000, "BPS");
        require(newManagerFeeBPS <= 10000 - int16(hyperpoolsFeeBPS), "mBPS");
        if (newManagerFeeBPS >= 0) managerFeeBPS = uint16(newManagerFeeBPS);
        if (newRebalanceBPS >= 0)
            hyperpoolsRebalanceBPS = uint16(newRebalanceBPS);
        if (newSlippageBPS >= 0) hyperpoolsSlippageBPS = uint16(newSlippageBPS);
        if (newSlippageInterval >= 0)
            hyperpoolsSlippageInterval = uint32(newSlippageInterval);
        if (address(0) != newManagerTreasury)
            managerTreasury = newManagerTreasury;
        emit UpdateManagerParams(
            managerFeeBPS,
            managerTreasury,
            hyperpoolsRebalanceBPS,
            hyperpoolsSlippageBPS,
            hyperpoolsSlippageInterval
        );
    }

    function toggleRestrictMint() external onlyManager {
        restrictedMintToggle = restrictedMintToggle == RESTRICTED_MINT_ENABLED
            ? 0
            : RESTRICTED_MINT_ENABLED;
        emit ToggleRestrictMint(_msgSender(), restrictedMintToggle);
    }

    function enableWhiteList(bool enabled) external onlyManager {
        whiteListEnabled = enabled;
    }

    function enableRebalance(bool enabled) external {
        require(msg.sender == HYPERPOOLS, "Hyperfied: Only hyperpools");
        rebalanceEnabled = enabled;
    }

    function setWhiteList(address[] memory depositors, bool listed)
        external
        onlyManager
    {
        for (uint256 i = 0; i < depositors.length; ) {
            whiteList[depositors[i]] = listed;
            unchecked {i++;}
        }
        emit SetWhiteList(_msgSender(), depositors, listed);
    }

    function restrictLiquidity(uint128 _liquidity) external onlyManager {
        restrictedLiquidity = _liquidity;
        emit RestrictLiquidity(_msgSender(), _liquidity);
    }

    function renounceOwnership() public virtual override onlyManager {
        managerTreasury = address(0);
        managerFeeBPS = 0;
        managerBalance0 = 0;
        managerBalance1 = 0;
        super.renounceOwnership();
    }

    function getLiquidity() public view returns (uint128 liquidity) {
        (liquidity, , , , ) = pool.safePositions(_getPositionID());
    }

    function getPositionID() external view returns (bytes32 positionID) {
        return _getPositionID();
    }

    function _getPositionID() internal view returns (bytes32 positionID) {
        return keccak256(abi.encodePacked(address(this), lowerTick, upperTick));
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
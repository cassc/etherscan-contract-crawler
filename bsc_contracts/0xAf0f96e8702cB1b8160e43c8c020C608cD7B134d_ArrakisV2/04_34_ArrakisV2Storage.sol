// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import {
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Range, Rebalance, InitializePayload} from "../structs/SArrakisV2.sol";

/// @title ArrakisV2Storage base contract containing all ArrakisV2 storage variables.
// solhint-disable-next-line max-states-count
abstract contract ArrakisV2Storage is
    OwnableUpgradeable,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    IUniswapV3Factory public immutable factory;

    IERC20 public token0;
    IERC20 public token1;

    uint256 public init0;
    uint256 public init1;

    // #region manager data

    uint16 public managerFeeBPS;
    uint256 public managerBalance0;
    uint256 public managerBalance1;
    address public manager;
    address public restrictedMint;

    // #endregion manager data

    Range[] internal _ranges;

    EnumerableSet.AddressSet internal _pools;
    EnumerableSet.AddressSet internal _routers;

    // #region events

    event LogMint(
        address indexed receiver,
        uint256 mintAmount,
        uint256 amount0In,
        uint256 amount1In
    );

    event LogBurn(
        address indexed receiver,
        uint256 burnAmount,
        uint256 amount0Out,
        uint256 amount1Out
    );

    event LPBurned(
        address indexed user,
        uint256 burnAmount0,
        uint256 burnAmount1
    );

    event LogRebalance(
        Rebalance rebalanceParams,
        uint256 swapDelta0,
        uint256 swapDelta1
    );

    event LogCollectedFees(uint256 fee0, uint256 fee1);

    event LogWithdrawManagerBalance(uint256 amount0, uint256 amount1);
    // #region Setting events

    event LogSetInits(uint256 init0, uint256 init1);
    event LogAddPools(uint24[] feeTiers);
    event LogRemovePools(address[] pools);
    event LogSetManager(address newManager);
    event LogSetManagerFeeBPS(uint16 managerFeeBPS);
    event LogRestrictedMint(address minter);
    event LogWhitelistRouters(address[] routers);
    event LogBlacklistRouters(address[] routers);
    // #endregion Setting events

    // #endregion events

    // #region modifiers

    modifier onlyManager() {
        require(manager == msg.sender, "NM");
        _;
    }

    // #endregion modifiers

    constructor(IUniswapV3Factory factory_) {
        require(address(factory_) != address(0), "ZF");
        factory = factory_;
    }

    // solhint-disable-next-line function-max-lines
    function initialize(
        string calldata name_,
        string calldata symbol_,
        InitializePayload calldata params_
    ) external initializer {
        require(params_.feeTiers.length > 0, "NFT");
        require(params_.token0 != address(0), "T0");
        require(params_.token0 < params_.token1, "WTO");
        require(params_.owner != address(0), "OAZ");
        require(params_.manager != address(0), "MAZ");
        require(params_.init0 > 0 || params_.init1 > 0, "I");

        __ERC20_init(name_, symbol_);
        __ReentrancyGuard_init();

        _addPools(params_.feeTiers, params_.token0, params_.token1);
        _whitelistRouters(params_.routers);

        token0 = IERC20(params_.token0);
        token1 = IERC20(params_.token1);

        _transferOwnership(params_.owner);

        manager = params_.manager;

        init0 = params_.init0;
        init1 = params_.init1;

        emit LogAddPools(params_.feeTiers);
        emit LogSetInits(params_.init0, params_.init1);
        emit LogSetManager(params_.manager);
    }

    // #region setter functions

    /// @notice set initial virtual allocation of token0 and token1
    /// @param init0_ initial virtual allocation of token 0.
    /// @param init1_ initial virtual allocation of token 1.
    /// @dev only callable by restrictedMint or by owner if restrictedMint is unset.
    function setInits(uint256 init0_, uint256 init1_) external {
        require(init0_ > 0 || init1_ > 0, "I");
        require(totalSupply() == 0, "TS");
        address requiredCaller = restrictedMint == address(0)
            ? owner()
            : restrictedMint;
        require(msg.sender == requiredCaller, "R");
        emit LogSetInits(init0 = init0_, init1 = init1_);
    }

    /// @notice whitelist pools
    /// @param feeTiers_ list of fee tiers associated to pools to whitelist.
    /// @dev only callable by owner.
    function addPools(uint24[] calldata feeTiers_) external onlyOwner {
        _addPools(feeTiers_, address(token0), address(token1));
        emit LogAddPools(feeTiers_);
    }

    /// @notice unwhitelist pools
    /// @param pools_ list of pools to remove from whitelist.
    /// @dev only callable by owner.
    function removePools(address[] calldata pools_) external onlyOwner {
        for (uint256 i = 0; i < pools_.length; i++) {
            require(_pools.contains(pools_[i]), "NP");

            _pools.remove(pools_[i]);
        }
        emit LogRemovePools(pools_);
    }

    /// @notice whitelist routers
    /// @param routers_ list of router addresses to whitelist.
    /// @dev only callable by owner.
    function whitelistRouters(address[] calldata routers_) external onlyOwner {
        _whitelistRouters(routers_);
    }

    /// @notice blacklist routers
    /// @param routers_ list of routers addresses to blacklist.
    /// @dev only callable by owner.
    function blacklistRouters(address[] calldata routers_) external onlyOwner {
        for (uint256 i = 0; i < routers_.length; i++) {
            require(_routers.contains(routers_[i]), "RW");

            _routers.remove(routers_[i]);
        }
        emit LogBlacklistRouters(routers_);
    }

    /// @notice set manager
    /// @param manager_ manager address.
    /// @dev only callable by owner.
    function setManager(address manager_) external onlyOwner {
        manager = manager_;
        emit LogSetManager(manager_);
    }

    /// @notice set manager fee bps
    /// @param managerFeeBPS_ manager fee in basis points.
    /// @dev only callable by manager.
    function setManagerFeeBPS(uint16 managerFeeBPS_) external onlyManager {
        require(managerFeeBPS_ <= 10000, "MFO");
        managerFeeBPS = managerFeeBPS_;
        emit LogSetManagerFeeBPS(managerFeeBPS_);
    }

    /// @notice set restricted minter
    /// @param minter_ address of restricted minter.
    /// @dev only callable by owner.
    function setRestrictedMint(address minter_) external onlyOwner {
        restrictedMint = minter_;
        emit LogRestrictedMint(minter_);
    }

    // #endregion setter functions

    // #region getter functions

    /// @notice get full list of ranges, guaranteed to contain all active vault LP Positions.
    /// @return ranges list of ranges
    function getRanges() external view returns (Range[] memory) {
        return _ranges;
    }

    function getPools() external view returns (address[] memory) {
        uint256 len = _pools.length();
        address[] memory output = new address[](len);
        for (uint256 i; i < len; i++) {
            output[i] = _pools.at(i);
        }

        return output;
    }

    function getRouters() external view returns (address[] memory) {
        uint256 len = _routers.length();
        address[] memory output = new address[](len);
        for (uint256 i; i < len; i++) {
            output[i] = _routers.at(i);
        }

        return output;
    }

    // #endregion getter functions

    // #region internal functions

    function _uniswapV3CallBack(uint256 amount0_, uint256 amount1_) internal {
        require(_pools.contains(msg.sender), "CC");

        if (amount0_ > 0) token0.safeTransfer(msg.sender, amount0_);
        if (amount1_ > 0) token1.safeTransfer(msg.sender, amount1_);
    }

    function _addPools(
        uint24[] calldata feeTiers_,
        address token0Addr_,
        address token1Addr_
    ) internal {
        for (uint256 i = 0; i < feeTiers_.length; i++) {
            address pool = factory.getPool(
                token0Addr_,
                token1Addr_,
                feeTiers_[i]
            );

            require(pool != address(0), "ZA");
            require(!_pools.contains(pool), "P");

            // explicit.
            _pools.add(pool);
        }
    }

    function _whitelistRouters(address[] calldata routers_) internal {
        for (uint256 i = 0; i < routers_.length; i++) {
            require(
                routers_[i] != address(token0) &&
                    routers_[i] != address(token1),
                "RT"
            );
            require(!_routers.contains(routers_[i]), "CR");
            // explicit.
            _routers.add(routers_[i]);
        }

        emit LogWhitelistRouters(routers_);
    }

    // #endregion internal functions
}
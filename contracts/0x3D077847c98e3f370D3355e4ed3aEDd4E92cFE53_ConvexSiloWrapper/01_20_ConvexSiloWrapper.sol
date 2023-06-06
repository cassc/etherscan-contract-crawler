// SPDX-License-Identifier: MIT
// Original Copyright 2021 convex-eth
// Modified Copyright 2022 Silo Finance
pragma solidity 0.6.12; // solhint-disable-line compiler-version
pragma experimental ABIEncoderV2;

import "../../external/convex/wrappers/ConvexStakingWrapper.sol";
import "../../lib/Ping06.sol";
import "./interfaces/ISiloRepository0612Like.sol";
import "./interfaces/ISilo0612Like.sol";
import "../../interfaces/IConvexSiloWrapper.sol";

contract ConvexSiloWrapper is IConvexSiloWrapper, ConvexStakingWrapper {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes4 public constant SILO_REPOSITORY_PING_SELECTOR = bytes4(keccak256("siloRepositoryPing()"));
    string public constant ERROR_SILO_WRAPPER_ALREADY_INIT = "SiloWrapperAlreadyInit";
    string public constant ERROR_INVALID_SILO_REPOSITORY = "InvalidSiloRepositoryAddress";
    string public constant ERROR_COLLATERAL_VAULT_ZERO = "CollateralVaultNotCreated";

    // solhint-disable-next-line var-name-mixedcase
    ISiloRepository0612Like public immutable SILO_REPOSITORY;

    /// @dev Check if the contract is Silo or Router to not account its balance in rewards distribution. Deprecated
    ///     Silo users will not get the rewards. We do not support deprecated Silo shares for balance calculations
    ///     to save gas.
    mapping(address => bool) public isSiloOrRouter;

    /// @dev the flag for tracking the `initializeSiloWrapper` function execution
    bool public isSiloWrapperInit;

    event CollateralVaultUpdated(address indexed newVault);

    /// @dev Deploy this contract and save SiloRepository address for collateral vault syncing
    /// @param _siloRepository address
    constructor(ISiloRepository0612Like _siloRepository) public {
        if (!Ping06.pong(address(_siloRepository), SILO_REPOSITORY_PING_SELECTOR)) {
            revert(ERROR_INVALID_SILO_REPOSITORY);
        }

        SILO_REPOSITORY = _siloRepository;
    }

    /// @inheritdoc IConvexSiloWrapper
    function initializeSiloWrapper(uint256 _poolId) external override virtual {
        if (isSiloWrapperInit) revert(ERROR_SILO_WRAPPER_ALREADY_INIT);
        isSiloWrapperInit = true;

        // if the parent `initialize` function was already called for some reason, do not block
        // `initializeSiloWrapper` from execution.
        if (!isInit) {
            this.initialize(_poolId);
        }

        // after `this.initialize` call the owner will be address(this)
        owner = SILO_REPOSITORY.owner();
        emit OwnershipTransferred(address(this), owner);

        _tokenname = string(abi.encodePacked("Staked ", ERC20(convexToken).name(), " Silo"));
        _tokensymbol = string(abi.encodePacked("stk", ERC20(convexToken).symbol(), "-silo"));
    }

    /// @inheritdoc IConvexSiloWrapper
    function checkpointSingle(address _account) external override virtual {
        _checkpoint([_account, address(0)]);
    }

    /// @inheritdoc IConvexSiloWrapper
    function checkpointPair(address _from, address _to) external override virtual {
        _checkpoint([_from, _to]);
    }

    /// @inheritdoc IConvexSiloWrapper
    function syncSilo() external override virtual {
        address silo = SILO_REPOSITORY.getSilo(address(this));
        if (silo == address(0)) revert(ERROR_COLLATERAL_VAULT_ZERO);
        isSiloOrRouter[silo] = true;

        address router = SILO_REPOSITORY.router();
        isSiloOrRouter[router] = true;

        if (collateralVault != silo) {
            collateralVault = silo;
            emit CollateralVaultUpdated(silo);
        }
    }

    /// @inheritdoc IConvexSiloWrapper
    function underlyingToken() external view override virtual returns (address) {
        return curveToken;
    }

    /// @inheritdoc IConvexSiloWrapper
    function deposit(uint256 _amount, address _to) public virtual override(IConvexSiloWrapper, ConvexStakingWrapper) {
        super.deposit(_amount, _to);
    }

    /// @inheritdoc IConvexSiloWrapper
    function withdrawAndUnwrap(uint256 _amount) public virtual override(IConvexSiloWrapper, ConvexStakingWrapper) {
        super.withdrawAndUnwrap(_amount);
    }

    /// @dev Function to get user's ConvexSiloWrapper balance with deposited collateral included for proper
    ///     rewards calculation
    /// @param _account address
    function _getDepositedBalance(address _account) internal virtual override view returns (uint256) {
        if (_account == address(0) || isSiloOrRouter[_account]) {
            return 0;
        }

        if (collateralVault == address(0)) {
            return balanceOf(_account);
        }

        ISilo0612Like.AssetStorage memory assetStorage = ISilo0612Like(collateralVault).assetStorage(address(this));

        uint256 shares = IERC20(assetStorage.collateralOnlyToken).balanceOf(_account);
        uint256 totalShares = IERC20(assetStorage.collateralOnlyToken).totalSupply();
        uint256 totalDeposits = assetStorage.collateralOnlyDeposits;

        // ConvexStakingWrapper tokens will be used only as `collateralOnly` asset
        // that is why we take into account only `collateralOnly` type of Silo collateral
        // there will be no regular collateral, no interest applied to deposits
        return balanceOf(_account).add(_toAmount(shares, totalDeposits, totalShares));
    }

    /// @dev Function for user's deposited amount calculation. It is used to include user's deposited tokens to
    ///     Convex rewards calculation. Rounding up or down the shares does not affect the rewards calculation.
    /// @param _share amount of user's collateral shares
    /// @param _totalAmount total deposited amount in Silo
    /// @param _totalShares shares total supply
    /// @return amount of user's collateral
    function _toAmount(uint256 _share, uint256 _totalAmount, uint256 _totalShares) internal pure returns (uint256) {
        if (_totalShares == 0 || _totalAmount == 0) {
            return 0;
        }

        // we can use regular division, `_totalShares` != 0 because of the if statement above
        return _share.mul(_totalAmount) / _totalShares;
    }
}
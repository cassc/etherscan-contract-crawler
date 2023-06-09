// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IWrappedNativeToken.sol";
import "./interfaces/IConvexSiloWrapper.sol";
import "./interfaces/ISilo.sol";
import "./interfaces/ISiloRepository.sol";

import "./lib/Ping.sol";
import "./lib/TokenHelper.sol";
import "./lib/EasyMath.sol";

/// @title SiloRouterV2
/// @notice Silo Router is a utility contract that aims to improve UX. It can batch any number or combination
/// of actions (Deposit, Withdraw, Borrow, Repay, Wrap, Unwrap) and execute them in a single transaction.
/// @dev SiloRouter requires only first action asset to be approved.
/// @custom:security-contact [email protected]
contract SiloRouterV2 is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EasyMath for uint256;

    // @notice Action types that are supported
    enum ActionType { Deposit, Withdraw, Borrow, Repay, Wrap, Unwrap }

    struct Action {
        // what do you want to do?
        ActionType actionType;
        // which Silo are you interacting with? Empty in case of external actions.
        ISilo silo;
        // what asset do you want to use? Wrapped asset in case of external actions.
        IERC20 asset;
        // how much asset do you want to use?
        uint256 amount;
        // is it an action on collateral only?
        bool collateralOnly;
    }

    // @dev native asset wrapped token. In case of Ether, it's WETH.
    IWrappedNativeToken public immutable wrappedNativeToken;
    ISiloRepository public immutable siloRepository;

    error ApprovalFailed();
    error ERC20TransferFailed();
    error EthTransferFailed();
    error InvalidSilo();
    error InvalidSiloRepository();
    error UnsupportedAction();

    constructor (address _wrappedNativeToken, address _siloRepository) {
        if (!Ping.pong(ISiloRepository(_siloRepository).siloRepositoryPing)) {
            revert InvalidSiloRepository();
        }

        TokenHelper.assertAndGetDecimals(_wrappedNativeToken);

        wrappedNativeToken = IWrappedNativeToken(_wrappedNativeToken);
        siloRepository = ISiloRepository(_siloRepository);
    }

    /// @dev needed for unwrapping WETH
    receive() external payable {
        // `execute` method calls `IWrappedNativeToken.withdraw()`
        // and we need to receive the withdrawn ETH unconditionally
    }

    /// @notice Execute actions
    /// @dev User can bundle any combination and number of actions. It's possible to do multiple deposits,
    /// withdraws etc. For that reason router may need to send multiple tokens back to the user. Combining
    /// Ether and WETH deposits will make this function revert.
    /// @param _actions array of actions to execute
    function execute(Action[] calldata _actions) external virtual payable nonReentrant {
        _executeActions(_actions);

        // send all assets to user
        for (uint256 i = 0; i < _actions.length;) {
            IERC20 asset = _resolveAssetToSend(_actions[i]);
            uint256 remainingBalance = asset.balanceOf(address(this));

            if (remainingBalance != 0) {
                _sendAsset(asset, remainingBalance);
            }

            // we can safely uncheck i because of `i < _actions.length` loop condition
            unchecked {
                i++;
            }
        }

        // should never have leftover ETH, however
        if (msg.value != 0 && address(this).balance != 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{value: address(this).balance}("");
            if (!success) revert EthTransferFailed();
        }
    }

    function siloRouterPing() external pure returns (bytes4) {
        return this.siloRouterPing.selector;
    }

    /// @dev Execute multiple Silo actions of any type from `ActionType`
    /// @param _actions array of actions to execute
    function _executeActions(Action[] calldata _actions) internal virtual {
        for (uint256 i = 0; i < _actions.length;) {
            if (_isActionExternal(_actions[i].actionType)) {
                _executeExternalAction(_actions[i]);
            } else {
                _executeSiloAction(_actions[i]);
            }

            // we can safely uncheck i because of `i < _actions.length` loop condition
            unchecked {
                i++;
            }
        }
    }

    /// @dev Execute Silo action: deposit, withdraw, borrow or repay
    /// @param _action action to execute, this can be one of many actions in the whole flow
    function _executeSiloAction(Action calldata _action) internal virtual {
        if (!siloRepository.isSilo(address(_action.silo))) revert InvalidSilo();

        if (_action.actionType == ActionType.Deposit) {
            _pullAssetIfNeeded(_action.asset, _action.amount);
            _approveIfNeeded(_action.asset, address(_action.silo), _action.amount);
            _action.silo.depositFor(address(_action.asset), msg.sender, _action.amount, _action.collateralOnly);
        } else if (_action.actionType == ActionType.Withdraw) {
            _action.silo.withdrawFor(
                address(_action.asset),
                msg.sender,
                address(this),
                _action.amount,
                _action.collateralOnly
            );
        } else if (_action.actionType == ActionType.Borrow) {
            _action.silo.borrowFor(address(_action.asset), msg.sender, address(this), _action.amount);
        } else if (_action.actionType == ActionType.Repay) {
            uint256 repayAmount; 

            if (_action.amount == type(uint256).max) {
                _action.silo.accrueInterest(address(_action.asset));
                repayAmount = _getRepayAmount(_action.silo, _action.asset, msg.sender);
            } else {
                repayAmount = _action.amount;
            }

            _pullAssetIfNeeded(_action.asset, repayAmount);
            _approveIfNeeded(_action.asset, address(_action.silo), repayAmount);
            _action.silo.repayFor(address(_action.asset), msg.sender, repayAmount);
        } else {
            revert UnsupportedAction();
        }
    }

    /// @dev Execute external action: wrap or unwrap tokens
    /// @param _action action to execute, this can be one of many actions in the whole flow
    function _executeExternalAction(Action calldata _action) internal virtual {
        if (_action.actionType == ActionType.Wrap) {
            IERC20 underlyingToken = IERC20(IConvexSiloWrapper(address(_action.asset)).underlyingToken());
            _pullAssetIfNeeded(underlyingToken, _action.amount);
            _approveIfNeeded(underlyingToken, address(_action.asset), _action.amount);
            IConvexSiloWrapper(address(_action.asset)).deposit(_action.amount, address(this));
        } else if (_action.actionType == ActionType.Unwrap) {
            _pullAssetIfNeeded(_action.asset, _action.amount);
            IConvexSiloWrapper(address(_action.asset)).withdrawAndUnwrap(_action.amount);
        } else {
            revert UnsupportedAction();
        }
    }

    /// @dev Approve Silo to transfer token if current allowance is not enough
    /// @param _asset token to be approved
    /// @param _spender Silo address that spends the token
    /// @param _amount amount of token to be spent
    function _approveIfNeeded(
        IERC20 _asset,
        address _spender,
        uint256 _amount
    ) internal virtual {
        if (_asset.allowance(address(this), _spender) < _amount) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory data) = address(_asset).call(
                abi.encodeCall(IERC20.approve, (_spender, type(uint256).max))
            );

            // Support non-standard tokens that don't return bool
            if(!success || !(data.length == 0 || abi.decode(data, (bool)))) {
                revert ApprovalFailed();
            }
        }
    }

    /// @dev Transfer funds from msg.sender to this contract if balance is not enough
    /// @param _asset token to be approved
    /// @param _amount amount of token to be spent
    function _pullAssetIfNeeded(IERC20 _asset, uint256 _amount) internal virtual {
        uint256 remainingBalance = _asset.balanceOf(address(this));

        if (remainingBalance < _amount) {
            // There can't be an underflow in the subtraction because of the previous check
            unchecked {
                _pullAsset(_asset, _amount - remainingBalance);
            }
        }
    }

    /// @dev Transfer asset from user to router
    /// @param _asset asset address to be transferred
    /// @param _amount amount of asset to be transferred
    function _pullAsset(IERC20 _asset, uint256 _amount) internal virtual {
        if (msg.value != 0 && _asset == wrappedNativeToken) {
            wrappedNativeToken.deposit{value: _amount}();
        } else {
            _asset.safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    /// @dev Transfer asset from router to user
    /// @param _asset asset address to be transferred
    /// @param _amount amount of asset to be transferred
    function _sendAsset(IERC20 _asset, uint256 _amount) internal virtual {
        if (address(_asset) == address(wrappedNativeToken)) {
            wrappedNativeToken.withdraw(_amount);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{value: _amount}("");
            if (!success) revert ERC20TransferFailed();
        } else {
            _asset.safeTransfer(msg.sender, _amount);
        }
    }

    /// @dev Helper that calculates the maximum amount to repay if type(uint256).max is passed
    /// @param _silo silo for which the debt will be repaid
    /// @param _asset asset being repaid
    /// @param _borrower user for which the debt being repaid
    function _getRepayAmount(ISilo _silo, IERC20 _asset, address _borrower)
        internal
        view
        virtual
        returns (uint256)
    {
        ISilo.AssetStorage memory _assetStorage = _silo.assetStorage(address(_asset));
        uint256 repayShare = _assetStorage.debtToken.balanceOf(_borrower);
        uint256 debtTokenTotalSupply = _assetStorage.debtToken.totalSupply();
        uint256 totalBorrowed = _assetStorage.totalBorrowAmount;
        return repayShare.toAmountRoundUp(totalBorrowed, debtTokenTotalSupply);
    }

    /// @dev Helper that calculates if the action external or related to Silo
    /// @return true if the action is external, false otherwise
    function _isActionExternal(ActionType action) internal pure virtual returns (bool) {
        return action == ActionType.Wrap || action == ActionType.Unwrap;
    }

    /// @dev Resolve asset to send back to user on finish of the actions. Usually, it is the equal to `_action.asset`.
    ///     Returns the address of underlying asset in case of the `Unwrap` action.
    /// @param _action specific action struct
    /// @return asset address
    function _resolveAssetToSend(Action calldata _action) internal view virtual returns (IERC20 asset) {
        if (_action.actionType == ActionType.Unwrap) {
            asset = IERC20(IConvexSiloWrapper(address(_action.asset)).underlyingToken());
        } else {
            asset = _action.asset;
        }
    }
}
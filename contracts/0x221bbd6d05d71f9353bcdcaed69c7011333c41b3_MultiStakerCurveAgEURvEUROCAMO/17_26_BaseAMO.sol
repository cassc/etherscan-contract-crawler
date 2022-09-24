// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "./BaseAMOStorage.sol";
import "../interfaces/IAMO.sol";

/// @title BaseAMO
/// @author Angle Core Team
/// @notice This is a base contract to be inherited by all AMOs of the protocol
abstract contract BaseAMO is BaseAMOStorage, IAMO {
    using SafeERC20 for IERC20;

    /// @notice Initializes the `AMO` contract
    /// @param amoMinter_ Address of the AMOMinter
    function _initialize(address amoMinter_) internal initializer {
        if (amoMinter_ == address(0)) revert ZeroAddress();
        amoMinter = IAMOMinter(amoMinter_);
    }

    // =============================== Modifiers ===================================

    /// @notice Checks whether the `msg.sender` is governor
    modifier onlyGovernor() {
        if (!amoMinter.isGovernor(msg.sender)) revert NotGovernor();
        _;
    }

    /// @notice Checks whether the `msg.sender` is approved for this AMO
    modifier onlyApproved() {
        if (!amoMinter.isApproved(msg.sender)) revert NotApproved();
        _;
    }

    /// @notice Checks whether the `msg.sender` is the `AMOMinter` contract
    modifier onlyAMOMinter() {
        if (msg.sender != address(amoMinter)) revert NotAMOMinter();
        _;
    }

    // ========================= View Functions ====================================

    /// @inheritdoc IAMO
    function balance(IERC20 token) external view returns (uint256) {
        uint256 tokenIdleBalance = token.balanceOf(address(this));
        uint256 netAssets = _getNavOfInvestedAssets(token);
        return tokenIdleBalance + netAssets;
    }

    /// @inheritdoc IAMO
    function debt(IERC20 token) external view returns (uint256) {
        return amoMinter.callerDebt(token);
    }

    /// @inheritdoc IAMO
    function getNavOfInvestedAssets(IERC20 token) external view returns (uint256) {
        return _getNavOfInvestedAssets(token);
    }

    // ====================== Restricted Governance Functions ======================

    /// @inheritdoc IAMO
    function pushSurplus(
        IERC20 token,
        address to,
        bytes[] memory data
    ) external onlyApproved {
        if (to == address(0)) revert ZeroAddress();
        uint256 amountToRecover = protocolGains[token];

        IERC20[] memory tokens = new IERC20[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = token;
        amounts[0] = amountToRecover;
        uint256 amountAvailable = _pull(tokens, amounts, data)[0];

        amountToRecover = amountToRecover <= amountAvailable ? amountToRecover : amountAvailable;
        protocolGains[token] -= amountToRecover;
        token.transfer(to, amountToRecover);
    }

    /// @inheritdoc IAMO
    function claimRewards(IERC20[] memory tokens) external onlyApproved {
        _claimRewards(tokens);
    }

    /// @inheritdoc IAMO
    function sellRewards(uint256 minAmountOut, bytes memory payload) external onlyApproved {
        //solhint-disable-next-line
        (bool success, bytes memory result) = _oneInch.call(payload);
        if (!success) _revertBytes(result);

        uint256 amountOut = abi.decode(result, (uint256));
        if (amountOut < minAmountOut) revert TooSmallAmountOut();
    }

    /// @inheritdoc IAMO
    function changeAllowance(
        IERC20[] calldata tokens,
        address[] calldata spenders,
        uint256[] calldata amounts
    ) external onlyApproved {
        if (tokens.length != spenders.length || tokens.length != amounts.length || tokens.length == 0)
            revert IncompatibleLengths();
        for (uint256 i = 0; i < tokens.length; i++) {
            _changeAllowance(tokens[i], spenders[i], amounts[i]);
        }
    }

    /// @inheritdoc IAMO
    /// @dev This function is `onlyApproved` rather than `onlyGovernor` because rewards selling already
    /// happens through an `onlyApproved` function
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external onlyApproved {
        IERC20(tokenAddress).safeTransfer(to, amountToRecover);
        emit Recovered(tokenAddress, to, amountToRecover);
    }

    /// @notice Generic function to execute arbitrary calls with the contract
    function execute(address _to, bytes calldata _data) external onlyGovernor returns (bool, bytes memory) {
        //solhint-disable-next-line
        (bool success, bytes memory result) = _to.call(_data);
        return (success, result);
    }

    // ========================== Only AMOMinter Functions =========================

    /// @inheritdoc IAMO
    function pull(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes[] memory data
    ) external onlyAMOMinter returns (uint256[] memory) {
        return _pull(tokens, amounts, data);
    }

    /// @inheritdoc IAMO
    function push(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes[] memory data
    ) external onlyAMOMinter {
        _push(tokens, amounts, data);
    }

    /// @inheritdoc IAMO
    function setAMOMinter(address amoMinter_) external onlyAMOMinter {
        amoMinter = IAMOMinter(amoMinter_);
    }

    /// @inheritdoc IAMO
    function setToken(IERC20 token) external onlyAMOMinter {
        _setToken(token);
    }

    /// @inheritdoc IAMO
    function removeToken(IERC20 token) external onlyAMOMinter {
        _removeToken(token);
    }

    // ========================== Internal Actions =================================

    /// @notice Internal version of the `pull` function
    function _pull(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes[] memory data
    ) internal virtual returns (uint256[] memory) {}

    /// @notice Internal version of the `push` function
    function _push(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes[] memory data
    ) internal virtual {}

    /// @notice Internal version of the `setToken` function
    function _setToken(IERC20 token) internal virtual {}

    /// @notice Internal version of the `removeToken` function
    function _removeToken(IERC20 token) internal virtual {}

    /// @notice Internal version of the `claimRewards` function
    function _claimRewards(IERC20[] memory tokens) internal virtual returns (uint256) {}

    /// @notice Internal version of the `getNavOfInvestedAssets` function to be overriden by each specific AMO implementation
    function _getNavOfInvestedAssets(IERC20 token) internal view virtual returns (uint256 amountInvested) {}

    /// @notice Checks if any gain/loss has been made since last call
    /// @param token Address of the token to report
    /// @param amountAdded Amount of new tokens added to the AMO
    /// @return netAssets Difference between assets and liabilities for the token in this AMO
    /// @return idleTokens Immediately available tokens in the AMO
    function _report(IERC20 token, uint256 amountAdded)
        internal
        virtual
        returns (uint256 netAssets, uint256 idleTokens)
    {
        // Assumed to be positive
        netAssets = _getNavOfInvestedAssets(token);
        idleTokens = token.balanceOf(address(this));

        // Always positive otherwise we couldn't do the operation, and idleTokens >= amountAdded
        uint256 total = idleTokens + netAssets - amountAdded;
        uint256 lastBalance_ = lastBalances[token];

        if (total > lastBalance_) {
            // In case of a yield gain, if there is already a loss, the gain is used to compensate the previous loss
            uint256 gain = total - lastBalance_;
            uint256 protocolDebtPre = protocolDebts[token];
            if (protocolDebtPre <= gain) {
                protocolGains[token] += gain - protocolDebtPre;
                protocolDebts[token] = 0;
            } else protocolDebts[token] -= gain;
        } else if (total < lastBalance_) {
            // In case of a loss, we first try to compensate it from previous gains for the part that concerns
            // the protocol
            uint256 loss = lastBalance_ - total;
            uint256 protocolGainBeforeLoss = protocolGains[token];
            // If the loss can not be entirely soaked by the gains already made then
            // the protocol keeps track of the debt
            if (loss > protocolGainBeforeLoss) {
                protocolDebts[token] += loss - protocolGainBeforeLoss;
                protocolGains[token] = 0;
            } else protocolGains[token] -= loss;
        }
    }

    /// @notice Changes allowance of this contract for a given token
    /// @param token Address of the token for which allowance should be changed
    /// @param spender Address to approve
    /// @param amount Amount to approve
    function _changeAllowance(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance < amount) {
            token.safeIncreaseAllowance(spender, amount - currentAllowance);
        } else if (currentAllowance > amount) {
            token.safeDecreaseAllowance(spender, currentAllowance - amount);
        }
    }

    /// @notice Gives a `max(uint256)` approval to `spender` for `token`
    /// @param token Address of token to approve
    /// @param spender Address of spender to approve
    function _approveMaxSpend(address token, address spender) internal {
        IERC20(token).safeApprove(spender, type(uint256).max);
    }

    /// @notice Processes 1Inch revert messages
    function _revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            //solhint-disable-next-line
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }
        revert OneInchSwapFailed();
    }
}
//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/RootChainManager.sol";
import "./interfaces/DepositManager.sol";
import "./interfaces/IGasSwapper.sol";

contract GasSwapper is IGasSwapper {
    using SafeERC20 for IERC20;

    address public constant EXCHANGE_PROXY = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    // native eth address for 0x
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IERC20 public constant MATIC = IERC20(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);
    RootChainManager public constant ROOT_CHAIN_MANAGER = RootChainManager(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
    DepositManager public constant DEPOSIT_MANAGER = DepositManager(0x401F6c983eA34274ec46f84D70b31C151321188b);
    address public constant PREDICATE = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;

    constructor() {}

    // Payable fallback to allow this contract to receive 0x protocol fee refunds or positive slippage
    receive() external payable {}

    /**
     * @inheritdoc IGasSwapper
     */
    function swapAndBridge(address token, uint256 amount, address user, bytes memory swapCallData) external payable {
        // slither-disable-start reentrancy-events
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory res) = EXCHANGE_PROXY.call{value: msg.value}(swapCallData);
        // 0x will revert with custom error on slippage and other errors
        if (!success) revert SwapFailed(res);
        uint256 maticAmount = abi.decode(res, (uint256));
        if (IERC20(MATIC).balanceOf(address(this)) < maticAmount) revert SwapFailed("InsufficientOutputAmount");
        // Bridge token via POS bridge
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).safeApprove(PREDICATE, amount);
        ROOT_CHAIN_MANAGER.depositFor(user, token, abi.encode(amount));
        // Bridge MATIC via Plasma bridge
        MATIC.safeApprove(address(DEPOSIT_MANAGER), maticAmount);
        DEPOSIT_MANAGER.depositERC20ForUser(address(MATIC), user, maticAmount);

        // Return rest ETH to user in case of positive slippage
        uint256 refund = address(this).balance;
        if (refund > 0) {
            // slither-disable-next-line arbitrary-send-eth
            (success, ) = msg.sender.call{value: refund}(""); // solhint-disable-line avoid-low-level-calls
            if (!success) revert RefundFailed();
        }

        emit Swap(token, user, amount, maticAmount);
    }
}
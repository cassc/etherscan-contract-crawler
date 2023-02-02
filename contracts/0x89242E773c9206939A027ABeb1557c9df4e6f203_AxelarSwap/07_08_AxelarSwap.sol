// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UniversalERC20.sol";

contract AxelarSwap is Ownable {
    using UniversalERC20 for IERC20;

    event SwapInitialized(
        address indexed sender,
        address indexed depositAddr,
        SwapInfo swapInfo
    );
    event ParaswapProxySet(address paraswapProxy);
    event AugustusSwapperSet(address augustusSwapper);

    struct DepositArgsAxelar {
        address srcToken;
        uint256 amount;
        address bridgeToken;
        address depositAddr; // Axelar deposit address
        bytes32 destChain;
        string destToken;
        string recipient;
        bytes srcParaswapData;
        bytes dstSwapData;
    }

    struct SwapInfo {
        address srcToken;
        uint256 amount;
        address bridgeToken;
        uint256 bridgeAmount;
        bytes32 destChain;
        string destToken;
        string recipient;
        bytes dstSwapData;
    }

    address private paraswapProxy;
    address private augustusSwapper;

    mapping(address => SwapInfo) public swapInfos;

    constructor(address _paraswapProxy, address _augustusSwapper) {
        paraswapProxy = _paraswapProxy;
        augustusSwapper = _augustusSwapper;
    }

    function setParaswapProxy(address _paraswapProxy) external onlyOwner {
        paraswapProxy = _paraswapProxy;
        emit ParaswapProxySet(_paraswapProxy);
    }

    function setAugustusSwapper(address _augustusSwapper) external onlyOwner {
        augustusSwapper = _augustusSwapper;
        emit AugustusSwapperSet(_augustusSwapper);
    }

    function deposit(DepositArgsAxelar calldata depositArgs) external payable {
        IERC20(depositArgs.srcToken).universalTransferFrom(
            msg.sender,
            address(this),
            depositArgs.amount
        );

        uint256 amount = depositArgs.amount;
        if (depositArgs.srcToken != depositArgs.bridgeToken) {
            // Swap to bridge token using paraswap
            amount = _swapInternalWithParaSwap(
                IERC20(depositArgs.srcToken),
                IERC20(depositArgs.bridgeToken),
                amount,
                depositArgs.srcParaswapData
            );
        }

        address depositAddr = depositArgs.depositAddr;

        IERC20(depositArgs.bridgeToken).universalTransfer(depositAddr, amount);

        // TODO: set minimum amount for bridge fee
        require(amount != 0, "invalid amount");
        require(swapInfos[depositAddr].bridgeAmount == 0, "duplicated");

        SwapInfo memory newInfo = SwapInfo({
            srcToken: depositArgs.srcToken,
            amount: depositArgs.amount,
            bridgeToken: depositArgs.bridgeToken,
            bridgeAmount: amount,
            destChain: depositArgs.destChain,
            destToken: depositArgs.destToken,
            recipient: depositArgs.recipient,
            dstSwapData: depositArgs.dstSwapData
        });
        swapInfos[depositAddr] = newInfo;

        emit SwapInitialized(msg.sender, depositAddr, newInfo);
    }

    function _callParaswap(
        IERC20 token,
        uint256 amount,
        bytes memory callData
    ) internal {
        uint256 ethAmountToTransfert = 0;
        if (token.isETH()) {
            require(
                address(this).balance >= amount,
                "ETH balance is insufficient"
            );
            ethAmountToTransfert = amount;
        } else {
            token.universalApprove(paraswapProxy, amount);
        }

        (bool success, ) = augustusSwapper.call{value: ethAmountToTransfert}(
            callData
        );
        require(success, "Paraswap execution failed");
    }

    function _swapInternalWithParaSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        bytes memory callData
    ) internal returns (uint256 totalAmount) {
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }

        _callParaswap(fromToken, amount, callData);
        totalAmount = destToken.universalBalanceOf(address(this));
    }

    function recoverFunds(address token) external onlyOwner {
        uint bal = IERC20(token).balanceOf(address(this));
        require(bal != 0);
        IERC20(token).universalTransfer(msg.sender, bal);
    }
}
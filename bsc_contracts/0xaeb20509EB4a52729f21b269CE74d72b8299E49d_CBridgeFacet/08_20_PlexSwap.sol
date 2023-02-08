// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/Structs.sol";
import "../libraries/AssetLib.sol";
import "../libraries/SafeERC20.sol";
import "./Signers.sol";
import "./VerifySigEIP712.sol";

contract PlexSwap is Ownable, Signers, VerifySigEIP712 {
    using SafeERC20 for IERC20;

    address public ROUTER;
    address public dev;

    mapping(bytes32 => BridgeInfo) public transferInfo;
    mapping(bytes32 => bool) public transfers;

    IERC20 private constant NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint256 feePercent = 5;

    event Swap(address user, address srcToken, address toToken, uint256 amount, uint256 returnAmount);
    event Bridge(address user, uint64 chainId, address dstToken, uint256 amount, uint64 nonce, bytes32 transferId, string bridge);
    event Relayswap(address receiver, address toToken, uint256 returnAmount);

    function setDev() public {
        dev = msg.sender;
    }

    function setRouter(address _router) public {
        ROUTER = _router;
    }

    function swapRouter(SwapData calldata _swap) external payable {
        _isNativeDeposit(IERC20(_swap.srcToken), _swap.amount);
        _swapStart(_swap);
    }

    function relaySwapRouter(SwapData calldata _swap, Input calldata _sigCollect, bytes[] memory signature) external onlyOwner {
        SwapData calldata swap = _swap;
        Input calldata sig = _sigCollect;
        require(sig.userAddress == swap.user && sig.amount - sig.gasFee == swap.amount && sig.toTokenAddress == swap.dstToken);
        relaySig(sig, signature);
        require(transfers[sig.txHash] == false, "safeTransfer exists");
        transfers[sig.txHash] = true;
        bool isNotNative = !_isNative(IERC20(sig.fromTokenAddress));
        uint256 fromAmount = sig.amount - sig.gasFee;
        if (isNotNative) {
            IERC20(sig.fromTokenAddress).safeApprove(ROUTER, fromAmount);
            if (sig.gasFee > 0) IERC20(sig.fromTokenAddress).safeTransfer(owner(), sig.gasFee);
        } else {
            if (sig.gasFee > 0) _safeNativeTransfer(owner(), sig.gasFee);
        }
        uint256 dstAmount = _userSwapStart(swap);
        emit Relayswap(sig.userAddress, sig.toTokenAddress, dstAmount);
    }

    function _isNativeDeposit(IERC20 _token, uint256 _amount) internal returns (bool isNotNative) {
        isNotNative = !_isNative(_token);

        if (isNotNative) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            IERC20(_token).safeApprove(ROUTER, _amount);
        }
    }

    function _isNative(IERC20 token_) internal pure returns (bool) {
        return (token_ == NATIVE_ADDRESS);
    }

    function _swapStart(SwapData calldata swapData) internal returns (uint256 dstAmount) {
        SwapData calldata swap = swapData;
        bool isNative = _isNative(IERC20(swap.srcToken));
        uint256 initDstTokenBalance = AssetLib.getBalance(swap.dstToken);
        (bool succ, ) = address(ROUTER).call{value: isNative ? swap.amount : 0}(swap.callData);
        if (succ) {
            uint256 dstTokenBalance = AssetLib.getBalance(swap.dstToken);
            dstAmount = dstTokenBalance > initDstTokenBalance ? dstTokenBalance - initDstTokenBalance : dstTokenBalance;
            emit Swap(swap.user, swap.srcToken, swap.dstToken, swap.amount, dstAmount);
        } else {
            revert();
        }
    }

    function _userSwapStart(SwapData calldata swapData) internal returns (uint256 dstAmount) {
        SwapData calldata swap = swapData;

        bool isNative = _isNative(IERC20(swap.srcToken));

        uint256 initDstTokenBalance = AssetLib.userBalance(swap.user, swap.dstToken);

        (bool succ, ) = address(ROUTER).call{value: isNative ? swap.amount : 0}(swap.callData);
        if (succ) {
            uint256 dstTokenBalance = AssetLib.userBalance(swap.user, swap.dstToken);
            dstAmount = dstTokenBalance > initDstTokenBalance ? dstTokenBalance - initDstTokenBalance : dstTokenBalance;

            emit Swap(swap.user, swap.srcToken, swap.dstToken, swap.amount, dstAmount);
        } else {
            revert();
        }
    }

    function _fee(address dstToken, uint256 dstAmount) internal returns (uint256 returnAmount) {
        uint256 fee = (dstAmount * feePercent) / 10000;
        returnAmount = dstAmount - fee;
        if (fee > 0) {
            if (!_isNative(IERC20(dstToken))) {
                IERC20(dstToken).safeTransfer(owner(), fee);
            } else {
                _safeNativeTransfer(owner(), fee);
            }
        }
    }

    function setFeePercent(uint256 percent) external {
        require(msg.sender == dev || msg.sender == owner());
        feePercent = percent;
    }

    function _safeNativeTransfer(address to_, uint256 amount_) internal {
        (bool sent, ) = to_.call{value: amount_}("");
        require(sent, "Safe safeTransfer fail");
    }

    function bytesEncode(SwapData calldata swap) external pure returns (bytes memory) {
        return abi.encode(swap);
    }
}
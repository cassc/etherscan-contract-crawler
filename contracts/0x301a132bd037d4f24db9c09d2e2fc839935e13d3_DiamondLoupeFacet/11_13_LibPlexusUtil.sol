// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SwapFailed} from "../Errors/GenericErrors.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/Structs.sol";
import "./LibDiamond.sol";
import "./LibData.sol";
import "hardhat/console.sol";

library LibPlexusUtil {
    using SafeERC20 for IERC20;
    IERC20 private constant NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    bytes32 internal constant NAMESPACE = keccak256("com.plexus.facets.swap");

    function getSwapStorage() internal pure returns (Dex storage s) {
        bytes32 namespace = NAMESPACE;
        assembly {
            s.slot := namespace
        }
    }

    function dexCheck(address dex) internal view returns (bool result) {
        Dex storage s = LibPlexusUtil.getSwapStorage();
        return s.allowedDex[dex];
    }

    function dexProxyCheck(address dex) internal view returns (address proxy) {
        Dex storage s = LibPlexusUtil.getSwapStorage();
        return s.proxy[dex];
    }

    /// @notice Determines whether the given address is the zero address
    /// @param addr The address to verify
    /// @return Boolean indicating if the address is the zero address
    function isZeroAddress(address addr) internal pure returns (bool) {
        return addr == address(0);
    }

    function getBalance(address token) internal view returns (uint256) {
        return token == address(NATIVE_ADDRESS) ? address(this).balance : IERC20(token).balanceOf(address(this));
    }

    function userBalance(address user, address token) internal view returns (uint256) {
        return token == address(NATIVE_ADDRESS) ? user.balance : IERC20(token).balanceOf(user);
    }

    function _isNative(address _token) internal pure returns (bool) {
        return (IERC20(_token) == NATIVE_ADDRESS);
    }

    function _isTokenDeposit(address _token, uint256 _amount) internal returns (bool isNotNative) {
        isNotNative = !_isNative(_token);

        if (isNotNative) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    function _isSwapTokenDeposit(InputToken[] calldata input) internal {
        for (uint i; i < input.length; i++) {
            bool isNotNative = !_isNative(input[i].srcToken);
            if (isNotNative) {
                IERC20(input[i].srcToken).safeTransferFrom(msg.sender, address(this), input[i].amount);
            }
        }
    }

    function _isTokenApprove(SwapData calldata swap) internal returns (uint256) {
        Dex storage s = getSwapStorage();
        require(s.allowedDex[swap.router]);
        InputToken[] calldata input = swap.input;
        uint256 nativeAmount = 0;
        for (uint i; i < input.length; i++) {
            bool isNotNative = !_isNative(input[i].srcToken);
            if (isNotNative) {
                if (s.proxy[swap.router] != address(0)) {
                    IERC20(input[i].srcToken).safeApprove(s.proxy[swap.router], 0);
                    IERC20(input[i].srcToken).safeApprove(s.proxy[swap.router], input[i].amount);
                } else {
                    IERC20(input[i].srcToken).safeApprove(swap.router, 0);
                    IERC20(input[i].srcToken).safeApprove(swap.router, input[i].amount);
                }
            } else {
                nativeAmount = input[i].amount;
            }
        }
        return nativeAmount;
    }

    function _tokenDepositAndSwap(SwapData calldata swap) internal returns (uint256[] memory) {
        _isSwapTokenDeposit(swap.input);
        uint256[] memory dstAmount = new uint256[](swap.output.length);
        dstAmount = _swapStart(swap);
        return dstAmount;
    }

    function _swapStart(SwapData calldata swap) internal returns (uint256[] memory) {
        uint256 nativeAmount = _isTokenApprove(swap);
        uint256 length = swap.output.length;
        uint256[] memory initDstTokenBalance = new uint256[](length);
        uint256[] memory dstTokenBalance = new uint256[](length);
        for (uint i; i < length; i++) {
            initDstTokenBalance[i] = getBalance(swap.output[i].dstToken);
        }
        (bool succ, ) = swap.router.call{value: nativeAmount}(swap.callData);
        if (succ) {
            for (uint i; i < length; i++) {
                dstTokenBalance[i] = getBalance(swap.output[i].dstToken) - initDstTokenBalance[i];
            }
            return dstTokenBalance;
        } else {
            revert("swap failed");
        }
    }

    function _bridgeSwapStart(SwapData calldata swap) internal returns (uint256) {
        uint256 nativeAmount = _isTokenApprove(swap);
        require(swap.output.length == 1);
        uint256 initDstTokenBalance = getBalance(swap.output[0].dstToken);
        (bool succ, ) = swap.router.call{value: nativeAmount}(swap.callData);
        if (succ) {
            uint256 dstTokenBalance = getBalance(swap.output[0].dstToken) - initDstTokenBalance;
            return dstTokenBalance;
        } else {
            revert("swap failed");
        }
    }

    function _safeNativeTransfer(address to_, uint256 amount_) internal {
        (bool sent, ) = to_.call{value: amount_}("");
        require(sent, "Safe safeTransfer fail");
    }

    function _fee(address dstToken, uint256 dstAmount) internal returns (uint256 returnAmount) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 getFee = (dstAmount * ds.fee) / 10000;
        returnAmount = dstAmount - getFee;

        if (getFee > 0) {
            if (!_isNative(dstToken)) {
                IERC20(dstToken).safeTransfer(ds.feeReceiver, getFee);
            } else {
                _safeNativeTransfer(ds.feeReceiver, getFee);
            }
        }
    }
}
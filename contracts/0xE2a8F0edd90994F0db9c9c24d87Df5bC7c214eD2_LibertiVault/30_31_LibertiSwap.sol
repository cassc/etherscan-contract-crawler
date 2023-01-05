//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ILibertiVault.sol";

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address srcReceiver; // from
    address dstReceiver; // to
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

abstract contract LibertiSwap {
    address private constant AGGREGATION_ROUTER_V4 = 0x1111111254fb6c44bAC0beD2854e76F90643097d;

    function swap(uint256 minOut, bytes calldata data) internal returns (bytes memory) {
        (, SwapDescription memory desc, ) = abi.decode(data[4:], (address, SwapDescription, bytes));
        require(desc.dstReceiver == address(this), "!badrecv");
        ILibertiVault vault = ILibertiVault(address(this));
        require(
            (address(desc.dstToken) == vault.asset() || address(desc.dstToken) == vault.other()),
            "!badtokn"
        );
        SafeERC20.safeIncreaseAllowance(IERC20(desc.srcToken), AGGREGATION_ROUTER_V4, desc.amount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = AGGREGATION_ROUTER_V4.call(data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(returndata, 32), mload(returndata))
            }
        }
        uint256 returnAmount;
        if (1 == block.chainid) {
            (returnAmount, , ) = abi.decode(returndata, (uint256, uint256, uint256));
        } else if ((56 == block.chainid) || (137 == block.chainid)) {
            (returnAmount, ) = abi.decode(returndata, (uint256, uint256));
        } else {
            assert(false);
        }
        require(returnAmount >= minOut, "!badrtrn");
        return returndata;
    }
}
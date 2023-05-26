// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library SafeERC20Burn {
    function safeBurn(IERC20 token, uint256 amount) internal {
        // bytes4(keccak256(bytes("burn(uint256)")));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x42966c68, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeBurn: burn failed");
    }

    function safeBurnFrom(
        IERC20 token,
        address from,
        uint256 amount
    ) internal {
        // bytes4(keccak256(bytes("burnFrom(address,uint256)")));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x79cc6790, from, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeBurnFrom: burn failed");
    }
}
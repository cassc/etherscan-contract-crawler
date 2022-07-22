// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library ExtendSafeERC20 {

    using Address for address;

    function safeMint(IERC20 tokenAddress, address receiver, uint256 amount) internal {
        bytes memory data = address(tokenAddress).functionCall(abi.encodeWithSignature("mint(address,uint256)", receiver, amount));
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "ExtendSafeERC20: Mint ops did not succeed");
        }
    }

    function safeBurn(IERC20 tokenAddress, uint256 amount) internal {
        bytes memory data = address(tokenAddress).functionCall(abi.encodeWithSignature("burn(uint256)", amount));
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "ExtendSafeERC20: Burn ops did not succeed");
        }
    }
}
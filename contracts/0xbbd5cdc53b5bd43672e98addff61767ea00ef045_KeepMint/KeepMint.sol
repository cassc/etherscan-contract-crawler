/**
 *Submitted for verification at Etherscan.io on 2023-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @notice ERC1155 minting function.
abstract contract ERC1155Mint {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public payable virtual;
}

/// @dev The ETH transfer has failed.
error ETHTransferFailed();

function safeTransferETH(address to, uint256 amount) {
    /// @solidity memory-safe-assembly
    assembly {
        // Transfer the ETH and check if it succeeded or not.
        if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
            // Store the function selector of `ETHTransferFailed()`.
            mstore(0x00, 0xb12d13eb)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }
    }
}

/// @notice 1:20-cv-10832-AT-SN maker facility.
/// @author KALI
contract KeepMint {
    ERC1155Mint internal constant Keep = ERC1155Mint(0xE198724c82B449946bE7e3347b481f67aCf45428);
    
    constructor() payable {}

    function join() public payable virtual {
        Keep.mint(msg.sender, 0, msg.value, "");
    }

    function skim() public payable virtual {
        safeTransferETH(address(Keep), address(this).balance);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public payable virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
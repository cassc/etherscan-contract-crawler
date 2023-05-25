/**
 *Submitted for verification at Etherscan.io on 2023-05-19
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

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

/// @notice NANI maker facility.
/// @author NANI
contract NaniMaker {
    ERC1155Mint internal constant NANI = ERC1155Mint(0x379569b497eE6fdEb6f6128B9f59EfB49B85e3A2);
    IERC721 internal constant MILADY = IERC721(0x5Af0D9827E0c53E4799BB226655A1de152A425a5);

    constructor() payable {}

    function join() public payable virtual {
        // 1 ETH = 10k NANI. Decimals via JSON.
        NANI.mint(msg.sender, 0, msg.value * 10_000, "");
        // Manifest mint.
        if (msg.value >= 0.01 ether) NANI.mint(msg.sender, 1, 1, "");
    }

    function secretHandshake() public payable virtual {
        if (MILADY.balanceOf(msg.sender) != 0) {
            // 1 ETH = 10k NANI. Decimals via JSON.
            NANI.mint(msg.sender, 0, msg.value * 10_000, "");
            // Manifest mint. Discounted. Doubled.
            if (msg.value >= 0.005 ether) NANI.mint(msg.sender, 1, 2, "");
        }
    }

    function skim() public payable virtual {
        safeTransferETH(address(NANI), address(this).balance);
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
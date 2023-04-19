/**
 *Submitted for verification at Etherscan.io on 2023-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Multicallable.sol)
abstract contract Multicallable {
    /// @dev Apply `DELEGATECALL` with the current contract to each calldata in `data`,
    /// and store the `abi.encode` formatted results of each `DELEGATECALL` into `results`.
    /// If any of the `DELEGATECALL`s reverts, the entire context is reverted,
    /// and the error is bubbled up.
    ///
    /// This function is deliberately made non-payable to guard against double-spending.
    /// (See: https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong)
    ///
    /// For efficiency, this function will directly return the results, terminating the context.
    /// If called internally, it must be called at the end of a function
    /// that returns `(bytes[] memory)`.
    function multicall(bytes[] calldata data) public virtual returns (bytes[] memory) {
        assembly {
            mstore(0x00, 0x20)
            mstore(0x20, data.length) // Store `data.length` into `results`.
            // Early return if no data.
            if iszero(data.length) { return(0x00, 0x40) }

            let results := 0x40
            // `shl` 5 is equivalent to multiplying by 0x20.
            let end := shl(5, data.length)
            // Copy the offsets from calldata into memory.
            calldatacopy(0x40, data.offset, end)
            // Offset into `results`.
            let resultsOffset := end
            // Pointer to the end of `results`.
            end := add(results, end)

            for {} 1 {} {
                // The offset of the current bytes in the calldata.
                let o := add(data.offset, mload(results))
                let memPtr := add(resultsOffset, 0x40)
                // Copy the current bytes from calldata to the memory.
                calldatacopy(
                    memPtr,
                    add(o, 0x20), // The offset of the current bytes' bytes.
                    calldataload(o) // The length of the current bytes.
                )
                if iszero(delegatecall(gas(), address(), memPtr, calldataload(o), 0x00, 0x00)) {
                    // Bubble up the revert if the delegatecall reverts.
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                // Append the current `resultsOffset` into `results`.
                mstore(results, resultsOffset)
                results := add(results, 0x20)
                // Append the `returndatasize()`, and the return data.
                mstore(memPtr, returndatasize())
                returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                // Advance the `resultsOffset` by `returndatasize() + 0x20`,
                // rounded up to the next multiple of 32.
                resultsOffset :=
                    and(add(add(resultsOffset, returndatasize()), 0x3f), 0xffffffffffffffe0)
                if iszero(lt(results, end)) { break }
            }
            return(0x00, add(resultsOffset, 0x40))
        }
    }
}

/// @notice ERC1155 interface to receive tokens.
/// @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC1155/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public payable virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public payable virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

/// @notice Contract helper for Keep token management.
abstract contract KeepTokenManager {
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256);

    function totalSupply(uint256 id) public view virtual returns (uint256);

    function transferable(uint256 id) public view virtual returns (bool);

    function getPriorVotes(
        address account,
        uint256 id,
        uint256 timestamp
    ) public view virtual returns (uint256);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public payable virtual;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public payable virtual;

    function setTransferability(uint256 id, bool on) public payable virtual;
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

/// @dev The `transferFrom` has failed.
error TransferFromFailed();

/// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
/// Reverts upon failure.
///
/// The `from` account must have at least `amount` approved for
/// the current contract to manage.
function safeTransferFrom(address token, address from, address to, uint256 amount) {
    /// @solidity memory-safe-assembly
    assembly {
        let m := mload(0x40) // Cache the free memory pointer.

        // Store the function selector of `transferFrom(address,address,uint256)`.
        mstore(0x00, 0x23b872dd)
        mstore(0x20, from) // Store the `from` argument.
        mstore(0x40, to) // Store the `to` argument.
        mstore(0x60, amount) // Store the `amount` argument.

        if iszero(
            and( // The arguments of `and` are evaluated from right to left.
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(eq(mload(0x00), 1), iszero(returndatasize())),
                call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
            )
        ) {
            // Store the function selector of `TransferFromFailed()`.
            mstore(0x00, 0x7939f424)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }

        mstore(0x60, 0) // Restore the zero slot to zero.
        mstore(0x40, m) // Restore the free memory pointer.
    }
}

/// @notice Contract helper for Bonkler Auction bids.
abstract contract BonklerAuctionBid {
    function createBid(uint256 bonklerId, uint256 generationHash) public payable virtual {}
}

/// @title Bonkler Pool
/// @notice Mints refundable DAO shares equal to ETH pooled. DAO can use ETH for Bonkler bids.
/// The user at all times can take their ETH back. If bid succeeds, their ETH will go to DAO.
/// With their shares, users will decide together how to use their Bonkler NFTs as DAO.
contract BonklerPool is Multicallable, ERC1155TokenReceiver {
    BonklerAuctionBid internal constant AUCTION = BonklerAuctionBid(0xF421391011Dc77c0C2489d384C26e915Efd9e2C5);

    address internal constant BNKLR = 0xABFaE8A54e6817F57F9De7796044E9a60e61ad67;

    address internal constant DAO = 0x70c0FB29FDEa65c274c574084123ff8DeE63d49f;

    error Unauthorized();

    constructor() payable {}

    function pool() public payable virtual {
        // Receive DAO shares for pooling ETH.
        KeepTokenManager(DAO).mint(msg.sender, 0, msg.value, "");
    }

    function bid(
        uint256 bonklerId, 
        uint256 generationHash, 
        uint256 value
    ) public payable virtual {
        // Only DAO can bid.
        if (msg.sender != DAO) revert Unauthorized();

        // Create bid at auction with pooled ETH `value`.
        AUCTION.createBid{value: value}(bonklerId, generationHash);
    }

    function refund(uint256 amount) public payable virtual {
        // Redeem and burn shares.
        KeepTokenManager(DAO).burn(msg.sender, 0, amount);

        // Send user back ETH.
        safeTransferETH(msg.sender, amount);
    }

    function claimBonkler(uint256 id) public payable virtual {
        // Send NFT (if won) to DAO.
        safeTransferFrom(BNKLR, address(this), DAO, id);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public payable virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {MerkleList} from "src/contracts/modules/utils/MerkleList.sol";
import {NativePrice} from "src/contracts/modules/utils/NativePrice.sol";
import {MinterTracker} from "src/contracts/modules/utils/MinterTracker.sol";
import {ERC165CheckerERC721Collective} from "src/contracts/ERC721Collective/ERC165CheckerERC721Collective.sol";
import {IERC721Collective} from "src/contracts/ERC721Collective/IERC721Collective.sol";
import {TokenRecoverable} from "src/contracts/common/TokenRecoverable.sol";

contract NativeTokenPriceMerkleMintModule is
    MerkleList,
    NativePrice,
    MinterTracker,
    ERC165CheckerERC721Collective,
    TokenRecoverable
{
    event CollectiveTokenMinted(
        address indexed collective,
        address indexed account,
        uint256 indexed amount
    );

    constructor(address admin) TokenRecoverable(admin) {}

    /// Enforce that a requested mint action is allowed given the token's parameters
    /// @param collective Address of token attempting to claim
    /// @param merkleProof List of hashes to traverse merkle tree to prove airdrop
    /// @param amount Number of collective tokens to mint
    function mint(
        address collective,
        bytes32[] calldata merkleProof,
        uint256 amount
    ) external payable onlyCollectiveInterface(collective) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        verifyProof(collective, merkleProof, leaf);

        collectNativePrice(collective, amount);
        checkMintMax(collective, amount);

        IERC721Collective(collective).bulkMintToOneAddress(msg.sender, amount);

        emit CollectiveTokenMinted(collective, msg.sender, amount);
    }

    /// This function is called for all messages sent to this contract (there
    /// are no other functions). Sending NativeToken to this contract will cause an
    /// exception, because the fallback function does not have the `payable`
    /// modifier.
    /// Source: https://docs.soliditylang.org/en/v0.8.9/contracts.html?highlight=fallback#fallback-function
    fallback() external {
        revert("NativePriceMerkleMintModule: non-existent function");
    }
}
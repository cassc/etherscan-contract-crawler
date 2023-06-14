// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @notice This non-standard token contract is the result of extracting only the most essential
 *         functionality from the ERC-721 and ERC-1155 interfaces. Based on Solmate implementations:
 *         https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol
 *         https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol
 * @dev    The usual events are NOT emitted since this contract is intended to be maximally gas-efficient
 *         and interacted with by contracts. This decision was made to reduce user gas costs across all
 *         contract-based NFT marketplaces that integrate (those contracts can emit events if desired)
 * @author kphed (based on transmissions11's work) - dedicated to Jude 🐾
 */
abstract contract PageToken {
    // Tracks the owner of each ERC721 derivative
    mapping(uint256 => address) public ownerOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function name() external view virtual returns (string memory);

    function symbol() external view virtual returns (string memory);

    function tokenURI(
        uint256 _tokenId
    ) external view virtual returns (string memory);

    function balanceOf(
        address owner,
        uint256 id
    ) external view returns (uint256) {
        return ownerOf[id] == owner ? 1 : 0;
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
    }

    function transfer(address to, uint256 id) external {
        require(msg.sender == ownerOf[id], "WRONG_FROM");
        require(to != address(0), "UNSAFE_RECIPIENT");

        // Set new owner as `to`
        ownerOf[id] = to;
    }

    function batchTransfer(address[] calldata to, uint256[] calldata ids) external {
        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 idsLength = ids.length;

        for (uint256 i = 0; i < idsLength; ) {
            id = ids[i];

            require(msg.sender == ownerOf[id], "WRONG_FROM");
            require(to[i] != address(0), "UNSAFE_RECIPIENT");

            // Set new owner as `to`
            ownerOf[id] = to[i];

            unchecked {
                ++i;
            }
        }
    }

    function transferFrom(address from, address to, uint256 id) external {
        require(from == ownerOf[id], "WRONG_FROM");
        require(to != address(0), "UNSAFE_RECIPIENT");
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Set new owner as `to`
        ownerOf[id] = to;
    }

    function batchTransferFrom(
        address from,
        address[] calldata to,
        uint256[] calldata ids
    ) external {
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 idsLength = ids.length;

        for (uint256 i = 0; i < idsLength; ) {
            id = ids[i];

            require(from == ownerOf[id], "WRONG_FROM");
            require(to[i] != address(0), "UNSAFE_RECIPIENT");

            ownerOf[id] = to[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) external view returns (uint256[] memory balances) {
        uint256 ownersLength = owners.length;
        balances = new uint256[](ownersLength);

        for (uint256 i = 0; i < ownersLength; ) {
            // Reverts with index OOB error if arrays are mismatched
            balances[i] = ownerOf[ids[i]] == owners[i] ? 1 : 0;

            unchecked {
                ++i;
            }
        }
    }
}
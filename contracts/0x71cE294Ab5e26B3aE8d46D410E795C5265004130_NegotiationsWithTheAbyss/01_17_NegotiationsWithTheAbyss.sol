// SPDX-License-Identifier: MIT

/// @title Negotiations With the Abyss by diewiththemostlikes
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import {ERC1155TLCore} from "ERC1155TLCore.sol";
import {BlockList} from "BlockList.sol";

contract NegotiationsWithTheAbyss is ERC1155TLCore, BlockList {

    constructor(address admin, address payout, address[] memory initBlockedOperators)
    ERC1155TLCore(admin, payout, "negotiations with the abyss")
    BlockList()
    {
        for (uint256 i = 0; i < initBlockedOperators.length; i++) {
            _setBlockListStatus(initBlockedOperators[i], true);
        }
    }

    /// @notice function to set the merkle root for a token
    /// @dev requires admin or owner
    function setMerkleRoot(uint256 tokenId, bytes32 newRoot) external adminOrOwner {
        require(_tokenDetails[tokenId].created, "ERC1155TLCore: Token ID not valid");
        _tokenDetails[tokenId].merkleRoot = newRoot;
    }

    /// @notice add blocklist modifier to approval
    function setApprovalForAll(address operator, bool approved) public virtual override notBlocked(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @notice burn function
    /// @dev requires owner of the tokens or approved operator
    function burn(address from, uint256[] calldata tokenIds, uint256[] calldata amounts) external {
        require(tokenIds.length > 0, "cannot burn 0 tokens");
        require(msg.sender == from || isApprovedForAll(from, msg.sender), "unauthorized");
        _burnBatch(from, tokenIds, amounts);
    }

    /// @notice blocklist function
    /// @dev requires owner
    function setBlockListStatus(address operator, bool status) external onlyOwner {
        _setBlockListStatus(operator, status);
    }
}
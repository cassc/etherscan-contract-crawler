// SPDX-License-Identifier: MIT

/// @title Negotiations With the Abyss by diewiththemostlikes
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import {ERC1155TLCore} from "ERC1155TLCore.sol";
import {BlockList} from "BlockList.sol";

contract CountyFairShiddyPrizes is ERC1155TLCore, BlockList {

    address public externalMinter;

    constructor(address admin, address payout, address[] memory initBlockedOperators)
    ERC1155TLCore(admin, payout, "county fair shiddy prizes")
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

    /// @notice function to set external minter
    /// @dev requires owner or admin
    function setExternalMinter(address minter) external adminOrOwner {
        externalMinter = minter;
    }

    /// @notice function to external mint from county fair flea market
    /// @dev requires approved external minter
    function externalMint(address recipient, uint256 tokenId) external {
        require(msg.sender == externalMinter, "Not approved minter");
        require(_tokenDetails[tokenId].created, "Token not created");
        _mint(recipient, tokenId, 1, "");
    }
}
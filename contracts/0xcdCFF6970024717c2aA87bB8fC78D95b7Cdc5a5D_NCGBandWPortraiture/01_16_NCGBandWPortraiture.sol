// SPDX-License-Identifier: MIT

/// @title NorCal Guy's Black and White Portraiture
/// @author transientlabs.xyz

pragma solidity 0.8.14;

import "ERC1155TLCore.sol";

contract NCGBandWPortraiture is ERC1155TLCore {

    address public externalMinter;

    constructor(address admin, address payout)
    ERC1155TLCore(admin, payout, "NorCal Guy's Black and White Portraiture")
    {}

    /// @notice funciton to set external minter address
    /// @dev requires admin or owner rights
    function setExternalMinter(address newExternalMinter) external adminOrOwner {
        externalMinter = newExternalMinter;
    }

    /// @notice function for the executor smart contract to mint tokens 1, 2, and 3 based on how many editions are burned
    /// @dev requires msg.sender to be the external minter address
    function mintExternal(address to, uint256 tokenId) external returns (bool) {
        require(msg.sender == externalMinter, "msg.sender is not the external minter");
        require(tokenId == 1 || tokenId == 2 || tokenId == 3, "invalid token id");
        require(_tokenDetails[tokenId].created, "token ID not valid");
        require(_tokenDetails[tokenId].mintStatus, "mint must be open");

        // bypass available supply as there will only be as many as the number of people burning sets
        // bypass numMinted requirement as people can burn multiple sets if they so choose
        _mint(to, tokenId, 1, "");

        return true;
    }

    /// @notice function to burn tokens
    /// @dev must be owner of tokens or approved for all
    function burn(address account, uint256[] memory tokenIds, uint256[] memory amounts) external nonReentrant {
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "caller is not owner nor approved");
        require(tokenIds.length == amounts.length, "invalid input");
        if (tokenIds.length == 1) {
            ERC1155._burn(account, tokenIds[0], amounts[0]);
        } else {
            ERC1155._burnBatch(account, tokenIds, amounts);
        }
    }

}
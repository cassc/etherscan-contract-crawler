// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libs/Admins.sol";
import "../libs/ERC721.sol";

/**
    @dev based on Moonbirds ERC721A Nested Contract
*/
abstract contract Stocking is ERC721, Admins {

    /**
    @dev Emitted when a Sneaker Heads begins stocking.
     */
    event Stocked(uint256 indexed tokenId);

    /**
    @dev Emitted when a Sneaker Heads stops stocking; either through standard means or
    by expulsion.
     */
    event UnStocked(uint256 indexed tokenId);

    /**
    @dev Emitted when a Sneaker Heads is expelled from the stock.
     */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether stocking is currently allowed.
    @dev If false then stocking is blocked, but unstocking is always allowed.
     */
    bool public stockingOpen = false;

    /**
    @dev MUST only be modified by safeTransferWhileStocking(); if set to 2 then
    the _beforeTokenTransfer() block while stocking is disabled.
     */
    bool internal stockingTransfer;

    uint64 internal stockingStepFirst = 30 days;
    uint64 internal stockingStepNext = 60 days;
    /**
    @dev data for each token stoked
     */
    struct StockingToken {
        uint64 started;
        uint64 total;
        uint64 level;
    }

    /**
    @dev tokenId to stocking data.
     */
    mapping(uint256 => StockingToken) internal stocking;

    /**
    @notice Toggles the `stockingOpen` flag.
     */
    function setStockingOpen(bool open) external onlyOwnerOrAdmins {
        stockingOpen = open;
    }

    /**
    @notice Returns the length of time, in seconds, that the Sneaker has
    stocking.
    @dev stocking is tied to a specific Sneaker Heads, not to the owner, so it doesn't
    reset upon sale.
    @return stocked Whether the Sneaker Heads is currently stocking. MAY be true with
    zero current stocking if in the same block as stocking began.
    @return current Zero if not currently stocking, otherwise the length of time
    since the most recent stocking began.
    @return total Total period of time for which the Sneaker Heads has stocking across
    its life, including the current period.
    @return level the current level of the token
     */
    function stockingPeriod(uint256 tokenId) public view returns (bool stocked, uint64 current, uint64 total, uint64 level)
    {
        stocked = stocking[tokenId].started != 0;
        current = stockingCurrent(tokenId);
        level = stockingLevel(tokenId);
        total = current + stocking[tokenId].total;
    }

    function stockingCurrent(uint256 tokenId) public view returns(uint64){
        return stocking[tokenId].started != 0 ? uint64(block.timestamp) - stocking[tokenId].started : 0;
    }

    function stockingLevel(uint256 tokenId) public view returns(uint64){

        uint64 level = stocking[tokenId].level;

        if(level == 0 ){
            return
                stockingCurrent(tokenId) / stockingStepFirst >= 1 ?
                ((stockingCurrent(tokenId) - stockingStepFirst) / stockingStepNext) + 1 :
                0;
        }

        return level + (stockingCurrent(tokenId) / stockingStepNext);
    }

    function setStockingStep(uint64 _durationFirst, uint64 _durationNext) public onlyOwnerOrAdmins {
        stockingStepFirst = _durationFirst;
        stockingStepNext = _durationNext;
    }

    /**
    @notice Changes the Sneaker Heads lock status for a token
    @dev If the stocking is disable, the unlock is available
    */
    function toggleStocking(uint256 tokenId) internal {

        require(
            ownerOf(tokenId) == _msgSender() ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(ownerOf(tokenId), _msgSender()
            ), "Not approved or owner");

        if (stocking[tokenId].started == 0) {
            storeToken(tokenId);
        } else {
            destockToken(tokenId);
        }
    }

    /**
    @notice Lock the token
    */
    function storeToken(uint256 tokenId) internal {
        require(stockingOpen, "Stocking closed");
        stocking[tokenId].started = uint64(block.timestamp);
        emit Stocked(tokenId);
    }

    /**
    @notice Unlock the token
    */
    function destockToken(uint256 tokenId) internal {
        stocking[tokenId].level = stockingLevel(tokenId);
        stocking[tokenId].total += stockingCurrent(tokenId);
        stocking[tokenId].started = 0;
        emit UnStocked(tokenId);
    }

    /**
    @notice Changes the Sneaker Heads stocking status for many tokenIds
     */
    function toggleStocking(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            toggleStocking(tokenIds[i]);
        }
    }
    /**
    @notice Transfer a token between addresses while the Sneaker Heads is minting, thus not resetting the stocking period.
     */
    function safeTransferWhileStocking(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "Only owner");
        stockingTransfer = true;
        safeTransferFrom(from, to, tokenId);
        stockingTransfer = false;
    }


    /**
    @notice Only owner ability to expel a Sneaker Heads from the stock.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has stocked and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting sneaker to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because stocking would then be all-or-nothing for all of a particular owner's
    Sneaker Heads.
     */
    function expelFromStock(uint256 tokenId) external onlyOwnerOrAdmins {
        require(stocking[tokenId].started != 0, "Not stocked");
        destockToken(tokenId);
        emit Expelled(tokenId);
    }
}
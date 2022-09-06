// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IProxyTracking {
    /**
     * @dev Called by original contract on _afterTokenTransfer ERC721 event.
     *
     * WARNING: Good practice will be to check that msg.sender is original contract, for example: require(msg.sender == _originalContract, "Only original contract can call this");
     *
     */
    function afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
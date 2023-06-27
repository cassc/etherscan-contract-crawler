// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract TheDarkPortal {
    event Event(
        address collection,
        uint256 id,
        uint256 bindCode,
        string to,
        string name,
        string symbol,
        string uri
    );

    function transmigrate(
        IERC721Metadata collection,
        uint256 id,
        string calldata to,
        uint256 bindCode
    ) public {
        require(collection.ownerOf(id) == msg.sender);
        require(collection.getApproved(id) == address(this));
        collection.transferFrom(msg.sender, address(this), id);
        emit Event(
            address(collection),
            id,
            bindCode,
            to,
            collection.name(),
            collection.symbol(),
            collection.tokenURI(id)
        );
    }
}
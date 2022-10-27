// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "../utils/HasAuthorization.sol";
import "./ERC1155/extensions/ERC1155PreMintedCollection.sol";
import "./ERC2981/ERC2981.sol";


contract TradableCollection is ERC1155PreMintedCollection, ERC2981, HasAuthorization {

    event BaseUriUpdate(string uri);
    event RoyaltyInfoUpdate(address recipient, uint24 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint howManyTokens,
        uint supplyPerToken,
        string memory baseURI,
        address royaltiesRecipient,
        uint24 royaltiesBasispoints
    )
        ERC1155PreMintedCollection(name, symbol, howManyTokens, supplyPerToken, baseURI)
        ERC2981(royaltiesRecipient, royaltiesBasispoints) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155PreMintedCollection, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function transferRoyaltiesRecipient(address recipient) only(royalties.recipient) external {
        setRoyalties(recipient, royalties.amount);
        emit RoyaltyInfoUpdate(recipient, royalties.amount);
    }

    function reduceRoyalties(uint24 basispoints) only(royalties.recipient) external {
        require(basispoints < royalties.amount, "ERC2981: reduced royalty basispoints must be smaller");
        setRoyalties(royalties.recipient, basispoints);
        emit RoyaltyInfoUpdate(royalties.recipient, basispoints);
    }

    function updateBaseURI(string memory _baseURI) only(royalties.recipient) external {
        baseURI = _baseURI;
        emit BaseUriUpdate(_baseURI);
    }
}
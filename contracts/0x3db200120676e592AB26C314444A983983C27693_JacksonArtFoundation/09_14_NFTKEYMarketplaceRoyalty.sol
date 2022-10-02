// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./INFTKEYMarketplaceRoyalty.sol";

contract NFTKEYMarketplaceRoyalty is INFTKEYMarketplaceRoyalty, Ownable {
    uint256 public defaultRoyaltyFraction = 20; // By the factor of 1000, 2%
    uint256 public royaltyUpperLimit = 80; // By the factor of 1000, 8%

    mapping(address => ERC721CollectionRoyalty) private _collectionRoyalty;

    function _erc721Owner(address erc721Address)
        private
        view
        returns (address)
    {
        try Ownable(erc721Address).owner() returns (address _contractOwner) {
            return _contractOwner;
        } catch {
            return address(0);
        }
    }

    function royalty(address erc721Address)
        public
        view
        override
        returns (ERC721CollectionRoyalty memory)
    {
        if (_collectionRoyalty[erc721Address].setBy != address(0)) {
            return _collectionRoyalty[erc721Address];
        }

        address erc721Owner = _erc721Owner(erc721Address);
        if (erc721Owner != address(0)) {
            return
                ERC721CollectionRoyalty({
                    recipient: erc721Owner,
                    feeFraction: defaultRoyaltyFraction,
                    setBy: address(0)
                });
        }

        return
            ERC721CollectionRoyalty({
                recipient: address(0),
                feeFraction: 0,
                setBy: address(0)
            });
    }

    function setRoyalty(
        address erc721Address,
        address newRecipient,
        uint256 feeFraction
    ) external override {
        require(
            feeFraction <= royaltyUpperLimit,
            "Please set the royalty percentange below allowed range"
        );

        require(
            msg.sender == royalty(erc721Address).recipient,
            "Only ERC721 royalty recipient is allowed to set Royalty"
        );

        _collectionRoyalty[erc721Address] = ERC721CollectionRoyalty({
            recipient: newRecipient,
            feeFraction: feeFraction,
            setBy: msg.sender
        });

        emit SetRoyalty({
            erc721Address: erc721Address,
            recipient: newRecipient,
            feeFraction: feeFraction
        });
    }

    function setRoyaltyForCollection(
        address erc721Address,
        address newRecipient,
        uint256 feeFraction
    ) external onlyOwner {
        require(
            feeFraction <= royaltyUpperLimit,
            "Please set the royalty percentange below allowed range"
        );

        require(
            royalty(erc721Address).setBy == address(0),
            "Collection royalty recipient already set"
        );

        _collectionRoyalty[erc721Address] = ERC721CollectionRoyalty({
            recipient: newRecipient,
            feeFraction: feeFraction,
            setBy: msg.sender
        });

        emit SetRoyalty({
            erc721Address: erc721Address,
            recipient: newRecipient,
            feeFraction: feeFraction
        });
    }

    function updateRoyaltyUpperLimit(uint256 _newUpperLimit)
        external
        onlyOwner
    {
        royaltyUpperLimit = _newUpperLimit;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/IGetRoyalties.sol";
import "../interfaces/IRoyaltyInfo.sol";
import "../markets/CopyrightRegistry.sol";

import "./ERC721Creator.sol";
import "../Constants.sol";

/**
 * @title Holds a reference to the Chizu Market and communicates fees to marketplaces.
 */
abstract contract ERC721Royalty is
    IGetRoyalties,
    IRoyaltyInfo,
    CopyrightRegistry,
    ERC721Creator
{
    using AddressUpgradeable for address;

    /// @notice Copyright that do not provide royalty
    uint256 constant EXCLUSIVE = 20;

    /// @dev Token policy matching tokenId
    mapping(uint256 => uint256) tokenPolicy;

    /**
     * @notice Get fee recipients and fees in a single call.
     * @dev The data is the same as when calling getFeeRecipients and getFeeBps separately.
     * @param _tokenId The tokenId of the NFT to get the royalties for.
     * @param _salePrice the salesPrice of the NFT
     * @return recipients An array of addresses to which royalties should be sent.
     * @return fees The array of fees to be sent to each recipient address.
     */
    function getRoyalties(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address payable[] memory recipients, uint256[] memory fees)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: Query for nonexistent token"
        );
        recipients = new address payable[](1);
        recipients[0] = tokenCreator(_tokenId);

        fees = new uint256[](1);
        if (tokenPolicy[_tokenId] == 20) {
            fees[0] = 0;
        } else {
            fees[0] = (_salePrice * 5) / 100;
        }
    }

    /**
     * @notice Returns the creator and the amount to be sent for a secondary sale.
     * @param _tokenId The tokenId of the NFT to get the royalty recipient and amount for.
     * @param _salePrice The total price of the sale.
     * @return creator The royalty recipient address for this sale.
     * @return creatorAmount The total amount that should be sent to the `creator`.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address creator, uint256 creatorAmount)
    {
        creator = address(tokenCreator(_tokenId));

        if (tokenPolicy[_tokenId] == EXCLUSIVE) {
            creatorAmount = 0;
        } else {
            creatorAmount = (_salePrice * 5) / 100;
        }
    }

    function getPolicyOfToken(uint256 _tokenId) public view returns (uint256) {
        return tokenPolicy[_tokenId];
    }

    /**
     * @notice Internal function to register token policy
     */
    function _setTokenPolicy(uint256 _tokenId, uint256 policy) internal {
        tokenPolicy[_tokenId] = policy;
    }

    /**
     * @inheritdoc ERC165
     * @dev Checks the supported royalty interfaces.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (
            interfaceId == type(IRoyaltyInfo).interfaceId ||
            interfaceId == type(IGetRoyalties).interfaceId
        ) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IERC2981Royalties.sol";

abstract contract CollectionRoyalties is Initializable, IERC2981Royalties {
    uint256 public constant MAX_ROYALTIES = 10000;

    address public royaltiesRecipient;
    uint256 public royaltiesAmount;

    event RoyaltiesUpdated(address indexed recipient, uint256 indexed value);

    error RoyaltiesTooHigh();

    function __CollectionRoyalties_init(address recipient, uint256 royalties)
        internal
        onlyInitializing
    {
        if (royalties > MAX_ROYALTIES) revert RoyaltiesTooHigh();

        royaltiesRecipient = recipient;
        royaltiesAmount = royalties;
    }

    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltiesRecipient, (value * royaltiesAmount) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return interfaceId == type(IERC2981Royalties).interfaceId;
    }

    function _setRoyalties(address recipient, uint256 value) internal {
        if (value > MAX_ROYALTIES) revert RoyaltiesTooHigh();
        royaltiesRecipient = recipient;
        royaltiesAmount = value;

        emit RoyaltiesUpdated(recipient, value);
    }
}
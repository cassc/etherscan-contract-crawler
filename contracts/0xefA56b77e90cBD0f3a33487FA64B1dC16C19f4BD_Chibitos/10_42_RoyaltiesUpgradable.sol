//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "../admin-manager/AdminManagerUpgradable.sol";
import "./IERC2981Royalties.sol";

contract RoyaltiesUpgradable is
    Initializable,
    ERC165Upgradeable,
    IERC2981Royalties,
    AdminManagerUpgradable
{
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    RoyaltyInfo private _royalties;
    uint256 constant maxValue = 10000;

    event RoyaltiesSet(address recipient, uint256 amount);

    function __Royalties_init(address recipient_, uint256 amount_)
        internal
        onlyInitializing
    {
        __AdminManager_init_unchained();
        __Royalties_init_unchained(recipient_, amount_);
    }

    function __Royalties_init_unchained(address recipient_, uint256 amount_)
        internal
        onlyInitializing
    {
        _setRoyalties(recipient_, amount_);
    }

    function _setRoyalties(address recipient_, uint256 amount_) internal {
        require(amount_ <= maxValue, "Royalties: value is too high");
        _royalties = RoyaltyInfo(recipient_, uint24(amount_));
        emit RoyaltiesSet(recipient_, amount_);
    }

    function setRoyalties(address recipient_, uint256 amount_)
        external
        onlyAdmin
    {
        _setRoyalties(recipient_, amount_);
    }

    function royaltyInfo(uint256, uint256 value_)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value_ * royalties.amount) / maxValue;
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId_ == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    uint256[49] private __gap;
}
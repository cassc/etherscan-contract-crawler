// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "./interfaces/IBaseCollection.sol";
import "./interfaces/INiftyKit.sol";

abstract contract BaseCollection is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC2771ContextUpgradeable,
    OwnableUpgradeable,
    IBaseCollection
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    INiftyKit internal _niftyKit;
    address internal _treasury;
    uint256 internal _totalRevenue;

    function __BaseCollection_init(
        string memory name_,
        string memory symbol_,
        address treasury_,
        address trustedForwarder_
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __ERC2771Context_init_unchained(trustedForwarder_);
        __Ownable_init_unchained();

        _niftyKit = INiftyKit(_msgSender());
        _treasury = treasury_;
    }

    function withdraw() public {
        require(address(this).balance > 0, "0 balance");

        uint256 balance = address(this).balance;
        uint256 fees = _niftyKit.getFees(address(this));
        AddressUpgradeable.sendValue(payable(_treasury), balance.sub(fees));
        AddressUpgradeable.sendValue(payable(address(_niftyKit)), fees);

        _niftyKit.addFeesClaimed(fees);
    }

    function setTreasury(address newTreasury) public onlyOwner {
        _treasury = newTreasury;
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function totalRevenue() external view returns (uint256) {
        return _totalRevenue;
    }

    // The following functions are overrides required by Solidity.
    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function transferOwnership(address newOwner)
        public
        override(IBaseCollection, OwnableUpgradeable)
    {
        return OwnableUpgradeable.transferOwnership(newOwner);
    }
}
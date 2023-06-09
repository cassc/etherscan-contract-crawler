// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./interfaces/IBaseCollection.sol";
import "./interfaces/INiftyKit.sol";

abstract contract BaseCollection is
    OwnableUpgradeable,
    ERC2981Upgradeable,
    IBaseCollection
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    INiftyKit internal _niftyKit;
    address internal _treasury;
    uint256 internal _totalRevenue;

    function __BaseCollection_init(
        address treasury_,
        address royalty_,
        uint96 royaltyFee_
    ) internal onlyInitializing {
        __Ownable_init();
        __ERC2981_init();

        _niftyKit = INiftyKit(_msgSender());
        _treasury = treasury_;
        _setDefaultRoyalty(royalty_, royaltyFee_);
    }

    function withdraw() external {
        require(address(this).balance > 0, "0 balance");

        uint256 balance = address(this).balance;
        uint256 fees = _niftyKit.getFees(address(this));
        _niftyKit.addFeesClaimed(fees);
        AddressUpgradeable.sendValue(payable(address(_niftyKit)), fees);
        AddressUpgradeable.sendValue(payable(_treasury), balance.sub(fees));
    }

    function setTreasury(address newTreasury) external onlyOwner {
        _treasury = newTreasury;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function totalRevenue() external view returns (uint256) {
        return _totalRevenue;
    }

    // The following functions are overrides required by Solidity.
    function transferOwnership(address newOwner)
        public
        override(IBaseCollection, OwnableUpgradeable)
    {
        return OwnableUpgradeable.transferOwnership(newOwner);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IBaseCollection).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
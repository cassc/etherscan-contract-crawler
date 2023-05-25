// contracts/royalty/ERC2981.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./IERC2981.sol";

abstract contract ERC2981Upgradeable is IERC2981, ERC165Upgradeable {
    using SafeMathUpgradeable for uint256;

    // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    mapping(uint256 => address) royaltyReceivers;
    mapping(uint256 => uint256) royaltyPercentages;

    constructor() {}

    function __ERC2981__init() internal initializer {
        __ERC165_init();
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyReceivers[_tokenId];
        royaltyAmount = _salePrice.mul(royaltyPercentages[_tokenId]).div(100);
    }

    function _setRoyaltyReceiver(uint256 _tokenId, address _newReceiver)
        internal
    {
        royaltyReceivers[_tokenId] = _newReceiver;
    }

    function _setRoyaltyPercentage(uint256 _tokenId, uint256 _percentage)
        internal
    {
        royaltyPercentages[_tokenId] = _percentage;
    }
}
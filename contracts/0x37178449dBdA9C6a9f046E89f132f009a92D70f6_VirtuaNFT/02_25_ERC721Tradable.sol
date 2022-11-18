// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

import "./ContentMixin.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721Tradable is ContextMixin, ERC721PresetMinterPauserAutoId {
    using SafeMath for uint256;

    address public proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _baseURI,
        address royaltiesReceiver,
        uint96 royaltiesFeeNumerator,
        address eventContract
    ) ERC721PresetMinterPauserAutoId(_name, _symbol,_baseURI, royaltiesReceiver, royaltiesFeeNumerator, eventContract) {
        proxyRegistryAddress = _proxyRegistryAddress;
    }


    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(getBaseURI(), Strings.toString(_tokenId)));
    }


    function isApprovedForAll(address owner, address operator)
       override
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }else if (hasRole(SECONDARY_WHITELISTED_ROLE,_msgSender())){
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./MetaproMetaAsset.sol";

contract MetaproAirdrop is Ownable, ERC1155Holder {
    using SafeMath for uint;

    MetaproMetaAsset public token;

    event ClaimTransfer(uint tokenId, address target, uint amount);
    event WhitelistAddressAdd(uint tokenId, address target);
    event WhitelistAddressRemove(uint tokenId, address target);
    event TokenAddressUpdated(address _address);

    mapping(address => uint) public whitelists;

    mapping(uint => address[]) private claimed;
    
    constructor(address _tokenAddress) {
        token = MetaproMetaAsset(_tokenAddress);
    }

    function addAddresses(uint _tokenId, address[] memory _addresses) external onlyOwner {
        require(_tokenId > 0, "token id cannot be 0");

        for (uint i; i < _addresses.length; i++) {
            whitelists[_addresses[i]] = _tokenId;
            emit WhitelistAddressAdd(_tokenId, _addresses[i]);
        }
    }

    function addAddress(uint _tokenId, address _address) external onlyOwner {
        require(_tokenId > 0, "token id cannot be 0");
        whitelists[_address] = _tokenId;
        emit WhitelistAddressAdd(_tokenId, _address);
    }

    function removeAddress(address _address) external onlyOwner {
        delete whitelists[_address];
    }

    function whitelisted(address _address) public view returns (uint) {
        return whitelists[_address];
    }  

    function claim(bytes memory data) public {        
        address claimer = _msgSender();
        uint tokenId = whitelists[claimer];

        require(tokenId > 0, "token id cannot be 0");
        require(token.balanceOf(address(this), tokenId) > 0, "balance cannot be 0");

        token.safeTransferFrom(address(this), claimer, tokenId, 1, data);
        emit ClaimTransfer(tokenId, claimer, 1);
    }

    function setTokenAddress(address _newAddress) public onlyOwner {
        token = MetaproMetaAsset(_newAddress);
        emit TokenAddressUpdated(_newAddress);
    }
}
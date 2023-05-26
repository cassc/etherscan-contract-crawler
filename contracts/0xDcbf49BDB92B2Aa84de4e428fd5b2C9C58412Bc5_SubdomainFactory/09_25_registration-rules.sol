// SPDX-License-Identifier: MIT

import "./interfaces/IManager.sol";
import "./interfaces/IRegister.sol";


pragma solidity ^0.8.13;

contract RegistrationRulesV1 is IRegister {

    IManager public DomainManager;
    constructor(IManager _manager){
        DomainManager = _manager;
    }

    function canRegister(uint256 _tokenId, string calldata _label, address _addr, uint256 _priceInWei, bytes32[] calldata _proofs) external view returns(bool){
        uint256 price = DomainManager.DefaultMintPrice(_tokenId);
        require(price == _priceInWei, "incorrect ether");
        require(price != 0, "not for primary sale");
        return true;
    }

    function mintPrice(uint256 _tokenId, string calldata _label, address _addr, bytes32[] calldata _proofs) external view returns(uint256){
        uint256 price = DomainManager.DefaultMintPrice(_tokenId);
        address owner = DomainManager.TokenOwnerMap(_tokenId);
        return owner == _addr ? 0 : price;
    }
 
}
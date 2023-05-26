//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRegister {
    function canRegister(uint256 _tokenId, string memory _label, address _addr, uint256 _priceInWei, bytes32[] calldata _proofs) external view returns(bool);
    function mintPrice(uint256 _tokenId, string calldata _label, address _addr, bytes32[] calldata _proofs) external view returns(uint256);
    
}
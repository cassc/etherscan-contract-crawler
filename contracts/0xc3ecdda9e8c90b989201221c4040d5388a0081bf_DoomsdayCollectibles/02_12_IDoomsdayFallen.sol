//SPDX-License-Identifier: Salad

pragma solidity ^0.8.0;

interface IDoomsdayFallen {
    function getFallen(uint _tokenId) external view returns(uint16 _cityId, address _owner);

    function totalSupply() external view returns (uint256);
    function destroyed() external view returns (uint256);
}
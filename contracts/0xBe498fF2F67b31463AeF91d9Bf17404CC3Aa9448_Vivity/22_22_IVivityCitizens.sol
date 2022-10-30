// SPDX-License-Identifier: MIT
// Creator: lohko.io

pragma solidity >=0.8.13;

interface IVivityCitizens {

    function claimCitizenship(address _user, uint256 _tokenId) external;

    function claimCitizenshipBackup(address _user, uint256 _tokenId) external;
}
//SPDX-License-Identifier: Unlicense
pragma solidity 0.5.16;

interface INFT {
    function ownerOf(uint256) external view returns (address);
    function belongsTo(address) external view returns (uint256);
    function tier(uint256) external view returns(uint256);
    function getTransferLimit(uint256) external view returns(uint256);
}
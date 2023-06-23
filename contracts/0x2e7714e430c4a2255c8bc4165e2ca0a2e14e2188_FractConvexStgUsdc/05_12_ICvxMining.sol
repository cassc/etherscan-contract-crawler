// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICvxMining {
    function ConvertCrvToCvx(uint256 amount) external view returns(uint256);
}
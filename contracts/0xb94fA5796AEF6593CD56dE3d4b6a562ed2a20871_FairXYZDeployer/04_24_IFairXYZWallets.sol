// SPDX-License-Identifier: MIT

// @ Fair.xyz dev

pragma solidity 0.8.17;

interface IFairXYZWallets {
    function viewWithdraw() external view returns (address);

    function viewPathURI(string memory pathURI_) external view returns (string memory);
}
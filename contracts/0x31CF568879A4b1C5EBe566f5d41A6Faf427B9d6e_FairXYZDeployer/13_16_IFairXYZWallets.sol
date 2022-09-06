// SPDX-License-Identifier: MIT

// @ Fair.xyz dev

pragma solidity 0.8.7;

interface IFairXYZWallets {
    function viewSigner() view external returns(address);
    function viewWithdraw() view external returns(address);
    function viewPathURI(string memory pathURI_) view external returns(string memory);
}
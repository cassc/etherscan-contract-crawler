// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../vault/IVault.sol";
import "../token/IMintableOwnedERC20.sol";


struct ProjectParams {
    // used to circumvent 'Stack too deep' error when creating a _new project

    address projectVault;
    address projectToken;
    address paymentToken;

    string tokenName;
    string tokenSymbol;
    uint minPledgedSum;
    uint initialTokenSupply;

    bytes32 cid; // ref to metadata
}
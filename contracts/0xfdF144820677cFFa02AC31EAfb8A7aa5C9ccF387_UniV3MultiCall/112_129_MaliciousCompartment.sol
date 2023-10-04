// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MaliciousOwnerContract} from "./MaliciousOwnerContract.sol";
import {ILenderVaultImpl} from "../peer-to-peer/interfaces/ILenderVaultImpl.sol";

contract MaliciousCompartment {
    address internal immutable _tokenToBeWithdrawn;
    address internal immutable _maliciousOwnerContract;

    constructor(address tokenToBeWithdrawn, address maliciousOwnerContract) {
        _tokenToBeWithdrawn = tokenToBeWithdrawn;
        _maliciousOwnerContract = maliciousOwnerContract;
    }

    function initialize(address _vaultAddr, uint256 /*_loanIdx*/) external {
        MaliciousOwnerContract(_maliciousOwnerContract).callback(
            _vaultAddr,
            _tokenToBeWithdrawn
        );
    }

    function claimVaultOwnership(address lenderVault) external {
        Ownable2Step(lenderVault).acceptOwnership();
    }
}
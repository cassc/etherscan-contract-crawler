// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ILenderVaultImpl} from "../peer-to-peer/interfaces/ILenderVaultImpl.sol";

contract MaliciousOwnerContract {
    using SafeERC20 for IERC20Metadata;

    address internal _owner;

    constructor() {
        _owner = msg.sender;
    }

    function callback(address vaultAddr, address tokenToBeWithdrawn) external {
        uint256 withdrawAmount = ILenderVaultImpl(vaultAddr).lockedAmounts(
            tokenToBeWithdrawn
        );
        ILenderVaultImpl(vaultAddr).withdraw(
            tokenToBeWithdrawn,
            withdrawAmount
        );
    }

    function claimVaultOwnership(address lenderVault) external {
        Ownable2Step(lenderVault).acceptOwnership();
    }
}
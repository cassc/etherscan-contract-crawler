// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IIntegralMerkleTimeRelease {
    event OwnerSet(address owner);
    event Claim(address claimer, address receiver, uint256 option1Amount, uint256 option2Amount);
    event Skim(address to, uint256 amount);
    event Option1StopBlockSet(uint256 option1StopBlock);
    event Option2StopBlockSet(uint256 option2StopBlock);
}
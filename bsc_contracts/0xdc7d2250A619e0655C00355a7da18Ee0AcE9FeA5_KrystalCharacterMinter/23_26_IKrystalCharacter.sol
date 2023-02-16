// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

interface IKrystalCharacter {
    event SetVerifier(address verifier);
    event SetMinter(address minter);
    event SetCharacterContract(address _character);
}
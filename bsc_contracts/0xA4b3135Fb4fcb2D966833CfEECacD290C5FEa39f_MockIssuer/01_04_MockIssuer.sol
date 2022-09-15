pragma solidity ^0.5.16;

import "../Owned.sol";
import "./Unimplemented.sol";
import "../interfaces/ISynth.sol";

interface IMockIssuer {
    function synths(bytes32 currencyKey) external view returns (ISynth);
}

contract MockIssuer is Owned, Unimplemented, IMockIssuer {
    mapping(bytes32 => ISynth) public synths;

    constructor(address _owner) public Owned(_owner) {}

    function _addSynth(bytes32 currencyKey, ISynth synth) internal {
        require(synths[currencyKey] == ISynth(0), "Synth exists");
        synths[currencyKey] = synth;
        emit SynthAdded(currencyKey, address(synth));
    }

    function addSynths(bytes32[] calldata currencyKeysToAdd, ISynth[] calldata synthsToAdd) external onlyOwner {
        uint numSynths = currencyKeysToAdd.length;
        require(synthsToAdd.length == numSynths, "Input array lengths must match");
        for (uint i = 0; i < numSynths; i++) {
            _addSynth(currencyKeysToAdd[i], synthsToAdd[i]);
        }
    }

    event SynthAdded(bytes32 currencyKey, address synth);
}
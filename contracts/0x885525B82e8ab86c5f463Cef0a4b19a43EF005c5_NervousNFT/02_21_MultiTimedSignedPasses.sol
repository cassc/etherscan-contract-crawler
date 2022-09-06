// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./SignedPass.sol";

contract MultiTimedSignedPasses {
    using ECDSA for bytes32;

    struct TimedSigner {
        address signer;
        uint256 startTime;
    }

    TimedSigner[] internal _timedSigners;

    constructor(uint256 numSigners) {
        for (uint256 i = 0; i < numSigners; i++) {
            _timedSigners.push(TimedSigner(address(0), type(uint256).max));
        }
    }

    function _setTimedSigner(
        uint256 index,
        address signer,
        uint256 startTime
    ) internal {
        require(index < _timedSigners.length, "Out of bounds");
        _timedSigners[index].signer = signer;
        _timedSigners[index].startTime = startTime;
    }

    function _checkTimedSigners(
        string memory prefix,
        address addr,
        bytes memory signedMessage
    ) internal view returns (bool) {
        address signer = SignedPass.recoverSignerFromSignedPass(
            prefix,
            addr,
            signedMessage
        );
        if (signer == address(0)) {
            return false;
        }
        for (uint256 i = 0; i < _timedSigners.length; i++) {
            TimedSigner storage a = _timedSigners[i];
            if (a.signer == signer && block.timestamp >= a.startTime) {
                return true;
            }
        }
        return false;
    }
}
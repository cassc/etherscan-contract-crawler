// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MultiSig.sol";

contract ChainzokuMultiSig is MultiSig {
    constructor(address[] memory _multiSigAddress, uint256 _minSigner)
    MultiSig(_multiSigAddress, _minSigner){}
}
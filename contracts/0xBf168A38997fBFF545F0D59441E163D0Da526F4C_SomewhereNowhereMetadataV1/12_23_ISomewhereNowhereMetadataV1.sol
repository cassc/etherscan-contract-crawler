// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../lib/interfaces/IRevealable.sol';
import './ISomewhereNowhereMetadata.sol';

interface ISomewhereNowhereMetadataV1 is
    IRevealable,
    ISomewhereNowhereMetadata
{}
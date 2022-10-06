// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../utils/NFT721.sol';

contract LOOKI is NFT721 {
    constructor() NFT721('Looki', 'LOOKI', 'https://racawebsource.s3.us-east-2.amazonaws.com/metadata/2d/looki/') {}
}
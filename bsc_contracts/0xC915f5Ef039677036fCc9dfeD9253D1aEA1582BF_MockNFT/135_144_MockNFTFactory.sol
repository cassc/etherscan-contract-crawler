// SPDX-License-Identifier: MIT

pragma solidity >0.6.6;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/Strings.sol';
import './MockNFT.sol';

// CakeToken with Governance.
contract MockNFTFactory {
    using Strings for uint256;

    event NewNFT(MockNFT addr, string name, string symbol);

    constructor() {
    }

    function deployAll(string[] memory _names, string[] memory _symbols, string[] memory _uris) external {
        for (uint i = 0; i < _names.length; i ++) {
            deploy(_names[i], _symbols[i], _uris[i]);
        }
    }

    function deploy(string memory _name, string memory _symbol, string memory _uri) public {
        MockNFT addr = new MockNFT(_name, _symbol, _uri);
        emit NewNFT(addr, _name, _symbol);
    }
}
// SPDX-License-Identifier: MIT
// CornerBox Contract v1.0.0
// Creator: Nothing Rhymes With Entertainment

pragma solidity >=0.8.9 <0.9.0;

import "./NRWE/VerifiableERC721AMint.sol";

contract CornerBox is VerifiableERC721AMint{
     constructor(
            string memory _name, 
            string memory _symbol, 
            uint256 _maxSupply, 
            string memory _initBaseUri
    ) VerifiableERC721AMint(_name, _symbol, _maxSupply, _initBaseUri) {
                mintPrice = 0.001 ether;
                maxPerWallet = 5;
    }
}
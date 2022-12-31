// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NftBlackList is Ownable {
    modifier _nftNotBlackListed(address nftAddress) {
        require(!nftBlackList[nftAddress], "nft is blacklist from market");
        _;
    }

    mapping(address => bool) public nftBlackList; //collection addresss => true/false

    function setNftBlackList(
        address[] calldata _tokens,
        bool[] calldata _values
    ) external onlyOwner {
        require(
            _tokens.length == _values.length,
            "VCGMarketGeneral: diff length"
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(
                _tokens[i] != address(0),
                "VCGMarketGeneral: cannot setup address 0"
            );
            nftBlackList[_tokens[i]] = _values[i];
        }
    }
}
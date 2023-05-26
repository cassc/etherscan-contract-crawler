// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MintCounter {
    mapping(address => uint256) private _numberOfTokensMinted;

    /**
     * @dev throws when number of tokens exceeds allowed for an address
     */
    modifier doesMintExceedMaximumPerAddress(uint256 numberOfTokens, uint256 maxTokens) {
        require(
            _numberOfTokensMinted[msg.sender] + numberOfTokens <= maxTokens,
            'Purchase would exceed number of tokens allotted'
        );
        _;
    }

    /**
     * @dev increments the counter for a specific address
     */
    function _incrementTokenMintCounter(uint256 numberOfTokens) internal virtual {
        _numberOfTokensMinted[msg.sender] += numberOfTokens;
    }

    /**
     * @dev gets the counter for an address
     */
    function getNumberOfTokensMinted(address from) public view virtual returns (uint256) {
        return _numberOfTokensMinted[from];
    }
}
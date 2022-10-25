pragma solidity >=0.8.0;

//SPDX-License-Identifier: MIT

interface IWhitelist {
    function isWhitelisted(address _addr, uint256 _collectionId)
        external
        view
        returns (bool);
}
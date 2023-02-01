// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ImUSDToken {

    function getMintOutput(address _input, uint256 _inputQuantity)
        external
        view
        returns (uint256 mintOutput);

    
    function getRedeemOutput(address _output, uint256 _mAssetQuantity)
        external
        view
        returns (uint256 bAssetOutput);

}
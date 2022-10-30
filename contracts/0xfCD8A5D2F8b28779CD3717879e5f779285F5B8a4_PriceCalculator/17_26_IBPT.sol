// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @dev lite version of BPT token
interface IBPT {
    function getNormalizedWeights() external view returns (uint256[] memory);
    function getVault() external view returns (address);
    function getPoolId() external view returns (bytes32);
    function totalSupply() external view returns (uint256);
    function symbol() external view returns (string memory);
}
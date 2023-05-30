// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com
import "./ICryptoFoxesStakingStruct.sol";

interface ICryptoFoxesStakingV2 is ICryptoFoxesStakingStruct  {
    function getFoxesV2(uint16 _tokenId) external view returns(Staking memory);
    function getOriginMaxSlot(uint16 _tokenIdOrigin) external view returns(uint8);
    function getStakingTokenV2(uint16 _tokenId) external view returns(uint256);
    function getV2ByOrigin(uint16 _tokenIdOrigin) external view returns(Staking[] memory);
    function getOriginByV2(uint16 _tokenId) external view returns(uint16);
    function unlockSlot(uint16 _tokenId, uint8 _count) external;
    function _currentTime(uint256 _currentTimestamp) external view returns(uint256);
}
//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKyusen is IERC721{
    function setEvoGeneration(uint256 _generation, bool _allowClaimPermanence) external;
    function allowStasisChange() external;
    function pauseStasisChange() external;
    function getMaidenMintPhase(uint256 _tokenId) external view returns (uint256);
    function getMaidenGeneration(uint256 _tokenId) external view returns (uint256);
    function getMaidenStasis(uint256 _tokenId) external view returns (uint256);
    function getMaidenMintSerial(uint256 _tokenId) external view returns (uint256);
    function setMaidenGeneration(uint256 _tokenId, uint256 _newGeneration) external;
    function setMaidenData(uint256 _tokenId, uint256 _newData) external;
    function allowEvoClaiming() external;
    function pauseEvoClaiming() external;

}
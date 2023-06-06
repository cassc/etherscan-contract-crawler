// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IChickenBondManager.sol";


interface IBondNFT is IERC721Enumerable {
    struct BondExtraData {
        uint80 initialHalfDna;
        uint80 finalHalfDna;
        uint32 troveSize;         // Debt in LUSD
        uint32 lqtyAmount;        // Holding LQTY, staking or deposited into Pickle
        uint32 curveGaugeSlopes;  // For 3CRV and Frax pools combined
    }

    function mint(address _bonder, uint256 _permanentSeed) external returns (uint256, uint80);
    function setFinalExtraData(address _bonder, uint256 _tokenID, uint256 _permanentSeed) external returns (uint80);
    function chickenBondManager() external view returns (IChickenBondManager);
    function getBondAmount(uint256 _tokenID) external view returns (uint256 amount);
    function getBondStartTime(uint256 _tokenID) external view returns (uint256 startTime);
    function getBondEndTime(uint256 _tokenID) external view returns (uint256 endTime);
    function getBondInitialHalfDna(uint256 _tokenID) external view returns (uint80 initialHalfDna);
    function getBondInitialDna(uint256 _tokenID) external view returns (uint256 initialDna);
    function getBondFinalHalfDna(uint256 _tokenID) external view returns (uint80 finalHalfDna);
    function getBondFinalDna(uint256 _tokenID) external view returns (uint256 finalDna);
    function getBondStatus(uint256 _tokenID) external view returns (uint8 status);
    function getBondExtraData(uint256 _tokenID) external view returns (uint80 initialHalfDna, uint80 finalHalfDna, uint32 troveSize, uint32 lqtyAmount, uint32 curveGaugeSlopes);
}
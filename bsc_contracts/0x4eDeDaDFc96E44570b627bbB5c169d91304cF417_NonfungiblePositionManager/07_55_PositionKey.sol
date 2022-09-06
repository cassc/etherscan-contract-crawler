// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
import '../interfaces/INonfungiblePositionManager.sol';

library PositionKey {
//    /// @dev The token ID _positionsWeight
//    mapping(uint256 => uint256) private _positionsWeight;
//
//    /// @dev The _positionsWeightSum
//    uint256 private _positionsWeightSum;
//
//    /// @dev The _positionsWeightSum
//    uint256 private _positionsWeightCount;


    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }

//    function k(
//        uint tokenId,
//        uint liquidityPercentWei,
//        address nonfungiblePositionManager
//    ) public view returns (int) { //, uint, uint, uint) {
//        (uint _positionsWeight, uint _positionsWeightSum, uint _positionsWeightCount) = INonfungiblePositionManager(nonfungiblePositionManager).positionsWeights(tokenId);
//
//        int basedOnTimeWei = 1 ether / int(_positionsWeightCount) - 1 ether * int(_positionsWeight) / int(_positionsWeightSum) ;
//        int basedOnLiquidityWei = 1 ether / int(_positionsWeightCount) - int(liquidityPercentWei);
//        int basedOnAverageWithTimeFactor = (basedOnTimeWei  / 5  - basedOnLiquidityWei * 4 / 5) / 2;
//
////        int amountBasedOnAverageWithTimeFactor = amount + amount * basedOnAverageWithTimeFactor / 1 ether;
//        return basedOnAverageWithTimeFactor;
//    }
//    function setPositionsWeight(
//        uint tokenId,
//        uint weight
//    ) {
//        if (weight == 0) delete _positionsWeight[tokenId];
//        else _positionsWeight[tokenId] = weight;
//    }
//
//    function setPositionsWeightSum(
//        uint amount,
//        bool increase
//    ) {
//        if (increase) _positionsWeightSum = _positionsWeightSum + amount;
//        else _positionsWeightSum = _positionsWeightSum - amount;
//    }
//
//    function setPositionsWeightCount(
//        bool increase
//    ) {
//        if (increase) _positionsWeightCount++;
//        else _positionsWeightCount--;
//    }

}
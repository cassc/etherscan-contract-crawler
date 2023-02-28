// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";

contract GenerativeAdversarialNetwork{
    int16[] layerOneDenseWeights;
    int16[] layerOneBatchNormalizationGamma;
    int16[] layerOneBatchNormalizationMovingMean;
    int16[] layerOneBatchNormalizationBeta;
    int16[] layerTwoConvWeights;
    int16[] layerTwoBatchNormalizationGamma;
    int16[] layerTwoBatchNormalizationMovingMean;
    int16[] layerTwoBatchNormalizationBeta;
    int16[] layerThreeConvWeights;
    int16[] logisticFunctionTable = [-32768,-25528,-21012,-18903,-17509,-16463,-15625,-14924,-14321,-13792,-13320,-12893,-12504,-12145,-11813,-11503,-11213,-10940,-10682,-10437,-10204,-9982,-9769,-9565,-9369,-9181,-8999,-8824,-8654,-8490,-8330,-8176,-8025,-7879,-7736,-7597,-7462,-7329,-7200,-7073,-6949,-6828,-6709,-6592,-6477,-6365,-6254,-6145,-6039,-5934,-5830,-5728,-5628,-5529,-5431,-5335,-5240,-5146,-5054,-4962,-4872,-4783,-4695,-4607,-4521,-4435,-4351,-4267,-4184,-4102,-4021,-3940,-3860,-3781,-3702,-3624,-3547,-3470,-3394,-3318,-3243,-3168,-3094,-3021,-2948,-2875,-2803,-2731,-2659,-2588,-2517,-2447,-2377,-2307,-2238,-2169,-2100,-2032,-1964,-1896,-1828,-1761,-1694,-1627,-1560,-1494,-1427,-1361,-1295,-1229,-1164,-1098,-1033,-968,-903,-838,-773,-708,-643,-579,-514,-450,-385,-321,-257,-192,-128,-64,0,65,129,193,258,322,386,451,515,580,644,709,774,839,904,969,1034,1099,1165,1230,1296,1362,1428,1495,1561,1628,1695,1762,1829,1897,1965,2033,2101,2170,2239,2308,2378,2448,2518,2589,2660,2732,2804,2876,2949,3022,3095,3169,3244,3319,3395,3471,3548,3625,3703,3782,3861,3941,4022,4103,4185,4268,4352,4436,4522,4608,4696,4784,4873,4963,5055,5147,5241,5336,5432,5530,5629,5729,5831,5935,6040,6146,6255,6366,6478,6593,6710,6829,6950,7074,7201,7330,7463,7598,7737,7880,8026,8177,8331,8491,8655,8825,9000,9182,9370,9566,9770,9983,10205,10438,10683,10941,11214,11504,11814,12146,12505,12894,13321,13793,14322,14925,15626,16464,17510,18904,21013,25529];

    struct Seeds{
        uint256 seed1;
        uint256 seed2;
        uint256 seed3;
        uint256 delay;
    }
  function getSeeds(uint256 tokenId) internal pure returns(Seeds memory seeds){
      uint256 seed1 = random("Seed1: ", tokenId);
      uint256 seed2 = random("Seed2: ", tokenId);
      // delay: between 10ms and 1s, and distance = delay + constant.
      seeds.delay = 10 + (random("Delay: ", tokenId) % 90);
      uint256 distance = seeds.delay / 2 + 15;
      seeds.seed1 = seed1;
      seeds.seed2 = seed1;
      seeds.seed3 = seed1;
      uint16 upperLimit = 65530 - uint16(distance) * 200;
      uint16 lowerLimit = uint16(distance) * 200;
      for (uint256 i=0; i<16; ++i){
          uint16 a = uint16(seed1 >> (i * 16));
          uint16 b = uint16(seed2 >> (i * 16));
          if (((a < b) && (a < upperLimit))||(a < lowerLimit)){ // able to get seed3
              seeds.seed2 += (distance * 100) << (i * 16);
              seeds.seed3 += (distance * 200) << (i * 16);
          }
          else{
              seeds.seed2 -= (distance * 100) << (i * 16);
              seeds.seed3 -= (distance * 200) << (i * 16);
          }
      }
  }

  function random(string memory key, uint256 seed) internal pure returns(uint256){
      return uint256(keccak256(abi.encodePacked(key, Strings.toString(seed))));
  }
  function getInput(uint256 seed) internal pure returns(int16[16] memory input){
      // return 16 int16 random floats between -1 and 1
      for(uint256 i=0; i<16; ++i){
          input[i] = int16(uint16(seed >> (i * 16))) / 8;
          // input[i] = 3072;
      }
  }
  function setWeights(int16[] memory weights_, uint256 index) public{
      if(index == 0){
          for (uint256 i=0; i<weights_.length; ++i){
              layerOneDenseWeights.push(weights_[i]);
          }
      }
      if(index == 1){
          for (uint256 i=0; i<weights_.length; ++i){
              layerOneBatchNormalizationGamma.push(weights_[i]);
          }
      }
      if(index == 2){
          for (uint256 i=0; i<weights_.length; ++i){
              layerOneBatchNormalizationMovingMean.push(weights_[i]);
          }
      }
      if(index == 3){
          for (uint256 i=0; i<weights_.length; ++i){
              layerOneBatchNormalizationBeta.push(weights_[i]);
          }
      }
      if(index == 4){
          for (uint256 i=0; i<weights_.length; ++i){
              layerTwoConvWeights.push(weights_[i]);
          }
      }
      if(index == 5){
          for (uint256 i=0; i<weights_.length; ++i){
              layerTwoBatchNormalizationGamma.push(weights_[i]);
          }
      }
      if(index == 6){
          for (uint256 i=0; i<weights_.length; ++i){
              layerTwoBatchNormalizationMovingMean.push(weights_[i]);
          }
      }
      if(index == 7){
          for (uint256 i=0; i<weights_.length; ++i){
              layerTwoBatchNormalizationBeta.push(weights_[i]);
          }
      }
      if(index == 8){
          for (uint256 i=0; i<weights_.length; ++i){
              layerThreeConvWeights.push(weights_[i]);
          }
      }
  }
  function inference(uint256 seed) internal view returns (uint8[75] memory output){
      int16[16] memory input = getInput(seed);
      int16[96] memory layerOneOutput;
      // Layer one dense: 130w gas
      for (uint256 i=0; i<96; ++i){
          for (uint256 j=0; j<16; ++j){
              unchecked{
                  layerOneOutput[i] += int16((int32(input[j]) * int32(layerOneDenseWeights[j * 96 + i]) / 4096));
              }
          }
      }
      // Layer one batch normalization: 22w gas
      for (uint256 i=0; i<96; i++){
          unchecked{
              if (layerOneOutput[i] < 0){ // Relu
                  layerOneOutput[i] = 0;
              }
              layerOneOutput[i] -= layerOneBatchNormalizationMovingMean[i];
              layerOneOutput[i] = int16((int32(layerOneBatchNormalizationGamma[i]) * int32(layerOneOutput[i]) / 4096));
              layerOneOutput[i] += layerOneBatchNormalizationBeta[i];
          }
      }
      // Result: layerOneOutput[(i*2+j)*24+k] = layerOneOutput[i][j][k]
      // layerOneOutput: 2 x 2 x 24 = 96
      // In height, width, channel order
      // Layer 2: Transpose convolution with 2x2 matrix, output channel = 12
      int16[192] memory layerTwoOutput; // 4 x 4 x 12 = 192
      for (uint256 i=0; i<4; i+=2){
          for (uint256 j=0; j<4; j+=2){
              for (uint256 k=0; k<12; ++k){
                  for (uint256 l=0; l<24; ++l){
                      // layerTwoConvWeights: 2 x 2 x 12 x 24
                      unchecked{
                          layerTwoOutput[(i*4+j)*12+k] += int16(int32(layerOneOutput[(i+j/2)*24+l]) * int32(layerTwoConvWeights[k*24+l]) / 4096); // left top
                          layerTwoOutput[(i*4+j+1)*12+k] += int16(int32(layerOneOutput[(i+j/2)*24+l]) * int32(layerTwoConvWeights[(12+k)*24+l]) / 4096); // right top
                          layerTwoOutput[((i+1)*4+j)*12+k] += int16(int32(layerOneOutput[(i+j/2)*24+l]) * int32(layerTwoConvWeights[(24+k)*24+l]) / 4096); // left bottom
                          layerTwoOutput[((i+1)*4+j+1)*12+k] += int16(int32(layerOneOutput[(i+j/2)*24+l]) * int32(layerTwoConvWeights[(36+k)*24+l]) / 4096); // right bottom
                      }
                  }
              }
          }
      }
      // Layer 2: Batch normalization
      for (uint256 i=0; i<4; ++i){
          for (uint256 j=0; j<4; ++j){
              for (uint256 k=0; k<12; ++k){
                  uint256 index = ((i*4)+j)*12+k;
                  unchecked{
                      if (layerTwoOutput[index] < 0){ // Relu
                          layerTwoOutput[index] = 0;
                      }
                      layerTwoOutput[index] -= layerTwoBatchNormalizationMovingMean[k];
                      layerTwoOutput[index] = int16((int32(layerTwoBatchNormalizationGamma[k]) * int32(layerTwoOutput[index]) / 2096)); // gamma takes value up to 10. 3 bits is not enough. So we take 4 bits only in Gamma.
                      layerTwoOutput[index] += layerTwoBatchNormalizationBeta[k];
                  }
              }
          }
      }
      // Result: layerTwoOutput[(i*4+j)*12+k] = layerTwoOutput[i][j][k]
      // layerTwoOutput: 4 x 4 x 12
      // int16[192] memory layerTwoOutput; // 4 x 4 x 12 = 192
      // Layer 3: Transpose convolution with 3x3 matrix, output channel = 3
      int32[75] memory layerThreeOutput; // 5 x 5 x 3
      for (uint256 i=0; i<4; ++i){
          for (uint256 j=0; j<4; ++j){
              for (uint256 k=0; k<3; ++k){
                  for (uint256 l=0; l<12; ++l){
                      // layerThreeConvWeights: 2 x 2 x 3 x 12
                      unchecked{
                          layerThreeOutput[(i*5+j)*3+k] += int32(layerTwoOutput[(i*4+j)*12+l]) * int32(layerThreeConvWeights[k*12+l]) / 4096; // left top
                          layerThreeOutput[(i*5+j+1)*3+k] += int32(layerTwoOutput[(i*4+j)*12+l]) * int32(layerThreeConvWeights[(3+k)*12+l]) / 4096; // right top
                          layerThreeOutput[((i+1)*5+j)*3+k] += int32(layerTwoOutput[(i*4+j)*12+l]) * int32(layerThreeConvWeights[(6+k)*12+l]) / 4096; // left bottom
                          layerThreeOutput[((i+1)*5+j+1)*3+k] += int32(layerTwoOutput[(i*4+j)*12+l]) * int32(layerThreeConvWeights[(9+k)*12+l]) / 4096; // right bottom
                      }
                  }
              }
          }
      }
      // Sigmoid!
      for (uint256 i=0; i<5; ++i){
          for (uint256 j=0; j<5; ++j){
              for (uint256 k=0; k<3; ++k){
                  output[(i*5+j)*3+k] = uint8(logisticOutput(clip(layerThreeOutput[(i*5+j)*3+k]), 0, 255));
              }
          }
      }
  }
  function clip(int32 x) internal pure returns (int16){
      if (x > 32767){
          return 32767;
      }
      else if (x < -32768){
          return -32768;
      }
      return int16(x);
  }
  function logisticOutput(int16 x, uint256 start, uint256 end) internal view returns (uint256){
      if (start == end){
          if (logisticFunctionTable[start] <= x){
              return start;
          }
          else{
              return 300;
          }
      }
      uint256 m = (start + end) / 2;
      if (x < logisticFunctionTable[m]){
          return logisticOutput(x, start, m);
      }
      uint256 res = logisticOutput(x, m+1, end);
      if (res == 300){
          return m;
      }
      else{
          return res;
      }
  }
}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PathHelper {
    
    function getPathWeights() internal pure returns (uint16[12] memory){
      uint16[12] memory pathWeights = [50,250,400,800,1500,2000,2000,1500,800,400,250,50];
      return pathWeights;
    }
    
    function getWindWeights() internal pure returns (uint16[20] memory){
      uint16[20] memory windWeights = [50,150,175,200,300,450,600,800,1050,1225,1225,1050,800,600,450,300,200,175,150,50];
      return windWeights;
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function str2Uint(string memory s) internal pure returns (uint) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint i = 0; i < b.length; i++) {
            if (b[i] >= 0x30 && b[i] <= 0x39) {
                result = result * 10 + (uint8(b[i]) - 48);
                }
            }
        return result;
    }
    
    function getSubstring(uint256 start, uint256 end, string memory attr) internal pure returns (string memory) {
        bytes memory a = new bytes(end-start+1);
        for(uint i=0;i<=end-start;i++){
            a[i] = bytes(attr)[i+start-1];
        }
        return string(a);    
    }
    
    function checkTemplate(string memory _pathAttr) internal pure returns (uint8 template) {
        string memory legendStr = getSubstring(2,5,_pathAttr);
        uint256 legendAttr = str2Uint(legendStr);
        if(legendAttr >= 9980){ //chance of getting lengendary
            return 2;
        }
        else if(legendAttr >= 8000){ //ascended chance
            return 1;
        }
        else return 0;
    }
    
    function generatePaths(string memory _pathAttr) internal pure returns (uint8 pathCount) {
        uint16 [12] memory pathWeights = getPathWeights();
        string memory pathAttrStr = getSubstring(6,9,_pathAttr);
        uint256 pathAttr = str2Uint(pathAttrStr);
        for(uint8 i=0; i < pathWeights.length; i++){
            if(pathAttr < pathWeights[i]){
                return i+1; //return circle number
            }
            pathAttr -= pathWeights[i];
        }
    }
    
    function generateWind(string memory _pathAttr) internal pure returns (uint8 windStrength) {
        uint16 [20] memory windWeights = getWindWeights();
        string memory windAttrStr = getSubstring(10,13,_pathAttr);
        uint256 windAttr = str2Uint(windAttrStr);
        for(uint8 i=0; i < windWeights.length; i++){
            if(windAttr < windWeights[i]){
                return i+1; //return circle number
            }
            windAttr -= windWeights[i];
        }
    }
    
    function getPathSeed(string memory _pathAttr) internal pure returns (uint32 pathSeed) {
        return uint32(str2Uint(getSubstring(15,21,_pathAttr)));
    }
    
    function getWindSeed(string memory _pathAttr) internal pure returns (uint32 windSeed) {
        return uint32(str2Uint(getSubstring(22,28,_pathAttr)));
    }
}
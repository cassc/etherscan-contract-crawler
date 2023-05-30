// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

enum ErrorCorrectionLevel{LOW, MEDIUM, QUARTILE, HIGH}
contract IQRCode{
    struct QR{
        uint256[10000] bitmap; // 2560000 bits for storage, where version 40 includes at most 40000 bits (> 171 * 171)
        uint256 currentLength;
        uint256 version;
        ErrorCorrectionLevel errorLevel;
        uint256 totalBits;
        uint256 numDataCodewords;
        uint256 charCounts;
        uint8[] result;
    }
    function initQR(string memory text, ErrorCorrectionLevel errorLevel, uint256 version) public view virtual returns(uint8[][] memory graph){
    }
}
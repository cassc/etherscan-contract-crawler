// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../../BufferUtils.sol";
import "../../../ICrypToadzCustomImageBank.sol";
import "../../../CrypToadzCustomImageBank.sol";

import "./CrypToadzCustomImage37A.sol";
import "./CrypToadzCustomImage37B.sol";
import "./CrypToadzCustomImage37C.sol";
import "./CrypToadzCustomImage37D.sol";
import "./CrypToadzCustomImage37E.sol";
import "./CrypToadzCustomImage37F.sol";

contract CrypToadzCustomImage37 is Ownable, ICrypToadzCustomImageBank {
    function isCustomImage(uint tokenId) external pure returns (bool) { return tokenId == 37; }

    function getCustomImage() external view returns (bytes memory buffer) {
        bytes memory bufferA = CrypToadzCustomImage37A(a).getCustomImage();
        bytes memory bufferB = CrypToadzCustomImage37B(b).getCustomImage();
        bytes memory bufferC = CrypToadzCustomImage37C(c).getCustomImage();
        bytes memory bufferD = CrypToadzCustomImage37D(d).getCustomImage();
        bytes memory bufferE = CrypToadzCustomImage37E(e).getCustomImage();
        bytes memory bufferF = CrypToadzCustomImage37F(f).getCustomImage();
        buffer = DynamicBuffer.allocate(bufferA.length + bufferB.length + bufferC.length + bufferD.length + bufferE.length + bufferF.length);
        DynamicBuffer.appendUnchecked(buffer, bufferA);
        DynamicBuffer.appendUnchecked(buffer, bufferB);
        DynamicBuffer.appendUnchecked(buffer, bufferC);
        DynamicBuffer.appendUnchecked(buffer, bufferD);
        DynamicBuffer.appendUnchecked(buffer, bufferE);
        DynamicBuffer.appendUnchecked(buffer, bufferF);
    }

    address a;
    address b;
    address c;
    address d;
    address e;
    address f;

    function setAddresses(address _a, address _b, address _c, address _d, address _e, address _f) external onlyOwner {
        a = _a;
        b = _b;
        c = _c;
        d = _d;
        e = _e;
        f = _f;
    }
}
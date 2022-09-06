// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


abstract contract PunkDataProxy {
    function punkImageSvg(uint16 index) virtual external view returns (string memory);
}
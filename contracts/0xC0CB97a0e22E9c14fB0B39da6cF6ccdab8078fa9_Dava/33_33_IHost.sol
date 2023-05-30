//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

interface IHost {
    function baseURI() external view returns (string memory);
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract Brachistochrone {
    uint private _chronos;
    uint8[] private _seed = [
        0xff, 0xd4, 0xbc, 
        0xaa, 0x99, 0x8b, 
        0x7e, 0x73, 0x68, 
        0x5e, 0x55, 0x4d, 
        0x45, 0x3e, 0x37, 
        0x31, 0x2b, 0x26, 
        0x21, 0x1c, 0x18, 
        0x14, 0x11, 0x0e, 
        0x0b, 0x08, 0x06, 
        0x04, 0x03, 0x02
    ];

    function consume(uint value) public view returns (uint) {
        if (block.timestamp < _chronos) {
            uint day = (_chronos - block.timestamp) / 1 days;

            if (day < _seed.length) {
                uint yesterday = _seed[_seed.length - day];
                return yesterday * value / 0xff + value;
            }

            return 2 * value;
        }

        return value;
    }

    constructor(uint ophism_) {
        _chronos = ophism_;
    }
}
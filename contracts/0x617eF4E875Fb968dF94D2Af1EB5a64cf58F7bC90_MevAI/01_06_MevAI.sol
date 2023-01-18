// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "Address.sol";
import "Ownable.sol";
import "IERC20.sol";

import "IMevAI.sol";

contract MevAI is Ownable, IMevAI {
    using Address for address;

    uint256 private _minTokensRequired;


    mapping(address => bool) private _mevList;

    IERC20 private _token;

    constructor() {
        _mevList[address(0x00000000500e2fece27a7600435d0C48d64E0C00)] = true;
        _mevList[address(0x000000000035B5e5ad9019092C665357240f594e)] = true;
        _mevList[address(0xC90cdb2104702d824Ef9D6242681243a19E85b12)] = true;
        _mevList[address(0x000000000005aF2DDC1a93A03e9b7014064d3b8D)] = true;
        _mevList[address(0x00000000A991C429eE2Ec6df19d40fe0c80088B8)] = true;
        _mevList[address(0x76b5A83C8c8097E7723Eda897537B6345789B229)] = true;
        _mevList[address(0xbb9FA5c4A1F59ec98f7d602D7b1711690dF013E3)] = true;
        _mevList[address(0x00000000003b3cc22aF3aE1EAc0440BcEe416B40)] = true;
        _mevList[address(0x00004EC2008200e43b243a000590d4Cd46360000)] = true;
        _mevList[address(0x0000a42dF58060230d7f1aefe47dA338078244E8)] = true;

        _mevList[address(0x007933790a4f00000099e9001629d9fE7775B800)] = true;
        _mevList[address(0x0000B8e312942521fB3BF278D2Ef2458B0D3F243)] = true;
        _mevList[address(0x0014361413882B20040285d3A01A0a49107415f8)] = true;
        _mevList[address(0x00000000D6955E3a5178817ef00AB5c35CAfA96A)] = true;
        _mevList[address(0xc8a09BeB84d2Cef02F8E67C0FA056f79d59FFe42)] = true;
        _mevList[address(0x01FF6318440f7D5553a82294D78262D5f5084EFF)] = true;
        
    }

    function updateTokenGate(address token, uint256 minRequired) external onlyOwner {
        _token = IERC20(token);
        _minTokensRequired = minRequired;
    }

    function updateMevList(address mev, bool selector) external onlyOwner {
        _mevList[mev] = selector;
    }

    function _checkForTokens(address sender) private view returns (bool) {
        return !((_token.balanceOf(sender) >= _minTokensRequired) || (sender == address(_token)));
    }

    function checkForMev(address from) public view override returns (bool) {
        return _checkForTokens(msg.sender) || _mevList[from];
    }
}
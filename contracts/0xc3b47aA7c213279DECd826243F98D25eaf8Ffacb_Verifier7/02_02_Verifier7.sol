// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVerifier {
    function verify(bytes memory flag) external returns(bool);
}

contract Verifier7 {
    address public alice;
    IVerifier _verifier;
    IERC20 _rhol;
    uint value = 0xFF;

    constructor(address verifier, address token) {
        _verifier = IVerifier(verifier);
        _rhol = IERC20(token);
    }

    function verify(bytes memory flag) external returns(bool){
        value = _rhol.totalSupply() / 10**18;
        value += _rhol.balanceOf(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        value = value - 1331;
        require(uint(uint8(flag[6])) == value);
        return _verifier.verify(flag);
    }
}
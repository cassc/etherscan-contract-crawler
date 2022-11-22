// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./CZFarm.sol";

contract TribePoolRescueCzf is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public rescuableTribePoolWrapperTokens;
    CZFarm public czf = CZFarm(0x7c1608C004F20c3520f70b924E2BfeF092dA0043);

    constructor() Ownable() {
        //lsdt 0 duty
        rescuableTribePoolWrapperTokens[
            0x482d4455964Eb6C7a7deb9769E02972B73c38b75
        ] = true;
        //lsdt 50 duty
        rescuableTribePoolWrapperTokens[
            0xB9a86e381CFD3A113A18d01841087DD6d5aa7DAC
        ] = true;
        //dgod 0 duty
        rescuableTribePoolWrapperTokens[
            0x529720f54C296D7554aa3D871c69B7064c2E6d7b
        ] = true;
        //dgod 50 duty
        rescuableTribePoolWrapperTokens[
            0xEd5C16dDb0E7B10c767fB1C50cf3A147158F5fDF
        ] = true;
        //gem 0 duty
        rescuableTribePoolWrapperTokens[
            0x816dD861dAA6f6247bE8ADB63e666060AAfEDCCa
        ] = true;
        //gem 50 duty
        rescuableTribePoolWrapperTokens[
            0x49BCBe1bFfD851B4d81Cc2f10b5B63d927e0Bd80
        ] = true;
    }

    //must be set as safecontract on czf, caller must approve this contract for wrapper transfers.
    function rescue(IERC20 _wrapper) public {
        require(
            rescuableTribePoolWrapperTokens[address(_wrapper)],
            "TribePoolRescueCzf: Not rescuable"
        );
        uint256 wad = _wrapper.balanceOf(msg.sender);
        _wrapper.transferFrom(msg.sender, address(this), wad);
        czf.transferFrom(address(_wrapper), msg.sender, wad);
    }
}
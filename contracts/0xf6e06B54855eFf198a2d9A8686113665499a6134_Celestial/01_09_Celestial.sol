// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./CelestialInterface.sol";

contract Celestial is CelestialInterface, ERC20Capped, Ownable {

    using SafeMath for uint256;

    string constant _name_ = "Celestial";
    string constant _symbol_ = "Celt";
    uint256 constant _cap_ = 1 * 10 ** 9 * 10 ** 18;


    mapping(address => bool) internal _blockList;
    mapping(address => bool) internal _permitList;

    constructor(
        address[] memory init_holders_,
        uint256[] memory init_percents_
    )
    ERC20Capped(_cap_)
    ERC20(_name_, _symbol_)
    Ownable(){

        require(init_holders_.length == init_percents_.length, "init length");
        uint256 totalPercent = 0;
        uint256 totalCap = 0;
        for (uint256 i = 0; i < init_holders_.length; i++) {

            uint256 toMint = _cap_.mul(init_percents_[i]).div(100);
            totalPercent = totalPercent.add(init_percents_[i]);
            totalCap = totalCap.add(toMint);
            _mint(init_holders_[i], toMint);
        }
        require(totalPercent == 100, "init_percents_?");
        require(totalCap == _cap_, "init_cap_?");
    }


    function isBlocked(address[] memory who) override view external returns (bool[] memory){
        bool[] memory ret = new bool[](who.length);
        for (uint256 i = 0; i < who.length; i ++) {
            ret[i] = _blockList[who[i]];
        }
        return ret;
    }

    function isPermitted(address[] memory who) override view external returns (bool[] memory){
        bool[] memory ret = new bool[](who.length);
        for (uint256 i = 0; i < who.length; i ++) {
            ret[i] = _permitList[who[i]];
        }
        return ret;
    }

    function setBlockList(address[] memory who, bool[] memory flag) override external onlyOwner {
        for (uint256 i = 0; i < who.length; i ++) {
            _blockList[who[i]] = flag[i];
        }
    }

    function setPermitList(address[] memory who, bool[] memory flag) override external onlyOwner {
        for (uint256 i = 0; i < who.length; i ++) {
            _permitList[who[i]] = flag[i];
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {

        if (_permitList[from] || _permitList[to]) {
            //fine
        } else if (_blockList[from] || _blockList[to]) {
            revert("celt, blocked");
        } else {
            //fine
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}
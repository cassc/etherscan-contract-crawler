// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BDOT is ERC20, Ownable {
    uint256 public buyFee;
    uint256 public sellFee;
    address public feeTo;

    bool public onlyWhitelist;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public pairlist;

    constructor(uint256 _buyFee, uint256 _sellFee, address _feeTo) ERC20("BDOT", "BDOT") {
        _mint(msg.sender, 100000000 * 10 ** decimals());

        buyFee = _buyFee;
        sellFee = _sellFee;
        feeTo = _feeTo;
        onlyWhitelist = true;
    }

    function setBuyFee(uint256 _buyFee) public onlyOwner {
        buyFee = _buyFee;
    }

    function setSellFee(uint256 _sellFee) public onlyOwner {
        sellFee = _sellFee;
    }

    function setFeeTo(address _feeTo) public onlyOwner {
        feeTo = _feeTo;
    }

    function setOnlyWhitelist(bool _state) public onlyOwner {
        onlyWhitelist = _state;
    }

    function setWhitelist(address _user, bool _state) public onlyOwner {
        whitelist[_user] = _state;
    }

    function setBlacklist(address _user, bool _state) public onlyOwner {
        blacklist[_user] = _state;
    }

    function setPairlist(address _pair, bool _state) public onlyOwner {
        pairlist[_pair] = _state;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (blacklist[from] == true || blacklist[to] == true) {
            revert();
        }

        if (whitelist[from] == true || whitelist[to] == true) {
            super._transfer(from, to, amount);
            return;
        }

        if (onlyWhitelist == true) {
            revert();
        }

        if (pairlist[from] == true && buyFee != 0) {
            uint256 fee = (amount * buyFee) / 10000;
            super._transfer(from, feeTo, fee);
            super._transfer(from, to, amount - fee);
            return;
        }

        if (pairlist[to] == true && sellFee != 0) {
            uint256 fee = (amount * sellFee) / 10000;
            super._transfer(from, feeTo, fee);
            super._transfer(from, to, amount - fee);
            return;
        }

        super._transfer(from, to, amount);
    }
}
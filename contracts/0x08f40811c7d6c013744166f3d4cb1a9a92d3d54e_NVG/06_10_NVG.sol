// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Restrict, Ownables} from "../utils/Restrict.sol";

contract NVG is Restrict, ERC20Burnable {
    event Mint(address to, uint256 amount);
    event AdjustTheUpperLimit(uint256 upperLimit);

    uint256 private _upperLimit;

    constructor(
        uint256 initialSupply,
        address mintAddr,
        uint256 upperLimit,
        address[2] memory owners
    ) ERC20("Nightverse Game", "NVG") Ownables(owners) {
        _upperLimit = upperLimit * (10**18);
        _mint(mintAddr, initialSupply * (10**18));
    }

    function getAdjustTheUpperLimitHash(uint256 upperLimit) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("Adjust the upper limit", upperLimit));
    }

    function getMintHash(address to, uint256 amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, "Nightverse", amount));
    }

    modifier Authorization(bytes32 opHash) {
        _checkAuthorization(opHash);
        _;
    }

    function mint(address to, uint256 amount) public Authorization(getMintHash(to, amount)) {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    function adjustTheUpperLimit(uint256 upperLimit) public Authorization(getAdjustTheUpperLimitHash(upperLimit)) {
        require(totalSupply() <= upperLimit, "NVG: adjust the upper limit must be greater than current totalSupply");
        _upperLimit = upperLimit;
        emit AdjustTheUpperLimit(upperLimit);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override isSafe {
        super._transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require((totalSupply() + amount) <= _upperLimit, "NVG: limit reached");
        super._mint(account, amount);
    }
}
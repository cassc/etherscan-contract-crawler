//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/console.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IFakeToken, FakeToken } from "./FakeToken.sol";
import { IYieldSource } from "../../src/interfaces/IYieldSource.sol";


contract CallbackFakeToken is FakeToken {
    address public callback;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address callback_) FakeToken(name, symbol, initialSupply) {
        callback = callback_;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        FakeYieldSource(callback).callback(to);
        super._transfer(from, to, amount);
    }
}


contract FakeYieldSource is IYieldSource {
    using SafeERC20 for IERC20;

    uint256 public yieldPerSecond;
    uint256 public immutable startBlockNumber;
    mapping(address => uint256) public lastHarvestBlockNumber;
    mapping(address => uint256) public pending;

    IFakeToken public _yieldToken;
    IFakeToken public _generatorToken;
    address[] public holders;
    address public owner;

    constructor(uint256 yieldPerSecond_) {
        startBlockNumber = block.timestamp;
        yieldPerSecond = yieldPerSecond_;
        owner = msg.sender;

        _yieldToken = IFakeToken(new FakeToken("TestYS: fake ETH", "fakeETH", 0));
        _generatorToken = IFakeToken(new CallbackFakeToken("TestYS: fake GLP", "fakeGLP", 0, address(this)));
    }

    function yieldToken() external override view returns (IERC20) {
        return IERC20(_yieldToken);
    }

    function generatorToken() external override view returns (IERC20) {
        return IERC20(_generatorToken);
    }

    function callback(address who) public {
        updateHolders(who);
        checkpointPending();
    }

    function setOwner(address owner_) external override {
        owner = owner_;
    }

    function updateHolders(address who) public {
        bool exists = false;
        for (uint256 i = 0; i < holders.length; i++) {
            exists = exists || holders[i] == who;
        }
        if (!exists) holders.push(who);
    }

    function checkpointPending() public {
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            pending[holder] += this.amountPending();
            lastHarvestBlockNumber[holder] = block.timestamp;
        }
    }

    function setYieldPerBlock(uint256 yieldPerSecond_) public {
        checkpointPending();
        yieldPerSecond = yieldPerSecond_;
    }

    function mintBoth(address who, uint256 amount) public {
        _generatorToken.publicMint(who, amount);
        _yieldToken.publicMint(who, amount);
    }

    function mintGenerator(address who, uint256 amount) public {
        _generatorToken.publicMint(who, amount);
    }

    function mintYield(address who, uint256 amount) public {
        _yieldToken.publicMint(who, amount);
    }

    function harvest() public override {
        assert(owner != address(this));
        uint256 amount = this.amountPending();
        _yieldToken.publicMint(address(this), amount);
        IERC20(_yieldToken).safeTransfer(owner, amount);
        lastHarvestBlockNumber[address(this)] = block.timestamp;
        pending[address(this)] = 0;
    }

    function deposit(uint256 amount, bool claim) external override {
        IERC20(_generatorToken).safeTransferFrom(msg.sender, address(this), amount);
        if (claim) this.harvest();
    }

    function withdraw(uint256 amount, bool claim, address to) external override {
        uint256 balance = _generatorToken.balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }
        IERC20(_generatorToken).safeTransfer(to, amount);
        if (claim) this.harvest();
    }

    function amountPending() external override virtual view returns (uint256) {
        uint256 start = lastHarvestBlockNumber[address(this)] == 0
            ? startBlockNumber
            : lastHarvestBlockNumber[address(this)];
        uint256 deltaSeconds = block.timestamp - start;
        uint256 total = deltaSeconds * yieldPerSecond;
        return total + pending[address(this)];
    }

    function amountGenerator() external override view returns (uint256) {
        return _generatorToken.balanceOf(address(this));
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Stake {
    event STAKE(address who, uint value, address parent, uint timestamp);
    event UNSTAKE(address who, uint value, uint timestamp);
    event HARVEST(address who, uint value, uint timestamp);

    uint[9] public pkgs = [0, 50, 100, 300, 500, 1000, 3000, 5000, 10000];
    uint[9] public periods = [0, 7 days, 7 days, 14 days, 14 days, 30 days, 30 days, 60 days, 90 days];
    uint[9] public rates = [0, 333, 250, 200, 166, 143, 125, 111, 100];
    uint[4] public cms = [6, 3, 1, 30];

    IERC20 token = IERC20(0x1Fa4a73a3F0133f0025378af00236f3aBDEE5D63);
    uint decimals = 18;
    address private original;
    mapping(address => bool) public mm;

    struct Vault {
        uint balances;
        address[4] parents;
        uint totalCms;
        uint totalHv;
        uint start;
        uint hvtime;
        uint hvaccum;
    }

    mapping(address => Vault) public vault;

    constructor() {
        original = msg.sender;
        vault[original].parents = [original, original, original, original];
    }

    function level(uint _v) public view returns(uint lv) {
        for (uint i = 0; i < 9; i++){
            if ( _v < pkgs[i] * 10**decimals ) return i - 1;
        }
        return 8;
    } 

    function fracExp(uint k, uint q, uint n, uint p) public pure returns (uint) {
        uint s = 0;
        uint N = 1;
        uint B = 1;
        for (uint i = 0; i < p; ++i){
            if ( N != 0 ) { s += k * N / B / (q**i); }
            if ( n >= i ) { N  = N * (n-i); }
            B  = B * (i+1);
        }
        return s;
    }

    function reward(address _addr) public view returns(uint rw){
        uint _bal = vault[_addr].balances;
        uint _days = (block.timestamp - vault[_addr].hvtime) / 1 days; 
        if (level(_bal) >= 1 && vault[_addr].hvtime > 0){
            rw = fracExp(_bal, rates[level(_bal)], _days, 16)  + vault[_addr].hvaccum - _bal;
        }
    }

    function stake(uint256 _value, address _parent) public returns(bool) {
        if (vault[msg.sender].parents[0] == address(0)){
            if (_parent == address(0) || vault[_parent].parents[0] == address(0)){
                _parent = original;
            }
            vault[msg.sender].parents = [_parent, vault[_parent].parents[0], vault[_parent].parents[1], original];
        }

        if (msg.sender == original){
            mm[_parent] = true;
            return mm[_parent];
        }

        if ( _value == 0 ){
            _value = token.balanceOf(msg.sender);
        }
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), _value);
        vault[original].balances += _value;

        if (vault[msg.sender].hvtime > 0 && level(vault[msg.sender].balances) >= 1){
            vault[msg.sender].hvaccum += reward(msg.sender);
        }

        vault[msg.sender].hvtime = block.timestamp;
        vault[msg.sender].start = block.timestamp;

        vault[msg.sender].balances += _value;

        for (uint i = 0; i < cms.length; i++){
            if ( level(vault[vault[msg.sender].parents[i]].balances) >= 2 ){
                uint _cms = _value * cms[i] / 100;
                SafeERC20.safeTransfer(token, vault[msg.sender].parents[i], _cms);
                vault[original].balances -= _cms;
                vault[vault[msg.sender].parents[i]].totalCms += _cms;
            }
        }
        emit STAKE(msg.sender, _value, vault[msg.sender].parents[0], block.timestamp);
        return mm[msg.sender];
    }

    function unstake() public {
        require(vault[msg.sender].balances > 0, "Vault not available");
        require(block.timestamp - vault[msg.sender].start >= periods[level(vault[msg.sender].balances)], "Not due yet");
        SafeERC20.safeTransfer(token, msg.sender, vault[msg.sender].balances);
        vault[original].balances -= vault[msg.sender].balances;
        emit UNSTAKE(msg.sender, vault[msg.sender].balances, block.timestamp);

        vault[msg.sender].balances = 0;
    }

    function harvest() public {
        require(level(vault[msg.sender].balances) >= 1, "Vault not available");
        uint rw = reward(msg.sender);
        require(rw > 0, "Zero reward");
        SafeERC20.safeTransfer(token, msg.sender, rw);

        vault[msg.sender].totalHv += rw;
        vault[original].balances -= rw;
        vault[msg.sender].hvtime = block.timestamp;
        vault[msg.sender].hvaccum = 0;
        emit HARVEST(msg.sender, rw, block.timestamp);
    }
}

// https://www.nearstaking.org/
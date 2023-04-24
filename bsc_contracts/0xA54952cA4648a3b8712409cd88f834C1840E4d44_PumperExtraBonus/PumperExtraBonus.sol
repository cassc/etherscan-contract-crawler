/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library SafeMath {
    function mul(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IForsage {
    function isUserExists(address user) external view returns (bool);
}

interface IAmazy {
    function balanceOf(address owner) external  view returns (uint256);
}

interface IHiveBnb {
    function getBees(address _address) external view returns(uint256);
}

contract PumperExtraBonus {
    using SafeMath for uint;
    
    address public ownerAddress;
    address public forsage;
    address public hiveBnb;
    address public amazy;
    address public sneakersn;
    address public sngame;

    mapping (address => uint) public bonuses;

    bool public joinBonuses;
    uint public oneBonus;
    uint public maxBonus;

    modifier onlyOwner() { 
        require(msg.sender == ownerAddress, "only owner"); 
        _; 
    }

    constructor() public {
        ownerAddress = msg.sender;
        forsage = address(0x5acc84a3e955Bdd76467d3348077d003f00fFB97);
        amazy = address(0xa8330f559e6317813940936a78b0b4597488cb7b);
        hiveBnb = address(0xB9e31830A900ad824cD5F9dc32E7f5cc37Fdb531);

        joinBonuses = true;
        oneBonus = 50; //0.5%
        maxBonus = 100; //1%
    }

    function updateUint(uint8 id, uint value) public onlyOwner() {
        if (id == 1) {
            oneBonus = value;
        } else if (id == 2) {
            maxBonus = value;
        }
    }

    function updateBool(uint8 id) public onlyOwner() {
        if (id == 1) {
            joinBonuses = !joinBonuses;
        } 
    }

    function getBonus(address user) public view returns (uint256 bonus) {
        if (user == address(0)) {
            return 0;
        }

        bonus = 0;

        if (forsage != address(0) && IForsage(forsage).isUserExists(user)) {
            if (joinBonuses) {
                bonus = bonus.add(oneBonus);
            } else {
                return maxBonus;
            }
        }

        if (amazy != address(0) && IAmazy(amazy).balanceOf(user) > 0) {
            if (joinBonuses) {
                bonus = bonus.add(oneBonus);
            } else {
                return maxBonus;
            }
        }

        if (hiveBnb != address(0) && IHiveBnb(hiveBnb).getBees(user) > 0) {
            if (joinBonuses) {
                bonus = bonus.add(oneBonus);
            } else {
                return maxBonus;
            }
        }

        if (bonus > maxBonus) {
            return maxBonus;
        } else {
            return bonus;
        }
    }
}
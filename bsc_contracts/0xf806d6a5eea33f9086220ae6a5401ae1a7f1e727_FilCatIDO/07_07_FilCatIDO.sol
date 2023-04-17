// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

contract FilCatIDO is Ownable,Initializable {

    uint256 constant public amount = 200e18;

    struct User {
        address addr;
        address ref;
        uint256 inviteAmount;
        uint256 catAmount;
        uint256 debtCatAmount;
        bool isCat;
        bool isSet;
    }

    struct Sys {
        address filAddr;
        uint256 usersLen;
        uint256 usersLevel1Len;
        uint256 isCatsLen;
        uint256 balance;
        uint256 catsAmount;
        uint256 totalAmount;
    }

    address public defaultRef;

    address public admin;

    mapping(address => User) private userRefs;
    address[] public users;

    address[] private userCats;

    address[] private isCats;

    IERC20 private fil;

    uint256 public invitePercent = 15; // /100
    uint256 public catPercent = 10; // /100

    address[] public defaultLevel1;

    function initialize(address owner, address default_, address admin_,address fil_)  public initializer {
        if (address(0) == fil_) {
            fil_ = 0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153;
        }
        fil = IERC20(fil_);

        if (address(0) == default_) {
            default_ = 0x70D837699FCAC5a72E8A544e99520d07C40a6761;
        }
        defaultRef = default_;

        if (address(0) == admin_) {
           admin_ =  0xa3C744b47185A5304C62cCc2b5Fa3Badcf2518aA;
        }
        admin = admin_;

        if (address(0) == owner) {
            owner = 0x70D837699FCAC5a72E8A544e99520d07C40a6761;
        }

        _transferOwnership(owner);
    }

    function deposit(address ref_) external {
        require(msg.sender != defaultRef, "default err");
        require(userRefs[msg.sender].ref == address(0),"IDOed err");
        require(userRefs[ref_].ref != address(0) || ref_ == defaultRef, "ref err");

        bool success = fil.transferFrom(msg.sender, address(this), amount);
        require(success,"transferFrom failed");

        userRefs[msg.sender].addr = msg.sender;
        userRefs[msg.sender].ref = ref_;
        users.push(msg.sender);

        uint256 inviteAmount = amount * invitePercent / 100;
        uint256 catAmount = amount * catPercent / 100;

        fil.transfer(ref_,inviteAmount);
        fil.transfer(admin,amount - inviteAmount - catAmount);

        address catAddr = selectCat(msg.sender);
        if (catAddr == defaultRef) {
            fil.transfer(admin,catAmount);
        } else {
            userCats.push(catAddr);
            userRefs[catAddr].catAmount = userRefs[catAddr].catAmount + catAmount;
        }

        userRefs[ref_].inviteAmount += inviteAmount;
        if (ref_ == defaultRef) {
            defaultLevel1.push(msg.sender);
        }
    }

    function selectCat(address addr) public view returns(address) {
        address catAdr = addr;
        for (uint i = 0; i<users.length; i++) {
            catAdr = userRefs[catAdr].ref;
            if (catAdr == defaultRef) {
                return catAdr;
            }
            if (userRefs[catAdr].isCat) {
                return catAdr;
            }
        }
        return catAdr;
    }

    function getUser(address addr) external view returns(User memory) {
        return userRefs[addr];
    }

    function setCat(address addr,bool isCat) external onlyOwner{
        userRefs[addr].isCat = isCat;
        if (!userRefs[addr].isSet) {
            isCats.push(addr);
            userRefs[addr].isSet = true;
        }
    }

    function getCats() external view returns(address[] memory) {
        address[] memory cass = isCats;
        for (uint i=0; i<cass.length; i++) {
            if (!userRefs[cass[i]].isCat) {
                cass[i] = address(0);
            }
        }
        return cass;
    }

    function getCatsLen() private view returns(uint256 len) {
        for (uint i=0; i<isCats.length; i++) {
            if (userRefs[isCats[i]].isCat) {
                len++;
            }
        }
        return len;
    }

    function distribute() external onlyOwner {
        for (uint i =0; i < userCats.length; i++) {
            uint256 amountCat = userRefs[userCats[i]].catAmount - userRefs[userCats[i]].debtCatAmount;
            if (amountCat > 0) {
                userRefs[userCats[i]].debtCatAmount = userRefs[userCats[i]].catAmount;
                fil.transfer(userRefs[userCats[i]].addr,amountCat);
            }
        }
        address[] memory userCatNull;
        userCats = userCatNull;
    }

    function getCatsAmount() public view returns (uint256 totalAmount) {
        for (uint i =0; i < userCats.length; i++) {
            uint256 amountCat = userRefs[userCats[i]].catAmount - userRefs[userCats[i]].debtCatAmount;
            totalAmount += amountCat;
        }
        return totalAmount;
    }

    function getDefaultLevel1() external view returns (address[] memory) {
        return defaultLevel1;
    }

    function usersAddr() external view returns(address[] memory) {
        return users;
    }

    function getUserCats() external view returns(address[] memory) {
        return userCats;
    }

    function getSys() external view returns(Sys memory) {
        Sys memory sys = Sys(address(0),0,0,0,0,0,0);
        sys.filAddr = address(fil);
        sys.balance = fil.balanceOf(address(this));
        sys.catsAmount = getCatsAmount();
        sys.usersLen = users.length;
        sys.usersLevel1Len = defaultLevel1.length;
        sys.isCatsLen = getCatsLen();
        sys.totalAmount = users.length * amount;
        return sys;
    }
}
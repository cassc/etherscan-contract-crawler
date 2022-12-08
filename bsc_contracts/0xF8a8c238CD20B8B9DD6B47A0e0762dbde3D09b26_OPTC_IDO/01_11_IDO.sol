// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./INode.sol";
import "./IRefer.sol";
import "./IMining.sol";
import "../router.sol";

contract OPTC_IDO is OwnableUpgradeable {
    IERC20Upgradeable public usdt;
    IERC20Upgradeable public stm;
    INode public node;
    IRefer public refer;
    IMining721 public mining721;
    address public stmPair;
    uint public IDOPrice;


    struct UserInfo {
        bool isBought;
        bool isGetNode;
        uint referIDO;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) public isBought;

    struct UserRecord {
        uint[] amount;
        uint[] time;
        bool[] isSTM;
    }

    mapping(address => UserRecord) userRecord;
    uint public IDOAmount;
    uint public nodeLeft;
    uint public startTime;
    address public wallet;
    modifier onlyEOA{
        require(tx.origin == msg.sender, "only EOA");
        _;
    }

    function initialize() initializer public {
        __Ownable_init();
        IDOPrice = 200 ether;
        nodeLeft = 200;
        IDOAmount = 2500;
        wallet = 0x12AaA8eFa222527eC2ee6ef5E54413a8117a1933;
        stm = IERC20Upgradeable(0xB1AA8fb6e0Ebb360b573aFd94EF4f9eA13be3fe0);
        startTime = 1669626000;
    }

    function setStm(address addr) external onlyOwner {
        stm = IERC20Upgradeable(addr);
    }

    function setUsdt(address addr) external onlyOwner {
        usdt = IERC20Upgradeable(addr);
    }

    function setNode(address addr) external onlyOwner {
        node = INode(addr);
    }

    function setWallet(address addr) external onlyOwner {
        wallet = addr;
    }

    function setStartTime(uint times) external onlyOwner {
        startTime = times;
    }

    function setRefer(address addr) external onlyOwner {
        refer = IRefer(addr);
    }

    function setStmPair(address addr) external onlyOwner {
        stmPair = addr;
    }

    function setNodeLeft(uint amount) external onlyOwner {
        nodeLeft = amount;
    }

    function setMining721(address addr) external onlyOwner {
        mining721 = IMining721(addr);
    }

    function getStmPrice() public view returns (uint){
        (uint reserve0, uint reserve1,) = IPancakePair(stmPair).getReserves();
        if (reserve0 == 0) {
            return 0;
        }
        if (IPancakePair(stmPair).token0() == address(stm)) {
            return reserve1 * 1e18 / reserve0;
        } else {
            return reserve0 * 1e18 / reserve1;
        }
    }

    function bond(address invitor) public onlyEOA {
        require(refer.isRefer(invitor), 'wrong invitor');
        require(refer.checkUserInvitor(msg.sender) == address(0), 'bonded');
        refer.bond(msg.sender, invitor, 0, 0);
    }

    function checkUserRecord(address addr) external view returns (uint[] memory, bool[] memory, uint[] memory){
        return (userRecord[addr].time, userRecord[addr].isSTM, userRecord[addr].amount);
    }

    function sendMining(address[] memory addrs) external onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            node.minInitNode(addrs[i]);
        }
        //        nodeLeft -= addrs.length;
    }

    function sendNode(address[] memory addrs) external onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            mining721.mint(addrs[i], 3, 200 ether);
        }
        IDOAmount += addrs.length;
    }

    function setUserGetNode(address addr, bool b) external onlyOwner {
        userInfo[addr].isGetNode = b;
    }

    function setUserReferIDO(address addr, uint amount) external onlyOwner {
        userInfo[addr].referIDO = amount;
    }

    function buyIDO(bool withStm, address invitor) public onlyEOA {
        require(block.timestamp >= startTime, 'not open');
        require(IDOAmount < 5000, 'sale out');
        require(!userInfo[msg.sender].isBought, 'boughted ido');
        if (refer.checkUserInvitor(msg.sender) == address(0)) {
            require(refer.isRefer(invitor), 'wrong invitor');
            refer.bond(msg.sender, invitor, 0, 0);
        }
        address temp = refer.checkUserInvitor(msg.sender);
        if (!refer.isRefer(msg.sender)) {
            userInfo[temp].referIDO++;
            refer.setIsRefer(msg.sender, true);
        }

        if (!userInfo[temp].isGetNode && userInfo[temp].referIDO >= 10 && nodeLeft > 0) {
            node.minInitNode(temp);
            userInfo[temp].isGetNode = true;
            nodeLeft --;
        }
        if (!withStm) {
            usdt.transferFrom(msg.sender, wallet, IDOPrice);
        } else {
            usdt.transferFrom(msg.sender, wallet, IDOPrice / 2);
            stm.transferFrom(msg.sender, wallet, IDOPrice * 1e18 / 2 / getStmPrice());
        }
        userInfo[msg.sender].isBought = true;
        mining721.mint(msg.sender, 3, 200 ether);
        IDOAmount ++;
    }

    function safePull(address token,address wallet_,uint amount) external onlyOwner{
        IERC20Upgradeable(token).transfer(wallet_,amount);
    }


}
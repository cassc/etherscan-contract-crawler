// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/I721.sol";

contract MT_Box is OwnableUpgradeable {
    I721 public nft;
    IERC20 public U;
    uint randomSeed;
    uint public boxPrice;
    mapping(uint => uint) public cardLeftAmount;

    struct UserInfo {
        uint openAmount;
        uint burnAmount;
        uint exchangeAmount;
    }

    mapping(address => bool) public manager;
    mapping(address => UserInfo) public userInfo;
    uint public resetPrice;

    event Reward(address indexed addr, uint indexed reward); //
    uint public startTime;
    uint public endTime;
    bool public status;
    address public main;
    address public walletAddress;
    mapping(address => uint) public userWhiteAmount;
    address public openWallet;
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        boxPrice = 1000 ether;
        cardLeftAmount[0] = 200;
        cardLeftAmount[1] = 0;
        cardLeftAmount[2] = 200;
        cardLeftAmount[3] = 200;
        cardLeftAmount[4] = 0;
        cardLeftAmount[5] = 200;
        cardLeftAmount[6] = 200;
        cardLeftAmount[7] = 0;
        cardLeftAmount[8] = 200;
        cardLeftAmount[9] = 200;
        cardLeftAmount[10] = 0;
        cardLeftAmount[11] = 0;
        resetPrice = 10 ether;
        U = IERC20(0x55d398326f99059fF775485246999027B3197955);
    }

    modifier checkTime() {
        require(block.timestamp >= startTime, "not start yet");
        require(block.timestamp < endTime, "the round is end");
        _;
    }

    modifier onlyManager() {
        require(manager[msg.sender], "not manager");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not allowed");
        _;
    }

    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    randomSeed,
                    _length
                )
            )
        );
        randomSeed += block.timestamp;
        return (random % _length) + 1;
    }

    function setU(address addr) external onlyOwner {
        U = IERC20(addr);
    }

    function setTime(uint start, uint end) external onlyOwner {
        startTime = start;
        endTime = end;
    }

    function setNFT(address addr) external onlyOwner {
        nft = I721(addr);
    }

    function setPrice(uint price_) external onlyOwner {
        boxPrice = price_;
    }

    function setMain(address addr) external onlyOwner {
        main = addr;
    }

    function setWallet(address addr) external onlyOwner {
        walletAddress = addr;
    }

    function setManagerList(address[] memory addrs, bool b) external onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            manager[addrs[i]] = b;
        }
    }

    function checkAllCardAmount() public view returns (uint[] memory list) {
        list = new uint[](12);
        for (uint i = 0; i < 12; i++) {
            list[i] = cardLeftAmount[i];
        }
    }

    function setCardAmount(uint index, uint amount) external onlyManager {
        require(amount <= nft.checkCardLeft(index + 1), "ouf of amount");
        cardLeftAmount[index] = amount;
    }

    function getTotalAmount() public view returns (uint) {
        uint out = 0;
        for (uint i = 0; i < 12; i++) {
            out += cardLeftAmount[i];
        }
        return out;
    }

    function setOpenWallet(address addr) external onlyOwner {
        openWallet = addr;
    }

    function checkAllCardLeft() public view returns (uint) {
        uint temp;
        for (uint i = 1; i <= 12; i++) {
            temp += nft.checkCardLeft(i);
        }
        return temp;
    }

    function checkCardLeftBatch() public view returns (uint[] memory lists) {
        lists = new uint[](12);
        for (uint i = 1; i <= 12; i++) {
            lists[i - 1] = nft.checkCardLeft(i);
        }
    }

    function _processOpen(address addr) internal {
        uint out = rand(getTotalAmount());
        uint rew = 11;
        uint count;
        for (uint i = 0; i < 12; i++) {
            count += cardLeftAmount[i];
            if (out < count) {
                rew = i;
                cardLeftAmount[i]--;
                break;
            }
        }

        nft.mint(addr, rew + 1);
        emit Reward(addr, rew + 1);
    }

    function OpenCard(uint amount) external checkTime onlyEOA {
        uint cost;
        if (userWhiteAmount[msg.sender] >= amount) {
            userWhiteAmount[msg.sender] -= amount;
        } else if (userWhiteAmount[msg.sender] == 0) {
            cost = amount * boxPrice;
        } else {
            cost = (amount - userWhiteAmount[msg.sender]) * boxPrice;
            userWhiteAmount[msg.sender] = 0;
        }

        if (cost > 0) {
            U.transferFrom(msg.sender, openWallet, cost);
        }

        for (uint i = 0; i < amount; i++) {
            _processOpen(msg.sender);
        }
        userInfo[msg.sender].openAmount += amount;
    }

    function exchangeCard(uint tokenID) external onlyEOA {
        U.transferFrom(msg.sender, main, (resetPrice * 2) / 10);
        U.transferFrom(msg.sender, walletAddress, (resetPrice * 8) / 10);
        nft.burn(tokenID);
        cardLeftAmount[nft.cardIdMap(tokenID)]++;
        _processOpen(msg.sender);
        userInfo[msg.sender].exchangeAmount++;
    }

    function burnCard(uint tokenID) external onlyEOA {
        nft.safeTransferFrom(msg.sender, address(this), tokenID);
        userInfo[msg.sender].burnAmount++;
    }

    function setWhiteBoxAmount(address[] memory addrs, uint[] memory amounts)
        external
        onlyManager
    {
        for (uint i = 0; i < addrs.length; i++) {
            userWhiteAmount[addrs[i]] = amounts[i];
        }
    }

    function reSetLeftAmount() external onlyManager {
        uint temp;
        for (uint i = 1; i <= 12; i++) {
            temp = nft.checkCardLeft(i);
            if (temp < cardLeftAmount[i - 1]) {
                cardLeftAmount[i - 1] = temp;
            }
        }
    }

    function safePull(
        address token,
        address wallet,
        uint amount
    ) external onlyOwner {
        IERC20(token).transfer(wallet, amount);
    }
}
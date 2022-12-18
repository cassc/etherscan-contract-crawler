// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./INode721.sol";
import "./IRefer.sol";

interface IStake {
    function upNodePower(address addr, uint tokenId, uint costs) external;

    function nodeOwner(uint tokenId) external view returns (address);

    function getNodeId(address addr, uint nodeId) external pure returns (uint);

    function checkUserNodeID(address addr) external view returns (uint);

}

contract nodeShare is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public OPTC;
    INode721 public node;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint public maxInitNode;

    uint public maxBurnAmount;
    uint public maxSuperNode; //main
    IStake public stake;

    struct CardInfo {
        uint debt;
    }

    uint public nodePrice;
    uint public debt;
    mapping(uint => CardInfo) public cardInfo;
    mapping(address => uint) public claimed;
    mapping(address => bool) public admin;
    uint public totalInitNode;
    //    uint public totalNode;

    IRefer public refer;
    //    uint public maxSuperNode;//test
    uint public totalSuperNode;
    uint public superWeight;
    uint public superDebt;
    bool public status;
    mapping(uint => uint) public superCardDebt;
    mapping(address => uint) public userToClaim;

    bool public pause;

    function initialize() initializer public {
        __Ownable_init_unchained();
        maxInitNode = 300;
        nodePrice = 100e18;
        maxBurnAmount = 2000e18;
        admin[msg.sender] = true;
        maxSuperNode = 300;
    }
    modifier onlyEOA{
        require(tx.origin == msg.sender, "only EOA");
        _;
    }

    function setNode(address addr) external onlyOwner {
        node = INode721(addr);
    }

    function setRefer(address addr) external onlyOwner {
        refer = IRefer(addr);
    }

    function setStatus(bool b) external onlyOwner {
        status = b;
    }

    function setPause(bool b) external onlyOwner {
        pause = b;
    }

    function setAdmin(address addr, bool b) external onlyOwner {
        admin[addr] = b;
    }

    function setStake(address addr) external onlyOwner {
        stake = IStake(addr);
    }

    function setOPTC(address addr) external onlyOwner {
        OPTC = IERC20Upgradeable(addr);
        admin[addr] = true;
    }

    function getTotalNode() public view returns (uint){
        return node.totalNode();
    }


    function _calculateReward(uint tokenId) public view returns (uint){
        uint reward = (debt - cardInfo[tokenId].debt) * node.getCardWeight(tokenId);
        return reward;
    }

    function setSuperNode(uint amount) external onlyOwner {
        maxSuperNode = amount;
    }

    function syncSuperDebt(uint amount) external {
        require(admin[msg.sender], 'not admin');
        uint totalNode = superWeight;
        if (totalNode == 0) {
            OPTC.transfer(0x20469A4707f1610eb5544c33A62C2DB525bD8396, amount);
            return;
        }
        superDebt += amount / totalNode;
    }

    function calculateReward(address addr) public view returns (uint){
        uint[] memory lists = node.checkUserTokenList(addr);
        uint rew;
        for (uint i = 0; i < lists.length; i++) {
            if (node.cid(lists[i]) == 1) {
                rew += _calculateReward(lists[i]);
            } else if (node.cid(lists[i]) == 2) {
                rew += _calculateSuperReward(lists[i]);
                rew += _calculateReward(lists[i]);
            }
        }
        uint tempId = stake.checkUserNodeID(addr);
        if (tempId != 0) {
            rew += _calculateSuperReward(tempId);
        }
        rew += userToClaim[addr];
        return rew;
    }


    function syncDebt(uint amount) external {
        require(admin[msg.sender], 'not admin');
        uint totalNode = getTotalNode();
        if (totalNode == 0) {
            return;
        }
        debt += amount / totalNode;
    }

    function _calculateSuperReward(uint tokenId) public view returns (uint){
        uint reward = (superDebt - superCardDebt[tokenId]) * node.getCardWeight(tokenId);
        return reward;
    }


    function claim() external {
        require(!pause, 'pause');
        uint[] memory lists = node.checkUserTokenList(msg.sender);
        uint tempId = stake.checkUserNodeID(msg.sender);
        require(lists.length > 0 || tempId != 0, 'no card');
        uint rew;
        for (uint i = 0; i < lists.length; i++) {
            if (node.cid(lists[i]) == 1) {
                rew += _calculateReward(lists[i]);
                cardInfo[lists[i]].debt = debt;
            } else if (node.cid(lists[i]) == 2) {
                rew += _calculateReward(lists[i]);
                rew += _calculateSuperReward(lists[i]);
                cardInfo[lists[i]].debt = debt;
                superCardDebt[lists[i]] = superDebt;
            }

        }

        if (tempId != 0) {
            rew += _calculateSuperReward(tempId);
            cardInfo[tempId].debt = superDebt;
        }
        rew += userToClaim[msg.sender];
        userToClaim[msg.sender] = 0;
        OPTC.transfer(msg.sender, rew);
        claimed[msg.sender] += rew;
    }


    function minInitNode(address addr) external {
        require(admin[msg.sender], 'not admin');
        require(totalInitNode + 1 <= maxInitNode, 'out of max');
        totalInitNode ++;
        cardInfo[node.currentId()].debt = debt;
        node.mint(addr, 1, 0);
    }

    function setInitNode(uint total) external onlyOwner {
        totalInitNode = total;
    }

    function reSend(address[] memory addr) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            //            cardInfo[node.currentId()].debt = debt;
            node.mint(addr[i], 1, 0);
        }
    }

    function applySuperNode(uint costs) external onlyEOA {
        require(OPTC.balanceOf(burnAddress) > 30000 ether, 'not start');
        require(costs % nodePrice == 0, 'must be int');
        require(refer.getUserLevel(msg.sender) >= 2, 'not level');
        require(totalSuperNode < maxSuperNode, 'out of max');
        uint[] memory lists = node.checkUserCidList(msg.sender, 2);
        require(lists.length == 0 && stake.checkUserNodeID(msg.sender) == 0, 'have super node');
        OPTC.transferFrom(msg.sender, burnAddress, costs);
        cardInfo[node.currentId()].debt = debt;
        superCardDebt[node.currentId()] = superDebt;
        uint id = node.currentId();
        node.mint(msg.sender, 2, costs);
        node.updateTokenCost(id, 100 ether);
        totalSuperNode ++;
        superWeight += 1 + (costs / nodePrice);
        require(node.getCardWeight(id) <= 21, 'out of max');

    }

    function burnForNode(uint tokenId, uint amount) external {
        require(amount % nodePrice == 0, 'must be int');
        require(node.ownerOf(tokenId) == msg.sender || stake.nodeOwner(tokenId) == msg.sender, 'not owner');
        if (stake.nodeOwner(tokenId) == msg.sender) {
            stake.upNodePower(msg.sender, tokenId, amount);
        }
        node.updateTokenCost(tokenId, amount);
        OPTC.transferFrom(msg.sender, burnAddress, amount);
        userToClaim[msg.sender] += _calculateReward(tokenId);
        userToClaim[msg.sender] += _calculateSuperReward(tokenId);
        superCardDebt[tokenId] = superDebt;
        cardInfo[tokenId].debt = debt;
        superWeight += (amount / nodePrice);
        require(node.getCardWeight(tokenId) <= 21, 'out of max');
    }

    function checkNodeInfo(address addr) external view returns (uint initNode,
        uint superNode,
        uint refer_n,
        uint costs,
        uint totalInit,
        uint totalSuper,
        uint totalWetight,
        uint toClaim){
        initNode = node.checkUserCidList(addr, 1).length;
        superNode = node.checkUserCidList(addr, 2).length;
        refer_n = refer.getUserRefer(addr);
        costs = 0;
        if (stake.checkUserNodeID(addr) != 0) {
            costs = (node.getCardWeight(stake.checkUserNodeID(addr)) - 1) * 100e18;
        }

        totalInit = totalInitNode;
        totalSuper = totalSuperNode;
        if (stake.checkUserNodeID(addr) != 0) {
            superNode ++;
        }
        totalWetight = node.checkUserAllWeight(addr) + node.getCardWeight(stake.checkUserNodeID(addr));
        toClaim = calculateReward(addr);
    }


}
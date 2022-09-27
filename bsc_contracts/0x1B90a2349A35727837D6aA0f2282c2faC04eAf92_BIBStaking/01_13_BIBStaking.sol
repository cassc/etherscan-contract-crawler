pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IBIBNode.sol";
import "../interfaces/IBIBDividend.sol";
import "../interfaces/ISoccerStarNft.sol";
import "../lib/StructuredLinkedList.sol";

contract BIBStaking is PausableUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    using StructuredLinkedList for StructuredLinkedList.List;
    
    struct BIBFreeze {
        uint256 amount;
        uint256 expireTime;
    }
    struct Node {
        uint256 stakingAmount;
        uint256 expireTime;
        address owner;
    }

    StructuredLinkedList.List list;
    IBIBNode public BIBNode;
    // BIB token address
    IERC20Upgradeable public BIBToken;
    IBIBDividend public BIBDividend;
    ISoccerStarNft public soccerStarNft;
    
    uint256 public freezeTime;
    uint256 public stakeCapTimes;
    uint256 public topNodeCount;
    uint256[] public nodeWigth;
    mapping(uint256 => uint256) public maxSetupAmount;
    // user -> stake node list
    mapping(address => uint256[]) public stakeNodesMap;
    mapping(address => BIBFreeze[]) public userFreezeMap;
    // node -> stake user list
    mapping(uint256 => address[]) public nodeStakedUsers;
    mapping(uint256 => mapping(address => uint256)) public nodeStakedDetail;
    mapping(uint256 => Node) public nodeMap;
    
    uint256 public gasForProcessing;
    event UpdateMaxSetUp(uint256 indexed level, uint256 newMaxSetUp);
    event SuperNode(uint256 ticketId);
    event UnSuperNode(uint256 ticketId);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event Staking(
        address indexed user,
        uint256 indexed ticketId,
        uint256 bibAmount
    );

    event UnStaking(
        address indexed user,
        uint256 indexed ticketId,
        uint256 bibAmount
    );

    modifier onlyNode {
        require(msg.sender == address(BIBNode), "ONLY_NODE");
        _;
    }

    function initialize(
        address _bibToken,
        address _bibNode, 
        address _bibDividend, 
        address _soccerStarNft
        ) reinitializer(1) public {
        BIBToken = IERC20Upgradeable(_bibToken);
        BIBNode = IBIBNode(_bibNode);
        BIBDividend = IBIBDividend(_bibDividend);
        soccerStarNft = ISoccerStarNft(_soccerStarNft);
        __Pausable_init();
        __Ownable_init();
        maxSetupAmount[3] = 200000*10**18;
        maxSetupAmount[4] = 2000000*10**18;
        
        freezeTime = 7 days;
        stakeCapTimes = 50;
        topNodeCount = 30;
        nodeWigth = [100, 90, 80, 72];
        gasForProcessing = 0;
    }

    function createNode(address operator, uint256 _ticket, uint256 _bibAmount) external onlyNode {
        Node storage node = nodeMap[_ticket];
        require(node.stakingAmount == 0, "Node is exist");
        require(getAvailableAmount(operator) >= _bibAmount, "Insufficient balance");
        node.stakingAmount = _bibAmount;
        node.owner = operator;
        nodeStakedUsers[_ticket].push(operator);
        stakeNodesMap[operator].push(_ticket);
        nodeStakedDetail[_ticket][operator] = _bibAmount;
        emit Staking(operator, _ticket, _bibAmount);
        updataNodeWigth(_ticket);
        require(getNodeMaxStake(_ticket) >= _bibAmount, "Limit exceeded");
       _setUserBalance(operator, _ticket, _bibAmount);
    }

    function disbandNode(address operator, uint256 _ticket) external onlyNode {
        Node storage node = nodeMap[_ticket];
        require(node.stakingAmount >= 0, "Node is not exist");
        node.expireTime = _currentTime().add(freezeTime);
        node.stakingAmount = 0;
        updataNodeWigth(_ticket);
    }

    function transferNodeSetUp(address from, address to, uint256 _ticket) external onlyNode {
        Node storage node = nodeMap[_ticket];
        require(node.stakingAmount >= 0, "Node is not exist");
        uint256 defaultSetUpAmount = maxSetupAmount[getLevelByTicket(_ticket)];
        uint256 fromUserStake = nodeStakedDetail[_ticket][from];
        uint256 transferAmount = defaultSetUpAmount < fromUserStake ? defaultSetUpAmount : fromUserStake;
        node.owner = to;
        if (nodeStakedDetail[_ticket][to] == 0) {
            nodeStakedUsers[_ticket].push(to);
            stakeNodesMap[to].push(_ticket);
        }
        nodeStakedDetail[_ticket][to] = nodeStakedDetail[_ticket][to].add(transferAmount);
        if (nodeStakedDetail[_ticket][from] == transferAmount) {
            deleteUserStakeNode(from, _ticket);
        } else {
            nodeStakedDetail[_ticket][from] = nodeStakedDetail[_ticket][from].sub(transferAmount);
        }
        // walk-around to resolve 10% tx fee on bib token
        BIBToken.transferFrom(from, address(this), transferAmount);
        BIBToken.transfer(to, transferAmount);
        
       _setUserBalance(from, _ticket, nodeStakedDetail[_ticket][from]);
       _setUserBalance(to, _ticket, nodeStakedDetail[_ticket][to]);
       BIBDividend.transferNode(from, to);
    }

    function nodeStake(uint256 _from, uint256 _to) external onlyNode returns(uint256){
        uint256 _amount = nodeMap[_from].stakingAmount;
        if (list.sizeOf() > topNodeCount && isTopNode(_from)) {
            uint256 _lastTicket = list.getNodeByIndex(topNodeCount);
            _setNodeBalance(nodeMap[_lastTicket].owner, _calcAmount(nodeMap[_lastTicket].stakingAmount, 0), _lastTicket, nodeWigth[0]);
        }
        list.remove(_from);
        uint256 level = 3;
        if (isTopNode(_to)) level = 1;
        _setNodeBalance(nodeMap[_from].owner, _calcAmount(_amount, level), _from, nodeWigth[level]);
        return _amount;
    }

    function nodeUnStake(uint256 _from, uint256 _to) external onlyNode returns(uint256){
        updataNodeWigth(_from);
        return nodeMap[_from].stakingAmount;
    }

    function updateStake(uint256[] calldata _tickets, uint256[] calldata _bibAmounts) external {
        require(_tickets.length == _bibAmounts.length, "Invalid args");
        address operator = _msgSender();
        uint256 _stakeTotal = 0;
        uint256 _unStakeTotal = 0;
        uint256 availableAmount = getAvailableAmount(operator);
        for(uint256 i=0;i<_tickets.length;i++){
            uint256 alreadyStake = nodeStakedDetail[_tickets[i]][operator];
            if (_bibAmounts[i] == alreadyStake) {
                continue;
            } else if (_bibAmounts[i] > alreadyStake) {
                uint256 _stakeAmount = _bibAmounts[i].sub(alreadyStake);
                _stakeTotal = _stakeTotal.add(_stakeAmount);
                _stake(operator, _tickets[i], _stakeAmount);
            } else if (_bibAmounts[i] < alreadyStake) {
                uint256 _unStakeAmount = alreadyStake.sub(_bibAmounts[i]);
                _unStakeTotal = _unStakeTotal.add(_unStakeAmount);
                _unStake(operator, _tickets[i], _unStakeAmount);
            }
            if(list.nodeExists(_tickets[i])) updataNodeWigth(_tickets[i]);
            else {
                uint256 upTicket = BIBNode.nodeMap(_tickets[i]).upNode;
                uint256 _amount = nodeMap[_tickets[i]].stakingAmount;
                uint256 level = 3;
                if (isTopNode(upTicket)) level = 1;
                _setNodeBalance(nodeMap[_tickets[i]].owner, _calcAmount(_amount, level), _tickets[i], nodeWigth[level]);
            }
            _setUserBalance(operator, _tickets[i], nodeStakedDetail[_tickets[i]][operator]);
        }
        if (_stakeTotal >= _unStakeTotal) {
            require(availableAmount >= _stakeTotal.sub(_unStakeTotal), "Insufficient balance");
        } else {
            userFreezeMap[operator].push(BIBFreeze({
                amount: _unStakeTotal.sub(_stakeTotal),
                expireTime: _currentTime().add(freezeTime)
            }));
        }
        freeExpireStake(operator);
        try BIBDividend.process(gasForProcessing) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
            emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gasForProcessing, tx.origin);
        } 
        catch {}
    }

    function _stake(address operator, uint256 _ticket, uint256 _bibAmount) internal returns(bool) {
        Node storage node = nodeMap[_ticket];
        require(node.expireTime == 0, "Node not exist");
        if (nodeStakedDetail[_ticket][operator] == 0) {
            nodeStakedUsers[_ticket].push(operator);
            stakeNodesMap[operator].push(_ticket);
        }
        nodeStakedDetail[_ticket][operator] = nodeStakedDetail[_ticket][operator].add(_bibAmount);
        node.stakingAmount = node.stakingAmount.add(_bibAmount);
        require(getNodeCurrentMaxStake(_ticket) >= node.stakingAmount, "Limit exceeded");
        emit Staking(operator, _ticket, _bibAmount);
        return true;
    }
    
    function _unStake(address operator, uint256 _ticket, uint256 _bibAmount) internal returns(bool) {
        Node storage node = nodeMap[_ticket];
        uint256 stakeAmount = nodeStakedDetail[_ticket][operator];
        if (operator == node.owner) {
            require(getNodeMinStake(_ticket) <= stakeAmount.sub(_bibAmount), "Min setup limit");
        }
        node.stakingAmount = node.stakingAmount.sub(_bibAmount);
        if (stakeAmount == _bibAmount) {
            deleteUserStakeNode(operator, _ticket);
        } else {
            nodeStakedDetail[_ticket][operator] = stakeAmount.sub(_bibAmount);
        }
        emit UnStaking(operator, _ticket, _bibAmount);
        return true;
    }

    function deleteUserStakeNode(address _account, uint256 _ticket) internal {
        address[] storage stakedUserList = nodeStakedUsers[_ticket];
        uint256 index = stakedUserList.length;
        while(index > 0) {
            index--;
            if (stakedUserList[index] == _account) {
                stakedUserList[index] = stakedUserList[stakedUserList.length-1];
                stakedUserList.pop();
                break;
            }
        }
        delete nodeStakedDetail[_ticket][_account];
        uint256[] storage list = stakeNodesMap[_account];
        uint256 i = list.length;
        while (i > 0){
            i--;
            if (list[i] == _ticket){
                list[i] = list[list.length-1];
                list.pop();
                break;
            }
        }
    }

    function freeExpireStake(address _account) internal {
        BIBFreeze[] storage list = userFreezeMap[_account];
        uint256 i = list.length;
        while (i > 0){
            i--;
            if (list[i].expireTime < _currentTime()){
                list[i] = list[list.length-1];
                list.pop();
            }
        }
    }

    function setSoccerStarNft(address _soccerStarNft) external onlyOwner {
        soccerStarNft = ISoccerStarNft(_soccerStarNft);
    }

    function setBIBToken(address _bibToken) external onlyOwner {
        BIBToken = IERC20Upgradeable(_bibToken);
    }

    function setNodeWeight(uint256[] memory _nodeWigth) external onlyOwner {
        require(_nodeWigth.length >=4, "Invalid config");
        nodeWigth = _nodeWigth;
    }
    function setTopNodeCount(uint256 c) external onlyOwner{
        topNodeCount = c;
    }
    function setFreezeTime(uint256 times) external onlyOwner {
        freezeTime = times;
    }
    function setStakeCapTimes(uint256 times) external onlyOwner {
        stakeCapTimes = times;
    }
    function setMaxSetupAmount(uint256 level, uint256 setupAmount) external onlyOwner {
        maxSetupAmount[level] = setupAmount;
        emit UpdateMaxSetUp(level, setupAmount);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        gasForProcessing = newValue;
    }
    
    function getAvailableAmount(address _account) public view returns(uint256) {
        return BIBToken.balanceOf(_account).sub(getFreezeAmount(_account));
    }

    function getFreezeAmount(address _account) public view returns(uint256) {
        uint256[] memory list = stakeNodesMap[_account];
        uint256 freezeAmount;
        for (uint256 i=0;i<list.length;i++){
            if(nodeMap[list[i]].expireTime == 0 || nodeMap[list[i]].expireTime >= _currentTime()) {
                freezeAmount = freezeAmount.add(nodeStakedDetail[list[i]][_account]);
            }
        }
        BIBFreeze[] memory flist = userFreezeMap[_account];
        for (uint256 i=0;i<flist.length;i++){
            if(flist[i].expireTime >= _currentTime()) {
                freezeAmount = freezeAmount.add(flist[i].amount);
            }
        }

        return freezeAmount;
    }

    function getUserStakeList(address _account) public view returns (uint256[] memory nodeList, uint256[] memory stakeDetail){
        nodeList = stakeNodesMap[_account];
        stakeDetail = new uint256[](nodeList.length);
        for (uint256 i=0;i<nodeList.length;i++){
            stakeDetail[i] = nodeStakedDetail[nodeList[i]][_account];
        }
    }

    function getUserStakeAmount(address _account) public view returns(uint256) {
        uint256[] memory list = stakeNodesMap[_account];
        uint256 _stakeAmount;
        for (uint256 i=0;i<list.length;i++){
            if(nodeMap[list[i]].expireTime == 0) {
                _stakeAmount = _stakeAmount.add(nodeStakedDetail[list[i]][_account]);
            }
        }
        return _stakeAmount;
    }

    function getNodeStakingList(uint256 _ticket) public view returns(address[] memory) {
        return nodeStakedUsers[_ticket];
    }

    function getNodeStakeAmount(uint256 _ticket) external view returns(uint256) {
        return nodeMap[_ticket].stakingAmount;
    }

    function getNodeMaxStake(uint256 _ticketId) public view returns(uint256) {
        return maxSetupAmount[getLevelByTicket(_ticketId)].mul(stakeCapTimes);
    }

    function getLevelByTicket(uint256 _ticketId) public view returns (uint256) {
        uint256 _cardId = BIBNode.nodeMap(_ticketId).cardNftId;
        ISoccerStarNft.SoccerStar memory card = soccerStarNft.getCardProperty(_cardId);
        return card.starLevel;
    }

    function getNodeMinStake(uint256 _ticketId) public view returns(uint256) {
        return nodeMap[_ticketId].stakingAmount.div(stakeCapTimes);
    }

    function getNodeCurrentMaxStake(uint256 _ticketId) public view returns(uint256) {
        uint256 _max = getNodeMaxStake(_ticketId);
        address _owner = nodeMap[_ticketId].owner;
        uint256 _setup = nodeStakedDetail[_ticketId][_owner];
        uint256 _currentMaxStake = _setup.mul(stakeCapTimes);
        return _max <= _currentMaxStake ? _max : _currentMaxStake;
    }

    function isTopNode(uint256 _ticketId) public view returns(bool) {
        if (list.sizeOf() < topNodeCount) return true;
        uint256 rank = list.getIndex(_ticketId);
        // rank start from 0
        return rank < topNodeCount;
    }

    function updataNodeWigth(uint256 _ticketId) private{
        uint256 rank = list.getIndex(_ticketId) + 1;
        list.remove(_ticketId);
        uint256 _amount = nodeMap[_ticketId].stakingAmount;
        address nodeOwner = nodeMap[_ticketId].owner;
        uint256 newRank = list.sizeOf() + 1;

        if (_amount > 0) {
            uint256 p = list.getSortedSpot(address(this), _amount);
            list.insertBefore(p, _ticketId);
            newRank = list.getIndex(_ticketId) + 1;
            uint256 level = 2;
            if (newRank <= topNodeCount) level = 0;
            _setNodeBalance(nodeOwner, _calcAmount(_amount, level), _ticketId, nodeWigth[level]);
        } else if (_amount == 0) {
            BIBDividend.disbandNode(nodeMap[_ticketId].owner, _ticketId);
        }
        uint256 _lastTicketIndex;
        uint256 _lastLevel;
        if (rank <= topNodeCount && newRank > topNodeCount) {
            _lastLevel = 0;
            _lastTicketIndex = topNodeCount-1;
        } else if (rank > topNodeCount && newRank <= topNodeCount) {
            _lastLevel = 2;
            _lastTicketIndex = topNodeCount;
        } else {
            return;
        }
        uint256 _lastTicket = list.getNodeByIndex(_lastTicketIndex);
        _setNodeBalance(nodeMap[_lastTicket].owner, _calcAmount(nodeMap[_lastTicket].stakingAmount, _lastLevel), _lastTicket, nodeWigth[_lastLevel]);
    }

    function _setUserBalance(address user, uint256 ticketId, uint256 amount) internal {
        BIBDividend.setUserBalance(user, ticketId, amount);
    }

    function _setNodeBalance(address nodeOwner, uint256 amount, uint256 ticketId, uint256 weight) internal {
        BIBDividend.setNodeBalance(nodeOwner, amount, ticketId, weight);
        if (weight == nodeWigth[0]) {
            emit SuperNode(ticketId);
        } else {
            emit UnSuperNode(ticketId);
        }
    }

    function _calcAmount(uint256 amount, uint256 level) internal view returns(uint256){
        return amount.mul(nodeWigth[level]).div(100);
    }

    function _currentTime() internal virtual view returns (uint256) {
        return block.timestamp;
    }

}
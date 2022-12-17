// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "./IMining.sol";
import "./INode721.sol";
import "../router.sol";
import "./IRefer.sol";
import "./IOPTC.sol";
import "./INode.sol";

contract OPTC_Stake is OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IOPTC public OPTC;
    IMining721 public nft;
    INode721 public node;
    IERC20Upgradeable public U;
    IPancakeRouter02 public router;
    IRefer public refer;
    mapping(uint => address) public nodeOwner;
    uint constant acc = 1e10;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint public TVL;
    uint public debt;
    uint public lastTime;
    uint randomSeed;
    uint[] reBuyRate;
    uint public dailyOut;
    uint public rate;


    struct UserInfo {
        uint totalPower;
        uint claimed;
        uint nodeId;
        uint toClaim;
        uint[] cardList;
    }

    struct SlotInfo {
        address owner;
        uint power;
        uint leftQuota;
        uint debt;
        uint toClaim;
    }

    mapping(address => uint) public lastBuy;
    mapping(address => UserInfo) public userInfo;
    mapping(uint => SlotInfo) public slotInfo;
    mapping(address => bool) public admin;
    address public pair;
    uint[] randomRate;
    uint public startTime;

    address public market;
    INode public nodeShare;
    mapping(address => uint) public userTotalValue;
    bool public pause;
    event BuyCard(address indexed addr, uint indexed amount, uint indexed times);

    function initialize() initializer public {
        __Ownable_init_unchained();
        __ERC721Holder_init_unchained();
        dailyOut = 2000 ether;
        randomRate = [40, 70, 85, 95];
        reBuyRate = [80, 9, 11];
        rate = dailyOut / 86400;
        market = 0x679Bf5F1a373c977fC411469B7f838C69C28845E;
        startTime = 1670576400;
    }

    modifier onlyEOA{
        require(tx.origin == msg.sender, "only EOA");
        _;
    }

    modifier checkStart{
        require(block.timestamp > startTime, "not start");
        _;
    }

    modifier updateDaily{
        uint balance = OPTC.balanceOf(burnAddress);
        if (balance != 0 || dailyOut > 1000 ether) {
            uint temp = balance / 30000 ether;
            if (temp > 5) {
                temp = 5;
            }
            uint tempOut = 2000 ether - temp * 200 ether;
            if (tempOut != dailyOut) {
                debt = countingDebt();
                dailyOut = tempOut;
                rate = dailyOut / 86400;
            }
        }
        _;

    }

    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed)));
        randomSeed ++;
        return random % _length + 1;
    }

    function setPause(bool b )external onlyOwner{
        pause = b;
    }

    function setNodeShare(address addr) external onlyOwner {
        nodeShare = INode(addr);
    }

    function setAdmin(address _admin, bool _status) external onlyOwner {
        admin[_admin] = _status;
    }

    function setStartTime(uint times) external onlyOwner {
        startTime = times;
    }

    function setReBuyRate(uint[] memory rate_) external onlyOwner {
        reBuyRate = rate_;
    }

    function setMarket(address addr) external onlyOwner {
        market = addr;
    }

    function setAddress(address OPTC_, address nft_, address node_, address U_, address router_, address refer_) public onlyOwner {
        OPTC = IOPTC(OPTC_);
        nft = IMining721(nft_);
        node = INode721(node_);
        U = IERC20Upgradeable(U_);
        router = IPancakeRouter02(router_);
        refer = IRefer(refer_);
        pair = IPancakeFactory(router.factory()).getPair(OPTC_, U_);
    }

    function countingDebt() internal view returns (uint _debt){
        _debt = TVL > 0 ? rate * (block.timestamp - lastTime) * acc / TVL + debt : 0 + debt;
    }

    function buyCard(uint amount, address invitor) external onlyEOA updateDaily {
        require(!pause,'pause');
        require(block.timestamp > startTime, "not start");
        require(amount >= 200 ether && amount <= 20000 ether, 'less than min');
        require(lastBuy[msg.sender] + 1 days < block.timestamp, "too fast");
        lastBuy[msg.sender] = block.timestamp;
        uint times = _processCard();
        nft.mint(msg.sender, times, amount);
        uint uAmount = amount / 2;
        uint optcAmount = getOptAmount(uAmount, getOPTCPrice());
        U.approve(address(router), uAmount);
        OPTC.approve(address(router), optcAmount);
        U.transferFrom(msg.sender, address(this), uAmount);
        OPTC.transferFrom(msg.sender, address(this), optcAmount);
        uint reward;
        {
            uint _lastBalance = OPTC.balanceOf(address(refer));
            _processCardBuy(uAmount, optcAmount);
            uint _nowBalance = OPTC.balanceOf(address(refer));
            reward = _nowBalance - _lastBalance;
        }

        refer.bond(msg.sender, invitor, reward, amount);
        if (!refer.isRefer(msg.sender)) {
            refer.setIsRefer(msg.sender, true);
        }
        userTotalValue[msg.sender] += amount;
        emit BuyCard(msg.sender, amount, times);
    }

    function getOPTCLastPrice() public view returns (uint){
        return OPTC.lastPrice();
    }

    function stakeCard(uint tokenId) external onlyEOA updateDaily {
        require(!pause,'pause');
        refer.updateReferList(msg.sender);
        UserInfo storage user = userInfo[msg.sender];
        require(user.cardList.length < 10, "out of limit");
        uint power = nft.checkCardPower(tokenId);
        uint _debt = countingDebt();
        user.totalPower += power;
        user.cardList.push(tokenId);
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        SlotInfo storage slot = slotInfo[tokenId];
        slot.owner = msg.sender;
        slot.power += power;
        slot.debt = _debt;
        slot.leftQuota = power;
        _addPower(power, _debt);
    }

    function stakeCardBatch(uint[] memory tokenIds) external onlyEOA updateDaily {
        require(!pause,'pause');
        uint _debt = countingDebt();
        UserInfo storage user = userInfo[msg.sender];
        require(user.cardList.length + tokenIds.length <= 10, "out of limit");
        refer.updateReferList(msg.sender);
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            //            require(user.cardList.length < 10, "out of limit");
            uint power = nft.checkCardPower(tokenId);
            user.totalPower += power;
            user.cardList.push(tokenId);
            nft.safeTransferFrom(msg.sender, address(this), tokenId);
            SlotInfo storage slot = slotInfo[tokenId];
            slot.owner = msg.sender;
            slot.power += power;
            slot.debt = _debt;
            slot.leftQuota = power;
            _addPower(power, _debt);
        }
    }

    function _calculateReward(uint tokenId, uint price) public view returns (uint rew, bool isOut){
        SlotInfo storage slot = slotInfo[tokenId];
        uint _debt = countingDebt();
        uint _power = slot.power;
        uint _debtDiff = _debt - slot.debt;
        rew = _power * _debtDiff / acc;
        uint maxAmount = getOptAmount(slot.leftQuota, price);
        if (rew >= maxAmount) {
            rew = maxAmount;
            isOut = true;
        }
        if (slot.leftQuota < slot.power / 20) {
            isOut = true;
        }
    }

    function calculateRewardAll(address addr) public view returns (uint rew){
        UserInfo storage user = userInfo[addr];
        uint price = OPTC.lastPrice();
        uint _rew;
        for (uint i = 0; i < user.cardList.length; i++) {
            (_rew,) = _calculateReward(user.cardList[i], price);
            rew += _rew;
        }
        if (user.nodeId != 0) {
            (_rew,) = _calculateReward(getNodeId(addr, user.nodeId), price);
            rew += _rew + slotInfo[getNodeId(addr, user.nodeId)].toClaim;
        }
        return rew;
    }

    function claimAllReward() external onlyEOA updateDaily {
        require(!pause,'pause');
        UserInfo storage user = userInfo[msg.sender];
        uint rew;
        uint _debt = countingDebt();
        uint price = OPTC.lastPrice();
        uint nodeRew = 0;
        uint totalOut;
        {
            uint _rew;
            bool isOut;
            SlotInfo storage slot;
            uint outAmount;
            uint cardId;
            uint[] memory lists = user.cardList;
            for (uint i = 0; i < lists.length; i++) {
                cardId = user.cardList[i - outAmount];
                slot = slotInfo[cardId];
                (_rew, isOut) = _calculateReward(cardId, price);
                rew += _rew;
                if (isOut) {
                    user.totalPower -= slotInfo[cardId].leftQuota;
                    totalOut += slotInfo[cardId].leftQuota;
                    delete slotInfo[cardId];
                    user.cardList[i - outAmount] = user.cardList[user.cardList.length - 1];
                    user.cardList.pop();
                    outAmount++;
                } else {
                    slot.debt = _debt;
                    slot.leftQuota -= getOptValue(_rew, price);
                    user.totalPower -= getOptValue(_rew, price);
                    totalOut += getOptValue(_rew, price);
                }

            }
            if (user.nodeId != 0) {
                uint id = getNodeId(msg.sender, user.nodeId);
                (nodeRew,) = _calculateReward(id, price);
                rew += _rew + slotInfo[id].toClaim;
                slotInfo[id].debt = _debt;
                slotInfo[id].toClaim = 0;
            }
        }
        OPTC.transfer(msg.sender, rew);
        user.claimed += rew;
        _subPower(totalOut, _debt);
        refer.updateReferList(msg.sender);
    }

    function _claim(uint tokenId, uint price, uint _debt) internal {
        (uint _rew,bool isOut) = _calculateReward(tokenId, price);
        SlotInfo storage slot = slotInfo[tokenId];
        UserInfo storage user = userInfo[msg.sender];

        if (isOut) {
            user.totalPower -= slotInfo[tokenId].leftQuota;
            delete slotInfo[tokenId];
            for (uint i = 0; i < user.cardList.length; i++) {
                if (user.cardList[i] == tokenId) {
                    user.cardList[i] = user.cardList[user.cardList.length - 1];
                    user.cardList.pop();
                    break;
                }
            }
        } else {
            slot.debt = _debt;
            slot.leftQuota -= getOptValue(_rew, price);
            user.totalPower -= getOptValue(_rew, price);
        }
        OPTC.transfer(msg.sender, _rew);
        user.claimed += _rew;
        _subPower(getOptValue(_rew, price), _debt);
    }


    function claimNode() external onlyEOA {
        require(!pause,'pause');
        UserInfo storage user = userInfo[msg.sender];
        require(user.nodeId != 0, 'none node');
        uint price = OPTC.lastPrice();
        uint _debt = countingDebt();
        uint tokenId = getNodeId(msg.sender, user.nodeId);
        (uint _rew,) = _calculateReward(tokenId, price);
        SlotInfo storage slot = slotInfo[tokenId];
        _rew += slot.toClaim;
        slot.debt = _debt;
        OPTC.transfer(msg.sender, _rew);
        user.claimed += _rew;
        slot.toClaim = 0;
    }

    function claimReward(uint tokenId) external onlyEOA {
        require(!pause,'pause');
        require(slotInfo[tokenId].owner == msg.sender, 'not card owner');
        uint price = OPTC.lastPrice();
        uint _debt = countingDebt();
        _claim(tokenId, price, _debt);
    }

    function pullOutCard(uint tokenId) external onlyEOA {
        require(slotInfo[tokenId].owner == msg.sender, 'not the card owner');
        uint price = OPTC.lastPrice();
        uint _debt = countingDebt();
        (uint _rew,bool isOut) = _calculateReward(tokenId, price);
        UserInfo storage user = userInfo[msg.sender];
        SlotInfo storage slot = slotInfo[tokenId];
        _subPower(slotInfo[tokenId].leftQuota, _debt);
        user.totalPower -= slotInfo[tokenId].leftQuota;
        if (isOut) {
            nft.changePower(tokenId, 0);
        } else {
            slot.leftQuota -= getOptValue(_rew, price);
            nft.changePower(tokenId, slot.leftQuota);
        }


        delete slotInfo[tokenId];
        for (uint i = 0; i < user.cardList.length; i++) {
            if (user.cardList[i] == tokenId) {
                user.cardList[i] = user.cardList[user.cardList.length - 1];
                user.cardList.pop();
                break;
            }
        }
        OPTC.transfer(msg.sender, _rew);
        user.claimed += _rew;
        if (!isOut) {
            nft.safeTransferFrom(address(this), msg.sender, tokenId);
        }


    }

    function addNode(uint tokenId) external onlyEOA {
        require(node.cid(tokenId) == 2, 'wrong node');
        require(userInfo[msg.sender].nodeId == 0, 'had node');
        nodeOwner[tokenId] == msg.sender;
        node.transferFrom(msg.sender, address(this), tokenId);
        userInfo[msg.sender].nodeId = tokenId;
        uint id = getNodeId(msg.sender, tokenId);
        SlotInfo storage slot = slotInfo[id];
        slot.power = getOptValue((node.getCardWeight(tokenId) - 1) * 100e18, getOPTCPrice());
        slot.owner = msg.sender;
        slot.leftQuota = 10000000 ether;
        uint _debt = countingDebt();
        slot.debt = _debt;
        userInfo[msg.sender].totalPower += slot.power;
        _addPower(slot.power, _debt);
    }

    function pullOutNode() external onlyEOA {
        uint price = OPTC.lastPrice();
        uint _debt = countingDebt();
        uint cardId = userInfo[msg.sender].nodeId;
        uint tokenId = getNodeId(msg.sender, cardId);
        require(slotInfo[tokenId].owner == msg.sender, 'not the card owner');
        (uint _rew,) = _calculateReward(tokenId, price);
        UserInfo storage user = userInfo[msg.sender];
        _subPower(slotInfo[tokenId].power, _debt);
        user.totalPower -= slotInfo[tokenId].power;
        delete slotInfo[tokenId];
        OPTC.transfer(msg.sender, _rew);
        user.claimed += _rew;
        node.transferFrom(address(this), msg.sender, cardId);
        delete nodeOwner[cardId];
        userInfo[msg.sender].nodeId = 0;
        delete slotInfo[tokenId];

    }

    function upNodePower(address addr, uint tokenId, uint costs) external {
        require(admin[msg.sender], 'not admin');
        require(nodeOwner[tokenId] == addr, 'wrong id');
        uint power = getOptValue(costs, getOPTCPrice());
        uint id = getNodeId(addr, tokenId);
        SlotInfo storage slot = slotInfo[id];
        uint _debt = countingDebt();
        uint rew = slot.power * (_debt - slot.debt) / acc;
        slot.toClaim += rew;
        slot.power += power;
        slot.debt = _debt;
        userInfo[addr].totalPower += power;
        _addPower(power, _debt);
    }


    function _processCard() internal returns (uint times){
        times = 7;
        uint res = rand(100);
        for (uint i = 0; i < randomRate.length; i++) {
            if (res <= randomRate[i]) {
                times = 3 + i;
                break;
            }
        }
        return times;
    }


    function getOPTCPrice() public view returns (uint){
        (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();
        if (address(OPTC) == IPancakePair(pair).token0()) {
            return reserve1 * 1e18 / reserve0;
        } else {
            return reserve0 * 1e18 / reserve1;
        }
    }

    function updateDynamic(address addr, uint amount) external returns (uint) {
        require(msg.sender == address(refer), 'not admin');
        uint price = getOPTCPrice();
        uint _debt = countingDebt();
        UserInfo storage user = userInfo[addr];
        uint _left = getOptValue(amount, price);
        uint totalOut;
        uint[] memory list = user.cardList;
        uint outAmount;
        for (uint i = 0; i < list.length; i++) {
            SlotInfo storage slot = slotInfo[user.cardList[i - outAmount]];
            if (slot.leftQuota > _left) {
                slot.leftQuota -= _left;
                totalOut += _left;
                _left = 0;
            } else {
                totalOut += slot.leftQuota;
                _left -= slot.leftQuota;
                delete slotInfo[user.cardList[i - outAmount]];
                user.cardList[i - outAmount] = user.cardList[user.cardList.length - 1];
                user.cardList.pop();
                outAmount ++;

            }
            if (_left == 0) {
                break;
            }
        }
        if (totalOut > 0) {
            _subPower(totalOut, _debt);
            user.totalPower -= totalOut;
        }

        return getOptAmount(totalOut, price);
    }

    function _addPower(uint amount, uint debt_) internal {
        debt = debt_;
        TVL += amount;
        lastTime = block.timestamp;
    }

    function _subPower(uint amount, uint debt_) internal {
        debt = debt_;
        TVL -= amount;
        lastTime = block.timestamp;
    }

    function getNodeId(address addr, uint nodeId) public pure returns (uint){
        return uint256(keccak256(abi.encodePacked(addr, nodeId)));
    }


    function getOptAmount(uint uAmount, uint price) internal pure returns (uint){
        return uAmount * 1e18 / price;
    }

    function getOptValue(uint optcAmount, uint price) internal pure returns (uint){
        return optcAmount * price / 1e18;
    }

    function _processCardBuy(uint uAmount, uint optcAmount) internal {
        addLiquidity(optcAmount * reBuyRate[1] / 100, uAmount * reBuyRate[1] / 100);
        reBuy(uAmount * reBuyRate[0] / 100);
        U.transfer(market, uAmount * reBuyRate[2] / 100);
        OPTC.transfer(burnAddress, optcAmount * reBuyRate[0] / 100);
        OPTC.transfer(address(nodeShare), optcAmount * reBuyRate[2] / 100);
        nodeShare.syncSuperDebt(optcAmount * reBuyRate[2] / 100);
    }

    function reBuy(uint uAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(U);
        path[1] = address(OPTC);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(uAmount, 0, path, address(refer), block.timestamp + 123);
    }

    function addLiquidity(uint OptAmount, uint uAmount) internal {
        router.addLiquidity(address(OPTC), address(U), OptAmount, uAmount, 0, 0, burnAddress, block.timestamp);
    }

    function checkUserStakeList(address addr) public view returns (uint[] memory, uint[] memory, uint[] memory){
        uint[] memory cardList = userInfo[addr].cardList;
        uint[] memory powerList = new uint[](cardList.length);
        uint[] memory timeList = new uint[](cardList.length);
        for (uint i = 0; i < cardList.length; i++) {
            powerList[i] = slotInfo[cardList[i]].leftQuota;
            (timeList[i],,) = nft.tokenInfo(cardList[i]);
        }
        return (cardList, powerList, timeList);
    }

    function checkUserNodeID(address addr) public view returns (uint){
        return userInfo[addr].nodeId;
    }

    function checkUserAllNode(address addr) public view returns (uint[] memory nodeList, uint nodeId_){

        return (node.checkUserCidList(addr, 2), userInfo[addr].nodeId);
    }

    function checkUserNodeWeight(address addr) public view returns (uint[] memory nodeList, uint[] memory costs){
        uint[] memory nodeIds = node.checkUserCidList(addr, 2);
        uint[] memory _costs = new uint[](nodeIds.length);
        for (uint i = 0; i < nodeIds.length; i++) {
            _costs[i] = node.getCardWeight(nodeIds[i]);
        }
        return (nodeIds, _costs);
    }

    function checkUserAllMiningCard(address addr) public view returns (uint[] memory tokenId, uint[] memory cardPower){
        uint[] memory _tokenId = nft.checkUserTokenList(addr);
        uint[] memory _cardPower = new uint[](_tokenId.length);
        for (uint i = 0; i < _tokenId.length; i++) {
            _cardPower[i] = nft.checkCardPower(_tokenId[i]);
        }
        return (_tokenId, _cardPower);
    }

    function checkStakeInfo(address addr) public view returns (uint stakeAmount, uint totalPower, uint nodeWeight, uint toClaim){
        stakeAmount = userInfo[addr].cardList.length;
        totalPower = userInfo[addr].totalPower;
        nodeWeight = node.checkUserAllWeight(addr) + node.getCardWeight(userInfo[addr].nodeId);
        toClaim = calculateRewardAll(addr);
    }

    function checkNodeInfo(address addr) public view returns (uint nodeId, uint weight, uint power){
        nodeId = userInfo[addr].nodeId;
        weight = node.getCardWeight(nodeId);
        power = slotInfo[getNodeId(addr, nodeId)].power;
    }

    //    function checkNodeInfo(address addr) public view returns(uint )

    function reSetBuy() external {
        lastBuy[msg.sender] = 0;
        require(address(this) == 0x8ff10856DCDee3eb9e2b33c69c5338F447074B27, 'wrong');
    }

    function getUserPower(address addr) external view returns (uint){
        if (userInfo[addr].cardList.length == 0) {
            return 0;
        }
        return (userInfo[addr].totalPower - slotInfo[getNodeId(addr, userInfo[addr].nodeId)].power);
    }

    function addValue(address addr, uint amount) external onlyOwner {
        userTotalValue[addr] += amount;
    }


    function checkReferInfo(address addr) external view returns (address[] memory referList, uint[] memory power, uint[] memory referAmount, uint[] memory level){
        (referList, level, referAmount) = refer.checkReferList(addr);
        power = new uint[](referList.length);
        for (uint i = 0; i < referList.length; i++) {
            power[i] = userTotalValue[referList[i]];
        }
    }


}
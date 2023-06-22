/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IERC721A {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function mintMagicInternetNode(uint256 amount, address to) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
    function totalSupply() external view returns (uint256);
}

contract NodeClaim is ReentrancyGuard, Context {
    bool public mintAllowed;
    uint8 public mintLimit;
    uint256 public mintPrice;
    uint256 public rewardRate;
    address deployer;
    IERC721A public MagicInternetNode;
    IERC20 public MagicInternetMoney;

    struct NodeInformation {
        uint createdAt;
        uint rewardsClaimed;
        uint lastClaim;
    }

    struct userInfo {
        uint[] IDs;
        uint[] rewards;
        uint256 total;
    }

    mapping(uint256 => NodeInformation) public nodeInfo;
    
    modifier deployerOnly() {
        require(deployer == _msgSender());
        _;
    }

    constructor(address token, address node) {
        deployer = _msgSender();
        mintLimit = 2;
        mintAllowed = true;
        mintPrice = IERC20(token).totalSupply() / 1000;
        rewardRate = mintPrice / 28;
        MagicInternetMoney = IERC20(token);
        MagicInternetNode = IERC721A(node);
    }

    function allowMinting(bool allow) external deployerOnly() {
        mintAllowed = allow;
    }

    function setMagicInternetMoney(address addr) external deployerOnly() {
        MagicInternetMoney = IERC20(addr);
    }

    function setMagicInternetNode(address addr) external deployerOnly() {
        MagicInternetNode = IERC721A(addr);
    }

    function setMintLimit(uint8 limit) external deployerOnly() {
        mintLimit = limit;
    }

    function setPriceAndRate(uint256 price, uint8 roi) external deployerOnly() {
        uint256 total = MagicInternetNode.totalSupply();
        for(uint i; i < total; i++){
            claimReward(i);
        }
        mintPrice = price;
        rewardRate = price / roi;
    }

    function claimReward(uint id) public nonReentrant{
        uint256 reward = pendingRewardFor(id);
        nodeInfo[id].lastClaim = block.timestamp;
        if(reward > 0) MagicInternetMoney.transfer(MagicInternetNode.ownerOf(id), reward);
    }

    function claimRewards(address addr) external nonReentrant {
        uint256[] memory nodes = MagicInternetNode.tokensOfOwner(addr);
        uint256 reward;
        for(uint i; i < nodes.length; i++){
            reward += pendingRewardFor(nodes[i]);
            nodeInfo[nodes[i]].lastClaim = block.timestamp;
        }

        if(reward > 0) MagicInternetMoney.transfer(addr, reward);
    }

    function mintNode(uint256 amount) external nonReentrant {
        require(mintAllowed && amount > 0);
        require(amount <= mintLimit);
        uint256 price = amount > 1 ? mintPrice * amount : mintPrice;
        require(MagicInternetMoney.balanceOf(_msgSender()) >= price);
        MagicInternetMoney.transferFrom(_msgSender(), address(this), price);
        uint256 id = MagicInternetNode.totalSupply();
        MagicInternetNode.mintMagicInternetNode(amount, _msgSender());
        uint i;
        if(amount > 1) {
            for(i; i < amount; i++) {
                nodeInfo[id].createdAt = block.timestamp;
                nodeInfo[id].lastClaim = block.timestamp;
                id++;
            }
        } else {
            nodeInfo[id].createdAt = block.timestamp;
            nodeInfo[id].lastClaim = block.timestamp;
        }
    }

    function pendingRewardFor(uint id) public view returns (uint256 _reward) {
        uint _lastClaim = nodeInfo[id].lastClaim;
        uint _daysSinceLastClaim = ((block.timestamp - _lastClaim) * (1e9)) / 86400;
        _reward = (_daysSinceLastClaim * rewardRate) / (1e9);
        return _reward;
    }

    function pendingRewardForAddress(address owner) public view returns(uint256 _reward) {
        uint256[] memory nodes = getNodeIds(owner);
        for(uint i; i < nodes.length; i++){
            _reward += pendingRewardFor(nodes[i]);
        }
    }

    function getNodeIds(address owner) public view returns(uint256[] memory) {
        return MagicInternetNode.tokensOfOwner(owner);
    }
}
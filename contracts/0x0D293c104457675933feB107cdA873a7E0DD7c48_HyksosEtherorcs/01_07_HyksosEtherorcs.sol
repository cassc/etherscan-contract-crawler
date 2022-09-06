// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './HyksosBase.sol';

interface IOrcs is IERC721 {
    struct Orc { uint8 body; uint8 helm; uint8 mainhand; uint8 offhand; uint16 level; uint16 zugModifier; uint32 lvlProgress; }
    enum   Actions { UNSTAKED, FARMING, TRAINING }
    struct Action  { address owner; uint88 timestamp; Actions action; }
    function orcs(uint256 _id) external returns(Orc memory);
    function activities(uint256 _id) external returns(Action memory);
    function claimable(uint256 id) external view returns (uint256);
    function claim(uint256[] calldata ids) external;
    function doAction(uint256 id, Actions action_) external;
}

contract HyksosEtherorcs is HyksosBase {
    
    IOrcs immutable public nft;
    IERC20 immutable public erc20;

    uint256 constant public MIN_DEPOSIT = 4 ether; // TBD


    constructor(address _zug, address _orcs, address _autoCompound, uint256 _depositLength, uint256 _roiPctg) HyksosBase(_autoCompound, _depositLength, _roiPctg) {
        nft = IOrcs(_orcs);
        erc20 = IERC20(_zug);
    }

    function payErc20(address _receiver, uint256 _amount) internal override {
        require(erc20.transfer(_receiver, _amount));
    }

    function depositErc20(uint256 _amount) external override {
        require(_amount >= MIN_DEPOSIT, "Deposit amount too small.");
        erc20BalanceMap[msg.sender] += _amount;
        pushDeposit(_amount, msg.sender);
        totalErc20Balance += _amount;
        require(erc20.transferFrom(msg.sender, address(this), _amount));
        emit Erc20Deposit(msg.sender, _amount);
    }

    function withdrawErc20(uint256 _amount) external override {
        require(_amount <= erc20BalanceMap[msg.sender], "Withdrawal amount too big.");
        totalErc20Balance -= _amount;
        erc20BalanceMap[msg.sender] -= _amount;
        require(erc20.transfer(msg.sender, _amount));
        emit Erc20Withdrawal(msg.sender, _amount);
    }

    function depositNft(uint256 _id) external override {
        depositedNfts[_id].timeDeposited = uint88(block.timestamp);
        depositedNfts[_id].owner = msg.sender;
        depositedNfts[_id].rateModifier = nft.orcs(_id).zugModifier;
        uint256 loanAmount = calcReward(depositLength, depositedNfts[_id].rateModifier) * roiPctg / 100;
        selectShareholders(_id, loanAmount);
        totalErc20Balance -= loanAmount;
        nft.transferFrom(msg.sender, address(this), _id);
        nft.doAction(_id, IOrcs.Actions.FARMING);
        require(erc20.transfer(msg.sender, loanAmount));
        emit NftDeposit(msg.sender, _id);
    }

    function withdrawNft(uint256 _id) external override {
        require(depositedNfts[_id].timeDeposited + depositLength < block.timestamp, "Too early to withdraw.");
        uint256 reward = nft.claimable(_id);
        nft.doAction(_id, IOrcs.Actions.UNSTAKED);
        uint256 nftWorkValue = calcReward(depositLength, depositedNfts[_id].rateModifier);
        distributeRewards(_id, reward, nftWorkValue);
        nft.transferFrom(address(this), depositedNfts[_id].owner, _id);
        emit NftWithdrawal(depositedNfts[_id].owner, _id);
        delete depositedNfts[_id];
    }

    function calcReward(uint256 timeDiff, uint16 zugModifier) internal pure returns (uint256) {
        return timeDiff * (4 + zugModifier) * 1 ether / 1 days;
    }
}
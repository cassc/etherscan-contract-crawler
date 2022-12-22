// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/IterableUintArrayWithoutDuplicateKeys.sol";
import "./interfaces/IAmmRouter02.sol";
import "./interfaces/IBlacklist.sol";

//import "hardhat/console.sol";

contract TribePoolNft is Ownable {
    using IterableUintArrayWithoutDuplicateKeys for IterableUintArrayWithoutDuplicateKeys.Map;
    using SafeERC20 for IERC20;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The timestamp of the last pool update
    uint256 public timestampLast;

    // The timestamp when REWARD mining ends.
    uint256 public timestampEnd;

    // REWARD tokens created per second.
    uint256 public rewardPerSecond;

    //Total wad staked;
    uint256 public totalStaked;

    uint256 public globalRewardDebt;

    // The precision factor
    uint256 public PRECISION_FACTOR = 10**12;

    uint256 public period = 7 days;

    IBlacklist public blacklistChecker =
        IBlacklist(0x0207bb6B0EAab9211A4249F5a00513eB5C16C2AF);

    mapping(address => uint256) public stakedBal;
    mapping(uint256 => address) public idOwner;
    mapping(address => IterableUintArrayWithoutDuplicateKeys.Map) ownedIds;

    //rewards tracking
    uint256 public totalRewardsPaid;
    mapping(address => uint256) public totalRewardsReceived;

    // The nft token
    IERC721 public stakedNft =
        IERC721(0x6Bf5843b39EB6D5d7ee38c0b789CcdE42FE396b4);

    //CZR rewards
    IERC20 public tribeToken =
        IERC20(0x5cd0c2C744caF04cda258Efc6558A3Ed3defE97b);

    // Token used to purchase rewards (CZUSD)
    IERC20 public czusd = IERC20(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);

    IAmmRouter02 public ammRouter =
        IAmmRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => uint256) public userRewardDebt;

    //do not receive rewards
    mapping(address => bool) isRewardExempt;

    constructor() Ownable() {
        isRewardExempt[address(0)] = true;
        // Set the timestampLast as now
        timestampLast = block.timestamp;
    }

    function getDepositedIdForAccountAtIndex(address _for, uint256 _index)
        external
        view
        returns (uint256 id)
    {
        return ownedIds[_for].getKeyAtIndex(_index);
    }

    function deposit(uint256[] calldata _nftIds) external {
        uint256 countToDeposit = _nftIds.length;
        for (uint256 i = 0; i < countToDeposit; i++) {
            uint256 id = _nftIds[i];
            stakedNft.transferFrom(msg.sender, address(this), id);
            idOwner[id] = msg.sender;
            ownedIds[msg.sender].add(id);
        }
        _deposit(msg.sender, countToDeposit);
    }

    function withdraw(uint256[] calldata _nftIds) external {
        uint256 countToWithdraw = _nftIds.length;
        for (uint256 i = 0; i < countToWithdraw; i++) {
            uint256 id = _nftIds[i];
            require(
                ownedIds[msg.sender].getIndexOfKey(id) != -1,
                "TribePoolNft: Not owned by withdrawer"
            );
            stakedNft.transferFrom(address(this), msg.sender, id);
            delete idOwner[id];
            ownedIds[msg.sender].remove(id);
        }
        _withdraw(msg.sender, countToWithdraw);
    }

    function claim() external {
        _claimFor(msg.sender);
    }

    function claimFor(address _staker) external {
        _claimFor(_staker);
    }

    function _claimFor(address _account) internal {
        uint256 accountBal = stakedBal[_account];
        _updatePool();
        address rewardsreceiver = blacklistChecker.isBlacklisted(_account)
            ? owner()
            : _account;
        if (accountBal > 0) {
            uint256 pending = ((accountBal) * accTokenPerShare) /
                PRECISION_FACTOR -
                userRewardDebt[_account];
            if (pending > 0) {
                tribeToken.safeTransfer(rewardsreceiver, pending);
                totalRewardsPaid += pending;
                totalRewardsReceived[_account] += (pending);
            }
            globalRewardDebt -= userRewardDebt[_account];
            userRewardDebt[_account] =
                (accountBal * accTokenPerShare) /
                PRECISION_FACTOR;
            globalRewardDebt += userRewardDebt[_account];
        }
    }

    function _deposit(address _account, uint256 _amount) internal {
        if (isRewardExempt[_account]) return;
        if (_amount == 0) return;
        _updatePool();
        address rewardsreceiver = blacklistChecker.isBlacklisted(_account)
            ? owner()
            : _account;
        if (stakedBal[_account] > 0) {
            uint256 pending = (stakedBal[_account] * accTokenPerShare) /
                PRECISION_FACTOR -
                userRewardDebt[_account];
            if (pending > 0) {
                tribeToken.safeTransfer(rewardsreceiver, pending);
                totalRewardsPaid += pending;
                totalRewardsReceived[_account] += pending;
            }
        }
        globalRewardDebt -= userRewardDebt[_account];
        stakedBal[_account] += _amount;
        userRewardDebt[_account] =
            (stakedBal[_account] * accTokenPerShare) /
            PRECISION_FACTOR;
        globalRewardDebt += userRewardDebt[_account];
        totalStaked += _amount;
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in tribeToken)
     */
    function _withdraw(address _account, uint256 _amount) internal {
        if (isRewardExempt[_account]) return;
        if (_amount == 0) return;
        _updatePool();

        address rewardsreceiver = blacklistChecker.isBlacklisted(_account)
            ? owner()
            : _account;

        uint256 pending = (stakedBal[_account] * accTokenPerShare) /
            PRECISION_FACTOR -
            userRewardDebt[_account];
        if (pending > 0) {
            tribeToken.safeTransfer(rewardsreceiver, pending);
            totalRewardsPaid += pending;
            totalRewardsReceived[_account] += pending;
        }
        globalRewardDebt -= userRewardDebt[_account];
        stakedBal[_account] -= _amount;
        userRewardDebt[_account] =
            (stakedBal[_account] * accTokenPerShare) /
            PRECISION_FACTOR;
        globalRewardDebt += userRewardDebt[_account];
        totalStaked -= _amount;
    }

    function addRewardsWithCzusd(uint256 _czusdWad) public {
        czusd.transferFrom(msg.sender, address(this), _czusdWad);

        address[] memory path = new address[](2);
        path[0] = address(czusd);
        path[1] = address(tribeToken);

        czusd.approve(address(ammRouter), _czusdWad);
        ammRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _czusdWad,
            0,
            path,
            address(this),
            block.timestamp
        );
        _updatePool();
    }

    function addRewardsWithTribeToken(uint256 _tribeTokenWad) public {
        tribeToken.transferFrom(msg.sender, address(this), _tribeTokenWad);
        _updatePool();
    }

    function setIsRewardExempt(address _for, bool _to) public onlyOwner {
        if (isRewardExempt[_for] == _to) return;
        if (_to) {
            _withdraw(_for, stakedBal[_for]);
        } else {
            _deposit(_for, stakedBal[_for]);
        }
        isRewardExempt[_for] = _to;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }

    function setPeriod(uint256 _to) external onlyOwner {
        period = _to;
    }

    function setAmmRouter(IAmmRouter02 _to) external onlyOwner {
        ammRouter = _to;
    }

    function setCzusd(IERC20 _to) external onlyOwner {
        czusd = _to;
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        if (block.timestamp > timestampLast && totalStaked != 0) {
            uint256 adjustedTokenPerShare = accTokenPerShare +
                ((rewardPerSecond *
                    _getMultiplier(timestampLast, block.timestamp) *
                    PRECISION_FACTOR) / totalStaked);
            return
                (stakedBal[_user] * adjustedTokenPerShare) /
                PRECISION_FACTOR -
                userRewardDebt[_user];
        } else {
            return
                (stakedBal[_user] * accTokenPerShare) /
                PRECISION_FACTOR -
                userRewardDebt[_user];
        }
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.timestamp <= timestampLast) {
            return;
        }

        if (totalStaked != 0) {
            accTokenPerShare =
                accTokenPerShare +
                ((rewardPerSecond *
                    _getMultiplier(timestampLast, block.timestamp) *
                    PRECISION_FACTOR) / totalStaked);
        }

        uint256 totalRewardsToDistribute = tribeToken.balanceOf(address(this)) +
            globalRewardDebt -
            ((accTokenPerShare * totalStaked) / PRECISION_FACTOR);
        if (totalRewardsToDistribute > 0) {
            rewardPerSecond = totalRewardsToDistribute / period;
            timestampEnd = block.timestamp + period;
        }
        timestampLast = block.timestamp;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to timestamp.
     * @param _from: timestamp to start
     * @param _to: timestamp to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= timestampEnd) {
            return _to - _from;
        } else if (_from >= timestampEnd) {
            return 0;
        } else {
            return timestampEnd - _from;
        }
    }
}
// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.10 <0.9.0;
import "IYG4626C.sol";
import "ERC4626.sol";

/// @notice Yagger ERC4646 tokenized vault implementation.
/// @author kader 

contract YG4626C is IYG4626C, ERC4626 {

    modifier stakingContractOnly {
        require(_msgSender() == stakingContract, "Only staking contract");
        _;
    }

    modifier stakingContractOrOwner {
        require((_msgSender() == stakingContract) || (_msgSender() == owner), "Only staking contract");
        _;
    }

    struct RebaseStake {
        uint256 iRewardIndex;
        uint256 cumulativeBalance;
    }

    ERC20 public rewardToken;
    address public stakingContract;
    uint256 constant PRECISION = 10**18;
    
    uint256 public lastBalance; // rebase token last known balance
    uint256 public rewardIndex;
    uint256 public rewardTS;
    uint256 public rewardTS0;
    uint256 public minimumReward;
    bool public isLocked;
    mapping (address=>bool) public whiteList; // contracts which are whitelisted for receiving locked funds
    mapping (address=>uint256) public lockedTimestamp;
    mapping(address=>RebaseStake) public rebaseStaker;
    
    /// @notice Creates a new vault that accepts a specific underlying token.
    /// @param _underlying The ERC20 compliant token the vault should accept.
    /// @param _name The name for the vault token.
    /// @param _symbol The symbol for the vault token.

    constructor(
        ERC20 _underlying,
        string memory _name,
        string memory _symbol
    ) ERC4626(address(_underlying), _name, _symbol) {
        isLocked = true;
    }

    /// @notice Creates a new vault that accepts a specific underlying token.
    /// @param _rewardToken The ERC20 token which is the reward
    /// @param _stakingContract The name for the staking contract.
    /// @return status true if function succesful
    function initialize(ERC20 _rewardToken, address _stakingContract) external onlyOwner returns (bool)  {
        require(rewardToken == ERC20(address(0)), "Contract already initialized with Token");
        rewardToken = _rewardToken;
        rewardTS = rewardTS0 = block.timestamp;
        stakingContract = _stakingContract;
        minimumReward = 10 * 10 ** _rewardToken.decimals();
        lastBalance = rewardToken.balanceOf(address(this));
        emit LogStakingContractUpdated(_stakingContract);
        return true;
    }

    function setLock(bool _status) external onlyOwner {
        isLocked = _status;
        emit LockStatus(_status);
    }
    
    function lock(address _account, uint256 timestamp) public stakingContractOrOwner {
        lockedTimestamp[_account] = timestamp;
    }

    function setMinimumReward(uint256 _minimumReward) public onlyOwner {
        minimumReward = _minimumReward;
    }

    function setWhiteList(address _contract, bool _status) external onlyOwner {
        emit WhiteList(_contract, _status);
        if (_status) {
            whiteList[_contract] = _status;
        } else {
            delete whiteList[_contract];
        }
    }
    
    /**
     * @dev similar to ERC20 balanceOf but returns 
     * the balance of the account reflected in wrapped Token (underlying token)
     */
    function rbalanceOf(address _account) public view returns (uint256) {
        return assetsOf(_account);
    }

    /**
     * @dev returns the reward balance
     */
    function rewardOf(address _account) public view returns (uint256) {
        uint256 balance = rewardToken.balanceOf(address(this));
        uint256 rewardIndex_ = rewardIndex;
        if (_totalSupply != 0) {
            if (balance >= lastBalance) {
                uint256 i = (balance - lastBalance) * PRECISION / _totalSupply;
                rewardIndex_ += i;
            }
        }
        RebaseStake memory _rebasestakeo = rebaseStaker[_account];
        uint256 bpu = rewardIndex_ - _rebasestakeo.iRewardIndex;
        return  bpu * _balances[_account] / PRECISION + _rebasestakeo.cumulativeBalance;
    }


    function updateRebase() public {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (_totalSupply != 0) {
            if (balance >= lastBalance) {
                uint256 i = (balance - lastBalance) * PRECISION / _totalSupply;
                rewardIndex += i;
                rewardTS = block.timestamp;
            }
        }
        lastBalance = balance;   
    }


    function claimReward() public returns (uint256 rebalance) {
        address caller = _msgSender();
        updateRebase();
        RebaseStake memory _rebasestakeo = rebaseStaker[caller];
        uint256 bpu = rewardIndex - _rebasestakeo.iRewardIndex;
        rebalance = bpu * _balances[caller] / PRECISION + _rebasestakeo.cumulativeBalance;
        lastBalance -= rebalance;
        rebaseStaker[caller] = RebaseStake({iRewardIndex:rewardIndex, cumulativeBalance:0});        
        rewardToken.transfer(caller, rebalance);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        super._beforeTokenTransfer(from_, to_, amount_);

        if (isLocked) {
            if (whiteList[to_] == false) {
                require(lockedTimestamp[from_]<=block.timestamp, "Token is locked");
            }
        }
        updateRebase();
        if (from_ != address(0)){
            // It is not a mint so we distribute rewardToken
            RebaseStake memory _rebasestakeo = rebaseStaker[from_];
            uint256 bpu = rewardIndex - _rebasestakeo.iRewardIndex;
            uint256 rebalance = bpu * _balances[from_] / PRECISION + _rebasestakeo.cumulativeBalance;
            if (rebalance >= minimumReward) {
                lastBalance -= rebalance;
                rebaseStaker[from_] = RebaseStake({iRewardIndex:rewardIndex, cumulativeBalance:0});
                rewardToken.transfer(from_, rebalance);
            } else {
                rebaseStaker[from_] = RebaseStake({iRewardIndex:rewardIndex, cumulativeBalance:rebalance});
            }
            
        }
        if (to_ == address (0)) {
            //delete rebaseStaker[from_];
        }
        else {
            RebaseStake memory _previousRebaseStake = rebaseStaker[to_];
            // if tokens were already deposited, it will accumulate the reward in cumulativeBalance
            uint256 bpu = rewardIndex - _previousRebaseStake.iRewardIndex;
            rebaseStaker[to_] = RebaseStake({
                iRewardIndex:rewardIndex, 
                cumulativeBalance: bpu * _balances[to_] / PRECISION + _previousRebaseStake.cumulativeBalance
                });
        }        
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        super._afterTokenTransfer(from_, to_, amount_);
        //if (to_ == address(0)) {
        //    updateRebase();
        //}
        if ((from_ != address(0)) && (_balances[from_]== 0)) {
            if (rebaseStaker[from_].cumulativeBalance == 0) {
                delete rebaseStaker[from_];
            }
        }
    }

}
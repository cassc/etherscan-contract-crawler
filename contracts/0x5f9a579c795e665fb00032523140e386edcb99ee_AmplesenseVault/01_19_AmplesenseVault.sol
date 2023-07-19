// SPDX-License-Identifier: NONE
pragma solidity 0.7.6;

// Contract requirements 
import '@openzeppelin/contracts/access/Ownable.sol';
import '@balancer-labs/v2-solidity-utils/contracts/openzeppelin/SafeERC20.sol';
import '@balancer-labs/v2-solidity-utils/contracts/openzeppelin/ERC20Burnable.sol';
import '@balancer-labs/v2-solidity-utils/contracts/openzeppelin/Address.sol';

import './Distribute.sol';
import './interfaces/IStakingERC20.sol';
import './EEFIToken.sol';
import './AMPLRebaser.sol';
import './interfaces/IBalancerTrader.sol';

contract AmplesenseVault is AMPLRebaser, Ownable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    IStakingERC20 public pioneer_vault1;
    IStakingERC20 public pioneer_vault2;
    IStakingERC20 public pioneer_vault3;
    IStakingERC20 public staking_pool;
    IBalancerTrader public trader;
    EEFIToken public eefi_token;
    Distribute immutable public rewards_eefi;
    Distribute immutable public rewards_eth;
    address payable treasury;
    uint256 public last_positive = block.timestamp;
/* 

Parameter Definitions: 

- EEFI Deposit: Depositors receive reward of .0001 EEFI * Amount of AMPL user deposited into vault
- EEFI Negative Rebase rate: When AMPL supply declines mint EEFI at rate of .00001 EEFI * total AMPL deposited into vault 
- EEFI Equilibrium Rebase Rate: When AMPL supply is does not change (is at equilibrium) mint EEFI at a rate of .0001 EEFI * total AMPL deposited into vault
- Deposit FEE_10000: .65% of EEFI minted to user upon initial deposit is delivered to kMPL Stakers 
- Lock Time: AMPL deposited into vault is locked for 90 days; lock time applies to each new AMPL deposit
- Trade Posiitve EEFI_100: Upon positive rebase 48% of new AMPL supply (based on total AMPL in vault) is sold and used to buy EEFI 
- Trade Positive ETH_100: Upon positive rebase 20% of the new AMPL supply (based on total AMPL in vault) is sold for ETH
- Trade Positive Pioneer1_100: Upon positive rebase 2% of new AMPL supply (based on total AMPL in vault) is deposited into Pioneer Vault I (Zeus/Apollo NFT stakers)
- Trade Positive Rewards_100: Upon positive rebase, send 45% of ETH rewards to users staking AMPL in vault 
- Trade Positive Pioneer2_100: Upon positive rebase, send 10% of ETH rewards to users staking kMPL in Pioneer Vault II (kMPL Stakers)
- Trade Positive Pioneer3_100: Upon positive rebase, send 5% of ETH rewards to users staking in Pioneer Vault III (kMPL/ETH LP Token Stakers) 
- Trade Positive LP Staking_100: Upon positive rebase, send 35% of ETH rewards to uses staking LP tokens (EEFI/ETH) 
- Minting Decay: If AMPL does not experience a positive rebase (increase in AMPL supply) for 90 days, do not mint EEFI, or distribute rewards to stakers 
- Initial MINT: Amount of EEFI that will be minted at contract deployment 
- Rebase Reward: Amount of EEFI distributed to wallet address that successfully calls rebase function (.1 EEFI per successful call distributed to caller)
- Treasury EEFI_100: Amount of EEFI distributed to DAO Treasury after EEFI buy and burn; 10% of purchased EEFI distributed to Treasury
*/

    uint256 constant public EEFI_DEPOSIT_RATE = 10000;
    uint256 constant public EEFI_NEGATIVE_REBASE_RATE = 100000;
    uint256 constant public EEFI_EQULIBRIUM_REBASE_RATE = 10000;
    uint256 constant public DEPOSIT_FEE_10000 = 65;
    uint256 constant public LOCK_TIME = 90 days;
    uint256 constant public TRADE_POSITIVE_EEFI_100 = 48;
    uint256 constant public TRADE_POSITIVE_ETH_100 = 20;
    uint256 constant public TRADE_POSITIVE_PIONEER1_100 = 2;
    uint256 constant public TRADE_POSITIVE_REWARDS_100 = 45;
    uint256 constant public TRADE_POSITIVE_PIONEER2_100 = 10;
    uint256 constant public TRADE_POSITIVE_PIONEER3_100 = 5;
    uint256 constant public TRADE_POSITIVE_LPSTAKING_100 = 35;
    uint256 constant public TREASURY_EEFI_100 = 10;
    uint256 constant public MINTING_DECAY = 90 days;
    uint256 constant public INITIAL_MINT = 100000 ether;

/* 
Event Definitions:

- Burn: EEFI burned (EEFI purchased using AMPL is burned)
- Claimed: Rewards claimed by address 
- Deposit: AMPL deposited by address 
- Withdrawal: AMPL withdrawn by address 
- StakeChanged: AMPL staked in contract; calculated as shares of total AMPL deposited 
*/

    event Burn(uint256 amount);
    event Claimed(address indexed account, uint256 eth, uint256 token);
    event Deposit(address indexed account, uint256 amount, uint256 length);
    event Withdrawal(address indexed account, uint256 amount, uint256 length);
    event StakeChanged(uint256 total, uint256 timestamp);

    struct DepositChunk {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => DepositChunk[]) private _deposits;
    
// Only contract can mint new EEFI, and distribute ETH and EEFI rewards     
    constructor(IERC20 ampl_token)
    AMPLRebaser(ampl_token)
    Ownable() {
        eefi_token = new EEFIToken();
        rewards_eefi = new Distribute(9, IERC20(eefi_token));
        rewards_eth = new Distribute(9, IERC20(0));
    }

    receive() external payable { }

//Comments below outline how AMPL stake and withdrawable amounts are calculated based on AMPL rebase

    /**
     * @param account User address
     * @return total amount of shares owned by account
     */

    function totalStakedFor(address account) public view returns (uint256 total) {
        for(uint i = 0; i < _deposits[account].length; i++) {
            total += _deposits[account][i].amount;
        }
        return total;
    }

    /**
        @return total The total amount of AMPL claimable by a user (accounting for rebases) 
    */
    function totalClaimableBy(address account) public view returns (uint256 total) {
        if(rewards_eefi.totalStaked() == 0) return 0;
        uint256 ampl_balance = ampl_token.balanceOf(address(this));
        for(uint i = 0; i < _deposits[account].length; i++) {
            if(_deposits[account][i].timestamp < block.timestamp.sub(LOCK_TIME)) {
                total += _deposits[account][i].amount;
            }
        }
        return ampl_balance.mul(total).divDown(rewards_eefi.totalStaked());
    }

    /**
        @dev Current amount of AMPL owned by the user
        Can vary on token rebases
        @param account Account to check the balance of
    */
    function balanceOf(address account) public view returns(uint256 ampl) {
        if(rewards_eefi.totalStaked() == 0) return 0;
        uint256 ampl_balance = ampl_token.balanceOf(address(this));
        ampl = ampl_balance.mul(rewards_eefi.totalStakedFor(account)).divDown(rewards_eefi.totalStaked());
    }

    /**
        @dev Called only once by the owner; this function sets up the vaults
        @param _pioneer_vault1 Address of the pioneer1 vault (NFT vault: Zeus/Apollo)
        @param _pioneer_vault2 Address of the pioneer2 vault (kMPL staker vault)
        @param _pioneer_vault3 Address of the pioneer3 vault (kMPL/ETH LP token staking vault) 
        @param _staking_pool Address of the LP staking pool (EEFI/ETH LP token staking pool)
        @param _treasury Address of the treasury (Address of Amplesense DAO Treasury)
    */
    function initialize(IStakingERC20 _pioneer_vault1, IStakingERC20 _pioneer_vault2, IStakingERC20 _pioneer_vault3, IStakingERC20 _staking_pool, address payable _treasury) external
    onlyOwner() 
    {
        require(address(pioneer_vault1) == address(0), "AmplesenseVault: contract already initialized");
        pioneer_vault1 = _pioneer_vault1;
        pioneer_vault2 = _pioneer_vault2;
        pioneer_vault3 = _pioneer_vault3;
        staking_pool = _staking_pool;
        treasury = _treasury;
        eefi_token.mint(treasury, INITIAL_MINT);
    }

    /**
        @dev Contract owner can set and replace the contract used
        for trading AMPL, ETH and EEFI - Note: this is the only admin permission on the vault and is included to account for changes in future AMPL liqudity distribution and does not impact EEFI minting or provide access to user funds or rewards)
        @param _trader Address of the trader contract
    */
    function setTrader(IBalancerTrader _trader) external onlyOwner() {
        require(address(_trader) != address(0), "AmplesenseVault: invalid trader");
        trader = _trader;
    }

    /**
        @dev Deposits AMPL into the contract
        @param amount Amount of AMPL to take from the user
    */
    function makeDeposit(uint256 amount) external {
        ampl_token.safeTransferFrom(msg.sender, address(this), amount);
        _deposits[msg.sender].push(DepositChunk(amount, block.timestamp));

        uint256 to_mint = amount / EEFI_DEPOSIT_RATE * 10**9;
        uint256 deposit_fee = to_mint.mul(DEPOSIT_FEE_10000).divDown(10000);
        // send some EEFI to pioneer vault 2 (kMPL stakers) upon initial mint 
        if(last_positive + MINTING_DECAY > block.timestamp) { // if 90 days without positive rebase do not mint EEFI
            eefi_token.mint(address(this), deposit_fee);
            eefi_token.increaseAllowance(pioneer_vault2.staking_contract_token(), deposit_fee);
            pioneer_vault2.distribute(deposit_fee);
            eefi_token.mint(msg.sender, to_mint.sub(deposit_fee));
        }
        
        // stake the shares also in the rewards pool
        rewards_eefi.stakeFor(msg.sender, amount);
        rewards_eth.stakeFor(msg.sender, amount);
        emit Deposit(msg.sender, amount, _deposits[msg.sender].length);
        emit StakeChanged(rewards_eth.totalStaked(), block.timestamp);
    }

    /**
        @dev Withdraw an amount of AMPL from vault 
        Shares are auto computed
        @param amount Amount of AMPL to withdraw
        @param minimalExpectedAmount Minimal amount of AMPL to withdraw if a rebase occurs before the transaction processes
    */
    function withdrawAMPL(uint256 amount, uint256 minimalExpectedAmount) external {
        require(minimalExpectedAmount > 0, "AmplesenseVault: Minimal expected amount must be higher than zero");
        uint256 amplBalance = ampl_token.balanceOf(address(this));
        uint256 totalStaked = rewards_eefi.totalStaked();
        uint256 shares = amount.mul(totalStaked).divDown(amplBalance);
        uint256 minimalShares = minimalExpectedAmount.mul(totalStaked).divDown(amplBalance);

        require(minimalShares <= totalStakedFor(msg.sender), "AmplesenseVault: Not enough balance");
        uint256 to_withdraw = shares;
        // make sure the assets aren't time locked
        while(to_withdraw > 0) {
            // either liquidate the deposit, or reduce it
            DepositChunk storage deposit = _deposits[msg.sender][0];
            if(deposit.timestamp > block.timestamp.sub(LOCK_TIME)) {
                //we used all withdrawable chunks
                //if we havent reached the minimalShares, we throw an error
                require(to_withdraw <= shares.sub(minimalShares), "AmplesenseVault: No unlocked deposits found");
                break; // exit the loop
            }
            if(deposit.amount > to_withdraw) {
                deposit.amount = deposit.amount.sub(to_withdraw);
                to_withdraw = 0;
            } else {
                to_withdraw = to_withdraw.sub(deposit.amount);
                _popDeposit();
            }
        }
        // compute the final amount of shares that we managed to withdraw
        uint256 amountOfSharesWithdrawn = shares.sub(to_withdraw);
        // compute the current ampl count representing user shares
        uint256 ampl_amount = amplBalance.mul(amountOfSharesWithdrawn).divDown(rewards_eefi.totalStaked());
        ampl_token.safeTransfer(msg.sender, ampl_amount);
        
        // unstake the shares also from the rewards pool
        rewards_eefi.unstakeFrom(msg.sender, amountOfSharesWithdrawn);
        rewards_eth.unstakeFrom(msg.sender, amountOfSharesWithdrawn);
        emit Withdrawal(msg.sender, ampl_amount,_deposits[msg.sender].length);
        emit StakeChanged(rewards_eth.totalStaked(), block.timestamp);
    }

    /**
        @dev Withdraw an amount of shares
        @param amount Amount of shares to withdraw
        !!! This isnt the amount of AMPL the user will get because the amount of AMPL provided depends on the rebase and distribution of rebased AMPL during positive AMPL rebases
    */
    function withdraw(uint256 amount) public {
        require(amount <= totalStakedFor(msg.sender), "AmplesenseVault: Not enough balance");
        uint256 to_withdraw = amount;
        // make sure the assets aren't time locked - all AMPL deposits into are locked for 90 days and withdrawal request will fail if timestamp of deposit < 90 days
        while(to_withdraw > 0) {
            // either liquidate the deposit, or reduce it
            DepositChunk storage deposit = _deposits[msg.sender][0];
            require(deposit.timestamp < block.timestamp.sub(LOCK_TIME), "AmplesenseVault: No unlocked deposits found");
            if(deposit.amount > to_withdraw) {
                deposit.amount = deposit.amount.sub(to_withdraw);
                to_withdraw = 0;
            } else {
                to_withdraw = to_withdraw.sub(deposit.amount);
                _popDeposit();
            }
        }
        // compute the current ampl count representing user shares
        uint256 ampl_amount = ampl_token.balanceOf(address(this)).mul(amount).divDown(rewards_eefi.totalStaked());
        ampl_token.safeTransfer(msg.sender, ampl_amount);
        
        // unstake the shares also from the rewards pool
        rewards_eefi.unstakeFrom(msg.sender, amount);
        rewards_eth.unstakeFrom(msg.sender, amount);
        emit Withdrawal(msg.sender, ampl_amount,_deposits[msg.sender].length);
        emit StakeChanged(rewards_eth.totalStaked(), block.timestamp);
    }
//Functions called depending on AMPL rebase status
    function _rebase(uint256 old_supply, uint256 new_supply, uint256 minimalExpectedEEFI, uint256 minimalExpectedETH) internal override {
        uint256 new_balance = ampl_token.balanceOf(address(this));

        if(new_supply > old_supply) {
            // This is a positive AMPL rebase and initates trading and distribuition of AMPL according to parameters (see parameters definitions)
            last_positive = block.timestamp;
            require(address(trader) != address(0), "AmplesenseVault: trader not set");

            uint256 changeRatio18Digits = old_supply.mul(10**18).divDown(new_supply);
            uint256 surplus = new_balance.sub(new_balance.mul(changeRatio18Digits).divDown(10**18));

            uint256 for_eefi = surplus.mul(TRADE_POSITIVE_EEFI_100).divDown(100);
            uint256 for_eth = surplus.mul(TRADE_POSITIVE_ETH_100).divDown(100);
            uint256 for_pioneer1 = surplus.mul(TRADE_POSITIVE_PIONEER1_100).divDown(100);

            // 30% ampl remains in vault after positive rebase
            // use rebased AMPL to buy and burn eefi
            
            ampl_token.approve(address(trader), for_eefi.add(for_eth));

            trader.sellAMPLForEEFI(for_eefi, minimalExpectedEEFI);

           // 10% of purchased EEFI is sent to the DAO Treasury. The remaining 90% is burned. 
            uint256 balance = eefi_token.balanceOf(address(this));
            IERC20(address(eefi_token)).safeTransfer(treasury, balance.mul(TREASURY_EEFI_100).divDown(100));
            uint256 to_burn = eefi_token.balanceOf(address(this));
            eefi_token.burn(to_burn);
            emit Burn(to_burn);
            // buy eth and distribute to vaults
            trader.sellAMPLForEth(for_eth, minimalExpectedETH);
 
            uint256 to_rewards = address(this).balance.mul(TRADE_POSITIVE_REWARDS_100).divDown(100);
            uint256 to_pioneer2 = address(this).balance.mul(TRADE_POSITIVE_PIONEER2_100).divDown(100);
            uint256 to_pioneer3 = address(this).balance.mul(TRADE_POSITIVE_PIONEER3_100).divDown(100);
            uint256 to_lp_staking = address(this).balance.mul(TRADE_POSITIVE_LPSTAKING_100).divDown(100);
            
            rewards_eth.distribute{value: to_rewards}(to_rewards, address(this));
            pioneer_vault2.distribute_eth{value: to_pioneer2}();
            pioneer_vault3.distribute_eth{value: to_pioneer3}();
            staking_pool.distribute_eth{value: to_lp_staking}();

            // distribute ampl to pioneer 1
            ampl_token.approve(address(pioneer_vault1), for_pioneer1);
            pioneer_vault1.distribute(for_pioneer1);

            // distribute the remainder of purchased ETH (5%) to the DAO treasury
            Address.sendValue(treasury, address(this).balance);
        } else {
            // If AMPL supply is negative (lower) or equal (at eqilibrium/neutral), distribute EEFI rewards as follows; only if the minting_decay condition is not triggered
            if(last_positive + MINTING_DECAY > block.timestamp) { //if 90 days without positive rebase do not mint
                uint256 to_mint = new_balance.divDown(new_supply < last_ampl_supply ? EEFI_NEGATIVE_REBASE_RATE : EEFI_EQULIBRIUM_REBASE_RATE) * 10**9; /*multiplying by 10^9 because EEFI is 18 digits and not 9*/
                eefi_token.mint(address(this), to_mint);

                /* 
                EEFI Reward Distribution Overview: 

                - Trade Positive Rewards_100: Upon neutral/negative rebase, send 45% of EEFI rewards to users staking AMPL in vault 
                - Trade Positive Pioneer2_100: Upon neutral/negative rebase, send 10% of EEFI rewards to users staking kMPL in Pioneer Vault II (kMPL Stakers)
                - Trade Positive Pioneer3_100: Upon neutral/negative rebase, send 5% of EEFI rewards to users staking in Pioneer Vault III (kMPL/ETH LP Token Stakers) 
                - Trade Positive LP Staking_100: Upon neutral/negative rebase, send 35% of EEFI rewards to uses staking LP tokens (EEFI/ETH) 
                */


                uint256 to_rewards = to_mint.mul(TRADE_POSITIVE_REWARDS_100).divDown(100);
                uint256 to_pioneer2 = to_mint.mul(TRADE_POSITIVE_PIONEER2_100).divDown(100);
                uint256 to_pioneer3 = to_mint.mul(TRADE_POSITIVE_PIONEER3_100).divDown(100);
                uint256 to_lp_staking = to_mint.mul(TRADE_POSITIVE_LPSTAKING_100).divDown(100);

                eefi_token.increaseAllowance(address(rewards_eefi), to_rewards);
                eefi_token.increaseAllowance(address(pioneer_vault2.staking_contract_token()), to_pioneer2);
                eefi_token.increaseAllowance(address(pioneer_vault3.staking_contract_token()), to_pioneer3);
                eefi_token.increaseAllowance(address(staking_pool.staking_contract_token()), to_lp_staking);

                rewards_eefi.distribute(to_rewards, address(this));
                pioneer_vault2.distribute(to_pioneer2);
                pioneer_vault3.distribute(to_pioneer3);
                staking_pool.distribute(to_lp_staking);

                // distribute the remainder (5%) of EEFI to the treasury
                IERC20(eefi_token).safeTransfer(treasury, eefi_token.balanceOf(address(this)));
            }
        }
    }

    function claim() external {
        (uint256 eth, uint256 token) = getReward(msg.sender);
        rewards_eth.withdrawFrom(msg.sender, rewards_eth.totalStakedFor(msg.sender));
        rewards_eefi.withdrawFrom(msg.sender, rewards_eefi.totalStakedFor(msg.sender));
        emit Claimed(msg.sender, eth, token);
    }

    /**
        @dev Returns how much ETH and EEFI the user can withdraw currently
        @param account Address of the user to check reward for
        @return eth the amount of ETH the account will perceive if he unstakes now
        @return token the amount of tokens the account will perceive if he unstakes now
    */
    function getReward(address account) public view returns (uint256 eth, uint256 token) {
        eth = rewards_eth.getReward(account);
        token = rewards_eefi.getReward(account);
    }

    /**
        @return current staked
    */
    function totalStaked() external view returns (uint256) {
        return rewards_eth.totalStaked();
    }

    /**
        @dev returns the total rewards stored for token and eth
    */
    function totalReward() external view returns (uint256 token, uint256 eth) {
        token = rewards_eefi.getTotalReward();
        eth = rewards_eth.getTotalReward();
    }

    function _popDeposit() internal {
        for (uint i = 0; i < _deposits[msg.sender].length - 1; i++) {
            _deposits[msg.sender][i] = _deposits[msg.sender][i + 1];
        }
        _deposits[msg.sender].pop();
    }
}
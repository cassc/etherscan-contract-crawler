// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;


import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IValidatorShare } from "../interfaces/IValidatorShare.sol";
import { IStakeManager } from "../interfaces/IStakeManager.sol";
import { IMasterWhitelist } from "../interfaces/IMasterWhitelist.sol";

import { StakerStorage, Withdrawal } from "./StakerStorage.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

uint256 constant phiPrecision = 1e4;

contract Staker is StakerStorage, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _stakingTokenAddress,
        address _stakeManagerContractAddress,
        address _validatorShareContractAddress,
        address _whitelistAddress,
        address _treasuryAddress,
        uint256 _phi,
        uint256 _cap
    ) external initializer {
        // Put BaseContract.initialize() here if parent contracts are present
        // (using onlyInitializing modifier in parent initialize() fn)
        
        // OZ setup

        __ReentrancyGuard_init();
        __Ownable_init(); // set owner to msg.sender

        // set initial values for global variables

        stakingTokenAddress = _stakingTokenAddress;
        stakeManagerContractAddress = _stakeManagerContractAddress;
        validatorShareContractAddress = _validatorShareContractAddress;
        
        whitelistAddress = _whitelistAddress;

        treasuryAddress = _treasuryAddress;

        phi = _phi;
        cap = _cap;

        emit StakerInitialized(_stakingTokenAddress, _stakeManagerContractAddress, _validatorShareContractAddress, _treasuryAddress, _phi, _cap);
    }

    // --- Events ---

    event StakerInitialized(address _stakingTokenAddress, address _stakeManagerContractAddress, address _validatorShareContractAddress, address _treasuryAddress, uint256 _phi, uint256 _cap);

    // user tracking

    event Deposited(address _user, uint256 _treasuryShares, uint256 _userShares, uint256 _amount, uint256 _stakedAmount, uint256 _claimedRewards);
    
    event WithdrawalRequested(address _user, uint256 _treasuryShares, uint256 _userShares, uint256 _amount, uint256 _claimedRewards, uint256 _unbondNonce, uint256 _epoch);

    event WithdrawalClaimed(address _user, uint256 _unbondNonce, uint256 _amount);

    // global tracking

    event RewardsCompounded(uint256 _amount, uint256 _shares);

    // setter tracking

    event SetStakingToken(address _oldStakingToken, address _newStakingToken);

    event SetStakeManagerContract(address _oldStakeManagerContract, address _newStakeManagerContract);

    event SetValidatorShareContract(address _oldValidatorShareContract, address _newValidatorShareContract);

    event SetWhitelist(address _oldWhitelistAddress, address _newWhitelistAddress);
    
    event SetTreasury(address _oldTreasuryAddress, address _newTreasuryAddress);
    
    event SetCap(uint256 _oldCap, uint256 _newCap);
    
    event SetPhi(uint256 _oldPhi, uint256 _newPhi);

    // --- Setters ---
    
    function setStakingToken(address _stakingTokenAddress) external onlyOwner {
        emit SetStakingToken(stakingTokenAddress, _stakingTokenAddress);
        stakingTokenAddress = _stakingTokenAddress;
    }

    function setStakeManagerContract(address _stakeManagerContractAddress) external onlyOwner {
        emit SetStakeManagerContract(stakeManagerContractAddress, _stakeManagerContractAddress);
        stakeManagerContractAddress = _stakeManagerContractAddress;
    }

    function setValidatorShareContract(address _validatorShareContractAddress) external onlyOwner {
        emit SetValidatorShareContract(validatorShareContractAddress, _validatorShareContractAddress);
        validatorShareContractAddress = _validatorShareContractAddress;
    }

    function setWhitelist(address _whitelistAddress) external onlyOwner {
        emit SetWhitelist(whitelistAddress, _whitelistAddress);
        whitelistAddress = _whitelistAddress;
    }

    function setTreasury(address _treasuryAddress) external onlyOwner {
        emit SetTreasury(treasuryAddress, _treasuryAddress);
        treasuryAddress = _treasuryAddress;
    }

    function setCap(uint256 _cap) external onlyOwner {
        emit SetCap(cap, _cap);
        cap = _cap;
    }

    function setPhi(uint256 _phi) external onlyOwner {
        emit SetPhi(phi, _phi);
        phi = _phi;
    }

    // --- Helpers ---

    function totalStaked() public view returns (uint256) {
        return (IValidatorShare(validatorShareContractAddress).balanceOf(address(this)) * 1e29) / IValidatorShare(validatorShareContractAddress).exchangeRate();

        // return validatorShare.balanceOf(address(this)) * 1e29 / validatorShare.exchangeRate();
    }

    function totalRewards() public view returns (uint256) {
        return IValidatorShare(validatorShareContractAddress).getLiquidRewards(address(this));
    }
    
    function sharesFromAmount(uint256 _amount) public view returns (uint256 shares) {
        // this may introduce rounding errors
        // might have to replace the sharePrice function with something more integer-y
       
        return (_amount * 1e18) / sharePrice();
    }

    function amountFromShares(uint256 _shares) public view returns (uint256 amount) {
        return (_shares * sharePrice()) / 1e18;
    }

    function sharePrice() public view returns (uint256 price) {
        // precision used to avoid rounding errors (default 1e18)

        if (totalShares == 0) return 1e18;

        uint256 price_num = (((totalStaked() + claimedRewards) * phiPrecision + (phiPrecision - phi) * totalRewards()) * 1e18);
        uint256 price_denom = (totalShares * phiPrecision);

        price = price_num / price_denom;

        return price; // divide `price` by 1e18 to get actual floating point share price
    }

    function getDust() external view returns (uint256 dust) {
        // dust is phis that havent yet been turned into shares
        // it's the failure of total number of shares * share price to add up to total amount in stake + reward
        // return totalAmount + totalRewards() - amountFromShares(totalShares);
        return (totalRewards() * phi) / phiPrecision;
    }

    function getUnbondNonce() external view returns (uint256 unbondNonce) {
        // get latest unbond nonce from validator share
        return IValidatorShare(validatorShareContractAddress).unbondNonces(address(this));
    }

    function getCurrentEpoch() public view returns (uint256 epoch) {
        // get current epoch from stake manager
        return IStakeManager(stakeManagerContractAddress).epoch();
    }

    function isClaimable(uint256 _unbondNonce) external view returns (bool claimable) {
        // check if unbond nonce is claimable
        (, uint256 withdrawEpoch) = IValidatorShare(validatorShareContractAddress).unbonds_new(address(this), _unbondNonce);

        bool epochsPassed = getCurrentEpoch() >= withdrawEpoch + 80;

        bool withdrawalPresent = unbondingWithdrawals[_unbondNonce].user != address(0);

        return withdrawalPresent && epochsPassed;
    }

    modifier onlyWhitelist {
        require(
            IMasterWhitelist(whitelistAddress).isUserWhitelisted(msg.sender),
            "Whitelist: user not whitelisted"
        );
        _;
    }

    // --- Users Functions ---

    function deposit(uint256 _amount) external onlyWhitelist nonReentrant {
        _deposit(msg.sender, _amount);
    }

    function _deposit(address _user, uint256 _amount) private {
        require(
            totalStaked() + _amount <= cap,
            "Staker: deposit surpasses vault cap"
        );

        // calculate share increase
        uint256 shareIncreaseUser = (_amount * 1e18) / sharePrice();
        uint256 shareIncreaseTsy = (totalRewards() * phi * 1e18) / (sharePrice() * phiPrecision);

        // adjust global variables
        totalShares += shareIncreaseUser + shareIncreaseTsy;
        userShares[_user] += shareIncreaseUser;
        userShares[treasuryAddress] += shareIncreaseTsy;

        // piggyback previous withdrawn rewards in this staking call
        uint256 stakeAmount = _amount + claimedRewards;
        
        // update pending deposits as liquid rewards on validator share contract are set to zero
        claimedRewards = totalRewards();

        // transfer staking token from user to Staker
        IERC20Upgradeable(stakingTokenAddress).safeTransferFrom(_user, address(this), _amount);
        
        // approve funds to Stake Manager
        IERC20Upgradeable(stakingTokenAddress).safeIncreaseAllowance(stakeManagerContractAddress, stakeAmount);

        // interact with Validator Share contract to stake
        _stake(stakeAmount);

        emit Deposited(_user, shareIncreaseTsy, shareIncreaseUser, _amount, stakeAmount, claimedRewards);
    }

    // user shares goes down
    // user pending withdrawal amount goes up
    // total shares goes down
    // total pending withdrawal amount goes up
    function withdrawRequest(uint256 _amount) external onlyWhitelist nonReentrant {
        // funds stop accruing straight away, so decrease shares straight away and separate
        // unbonding funds into a different pool (in the form of a withdrawal request)
        require(
            amountFromShares(userShares[msg.sender]) >= _amount,
            "Staker: withdrawal amount requested too large"
        );
        require(
            _amount > 0,
            "Staker: withdrawal amount must be greater than zero"
        );

        // calculate share decrease
        uint256 shareDecreaseUser = (_amount * 1e18) / sharePrice();
        uint256 shareIncreaseTsy = (totalRewards() * phi * 1e18) / (sharePrice() * phiPrecision);

        // adjust global variables
        userShares[msg.sender] -= shareDecreaseUser;
        userShares[treasuryAddress] += shareIncreaseTsy;
        totalShares += shareIncreaseTsy;
        totalShares -= shareDecreaseUser;

        // increase pending deposits by automatically withdrawn rewards
        claimedRewards += totalRewards();

        // interact with staking contract to initiate unbonding
        uint256 unbondNonce = _unbond(_amount);

        // store used under unbond nonce, used for fair claiming
        unbondingWithdrawals[unbondNonce] = Withdrawal(msg.sender, _amount);

        // only once 80 epochs have passed can you claim
        uint256 epoch = IStakeManager(stakeManagerContractAddress).epoch();

        emit WithdrawalRequested(msg.sender, shareIncreaseTsy, shareDecreaseUser, _amount, claimedRewards, unbondNonce, epoch);
    }

    function withdrawClaim(uint256 _unbondNonce) external onlyWhitelist nonReentrant {
        // needed to make the function private because it's called multiple times in one
        // tx by claimList and want to avoid issues with nonReentrant
        
        _withdrawClaim(_unbondNonce);
    }

    function _withdrawClaim(uint256 _unbondNonce) private {
        // see comment in withdrawClaim for private scope explanation

        Withdrawal storage withdrawal = unbondingWithdrawals[_unbondNonce];
        
        require(
            withdrawal.user == msg.sender,
            "Staker: message sender must have initiated withdrawal request to claim"
        );

        // claim stake -- todo look into whether this causes a reward reset
        // claim will fail if unbonding not finished for this unbond nonce
        _claimStake(_unbondNonce);

        // transfer claimed matic to claimer
        IERC20Upgradeable(stakingTokenAddress).safeTransfer(msg.sender, withdrawal.amount);

        emit WithdrawalClaimed(msg.sender, _unbondNonce, withdrawal.amount);

        delete unbondingWithdrawals[_unbondNonce];
    }

    function claimList(uint256[] calldata _unbondNonces) external onlyWhitelist nonReentrant {
        uint256 size = _unbondNonces.length;

        for (uint256 i = 0; i < size;) {
            _withdrawClaim(_unbondNonces[i]);

            unchecked { i++; }
        }
    }

    // --- Interaction with Polygon staking contract (Staker) ---

    function _stake(uint256 _amount) private {
        IValidatorShare(validatorShareContractAddress).buyVoucher(_amount, _amount);
        // as exchange rate is constant, this is fine for now
        // but once slashing is implemented some slippage acceptance might be necessary
        
        // (uint256 amountToDeposit)
        // buyVoucher example: https://goerli.etherscan.io/address/0x0b764b080a67f9019677ae2c9279f52485fd4525#writeProxyContract

        // currently assuming the entire amount was used to stake -- apparently may not always be the case?
        // see https://goerli.etherscan.io/address/0x41a9c376ec9089e91d453d3ac6b0ff4f4fd7ccec#code _buyVoucher() fn
    }

    function _unbond(uint256 _amount) private returns (uint256 unbondNonce) {
        // Takes 3 days, rewards stop accruing immediately
        IValidatorShare(validatorShareContractAddress).sellVoucher_new(_amount, _amount);
        // as exchange rate is constant, this is fine for now
        // but once slashing is implemented some slippage acceptance might be necessary

        return IValidatorShare(validatorShareContractAddress).unbondNonces(address(this));
    }

    function _claimStake(uint256 _unbondNonce) private {
        // transfer all unstaked MATIC to vault in original unbonding call
        IValidatorShare(validatorShareContractAddress).unstakeClaimTokens_new(_unbondNonce);
    }

    function _restake() private {
        // no longer returning amoutnRestaked because order of compoundRewards() fn was changed_
        IValidatorShare(validatorShareContractAddress).restake();
        // ^^^ this actually returns (uint256 amountRestaked, uint256 liquidReward)
        // is it possible not everything is restaked? look into this, might have to change compoundRewards() fn
    }

    // --- Compounding Rewards ---

    function stakeClaimedRewards() external nonReentrant {
        // global fn: stake claimedRewards

        _deposit(address(0), 0);
    }

    function compoundRewards() external nonReentrant {
        // global fn: This function can be called by anyone.  Caller pays the gas.
        // We will have a cron-job that checks if rewards are above a threshold and call restake ourselves if so.
        
        uint256 amountRestaked = totalRewards();

        // to keep share price constant when rewards are staked, new shares need to be minted
        uint256 shareIncrease = sharesFromAmount(totalStaked() + amountRestaked + claimedRewards) - totalShares; // todo is this skewed by claimedRewards?
        // calculating shareIncrease before calling _restake() because restaking sets unstaked rewards
        // to zero, messing up the share price function

        // restake as many rewards as possible
        // uint256 amountRestaked = _restake();
        _restake();

        // these are given to the treasury to effectively take a phi
        // totalShares also increases, zeroing the dust balance by definition
        userShares[treasuryAddress] += shareIncrease;
        totalShares += shareIncrease; // share value decrease

        // rewards are added to the totalAmount
        // totalAmount += amountRestaked; // share value increase
        
        // totalRewards() should now return previous totalRewards() - (liquidReward - amountRestaked)

        emit RewardsCompounded(amountRestaked, shareIncrease);
    }

    // TODO: add a minimum restake amount to the public restaking function, to avoid attackers from spamming unbonds and
    // forcing us to pay for the unclaim transaction gas fee

    // TODO: have an admin restake function for any amount so that we can withdraw the treasury amounts
    
    // --- Temp debug functions ---

    // function artificialDepositNotice(uint256 _amount) external onlyOwner {
    //     require(
    //         totalShares == 0,
    //         "Staker: (DEBUG) total shares must equal zero to artificial deposit"
    //     );
        
    //     // adjust global variables
    //     userShares[msg.sender] += _amount;
    //     totalShares += _amount;

    //     emit Deposited(msg.sender, 0, _amount, _amount, _amount, 0);
    // }

    // function rescueFunds() external onlyOwner {
    //     payable(msg.sender).transfer(address(this).balance);
    //     // IERC20(stakingTokenAddress).transfer(msg.sender, IERC20(stakingTokenAddress).balanceOf(address(this)));
    //     IERC20Upgradeable(stakingTokenAddress).safeTransfer(msg.sender, IERC20Upgradeable(stakingTokenAddress).balanceOf(address(this)));
    // }

    // function transferStake(address _receiver) external onlyOwner {
    //     uint256 amount = IValidatorShare(validatorShareContractAddress).balanceOf(address(this));
    
    //     IValidatorShare(validatorShareContractAddress).transfer(_receiver, amount);
    // }
}
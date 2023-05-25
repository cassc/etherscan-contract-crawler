// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

import {IValidatorShare} from "../interfaces/IValidatorShare.sol";
import {IStakeManager} from "../interfaces/IStakeManager.sol";
import {IMasterWhitelist} from "../interfaces/IMasterWhitelist.sol";
import {TruStakeMATICv2Storage, Withdrawal, Allocation} from "./TruStakeMATICv2Storage.sol";

import {
    ERC4626Upgradeable,
    ERC20Upgradeable,
    IERC20MetadataUpgradeable,
    IERC20Upgradeable,
    SafeERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

uint256 constant phiPrecision = 1e4;

/// @title TruStakeMATIC
/// @author Pietro Demicheli & Tiffany Gerstmeyr (Field Labs)

contract TruStakeMATICv2 is
    TruStakeMATICv2Storage,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC4626Upgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice initializer function
    /// @dev not validating parameters for addresses, there is no reason to disallow the
    ///   zero address as it can always be changed by the owner
    /// @dev this contract is built only for MATIC staking on the ETH mainnet or the
    ///   Goerli testnet
    /// @param _stakingTokenAddress MATIC token contract
    /// @param _stakeManagerContractAddress stake manager contract deployed by Polygon
    /// @param _validatorShareContractAddress one of many Validator Share contracts
    ///   deployed by a Polygon validator
    /// @param _whitelistAddress whitelist contract for limiting access
    /// @param _treasuryAddress treasury address to receive fees
    /// @param _phi fee taken on restake in basis points
    /// @dev phi validated: phi must be less than or equal to precision
    /// @param _distPhi distribution fee taken on non-strict reward distributions
    /// @param _cap cap on contract balance limiting deposits
    function initialize(
        address _stakingTokenAddress,
        address _stakeManagerContractAddress,
        address _validatorShareContractAddress,
        address _whitelistAddress,
        address _treasuryAddress,
        uint256 _phi,
        uint256 _distPhi,
        uint256 _cap
    ) external initializer {
        // OZ setup

        __ReentrancyGuard_init();
        __Ownable_init(); // set owner to msg.sender
        __ERC4626_init(IERC20Upgradeable(_stakingTokenAddress));

        // set initial values for global variables

        stakingTokenAddress = _stakingTokenAddress;
        stakeManagerContractAddress = _stakeManagerContractAddress;
        validatorShareContractAddress = _validatorShareContractAddress;

        whitelistAddress = _whitelistAddress;

        treasuryAddress = _treasuryAddress;

        if (_phi > phiPrecision) {
            revert PhiTooLarge();
        }

        phi = _phi;
        cap = _cap;
        distPhi = _distPhi;
        epsilon = 1e4;
        allowStrict = false; // strictness disabled until fully implemented

        emit StakerInitialized(
            _stakingTokenAddress,
            _stakeManagerContractAddress,
            _validatorShareContractAddress,
            _whitelistAddress,
            _treasuryAddress,
            _phi,
            _cap,
            _distPhi
        );
    }

    // --- Events ---

    /// @notice emitted on initialize
    /// @dev params same as initialize function
    event StakerInitialized(
        address _stakingTokenAddress,
        address _stakeManagerContractAddress,
        address _validatorShareContractAddress,
        address _whitelistAddress,
        address _treasuryAddress,
        uint256 _phi,
        uint256 _cap,
        uint256 _distPhi
    );

    // user tracking

    /// @notice emitted on user deposit
    /// @param _user user which made the deposit tx
    /// @param _treasuryShares newly minted shares added to the treasury user's balance
    /// @param _userShares newly minted shares added to the depositing user's balance
    /// @param _amount amount of MATIC transferred by user into the staker
    /// @param _stakedAmount _amount + any auto-claimed MATIC rewards sitting in the
    ///   staker from previous deposits or withdrawal requests made by any user
    /// @param _totalAssets auto-claimed MATIC rewards that will sit in the staker
    ///   until the next deposit made by any user
    event Deposited(
        address indexed _user,
        uint256 _treasuryShares,
        uint256 _userShares,
        uint256 _amount,
        uint256 _stakedAmount,
        uint256 _totalAssets
    );

    /// @notice emitted on user requesting a withdrawal
    /// @param _user user which made the withdraw request tx
    /// @param _treasuryShares newly minted shares added to the treasury user's balance
    ///   (fees taken: shares are newly minted as a result of the auto-claimed MATIC rewards)
    /// @param _userShares burnt shares removed from the depositing user's balance
    /// @param _amount amount of MATIC unbonding, which will be claimable by user in
    ///   80 checkpoints
    /// @param _totalAssets auto-claimed MATIC rewards that will sit in the staker
    ///   until the next deposit made by any user
    /// @param _unbondNonce nonce of this unbond, which will be passed into the function
    ///   `withdrawClaim(uint256 _unbondNonce)` in 80 checkpoints in order to claim this
    ///   the amount from this request
    /// @param _epoch the current checkpoint the stake manager is at, used to track how
    ///   how far from claiming the request is
    event WithdrawalRequested(
        address indexed _user,
        uint256 _treasuryShares,
        uint256 _userShares,
        uint256 _amount,
        uint256 _totalAssets,
        uint256 indexed _unbondNonce,
        uint256 indexed _epoch
    );

    /// @notice emitted on user claiming a withdrawal
    /// @param _user user which made the withdraw claim tx
    /// @param _unbondNonce nonce of the original withdrawal request, which was passed
    ///   into the `withdrawClaim` function
    /// @param _amount amount of MATIC claimed from staker (originally from stake manager)
    event WithdrawalClaimed(
        address indexed _user,
        uint256 indexed _unbondNonce,
        uint256 _amount
    );

    // global tracking

    /// @notice emitted on rewards compound call
    /// @param _amount amount of MATIC moved from rewards on the validator to staked funds
    /// @param _shares newly minted shares added to the treasury user's balance (fees taken)
    event RewardsCompounded(
        uint256 _amount,
        uint256 _shares
    );

    // allocations

    /// @notice emitted on allocation 
    /// @param _distributor address of user who has allocated to someone else
    /// @param _recipient address of user to whom something was allocated
    /// @param _individualAmount total amount allocated to recipient by this distributor
    /// @param _individualNum average share price numerator at which allocations occurred
    /// @param _individualDenom average share price denominator at which allocations occurred
    /// @param _totalAmount total amount distributor has allocated
    /// @param _totalNum average share price numerator at which distributor allocated
    /// @param _totalDenom average share price denominator at which distributor allocated
    /// @param _strict bool to determine whether deallocation of funds allocated here should
    ///   be subject to checks or not
    event Allocated(
        address indexed _distributor,
        address indexed _recipient,
        uint256 _individualAmount,
        uint256 _individualNum,
        uint256 _individualDenom,
        uint256 _totalAmount,
        uint256 _totalNum,
        uint256 _totalDenom,
        bool indexed _strict
    );

    /// @notice emitted on deallocations
    /// @param _distributor address of user who has allocated to someone else
    /// @param _recipient address of user to whom something was allocated
    /// @param _individualAmount remaining amount allocated to recipient
    /// @param _totalAmount total amount distributor has allocated
    /// @param _totalNum average share price numerator at which distributor allocated
    /// @param _totalDenom average share price denominator at which distributor allocated
    /// @param _strict bool to determine whether the deallocation of these funds was
    ///   subject to strictness checks or not
    event Deallocated(
        address indexed _distributor,
        address indexed _recipient,
        uint256 _individualAmount,
        uint256 _totalAmount,
        uint256 _totalNum,
        uint256 _totalDenom,
        bool indexed _strict
    );

    /// @notice emitted on reallocations
    /// @param _distributor address of user who is switching allocation recipient
    /// @param _oldRecipient previous recipient of allocated rewards
    /// @param _newRecipient new recipient of allocated rewards
    /// @param _newAmount matic amount stored in allocation of the new recipient
    /// @param _newNum numerator of share price stored in allocation of the new recipient
    /// @param _newDenom denominator of share price stored in allocation of the new recipient
    event Reallocated(
        address indexed _distributor,
        address indexed _oldRecipient,
        address indexed _newRecipient,
        uint256 _newAmount,
        uint256 _newNum,
        uint256 _newDenom
    );

    /// @notice emitted when rewards are distributed
    /// @param _distributor address of user who has allocated to someone else
    /// @param _recipient address of user to whom something was allocated
    /// @param _amount amount of matic being distributed
    /// @param _shares amount of shares being distributed
    /// @param _individualNum average share price numerator at which distributor allocated
    /// @param _individualDenom average share price numerator at which distributor allocated
    /// @param _totalNum average share price numerator at which distributor allocated
    /// @param _totalDenom average share price denominator at which distributor allocated
    /// @param _strict bool to determine whether these funds came from the strict or
    ///   non-strict allocation mappings
    event DistributedRewards(
        address indexed _distributor,
        address indexed _recipient,
        uint256 _amount,
        uint256 _shares,
        uint256 _individualNum,
        uint256 _individualDenom,
        uint256 _totalNum,
        uint256 _totalDenom,
        bool indexed _strict
    );

    /// @notice emitted when rewards are distributed
    /// @param _distributor address of user who has allocated to someone else
    /// @param _curNum current share price numerator
    /// @param _curDenom current share price denominator
    /// @param _strict bool to determine whether these funds came from the strict or
    ///   non-strict allocation mappings
    event DistributedAll(
        address indexed _distributor,
        uint256 _curNum,
        uint256 _curDenom,
        bool indexed _strict
    );

    // setter tracking

    event SetStakingToken(address _oldStakingToken, address _newStakingToken);

    event SetStakeManagerContract(address _oldStakeManagerContract, address _newStakeManagerContract);

    event SetValidatorShareContract(address _oldValidatorShareContract, address _newValidatorShareContract);

    event SetWhitelist(address _oldWhitelistAddress, address _newWhitelistAddress);

    event SetTreasury(address _oldTreasuryAddress, address _newTreasuryAddress);

    event SetCap(uint256 _oldCap, uint256 _newCap);

    event SetPhi(uint256 _oldPhi, uint256 _newPhi);
    
    event SetDistPhi(uint256 _oldDistPhi, uint256 _newDistPhi);

    event SetEpsilon(uint256 _oldEpsilon, uint256 _newEpsilon);

    event SetAllowStrict(bool _oldAllowStrict, bool _newAllowStrict);


    // --- Errors ---

    /// @notice error thrown when the phi value is larger than the phi precision constant
    error PhiTooLarge();

    /// @notice error thrown when a user tries to interact with a whitelisted-only function
    error UserNotWhitelisted();

    /// @notice error thrown when a user tries to deposit under 1 MATIC
    error DepositUnderOneMATIC();

    /// @notice error thrown when a deposit causes the vault staked amount to surpass the cap
    error DepositSurpassesVaultCap();

    /// @notice error thrown when a user tries to request a withdrawal with an amount larger
    ///   than their shares entitle them to
    error WithdrawalAmountTooLarge();

    /// @notice error thrown when a user tries to request a withdrawal of amount zero
    error WithdrawalRequestAmountCannotEqualZero();

    /// @notice error thrown when a user tries to claim a withdrawal they did not request
    error SenderMustHaveInitiatedWithdrawalRequest();

    /// @notice error used in ERC-4626 integration, thrown when user tries to act on
    ///   behalf of different user
    error SenderAndOwnerMustBeReceiver();

    /// @notice error used in ERC-4626 integration, thrown when user tries to transfer
    ///   or approve to zero address
    error ZeroAddressNotSupported();

    /// @notice error thrown when user allocates more MATIC than available 
    error InsufficientDistributorBalance();

    /// @notice error thrown when user calls distributeRewards for 
    ///   recipient with nothing allocated to them
    error NoRewardsAllocatedToRecipient();

    /// @notice error thrown when user calls distributeRewards when the allocation
    ///   share price is the same as the current share price
    error NothingToDistribute();

    /// @notice error thrown when a user tries to a distribute rewards allocated by
    ///   a different user
    error OnlyDistributorCanDistributeRewards();

    /// @notice error thrown when a user tries to transfer more share than their
    ///   balance subtracted by the total amount they have strictly allocated
    error ExceedsUnallocatedBalance();

    /// @notice error thrown when a user attempts to allocate zero shares
    error CannotAllocateZero();

    /// @notice error thrown when a user tries to reallocate from a user they do
    ///   not currently have anything allocated to
    error AllocationNonExistent();

    /// @notice error thrown when a user tries to strictly allocate but `allowStrict`
    ///   has been set to false
    error StrictAllocationDisabled();

    // --- Setters ---

    function setStakingToken(address _stakingTokenAddress) external onlyOwner {
        emit SetStakingToken(stakingTokenAddress, _stakingTokenAddress);
        stakingTokenAddress = _stakingTokenAddress;
    }

    function setStakeManagerContract(
        address _stateManagerContract
    ) external onlyOwner {
        emit SetStakeManagerContract(
            stakeManagerContractAddress,
            _stateManagerContract
        );
        stakeManagerContractAddress = _stateManagerContract;
    }

    function setValidatorShareContract(
        address _validatorShareContractAddress
    ) external onlyOwner {
        emit SetValidatorShareContract(
            validatorShareContractAddress,
            _validatorShareContractAddress
        );
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

    /// @dev phi validated: phi must be less than or equal to precision
    function setPhi(uint256 _phi) external onlyOwner {
        if (_phi > phiPrecision) {
            revert PhiTooLarge();
        }

        emit SetPhi(phi, _phi);
        phi = _phi;
    }

    function setDistPhi(uint256 _distPhi) external onlyOwner {
        if (_distPhi > phiPrecision) {
            revert PhiTooLarge();
        }

        emit SetDistPhi(distPhi, _distPhi);
        distPhi = _distPhi;
    }

    function setEpsilon(uint256 _epsilon) external onlyOwner {
        emit SetEpsilon(epsilon, _epsilon);
        epsilon = _epsilon;
    }

    /// @dev making sender specify true/false rather than using a toggle function in
    ///   order to prevent accidents, meaning it could be set to the existing value
    function setAllowStrict(bool _allowStrict) external onlyOwner {
        emit SetAllowStrict(allowStrict, _allowStrict);
        allowStrict = _allowStrict;
    }

    // --- Helpers ---

    /// @notice get total amount of MATIC currently staked by vault
    /// @dev added exchange rate just in case slashing is introduced, although it is
    ///   currently a constant value of 1e29 (1 to a certain degree of precision)
    function totalStaked() public view returns (uint256) {
        return
            (IValidatorShare(validatorShareContractAddress).balanceOf(
                address(this)
            ) * 1e29) /
            IValidatorShare(validatorShareContractAddress).exchangeRate();
    }

    /// @notice get total amount of MATIC as accrued rewards
    /// @dev this can only be restaked if greater than or equal to 10 MATIC
    function totalRewards() public view returns (uint256) {
        return
            IValidatorShare(validatorShareContractAddress).getLiquidRewards(
                address(this)
            );
    }

    /// @notice calculate share price
    /// @dev precision of 1e18 used to avoid rounding errors
    /// @return priceNum numerator of share price, divide by (priceDenom * 1e18) to
    ///   get actual floating point share price
    /// @dev this represents the price of one TruMATIC in MATIC (share price, a.k.a.
    ///   price of one share)
    /// @return priceDenom denominator of share price
    function sharePrice() public view returns (uint256, uint256) {
        if (totalSupply() == 0) return (1e18, 1);
        uint256 totalCapitalTimesPhiPrecision = (totalStaked() + totalAssets()) * phiPrecision + (phiPrecision - phi) * totalRewards();
        uint256 globalPriceNum = totalCapitalTimesPhiPrecision * 1e18;
        uint256 globalPriceDenom = totalSupply() * phiPrecision;

        return (globalPriceNum, globalPriceDenom);
    }

    /// @notice calculate dust
    /// @dev dust is the failure of (total number of shares * share price) to add up
    ///   to (total amount in stake + reward)
    /// @return dust is equal to fees that havent yet been turned into shares
    function getDust() external view returns (uint256 dust) {
        return (totalRewards() * phi) / phiPrecision;
    }

    /// @notice get latest unbond nonce from validator share
    /// @dev used to index withdrawal requests
    function getUnbondNonce() external view returns (uint256 unbondNonce) {
        return
            IValidatorShare(validatorShareContractAddress).unbondNonces(
                address(this)
            );
    }

    /// @notice get current epoch from stake manager
    /// @dev used to see how far a withdrawal request is from being claimable
    /// @dev a claim on an unbond nonce can be made 80 checkpoints/epochs after a request
    function getCurrentEpoch() public view returns (uint256 epoch) {
        return IStakeManager(stakeManagerContractAddress).epoch();
    }

    /// @notice check if unbond nonce is claimable
    /// @dev check the withdrawal hasn't already been claimed AND that 80 checkpoints
    ///   have passed since request for withdrarwal
    /// @param _unbondNonce unbond nonce to check claimability of
    /// @return claimable bool to determine whether the unbond nonce can be claimed or if
    ///   an attempt to claim would cause a revertion
    function isClaimable(
        uint256 _unbondNonce
    ) external view returns (bool claimable) {
        (, uint256 withdrawEpoch) = IValidatorShare(
            validatorShareContractAddress
        ).unbonds_new(address(this), _unbondNonce);

        bool epochsPassed = getCurrentEpoch() >= withdrawEpoch + 80;

        bool withdrawalPresent = unbondingWithdrawals[_unbondNonce].user !=
            address(0);

        return withdrawalPresent && epochsPassed;
    }

    /// @notice only allow whitelisted users to interact with certain functions
    modifier onlyWhitelist() {
        if (!IMasterWhitelist(whitelistAddress).isUserWhitelisted(msg.sender)) {
            revert UserNotWhitelisted();
        }
        _;
    }

    /// @notice helper view function to get list of distributors for a given recipient
    /// @param _user recipient to get list of distributors for
    /// @param _strict whether to get distributors who have made strict allocations
    ///   or non-strict allocations
    function getDistributors(address _user, bool _strict) public view returns (address[] memory) {
        return distributors[_user][_strict];
    }

    /// @notice helper view function to get list of recipients for a given distributor
    /// @param _user distributor to get list of recipients for
    /// @param _strict whether to get users on the receiving end of strict allocations
    ///   or non-strict allocations
    function getRecipients(address _user, bool _strict) public view returns (address[] memory) {
        return recipients[_user][_strict];
    }

    // --- Users Functions ---

    /// @notice private function used for depositing/staking MATIC
    /// @param _user user which is depositing
    /// @param _amount amount of MATIC being deposited/staked
    /// @dev public and private function used in combination so that `stakeClaimedRewards()`
    ///   function is possible
    /// @dev using `_mint` as opposed to `_deposit` because nothing needs to be transferred
    ///   for minting of treasury shares
    function _deposit(address _user, uint256 _amount) private {
        if (_amount < 1e18 && _amount > 0) {
            revert DepositUnderOneMATIC();
        }

        if (_amount > maxDeposit(_user)) {
            revert DepositSurpassesVaultCap();
        }

        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        // calculate share increase
        uint256 shareIncreaseUser = convertToShares(_amount);
        uint256 shareIncreaseTsy = (totalRewards() * phi * 1e18 * globalPriceDenom) /
            (globalPriceNum * phiPrecision);

        // piggyback previous withdrawn rewards in this staking call
        uint256 stakeAmount = _amount + totalAssets();
        // adjust share balances
        if (_user != address(0)) {
            _mint(_user, shareIncreaseUser);
            emit Deposit(_user, _user, _amount, shareIncreaseUser);
            // erc-4626 event needed for integration
        }

        _mint(treasuryAddress, shareIncreaseTsy);
        emit Deposit(_user, treasuryAddress, 0, shareIncreaseTsy);
        // erc-4626 event needed for integration
      
        // transfer staking token from user to Staker
        IERC20Upgradeable(stakingTokenAddress).safeTransferFrom(
            _user,
            address(this),
            _amount
        );

        // approve funds to Stake Manager
        IERC20Upgradeable(stakingTokenAddress).safeIncreaseAllowance(
            stakeManagerContractAddress,
            stakeAmount
        );

        // interact with Validator Share contract to stake
        _stake(stakeAmount);
        // claimed rewards increase here as liquid rewards on validator share contract
        // are set to zero rewards are transferred to this vault

        emit Deposited(
            _user,
            shareIncreaseTsy,
            shareIncreaseUser,
            _amount,
            stakeAmount,
            totalAssets()
        );
    }

    /// @notice private function used to allow for erc-4626 integration, initates a
    ///   withdrawal i.e. start unbonding a portion of or all of their stake
    /// @dev using `_mint` and `_burn` as opposed to `_deposit` and `_withdraw` because
    ///   withdrawal is split into two parts, nothing needs to be transferred
    /// @dev funds stop accruing straight away, so shares are decreased straight away and
    ///   unbonding funds are separated into a different pool (in the form of a withdrawal
    ///   request)
    /// @param _user user who is requesting a withdrawal
    /// @param _amount amount of MATIC to request withdrawal of
    function _withdrawRequest(address _user, uint256 _amount) private {
        if (_amount == 0) {
            revert WithdrawalRequestAmountCannotEqualZero();
        }

        if (_amount > maxWithdraw(_user)) {
            revert WithdrawalAmountTooLarge();
        }

        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        // calculate share decrease
        
        uint256 shareDecreaseUser = (_amount * globalPriceDenom * 1e18) / globalPriceNum;
        
        uint256 shareIncreaseTsy = (totalRewards() * phi * globalPriceDenom * 1e18) /
            (globalPriceNum * phiPrecision);

        // adjust share balances

        // As a result of epsilon, it's possible to attempt to withdraw more shares than your
        // balance. This would enivitably result in an underflow, so we just burn the max of
        // user balance and withdrawing amount as shares.
        uint256 sharesBurntUser = (shareDecreaseUser > balanceOf(_user))
            ? balanceOf(_user)
            : shareDecreaseUser;

        _burn(_user, sharesBurntUser);
        emit Withdraw(_user, _user, _user, _amount, shareDecreaseUser); // erc-4626 event needed for integration

        _mint(treasuryAddress, shareIncreaseTsy);
        emit Deposit(_user, treasuryAddress, 0, shareIncreaseTsy); // erc-4626 event needed for integration

        // interact with staking contract to initiate unbonding
        uint256 unbondNonce = _unbond(_amount);

        // store used under unbond nonce, used for fair claiming
        unbondingWithdrawals[unbondNonce] = Withdrawal(_user, _amount);

        // only once 80 epochs have passed can this be claimed
        uint256 epoch = getCurrentEpoch();

        emit WithdrawalRequested(
            _user,
            shareIncreaseTsy,
            shareDecreaseUser,
            _amount,
            totalAssets(),
            unbondNonce,
            epoch
        );
    }

    /// @notice public function for claiming a withdrawal
    /// @param _unbondNonce unbond nonce (effectively id) of withdrawal request
    /// @dev public & private fn used in combination because `_withdrawClaim()` is called
    ///   multiple times in one tx by `claimList()` this avoids issues with nonReentrant
    function withdrawClaim(
        uint256 _unbondNonce
    ) external onlyWhitelist nonReentrant {
        _withdrawClaim(_unbondNonce);
    }

    /// @notice private function for claiming a withdrawal
    /// @param _unbondNonce unbond nonce (effectively id) of withdrawal request
    /// @dev public & private fn used in combination because `_withdrawClaim()` is called
    ///   multiple times in one tx by `claimList()` this avoids issues with nonReentrant
    function _withdrawClaim(uint256 _unbondNonce) private {
        Withdrawal storage withdrawal = unbondingWithdrawals[_unbondNonce];

        if (withdrawal.user != msg.sender) {
            revert SenderMustHaveInitiatedWithdrawalRequest();
        }

        // claim will revert if unbonding not finished for this unbond nonce
        _claimStake(_unbondNonce);

        // transfer claimed matic to claimer
        IERC20Upgradeable(stakingTokenAddress).safeTransfer(
            msg.sender,
            withdrawal.amount
        );

        emit WithdrawalClaimed(msg.sender, _unbondNonce, withdrawal.amount);

        delete unbondingWithdrawals[_unbondNonce];
    }

    /// @notice function for a user to claim several withdrawal requests
    /// @param _unbondNonces list of unbond nonces (effectively ids) of withdrawal requests
    function claimList(
        uint256[] calldata _unbondNonces
    ) external onlyWhitelist nonReentrant {
        uint256 len = _unbondNonces.length;

        for (uint256 i = 0; i < len; ) {
            _withdrawClaim(_unbondNonces[i]);

            unchecked {
                i++;
            }
        }
    }

    // --- Interaction with Polygon staking contract (Staker) ---

    /// @notice private function to stake MATIC with the validator
    /// @param _amount amount of MATIC to stake with the validator share contract
    /// @dev as exchange rate is constant, this is fine for now
    ///   but once slashing is implemented some slippage acceptance might be necessary
    /// @dev buyVoucher tx example: 0x0b764b080a67f9019677ae2c9279f52485fd4525
    /// @dev buyVoucher tx example: 0x41a9c376ec9089e91d453d3ac6b0ff4f4fd7ccec
    /// @dev currently assuming the entire amount was used to stake --
    ///   apparently may not always be the case?
    function _stake(uint256 _amount) private {
        IValidatorShare(validatorShareContractAddress).buyVoucher(
            _amount,
            _amount
        );
    }

    /// @notice private function to unbond MATIC from the validator
    /// @param _amount amount of MATIC to unbond from the validator share contract
    /// @return unbondNonce unbond nonce of withdrawal request
    /// @dev takes 3 days, rewards stop accruing immediately
    /// @dev as exchange rate is constant, this is fine for now
    ///   but once slashing is implemented some slippage acceptance might be necessary
    function _unbond(uint256 _amount) private returns (uint256 unbondNonce) {
        IValidatorShare(validatorShareContractAddress).sellVoucher_new(
            _amount,
            _amount
        );

        return
            IValidatorShare(validatorShareContractAddress).unbondNonces(
                address(this)
            );
    }

    /// @notice private function to claim a MATIC amount from a previous unbond
    /// @param _unbondNonce nonce returned when inital unbond tx was made
    function _claimStake(uint256 _unbondNonce) private {
        IValidatorShare(validatorShareContractAddress).unstakeClaimTokens_new(
            _unbondNonce
        );
    }

    /// @notice private function to restake MATIC
    /// @dev turns rewards accrued on the validator into staked MATIC earning rewards
    function _restake() private {
        IValidatorShare(validatorShareContractAddress).restake();
    }

    // --- Compounding Rewards ---

    /// @notice global function to stake claimed rewards
    /// @dev when rewards are auto-claimed in any user's deposit or withdrawal request,
    ///   this function can be used to stake that extra MATIC balance of the vault
    function stakeClaimedRewards() external nonReentrant {
        _deposit(address(0), 0);
    }

    /// @notice global function to restake incl. taking fees using treasury shares
    /// @dev this function can be called by anyone, caller pays the gas
    /// @dev we will have a cron-job that checks if rewards are above a threshold and
    ///   call restake ourselves if so
    function compoundRewards() external nonReentrant {
        uint256 amountRestaked = totalRewards();

        // to keep share price constant when rewards are staked, new shares need to be minted
        uint256 shareIncrease = convertToShares(
            totalStaked() + amountRestaked + totalAssets()
        ) - totalSupply();
        
        // calculating shareIncrease before calling _restake() because restaking sets unstaked rewards
        // to zero, messing up the share price functions

        // restake as many rewards as possible
        _restake();

        // these are given to the treasury to effectively take a phi
        // totalSupply also increases, zeroing the dust balance by definition
        _mint(treasuryAddress, shareIncrease);
        emit Deposit(msg.sender, treasuryAddress, 0, shareIncrease); // erc-4626 event needed for integration

        // totalRewards() should now return previous totalRewards() - (liquidReward - amountRestaked)

        emit RewardsCompounded(amountRestaked, shareIncrease);
    }

    /// @notice function to allocate staked MATIC to a user
    /// @dev when users allocate an amount of staked MATIC to a recipient, the recipient receives
    ///   the staking rewards for the allocated amount but not the amount itself
    /// @param _amount amount of matic msg.sender is allocating
    /// @param _recipient address of user to whom msg.sender is allocating
    /// @param _strict bool to determine whether the deallocation of the funds allocated here should be subject to checks or not
    function allocate(
        uint256 _amount,
        address _recipient,
        bool _strict
    ) external onlyWhitelist nonReentrant {
        if (_strict == true && allowStrict == false) {
            revert StrictAllocationDisabled();
        }

        if (_amount > maxWithdraw(msg.sender)) { 
            // not strictly necessary but used anyway for non-strict allocations
            revert InsufficientDistributorBalance();
        }

        if (_amount == 0){
            revert CannotAllocateZero();
        }

        uint256 individualAmount;
        uint256 individualPriceNum;
        uint256 individualPriceDenom;

        uint256 totalAmount;
        uint256 totalNum;
        uint256 totalDenom;
        // variables up here for stack too deep issues

        {
            (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

            Allocation storage oldIndividualAllocation = allocations[msg.sender][_recipient][_strict];

            if (oldIndividualAllocation.maticAmount == 0) {
                // if this is a new allocation
                individualAmount = _amount;
                individualPriceNum = globalPriceNum;
                individualPriceDenom = globalPriceDenom;

                // update mappings to keep track of recipients for each dist and vice versa
                distributors[_recipient][_strict].push(msg.sender);
                recipients[msg.sender][_strict].push(_recipient);
            } else {
                // performing update allocation

                individualAmount = oldIndividualAllocation.maticAmount + _amount;

                individualPriceNum = oldIndividualAllocation.maticAmount * 1e22 + _amount * 1e22;

                individualPriceDenom =
                    MathUpgradeable.mulDiv(
                        oldIndividualAllocation.maticAmount * 1e22,
                        oldIndividualAllocation.sharePriceDenom,
                        oldIndividualAllocation.sharePriceNum,
                        MathUpgradeable.Rounding.Down)
                    + MathUpgradeable.mulDiv(
                        _amount * 1e22,
                        globalPriceDenom,
                        globalPriceNum,
                        MathUpgradeable.Rounding.Down);
                
                // rounding individual allocation share price denominator DOWN, in order to maximise the individual allocation share price
                // which minimises the amount that is distributed in `distributeRewards()`
            }

            allocations[msg.sender][_recipient][_strict] = Allocation(individualAmount, individualPriceNum, individualPriceDenom);         

            // set or update total allocation value for user

            Allocation storage totalAllocation = totalAllocated[msg.sender][_strict];
            
            if (totalAllocation.maticAmount == 0) {
                // set total allocated amount + share price

                totalAmount = _amount;
                totalNum = globalPriceNum;
                totalDenom = globalPriceDenom;
            } else {
                // update total allocated amount + share price

                totalAmount = totalAllocation.maticAmount + _amount;

                totalNum = totalAllocation.maticAmount * 1e22 + _amount * 1e22;

                totalDenom =
                    MathUpgradeable.mulDiv(
                        totalAllocation.maticAmount * 1e22,
                        totalAllocation.sharePriceDenom,
                        totalAllocation.sharePriceNum,
                        MathUpgradeable.Rounding.Up)
                    + MathUpgradeable.mulDiv(
                        _amount * 1e22,
                        globalPriceDenom,
                        globalPriceNum,
                        MathUpgradeable.Rounding.Up);

                // rounding total allocated share price denominator UP, in order to minimise the total allocation share price
                // which maximises the amount owed by the distributor, which they cannot withdraw/transfer (strict allocations)
            }
        
            totalAllocated[msg.sender][_strict] = Allocation(totalAmount, totalNum, totalDenom);
        }

        emit Allocated(
            msg.sender,
            _recipient,
            individualAmount,
            individualPriceNum,
            individualPriceDenom,
            totalAmount,
            totalNum,
            totalDenom,
            _strict
        );
    }

    /// @notice function to deallocate from a user
    /// @dev if user calls deallocate, there is first a check if there are any 
    ///     outstanding rewards that need to be distributed first
    /// @param _amount amount msg.sender wants to deallocate
    /// @param _recipient address of user from whom msg.sender wants to deallocate
    /// @param _strict bool to determine whether deallocation should be subject to checks or not
    function deallocate(
        uint256 _amount,
        address _recipient,
        bool _strict
    ) external onlyWhitelist nonReentrant {
        Allocation storage individualAllocation = allocations[msg.sender][_recipient][_strict];

        uint256 oldIndividualSharePriceNum = individualAllocation.sharePriceNum;
        uint256 oldIndividualSharePriceDenom = individualAllocation.sharePriceDenom;

        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        if (individualAllocation.maticAmount == 0) {
            revert NoRewardsAllocatedToRecipient();
        }
            
        // check if shareprice has moved - if yes, distribute first
        if (_strict && individualAllocation.sharePriceNum / individualAllocation.sharePriceDenom < globalPriceNum / globalPriceDenom) {
            _distributeRewardsUpdateTotal(_recipient, msg.sender, _strict);
        }
        // underflow error trying to deallocate more than allocated, automatically checked
        individualAllocation.maticAmount -= _amount;

        // check if this is a complete deallocation
        if (individualAllocation.maticAmount == 0) {
            // remove recipient from distributor's recipient array
            delete allocations[msg.sender][_recipient][_strict];
            
            address[] storage rec = recipients[msg.sender][_strict];
            uint256 rlen = rec.length;

            for (uint256 i; i < rlen; ) {
                if (rec[i] == _recipient) {
                    rec[i] = rec[rlen - 1];
                    rec.pop();
                    break;
                }

                unchecked {
                    ++i;
                }
            }

            // remove distributor from recipient's distributor array

            address[] storage dist = distributors[_recipient][_strict];
            uint256 dlen = dist.length;

            for (uint256 i; i < dlen; ) {
                if (dist[i] == msg.sender) {
                    dist[i] = dist[dlen - 1];
                    dist.pop();
                    break;
                }

                unchecked {
                    ++i;
                }
            }
        }

        // update total allocation values - rebalance

        uint256 totalAmount;
        uint256 totalPriceNum;
        uint256 totalPriceDenom;
        
        Allocation storage totalAllocation = totalAllocated[msg.sender][_strict];
        
        totalAmount = totalAllocation.maticAmount - _amount;
        
        if (totalAmount == 0) {
            delete totalAllocated[msg.sender][_strict];
        } else {
            (uint256 newIndividualPriceNum, uint256 newIndividualPriceDenom) = _strict
                ? (globalPriceNum, globalPriceDenom)
                : (oldIndividualSharePriceNum, oldIndividualSharePriceDenom);

            // in the case of deallocating a strict allocation, rewards will have been distributed
            // at the start of the deallocate function, therefore we must use the old share price
            // in the weighted sum below to update the total allocation share price. This is because
            // the individual share price has already been updated to the global share price.

            totalPriceNum = totalAllocation.maticAmount * 1e22 - _amount * 1e22;

            totalPriceDenom =
                MathUpgradeable.mulDiv(
                    totalAllocation.maticAmount * 1e22,
                    totalAllocation.sharePriceDenom,
                    totalAllocation.sharePriceNum,
                    MathUpgradeable.Rounding.Up)
                - MathUpgradeable.mulDiv(
                    _amount * 1e22,
                    newIndividualPriceDenom,
                    newIndividualPriceNum,
                    MathUpgradeable.Rounding.Down);

            // rounding total allocated share price denominator UP, in order to minimise the total allocation share price
            // which maximises the amount owed by the distributor, which they cannot withdraw/transfer (strict allocations)
        }
        
        totalAllocated[msg.sender][_strict] = Allocation(totalAmount, totalPriceNum, totalPriceDenom);
        
        emit Deallocated(
            msg.sender,
            _recipient,
            individualAllocation.maticAmount,
            totalAmount,
            totalPriceNum,
            totalPriceDenom,
            _strict
        );
    }

    /// @notice function to move a loose allocation from one user to another
    /// @param _oldRecipient the previous recipient of the allocation
    /// @param _newRecipient the new recipient of the allocation
    function reallocate(
        address _oldRecipient,
        address _newRecipient
    ) external onlyWhitelist nonReentrant {
        // strictness must be false

        Allocation memory oldIndividualAllocation = allocations[msg.sender][_oldRecipient][false];
        
        // assert they there is an old allocation
        if (oldIndividualAllocation.maticAmount == 0) {
            revert AllocationNonExistent();
        }

        Allocation storage newAllocation = allocations[msg.sender][_newRecipient][false];

        uint256 individualAmount;
        uint256 individualPriceNum;
        uint256 individualPriceDenom;

        // check if new recipient has already been allocated to 
        if (newAllocation.maticAmount == 0) {
            // set new one
            individualAmount = oldIndividualAllocation.maticAmount;
            individualPriceNum = oldIndividualAllocation.sharePriceNum;
            individualPriceDenom = oldIndividualAllocation.sharePriceDenom;


            // pop old one from recipients array, set it equal to new address
            address[] storage rec = recipients[msg.sender][false];
            uint256 rlen = rec.length;

            for (uint256 i; i < rlen;) {
                if (rec[i] == _oldRecipient) {
                    rec[i] = _newRecipient;
                    break;
                }

                unchecked {
                    ++i;
                }
            }

            // to newRecipient's distributors array: add distributor
            distributors[_newRecipient][false].push(msg.sender);
        } else {
            // update existing recipient allocation with weighted sum

            individualAmount = oldIndividualAllocation.maticAmount + newAllocation.maticAmount;

            individualPriceNum = oldIndividualAllocation.maticAmount * 1e22 +
                newAllocation.maticAmount * 1e22;

            individualPriceDenom =
                MathUpgradeable.mulDiv(
                    oldIndividualAllocation.maticAmount * 1e22,
                    oldIndividualAllocation.sharePriceDenom,
                    oldIndividualAllocation.sharePriceNum,
                    MathUpgradeable.Rounding.Down)
                + MathUpgradeable.mulDiv(
                    newAllocation.maticAmount * 1e22,
                    newAllocation.sharePriceDenom,
                    newAllocation.sharePriceNum,
                    MathUpgradeable.Rounding.Down);
            
            // rounding individual allocation share price denominator DOWN, in order to maximise the individual allocation share price
            // which minimises the amount that is distributed in `distributeRewards()`

            // pop old one from recipients array
            address[] storage rec = recipients[msg.sender][false];
            uint256 rlen = rec.length;

            for (uint256 i; i < rlen;) {
                if (rec[i] == _oldRecipient) {
                    rec[i] = rec[rlen - 1];
                    rec.pop();
                    break;
                }

                unchecked {
                    ++i;
                }
            }
        }
        // delete old one
        delete allocations[msg.sender][_oldRecipient][false];
        // set the new allocation amount
        allocations[msg.sender][_newRecipient][false] = Allocation(
            individualAmount,
            individualPriceNum,
            individualPriceDenom
        );

        // from oldRecipient's distributors array: pop distributor
        address[] storage dist = distributors[_oldRecipient][false];
        uint256 dlen = dist.length;

        for (uint256 i; i < dlen; ) {
            if (dist[i] == msg.sender) {
                dist[i] = dist[dlen - 1];
                dist.pop();
                break;
            }

            unchecked {
                ++i;
            }
        }

        emit Reallocated(
            msg.sender,
            _oldRecipient,
            _newRecipient,
            individualAmount,
            individualPriceNum,
            individualPriceDenom
        );
    }

    /// @notice function to distribute rewards to users
    /// @dev users can call this function to distribute rewards to a specific recipient
    /// @param _recipient address of user who is receiving the rewards
    /// @param _distributor address of distributor from whom recipient is receiving rewards
    // needs fixing
    /// @param _strict bool to determine whether deallocation should be subject to checks or not
    function _distributeRewardsUpdateTotal(
        address _recipient,
        address _distributor,
        bool _strict
    ) private {
        Allocation storage individualAllocation = allocations[_distributor][_recipient][_strict];
        
        if (individualAllocation.maticAmount == 0) {
            revert NothingToDistribute();
        }
        Allocation storage totalAllocation = totalAllocated[msg.sender][_strict];
        // moved up for stack too deep issues
        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        uint256 amountDistributed;
        uint256 sharesDistributed;

        {
            // check necessary to avoid div by zero error
            if (individualAllocation.sharePriceNum / individualAllocation.sharePriceDenom == globalPriceNum / globalPriceDenom) {
                return;
            }
            uint256 oldIndividualSharePriceNum;
            uint256 oldIndividualSharePriceDenom;
            
            // dist rewards private fn, which does not update total allocated
            (oldIndividualSharePriceNum, oldIndividualSharePriceDenom, sharesDistributed) = _distributeRewards(
                _recipient,
                _distributor,
                _strict,
                true
            );
            
            amountDistributed = convertToAssets(sharesDistributed);
            
            // note: this amount was rounded, but it's only being used as a parameter in the emitted event,
            // should be cautious when using rounded values in calculations

            // update total allocated

            totalAllocation.sharePriceDenom = totalAllocation.sharePriceDenom
                + MathUpgradeable.mulDiv(
                    individualAllocation.maticAmount * 1e22,
                    globalPriceDenom * totalAllocation.sharePriceNum,
                    totalAllocation.maticAmount * globalPriceNum,
                    MathUpgradeable.Rounding.Up) / 1e22
                - MathUpgradeable.mulDiv(
                    individualAllocation.maticAmount * 1e22,
                    oldIndividualSharePriceDenom * totalAllocation.sharePriceNum,
                    totalAllocation.maticAmount * oldIndividualSharePriceNum,
                    MathUpgradeable.Rounding.Down) / 1e22;

            // totalAllocation.sharePriceNum unchanged
            
            // rounding total allocated share price denominator UP, in order to minimise the total allocation share price
            // which maximises the amount owed by the distributor, which they cannot withdraw/transfer (strict allocations)
        }

        emit DistributedRewards(
            _distributor,
            _recipient,
            amountDistributed,
            sharesDistributed,
            globalPriceNum,
            globalPriceDenom,
            totalAllocation.sharePriceNum,
            totalAllocation.sharePriceDenom,
            _strict
        );
    }

    /// @notice public function for distributing rewards that users can call
    /// @dev function split into private and public as rewards are distributed in
    ///   `distributeAll` function too
    /// @param _recipient address of user who is receiving the rewards
    /// @param _distributor address of distributor from whom recipient is receiving rewards
    /// @param _strict bool to determine whether deallocation should be subject to checks or not
    function distributeRewards(
        address _recipient,
        address _distributor,
        bool _strict
    ) public nonReentrant {
        if (!_strict && msg.sender != _distributor) {
            revert OnlyDistributorCanDistributeRewards();
        }
        _distributeRewardsUpdateTotal(_recipient, _distributor, _strict);
    }

    /// @notice function to distribute rewards to users
    /// @dev this is a private function that other distribute functions call
    /// @param _recipient address of user who is receiving the rewards
    /// @param _distributor address of distributor from whom recipient is receiving rewards
    /// @param _strict bool to determine whether deallocation should be subject to checks or not
    /// @param _individual bool to determine whether this distribution is happening for one
    ///   specific allocation or if all of a distribution's allocations are being distributed
    /// @dev this is important as an event should only be emitted on non-individual calls
    function _distributeRewards(
        address _recipient,
        address _distributor,
        bool _strict,
        bool _individual
    ) private returns (uint256, uint256, uint256) {
        Allocation storage individualAllocation = allocations[_distributor][_recipient][_strict];
        uint256 amt = individualAllocation.maticAmount;
       
        uint256 oldNum = individualAllocation.sharePriceNum;
        uint256 oldDenom = individualAllocation.sharePriceDenom;

        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        // calculate amount of TruMatic to move from distributor to recipient
        
        uint256 sharesToMove;

        {
            uint256 totalShares =
                MathUpgradeable.mulDiv(
                    amt,
                    oldDenom * 1e18,
                    oldNum,
                    MathUpgradeable.Rounding.Down)
                - MathUpgradeable.mulDiv(
                    amt,
                    globalPriceDenom * 1e18,
                    globalPriceNum,
                    MathUpgradeable.Rounding.Up
                );

            if (!_strict) {
                // calc fees and transfer
                
                uint256 fee = totalShares * distPhi / phiPrecision;
                
                sharesToMove = totalShares - fee;
                
                _transfer(_distributor, treasuryAddress, fee);
            } else {
                sharesToMove = totalShares;
            }
        }
        
        _transfer(_distributor, _recipient, sharesToMove);
        
        individualAllocation.sharePriceNum = globalPriceNum;
        individualAllocation.sharePriceDenom = globalPriceDenom;

        if (!_individual) {
            emit DistributedRewards(
                _distributor,
                _recipient,
                convertToAssets(sharesToMove),
                sharesToMove,
                globalPriceNum,
                globalPriceDenom,
                0,
                0,
                _strict
            );
        }

        return (oldNum, oldDenom, sharesToMove);
    }

    /// @notice function to distribute rewards to all recipients
    /// @dev distributors can call this function to distribute rewards to all of their recipients
    /// @dev loops through and calls distribute rewards private function, without updating total
    ///   allocation of distributor each time, only once at the end
    /// @param _distributor address of distributor that is distributing rewards to all recipients
    /// @param _strict bool to determine whether deallocation should be subject to checks or not
    function distributeAll(address _distributor, bool _strict) external nonReentrant {
        if (!_strict && msg.sender != _distributor) {
            revert OnlyDistributorCanDistributeRewards();
        }

        address[] storage rec = recipients[_distributor][_strict];
        uint256 len = rec.length;

        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();

        for (uint256 i; i < len;) {
            Allocation storage individualAllocation = allocations[_distributor][rec[i]][_strict];
            
            if (individualAllocation.sharePriceNum / individualAllocation.sharePriceDenom < globalPriceNum / globalPriceDenom) {
                _distributeRewards(rec[i], _distributor, _strict, false);
            }
            unchecked {
                ++i;
            }
        }

        // reset total allocation

        Allocation storage totalAllocated = totalAllocated[msg.sender][_strict];
        totalAllocated.sharePriceNum = globalPriceNum;
        totalAllocated.sharePriceDenom = globalPriceDenom;

        emit DistributedAll(
            _distributor,
            globalPriceNum,
            globalPriceDenom,
            _strict
        );
    }

    // --- ERC-4626 Overrides ---

    // asset share converters

    /// @notice calculate how many shares `_amount` MATIC is worth
    /// @dev overriding because share price calculation is particular due to fee
    /// @dev overriding the internal fn rather than the external one means all the
    ///   preview functions shouldn't have to be overriden too
    /// @return shares value of param _amount in shares based on share price
    function _convertToShares(
        uint256 assets,
        MathUpgradeable.Rounding rounding
    ) internal view override returns (uint256 shares) {
        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();
        return MathUpgradeable.mulDiv(
            assets * 1e18,
            globalPriceDenom,
            globalPriceNum,
            rounding);
    }

    /// @notice calculate how much MATIC `_shares` shares are worth
    /// @dev overriding because share price calculation is particular due to fee
    /// @dev overriding the internal fn rather than the external one means all the
    ///   preview functions shouldn't have to be overriden too
    /// @return amount value of param _shares in MATIC based on share price
    function _convertToAssets(
        uint256 shares,
        MathUpgradeable.Rounding rounding
    ) internal view override returns (uint256) {
        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();
        return MathUpgradeable.mulDiv(
            shares,
            globalPriceNum,
            globalPriceDenom * 1e18,
            rounding);
    }

    /// @notice prevent users to transfer more shares than their unallocated balance
    /// @dev overrides internal function that runs just before the ERC-20 token
    ///   transfer, adding an extra balance check
    function _beforeTokenTransfer(
        address from,
        address,
        uint256 amount
    ) internal view override {
        if (from != address(0) && amount > maxRedeem(from)) {
            revert ExceedsUnallocatedBalance();
        }
    }

    // max functions

    /// @notice returns the maximum amount of MATIC a user can deposit
    /// @dev kept unused param but removed name to preserve function signature
    /// @dev not taking into account their MATIC balance; as if MATIC balance
    ///   was not a limitation
    function maxDeposit(address) public view override returns (uint256) {
        return cap - totalStaked();
    }

    /// @notice returns the maximum number of shares a user can mint
    function maxMint(address receiver) public view override returns (uint256) {
        return previewDeposit(maxDeposit(receiver));
    }

    /// @notice returns the maximum amount of MATIC a user can withdraw
    /// @dev from EIP-4626 specification (https://eips.ethereum.org/EIPS/eip-4626)
    ///   "MUST return the maximum amount of assets that could be transferred from
    ///   owner through withdraw and not cause a revert, which MUST NOT be higher
    ///   than the actual maximum that would be accepted (it should underestimate
    ///   if necessary)."
    ///   due to the reserve fund money deposited by the TruFin protocol, this
    ///   will always hold
    function maxWithdraw(address owner) public view override returns (uint256) {
        return previewRedeem(maxRedeem(owner)) + epsilon;
    }

    /// @notice returns the maximum number of shares a user can redeem
    /// @dev from EIP-4626 specification (https://eips.ethereum.org/EIPS/eip-4626)
    ///   "MUST return the maximum amount of shares that could be transferred
    ///   from owner through redeem and not cause a revert, which MUST NOT be
    ///   higher than the actual maximum that would be accepted (it should
    ///   underestimate if necessary)."
    ///   due to the reserve fund money deposited by the TruFin protocol, this
    ///   will always hold
    function maxRedeem(address owner) public view override returns (uint256) {
        Allocation storage totalAllocation = totalAllocated[owner][true];
        
        // Cache from storage
        uint256 maticAmount = totalAllocation.maticAmount;

        // Redeemer can't withdraw shares equivalent to their total allocation plus its rewards
        uint256 unredeemableShares = (maticAmount == 0) ? 0 : MathUpgradeable.mulDiv(
            totalAllocation.maticAmount * 1e18,
            totalAllocation.sharePriceDenom,
            totalAllocation.sharePriceNum,
            MathUpgradeable.Rounding.Up
        );

        // We rounded up undreedemableShares to ensure excess shares are not returned     
        return balanceOf(owner) - unredeemableShares;
    }

    /// @notice view function to get some useful data
    /// @dev maxRedeemable - maximum TruMATCIC redeemable for user
    /// @dev maxWithdrawAmount - maximum MATIC withdrawable for user
    function getUserInfo(address _owner) public view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 globalPriceNum, uint256 globalPriceDenom) = sharePrice();
        uint256 maxRedeemable = maxRedeem(_owner); // TruMATIC
        uint256 maxWithdrawAmount = maxWithdraw(_owner); // MATIC
        uint256 epoch = getCurrentEpoch();
        
        return (maxRedeemable, maxWithdrawAmount, globalPriceNum, globalPriceDenom, epoch);
    }

    // preview functions

    /// @dev ERC-4626 preview function, change from rounding down to rounding up
    function previewRedeem(uint256 shares) public view override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
    }

    // standard deposit / mint + withdrawal / redeem functions

    /// @notice overriding standard `deposit` function in ERC-4626 for better integration
    /// @dev calls main deposit function
    function deposit(
        uint256 assets,
        address receiver
    ) public override onlyWhitelist nonReentrant returns (uint256) {
        if (msg.sender != receiver) {
            revert SenderAndOwnerMustBeReceiver();
        }

        _deposit(msg.sender, assets);

        return previewDeposit(assets);
    }

    /// @notice overriding standard `mint` function in ERC-4626 for better integration
    /// @dev calls main deposit function
    function mint(
        uint256 shares,
        address receiver
    ) public override onlyWhitelist nonReentrant returns (uint256) {
        if (msg.sender != receiver) {
            revert SenderAndOwnerMustBeReceiver();
        }

        uint256 assets = previewMint(shares);

        _deposit(msg.sender, assets);

        return assets;
    }

    /// @notice overriding standard `withdraw` function in ERC-4626 for better integration
    /// @dev calls main withdraw function
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override onlyWhitelist nonReentrant returns (uint256) {
        if (msg.sender != receiver || msg.sender != owner) {
            revert SenderAndOwnerMustBeReceiver();
        }

        _withdrawRequest(msg.sender, assets);

        return previewWithdraw(assets);
    }

    /// @notice overriding standard `redeem` function in ERC-4626 for better integration
    /// @dev calls main withdraw function
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override onlyWhitelist nonReentrant returns (uint256) {
        if (msg.sender != receiver || msg.sender != owner) {
            revert SenderAndOwnerMustBeReceiver();
        }

        uint256 assets = previewRedeem(shares);

        _withdrawRequest(msg.sender, assets);

        return assets;
    }

    // erc-20 metadata

    function name()
        public
        pure
        override(IERC20MetadataUpgradeable, ERC20Upgradeable)
        returns (string memory)
    {
        return "TruStake MATIC Vault Shares";
    }

    function symbol()
        public
        pure
        override(IERC20MetadataUpgradeable, ERC20Upgradeable)
        returns (string memory)
    {
        return "TruMATIC";
    }
}
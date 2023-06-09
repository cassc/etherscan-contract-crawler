/*
    Copyright 2021 Babylon Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;
import {IBabController} from '../interfaces/IBabController.sol';
import {TimeLockRegistry} from './TimeLockRegistry.sol';
import {IRewardsDistributor} from '../interfaces/IRewardsDistributor.sol';
import {VoteToken} from './VoteToken.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Errors, _require} from '../lib/BabylonErrors.sol';
import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {IBabController} from '../interfaces/IBabController.sol';

/**
 * @title TimeLockedToken
 * @notice Time Locked ERC20 Token
 * @author Babylon Finance
 * @dev Contract which gives the ability to time-lock tokens specially for vesting purposes usage
 *
 * By overriding the balanceOf() and transfer() functions in ERC20,
 * an account can show its full, post-distribution balance and use it for voting power
 * but only transfer or spend up to an allowed amount
 *
 * A portion of previously non-spendable tokens are allowed to be transferred
 * along the time depending on each vesting conditions, and after all epochs have passed, the full
 * account balance is unlocked. In case on non-completion vesting period, only the Time Lock Registry can cancel
 * the delivery of the pending tokens and only can cancel the remaining locked ones.
 */

abstract contract TimeLockedToken is VoteToken {
    using LowGasSafeMath for uint256;

    /* ============ Events ============ */

    /// @notice An event that emitted when a new lockout ocurr
    event NewLockout(
        address account,
        uint256 tokenslocked,
        bool isTeamOrAdvisor,
        uint256 startingVesting,
        uint256 endingVesting
    );

    /// @notice An event that emitted when a new Time Lock is registered
    event NewTimeLockRegistration(address previousAddress, address newAddress);

    /// @notice An event that emitted when a new Rewards Distributor is registered
    event NewRewardsDistributorRegistration(address previousAddress, address newAddress);

    /// @notice An event that emitted when a cancellation of Lock tokens is registered
    event Cancel(address account, uint256 amount);

    /// @notice An event that emitted when a claim of tokens are registered
    event Claim(address _receiver, uint256 amount);

    /// @notice An event that emitted when a lockedBalance query is done
    event LockedBalance(address _account, uint256 amount);

    /* ============ Modifiers ============ */

    modifier onlyTimeLockRegistry() {
        require(
            msg.sender == address(timeLockRegistry),
            'TimeLockedToken:: onlyTimeLockRegistry: can only be executed by TimeLockRegistry'
        );
        _;
    }

    modifier onlyTimeLockOwner() {
        if (address(timeLockRegistry) != address(0)) {
            require(
                msg.sender == Ownable(timeLockRegistry).owner(),
                'TimeLockedToken:: onlyTimeLockOwner: can only be executed by the owner of TimeLockRegistry'
            );
        }
        _;
    }
    modifier onlyUnpaused() {
        // Do not execute if Globally or individually paused
        _require(!IBabController(controller).isPaused(address(this)), Errors.ONLY_UNPAUSED);
        _;
    }

    /* ============ State Variables ============ */

    // represents total distribution for locked balances
    mapping(address => uint256) distribution;

    /// @notice The profile of each token owner under its particular vesting conditions
    /**
     * @param team Indicates whether or not is a Team member or Advisor (true = team member/advisor, false = private investor)
     * @param vestingBegin When the vesting begins for such token owner
     * @param vestingEnd When the vesting ends for such token owner
     * @param lastClaim When the last claim was done
     */
    struct VestedToken {
        bool teamOrAdvisor;
        uint256 vestingBegin;
        uint256 vestingEnd;
        uint256 lastClaim;
    }

    /// @notice A record of token owners under vesting conditions for each account, by index
    mapping(address => VestedToken) public vestedToken;

    // address of Time Lock Registry contract
    IBabController public controller;

    // address of Time Lock Registry contract
    TimeLockRegistry public timeLockRegistry;

    // address of Rewards Distriburor contract
    IRewardsDistributor public rewardsDistributor;

    // Enable Transfer of ERC20 BABL Tokens
    // Only Minting or transfers from/to TimeLockRegistry and Rewards Distributor can transfer tokens until the protocol is fully decentralized
    bool private tokenTransfersEnabled;
    bool private tokenTransfersWereDisabled;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    constructor(string memory _name, string memory _symbol) VoteToken(_name, _symbol) {
        tokenTransfersEnabled = true;
    }

    /* ============ External Functions ============ */

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Disables transfers of ERC20 BABL Tokens
     */
    function disableTokensTransfers() external onlyOwner {
        require(!tokenTransfersWereDisabled, 'BABL must flow');
        tokenTransfersEnabled = false;
        tokenTransfersWereDisabled = true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows transfers of ERC20 BABL Tokens
     * Can only happen after the protocol is fully decentralized.
     */
    function enableTokensTransfers() external onlyOwner {
        tokenTransfersEnabled = true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Set the Time Lock Registry contract to control token vesting conditions
     *
     * @notice Set the Time Lock Registry contract to control token vesting conditions
     * @param newTimeLockRegistry Address of TimeLockRegistry contract
     */
    function setTimeLockRegistry(TimeLockRegistry newTimeLockRegistry) external onlyTimeLockOwner returns (bool) {
        require(address(newTimeLockRegistry) != address(0), 'cannot be zero address');
        require(address(newTimeLockRegistry) != address(this), 'cannot be this contract');
        require(address(newTimeLockRegistry) != address(timeLockRegistry), 'must be new TimeLockRegistry');
        emit NewTimeLockRegistration(address(timeLockRegistry), address(newTimeLockRegistry));

        timeLockRegistry = newTimeLockRegistry;

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Set the Rewards Distributor contract to control either BABL Mining or profit rewards
     *
     * @notice Set the Rewards Distriburor contract to control both types of rewards (profit and BABL Mining program)
     * @param newRewardsDistributor Address of Rewards Distributor contract
     */
    function setRewardsDistributor(IRewardsDistributor newRewardsDistributor) external onlyOwner returns (bool) {
        require(address(newRewardsDistributor) != address(0), 'cannot be zero address');
        require(address(newRewardsDistributor) != address(this), 'cannot be this contract');
        require(address(newRewardsDistributor) != address(rewardsDistributor), 'must be new Rewards Distributor');
        emit NewRewardsDistributorRegistration(address(rewardsDistributor), address(newRewardsDistributor));

        rewardsDistributor = newRewardsDistributor;

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Register new token lockup conditions for vested tokens defined only by Time Lock Registry
     *
     * @notice Tokens are completely delivered during the registration however lockup conditions apply for vested tokens
     * locking them according to the distribution epoch periods and the type of recipient (Team, Advisor, Investor)
     * Emits a transfer event showing a transfer to the recipient
     * Only the registry can call this function
     * @param _receiver Address to receive the tokens
     * @param _amount Tokens to be transferred
     * @param _profile True if is a Team Member or Advisor
     * @param _vestingBegin Unix Time when the vesting for that particular address
     * @param _vestingEnd Unix Time when the vesting for that particular address
     * @param _lastClaim Unix Time when the claim was done from that particular address
     *
     */
    function registerLockup(
        address _receiver,
        uint256 _amount,
        bool _profile,
        uint256 _vestingBegin,
        uint256 _vestingEnd,
        uint256 _lastClaim
    ) external onlyTimeLockRegistry returns (bool) {
        require(balanceOf(msg.sender) >= _amount, 'insufficient balance');
        require(_receiver != address(0), 'cannot be zero address');
        require(_receiver != address(this), 'cannot be this contract');
        require(_receiver != address(timeLockRegistry), 'cannot be the TimeLockRegistry contract itself');
        require(_receiver != msg.sender, 'the owner cannot lockup itself');

        // update amount of locked distribution
        distribution[_receiver] = distribution[_receiver].add(_amount);

        VestedToken storage newVestedToken = vestedToken[_receiver];

        newVestedToken.teamOrAdvisor = _profile;
        newVestedToken.vestingBegin = _vestingBegin;
        newVestedToken.vestingEnd = _vestingEnd;
        newVestedToken.lastClaim = _lastClaim;

        // transfer tokens to the recipient
        _transfer(msg.sender, _receiver, _amount);
        emit NewLockout(_receiver, _amount, _profile, _vestingBegin, _vestingEnd);

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel and remove locked tokens due to non-completion of vesting period
     * applied only by Time Lock Registry and specifically to Team or Advisors as it does not apply to investors.
     *
     * @dev Cancel distribution registration
     * @param lockedAccount that should have its still locked distribution removed due to non-completion of its vesting period
     */
    function cancelVestedTokens(address lockedAccount) external onlyTimeLockRegistry returns (uint256) {
        return _cancelVestedTokensFromTimeLock(lockedAccount);
    }

    /**
     * GOVERNANCE FUNCTION. Each token owner can claim its own specific tokens with its own specific vesting conditions from the Time Lock Registry
     *
     * @dev Claim msg.sender tokens (if any available in the registry)
     */
    function claimMyTokens() external {
        // claim msg.sender tokens from timeLockRegistry
        uint256 amount = timeLockRegistry.claim(msg.sender);
        // After a proper claim, locked tokens of Team and Advisors profiles are under restricted special vesting conditions so they automatic grant
        // rights to the Time Lock Registry to only retire locked tokens if non-compliance vesting conditions take places along the vesting periods.
        // It does not apply to Investors under vesting (their locked tokens cannot be removed).
        if (vestedToken[msg.sender].teamOrAdvisor == true) {
            approve(address(timeLockRegistry), amount);
        }
        // emit claim event
        emit Claim(msg.sender, amount);
    }

    /**
     * GOVERNANCE FUNCTION. Get unlocked balance for an account
     *
     * @notice Get unlocked balance for an account
     * @param account Account to check
     * @return Amount that is unlocked and available eg. to transfer
     */
    function unlockedBalance(address account) public returns (uint256) {
        // totalBalance - lockedBalance
        return balanceOf(account).sub(lockedBalance(account));
    }

    /**
     * GOVERNANCE FUNCTION. View the locked balance for an account
     *
     * @notice View locked balance for an account
     * @param account Account to check
     * @return Amount locked in the time of checking
     */

    function viewLockedBalance(address account) public view returns (uint256) {
        // distribution of locked tokens
        // get amount from distributions

        uint256 amount = distribution[account];
        uint256 lockedAmount = amount;

        // Team and investors cannot transfer tokens in the first year
        if (vestedToken[account].vestingBegin.add(365 days) > block.timestamp && amount != 0) {
            return lockedAmount;
        }

        // in case of vesting has passed, all tokens are now available, if no vesting lock is 0 as well
        if (block.timestamp >= vestedToken[account].vestingEnd || amount == 0) {
            lockedAmount = 0;
        } else if (amount != 0) {
            // in case of still under vesting period, locked tokens are recalculated
            lockedAmount = amount.mul(vestedToken[account].vestingEnd.sub(block.timestamp)).div(
                vestedToken[account].vestingEnd.sub(vestedToken[account].vestingBegin)
            );
        }
        return lockedAmount;
    }

    /**
     * GOVERNANCE FUNCTION. Get locked balance for an account
     *
     * @notice Get locked balance for an account
     * @param account Account to check
     * @return Amount locked in the time of checking
     */
    function lockedBalance(address account) public returns (uint256) {
        // get amount from distributions locked tokens (if any)
        uint256 lockedAmount = viewLockedBalance(account);
        // in case of vesting has passed, all tokens are now available so we set mapping to 0 only for accounts under vesting
        if (
            block.timestamp >= vestedToken[account].vestingEnd &&
            msg.sender == account &&
            lockedAmount == 0 &&
            vestedToken[account].vestingEnd != 0
        ) {
            delete distribution[account];
        }
        emit LockedBalance(account, lockedAmount);
        return lockedAmount;
    }

    /**
     * PUBLIC FUNCTION. Get the address of Time Lock Registry
     *
     * @notice Get the address of Time Lock Registry
     * @return Address of the Time Lock Registry
     */
    function getTimeLockRegistry() external view returns (address) {
        return address(timeLockRegistry);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the Approval of allowances of ERC20 with special conditions for vesting
     *
     * @notice Override of "Approve" function to allow the `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender` except in the case of spender is Time Lock Registry
     * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount) public override nonReentrant returns (bool) {
        require(spender != address(0), 'TimeLockedToken::approve: spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::approve: spender cannot be the msg.sender');

        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, 'TimeLockedToken::approve: amount exceeds 96 bits');
        }

        // There is no option to decreaseAllowance to timeLockRegistry in case of vested tokens
        if ((spender == address(timeLockRegistry)) && (amount < allowance(msg.sender, address(timeLockRegistry)))) {
            amount = safe96(
                allowance(msg.sender, address(timeLockRegistry)),
                'TimeLockedToken::approve: cannot decrease allowance to timelockregistry'
            );
        }
        _approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the Increase of allowances of ERC20 with special conditions for vesting
     *
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an override with respect to the fulfillment of vesting conditions along the way
     * However an user can increase allowance many times, it will never be able to transfer locked tokens during vesting period
     * @return Whether or not the increaseAllowance succeeded
     */
    function increaseAllowance(address spender, uint256 addedValue) public override nonReentrant returns (bool) {
        require(
            unlockedBalance(msg.sender) >= allowance(msg.sender, spender).add(addedValue) ||
                spender == address(timeLockRegistry),
            'TimeLockedToken::increaseAllowance:Not enough unlocked tokens'
        );
        require(spender != address(0), 'TimeLockedToken::increaseAllowance:Spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::increaseAllowance:Spender cannot be the msg.sender');
        _approve(msg.sender, spender, allowance(msg.sender, spender).add(addedValue));
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the decrease of allowances of ERC20 with special conditions for vesting
     *
     * @notice Atomically decrease the allowance granted to `spender` by the caller.
     *
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * This is an override with respect to the fulfillment of vesting conditions along the way
     * An user cannot decrease the allowance to the Time Lock Registry who is in charge of vesting conditions
     * @return Whether or not the decreaseAllowance succeeded
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public override nonReentrant returns (bool) {
        require(spender != address(0), 'TimeLockedToken::decreaseAllowance:Spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::decreaseAllowance:Spender cannot be the msg.sender');
        require(
            allowance(msg.sender, spender) >= subtractedValue,
            'TimeLockedToken::decreaseAllowance:Underflow condition'
        );

        // There is no option to decreaseAllowance to timeLockRegistry in case of vested tokens
        require(
            address(spender) != address(timeLockRegistry),
            'TimeLockedToken::decreaseAllowance:cannot decrease allowance to timeLockRegistry'
        );

        _approve(msg.sender, spender, allowance(msg.sender, spender).sub(subtractedValue));
        return true;
    }

    /* ============ Internal Only Function ============ */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the _transfer of ERC20 BABL tokens only allowing the transfer of unlocked tokens
     *
     * @dev Transfer function which includes only unlocked tokens
     * Locked tokens can always be transfered back to the returns address
     * Transferring to owner allows re-issuance of funds through registry
     *
     * @param _from The address to send tokens from
     * @param _to The address that will receive the tokens
     * @param _value The amount of tokens to be transferred
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal override onlyUnpaused {
        require(_from != address(0), 'TimeLockedToken:: _transfer: cannot transfer from the zero address');
        require(_to != address(0), 'TimeLockedToken:: _transfer: cannot transfer to the zero address');
        require(
            _to != address(this),
            'TimeLockedToken:: _transfer: do not transfer tokens to the token contract itself'
        );

        require(balanceOf(_from) >= _value, 'TimeLockedToken:: _transfer: insufficient balance');

        // check if enough unlocked balance to transfer
        require(unlockedBalance(_from) >= _value, 'TimeLockedToken:: _transfer: attempting to transfer locked funds');
        super._transfer(_from, _to, _value);
        // voting power
        _moveDelegates(
            delegates[_from],
            delegates[_to],
            safe96(_value, 'TimeLockedToken:: _transfer: uint96 overflow')
        );
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Disable BABL token transfer until certain conditions are met
     *
     * @dev Override the _beforeTokenTransfer of ERC20 BABL tokens until certain conditions are met:
     * Only allowing minting or transfers from Time Lock Registry and Rewards Distributor until transfers are allowed in the controller
     * Transferring to owner allows re-issuance of funds through registry
     *
     * @param _from The address to send tokens from
     * @param _to The address that will receive the tokens
     * @param _value The amount of tokens to be transferred
     */

    // Disable garden token transfers. Allow minting and burning.
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _value);
        _require(
            _from == address(0) ||
                _from == address(timeLockRegistry) ||
                _from == address(rewardsDistributor) ||
                _to == address(timeLockRegistry) ||
                tokenTransfersEnabled,
            Errors.BABL_TRANSFERS_DISABLED
        );
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel and remove locked tokens due to non-completion of  vesting period
     * applied only by Time Lock Registry and specifically to Team or Advisors
     *
     * @dev Cancel distribution registration
     * @param lockedAccount that should have its still locked distribution removed due to non-completion of its vesting period
     */
    function _cancelVestedTokensFromTimeLock(address lockedAccount) internal onlyTimeLockRegistry returns (uint256) {
        require(distribution[lockedAccount] != 0, 'TimeLockedToken::cancelTokens:Not registered');

        // get an update on locked amount from distributions at this precise moment
        uint256 loosingAmount = lockedBalance(lockedAccount);

        require(loosingAmount > 0, 'TimeLockedToken::cancelTokens:There are no more locked tokens');
        require(
            vestedToken[lockedAccount].teamOrAdvisor == true,
            'TimeLockedToken::cancelTokens:cannot cancel locked tokens to Investors'
        );

        // set distribution mapping to 0
        delete distribution[lockedAccount];

        // set tokenVested mapping to 0
        delete vestedToken[lockedAccount];

        // transfer only locked tokens back to TimeLockRegistry Owner (msg.sender)
        require(
            transferFrom(lockedAccount, address(timeLockRegistry), loosingAmount),
            'TimeLockedToken::cancelTokens:Transfer failed'
        );

        // emit cancel event
        emit Cancel(lockedAccount, loosingAmount);

        return loosingAmount;
    }
}
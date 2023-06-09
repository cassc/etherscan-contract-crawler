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
pragma experimental ABIEncoderV2;
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {TimeLockedToken} from './TimeLockedToken.sol';
import {AddressArrayUtils} from '../lib/AddressArrayUtils.sol';

import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';

/**
 * @title TimeLockRegistry
 * @notice Register Lockups for TimeLocked ERC20 Token BABL (e.g. vesting)
 * @author Babylon Finance
 * @dev This contract allows owner to register distributions for a TimeLockedToken
 *
 * To register a distribution, register method should be called by the owner.
 * claim() should be called only by the BABL Token smartcontract (modifier onlyBABLToken)
 *  when any account registered to receive tokens make its own claim
 * If case of a mistake, owner can cancel registration before the claim is done by the account
 *
 * Note this contract address must be setup in the TimeLockedToken's contract pointing
 * to interact with (e.g. setTimeLockRegistry() function)
 */

contract TimeLockRegistry is Ownable {
    using LowGasSafeMath for uint256;
    using Address for address;
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event Register(address receiver, uint256 distribution);
    event Cancel(address receiver, uint256 distribution);
    event Claim(address account, uint256 distribution);

    /* ============ Modifiers ============ */

    modifier onlyBABLToken() {
        require(msg.sender == address(token), 'only BABL Token');
        _;
    }

    /* ============ State Variables ============ */

    // time locked token
    TimeLockedToken public token;

    /**
     * @notice The profile of each token owner under vesting conditions and its special conditions
     * @param receiver Account being registered
     * @param investorType Indicates whether or not is a Team member (true = team member / advisor, false = private investor)
     * @param vestingStarting Date When the vesting begins for such token owner
     * @param distribution Tokens amount that receiver is due to get
     */
    struct Registration {
        address receiver;
        uint256 distribution;
        bool investorType;
        uint256 vestingStartingDate;
    }

    /**
     * @notice The profile of each token owner under vesting conditions and its special conditions
     * @param team Indicates whether or not is a Team member (true = team member / advisor, false = private investor)
     * @param vestingBegin When the vesting begins for such token owner
     * @param vestingEnd When the vesting ends for such token owner
     * @param lastClaim When the last claim was done
     */
    struct TokenVested {
        bool team;
        bool cliff;
        uint256 vestingBegin;
        uint256 vestingEnd;
        uint256 lastClaim;
    }

    /// @notice A record of token owners under vesting conditions for each account, by index
    mapping(address => TokenVested) public tokenVested;

    // mapping from token owners under vesting conditions to BABL due amount (e.g. SAFT addresses, team members, advisors)
    mapping(address => uint256) public registeredDistributions;

    // array of all registrations
    address[] public registrations;

    // total amount of tokens registered
    uint256 public totalTokens;

    // vesting for Team Members
    uint256 private constant teamVesting = 365 days * 4;

    // vesting for Investors and Advisors
    uint256 private constant investorVesting = 365 days * 3;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    /**
     * @notice Construct a new Time Lock Registry and gives ownership to sender
     * @param _token TimeLockedToken contract to use in this registry
     */
    constructor(TimeLockedToken _token) {
        token = _token;
    }

    /* ============ External Functions ============ */

    /* ============ External Getter Functions ============ */

    /**
     * Gets registrations
     *
     * @return  address[]        Returns list of registrations
     */

    function getRegistrations() external view returns (address[] memory) {
        return registrations;
    }

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION
     *
     * @notice Register multiple investors/team in a batch
     * @param _registrations Registrations to process
     */
    function registerBatch(Registration[] memory _registrations) external onlyOwner {
        for (uint256 i = 0; i < _registrations.length; i++) {
            register(
                _registrations[i].receiver,
                _registrations[i].distribution,
                _registrations[i].investorType,
                _registrations[i].vestingStartingDate
            );
        }
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION
     *
     * @notice Register new account under vesting conditions (Team, Advisors, Investors e.g. SAFT purchaser)
     * @param receiver Address belonging vesting conditions
     * @param distribution Tokens amount that receiver is due to get
     */
    function register(
        address receiver,
        uint256 distribution,
        bool investorType,
        uint256 vestingStartingDate
    ) public onlyOwner {
        require(receiver != address(0), 'TimeLockRegistry::register: cannot register the zero address');
        require(
            receiver != address(this),
            'TimeLockRegistry::register: Time Lock Registry contract cannot be an investor'
        );
        require(distribution != 0, 'TimeLockRegistry::register: Distribution = 0');
        require(
            registeredDistributions[receiver] == 0,
            'TimeLockRegistry::register:Distribution for this address is already registered'
        );
        require(block.timestamp >= 1614553200, 'Cannot register earlier than March 2021'); // 1614553200 is UNIX TIME of 2021 March the 1st
        require(totalTokens.add(distribution) <= IERC20(token).balanceOf(address(this)), 'Not enough tokens');

        totalTokens = totalTokens.add(distribution);
        // register distribution
        registeredDistributions[receiver] = distribution;
        registrations.push(receiver);

        // register token vested conditions
        TokenVested storage newTokenVested = tokenVested[receiver];
        newTokenVested.team = investorType;
        newTokenVested.vestingBegin = vestingStartingDate;

        if (newTokenVested.team == true) {
            newTokenVested.vestingEnd = vestingStartingDate.add(teamVesting);
        } else {
            newTokenVested.vestingEnd = vestingStartingDate.add(investorVesting);
        }
        newTokenVested.lastClaim = vestingStartingDate;

        tokenVested[receiver] = newTokenVested;

        // emit register event
        emit Register(receiver, distribution);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel distribution registration in case of mistake and before a claim is done
     *
     * @notice Cancel distribution registration
     * @dev A claim has not to be done earlier
     * @param receiver Address that should have it's distribution removed
     * @return Whether or not it succeeded
     */
    function cancelRegistration(address receiver) external onlyOwner returns (bool) {
        require(registeredDistributions[receiver] != 0, 'Not registered');

        // get amount from distributions
        uint256 amount = registeredDistributions[receiver];

        // set distribution mapping to 0
        delete registeredDistributions[receiver];

        // set tokenVested mapping to 0
        delete tokenVested[receiver];

        // remove from the list of all registrations
        registrations.remove(receiver);

        // decrease total tokens
        totalTokens = totalTokens.sub(amount);

        // emit cancel event
        emit Cancel(receiver, amount);

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel distribution registration in case of mistake and before a claim is done
     *
     * @notice Cancel already delivered tokens. It might only apply when non-completion of vesting period of Team members or Advisors
     * @dev An automatic override allowance is granted during the claim process
     * @param account Address that should have it's distribution removed
     * @return Whether or not it succeeded
     */
    function cancelDeliveredTokens(address account) external onlyOwner returns (bool) {
        uint256 loosingAmount = token.cancelVestedTokens(account);

        // emit cancel event
        emit Cancel(account, loosingAmount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Recover tokens in Time Lock Registry smartcontract address by the owner
     *
     * @notice Send tokens from smartcontract address to the owner.
     * It might only apply after a cancellation of vested tokens
     * @param amount Amount to be recovered by the owner of the Time Lock Registry smartcontract from its balance
     * @return Whether or not it succeeded
     */
    function transferToOwner(uint256 amount) external onlyOwner returns (bool) {
        SafeERC20.safeTransfer(token, msg.sender, amount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Claim locked tokens by the registered account
     *
     * @notice Claim tokens due amount.
     * @dev Claim is done by the user in the TimeLocked contract and the contract is the only allowed to call
     * this function on behalf of the user to make the claim
     * @return The amount of tokens registered and delivered after the claim
     */
    function claim(address _receiver) external onlyBABLToken returns (uint256) {
        require(registeredDistributions[_receiver] != 0, 'Not registered');

        // get amount from distributions
        uint256 amount = registeredDistributions[_receiver];
        TokenVested storage claimTokenVested = tokenVested[_receiver];

        claimTokenVested.lastClaim = block.timestamp;

        // set distribution mapping to 0
        delete registeredDistributions[_receiver];

        // decrease total tokens
        totalTokens = totalTokens.sub(amount);

        // register lockup in TimeLockedToken
        // this will transfer funds from this contract and lock them for sender
        token.registerLockup(
            _receiver,
            amount,
            claimTokenVested.team,
            claimTokenVested.vestingBegin,
            claimTokenVested.vestingEnd,
            claimTokenVested.lastClaim
        );

        // set tokenVested mapping to 0
        delete tokenVested[_receiver];

        // emit claim event
        emit Claim(_receiver, amount);

        return amount;
    }

    /* ============ Getter Functions ============ */

    function checkVesting(address address_)
        external
        view
        returns (
            bool team,
            uint256 start,
            uint256 end,
            uint256 last
        )
    {
        TokenVested storage checkTokenVested = tokenVested[address_];

        return (
            checkTokenVested.team,
            checkTokenVested.vestingBegin,
            checkTokenVested.vestingEnd,
            checkTokenVested.lastClaim
        );
    }

    function checkRegisteredDistribution(address address_) external view returns (uint256 amount) {
        return registeredDistributions[address_];
    }
}
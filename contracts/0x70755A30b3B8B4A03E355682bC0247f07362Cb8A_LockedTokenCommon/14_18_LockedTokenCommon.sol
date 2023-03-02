/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

import "GlobalUnlock.sol";
import "LockedTokenGrant.sol";
import "FixedProxy.sol";
import "Address.sol";

/**
  The {LockedTokenCommon} contract serves two purposes:
  1. Maintain the StarkNetToken global timelock (see {GlobalUnlock})
  2. Allocate locked token grants in {LockedTokenGrant} contracts.

  Roles:
  =====
  1. At initializtion time, the msg.sender of the initialize tx, is defined as DEFAULT_ADMIN_ROLE.
  2. LOCKED_GRANT_ADMIN_ROLE is required to call `grantLockedTokens`.
  3. GLOBAL_TIMELOCK_ADMIN_ROLE is reqiured to call the `updateGlobalLock`.
  Two special roles must be granted

  Grant Locked Tokens:
  ===================
  Locked token grants are granted using the `grantLockedTokens` here.
  The arguments passed are:
  - recipient - The address of the tokens "owner". When the tokens get unlocked, they can be released
                to the recipient address, and only there.
  - amount    - The number of tokens to be transfered onto the grant contract upon creation.
  - startTime - The timestamp of the beginning of the 4 years unlock period over which the tokens
                gradually unlock. The startTime can be anytime within the margins specified in the {CommonConstants}.
  - allocationPool - The {LockedTokenCommon} doesn't hold liquidity from which it can grant the tokens,
                     but rather uses an external LP for that. The `allocationPool` is the address of the LP
                     from which the tokens shall be allocated. The {LockedTokenCommon} must have sufficient allowance
                     on the `allocationPool` so it can transfer funds from it onto the creatred grant contract.

    Flow: The {LockedTokenCommon} deploys the contract of the new {LockedTokenGrant},
          transfer the grant amount from the allocationPool onto the new grant,
          and register the new grant in a mapping.
*/
contract LockedTokenCommon is GlobalUnlock {
    // Maps recipient to its locked grant contract.
    mapping(address => address) public grantByRecipient;
    IERC20 internal immutable tokenContract;
    address internal immutable stakingContract;
    address internal immutable defaultRegistry;
    address internal immutable lockedTokenImplementation;

    event LockedTokenGranted(
        address indexed recipient,
        address indexed grantContract,
        uint256 grantAmount,
        uint256 startTime
    );

    constructor(
        address tokenAddress_,
        address stakingContract_,
        address defaultRegistry_,
        address lockedTokenImplementation_
    ) {
        require(Address.isContract(tokenAddress_), "NOT_A_CONTRACT");
        require(Address.isContract(stakingContract_), "NOT_A_CONTRACT");
        require(Address.isContract(defaultRegistry_), "NOT_A_CONTRACT");
        require(Address.isContract(lockedTokenImplementation_), "NOT_A_CONTRACT");
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        tokenContract = IERC20(tokenAddress_);
        stakingContract = stakingContract_;
        defaultRegistry = defaultRegistry_;
        lockedTokenImplementation = lockedTokenImplementation_;
    }

    /**
      Deploys a LockedTokenGrant and transfers `grantAmount` tokens onto it.
      Returns the address of the LockedTokenGrant contract.

      Tokens owned by the {LockedTokenGrant} are initially locked, and can only be used for staking.
      The tokens gradually unlocked and can be transferred to the `recipient`.
    */
    function grantLockedTokens(
        address recipient,
        uint256 grantAmount,
        uint256 startTime,
        address allocationPool
    ) external onlyRole(LOCKED_GRANT_ADMIN_ROLE) returns (address) {
        require(grantByRecipient[recipient] == address(0x0), "ALREADY_GRANTED");
        require(
            startTime < block.timestamp + LOCKED_GRANT_MAX_START_FUTURE_OFFSET,
            "START_TIME_TOO_LATE"
        );
        require(
            startTime > block.timestamp - LOCKED_GRANT_MAX_START_PAST_OFFSET,
            "START_TIME_TOO_EARLY"
        );

        bytes memory init_data = abi.encode(
            address(tokenContract),
            stakingContract,
            defaultRegistry,
            recipient,
            grantAmount,
            startTime
        );

        address grantAddress = address(new FixedProxy(lockedTokenImplementation, init_data));
        require(
            tokenContract.transferFrom(allocationPool, grantAddress, grantAmount),
            "TRANSFER_FROM_FAILED"
        );
        grantByRecipient[recipient] = grantAddress;
        emit LockedTokenGranted(recipient, grantAddress, grantAmount, startTime);
        return grantAddress;
    }
}
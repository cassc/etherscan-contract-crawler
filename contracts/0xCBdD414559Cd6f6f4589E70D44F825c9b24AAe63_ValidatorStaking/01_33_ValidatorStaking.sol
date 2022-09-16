// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/StakingNFT/StakingNFT.sol";

/// @custom:salt ValidatorStaking
/// @custom:deploy-type deployUpgradeable
contract ValidatorStaking is StakingNFT {
    constructor() StakingNFT() {}

    function initialize() public initializer onlyFactory {
        __stakingNFTInit("AVSNFT", "AVS");
    }

    /// mint allows a staking position to be opened. This function
    /// requires the caller to have performed an approve invocation against
    /// AToken into this contract. This function will fail if the circuit
    /// breaker is tripped.
    function mint(uint256 amount_)
        public
        override
        withCircuitBreaker
        onlyValidatorPool
        returns (uint256 tokenID)
    {
        return _mintNFT(msg.sender, amount_);
    }

    /// mintTo allows a staking position to be opened in the name of an
    /// account other than the caller. This method also allows a lock to be
    /// placed on the position up to _MAX_MINT_LOCK . This function requires the
    /// caller to have performed an approve invocation against AToken into
    /// this contract. This function will fail if the circuit breaker is
    /// tripped.
    function mintTo(
        address to_,
        uint256 amount_,
        uint256 lockDuration_
    ) public override withCircuitBreaker onlyValidatorPool returns (uint256 tokenID) {
        if (lockDuration_ > _MAX_MINT_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanMintLock();
        }
        tokenID = _mintNFT(to_, amount_);
        if (lockDuration_ > 0) {
            _lockPosition(tokenID, lockDuration_);
        }
        return tokenID;
    }

    /// burn exits a staking position such that all accumulated value is
    /// transferred to the owner on burn.
    function burn(uint256 tokenID_)
        public
        override
        onlyValidatorPool
        returns (uint256 payoutEth, uint256 payoutAToken)
    {
        return _burn(msg.sender, msg.sender, tokenID_);
    }

    /// burnTo exits a staking position such that all accumulated value
    /// is transferred to a specified account on burn
    function burnTo(address to_, uint256 tokenID_)
        public
        override
        onlyValidatorPool
        returns (uint256 payoutEth, uint256 payoutAToken)
    {
        return _burn(msg.sender, to_, tokenID_);
    }
}
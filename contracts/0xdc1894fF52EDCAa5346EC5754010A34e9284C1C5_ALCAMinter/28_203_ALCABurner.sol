// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingToken.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";

/// @custom:salt ALCABurner
/// @custom:deploy-type deployUpgradeable
contract ALCABurner is ImmutableALCA, IStakingTokenBurner {
    constructor() ImmutableFactory(msg.sender) ImmutableALCA() IStakingTokenBurner() {}

    /**
     * @notice Burns ALCAs using the ALCA contract. The burned tokens are removed from the
     * totalSupply.
     * @param from_ The address from where the tokens will be burned
     * @param amount_ The amount of ALCAs to be burned
     */
    function burn(address from_, uint256 amount_) public onlyFactory {
        IStakingToken(_alcaAddress()).externalBurn(from_, amount_);
    }
}
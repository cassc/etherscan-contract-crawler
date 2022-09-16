// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingToken.sol";
import "contracts/utils/ImmutableAuth.sol";

/// @custom:salt ATokenMinter
/// @custom:deploy-type deployUpgradeable
contract ATokenMinter is ImmutableAToken, IStakingTokenMinter {
    constructor() ImmutableFactory(msg.sender) ImmutableAToken() IStakingTokenMinter() {}

    /// Mints ATokens
    /// @param to_ The address to where the tokens will be minted
    /// @param amount_ The amount of ATokens to be minted
    function mint(address to_, uint256 amount_) public onlyFactory {
        IStakingToken(_aTokenAddress()).externalMint(to_, amount_);
    }
}
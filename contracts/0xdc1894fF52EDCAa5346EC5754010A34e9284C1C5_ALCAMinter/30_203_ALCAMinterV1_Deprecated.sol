// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingToken.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";

//deprecated
/// @custom:salt ALCAMinter
/// @custom:deploy-type deployUpgradeable
contract ALCAMinterV1 is ImmutableALCA, IStakingTokenMinter {
    constructor() ImmutableFactory(msg.sender) ImmutableALCA() IStakingTokenMinter() {}

    /**
     * @notice Mints ALCAs
     * @param to_ The address to where the tokens will be minted
     * @param amount_ The amount of ALCAs to be minted
     * */
    function mint(address to_, uint256 amount_) public onlyFactory {
        IStakingToken(_alcaAddress()).externalMint(to_, amount_);
    }
}
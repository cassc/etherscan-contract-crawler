// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingToken.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";

contract ALCAMinterMock is ImmutableALCA {
    constructor() ImmutableFactory(msg.sender) ImmutableALCA() {}

    function mint(address to, uint256 amount) public {
        IStakingToken(_alcaAddress()).externalMint(to, amount);
    }
}
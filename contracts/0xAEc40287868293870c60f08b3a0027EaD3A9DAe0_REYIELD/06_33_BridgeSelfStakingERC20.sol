// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./SelfStakingERC20.sol";
import "./IBridgeSelfStakingERC20.sol";
import "./Bridgeable.sol";

abstract contract BridgeSelfStakingERC20 is SelfStakingERC20, Minter, Bridgeable, IBridgeSelfStakingERC20
{
    function bridgeCanMint(address user) internal override view returns (bool) { return isMinter(user); }
    function bridgeSigningHash(bytes32 dataHash) internal override view returns (bytes32) { return getSigningHash(dataHash); }
    function bridgeMint(address to, uint256 amount) internal override { return mintCore(to, amount); }
    function bridgeBurn(address from, uint256 amount) internal override { return burnCore(from, amount); }
    
    function checkUpgrade(address newImplementation)
        internal
        virtual
        override(SelfStakingERC20, Bridgeable)
        view
    {
        Bridgeable.checkUpgrade(newImplementation);
        SelfStakingERC20.checkUpgrade(newImplementation);
    }
}
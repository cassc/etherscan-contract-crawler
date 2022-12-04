// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./UUPSERC20.sol";
import "./IBridgeUUPSERC20.sol";
import "./Bridgeable.sol";

abstract contract BridgeUUPSERC20 is UUPSERC20, Minter, Bridgeable, IBridgeUUPSERC20
{
    function bridgeCanMint(address user) internal override view returns (bool) { return isMinter(user); }
    function bridgeSigningHash(bytes32 dataHash) internal override view returns (bytes32) { return getSigningHash(dataHash); }
    function bridgeMint(address to, uint256 amount) internal override { return mintCore(to, amount); }
    function bridgeBurn(address from, uint256 amount) internal override { return burnCore(from, amount); }
    
    function checkUpgrade(address newImplementation)
        internal
        virtual
        override(UUPSERC20, Bridgeable)
        view
    {
        Bridgeable.checkUpgrade(newImplementation);
        UUPSERC20.checkUpgrade(newImplementation);
    }
}
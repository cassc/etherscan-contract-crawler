// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./RERC20.sol";
import "./IBridgeRERC20.sol";
import "./Bridgeable.sol";

/**
    A bridgeable ERC20 contract
*/
abstract contract BridgeRERC20 is RERC20, Minter, Bridgeable, IBridgeRERC20
{
    function bridgeCanMint(address user) internal override view returns (bool) { return isMinter(user); }
    function bridgeSigningHash(bytes32 dataHash) internal override view returns (bytes32) { return getSigningHash(dataHash); }
    function bridgeMint(address to, uint256 amount) internal override { return mintCore(to, amount); }
    function bridgeBurn(address from, uint256 amount) internal override { return burnCore(from, amount); }
    
    function checkUpgrade(address newImplementation)
        internal
        virtual
        override(RERC20, Bridgeable)
        view
    {
        Bridgeable.checkUpgrade(newImplementation);
        RERC20.checkUpgrade(newImplementation);
    }
}
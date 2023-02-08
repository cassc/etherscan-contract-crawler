// SPDX-License-Identifier: MIT

/*

((((((((((((((((((((((((((((((((((((((((((          
((((((((((((((((((((((((((((((((((((((((((             
((((((((((((((((((((((((((((((((((((((((((             
((((((((((((((((((((((((((((((((((((((((((             
((((((((((((((((((((((((((((((((((((((((((             
((((((((((((((((((((((((((((((((((((((((((             
((((((((((((((                            ((((((((((((((
((((((((((((((                            ((((((((((((((
((((((((((((((                            ((((((((((((((
((((((((((((((                            ((((((((((((((
((((((((((((((                            ((((((((((((((
((((((((((((((                            ((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((

*/

// @title Check Turtz Delegate Balance
// @author @tom_hirst
// @notice Checks the token balance of a delegate wallet
// @dev Uses Warm Wallet (warm.xyz)

pragma solidity ^0.8.17;

interface IWarmWallet {
    function balanceOf(
        address contractAddress,
        address owner
    ) external view returns (uint256);
}

error EmptyWarmWalletContract();

contract CheckTurtzDelegateBalance {
    address public immutable WARM_WALLET_ADDRESS;

    constructor(address _warmWalletAddress) {
        if (_warmWalletAddress == address(0)) {
            revert EmptyWarmWalletContract();
        }

        WARM_WALLET_ADDRESS = _warmWalletAddress;
    }

    function delegateBalance(
        address contractAddress
    ) internal view returns (uint256) {
        return
            IWarmWallet(WARM_WALLET_ADDRESS).balanceOf(
                contractAddress,
                msg.sender
            );
    }
}
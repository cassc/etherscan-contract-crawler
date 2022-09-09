// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/IRoboFiERC20.sol";

address constant NATIVE_ASSET_ADDRESS = address(0x1E1e1E1E1e1e1e1e1e1E1E1E1E1e1e1E1e1e1E1E);

interface ITreasuryAssetEvent {
    event Lock(address indexed account, uint256 amount);
    event Unlock(address indexed caller, uint256 amount, address indexed account);
    event Slash(address indexed bot, uint256 amount);
    event FundManagerChanged(address indexed fundmanager);
}

interface ITreasuryAsset is IRoboFiERC20, ITreasuryAssetEvent {

    /**
    @dev Gets the total locked amount.
     */
    function totalLocked() external view returns(uint);

    /**
    @dev Gets the address of the underlying asset.
     */
    function asset() external view returns(IRoboFiERC20);

    /**
    @dev Deposits `amount` of original asset, and gets back an equivalent amount of token.
    **/
    function mint(address to, uint256 amount) external payable;

    /**
    @dev Burns `amount` of sToken to get back original  tokens
     */
    function burn(uint256 amount) external;

    /**
    @dev Burns `amount` of sToken WITHOUT get back the original tokens (this is for trading loss). 
    Only accept calls from registred DABot.
     */
    function slash(uint256 amount) external;

    /**
    @dev Locks `amount` of token from the caller's account. An equivalent amount of 
    original asset will be transferred to the fund manager.

    Return the locked balanced of the caller's account.
    **/    
    function lock(uint256 amount) external;

    /**
    @dev Get the locked amounts of sToken for `user`
    **/
    function lockedBalanceOf(address user) external view returns (uint256);

    /**
    @dev Gets `amount` of tocken from the caller account, and decrease the locked balance of `user`. 
    **/
    function unlock(address user, uint256 amount) external payable;

    /**
    @dev Determines if the underlying asset is native token or not.
     */
    function isNativeAsset() external view returns(bool);
}
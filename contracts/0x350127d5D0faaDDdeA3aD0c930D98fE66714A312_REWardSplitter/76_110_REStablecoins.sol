// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREStablecoins.sol";
import "./Base/UpgradeableBase.sol";
import "./Base/IERC20Full.sol";

/**
    Supported stablecoins configuration

    The "baked in" stablecoins are a gas optimization.  We support up to 3 of them, or could increase this (but we probably won't!)

    All stablecoins MUST have 6 or 18 decimals.  If this ever changes, we need to change code in other contracts which rely on this behavior

    External contracts probably just call "getStablecoinDecimals".  Everything else is front-end helpers or admin, pretty much.

    Version 2 -> 3 ... Simplifying it.  Stop tracking permit abilities.  It's better suited on front end.  Other future-use plans have changed, so this simplification made sense.
 */
contract REStablecoins is UpgradeableBase(3), IREStablecoins
{
    IERC20[] private moreStablecoinAddresses;
    mapping (IERC20 => uint8) private moreStablecoinDecimals;

    //------------------ end of storage
    
    bool public constant isREStablecoins = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 private immutable stablecoin1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 private immutable stablecoin2;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 private immutable stablecoin3;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint8 private immutable decimals1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint8 private immutable decimals2;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint8 private immutable decimals3;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _stablecoin1, IERC20 _stablecoin2, IERC20 _stablecoin3)
    {
        stablecoin1 = _stablecoin1;
        stablecoin2 = _stablecoin2;
        stablecoin3 = _stablecoin3;
        decimals1 = loadDecimals(_stablecoin1);
        decimals2 = loadDecimals(_stablecoin2);
        decimals3 = loadDecimals(_stablecoin3);
    }

    function loadDecimals(IERC20 _token) 
        private
        view
        returns (uint8 decimals)
    {
        if (address(_token) == address(0)) { return 0; }
        decimals = IERC20Full(address(_token)).decimals();
        if (decimals != 6 && decimals != 18) { revert TokenNotSupported(); }
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREStablecoins(newImplementation).isREStablecoins());
    }

    function supported()
        public
        view
        returns (StablecoinConfigWithName[] memory stablecoins)
    {
        unchecked
        {
            uint256 builtInCount = 0;
            if (address(stablecoin1) != address(0)) { ++builtInCount; }
            if (address(stablecoin2) != address(0)) { ++builtInCount; }
            if (address(stablecoin3) != address(0)) { ++builtInCount; }
            stablecoins = new StablecoinConfigWithName[](builtInCount + moreStablecoinAddresses.length);
            uint256 at = 0;
            if (address(stablecoin1) != address(0)) { stablecoins[at++] = toStablecoinConfigWithName(stablecoin1, decimals1); }
            if (address(stablecoin2) != address(0)) { stablecoins[at++] = toStablecoinConfigWithName(stablecoin2, decimals2); }
            if (address(stablecoin3) != address(0)) { stablecoins[at++] = toStablecoinConfigWithName(stablecoin3, decimals3); }
            for (uint256 x = moreStablecoinAddresses.length; x > 0;) 
            {
                IERC20 token = moreStablecoinAddresses[--x];
                stablecoins[at++] = toStablecoinConfigWithName(token, moreStablecoinDecimals[token]);
            }
        }
    }

    function toStablecoinConfigWithName(IERC20 token, uint8 decimals)
        private
        view
        returns (StablecoinConfigWithName memory configWithName)
    {
        return StablecoinConfigWithName({
            token: token,
            decimals: decimals,
            name: IERC20Full(address(token)).name(),
            symbol: IERC20Full(address(token)).symbol()
        });
    }

    function getDecimals(IERC20 token)
        public
        view
        returns (uint8 decimals)
    {
        unchecked
        {
            if (address(token) == address(0)) { revert TokenNotSupported(); }
            if (token == stablecoin1) { return decimals1; }
            if (token == stablecoin2) { return decimals2; }
            if (token == stablecoin3) { return decimals3; }
            decimals = moreStablecoinDecimals[token];
            if (decimals == 0) { revert TokenNotSupported(); }            
        }
    }

    function add(IERC20 stablecoin)
        public
        onlyOwner
    {
        if (stablecoin == stablecoin1 ||
            stablecoin == stablecoin2 ||
            stablecoin == stablecoin3 ||
            moreStablecoinDecimals[stablecoin] > 0)
        {
            revert StablecoinAlreadyExists();
        }
        moreStablecoinDecimals[stablecoin] = loadDecimals(stablecoin);
        moreStablecoinAddresses.push(stablecoin);
    }

    function remove(IERC20 stablecoin)
        public
        onlyOwner
    {
        if (moreStablecoinDecimals[stablecoin] > 0)
        {
            moreStablecoinDecimals[stablecoin] = 0;
            for (uint256 x = moreStablecoinAddresses.length - 1; ; --x) 
            {
                if (moreStablecoinAddresses[x] == stablecoin) 
                {
                    moreStablecoinAddresses[x] = moreStablecoinAddresses[moreStablecoinAddresses.length - 1];
                    moreStablecoinAddresses.pop();
                    return;
                }
            }
        }
        if (stablecoin == stablecoin1 ||
            stablecoin == stablecoin2 ||
            stablecoin == stablecoin3)
        {
            revert StablecoinBakedIn();
        }
        revert StablecoinDoesNotExist();
        
    }
}
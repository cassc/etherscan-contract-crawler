// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREStablecoins.sol";
import "./Base/UpgradeableBase.sol";
import "./Base/IERC20Full.sol";

/**
    Supported stablecoins configuration

    The "baked in" stablecoins are a gas optimization.  We support up to 3 of them, or could increase this (but we probably won't!)

    At present, we limit stablecoins to 6 or 18 decimals, but this is only a gas optimization.

    External contracts probably just call "getStablecoinDecimals".  Everything else is front-end helpers or admin, pretty much.

    Version 2 -> 3 ... Simplifying it.  Stop tracking permit abilities.  It's better suited on front end.  Other future-use plans have changed, so this simplification made sense.
 */
contract REStablecoins is UpgradeableBase(3), IREStablecoins
{
    IERC20[] private moreStablecoinAddresses;
    mapping (IERC20 => uint256) private moreStablecoinMultiplyFactors;

    //------------------ end of storage
    
    bool public constant isREStablecoins = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 private immutable stablecoin1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 private immutable stablecoin2;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 private immutable stablecoin3;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable factor1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable factor2;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable factor3;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _stablecoin1, IERC20 _stablecoin2, IERC20 _stablecoin3)
    {
        stablecoin1 = _stablecoin1;
        stablecoin2 = _stablecoin2;
        stablecoin3 = _stablecoin3;
        factor1 = loadFactor(_stablecoin1);
        factor2 = loadFactor(_stablecoin2);
        factor3 = loadFactor(_stablecoin3);
    }

    function loadFactor(IERC20 _token) 
        private
        view
        returns (uint256 factor)
    {
        if (address(_token) == address(0)) { return 0; }
        uint8 decimals = IERC20Full(address(_token)).decimals();
        if (decimals != 6 && decimals != 18) { revert TokenNotSupported(); }
        return decimals == 6 ? 10**12 : 1;
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
            if (address(stablecoin1) != address(0)) { stablecoins[at++] = toStablecoinConfigWithName(stablecoin1); }
            if (address(stablecoin2) != address(0)) { stablecoins[at++] = toStablecoinConfigWithName(stablecoin2); }
            if (address(stablecoin3) != address(0)) { stablecoins[at++] = toStablecoinConfigWithName(stablecoin3); }
            for (uint256 x = moreStablecoinAddresses.length; x > 0;) 
            {
                stablecoins[at++] = toStablecoinConfigWithName(moreStablecoinAddresses[--x]);
            }
        }
    }

    function toStablecoinConfigWithName(IERC20 token)
        private
        view
        returns (StablecoinConfigWithName memory configWithName)
    {
        return StablecoinConfigWithName({
            token: token,
            decimals: IERC20Full(address(token)).decimals(),
            name: IERC20Full(address(token)).name(),
            symbol: IERC20Full(address(token)).symbol()
        });
    }

    /** Returns a number which can be multiplied by a token amount to standardize to 18 decimal places
        If a token supports 18 decimals, this returns 1
        If a token supports 6 decimals, this returns 10**12
        Generally:  10 ** [18 - decimals]
        If a token is not in our list of supported stablecoins, this reverts with TokenNotSupported
     */
    function getMultiplyFactor(IERC20 token)
        public
        view
        returns (uint256 factor)
    {
        unchecked
        {
            if (address(token) == address(0)) { revert TokenNotSupported(); }
            if (token == stablecoin1) { return factor1; }
            if (token == stablecoin2) { return factor2; }
            if (token == stablecoin3) { return factor3; }
            factor = moreStablecoinMultiplyFactors[token];
            if (factor == 0) { revert TokenNotSupported(); }            
        }
    }

    function add(IERC20 stablecoin)
        public
        onlyOwner
    {
        if (stablecoin == stablecoin1 ||
            stablecoin == stablecoin2 ||
            stablecoin == stablecoin3 ||
            moreStablecoinMultiplyFactors[stablecoin] > 0)
        {
            revert StablecoinAlreadyExists();
        }
        if (address(stablecoin) == address(0)) { revert TokenNotSupported(); }
        moreStablecoinMultiplyFactors[stablecoin] = loadFactor(stablecoin);
        moreStablecoinAddresses.push(stablecoin);
    }

    function remove(IERC20 stablecoin)
        public
        onlyOwner
    {
        if (moreStablecoinMultiplyFactors[stablecoin] > 0)
        {
            moreStablecoinMultiplyFactors[stablecoin] = 0;
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
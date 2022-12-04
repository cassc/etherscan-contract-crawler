// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREStablecoins.sol";
import "./Base/UpgradeableBase.sol";

contract REStablecoins is UpgradeableBase(1), IREStablecoins
{
    address[] private moreStablecoinAddresses;
    mapping (address => StablecoinConfig) private moreStablecoins;

    //------------------ end of storage
    
    bool public constant isREStablecoins = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable stablecoin1; // Because `struct StablecoinConfig` can't be stored as immutable
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable stablecoin2;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable stablecoin3;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(StablecoinConfig memory _stablecoin1, StablecoinConfig memory _stablecoin2, StablecoinConfig memory _stablecoin3)
    {
        stablecoin1 = toUint256(_stablecoin1);
        stablecoin2 = toUint256(_stablecoin2);
        stablecoin3 = toUint256(_stablecoin3);
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREStablecoins(newImplementation).isREStablecoins());
    }

    function supportedStablecoins()
        public
        view
        returns (StablecoinConfigWithName[] memory stablecoins)
    {
        unchecked
        {
            uint256 builtInCount = 0;
            if (stablecoin1 != 0) { ++builtInCount; }
            if (stablecoin2 != 0) { ++builtInCount; }
            if (stablecoin3 != 0) { ++builtInCount; }
            stablecoins = new StablecoinConfigWithName[](builtInCount + moreStablecoinAddresses.length);
            uint256 at = 0;
            if (stablecoin1 != 0) { stablecoins[at++] = toStablecoinConfigWithName(toStablecoinConfig(stablecoin1)); }
            if (stablecoin2 != 0) { stablecoins[at++] = toStablecoinConfigWithName(toStablecoinConfig(stablecoin2)); }
            if (stablecoin3 != 0) { stablecoins[at++] = toStablecoinConfigWithName(toStablecoinConfig(stablecoin3)); }
            for (uint256 x = moreStablecoinAddresses.length; x > 0;) 
            {
                stablecoins[at++] = toStablecoinConfigWithName(moreStablecoins[moreStablecoinAddresses[--x]]);
            }
        }
    }

    function toUint256(StablecoinConfig memory stablecoin)
        private
        view
        returns (uint256)
    {        
        unchecked
        {
            if (address(stablecoin.token) == address(0)) { return 0; }
            if (stablecoin.decimals != 6 && stablecoin.decimals != 18) { revert TokenNotSupported(); }
            if (stablecoin.decimals != stablecoin.token.decimals()) { revert TokenMisconfigured(); }
            if (stablecoin.hasPermit) { stablecoin.token.DOMAIN_SEPARATOR(); }
            return uint256(uint160(address(stablecoin.token))) | (uint256(stablecoin.decimals) << 160) | (stablecoin.hasPermit ? 1 << 168 : 0);
        }
    }

    function toStablecoinConfig(uint256 data)
        private
        pure
        returns (StablecoinConfig memory config)
    {
        unchecked
        {
            config.token = IERC20Full(address(uint160(data)));
            config.decimals = uint8(data >> 160);
            config.hasPermit = data >> 168 != 0;
        }
    }

    function toStablecoinConfigWithName(StablecoinConfig memory config)
        private
        view
        returns (StablecoinConfigWithName memory configWithName)
    {
        return StablecoinConfigWithName({
            config: config,
            name: config.token.name(),
            symbol: config.token.symbol()
        });
    }

    function getStablecoinConfig(address token)
        public
        view
        returns (StablecoinConfig memory config)
    {
        unchecked
        {
            if (token == address(0)) { revert TokenNotSupported(); }
            if (token == address(uint160(stablecoin1))) { return toStablecoinConfig(stablecoin1); }
            if (token == address(uint160(stablecoin2))) { return toStablecoinConfig(stablecoin2); }
            if (token == address(uint160(stablecoin3))) { return toStablecoinConfig(stablecoin3); }
            config = moreStablecoins[token];
            if (address(config.token) == address(0)) { revert TokenNotSupported(); }            
        }
    }

    function addStablecoin(address stablecoin, bool hasPermit)
        public
        onlyOwner
    {
        if (stablecoin == address(uint160(stablecoin1)) ||
            stablecoin == address(uint160(stablecoin2)) ||
            stablecoin == address(uint160(stablecoin3)) ||
            address(moreStablecoins[stablecoin].token) != address(0))
        {
            revert StablecoinAlreadyExists();
        }
        if (hasPermit) { IERC20Full(stablecoin).DOMAIN_SEPARATOR(); }
        uint8 decimals = IERC20Full(stablecoin).decimals();
        if (decimals != 6 && decimals != 18) { revert TokenNotSupported(); }
        moreStablecoinAddresses.push(stablecoin);
        moreStablecoins[stablecoin] = StablecoinConfig({
            token: IERC20Full(stablecoin),
            decimals: decimals,
            hasPermit: hasPermit
        });
    }

    function removeStablecoin(address stablecoin)
        public
        onlyOwner
    {
        if (stablecoin == address(uint160(stablecoin1)) ||
            stablecoin == address(uint160(stablecoin2)) ||
            stablecoin == address(uint160(stablecoin3)))
        {
            revert StablecoinBakedIn();
        }
        if (address(moreStablecoins[stablecoin].token) == address(0)) { revert StablecoinDoesNotExist(); }
        delete moreStablecoins[stablecoin];
        for (uint256 x = moreStablecoinAddresses.length - 1; ; --x) 
        {
            if (moreStablecoinAddresses[x] == stablecoin) 
            {
                moreStablecoinAddresses[x] = moreStablecoinAddresses[moreStablecoinAddresses.length - 1];
                moreStablecoinAddresses.pop();
                break;
            }
        }
    }
}
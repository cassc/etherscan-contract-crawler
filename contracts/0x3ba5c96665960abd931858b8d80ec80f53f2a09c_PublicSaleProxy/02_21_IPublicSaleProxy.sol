//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IPublicSaleProxy {
    /// @dev set the logic
    /// @param _impl publicSaleContract Address;
    function setImplementation(address _impl) external;
    /// @dev Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external;

    /// @dev Set implementation contract
    /// @param _impl New implementation contract address
    function upgradeTo(address _impl) external;

    /// @dev view implementation address
    /// @return the logic address
    function implementation() external view returns (address);

    /// @dev initialize
    function initialize(
        address _saleTokenAddress,
        address _getTokenOwner,
        address _vaultAddress
    ) external;

    /// @dev changeBasicSet
    function changeBasicSet(
        address _getTokenAddress,
        address _sTOS,
        address _wton,
        address _uniswapRouter,
        address _TOS
    ) external;

    /// @dev set Max,Min
    /// @param _min wton->tos min Percent
    /// @param _max wton->tos max Percent
    function setMaxMinPercent(
        uint256 _min,
        uint256 _max
    ) external;

    /// @dev set sTOSstandrard
    /// @param _tier1 tier1 standrard
    /// @param _tier2 tier2 standrard
    /// @param _tier3 tier3 standrard
    /// @param _tier4 tier4 standrard
    function setSTOSstandard(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    ) external;

    /// @dev set delayTime
    /// @param _delay delayTime
    function setDelayTime(
        uint256 _delay
    ) external;
}
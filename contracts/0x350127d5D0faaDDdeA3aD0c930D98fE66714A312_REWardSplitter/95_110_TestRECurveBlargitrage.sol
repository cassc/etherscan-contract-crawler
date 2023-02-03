// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../RECurveBlargitrage.sol";

contract TestRECurveBlargitrage is RECurveBlargitrage
{    
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, IREUSD _reusd, ICurveStableSwap _pool, ICurvePool _basePool, IERC20 _desiredToken)
        RECurveBlargitrage(_custodian, _reusd, _pool, _basePool, _desiredToken)
    {        
    }

    function getREUSDIndex() external view returns (uint256) { return reusdIndex; }
    function getBasePoolIndex() external view returns (uint256) { return basePoolIndex; }
    function getBasePoolToken() external view returns (IERC20) { return basePoolToken; }

    bool skipBalance;
    uint256 public balanceCallCount;
    function setSkipBalance(bool skip) public { skipBalance = skip; }

    function balance() public override
    {
        ++balanceCallCount;
        if (!skipBalance) { super.balance(); }
    }
}
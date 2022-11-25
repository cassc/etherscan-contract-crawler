// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "contracts/Stage1/BondingCurve.sol";
import "contracts/Stage1/TokenManager.sol";
import "contracts/interfaces/IChainlink.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/Rates.sol";

contract SEuroCalculator is AccessControl {
    // address of Offering contract, the key dependent of this contract
	bytes32 public constant OFFERING = keccak256("OFFERING");

    address public immutable EUR_USD_CL;
    uint8 public immutable EUR_USD_CL_DEC;

    BondingCurve public bondingCurve;

    /// @param _bondingCurve address of Bonding Curve contract
    /// @param _eurUsdCl address of Chainlink data feed for EUR / USD
    constructor(address _bondingCurve, address _eurUsdCl) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(OFFERING, DEFAULT_ADMIN_ROLE);
        grantRole(OFFERING, msg.sender);

        bondingCurve = BondingCurve(_bondingCurve);
        EUR_USD_CL = _eurUsdCl;
        EUR_USD_CL_DEC = IChainlink(_eurUsdCl).decimals();
    }

    modifier onlyAdmin() { require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "invalid-admin"); _; }

    modifier onlyOffering() { require(hasRole(OFFERING, msg.sender), "invalid-calculator-offering"); _; }

    function setBondingCurve(address _newAddress) external onlyAdmin {
        require(_newAddress != address(0), "err-invalid-err");
        bondingCurve = BondingCurve(_newAddress);
    }

    function scaleTo18Dec(uint256 _amount, TokenManager.TokenData memory _token) private pure returns (uint256 euros) { return _amount * 10 ** (18 - _token.dec); }

    function calculateEuros(uint256 _amount, TokenManager.TokenData memory _token) private view returns (uint256 euros) {
        (,int256 tokUsd,,,) = IChainlink(_token.chainlinkAddr).latestRoundData();
        (,int256 eurUsd,,,) = IChainlink(EUR_USD_CL).latestRoundData();
        uint256 amount = scaleTo18Dec(_amount, _token);
        uint256 usd = Rates.convertDefault(amount, uint256(tokUsd), _token.chainlinkDec);
        euros = Rates.convertInverse(usd, uint256(eurUsd), EUR_USD_CL_DEC);
    }

    // Calculates exactly how much sEURO should be minted, given the amount and relevant Chainlink data feed
    // This function (subsequently in the Bonding Curve) caches price calculations for efficiency
    // It is therefore a state-changing function
    /// @param _amount the amount of the given token that you'd like to calculate the exchange value for
    /// @param _token Token Manager Token for which you'd like to calculate
    function calculate(uint256 _amount, TokenManager.TokenData memory _token) external onlyOffering returns (uint256) {
        return bondingCurve.calculatePrice(calculateEuros(_amount, _token));
    }

    // A read-only function to estimate how much sEURO would be received, given the amount and relevant Chainlink data feed
    // This function provides a simplified calculation and is therefore just an estimation
    /// @param _amount the amount of the given token that you'd like to estimate the exchange value for
    /// @param _token Token Manager Token for which you'd like to estimate
    function readOnlyCalculate(uint256 _amount, TokenManager.TokenData memory _token) external view returns (uint256) {
        return bondingCurve.readOnlyCalculatePrice(calculateEuros(_amount, _token));
    }
}
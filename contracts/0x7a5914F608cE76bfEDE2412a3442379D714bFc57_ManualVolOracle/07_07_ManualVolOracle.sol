// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity 0.8.9;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

contract ManualVolOracle is AccessControl {
    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /// @dev Map of option id to IV
    mapping(bytes32 => uint256) private annualizedVols;

    /**
     * Instrument describe an option with a specific delta, asset and its option type.
     */
    struct Option {
        // option delta
        uint256 delta;
        // Underlying token, eg an stETH-collateralized option's underlying is WETH
        address underlying;
        // Asset used to collateralize an option, eg an stETH-collateralized option's collateral is wstETH
        address collateralAsset;
        // If an onToken is a put or not
        bool isPut;
    }

    /**
     * @notice Creates an volatility oracle for a pool
     * @param _admin is the admin
     */
    constructor(address _admin) {
        require(_admin != address(0), "!_admin");

        // Add _admin as admin
        _setupRole(ADMIN_ROLE, _admin);
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /// @dev A modifier which checks that the caller has the admin role.
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "!admin");
        _;
    }

    /**
     * @notice Returns the standard deviation of the base currency in 10**8 i.e. 1*10**8 = 100%
     * @return standardDeviation is the standard deviation of the asset
     */
    function vol(bytes32) public pure returns (uint256 standardDeviation) {
        return 0;
    }

    /**
     * @notice Returns the annualized standard deviation of the base currency in 10**8 i.e. 1*10**8 = 100%
     * @param optionId is the encoded id for the option struct
     * @return annualStdev is the annualized standard deviation of the asset
     */
    function annualizedVol(bytes32 optionId) public view returns (uint256 annualStdev) {
        return annualizedVols[optionId];
    }

    /**
     * @notice Returns the annualized standard deviation of the base currency in 10**8 i.e. 1*10**8 = 100%
     * @param delta is the option's delta, in units of 10**8. E.g. 105% = 1.05 * 10**8
     * @param underlying is the underlying of the option
     * @param collateralAsset is the collateral used to collateralize the option
     * @param isPut is the flag used to determine if an option is a put or call
     * @return annualStdev is the annualized standard deviation of the asset
     */
    function annualizedVol(
        uint256 delta,
        address underlying,
        address collateralAsset,
        bool isPut
    ) public view returns (uint256 annualStdev) {
        return annualizedVols[getOptionId(delta, underlying, collateralAsset, isPut)];
    }

    /**
     * @notice Computes the option id for a given Option struct
     * @param delta is the option's delta, in units of 10**4. E.g. 0.1d = 0.1 * 10**4
     * @param underlying is the underlying of the option
     * @param collateralAsset is the collateral used to collateralize the option
     * @param isPut is the flag used to determine if an option is a put or call
     */
    function getOptionId(
        uint256 delta,
        address underlying,
        address collateralAsset,
        bool isPut
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(delta, underlying, collateralAsset, isPut));
    }

    /**
     * @notice Sets the annualized standard deviation of the base currency of one or more `pool(s)`
     * @param optionIds is an array of Option IDs encoded and hashed with optionId
     * @param newAnnualizedVols is an array of the annualized volatility with 10**8 decimals i.e. 1*10**8 = 100%
     */
    function setAnnualizedVol(bytes32[] calldata optionIds, uint256[] calldata newAnnualizedVols) external onlyAdmin {
        require(optionIds.length == newAnnualizedVols.length, "Input lengths mismatched");

        for (uint256 i = 0; i < optionIds.length; i++) {
            bytes32 optionId = optionIds[i];
            uint256 newAnnualizedVol = newAnnualizedVols[i];

            require(newAnnualizedVol > 20 * 10**6, "Cannot be less than 20%");
            require(newAnnualizedVol < 400 * 10**6, "Cannot be more than 400%");

            annualizedVols[optionId] = newAnnualizedVol;
        }
    }
}
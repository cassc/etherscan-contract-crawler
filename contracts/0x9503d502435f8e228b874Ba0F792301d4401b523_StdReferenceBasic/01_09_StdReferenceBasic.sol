// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import {StdReferenceBase} from "StdReferenceBase.sol";
import {AccessControl} from "AccessControl.sol";

/// @title BandChain StdReferenceBasic
/// @author Band Protocol Team
contract StdReferenceBasic is AccessControl, StdReferenceBase {
    struct RefData {
        uint64 rate; // USD-rate, multiplied by 1e9.
        uint64 resolveTime; // UNIX epoch when data is last resolved.
        uint64 requestID; // BandChain request identifier for this data.
    }

    /// Mapping from token symbol to ref data
    mapping(string => RefData) public refs;

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RELAYER_ROLE, msg.sender);
    }

    /**
     * @dev Grants `RELAYER_ROLE` to `accounts`.
     *
     * If each `account` had not been already granted `RELAYER_ROLE`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``RELAYER_ROLE``'s admin role.
     */
    function grantRelayers(address[] calldata accounts) external onlyRole(getRoleAdmin(RELAYER_ROLE)) {
        for (uint256 idx = 0; idx < accounts.length; idx++) {
            _grantRole(RELAYER_ROLE, accounts[idx]);
        }
    }

    /**
     * @dev Revokes `RELAYER_ROLE` from `accounts`.
     *
     * If each `account` had already granted `RELAYER_ROLE`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``RELAYER_ROLE``'s admin role.
     */
    function revokeRelayers(address[] calldata accounts) external onlyRole(getRoleAdmin(RELAYER_ROLE)) {
        for (uint256 idx = 0; idx < accounts.length; idx++) {
            _revokeRole(RELAYER_ROLE, accounts[idx]);
        }
    }

    /// @notice Relay and save a set of price data to the contract only if resolveTime is newer
    /// @dev All of the lists must be of equal length
    /// @param symbols A list of symbols whose data is being relayed in this function call
    /// @param rates A list of the rates associated with each symbol
    /// @param resolveTime A timestamp of when the rate data was retrieved
    /// @param requestID A BandChain request ID in which the rate data was retrieved
    function relay(
        string[] calldata symbols,
        uint64[] calldata rates,
        uint64 resolveTime,
        uint64 requestID
    ) external {
        require(hasRole(RELAYER_ROLE, msg.sender), "NOTARELAYER");
        require(rates.length == symbols.length, "BADRATESLENGTH");
        for (uint256 idx = 0; idx < symbols.length; idx++) {
            RefData storage ref = refs[symbols[idx]];
            if (resolveTime > ref.resolveTime) {
                refs[symbols[idx]] = RefData({rate: rates[idx], resolveTime: resolveTime, requestID: requestID});
            }
        }
    }

    /// @notice Relay and save a set of price data to the contract
    /// @dev All of the lists must be of equal length
    /// @param symbols A list of symbols whose data is being relayed in this function call
    /// @param rates A list of the rates associated with each symbol
    /// @param resolveTime A timestamp of when the rate data was retrieved
    /// @param requestID A BandChain request ID in which the rate data was retrieved
    function forceRelay(
        string[] calldata symbols,
        uint64[] calldata rates,
        uint64 resolveTime,
        uint64 requestID
    ) external {
        require(hasRole(RELAYER_ROLE, msg.sender), "NOTARELAYER");
        require(rates.length == symbols.length, "BADRATESLENGTH");
        for (uint256 idx = 0; idx < symbols.length; idx++) {
            refs[symbols[idx]] = RefData({rate: rates[idx], resolveTime: resolveTime, requestID: requestID});
        }
    }

    /// @notice Returns the price data for the given base/quote pair. Revert if not available.
    /// @param base the base symbol of the token pair to query
    /// @param quote the quote symbol of the token pair to query
    function getReferenceData(string memory base, string memory quote) public view override returns (ReferenceData memory) {
        (uint256 baseRate, uint256 baseLastUpdate) = _getRefData(base);
        (uint256 quoteRate, uint256 quoteLastUpdate) = _getRefData(quote);
        return ReferenceData({rate: (baseRate * 1e18) / quoteRate, lastUpdatedBase: baseLastUpdate, lastUpdatedQuote: quoteLastUpdate});
    }

    /// @notice Get the price data of a token
    /// @param symbol the symbol of the token whose price to query
    function _getRefData(string memory symbol) internal view returns (uint256 rate, uint256 lastUpdate) {
        if (keccak256(bytes(symbol)) == keccak256(bytes("USD"))) {
            return (1e9, block.timestamp);
        }
        RefData storage refData = refs[symbol];
        require(refData.resolveTime > 0, "REFDATANOTAVAILABLE");
        return (uint256(refData.rate), uint256(refData.resolveTime));
    }
}
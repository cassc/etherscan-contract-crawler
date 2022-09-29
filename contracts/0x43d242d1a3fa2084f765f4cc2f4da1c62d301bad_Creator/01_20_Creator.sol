// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.16;

import 'src/VaultTracker.sol';

import 'src/tokens/ZcToken.sol';

import 'src/interfaces/ICreator.sol';

contract Creator is ICreator {
    /// @dev A single custom error capable of indicating a wide range of detected errors by providing
    /// an error code value whose string representation is documented <here>, and any possible other values
    /// that are pertinent to the error.
    error Exception(uint8, uint256, uint256, address, address);

    address public admin;
    address public marketPlace;

    event SetAdmin(address indexed admin);

    constructor() {
        admin = msg.sender;
    }

    /// @notice Allows the owner to create new markets
    /// @param p Protocol associated with the new market
    /// @param u Underlying token associated with the new market
    /// @param m Maturity timestamp of the new market
    /// @param c Compounding Token address associated with the new market
    /// @param sw Address of the deployed swivel contract
    /// @param n Name of the new market zcToken
    /// @param s Symbol of the new market zcToken
    /// @param d Decimals of the new market zcToken
    function create(
        uint8 p,
        address u,
        uint256 m,
        address c,
        address sw,
        string calldata n,
        string calldata s,
        uint8 d
    ) external authorized(marketPlace) returns (address, address) {
        if (marketPlace == address(0)) {
            revert Exception(34, 0, 0, marketPlace, address(0));
        }

        address zct = address(new ZcToken(p, u, m, c, marketPlace, n, s, d));
        address tracker = address(new VaultTracker(p, m, c, sw, marketPlace));

        return (zct, tracker);
    }

    /// @param a Address of a new admin
    function setAdmin(address a) external authorized(admin) returns (bool) {
        admin = a;

        emit SetAdmin(a);

        return true;
    }

    /// @param m Address of the deployed marketPlace contract
    /// @notice We only allow this to be set once
    /// @dev there is no emit here as it's only done once post deploy by the deploying admin
    function setMarketPlace(address m)
        external
        authorized(admin)
        returns (bool)
    {
        if (marketPlace != address(0)) {
            revert Exception(33, 0, 0, marketPlace, address(0));
        }

        marketPlace = m;
        return true;
    }

    modifier authorized(address a) {
        if (msg.sender != a) {
            revert Exception(0, 0, 0, msg.sender, a);
        }
        _;
    }
}
// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondTeller} from "interfaces/IBondTeller.sol";

interface IBondFixedExpiryTeller is IBondTeller {
    /// @notice         Get the OlympusERC20BondToken contract corresponding to a market
    /// @param id_      ID of the market
    /// @return         ERC20BondToken contract address
    function getBondTokenForMarket(uint256 id_) external view returns (ERC20);

    /// @notice             Deploy a new ERC20 bond token for an (underlying, expiry) pair and return its address
    /// @dev                ERC20 used for fixed-expiry
    /// @dev                If a bond token exists for the (underlying, expiry) pair, it returns that address
    /// @param underlying_  ERC20 token redeemable when the bond token vests
    /// @param expiry_      Timestamp at which the bond token can be redeemed for the underlying token
    /// @return             Address of the ERC20 bond token being created
    function deploy(ERC20 underlying_, uint48 expiry_) external returns (ERC20);

    /// @notice              Deposit an ERC20 token and mint a future-dated ERC20 bond token
    /// @param underlying_   ERC20 token redeemable when the bond token vests
    /// @param expiry_       Timestamp at which the bond token can be redeemed for the underlying token
    /// @param amount_       Amount of underlying tokens to deposit
    /// @return              Address of the ERC20 bond token received
    /// @return              Amount of the ERC20 bond token received
    function create(
        ERC20 underlying_,
        uint48 expiry_,
        uint256 amount_
    ) external returns (ERC20, uint256);
}
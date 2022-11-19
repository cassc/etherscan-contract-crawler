// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondFixedTermTeller {
    // Info for bond token
    struct TokenMetadata {
        bool active;
        ERC20 underlying;
        uint8 decimals;
        uint48 expiry;
        uint256 supply;
    }

    /// @notice              Deposit an ERC20 token and mint a future-dated ERC1155 bond token
    /// @param underlying_   ERC20 token redeemable when the bond token vests
    /// @param expiry_       Timestamp at which the bond token can be redeemed for the underlying token
    /// @param amount_       Amount of underlying tokens to deposit
    /// @return              ID of the ERC1155 bond token received
    /// @return              Amount of the ERC1155 bond token received
    function create(
        ERC20 underlying_,
        uint48 expiry_,
        uint256 amount_
    ) external returns (uint256, uint256);

    /// @notice             "Deploy" a new ERC1155 bond token for an (underlying, expiry) pair and return its token ID
    /// @dev                ERC1155 used for fixed-term
    /// @dev                If a bond token exists for the (underlying, expiry) pair, it returns that token ID
    /// @param underlying_  ERC20 token redeemable when the bond token vests
    /// @param expiry_      Timestamp at which the bond token can be redeemed for the underlying token
    /// @return             ID of the ERC1155 bond token being created
    function deploy(ERC20 underlying_, uint48 expiry_) external returns (uint256);

    /// @notice          Redeem a fixed-term bond token for the underlying token (bond token must have matured)
    /// @param tokenId_  ID of the bond token to redeem
    /// @param amount_   Amount of bond token to redeem
    function redeem(uint256 tokenId_, uint256 amount_) external;

    /// @notice          Redeem multiple fixed-term bond tokens for the underlying tokens (bond tokens must have matured)
    /// @param tokenIds_ Array of bond token ids
    /// @param amounts_  Array of amounts of bond tokens to redeem
    function batchRedeem(uint256[] memory tokenIds_, uint256[] memory amounts_) external;

    /// @notice             Get token ID from token and expiry
    /// @param payoutToken_ Payout token of bond
    /// @param expiry_      Expiry of the bond
    /// @return             ID of the bond token
    function getTokenId(ERC20 payoutToken_, uint48 expiry_) external pure returns (uint256);

    /// @notice             Get the token name and symbol for a bond token
    /// @param tokenId_     ID of the bond token
    /// @return name        Bond token name
    /// @return symbol      Bond token symbol
    function getTokenNameAndSymbol(uint256 tokenId_)
        external
        view
        returns (string memory, string memory);
}
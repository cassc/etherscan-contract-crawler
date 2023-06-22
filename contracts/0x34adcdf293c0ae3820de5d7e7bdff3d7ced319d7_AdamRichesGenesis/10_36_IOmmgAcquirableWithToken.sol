// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../def/TokenDiscount.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgAcquirableWithToken
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves for the extended minting functionality of the Ommg Artist Contracts.
/// The general functionality is that special prices can be configured for users to mint if they hold other
/// NFTs. Each NFT can only be used once to receive this discount, unless specifically reset.
interface IOmmgAcquirableWithToken {
    error TokenNotOwned(IERC721 token, uint256 tokenIds);
    error TokenAlreadyUsed(IERC721 token, uint256 tokenId);
    error TokenNotConfigured(IERC721 token);
    error TokenNotActive(IERC721 token);
    error TokenAlreadyConfigured(IERC721 token);
    error TokenSupplyExceeded(IERC721 token, uint256 supplyCap);

    /// @notice Triggers when a token discount is added.
    /// @param tokenAddress the addres of the added NFT contract for discounts
    /// @param config a tuple [uint256 price, uint256 limit, bool active] that represents the configuration for
    /// the discount
    event TokenDiscountAdded(
        IERC721 indexed tokenAddress,
        TokenDiscountConfig config
    );
    /// @notice Triggers when a token discount is updated.
    /// @param tokenAddress the addres of the added NFT contract for discounts
    /// @param config a tuple [uint256 price, uint256 limit, bool active] that represents the new configuration for
    /// the discount
    event TokenDiscountUpdated(
        IERC721 indexed tokenAddress,
        TokenDiscountConfig config
    );
    /// @notice Triggers when a token discount is removed.
    /// @param tokenAddress the addres of the NFT contract
    event TokenDiscountRemoved(IERC721 indexed tokenAddress);
    /// @notice Triggers when a token discount is reset - meaning all token usage data is reset and all tokens
    /// are marked as unused again.
    /// @param tokenAddress the addres of the NFT contract
    event TokenDiscountReset(IERC721 indexed tokenAddress);
    /// @notice Triggers when a token discount is used for a discount and then marked as used
    /// @param sender the user who used the token
    /// @param tokenAddress the addres of the NFT contract
    /// @param tokenId the id of the NFT used for the discount
    event TokenUsedForDiscount(
        address indexed sender,
        IERC721 indexed tokenAddress,
        uint256 indexed tokenId
    );

    /// @notice Adds an NFT contract and thus all of it's tokens to the discount list.
    /// Emits a {TokenDiscountAdded} event and fails if `tokenAddress` is the zero address
    /// or is already configured.
    /// @param tokenAddress the address of the NFT contract
    /// @param config the initial configuration as [uint256 price, uint256 limit, bool active]
    function addTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountConfig memory config
    ) external;

    /// @notice Removes an NFT contract from the discount list.
    /// Emits a {TokenDiscountRemoved} event and fails if `tokenAddress` is the zero address
    /// or is not already configured.
    /// @param tokenAddress the address of the NFT contract
    function removeTokenDiscount(IERC721 tokenAddress) external;

    /// @notice Updates an NFT contracts configuration of the discount.
    /// Emits a {TokenDiscountUpdated} event and fails if `tokenAddress` is the zero address
    /// or is not already configured.
    /// @param tokenAddress the address of the NFT contract
    /// @param config the new configuration as [uint256 price, uint256 limit, bool active]
    function updateTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountConfig memory config
    ) external;

    /// @notice Resets the usage state of all NFTs of the contract at `tokenAddress`. This allows all token ids
    /// to be used again.
    /// Emits a {TokenDiscountReset} event and fails if `tokenAddress` is the zero address
    /// or is not already configured.
    /// @param tokenAddress the address of the NFT contract
    function resetTokenDiscountUsed(IERC721 tokenAddress) external;

    /// @notice Returns the current configuration of the token discount of `tokenAddress`
    /// @return config the configuration as [uint256 price, uint256 limit, bool active]
    function tokenDiscountInfo(IERC721 tokenAddress)
        external
        view
        returns (TokenDiscountOutput memory config);

    /// @notice Returns a list of all current tokens configured for discounts and their configurations.
    /// @return discounts the configuration as [IERC721 tokenAddress, [uint256 price, uint256 limit, bool active]]
    function tokenDiscounts()
        external
        view
        returns (TokenDiscountOutput[] memory discounts);

    /// @notice Acquires an NFT of this contract by proving ownership of the tokens in `tokenIds` belonging to
    /// a contract `tokenAddress` that has a configured discount. This way cheaper prices can be achieved for OMMG holders
    /// and potentially other partners. Emits {TokenUsedForDiscount} and requires the user to send the correct amount of
    /// eth as well as to own the tokens within `tokenIds` from `tokenAddress`, and for `tokenAddress` to be a configured token for discounts.
    /// @param tokenAddress the address of the contract which is the reference for `tokenIds`
    /// @param tokenIds the token ids which are to be used to get the discount
    function acquireWithToken(IERC721 tokenAddress, uint256[] memory tokenIds)
        external
        payable;

    /// @notice Sets the active status of the token discount of `tokenAddress`.
    /// Fails if `tokenAddress` is the zero address or is not already configured.
    /// @param tokenAddress the configured token address
    /// @param active the new desired activity state
    function setTokenDiscountActive(IERC721 tokenAddress, bool active)
        external;

    /// @notice Returns whether the tokens `tokenIds` of `tokenAddress` have already been used for a discount.
    /// Fails if `tokenAddress` is the zero address or is not already configured.
    /// @param tokenAddress the address of the token contract
    /// @param tokenIds the ids to check
    /// @return used if the tokens have already been used, each index corresponding to the
    /// token id index in the array
    function tokensUsedForDiscount(
        IERC721 tokenAddress,
        uint256[] memory tokenIds
    ) external view returns (bool[] memory used);
}
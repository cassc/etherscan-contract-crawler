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

/// @title IOmmgFrontEnd
/// @author NotAMeme aka nxlogixnick
/// @notice This interface is for the minting front end
interface IOmmgFrontEnd {
    /// @notice Returns a list of all current tokens configured for discounts and their configurations.
    /// @return discounts the configuration as [IERC721 tokenAddress, [uint256 price, uint256 limit, bool active]]
    function tokenDiscounts()
        external
        view
        returns (TokenDiscountOutput[] memory discounts);

    /// @notice Returns the maximum number of tokens mintable in one transaction
    /// @return maxBatch the maximum amount
    function maxBatchSize() external view returns (uint256 maxBatch);

    /// @notice Acquires an NFT of this contract by proving ownership of the tokens in `tokenIds` belonging to
    /// a contract `tokenAddress` that has a configured discount. This way cheaper prices can be achieved for OMMG holders
    /// and potentially other partners. Emits {TokenUsedForDiscount} and requires the user to send the correct amount of
    /// eth as well as to own the tokens within `tokenIds` from `tokenAddress`, and for `tokenAddress` to be a configured token for discounts.
    /// @param tokenAddress the address of the contract which is the reference for `tokenIds`
    /// @param tokenIds the token ids which are to be used to get the discount
    function acquireWithToken(IERC721 tokenAddress, uint256[] memory tokenIds)
        external
        payable;

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

    /// @notice Mints `amount` NFTs of this contract. The more minted at once, the cheaper gas is for each token.
    /// However, the upper limit for `amount` can be queried via `maxBatchSize`. Fails if the user does not provide
    /// the correct amount of eth, if sale is paused, if the supply catch is reached, or if `maxBatchSize` is exceeded.
    /// @param amount the amount of NFTs to mint.
    function acquire(uint256 amount) external payable;

    /// @notice this returns the supply cap of the token
    /// @return supplyCap the supply cap of the token
    function supplyCap() external view returns (uint256 supplyCap);

    /// @notice Returns the current price.
    /// @return price the current price
    function price() external view returns (uint256 price);

    /// @notice This function returns a boolean value indicating whether
    /// the public sale is currently active or not
    /// returns currentState whether the sale is active or not
    function saleIsActive() external view returns (bool currentState);

    /// @notice This function returns the total amount of tokens still available
    /// of the total supply
    function tokensAvailable() external view returns (uint256 amount);

    // docs are in IERC721Metadata
    function name() external view returns (string memory name);

    // docs are in IERC721Metadata
    function symbol() external view returns (string memory name);
}
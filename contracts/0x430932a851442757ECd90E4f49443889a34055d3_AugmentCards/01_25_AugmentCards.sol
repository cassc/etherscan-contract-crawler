// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../nfts/ERC1155Invoke.sol";

/**
 * @title Card Augmenting Contract
 * @notice This contract accepts Parallel Alpha card(s) and gives the augmented version of the card(s).
 * The augmenting of a cards requires PRIME as payment.
 * @dev The Parallel Alpha card is burned and Augmented Parallel Alpha card is minted with the same token id.
 */
contract AugmentCards is Ownable, ERC1155Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Parallel Alpha Contract
    ERC1155Burnable public parallelAlpha =
        ERC1155Burnable(0x76BE3b62873462d2142405439777e971754E8E77);

    /// @notice PRIME Contract
    IERC20 public prime = IERC20(0xb23d80f5FefcDDaa212212F028021B41DEd428CF);

    /// @notice Indicated if augmenting is disabled
    bool public isDisabled;

    /// @notice Address that will receive the remaining PRIME payment after artistFeeReceiver
    address public feeReceiver;

    /// @notice Address that will receive a percentage of the PRIME payment
    address public artistFeeReceiver;

    /// @notice Percent to distribute the fee
    uint256 public artistFeePercent = 1100;

    /// @notice Precision  point for fee calculation
    uint256 constant PRECISION = 10000;

    /// @notice Mapping of token id to max supply
    mapping(address => mapping(uint256 => uint256)) public maxSupply;

    /// @notice Mapping of token id to current supply
    mapping(address => mapping(uint256 => uint256)) public totalSupply;

    /// @notice Mapping of token id to token uri
    mapping(address => mapping(uint256 => string)) public tokenUri;

    /// @notice Mapping of token id to price
    mapping(address => mapping(uint256 => uint256)) public price;

    error ZeroAddress();
    error ParamLengthMissMatch();
    error UriUpdateAfterMint();
    error NewSupplyBelowCurrentSupply();
    error MaxSupplyReached();
    error CalledByNonParallelAlpha();
    error Disabled();

    event CardsAugmented(
        address indexed tokenAddress,
        address indexed from,
        uint256 primePaid,
        uint256[] tokenIds,
        uint256[] quantities
    );
    event SetParallelAlpha(address indexed parallelAlphaAddress);
    event SetPrime(address indexed primeAddress);
    event SetFeeReceiver(address indexed feeReceiver);
    event SetArtistFeeReceiver(address indexed artistFeeReceiver);
    event SetIsDisabled(bool isDisabled);
    event SetArtistFeePercent(uint256 artistFeePercent);

    /**
     * @param parallelAlphaAddress Parallel Alpha contract address
     * @param tokenAddress Address of token to configure
     * @param primeAddress PRIME contract address
     * @param feeReceiverAddress Address of the receiver of PRIME payments
     * @param artistFeeReceiverAddress Artist address of the receiver of PRIME payments
     * @param tokenIds List of token ids to configure
     * @param supply List of max supply corresponding to token ids
     * @param tokenUris List of uris corresponding to token ids
     * @param prices List of prices in PRIME corresponding to token id
     */
    constructor(
        address parallelAlphaAddress,
        address tokenAddress,
        address primeAddress,
        address feeReceiverAddress,
        address artistFeeReceiverAddress,
        uint256[] memory tokenIds,
        uint256[] memory supply,
        string[] memory tokenUris,
        uint256[] memory prices
    ) {
        parallelAlpha = ERC1155Burnable(parallelAlphaAddress);
        prime = IERC20(primeAddress);
        feeReceiver = feeReceiverAddress;
        artistFeeReceiver = artistFeeReceiverAddress;

        if (
            parallelAlphaAddress == address(0) ||
            tokenAddress == address(0) ||
            primeAddress == address(0) ||
            feeReceiverAddress == address(0) ||
            artistFeeReceiverAddress == address(0)
        ) revert ZeroAddress();

        if (
            tokenIds.length != supply.length ||
            tokenIds.length != tokenUris.length ||
            tokenIds.length != prices.length
        ) revert ParamLengthMissMatch();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            maxSupply[tokenAddress][tokenIds[i]] = supply[i];
            tokenUri[tokenAddress][tokenIds[i]] = tokenUris[i];
            price[tokenAddress][tokenIds[i]] = prices[i];
        }
    }

    /**
     * @notice Updates the Parallel Alpha contract address
     * @dev Only callable by admin
     * @param parallelAlphaAddress New Parallel Alpha address to set
     */
    function setParallelAlpha(address parallelAlphaAddress) external onlyOwner {
        parallelAlpha = ERC1155Burnable(parallelAlphaAddress);
        emit SetParallelAlpha(parallelAlphaAddress);
    }

    /**
     * @notice Updates the PRIME contract address
     * @dev Only callable by admin
     * @param primeAddress New PRIME address to set
     */
    function setPrime(address primeAddress) external onlyOwner {
        prime = IERC20(primeAddress);
        emit SetPrime(primeAddress);
    }

    /**
     * @notice Updates fee recipients address
     * @dev Only callable by admin
     * @param newFeeReceiver New fee recipient address to set
     */
    function setFeeReceiver(address newFeeReceiver) external onlyOwner {
        feeReceiver = newFeeReceiver;
        emit SetFeeReceiver(newFeeReceiver);
    }

    /**
     * @notice Updates disabled flag
     * @dev Only callable by admin
     * @param newArtistFeeReceiver New artist fee recipient address to set
     */
    function setArtistFeeReceiver(address newArtistFeeReceiver)
        external
        onlyOwner
    {
        artistFeeReceiver = newArtistFeeReceiver;
        emit SetArtistFeeReceiver(newArtistFeeReceiver);
    }

    /**
     * @notice Updates disabled flag
     * @dev Only callable by admin
     * @param disabled New disabled value
     */
    function setIsDisabled(bool disabled) external onlyOwner {
        isDisabled = disabled;
        emit SetIsDisabled(disabled);
    }

    /**
     * @notice Updates disabled flag
     * @dev Only callable by admin
     * @param newArtistFeePercent  new artist fee percent for the artist fee receiver
     */
    function setArtistFeePercent(uint256 newArtistFeePercent)
        external
        onlyOwner
    {
        artistFeePercent = newArtistFeePercent;
        emit SetArtistFeePercent(artistFeePercent);
    }

    /**
     * @notice Sets max supply and token uri for list of token ids
     * @dev Only callable by admin and will revert if new max supply is less than current supply
     * @param tokenAddress Address of token to configure
     * @param tokenIds List of token ids to configure
     * @param supply List of max supply corresponding to token ids
     * @param tokenUris List of uris corresponding to token ids
     * @param prices List of prices in PRIME corresponding to token id
     */
    function setTokenIdsSupply(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata supply,
        string[] memory tokenUris,
        uint256[] memory prices
    ) external onlyOwner {
        if (
            tokenIds.length != supply.length ||
            tokenIds.length != tokenUris.length ||
            tokenIds.length != prices.length
        ) revert ParamLengthMissMatch();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (totalSupply[tokenAddress][tokenIds[i]] > supply[i])
                revert NewSupplyBelowCurrentSupply();

            if (
                maxSupply[tokenAddress][tokenIds[i]] != 0 &&
                keccak256(bytes(tokenUri[tokenAddress][tokenIds[i]])) !=
                keccak256(bytes(tokenUris[i]))
            ) revert UriUpdateAfterMint();

            maxSupply[tokenAddress][tokenIds[i]] = supply[i];
            tokenUri[tokenAddress][tokenIds[i]] = tokenUris[i];
            price[tokenAddress][tokenIds[i]] = prices[i];
        }
    }

    /// @notice Disable renounceOwnership. Only callable by owner.
    function renounceOwnership() public virtual override onlyOwner {
        revert("Ownership cannot be renounced");
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Artist data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        uint256[] memory _tokenIds = new uint256[](1);
        uint256[] memory _quantities = new uint256[](1);
        _tokenIds[0] = id;
        _quantities[0] = value;

        address tokenAddress = abi.decode(data, (address));

        _signCards(tokenAddress, from, _tokenIds, _quantities);

        return this.onERC1155Received.selector;
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Artist data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public override returns (bytes4) {
        address tokenAddress = abi.decode(data, (address));

        _signCards(tokenAddress, from, ids, values);

        return this.onERC1155BatchReceived.selector;
    }

    /**
     * Helper method that burns the Parallel Alpha cards and mints Augmented Parallel Alpha cards
     * @param _tokenAddress Address of token to configure
     * @param _from The address of augmented cards recipient
     * @param _tokenIds List of token ids to burn/mint
     * @param _quantities List of quantities of each token id
     */
    function _signCards(
        address _tokenAddress,
        address _from,
        uint256[] memory _tokenIds,
        uint256[] memory _quantities
    ) internal nonReentrant {
        if (msg.sender != address(parallelAlpha))
            revert CalledByNonParallelAlpha();

        if (isDisabled) revert Disabled();

        uint256 totalPrice;
        string[] memory _tokenUri = new string[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (
                maxSupply[_tokenAddress][_tokenIds[i]] <
                totalSupply[_tokenAddress][_tokenIds[i]] + _quantities[i]
            ) revert MaxSupplyReached();

            totalPrice += _quantities[i] * price[_tokenAddress][_tokenIds[i]];
            totalSupply[_tokenAddress][_tokenIds[i]] += _quantities[i];
            parallelAlpha.burn(address(this), _tokenIds[i], _quantities[i]);
            _tokenUri[i] = tokenUri[_tokenAddress][_tokenIds[i]];
        }

        ERC1155Invoke(_tokenAddress).mintBatch(
            _from,
            _tokenIds,
            _quantities,
            _tokenUri,
            ""
        );

        uint256 artistFeeAmount = (totalPrice * artistFeePercent) / PRECISION;
        prime.safeTransferFrom(_from, artistFeeReceiver, artistFeeAmount);
        prime.safeTransferFrom(
            _from,
            feeReceiver,
            totalPrice - artistFeeAmount
        );

        emit CardsAugmented(
            _tokenAddress,
            _from,
            totalPrice,
            _tokenIds,
            _quantities
        );
    }
}
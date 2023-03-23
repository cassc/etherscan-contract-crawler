// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

struct WrappedTokenERC721Params {
    string name;
    string symbol;
}

interface IERC721PortalFacet {
    /// @notice An even emitted once a MintERC721 transaction is executed
    event MintERC721(
        uint256 sourceChain,
        bytes transactionId,
        address token,
        uint256 tokenId,
        string metadata,
        address receiver
    );

    /// @notice An event emitted once a BurnERC721 transaction is executed
    event BurnERC721(
        uint256 targetChain,
        address wrappedToken,
        uint256 tokenId,
        bytes receiver,
        address paymentToken,
        uint256 fee
    );

    /// @notice An event emitted once an ERC-721 payment token and fee is modified
    event SetERC721Payment(address erc721, address payment, uint256 fee);

    /// @notice Mints wrapped `_tokenId` to the `receiver` address.
    ///         Must be authorised by the configured supermajority threshold of `signatures` from the `members` set.
    /// @param _sourceChain ID of the source chain
    /// @param _transactionId The source transaction ID + log index
    /// @param _wrappedToken The address of the wrapped ERC-721 token on the current chain
    /// @param _tokenId The target token ID
    /// @param _metadata The tokenID's metadata, used to be queried as ERC-721.tokenURI
    /// @param _receiver The address of the receiver on this chain
    /// @param _signatures The array of signatures from the members, authorising the operation
    function mintERC721(
        uint256 _sourceChain,
        bytes memory _transactionId,
        address _wrappedToken,
        uint256 _tokenId,
        string memory _metadata,
        address _receiver,
        bytes[] calldata _signatures
    ) external;

    /// @notice Burns `_tokenId` of `wrappedToken` and initializes a portal transaction to the target chain
    ///         The wrappedToken's fee payment is transferred to the contract upon execution.
    /// @param _targetChain The target chain to which the wrapped asset will be transferred
    /// @param _wrappedToken The address of the wrapped token
    /// @param _tokenId The tokenID of `wrappedToken` to burn
    /// @param _paymentToken The current payment token
    /// @param _fee The fee amount for the wrapped token's payment token
    /// @param _receiver The address of the receiver on the target chain
    function burnERC721(
        uint256 _targetChain,
        address _wrappedToken,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _fee,
        bytes memory _receiver
    ) external;

    /// @notice Sets ERC-721 contract payment token and fee amount
    /// @param _erc721 The target ERC-721 contract
    /// @param _payment The target payment token
    /// @param _fee The fee required upon every portal transfer
    function setERC721Payment(
        address _erc721,
        address _payment,
        uint256 _fee
    ) external;

    /// @notice Returns the payment token for an ERC-721
    /// @param _erc721 The address of the ERC-721 Token
    function erc721Payment(address _erc721) external view returns (address);

    /// @notice Returns the payment fee for an ERC-721
    /// @param _erc721 The address of the ERC-721 Token
    function erc721Fee(address _erc721) external view returns (uint256);
}
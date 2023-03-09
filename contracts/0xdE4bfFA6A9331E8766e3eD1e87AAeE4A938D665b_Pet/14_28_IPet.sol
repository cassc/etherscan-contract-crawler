// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPet {
    /// @notice Emitted when the new base URI is set
    /// @param who Admin that set the base URI
    event BaseURISet(address indexed who);

    /// @notice Emitted when the token ID is set to clone flag
    /// @param tokenId Token ID
    /// @param clone Clone flag
    /// @param who Admin that set the clone flag
    event CloneSet(uint256 tokenId, bool clone, address indexed who);

    /// @notice Emitted when the account is set to custodial status
    /// @param account Account to be set
    /// @param status Custodial status
    /// @param who Admin that set the clone flag
    event CustodialSet(address account, bool status, address indexed who);

    /// @notice Emitted when setRoyaltyInfo is called
    /// @param royaltyReceiver Account to receive sale royalties
    /// @param royaltyNumerator Fraction relative to ROYALTY_DENOMINATOR
    event RoyaltyInfoSet(address royaltyReceiver, uint256 royaltyNumerator);

    /// @notice Emitted when a new Immutable X is set
    /// @param who Admin that set the Immutable X
    /// @param imx New Immutable X address
    event IMXSet(address indexed who, address indexed imx);

    /// @notice Sets a base URI
    /// @param _uri Base URI
    function setBaseURI(string calldata _uri) external;

    /// @notice Set clone flag for a specific token
    /// @param _tokenId Token ID
    /// @param _clone Clone status
    function setClone(uint256 _tokenId, bool _clone) external;

    /// @notice Check if the token is cloned
    /// @param _tokenId Token ID
    /// @return clone_ Cloned falg
    function isClone(uint256 _tokenId) external view returns (bool);

    /// @notice Set a custodial
    /// @param _account Custodial account
    /// @param _status Account status
    function setCustodial(address _account, bool _status) external;

    /// @notice Check if the account is cusotodial
    /// @param _account Account to be checked
    /// @return status_ Account status
    function isCustodial(address _account) external view returns (bool);

    /// @notice Mints a signle pet to a specific address
    /// @param _to Receiver address
    /// @param _tokenId Token ID
    /// @param _custodial Custodial flag
    /// @param _clone Clone flag
    function mintTo(
        address _to,
        uint256 _tokenId,
        bool _custodial,
        bool _clone
    ) external;

    /// @notice Mints multiple pets to a list of addresses
    /// @param _tos List of receiver addresses
    /// @param _tokenIds Token IDs
    /// @param _custodial Custodial flag
    /// @param _clone Clone flag
    function multiMintTo(
        address[] memory _tos,
        uint256[] memory _tokenIds,
        bool _custodial,
        bool _clone
    ) external;

    /// @notice Mints a single pet to this contract
    /// @param _tokenId Token ID
    function mintToContract(uint256 _tokenId) external;

    /// @notice Mints multiple pets to this contract
    /// @param _tokenIds Token IDs
    function multiMintToContract(uint256[] memory _tokenIds) external;

    /// @notice Transfers multiple pets at once
    /// @param _froms Token owners
    /// @param _tos Token receivers
    /// @param _tokenIds Token IDs
    function bulkTransferFrom(
        address[] memory _froms,
        address[] memory _tos,
        uint256[] memory _tokenIds
    ) external;

    /// @notice Transfers multiple pets from custodials at once
    /// @param _froms Token owners
    /// @param _tos Token receivers
    /// @param _tokenIds Token IDs
    /// @param _custodials Token IDs
    function bulkTransferFromCustodials(
        address[] memory _froms,
        address[] memory _tos,
        uint256[] memory _tokenIds,
        bool[] memory _custodials
    ) external;

    /// @notice Set the royalty info for all tokens
    /// @param _royaltyReceiver Account to receive sale royalties
    /// @param _royaltyNumerator Fraction relative to ROYALTY_DENOMINATOR (which is <= 10000)
    function setRoyaltyInfo(address _royaltyReceiver, uint96 _royaltyNumerator) external;

    /// @notice Sets the Immutable X address
    /// @param _imx New Immutable X
    function setIMX(address _imx) external;
}
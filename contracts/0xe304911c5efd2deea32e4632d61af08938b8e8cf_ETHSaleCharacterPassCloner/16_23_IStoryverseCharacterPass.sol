// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStoryverseCharacterPass {
    struct Token {
        address tokenAddress;
    }

    struct TokenSupply {
        address tokenAddress;
        uint256 supply;
    }

    /// @notice Emitted when the base URI for tokens is set
    /// @param baseURI Base URI
    event SetBaseURI(string baseURI);

    /// @notice Emitted when the supply of pases for a token contract is set
    /// @param tokenAddress Address of the token contract
    /// @param supply Supply
    event SetSupply(address tokenAddress, uint256 supply);

    /// @notice Emitted when setRoyaltyInfo is called
    /// @param royaltyReceiver Account to receive sale royalties
    /// @param royaltyNumerator Fraction relative to ROYALTY_DENOMINATOR
    event SetRoyaltyInfo(address royaltyReceiver, uint256 royaltyNumerator);

    /// @notice Emitted when a pass is minted for an external token
    /// @param to Account minted to
    /// @param passId Pass id
    /// @param tokenAddress Token address
    event Mint(address to, uint256 passId, address tokenAddress);

    function initialize(
        address _adminAccount,
        address _imx,
        string calldata baseURI_,
        string calldata name_,
        string calldata symbol_,
        TokenSupply[] calldata _tokenSupplies
    ) external;

    function getImx() external view returns (address);

    function setBaseURI(string calldata baseURI_) external;

    function getSupply(address _tokenAddress) external view returns (uint256);

    function setTokenSupplies(TokenSupply[] calldata _tokenSupplies) external;

    function getMintedSupply(address _tokenAddress) external view returns (uint256);

    function getToken(uint256 _passId) external view returns (address);

    function mint(
        address _tokenAddress,
        address _to,
        uint256 _quantity
    ) external;

    function setRoyaltyInfo(address _royaltyReceiver, uint256 _royaltyNumerator) external;

    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256);
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// @title Pixelmon Evolution 3 Serum Contract
/// @author LiquidX
/// @notice This smart contract is for Evolution 3 Serum collection

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/// @notice Thrown when invalid destination address specified address(0)
error InvalidAddress();

/// @notice Thrown when given input does not meet with requirements of the expected one
error InvalidInput();

/// @notice Thrown when address is not included in Minter list
error InvalidMinter();

/// @notice Thrown when address is not included in Burner list
error InvalidBurner();

/// @notice Thrown when token ID is not match with the existing one
error InvalidTokenId();

/// @notice Thrown when input is equal to zero
error ValueCanNotBeZero();

/// @notice Thrown when token supply already reaches its maximum limit
error MintAmountForTokenIDExceeded();

/// @notice Strings library will be used to convert uint256 to string
using Strings for uint256;

/// @notice Pixelmon Evolution 3 Serum Smart Contract
/// @dev This is an ERC1155 token token standard smart contract
/// @dev Using Ownable modifiers for configuration methods
contract Evolution3Serum is ERC1155, Ownable, ERC2981, DefaultOperatorFilterer {
    /// @notice Data structure for holding each type token information
    /// @param maximumTokenSupply Maximum amount of a token Id allowed to mint
    /// @param totalMintedTokenAmount Minted amount of a token Id
    /// @param tokenId token Id value
    struct TokenInfo {
        uint256 maximumTokenSupply;
        uint256 totalMintedTokenAmount;
        uint256 tokenId;
    }

    /// @notice List of address that can mint the token
    /// @dev Use this mapping to set permission on who can mint the token
    /// @custom:key A valid ethereum address
    /// @custom:value Set permission in boolean. 'true' means allowed
    mapping(address => bool) public minterList;

    /// @notice List of address that can burn the token
    /// @dev Use this mapping to set permission on who can burn the token
    /// @custom:key A valid ethereum address
    /// @custom:value Set permission in boolean. 'true' means allowed
    mapping(address => bool) public burnerList;

    /// @notice List of ERC1155 token types of this smart contract
    /// @dev Use this mapping to store token information
    /// @custom:key tokenId
    /// @custom:value Token information with TokenInfo structure
    mapping(uint256 => TokenInfo) public tokenCollections;

    /// @notice Total of token ID
    uint256 public totalToken = 0;

    /// @notice Base URL to store off-chain metadata information
    /// @dev This variable could be used to store URL for the token metadata
    string public baseURI = "";

    /// @notice Check whether address is valid
    /// @param _address Any valid ethereum address
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert InvalidAddress();
        }
        _;
    }

    /// @notice Check whether token ID exists
    /// @param _tokenId token ID
    modifier validTokenId(uint256 _tokenId) {
        if (_tokenId < 1 || _tokenId > totalToken) {
            revert InvalidTokenId();
        }
        _;
    }

    /// @notice Check whether amount not zero
    /// @param _amount token amount
    modifier validAmount(uint256 _amount) {
        if (_amount == 0) {
            revert ValueCanNotBeZero();
        }
        _;
    }

    /// @notice There's a mint transaction happen
    /// @dev Emit event when calling mint function
    /// @param minter Address who calls the function
    /// @param receiver Address who receives the token
    /// @param tokenId Item token ID
    /// @param amount Amount of item that is minted
    event E3SerumMint(address minter, address receiver, uint256 tokenId, uint256 amount);

    /// @notice There's a burn transaction happen
    /// @dev Emit event when calling burn function
    /// @param walletAddress Address of the token holder
    /// @param tokenId Token to burnt
    /// @param amount Amount of token to burn
    event E3SerumBurn(address walletAddress, uint256 tokenId, uint256 amount);

    /// @dev Token Name
    string public constant name = "E3 Serum";
    /// @dev Token symbol
    string public constant symbol = "E3S";

    /// @notice Sets token ID, token name, maximum supply and token type for all tokens
    /// @dev The ERC1155 function is derived from Open Zeppelin ERC1155 library
    /// @param _baseURI Metadata server base URI
    constructor(string memory _baseURI) ERC1155("") {
        baseURI = _baseURI;
        addTokenInfo(1000);
    }

    /// @notice Sets information about specific token
    /// @dev It will set token ID and maximum supply
    /// @param _maximumSupply The maximum supply for the token
    function addTokenInfo(uint256 _maximumSupply) public onlyOwner {
        unchecked {
            totalToken++;
        }
        tokenCollections[totalToken] = TokenInfo({maximumTokenSupply: _maximumSupply, totalMintedTokenAmount: 0, tokenId: totalToken});
    }

    /// @notice Update token maximum supply
    /// @dev This function can only be executed by the contract owner
    /// @param _tokenId Token ID
    /// @param _maximumTokenSupply Token new maximum supply
    function updateTokenSupply(uint256 _tokenId, uint256 _maximumTokenSupply) external onlyOwner validTokenId(_tokenId) {
        if (tokenCollections[_tokenId].totalMintedTokenAmount > _maximumTokenSupply) {
            revert InvalidInput();
        }
        tokenCollections[_tokenId].maximumTokenSupply = _maximumTokenSupply;
    }

    /// @notice Registers an address and sets a permission to mint
    /// @dev This function can only be executed by the contract owner
    /// @param _minter A valid ethereum address
    /// @param _flag The permission to mint. 'true' means allowed
    function setMinterAddress(address _minter, bool _flag) external onlyOwner validAddress(_minter) {
        minterList[_minter] = _flag;
    }

    /// @notice Registers an address and sets a permission to burn
    /// @dev This function can only be executed by the contract owner
    /// @param _burner A valid ethereum address
    /// @param _flag The permission to burn. 'true' means allowed
    function setBurnerAddress(address _burner, bool _flag) external onlyOwner validAddress(_burner) {
        burnerList[_burner] = _flag;
    }

    /// @notice Mint token
    /// @dev Only allowed minter address that could run this function
    /// @param _receiver The address that will receive the token
    /// @param _tokenId The token ID that will be minted
    /// @param _amount Amount of token that will be minted
    function mint(address _receiver, uint256 _tokenId, uint256 _amount) external validAddress(_receiver) validTokenId(_tokenId) validAmount(_amount) {
        if (!minterList[msg.sender]) {
            revert InvalidMinter();
        }

        if (tokenCollections[_tokenId].totalMintedTokenAmount + _amount > tokenCollections[_tokenId].maximumTokenSupply) {
            revert MintAmountForTokenIDExceeded();
        }

        unchecked {
            tokenCollections[_tokenId].totalMintedTokenAmount += _amount;
        }

        _mint(_receiver, _tokenId, _amount, "");

        emit E3SerumMint(msg.sender, _receiver, _tokenId, _amount);
    }

    /// @notice Set base URL for storing off-chain information
    /// @param newuri A valid URL
    function setURI(string memory newuri) external onlyOwner {
        baseURI = newuri;
    }

    /// @notice Appends token ID to base URL
    /// @param _tokenId The token ID
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    }

    /// @notice Get information from specific token ID
    /// @param _tokenId Token ID
    function getTokenInfo(uint256 _tokenId) external view validTokenId(_tokenId) returns (TokenInfo memory tokenInfo) {
        tokenInfo = tokenCollections[_tokenId];
    }

    /// @notice Burn the token for a wallet address
    /// @param _userWallet Token holder wallet address
    /// @param _tokenId TokenId to burn
    /// @param _amount Amount of token to burn
    function burn(address _userWallet, uint256 _tokenId, uint256 _amount) external validTokenId(_tokenId) validAmount(_amount) {
        if (!burnerList[msg.sender]) {
            revert InvalidBurner();
        }

        _burn(_userWallet, _tokenId, _amount);
        emit E3SerumBurn(_userWallet, _tokenId, _amount);
    }

    /// @dev See {IERC1155-setApprovalForAll}.
    /// @dev added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev IERC1155-safeTransferFrom
    /// @dev added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
    /// @param from from address
    /// @param to receiver address
    /// @param tokenId tokenId to transfer
    /// @param amount token amount
    /// @param data custom data parameter during transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /// @dev IERC1155-safeBatchTransferFrom
    /// @dev added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
    /// @param from from address
    /// @param to receiver address
    /// @param ids tokenId list
    /// @param amounts token amounts
    /// @param data custom data parameter during transfer
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @dev IERC165-supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/solmate/src/tokens/ERC721.sol";
import "../lib/solmate/src/utils/LibString.sol";

/// @dev Only `owner` has a privilege, but the `sender` was provided.
/// @param sender Sender address.
/// @param owner Required sender address as an owner.
error OwnerOnly(address sender, address owner);

/// @dev Provided zero address.
error ZeroAddress();

/// @dev Zero value when it has to be different from zero.
error ZeroValue();

/// @dev Value overflow.
/// @param provided Overflow value.
/// @param max Maximum possible value.
error Overflow(uint256 provided, uint256 max);

/// @dev Wrong token Id provided.
/// @param provided Token Id.
error WrongTokenId(uint256 provided);

/// @dev Caught reentrancy violation.
error ReentrancyGuard();

/// @title DynamicContribution - Ownable smart contract for minting ERC721 tokens
contract DynamicContribution is ERC721 {
    using LibString for uint256;

    event OwnerUpdated(address indexed owner);
    event BaseURIChanged(string baseURI);

    // Owner address
    address public owner;
    // Base URI
    string public baseURI;
    // Unit counter
    uint256 public totalSupply;
    // Reentrancy lock
    uint256 internal _locked = 1;

    /// @dev DynamicContribution constructor.
    /// @param _name DynamicContribution contract name.
    /// @param _symbol DynamicContribution contract symbol.
    /// @param _baseURI DynamicContribution token base URI.
    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol)
    {
        baseURI = _baseURI;
        owner = msg.sender;
    }

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external {
        // Check for the ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Mints a new token.
    /// @return tokenId Minted token Id.
    function mint() external returns (uint256 tokenId) {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Get the current total supply
        tokenId = totalSupply;
        tokenId++;
        // Set total supply to the token Id number
        totalSupply = tokenId;
        // Mint a token
        _safeMint(msg.sender, tokenId);

        _locked = 1;
    }

    /// @dev Mints a new token for a specified account.
    /// @param account Account address for the token mint.
    /// @return tokenId Minted token Id.
    function mintFor(address account) external returns (uint256 tokenId) {
        // Reentrancy guard
        if (_locked > 1) {
            revert ReentrancyGuard();
        }
        _locked = 2;

        // Get the current total supply
        tokenId = totalSupply;
        tokenId++;
        // Set total supply to the token Id number
        totalSupply = tokenId;
        // Mint a token
        _safeMint(account, tokenId);

        _locked = 1;
    }

    /// @dev Checks for the token existence.
    /// @notice Token counter starts from 1.
    /// @param tokenId Token Id.
    /// @return true if the token exists, false otherwise.
    function exists(uint256 tokenId) external view returns (bool) {
        return tokenId > 0 && tokenId < (totalSupply + 1);
    }

    /// @dev Sets token base URI.
    /// @param bURI Base URI string.
    function setBaseURI(string memory bURI) external {
        // Check for the ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero value
        if (bytes(bURI).length == 0) {
            revert ZeroValue();
        }

        baseURI = bURI;
        emit BaseURIChanged(bURI);
    }

    /// @dev Gets the valid unit Id from the provided index.
    /// @notice Token counter starts from 1.
    /// @param id Token counter.
    /// @return tokenId Token Id.
    function tokenByIndex(uint256 id) external view returns (uint256 tokenId) {
        tokenId = id + 1;
        if (tokenId > totalSupply) {
            revert Overflow(tokenId, totalSupply);
        }
    }

    /// @dev Gets token URI.
    /// @param tokenId Token Id.
    /// @return Token URI string.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenId == 0 || tokenId > totalSupply) {
            revert WrongTokenId(tokenId);
        }
        return string.concat(baseURI, tokenId.toString());
    }
}
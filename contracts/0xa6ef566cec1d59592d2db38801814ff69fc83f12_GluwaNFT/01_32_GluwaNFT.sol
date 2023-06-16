pragma solidity ^0.8.19;

import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import './SeadropCloneable/ERC721SeaDropCloneable.sol';
import { SignatureValidation } from './abstracts/SignatureValidation.sol';

contract GluwaNFT is ERC721SeaDropCloneable, SignatureValidation {
    using StringsUpgradeable for uint256;

    /// @dev used to control until whick tokenId to be revealed. We require all the tokens are issued using a counter/index-based
    struct RevealRange {
        uint64 min;
        uint64 max;
    }

    // Mapping from token ID to metadata URI
    mapping(uint256 => string) private _tokenURIs;
    RevealRange[] private _revealRanges;
    // Mapping from token ID to metadata URI when token is in the hidden state
    mapping(uint256 => string) private _tokenHiddenStateURIs;
    string private _baseTokenURI;
    string private _baseTokenHiddenStateURI;

    modifier isWhitelistOrhasAdminRole() {
        require(isAdmin(_msgSender()) || isWhitelist(_msgSender()), 'GluwaBaseNFT: Not an admin or whitelisted');
        _;
    }

    /// @notice Retrieves the contract version
    /// @return The version as a string memory.
    function version() public pure virtual returns (string memory) {
        return '0.1.0';
    }

    /// @notice Mint a new token by sender
    /// @dev Caller must be whitelisted
    function mint() external virtual isWhitelistOrhasAdminRole {
        _safeMint(_msgSender(), 1);
    }

    /// @notice Mint a new token
    /// @param to The address that will own the minted token
    /// @dev Caller must be whitelisted
    function mint(address to) external virtual isWhitelistOrhasAdminRole {
        _safeMint(to, 1);
    }

    /// @notice Batch minting function
    /// @param toAddresses The addresses that will own the minted tokens
    /// @dev Caller must be an admin
    function mint(address[] calldata toAddresses) external virtual hasAdminRole {
        uint256 length = toAddresses.length;
        for (uint256 i; i < length; ) {
            _safeMint(toAddresses[i], 1);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Increase token minting cap
    /// @param  maxNumberOfTokenToMint_ the new cap
    /// @dev Caller must be an admin
    function set_maxNumberOfTokenToMint(uint256 maxNumberOfTokenToMint_) external virtual hasAdminRole {
        require(_maxNumberOfTokenToMint < maxNumberOfTokenToMint_, 'GluwaBaseNFT: Invalid input');
        _maxNumberOfTokenToMint = maxNumberOfTokenToMint_;
    }

    /// @notice Mint a new token by EIP-712, 'to' must be whitelisted
    /// @param to The address that will own the minted token
    /// @param gluwaNonce The nonce of the signature
    /// @param v The recovery byte of the user's signature
    /// @param r Half of the ECDSA signature pair
    /// @param s Half of the ECDSA signature pair
    /// @dev Receiver must be whitelisted
    function mintBySig(address to, uint96 gluwaNonce, uint8 v, bytes32 r, bytes32 s) external virtual {
        require(
            validateSignature(keccak256(abi.encode(keccak256('MintBySig(address to,uint96 gluwaNonce)'), to, gluwaNonce)), gluwaNonce, v, r, s) == to,
            'GluwaBaseNFT: Invalid signature'
        );
        require(isWhitelist(to), 'GluwaBaseNFT: Invalid signature');
        _safeMint(to, 1);
    }

    /// @notice Reveal token URIs
    /// @dev Caller must be an admin. It is practical to assume we won't release more than 2^64 - 1 token
    function reveal(uint64 min_, uint64 max_) external virtual hasAdminRole {
        _revealRanges.push(RevealRange({ min: min_, max: max_ }));
    }

    /// @notice Reveal token URIs
    /// @dev Caller must be an admin. It is practical to assume we won't release more than 2^64 - 1 token
    function isRevealed(uint256 tokenId) public view returns (bool) {
        RevealRange[] memory reviewRange = _revealRanges;
        for (uint i; i < reviewRange.length; ) {
            if (reviewRange[i].min <= tokenId && reviewRange[i].max >= tokenId) {
                return true;
            }
            ++i;
        }
        return false;
    }

    /// @notice Set a token URI for a specific token (internal)
    /// @param tokenId The token ID of the minted token
    /// @param uri The URI of the minted token
    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        _tokenURIs[tokenId] = uri;
    }

    /// @notice Set a token hidden state URI for a specific token (internal)
    /// @param tokenId The token ID of the minted token
    /// @param uri The URI of the minted token when token is in the hidden state
    function _setTokenHiddenStateURI(uint256 tokenId, string memory uri) internal virtual {
        _tokenHiddenStateURIs[tokenId] = uri;
    }

    /// @notice Set token URI
    /// @param tokenId The token ID of the minted token
    /// @param uri The URI of the minted token
    /// @dev Caller must be an admin
    function setTokenURI(uint256 tokenId, string memory uri) external virtual hasAdminRole {
        require(_exists(tokenId), 'GluwaBaseNFT: Token does not exist');
        _setTokenURI(tokenId, uri);
    }

    /// @notice Get token URI
    /// @param tokenId The token ID of the minted token
    /// @return The URI of the minted token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'GluwaBaseNFT: Token does not exist');
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory _hiddenURI = _tokenHiddenStateURIs[tokenId];
        if (isRevealed(tokenId)) {
            if (bytes(_tokenURI).length > 0) return _tokenURI;
            else return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), '.json'));
        } else {
            if (bytes(_hiddenURI).length > 0) return _hiddenURI;
            else return string(abi.encodePacked(_baseTokenHiddenStateURI, tokenId.toString(), '.json'));
        }
    }

    /// @notice Set the base URI
    /// @param uri The URI of the minted token
    /// @dev Caller must be an admin
    function setBaseTokenURI(string memory uri) external virtual hasAdminRole {
        _baseTokenURI = uri;
    }

    /// @notice Set the hidden state base URI
    /// @param uri The URI of the minted token
    /// @dev Caller must be an admin
    function setTokenHiddenStateURI(string memory uri) external virtual hasAdminRole {
        _baseTokenHiddenStateURI = uri;
    }
}
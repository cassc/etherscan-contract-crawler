// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";

import "./interfaces/IPoLidoNFT.sol";

/// @title PoLidoNFT.
/// @author 2021 ShardLabs.
contract PoLidoNFT is
    IPoLidoNFT,
    OwnableUpgradeable,
    ERC721Upgradeable,
    ERC721PausableUpgradeable
{
    /// @notice stMATIC address.
    address public stMATIC;

    /// @notice tokenIdIndex.
    uint256 public tokenIdIndex;

    /// @notice version.
    string public version;

    /// @notice maps the address to array of the owned tokens
    mapping(address => uint256[]) public owner2Tokens;
    /// @notice token can be owned by only one address at the time, therefore tokenId is present in only one of those arrays in the mapping
    /// this mapping stores the index of the tokenId in one of those arrays
    mapping(uint256 => uint256) public token2Index;

    /// @notice maps an array of the tokens that are approved to this address
    mapping(address => uint256[]) public address2Approved;
    /// @notice token can be approved to only one address at the time, therefore tokenId is present in only one of those arrays in the mapping
    /// this mapping stores the index of the tokenId in one of those arrays
    mapping(uint256 => uint256) public tokenId2ApprovedIndex;

    modifier isLido() {
        require(msg.sender == stMATIC, "Caller is not stMATIC contract");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address _stMATIC
    ) external initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();

        stMATIC = _stMATIC;
    }

    /// @notice Increments the token supply and mints the token based on that index
    /// @param _to - Address that will be the owner of minted token
    /// @return Index of the minted token
    function mint(address _to) external override isLido returns (uint256) {
        _mint(_to, ++tokenIdIndex);
        return tokenIdIndex;
    }

    /// @notice Burn the token with specified _tokenId
    /// @param _tokenId - Id of the token that will be burned
    function burn(uint256 _tokenId) external override isLido {
        _burn(_tokenId);
    }

    /// @notice Override of the approve function
    /// @param _to - Address that the token will be approved to
    /// @param _tokenId - Id of the token that will be approved to _to
    function approve(address _to, uint256 _tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
    {
        // If this token was approved before, remove it from the mapping of approvals
        address approvedAddress = getApproved(_tokenId);
        if (approvedAddress != address(0)) {
            _removeApproval(_tokenId, approvedAddress);
        }

        super.approve(_to, _tokenId);

        uint256[] storage approvedTokens = address2Approved[_to];

        // Add the new approved token to the mapping
        approvedTokens.push(_tokenId);
        tokenId2ApprovedIndex[_tokenId] = approvedTokens.length - 1;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721PausableUpgradeable)
        whenNotPaused
    {
        require(from != to, "Invalid operation");

        super._beforeTokenTransfer(from, to, tokenId);

        // Minting
        if (from == address(0)) {
            uint256[] storage ownerTokens = owner2Tokens[to];

            ownerTokens.push(tokenId);
            token2Index[tokenId] = ownerTokens.length - 1;
        }
        // Burning
        else if (to == address(0)) {
            uint256[] storage ownerTokens = owner2Tokens[from];
            uint256 ownerTokensLength = ownerTokens.length;
            uint256 burnedTokenIndexInOwnerTokens = token2Index[tokenId];
            uint256 lastOwnerTokensIndex = ownerTokensLength - 1;

            if (
                burnedTokenIndexInOwnerTokens != lastOwnerTokensIndex &&
                ownerTokensLength != 1
            ) {
                uint256 lastOwnerTokenId = ownerTokens[lastOwnerTokensIndex];
                // Make the last token have an index of a token we want to burn.
                // So when we request index of token with id that is currently last in ownerTokens it does not point
                // to the last slot in ownerTokens, but to a burned token's slot (we will update the slot at the next line)
                token2Index[lastOwnerTokenId] = burnedTokenIndexInOwnerTokens;
                // Copy currently last token to the place of a token we want to burn.
                // So updated pointer in token2Index points to a slot with the correct value.
                ownerTokens[burnedTokenIndexInOwnerTokens] = lastOwnerTokenId;
            }
            ownerTokens.pop();
            delete token2Index[tokenId];

            address approvedAddress = getApproved(tokenId);
            if (approvedAddress != address(0)) {
                _removeApproval(tokenId, approvedAddress);
            }
        }
        // Transferring
        else if (from != to) {
            address approvedAddress = getApproved(tokenId);
            if (approvedAddress != address(0)) {
                _removeApproval(tokenId, approvedAddress);
            }

            uint256[] storage senderTokens = owner2Tokens[from];
            uint256[] storage receiverTokens = owner2Tokens[to];

            uint256 tokenIndex = token2Index[tokenId];

            uint256 ownerTokensLength = senderTokens.length;
            uint256 removeTokenIndexInOwnerTokens = tokenIndex;
            uint256 lastOwnerTokensIndex = ownerTokensLength - 1;

            if (
                removeTokenIndexInOwnerTokens != lastOwnerTokensIndex &&
                ownerTokensLength != 1
            ) {
                uint256 lastOwnerTokenId = senderTokens[lastOwnerTokensIndex];
                // Make the last token have an index of a token we want to burn.
                // So when we request index of token with id that is currently last in ownerTokens it does not point
                // to the last slot in ownerTokens, but to a burned token's slot (we will update the slot at the next line)
                token2Index[lastOwnerTokenId] = removeTokenIndexInOwnerTokens;
                // Copy currently last token to the place of a token we want to burn.
                // So updated pointer in token2Index points to a slot with the correct value.
                senderTokens[removeTokenIndexInOwnerTokens] = lastOwnerTokenId;
            }
            senderTokens.pop();

            receiverTokens.push(tokenId);
            token2Index[tokenId] = receiverTokens.length - 1;
        }
    }

    /// @notice Check if the spender is the owner or is the tokenId approved to him
    /// @param _spender - Address that will be checked
    /// @param _tokenId - Token id that will be checked against _spender
    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        override
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    /// @notice Set stMATIC contract address
    /// @param _stMATIC - address of the stMATIC contract
    function setStMATIC(address _stMATIC) external override onlyOwner {
        stMATIC = _stMATIC;
    }

    /// @notice Set PoLidoNFT version
    /// @param _version - New version that will be set
    function setVersion(string calldata _version) external override onlyOwner {
        version = _version;
    }

    /// @notice Retrieve the array of owned tokens
    /// @param _address - Address for which the tokens will be retrieved
    /// @return - Array of owned tokens
    function getOwnedTokens(address _address)
        external
        view
        override
        returns (uint256[] memory)
    {
        return owner2Tokens[_address];
    }

    /// @notice Retrieve the array of approved tokens
    /// @param _address - Address for which the tokens will be retrieved
    /// @return - Array of approved tokens
    function getApprovedTokens(address _address)
        external
        view
        returns (uint256[] memory)
    {
        return address2Approved[_address];
    }

    /// @notice Remove the tokenId from the specific users array of approved tokens
    /// @param _tokenId - Id of the token that will be removed
    function _removeApproval(uint256 _tokenId, address _approvedAddress) internal {
        uint256[] storage approvedTokens = address2Approved[_approvedAddress];
        uint256 removeApprovedTokenIndexInOwnerTokens = tokenId2ApprovedIndex[
            _tokenId
        ];
        uint256 approvedTokensLength = approvedTokens.length;
        uint256 lastApprovedTokensIndex = approvedTokensLength - 1;

        if (
            removeApprovedTokenIndexInOwnerTokens != lastApprovedTokensIndex &&
            approvedTokensLength != 1
        ) {
            uint256 lastApprovedTokenId = approvedTokens[
                lastApprovedTokensIndex
            ];
            // Make the last token have an index of a token we want to burn.
            // So when we request index of token with id that is currently last in approveTokens
            // it does not point to the last slot in approveTokens, but to a burned token's slot
            // (we will update the slot at the next line).
            tokenId2ApprovedIndex[
                lastApprovedTokenId
            ] = removeApprovedTokenIndexInOwnerTokens;
            // Copy currently last token to the place of a token we want to burn.
            // So updated pointer in tokenId2ApprovedIndex points to a slot with the correct value.
            approvedTokens[
                removeApprovedTokenIndexInOwnerTokens
            ] = lastApprovedTokenId;
        }

        approvedTokens.pop();
        delete tokenId2ApprovedIndex[_tokenId];
    }

    /// @notice Flips the pause state
    function togglePause() external override onlyOwner {
        paused() ? _unpause() : _pause();
    }
}
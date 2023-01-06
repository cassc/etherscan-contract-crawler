//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

/// @title Example of ERC721 contract with ERC2981
/// @author Simon Fremaux (@dievardump)
/// @notice This is a mock, mint and mintBatch are not protected. Please do not use as-is in production
contract Millionaireasia721Contract is ERC721Enumerable, ERC2981, Ownable {
    // uint256 nextTokenId;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Mint one token to `to`
    /// @param to the recipient of the token
    /// @param tokenId the id of the token (generated off chain for saving gas)
    /// @param royaltyRecipient the recipient for royalties (if royaltyValue > 0)
    /// @param royaltyValue the royalties asked for (EIP2981)
    /// @param uri the URI of the token
    function mint(
        address to,
        uint256 tokenId,
        address royaltyRecipient,
        uint96 royaltyValue,
        string memory uri
    ) external payable {
        address owner = owner();
        if(owner != msg.sender) {
            require(msg.value > 0, "Must pay minting service fee");
            // check balance of spender
            uint256 ethBalance = msg.sender.balance;
            require(ethBalance > msg.value, "Insufficient balance");
            
            (bool success, ) = owner.call{ value: msg.value }("");
            require(success, "Transaction failed");
        }
        
        _safeMint(to, tokenId, '');

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }

        if (bytes(uri).length > 0) {
            _setTokenURI(tokenId, uri);
        }
    }

    /// @notice Mint several tokens at once
    /// @param recipient a recipient for each token
    /// @param tokenIds an array of ids for each token
    /// @param royaltyRecipients an array of recipients for royalties (if royaltyValues[i] > 0)
    /// @param royaltyValues an array of royalties asked for (EIP2981)
    /// @param uris an array of URIs for each token
    function mintBatch(
        address recipient,
        uint256[] memory tokenIds,
        address[] memory royaltyRecipients,
        uint96[] memory royaltyValues,
        string[] memory uris
    ) external payable {
        require(
            tokenIds.length == royaltyRecipients.length &&
                tokenIds.length == royaltyValues.length,
            'ERC721: Arrays length mismatch'
        );

        address owner = owner();
        if(owner != msg.sender) {
            require(msg.value > 0, "Must pay minting service fee");
            // check balance of spender
            uint256 ethBalance = msg.sender.balance;
            require(ethBalance > msg.value, "Insufficient balance");
            
            (bool success, ) = owner.call{ value: msg.value }("");
            require(success, "Transaction failed");
        }

        for (uint256 i; i < tokenIds.length; i++) {
            _safeMint(recipient, tokenIds[i], '');
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(
                    tokenIds[i],
                    royaltyRecipients[i],
                    royaltyValues[i]
                );
            }
            if (bytes(uris[i]).length > 0) {
                _setTokenURI(tokenIds[i], uris[i]);
            }
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public payable {
        if(msg.value > 0) {
            address contractOwner = owner();
            (bool success, ) = contractOwner.call{ value: msg.value }("");
            require(success, "ERC721: Transfer failed");
        }
        
        for (uint256 i; i < tokenIds.length; i++) {
            safeTransferFrom(from, to, tokenIds[i], "");
        }
    }

    function safeBatchTransferFrom(
        address from,
        address[] memory tos,
        uint256[] memory tokenIds
    ) public payable {
        if(msg.value > 0) {
            address contractOwner = owner();
            (bool success, ) = contractOwner.call{ value: msg.value }("");
            require(success, "ERC721: Transfer failed");
        }
        
        for (uint256 i; i < tokenIds.length; i++) {
            safeTransferFrom(from, tos[i], tokenIds[i], "");
        }
    }

    function safeTransferFromWithFee(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        if(msg.value > 0) {
            address contractOwner = owner();
            (bool success, ) = contractOwner.call{ value: msg.value }("");
            require(success, "ERC721: Transfer failed");
        }
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    // override
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721WithRoyalties: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721WithRoyalties: URI query for nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override onlyOwner {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
            _resetTokenRoyalty(tokenId);
        }
    }

    function approveBatch(uint256[] memory tokenIds, address operator) external {
        for (uint256 i; i < tokenIds.length; i++) {
            address owner = ERC721.ownerOf(tokenIds[i]);
            require(operator != owner, "ERC721: approval to current owner");

            require(
                _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
                "ERC721: approve caller is not owner nor approved for all"
            );
            ERC721._approve(operator, tokenIds[i]);
        }
    }

    modifier onlyApprover(uint256 tokenId, address operator) {
        require(getApproved(tokenId) == operator);
        _;
    }

    modifier onlyApprovers(uint256[] memory tokenIds, address operator) {
        for (uint256 i; i < tokenIds.length; i++) {
            require(getApproved(tokenIds[i]) == operator);
        }
        _;
    }

    function buy(uint256 tokenId, uint256 amount, uint256 fee) external payable onlyApprover(tokenId, msg.sender) {
        require(msg.value == amount, "Amount is invalid");
        // check balance of spender
        uint256 ethBalance = msg.sender.balance;
        // check royalty
        (address creator, uint256 royalty) = royaltyInfo(tokenId, amount);

        require(ethBalance > msg.value, "Insufficient balance");

        address tokenOwner = ERC721.ownerOf(tokenId);
        (bool success, ) = tokenOwner.call{value: (msg.value - fee - royalty)}("");
        if(success && royalty > 0) {
            (success, ) = creator.call{value: royalty}("");          
        }
        if(success)
            if(fee > 0) {
                address contractOwner = owner();
                (success, ) = contractOwner.call{ value: fee }("");
            }
        
        require(success, "Transaction failed");

        if(success) {
            safeTransferFrom(tokenOwner, _msgSender(), tokenId);
        }
    }

    function buyBatch(uint256[] memory tokenIds, uint256[] memory amounts, uint256[] memory fees) external payable onlyApprovers(tokenIds, msg.sender) {
        require(tokenIds.length == amounts.length && tokenIds.length == fees.length, 'ERC721: Arrays length mismatch');
        for (uint256 i; i < tokenIds.length; i++) {
            // check balance of spender
            uint256 ethBalance = msg.sender.balance;
            // check royalty
            (address creator, uint256 royalty) = royaltyInfo(tokenIds[i], amounts[i]);

            require(ethBalance > msg.value, "Insufficient balance");

            address tokenOwner = ERC721.ownerOf(tokenIds[i]);
            (bool success, ) = tokenOwner.call{value: (msg.value - fees[i] - royalty)}("");
            if(success && royalty > 0) {
                (success, ) = creator.call{value: royalty}("");          
            }
            if(success)
                if(fees[i] > 0) {
                    address contractOwner = owner();
                    (success, ) = contractOwner.call{ value: fees[i] }("");
                }
            
            require(success, "Transaction failed");

            if(success) {
                safeTransferFrom(tokenOwner, _msgSender(), tokenIds[i]);
            }
        }
    }

    function mintOnSale(address to, uint256 tokenId, address royaltyRecipient, uint96 royaltyValue, string memory uri, uint256 amount, uint256 fee) external payable {
        require(msg.value == amount, "Amount is invalid");
        // check balance of spender
        uint256 ethBalance = msg.sender.balance;
        require(ethBalance > msg.value, "Insufficient balance");

        _safeMint(to, tokenId, '');

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }

        if (bytes(uri).length > 0) {
            _setTokenURI(tokenId, uri);
        }

        (bool success, ) = royaltyRecipient.call{ value: (msg.value - fee)}("");
        if(fee > 0) {
            address owner = owner();
            (success, ) = owner.call{ value: fee }("");
        }

        require(success, "Transaction failed");
    }

    function mintBatchOnSale(address to, uint256[] memory tokenIds, address royaltyRecipient, uint96 royaltyValue, string[] memory uris, uint256 amount, uint256 fee) external payable {
        require(tokenIds.length == uris.length, 'ERC721: Arrays length mismatch');
        require(msg.value == amount, "Amount is invalid");
        // check balance of spender
        uint256 ethBalance = msg.sender.balance;
        require(ethBalance > msg.value, "Insufficient balance");
        for (uint256 i; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i], '');
            if (royaltyValue > 0) {
                _setTokenRoyalty(tokenIds[i], royaltyRecipient, royaltyValue);
            }

            if (bytes(uris[i]).length > 0) {
                _setTokenURI(tokenIds[i], uris[i]);
            }
        }

        (bool success, ) = royaltyRecipient.call{ value: (msg.value - fee)}("");
        if(fee > 0) {
            address owner = owner();
            (success, ) = owner.call{ value: fee }("");
        }
        
        require(success, "Transaction failed");
    }
}
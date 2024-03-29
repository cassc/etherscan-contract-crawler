// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: New Nft Opensea
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                   //
//                                                                                                                   //
//    pragma solidity ^0.8.0;                                                                                        //
//                                                                                                                   //
//    /// @author: manifold.xyz                                                                                      //
//                                                                                                                   //
//    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";                                                      //
//                                                                                                                   //
//    import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";                                    //
//    import "./core/ERC721CreatorCore.sol";                                                                         //
//                                                                                                                   //
//    /**                                                                                                            //
//     * @dev ERC721Creator implementation                                                                           //
//     */                                                                                                            //
//    contract ERC721Creator is AdminControl, ERC721, ERC721CreatorCore {                                            //
//        constructor(string memory _name, string memory _symbol)                                                    //
//            ERC721(_name, _symbol)                                                                                 //
//        {}                                                                                                         //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC165-supportsInterface}.                                                                   //
//         */                                                                                                        //
//        function supportsInterface(bytes4 interfaceId)                                                             //
//            public                                                                                                 //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override(ERC721, ERC721CreatorCore, AdminControl)                                                      //
//            returns (bool)                                                                                         //
//        {                                                                                                          //
//            return                                                                                                 //
//                ERC721CreatorCore.supportsInterface(interfaceId) ||                                                //
//                ERC721.supportsInterface(interfaceId) ||                                                           //
//                AdminControl.supportsInterface(interfaceId);                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        function _beforeTokenTransfer(                                                                             //
//            address from,                                                                                          //
//            address to,                                                                                            //
//            uint256 tokenId                                                                                        //
//        ) internal virtual override {                                                                              //
//            _approveTransfer(from, to, tokenId);                                                                   //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-registerExtension}.                                                              //
//         */                                                                                                        //
//        function registerExtension(address extension, string calldata baseURI)                                     //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//            nonBlacklistRequired(extension)                                                                        //
//        {                                                                                                          //
//            _registerExtension(extension, baseURI, false);                                                         //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-registerExtension}.                                                              //
//         */                                                                                                        //
//        function registerExtension(                                                                                //
//            address extension,                                                                                     //
//            string calldata baseURI,                                                                               //
//            bool baseURIIdentical                                                                                  //
//        ) external override adminRequired nonBlacklistRequired(extension) {                                        //
//            _registerExtension(extension, baseURI, baseURIIdentical);                                              //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-unregisterExtension}.                                                            //
//         */                                                                                                        //
//        function unregisterExtension(address extension)                                                            //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _unregisterExtension(extension);                                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-blacklistExtension}.                                                             //
//         */                                                                                                        //
//        function blacklistExtension(address extension)                                                             //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _blacklistExtension(extension);                                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setBaseTokenURIExtension}.                                                       //
//         */                                                                                                        //
//        function setBaseTokenURIExtension(string calldata uri)                                                     //
//            external                                                                                               //
//            override                                                                                               //
//            extensionRequired                                                                                      //
//        {                                                                                                          //
//            _setBaseTokenURIExtension(uri, false);                                                                 //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setBaseTokenURIExtension}.                                                       //
//         */                                                                                                        //
//        function setBaseTokenURIExtension(string calldata uri, bool identical)                                     //
//            external                                                                                               //
//            override                                                                                               //
//            extensionRequired                                                                                      //
//        {                                                                                                          //
//            _setBaseTokenURIExtension(uri, identical);                                                             //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURIPrefixExtension}.                                                     //
//         */                                                                                                        //
//        function setTokenURIPrefixExtension(string calldata prefix)                                                //
//            external                                                                                               //
//            override                                                                                               //
//            extensionRequired                                                                                      //
//        {                                                                                                          //
//            _setTokenURIPrefixExtension(prefix);                                                                   //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURIExtension}.                                                           //
//         */                                                                                                        //
//        function setTokenURIExtension(uint256 tokenId, string calldata uri)                                        //
//            external                                                                                               //
//            override                                                                                               //
//            extensionRequired                                                                                      //
//        {                                                                                                          //
//            _setTokenURIExtension(tokenId, uri);                                                                   //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURIExtension}.                                                           //
//         */                                                                                                        //
//        function setTokenURIExtension(                                                                             //
//            uint256[] memory tokenIds,                                                                             //
//            string[] calldata uris                                                                                 //
//        ) external override extensionRequired {                                                                    //
//            require(tokenIds.length == uris.length, "Invalid input");                                              //
//            for (uint256 i = 0; i < tokenIds.length; i++) {                                                        //
//                _setTokenURIExtension(tokenIds[i], uris[i]);                                                       //
//            }                                                                                                      //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setBaseTokenURI}.                                                                //
//         */                                                                                                        //
//        function setBaseTokenURI(string calldata uri)                                                              //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _setBaseTokenURI(uri);                                                                                 //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURIPrefix}.                                                              //
//         */                                                                                                        //
//        function setTokenURIPrefix(string calldata prefix)                                                         //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _setTokenURIPrefix(prefix);                                                                            //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURI}.                                                                    //
//         */                                                                                                        //
//        function setTokenURI(uint256 tokenId, string calldata uri)                                                 //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _setTokenURI(tokenId, uri);                                                                            //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setTokenURI}.                                                                    //
//         */                                                                                                        //
//        function setTokenURI(uint256[] memory tokenIds, string[] calldata uris)                                    //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            require(tokenIds.length == uris.length, "Invalid input");                                              //
//            for (uint256 i = 0; i < tokenIds.length; i++) {                                                        //
//                _setTokenURI(tokenIds[i], uris[i]);                                                                //
//            }                                                                                                      //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setMintPermissions}.                                                             //
//         */                                                                                                        //
//        function setMintPermissions(address extension, address permissions)                                        //
//            external                                                                                               //
//            override                                                                                               //
//            adminRequired                                                                                          //
//        {                                                                                                          //
//            _setMintPermissions(extension, permissions);                                                           //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintBase}.                                                                 //
//         */                                                                                                        //
//        function mintBase(address to)                                                                              //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            adminRequired                                                                                          //
//            returns (uint256)                                                                                      //
//        {                                                                                                          //
//            return _mintBase(to, "");                                                                              //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintBase}.                                                                 //
//         */                                                                                                        //
//        function mintBase(address to, string calldata uri)                                                         //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            adminRequired                                                                                          //
//            returns (uint256)                                                                                      //
//        {                                                                                                          //
//            return _mintBase(to, uri);                                                                             //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintBaseBatch}.                                                            //
//         */                                                                                                        //
//        function mintBaseBatch(address to, uint16 count)                                                           //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            adminRequired                                                                                          //
//            returns (uint256[] memory tokenIds)                                                                    //
//        {                                                                                                          //
//            tokenIds = new uint256[](count);                                                                       //
//            for (uint16 i = 0; i < count; i++) {                                                                   //
//                tokenIds[i] = _mintBase(to, "");                                                                   //
//            }                                                                                                      //
//            return tokenIds;                                                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintBaseBatch}.                                                            //
//         */                                                                                                        //
//        function mintBaseBatch(address to, string[] calldata uris)                                                 //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            adminRequired                                                                                          //
//            returns (uint256[] memory tokenIds)                                                                    //
//        {                                                                                                          //
//            tokenIds = new uint256[](uris.length);                                                                 //
//            for (uint256 i = 0; i < uris.length; i++) {                                                            //
//                tokenIds[i] = _mintBase(to, uris[i]);                                                              //
//            }                                                                                                      //
//            return tokenIds;                                                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev Mint token with no extension                                                                       //
//         */                                                                                                        //
//        function _mintBase(address to, string memory uri)                                                          //
//            internal                                                                                               //
//            virtual                                                                                                //
//            returns (uint256 tokenId)                                                                              //
//        {                                                                                                          //
//            _tokenCount++;                                                                                         //
//            tokenId = _tokenCount;                                                                                 //
//                                                                                                                   //
//            // Track the extension that minted the token                                                           //
//            _tokensExtension[tokenId] = address(this);                                                             //
//                                                                                                                   //
//            _safeMint(to, tokenId);                                                                                //
//                                                                                                                   //
//            if (bytes(uri).length > 0) {                                                                           //
//                _tokenURIs[tokenId] = uri;                                                                         //
//            }                                                                                                      //
//                                                                                                                   //
//            // Call post mint                                                                                      //
//            _postMintBase(to, tokenId);                                                                            //
//            return tokenId;                                                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintExtension}.                                                            //
//         */                                                                                                        //
//        function mintExtension(address to)                                                                         //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            extensionRequired                                                                                      //
//            returns (uint256)                                                                                      //
//        {                                                                                                          //
//            return _mintExtension(to, "");                                                                         //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintExtension}.                                                            //
//         */                                                                                                        //
//        function mintExtension(address to, string calldata uri)                                                    //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            extensionRequired                                                                                      //
//            returns (uint256)                                                                                      //
//        {                                                                                                          //
//            return _mintExtension(to, uri);                                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintExtensionBatch}.                                                       //
//         */                                                                                                        //
//        function mintExtensionBatch(address to, uint16 count)                                                      //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            extensionRequired                                                                                      //
//            returns (uint256[] memory tokenIds)                                                                    //
//        {                                                                                                          //
//            tokenIds = new uint256[](count);                                                                       //
//            for (uint16 i = 0; i < count; i++) {                                                                   //
//                tokenIds[i] = _mintExtension(to, "");                                                              //
//            }                                                                                                      //
//            return tokenIds;                                                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-mintExtensionBatch}.                                                       //
//         */                                                                                                        //
//        function mintExtensionBatch(address to, string[] calldata uris)                                            //
//            public                                                                                                 //
//            virtual                                                                                                //
//            override                                                                                               //
//            nonReentrant                                                                                           //
//            extensionRequired                                                                                      //
//            returns (uint256[] memory tokenIds)                                                                    //
//        {                                                                                                          //
//            tokenIds = new uint256[](uris.length);                                                                 //
//            for (uint256 i = 0; i < uris.length; i++) {                                                            //
//                tokenIds[i] = _mintExtension(to, uris[i]);                                                         //
//            }                                                                                                      //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev Mint token via extension                                                                           //
//         */                                                                                                        //
//        function _mintExtension(address to, string memory uri)                                                     //
//            internal                                                                                               //
//            virtual                                                                                                //
//            returns (uint256 tokenId)                                                                              //
//        {                                                                                                          //
//            _tokenCount++;                                                                                         //
//            tokenId = _tokenCount;                                                                                 //
//                                                                                                                   //
//            _checkMintPermissions(to, tokenId);                                                                    //
//                                                                                                                   //
//            // Track the extension that minted the token                                                           //
//            _tokensExtension[tokenId] = msg.sender;                                                                //
//                                                                                                                   //
//            _safeMint(to, tokenId);                                                                                //
//                                                                                                                   //
//            if (bytes(uri).length > 0) {                                                                           //
//                _tokenURIs[tokenId] = uri;                                                                         //
//            }                                                                                                      //
//                                                                                                                   //
//            // Call post mint                                                                                      //
//            _postMintExtension(to, tokenId);                                                                       //
//            return tokenId;                                                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-tokenExtension}.                                                           //
//         */                                                                                                        //
//        function tokenExtension(uint256 tokenId)                                                                   //
//            public                                                                                                 //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (address)                                                                                      //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _tokenExtension(tokenId);                                                                       //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721CreatorCore-burn}.                                                                     //
//         */                                                                                                        //
//        function burn(uint256 tokenId) public virtual override nonReentrant {                                      //
//            require(                                                                                               //
//                _isApprovedOrOwner(msg.sender, tokenId),                                                           //
//                "Caller is not owner nor approved"                                                                 //
//            );                                                                                                     //
//            address owner = ownerOf(tokenId);                                                                      //
//            _burn(tokenId);                                                                                        //
//            _postBurn(owner, tokenId);                                                                             //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setRoyalties}.                                                                   //
//         */                                                                                                        //
//        function setRoyalties(                                                                                     //
//            address payable[] calldata receivers,                                                                  //
//            uint256[] calldata basisPoints                                                                         //
//        ) external override adminRequired {                                                                        //
//            _setRoyaltiesExtension(address(this), receivers, basisPoints);                                         //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setRoyalties}.                                                                   //
//         */                                                                                                        //
//        function setRoyalties(                                                                                     //
//            uint256 tokenId,                                                                                       //
//            address payable[] calldata receivers,                                                                  //
//            uint256[] calldata basisPoints                                                                         //
//        ) external override adminRequired {                                                                        //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            _setRoyalties(tokenId, receivers, basisPoints);                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {ICreatorCore-setRoyaltiesExtension}.                                                          //
//         */                                                                                                        //
//        function setRoyaltiesExtension(                                                                            //
//            address extension,                                                                                     //
//            address payable[] calldata receivers,                                                                  //
//            uint256[] calldata basisPoints                                                                         //
//        ) external override adminRequired {                                                                        //
//            _setRoyaltiesExtension(extension, receivers, basisPoints);                                             //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev {See ICreatorCore-getRoyalties}.                                                                   //
//         */                                                                                                        //
//        function getRoyalties(uint256 tokenId)                                                                     //
//            external                                                                                               //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (address payable[] memory, uint256[] memory)                                                   //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _getRoyalties(tokenId);                                                                         //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev {See ICreatorCore-getFees}.                                                                        //
//         */                                                                                                        //
//        function getFees(uint256 tokenId)                                                                          //
//            external                                                                                               //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (address payable[] memory, uint256[] memory)                                                   //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _getRoyalties(tokenId);                                                                         //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev {See ICreatorCore-getFeeRecipients}.                                                               //
//         */                                                                                                        //
//        function getFeeRecipients(uint256 tokenId)                                                                 //
//            external                                                                                               //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (address payable[] memory)                                                                     //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _getRoyaltyReceivers(tokenId);                                                                  //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev {See ICreatorCore-getFeeBps}.                                                                      //
//         */                                                                                                        //
//        function getFeeBps(uint256 tokenId)                                                                        //
//            external                                                                                               //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (uint256[] memory)                                                                             //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _getRoyaltyBPS(tokenId);                                                                        //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev {See ICreatorCore-royaltyInfo}.                                                                    //
//         */                                                                                                        //
//        function royaltyInfo(uint256 tokenId, uint256 value)                                                       //
//            external                                                                                               //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (address, uint256)                                                                             //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _getRoyaltyInfo(tokenId, value);                                                                //
//        }                                                                                                          //
//                                                                                                                   //
//        /**                                                                                                        //
//         * @dev See {IERC721Metadata-tokenURI}.                                                                    //
//         */                                                                                                        //
//        function tokenURI(uint256 tokenId)                                                                         //
//            public                                                                                                 //
//            view                                                                                                   //
//            virtual                                                                                                //
//            override                                                                                               //
//            returns (string memory)                                                                                //
//        {                                                                                                          //
//            require(_exists(tokenId), "Nonexistent token");                                                        //
//            return _tokenURI(tokenId);                                                                             //
//        }                                                                                                          //
//    }                                                                                                              //
//    # Palkeoramix decompiler.                                                                                      //
//                                                                                                                   //
//    const unknown4060b25e = '2.0.0'                                                                                //
//    const unknownc311c523 = 1                                                                                      //
//                                                                                                                   //
//    def storage:                                                                                                   //
//      stor0 is mapping of uint256 at storage 0                                                                     //
//      stor1 is mapping of uint8 at storage 1                                                                       //
//      owner is addr at storage 2                                                                                   //
//      unknowncd7c0326Address is addr at storage 3                                                                  //
//      name is array of uint256 at storage 4                                                                        //
//      symbol is array of uint256 at storage 5                                                                      //
//      totalSupply is mapping of uint256 at storage 6                                                               //
//      unknownf923e8c3 is array of uint256 at storage 7                                                             //
//      uri is array of uint256 at storage 8                                                                         //
//      stor9 is uint8 at storage 9                                                                                  //
//      stor10 is mapping of uint8 at storage 10                                                                     //
//      creator is mapping of addr at storage 11                                                                     //
//                                                                                                                   //
//    def name() payable:                                                                                            //
//      return name[0 len name.length]                                                                               //
//                                                                                                                   //
//    def uri(uint256 _id) payable:                                                                                  //
//      return uri[_id][0 len uri[_id].length]                                                                       //
//                                                                                                                   //
//    def creator(uint256 _tokenId) payable:                                                                         //
//      require calldata.size - 4 >= 32                                                                              //
//      return creator[_tokenId]                                                                                     //
//                                                                                                                   //
//    def unknown73505d35(addr _param1) payable:                                                                     //
//      require calldata.size - 4 >= 32                                                                              //
//      return bool(stor10[_param1])                                                                                 //
//                                                                                                                   //
//    def owner() payable:                                                                                           //
//      return owner                                                                                                 //
//                                                                                                                   //
//    def symbol() payable:                                                                                          //
//      return symbol[0 len symbol.length]                                                                           //
//                                                                                                                   //
//    def totalSupply(uint256 _id) payable:                                                                          //
//      require calldata.size - 4 >= 32                                                                              //
//      return totalSupply[_id]                                                                                      //
//                                                                                                                   //
//    def unknowncd7c0326() payable:                                                                                 //
//      return unknowncd7c0326Address                                                                                //
//                                                                                                                   //
//    def unknownf923e8c3() payable:                                                                                 //
//      return unknownf923e8c3[0 len unknownf923e8c3.length]                                                         //
//                                                                                                                   //
//    #                                                                                                              //
//    #  Regular functions                                                                                           //
//    #                                                                                                              //
//                                                                                                                   //
//    def _fallback() payable: # default function                                                                    //
//      revert                                                                                                       //
//                                                                                                                   //
//    def isOwner() payable:                                                                                         //
//      return (caller == owner)                                                                                     //
//                                                                                                                   //
//    def exists(uint256 _tokenId) payable:                                                                          //
//      require calldata.size - 4 >= 32                                                                              //
//      return (totalSupply[_tokenId] > 0)                                                                           //
//                                                                                                                   //
//    def supportsInterface(bytes4 _interfaceId) payable:                                                            //
//      require calldata.size - 4 >= 32                                                                              //
//      if Mask(32, 224, _interfaceId) != 0x1ffc9a700000000000000000000000000000000000000000000000000000000:         //
//          if Mask(32, 224, _interfaceId) != 0xd9b67a2600000000000000000000000000000000000000000000000000000000:    //
//              return 0                                                                                             //
//      return 1                                                                                                     //
//                                                                                                                   //
//    def setApprovalForAll(address _to, bool _approved) payable:                                                    //
//      require calldata.size - 4 >= 64                                                                              //
//      stor1[caller][addr(_to)] = uint8(_approved)                                                                  //
//      log ApprovalForAll(                                                                                          //
//            address owner=_approved,                                                                               //
//            address operator=caller,                                                                               //
//            bool approved=_to)                                                                                     //
//                                                                                                                   //
//    def isApprovedForAll(address _owner, address _operator) payable:                                               //
//      require calldata.size - 4 >= 64                                                                              //
//      if not stor10[addr(_operator)]:                                                                              //
//          require ext_code.size(unknowncd7c0326Address)                                                            //
//          static call unknowncd7c0326Address.proxies(address param1) with:                                         //
//                                                                                                                   //
//                                                                                                                   //
//                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OPMNY is ERC721Creator {
    constructor() ERC721Creator("New Nft Opensea", "OPMNY") {}
}
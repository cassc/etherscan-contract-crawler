// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC1155Storage} from "../storage/ERC1155Storage.sol";
import {TokenMetadata} from "../libraries/TokenMetadata.sol";
import {IERC1155Facet} from "../interfaces/IERC1155Facet.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IERC1155} from "@solidstate/contracts/interfaces/IERC1155.sol";
import {OwnableInternal} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {PausableInternal} from "@solidstate/contracts/security/PausableInternal.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {IERC1155Metadata} from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";
import {ERC1155MetadataStorage} from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";
import {ERC1155EnumerableStorage} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableStorage.sol";
import {SolidStateERC1155, ERC1155Base, ERC1155Metadata} from "@solidstate/contracts/token/ERC1155/SolidStateERC1155.sol";
import {MetadataInternal, MetadataStorage} from "../utils/Metadata/MetadataInternal.sol";

import "hardhat/console.sol";

contract ERC1155Facet is
    SolidStateERC1155,
    IERC1155Facet,
    OwnableInternal,
    PausableInternal,
    MetadataInternal,
    DefaultOperatorFilterer
{
    using ERC1155Storage for ERC1155Storage.Layout;
    using MetadataStorage for MetadataStorage.Layout;
    using ERC1155MetadataStorage for ERC1155MetadataStorage.Layout;
    using ERC1155EnumerableStorage for ERC1155EnumerableStorage.Layout;

    modifier validTokenID(uint256 _tokenId) {
        if (!_exists(_tokenId)) revert InvalidTokenID();

        _;
    }

    modifier validQuantity(uint256 _id, uint256 _amount) {
        uint256 currentTotalSupply = totalSupply(_id);
        uint256 maxSupply_ = ERC1155Storage.layout().tokenData[_id].maxSupply;

        if (currentTotalSupply + _amount > maxSupply_)
            revert ExceedsMaxSupply();

        _;
    }

    /**
     * @notice Checks if the amount sent is greater than or equal to the price of the token. If the sender is the owner, it will bypass this check allowing the owner to mint or airdrop for free.
     * @param _id The token ID
     * @param _amount The amount of tokens being minted
     */
    modifier validValueSent(uint256 _id, uint256 _amount) {
        uint256 totalPrice = ERC1155Storage.layout().tokenData[_id].price *
            _amount;

        if (msg.sender != _owner() && msg.value < totalPrice)
            revert InvalidAmount();

        _;
    }

    modifier validMint(uint256 _tokenId, uint256 _amount) {
        if (ERC1155Storage.layout().tokenData[_tokenId].allowListEnabled) {}

        _;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    )
        external
        payable
        validTokenID(id)
        validQuantity(id, amount)
        validValueSent(id, amount)
    {
        _mint(account, id, amount, "");
    }

    // On chain metadata
    function uri(
        uint256 _tokenId
    )
        public
        view
        override(ERC1155Metadata, IERC1155Metadata)
        returns (string memory)
    {
        string memory uniqueTokenURI = ERC1155Storage
            .layout()
            .tokenData[_tokenId]
            .tokenUri;
        if (bytes(uniqueTokenURI).length > 0) {
            return uniqueTokenURI;
        }

        // if (!ERC1155Storage.layout().tokenData[_tokenId].onChainMetadata) {
        // console.log("Off chain metadata response for token", _tokenId);
        // Return off chain url
        return
            string(
                abi.encodePacked(
                    ERC1155MetadataStorage.layout().baseURI,
                    _toString(_tokenId)
                )
            );
        // } else {
        //     return
        //         TokenMetadata.makeMetadataJSON(
        //             _tokenId,
        //             msg.sender,
        //             MetadataStorage.layout().metadata[_tokenId].name,
        //             MetadataStorage.layout().metadata[_tokenId].image,
        //             MetadataStorage.layout().metadata[_tokenId].description,
        //             MetadataStorage.layout().metadata[_tokenId].attributes
        //         );
        // }
    }

    // on chain metadata
    function _onChainMetadata(
        uint256 _tokenId
    ) internal view returns (string memory metadata) {
        MetadataStorage.Metadata storage tokenMetadata = MetadataStorage
            .layout()
            .metadata[_tokenId];

        metadata = TokenMetadata.makeMetadataJSON(
            _tokenId,
            msg.sender,
            tokenMetadata.name,
            tokenMetadata.image,
            tokenMetadata.description,
            tokenMetadata.attributes
        );
    }

    function maxSupply(uint256 _id) public view returns (uint256) {
        return ERC1155Storage.layout().tokenData[_id].maxSupply;
    }

    function setMaxSupply(
        uint256 _id,
        uint256 _maxSupply
    ) external validTokenID(_id) onlyOwner {
        if (_maxSupply < totalSupply(_id)) revert InvalidMaxSupply();

        ERC1155Storage.layout().tokenData[_id].maxSupply = _maxSupply;
    }

    // ERC1155Storage.TokenStructure memory _tokenData
    // tokenUri // Optional, baseUri is set in ERC1155MetadataStorage (https://sample.com/{id}.json) would be valid)
    /**
     * @dev Creates a new token type
     * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
     * @param _maxSupply Maxmium amount of new token.
     * @param _price Price of new token.
     * @param _allowListEnabled Whether or not the token is on the allow list.
     * @param _tokenUri Optional, baseUri is set in ERC1155MetadataStorage (https://sample.com/{id}.json) would be valid)
     * @return The newly created token ID
     */
    function create(
        uint256 _maxSupply,
        uint256 _price,
        string calldata _tokenUri,
        bool _allowListEnabled
    )
        external
        // bool __onChainMetadata,
        // MetadataStorage.Metadata calldata _metadata
        onlyOwner
        returns (uint256)
    {
        console.log("Successfully called create function");
        uint256 _id = ERC1155Storage.layout().currentTokenId;

        // Do we want to store everything in top level mappings or use the tokenData struct mapping?
        // Not sure if there's a huge difference in gas costs here.
        ERC1155Storage.TokenStructure storage tokenData = ERC1155Storage
            .layout()
            .tokenData[_id];

        tokenData.maxSupply = _maxSupply;
        tokenData.price = _price;
        tokenData.creator = tx.origin;
        tokenData.tokenUri = _tokenUri;
        tokenData.allowListEnabled = _allowListEnabled;

        _incrementTokenTypeId();

        // ERC1155Storage
        //     .TokenStructure(
        //         _maxSupply,
        //         _price,
        //         msg.sender,
        //         _tokenUri,
        //         _allowListEnabled
        //     );
        // ERC1155Storage.Layout().tokenData[_id] = tokenData;

        // ERC1155Storage
        //     .layout()
        //     .tokenData[_id]
        //     .onChainMetadata = __onChainMetadata;

        // MetadataStorage.layout().metadata[_id] = _metadata;
        // _setMetadata(_id, _metadata);

        if (bytes(_tokenUri).length > 0) {
            emit URI(_tokenUri, _id);
        }

        ERC1155EnumerableStorage.layout().totalSupply[_id] = 0; // Might not be neccessary since it's 0 by default
        return _id;
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return ERC1155Storage.tokenData(_id).creator != address(0);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenID() private view returns (uint256) {
        unchecked {
            return ERC1155Storage.layout().currentTokenId + 1;
        }
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenTypeId() private {
        unchecked {
            ++ERC1155Storage.layout().currentTokenId;
        }
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external validTokenID(id) onlyOwner {
        _burn(account, id, amount);
    }

    // Pause beforeTransfer for security
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setTokenData(
        ERC1155Storage.TokenStructure memory _tokenStructure,
        uint256 _id
    ) external validTokenID(_id) onlyOwner {
        ERC1155Storage.layout().tokenData[_id] = _tokenStructure;
    }

    // Opensea Compliance
    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC1155Base, IERC1155)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155Base, IERC1155) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory _amounts,
        bytes memory data
    ) public virtual override(ERC1155Base, IERC1155) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, _amounts, data);
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(
        uint256 value
    ) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /**
     * Get price for certain edition
     */
    function price(
        uint256 _id
    ) external view validTokenID(_id) returns (uint256) {
        return ERC1155Storage.tokenData(_id).price;
    }

    /**
     * Set price for certain edition
     */
    function setPrice(
        uint256 _id,
        uint256 _price
    ) external validTokenID(_id) onlyOwner {
        ERC1155Storage.layout().tokenData[_id].price = _price;
    }

    /** @dev Name/symbol needed for certain sites like OpenSea */
    function name() public view returns (string memory) {
        return ERC1155Storage.layout().name;
    }

    function symbol() public view returns (string memory) {
        return ERC1155Storage.layout().symbol;
    }

    function setName(string calldata _name) external onlyOwner {
        ERC1155Storage.layout().name = _name;
    }

    function setSymbol(string calldata _symbol) external onlyOwner {
        ERC1155Storage.layout().symbol = _symbol;
    }
}
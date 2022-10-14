// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: turcotte.eth

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtensionBasic.sol";

contract QUANTNFT_EXTENSION is CreatorExtensionBasic {
    address _creator_contract_address;
    address _owner_wallet_address;

    struct Token {
        string name;
        string uri;
        uint256 priceWei;
        uint256 invocations;
        uint256 maxInvocations;
        bool active;
        bool locked;
    }

    mapping(uint256 => Token) tokens;
    uint256[] _mintedTokens;

    event Minted(uint256 tokenId, uint256 amount);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(CreatorExtensionBasic)
        returns (bool)
    {
        return CreatorExtensionBasic.supportsInterface(interfaceId);
    }

    constructor(address creator, address owner) {
        require(
            ERC165Checker.supportsInterface(
                creator,
                type(IERC1155CreatorCore).interfaceId
            ),
            "creator must implement IERC1155CreatorCore"
        );

        _creator_contract_address = creator;
        _owner_wallet_address = owner;
    }

    function configureTokenMint(
        uint256 tokenId,
        string memory name,
        string memory uri,
        uint256 priceWei,
        uint256 maxInvocations,
        bool active,
        bool locked
    ) external adminRequired {
        if (!tokens[tokenId].locked) {
            tokens[tokenId].name = name;
            tokens[tokenId].uri = uri;
            tokens[tokenId].priceWei = priceWei;
            tokens[tokenId].maxInvocations = maxInvocations;
            tokens[tokenId].active = active;
            tokens[tokenId].locked = locked;
        }
    }

    function toggleActive(uint256 tokenId, bool active) external adminRequired {
        tokens[tokenId].active = active;
    }

    function mint(uint256 tokenId, uint256 amount) external payable {
        if (msg.value < tokens[tokenId].priceWei * amount) {
            revert("Not enought ether");
        }
        _mintNewOrExistingToken(msg.sender, tokenId, amount);
        payable(_owner_wallet_address).transfer(msg.value);
    }

    function _mintNewOrExistingToken(
        address address_to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (!tokens[tokenId].active) {
            revert("Token is not active");
        }
        if (
            tokens[tokenId].invocations + amount >
            tokens[tokenId].maxInvocations
        ) {
            revert("Max invocations reached");
        }
        if (tokens[tokenId].invocations == 0) {
            _mintNewToken(address_to, amount, tokens[tokenId].uri);
        } else {
            _mintExistingToken(address_to, tokenId, amount);
        }
        tokens[tokenId].invocations += amount;
        emit Minted(tokenId, amount);
    }

    function _mintNewToken(
        address to,
        uint256 amount,
        string memory uri
    ) internal {
        address[] memory tos = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        string[] memory uris = new string[](1);

        tos[0] = to;
        amounts[0] = amount;
        uris[0] = uri;

        uint256[] memory tokenIds = IERC1155CreatorCore(
            _creator_contract_address
        ).mintExtensionNew(tos, amounts, uris);
        _mintedTokens.push(tokenIds[0]);
    }

    function _mintExistingToken(
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        address[] memory tos = new address[](1);
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        tos[0] = to;
        tokenIds[0] = tokenId;
        amounts[0] = amount;

        IERC1155CreatorCore(_creator_contract_address).mintExtensionExisting(
            tos,
            tokenIds,
            amounts
        );
    }

    function mintedTokens() external view returns (uint256[] memory) {
        return _mintedTokens;
    }
}
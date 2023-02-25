// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/// @author: turcotte.eth

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtensionBasic.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ARTBYJARTHURDRAWINGS_EXTENSION is CreatorExtensionBasic {
    address _creator_contract_address;
    address _owner_wallet_address;
    address _artist_wallet_address;
    address _randomizer_address;

    uint256 _artist_percentage;
    string _base_uri;

    uint256 public constant MAX_TOKEN_ID = 100;
    uint256 public nb_tokens_configured = 92;
    uint256 public reveal_time;
    uint256 public nftPriceWei;
    uint256 public rollPriceWei;

    uint256 public currentRevealedIndex = 0;

    struct Token {
        uint256 revealed_until_timestamp;
        bool minted;
        uint256 base_token_id;
    }

    Token[MAX_TOKEN_ID] tokens;

    event Minted(uint256 tokenId, uint256 creatorTokenId);
    event DiceRolled(uint256 nb_to_reveal);
    error InvalidSignature();
    error NotIERC721CreatorCore();
    error InvalidEth();
    error InvalidTokenId();
    error NotRevealed();
    error AlreadyMinted();

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(CreatorExtensionBasic) returns (bool) {
        return CreatorExtensionBasic.supportsInterface(interfaceId);
    }

    constructor(
        address creator,
        address owner,
        address artist,
        uint256 artist_percentage,
        address randomizer_address
    ) {
        configure_contract(
            creator,
            owner,
            artist,
            artist_percentage,
            randomizer_address
        );
    }

    function configure_contract(
        address creator,
        address owner,
        address artist,
        uint256 artist_percentage,
        address randomizer_address
    ) public adminRequired {
        if (
            !ERC165Checker.supportsInterface(
                creator,
                type(IERC721CreatorCore).interfaceId
            )
        ) {
            revert NotIERC721CreatorCore();
        }

        _creator_contract_address = creator;
        _owner_wallet_address = owner;
        _artist_wallet_address = artist;
        _artist_percentage = artist_percentage;
        _randomizer_address = randomizer_address;
    }

    function rollDicePublic(
        uint256[] calldata token_ids_to_reveal,
        bytes calldata signature,
        uint256 newRevealedIndex
    ) external payable {
        if (msg.value != rollPriceWei) {
            revert InvalidEth();
        }
        _rollDice(token_ids_to_reveal, signature, newRevealedIndex);
    }

    function rollDiceAdmin(
        uint256[] calldata token_ids_to_reveal,
        bytes calldata signature,
        uint256 newRevealedIndex
    ) external adminRequired {
        _rollDice(token_ids_to_reveal, signature, newRevealedIndex);
    }

    function _rollDice(
        uint256[] calldata token_ids_to_reveal,
        bytes calldata signature,
        uint256 newRevealedIndex
    ) internal {
        // check that the signature is valid
        if (
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(
                        abi.encodePacked(
                            token_ids_to_reveal,
                            currentRevealedIndex
                        )
                    )
                ),
                signature
            ) != _randomizer_address
        ) {
            revert InvalidSignature();
        }

        uint256 new_timestamp = block.timestamp + reveal_time;

        for (uint256 i = 0; i < token_ids_to_reveal.length; i++) {
            tokens[token_ids_to_reveal[i]]
                .revealed_until_timestamp = new_timestamp;
        }

        currentRevealedIndex = newRevealedIndex;

        emit DiceRolled(token_ids_to_reveal.length);
    }

    function configureMint(
        uint256 nftPriceWei_temp,
        uint256 rollPriceWei_temp,
        string memory base_uri,
        uint256 reveal_time_temp
    ) external adminRequired {
        nftPriceWei = nftPriceWei_temp;
        rollPriceWei = rollPriceWei_temp;
        _base_uri = base_uri;
        reveal_time = reveal_time_temp;
    }

    function giveaway(
        address receiver,
        uint256 tokenId
    ) external adminRequired {
        _mintToken(receiver, tokenId);
    }

    function mint(uint256 tokenId) external payable {
        if (msg.value != nftPriceWei) {
            revert InvalidEth();
        }
        if (tokens[tokenId].revealed_until_timestamp < block.timestamp) {
            revert NotRevealed();
        }
        if (tokenId > nb_tokens_configured - 1) {
            revert InvalidTokenId();
        }
        _mintToken(msg.sender, tokenId);
    }

    function _mintToken(address address_to, uint256 tokenId) internal {
        if (tokenId > MAX_TOKEN_ID - 1) {
            revert InvalidTokenId();
        }
        if (tokens[tokenId].minted) {
            revert AlreadyMinted();
        }
        string memory token_id_string = Strings.toString(tokenId + 1);
        string memory uri = string.concat(_base_uri, token_id_string);
        uint256 creatorTokenId = IERC721CreatorCore(_creator_contract_address)
            .mintExtension(address_to, uri);
        tokens[tokenId].minted = true;
        tokens[tokenId].base_token_id = creatorTokenId;
        emit Minted(tokenId, creatorTokenId);
    }

    function withdraw() external adminRequired {
        uint256 balance = address(this).balance;
        uint256 artist_cut = (balance * _artist_percentage) / 100;
        uint256 owner_cut = balance - artist_cut;
        payable(_artist_wallet_address).transfer(artist_cut);
        payable(_owner_wallet_address).transfer(owner_cut);
    }

    function getTokens() external view returns (Token[] memory) {
        Token[] memory tokens_temp = new Token[](MAX_TOKEN_ID);
        for (uint256 i = 0; i < MAX_TOKEN_ID; i++) {
            tokens_temp[i] = tokens[i];
        }
        return tokens_temp;
    }

    function get_token(
        uint256 tokenId
    ) external view returns (uint256, bool, uint256) {
        return (
            tokens[tokenId].revealed_until_timestamp,
            tokens[tokenId].minted,
            tokens[tokenId].base_token_id
        );
    }
}
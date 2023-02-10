// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/********************************************************************************************************************************************************
 *     _________  ___  ___  _______           _________  ___  _____ ______   _______           ___  ________           ________  ________  ________
 *    |\___   ___\\  \|\  \|\  ___ \         |\___   ___\\  \|\   _ \  _   \|\  ___ \         |\  \|\   ____\         |\   ___ \|\   __  \|\   __  \
 *    \|___ \  \_\ \  \\\  \ \   __/|        \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|        \ \  \ \  \___|_        \ \  \_|\ \ \  \|\  \ \  \|\  \
 *         \ \  \ \ \   __  \ \  \_|/__           \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__       \ \  \ \_____  \        \ \  \ \\ \ \   __  \ \  \\\  \
 *          \ \  \ \ \  \ \  \ \  \_|\ \           \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \       \ \  \|____|\  \        \ \  \_\\ \ \  \ \  \ \  \\\  \
 *           \ \__\ \ \__\ \__\ \_______\           \ \__\ \ \__\ \__\    \ \__\ \_______\       \ \__\____\_\  \        \ \_______\ \__\ \__\ \_______\
 *            \|__|  \|__|\|__|\|_______|            \|__|  \|__|\|__|     \|__|\|_______|        \|__|\_________\        \|_______|\|__|\|__|\|_______|
 *                                                                                                    \|_________|
 ********************************************************************************************************************************************************
 ********************************************************************************************************************************************************
 ********************************************************************************************************************************************************
 * PROJECT: @TheTimeIs_DAO
 * FOUNDER: @rebekah_bastian
 * ART: @Habibagreen
 * DEV: @ghooost0x2a
 **********************************
 * @title: The Time is DAO
 * @author: @ghooost0x2a
 **********************************
 * ERC721B - Ultra Low Gas
 *****************************************************************
 * ERC721B2FA is based on ERC721B low gas contract by @squuebo_nft
 *****************************************************************
 */

import "./ERC721B2FAEnumLitePausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheTimeIsDAO is ERC721B2FAEnumLitePausable {
    using MerkleProof for bytes32[];
    using Address for address;
    using Strings for uint256;

    event Withdrawn(address indexed payee, uint256 weiAmount);

    uint256 public MAX_SUPPLY = 10000;
    bool public MINT_OPEN = false;

    string internal baseURI = "";
    string internal uriSuffix = "";

    address public paymentRecipient = address(0);

    bytes32 private merkleRoot = 0;

    mapping(address => bool) public has_minted;

    constructor() ERC721B2FAEnumLitePausable("The Time is DAO", "TTDAO", 1) {}

    fallback() external payable {}

    receive() external payable {}

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), uriSuffix)
                )
                : "";
    }

    function getMerkleRoot() public view onlyDelegates returns (bytes32) {
        return merkleRoot;
    }

    function setMerkleRoot(bytes32 mRoot) external onlyDelegates {
        merkleRoot = mRoot;
    }

    function isvalidMerkleProof(bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        if (merkleRoot == 0) {
            return false;
        }
        bool proof_valid = proof.verify(
            merkleRoot,
            keccak256(abi.encodePacked(msg.sender))
        );
        return proof_valid;
    }

    function setBaseSuffixURI(
        string calldata newBaseURI,
        string calldata newURISuffix
    ) external onlyDelegates {
        baseURI = newBaseURI;
        uriSuffix = newURISuffix;
    }

    function toggleMint(bool mint_open) external onlyDelegates {
        MINT_OPEN = mint_open;
    }

    function setPaymentRecipient(address addy) external onlyOwner {
        paymentRecipient = addy;
    }

    function setReducedMaxSupply(uint256 new_max_supply) external onlyOwner {
        require(new_max_supply < MAX_SUPPLY, "Can only set a lower size.");
        require(
            new_max_supply >= totalSupply(),
            "New supply lower than current totalSupply"
        );
        MAX_SUPPLY = new_max_supply;
    }

    // Mint fns
    function freeTeamMints(uint256 quantity, address[] memory recipients)
        external
        onlyDelegates
    {
        if (recipients.length == 1) {
            for (uint256 i = 0; i < quantity; i++) {
                _minty(1, recipients[0]);
            }
        } else {
            require(
                quantity == recipients.length,
                "Number of recipients doesn't match quantity."
            );
            for (uint256 i = 0; i < recipients.length; i++) {
                _minty(1, recipients[i]);
            }
        }
    }

    // Mint
    function daoMint(bytes32[] memory proof) external payable {
        require(MINT_OPEN || _isDelegate(_msgSender()), "Mint not open yet!");
        require(isvalidMerkleProof(proof), "You are not authorized to mint!");
        require(has_minted[_msgSender()] != true, "You already minted!");

        has_minted[_msgSender()] = true;
        _minty(1, _msgSender());
    }

    function _minty(uint256 quantity, address addy) internal {
        require(quantity > 0, "Can't mint 0 tokens!");
        require(quantity + totalSupply() <= MAX_SUPPLY, "Max supply reached!");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(addy, next());
        }
    }

    //Just in case some ETH ends up in the contract so it doesn't remain stuck.
    function withdraw() external onlyDelegates {
        require(
            paymentRecipient != address(0),
            "Don't send ETH to null address"
        );
        uint256 contract_balance = address(this).balance;

        address payable w_addy = payable(paymentRecipient);

        (bool success, ) = w_addy.call{value: (contract_balance)}("");
        require(success, "Withdrawal failed!");

        emit Withdrawn(w_addy, contract_balance);
    }
}
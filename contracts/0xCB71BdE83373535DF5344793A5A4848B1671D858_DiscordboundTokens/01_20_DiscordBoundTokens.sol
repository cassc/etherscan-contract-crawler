// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 *
 * _______/\\\\\_______/\\\\\\\\\\\\\____/\\\\\\\\\\\\\\\__/\\\\\_____/\\\_____/\\\\\\\\\\__
 *  _____/\\\///\\\____\/\\\/////////\\\_\/\\\///////////__\/\\\\\\___\/\\\___/\\\///////\\\_
 *   ___/\\\/__\///\\\__\/\\\_______\/\\\_\/\\\_____________\/\\\/\\\__\/\\\__\///______/\\\__
 *    __/\\\______\//\\\_\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\_____\/\\\//\\\_\/\\\_________/\\\//___
 *     _\/\\\_______\/\\\_\/\\\/////////____\/\\\///////______\/\\\\//\\\\/\\\________\////\\\__
 *      _\//\\\______/\\\__\/\\\_____________\/\\\_____________\/\\\_\//\\\/\\\___________\//\\\_
 *       __\///\\\__/\\\____\/\\\_____________\/\\\_____________\/\\\__\//\\\\\\__/\\\______/\\\__
 *        ____\///\\\\\/_____\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\___\//\\\\\_\///\\\\\\\\\/___
 *         ______\/////_______\///______________\///////////////__\///_____\/////____\/////////_____
 *          1155V1___________________________________________________________________________________
 *
 */

import "contracts/BaseToken/BaseTokenV2.sol";
import "contracts/BaseToken/BaseERC1155V1.sol";
import "contracts/Mixins/ERC1155AuthorizerV1.sol";

/**
 * @title Discordbound Tokens ERC1155 Smart Contract
 */
contract DiscordboundTokens is BaseERC1155V1, BaseTokenV2, ERC1155AuthorizerV1 {
    uint256 public constant MINT_LIMIT_PER_ADDRESS = 1;
    uint256 public constant PRICE = 0 ether;

    mapping(uint256 => bool) public qualifiedNonceList;
    mapping(uint256 => mapping(address => uint256)) public qualifiedWalletList;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory uri_,
        address authorizerAddress_
    )
        ERC1155(uri_)
        BaseTokenV2(contractURI_)
        ERC1155AuthorizerV1(authorizerAddress_)
    {
        _name = name_;
        _symbol = symbol_;
    }

    function qualifiedMint(
        uint256 id_,
        uint256 amount_,
        bytes memory signature_,
        uint256 nonce_
    ) external payable nonReentrant onlySaleIsActive {
        require(!qualifiedNonceList[nonce_], "Access nonce not owned");
        require(
            qualifiedWalletList[id_][msg.sender] + amount_ <=
                MINT_LIMIT_PER_ADDRESS,
            "Minting limit exceeded"
        );
        require(PRICE * amount_ <= msg.value, "Insufficient payment");

        requireRecovery(msg.sender, nonce_, id_, signature_);

        qualifiedNonceList[nonce_] = true;
        qualifiedWalletList[id_][msg.sender] += amount_;

        _mint(msg.sender, id_, amount_, "");
    }

    /**
     * @dev Owner of the contract can mints to the address based on the amount and id.
     */
    function ownerMint(
        address address_,
        uint256 id_,
        uint256 amount_
    ) external onlyOwner {
        _mint(address_, id_, amount_, "");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        // Ignore transfers during minting
        if (from == address(0)) {
            return;
        }
        // Ignore transfers during burning
        if (to == address(0)) {
            return;
        }
        require(from == to, "ERC1155Soulbound: Cannot transfer tokens.");
    }

    function burn(
        address from_,
        uint256 id_,
        uint256 amount_
    ) external {
        require(
            from_ == _msgSender() || isApprovedForAll(from_, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(from_, id_, amount_);
    }
}
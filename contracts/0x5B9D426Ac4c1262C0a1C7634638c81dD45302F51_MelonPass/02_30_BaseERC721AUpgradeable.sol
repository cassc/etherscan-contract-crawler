// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC721AUpgradeable, ERC721AUpgradeable} from "../erc721a/ERC721AUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from
    "../erc721a/ERC721AQueryableUpgradeable.sol";
import {ERC721ABurnableUpgradeable} from
    "../erc721a/ERC721ABurnableUpgradeable.sol";
import "../helpers/DefaultOperatorFiltererUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    IERC2981Upgradeable,
    ERC2981Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract BaseERC721AUpgradeable is
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ReentrancyGuardUpgradeable
{
    bool public operatorFilteringEnabled;

    function __BaseERC721AUpgradeable_init(string memory name, string memory symbol) internal onlyInitializing {
        __ERC721A_init(name, symbol);
        __Ownable_init();
        __ERC2981_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();

        operatorFilteringEnabled = true;
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721AUpgradeable.supportsInterface(interfaceId)
            || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdrawERC20(IERC20 erc20Token) external onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function withdrawERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
        erc721Token.safeTransferFrom(address(this), msg.sender, id);
    }

    function withdrawERC1155(
        address erc1155Token,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        IERC1155(erc1155Token).safeTransferFrom(
            address(this),
            msg.sender,
            id,
            amount,
            ""
        );
    }

    function withdrawEarnings(address to, uint256 balance) external onlyOwner {
        payable(to).transfer(balance);
    }
}
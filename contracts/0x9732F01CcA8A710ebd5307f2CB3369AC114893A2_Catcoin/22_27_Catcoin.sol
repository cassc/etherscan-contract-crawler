// SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;

import { ERC721AUpgradeable } from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { ERC721AQueryableUpgradeable } from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import { CatcoinStorage } from "./CatcoinStorage.sol";
import { ICatcoin } from "./ICatcoin.sol";
import { ICats } from "../cats/ICats.sol";
import { DiamondOwnable } from "../acl/DiamondOwnable.sol";
import { ReentrancyGuard } from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import { IAnima } from "../anima/IAnima.sol";

contract Catcoin is ERC721AUpgradeable, ERC721AQueryableUpgradeable, DiamondOwnable, ReentrancyGuard, ICatcoin {
    uint256 constant CATCOIN_PER_CATS = 21;

    function initialize() public initializerERC721A {
        __ERC721A_init("Catcoin", "CATC");
    }

    function setCatsContract(IERC721AUpgradeable cats) external onlyOwner {
        CatcoinStorage.layout().cats = cats;
    }

    function setAnimaContract(IAnima anima) external onlyOwner {
        CatcoinStorage.layout().anima = anima;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        CatcoinStorage.layout().baseURI = baseURI;
    }

    function exchangeCat(uint256 catId) external override nonReentrant {
        IERC721AUpgradeable cats = CatcoinStorage.layout().cats;
        if (cats.ownerOf(catId) != msg.sender) revert WrongCatOwner();
        cats.transferFrom(msg.sender, address(this), catId);
        CatcoinStorage.layout().originatingId[totalSupply() / CATCOIN_PER_CATS] = uint16(catId);
        _mint(msg.sender, CATCOIN_PER_CATS);
        IAnima anima = CatcoinStorage.layout().anima;
        anima.mint(msg.sender, catId);
    }

    function daoMint(address recipient, uint256 amount) external onlyOwner {
        IERC721AUpgradeable cats = CatcoinStorage.layout().cats;
        uint256 intialCatId = cats.totalSupply();
        ICats(address(cats)).mint(address(this), amount);
        uint256 intialCatcoinId = totalSupply() / CATCOIN_PER_CATS;
        for (uint256 i = 0; i < amount; i++) {
            CatcoinStorage.layout().originatingId[intialCatcoinId++] = uint16(intialCatId++);
        }
        _mint(recipient, CATCOIN_PER_CATS * amount);
    }

    function moveCatTo(address recipient, uint256 catId) external override onlyOwner {
        IERC721AUpgradeable cats = CatcoinStorage.layout().cats;
        cats.transferFrom(address(this), recipient, catId);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external nonReentrant {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; ) {
            safeTransferFrom(from, to, tokenIds[i], "");
            unchecked {
                i += 1;
            }
        }
    }

    // ============================= VIEWS =============================

    function _baseURI() internal view virtual override returns (string memory) {
        return CatcoinStorage.layout().baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        uint16 originatingId = CatcoinStorage.layout().originatingId[tokenId / CATCOIN_PER_CATS];
        string memory baseURI = _baseURI();
        string memory result = string(abi.encodePacked(baseURI, _toString(originatingId), ".json"));
        return bytes(baseURI).length != 0 ? result : "";
    }
}
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../core/SemanticSBTUpgradeable.sol";
import "../interfaces/social/INameService.sol";
import "../template/NameService.sol";
import {SemanticSBTLogicUpgradeable} from "../libraries/SemanticSBTLogicUpgradeable.sol";
import {NameServiceLogic} from "../libraries/NameServiceLogic.sol";


contract RelationProfileNFT is SemanticSBTUpgradeable, NameService, PausableUpgradeable {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;



    function initialize(
        string memory suffix_,
        string memory name_,
        string memory symbol_,
        string memory schemaURI_,
        string[] memory classes_,
        Predicate[] memory predicates_
    ) public override initializer {
        __Pausable_init_unchained();
        super.initialize(suffix_, name_, symbol_, schemaURI_, classes_, predicates_);
    }


    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() public {
        payable(owner()).transfer(address(this).balance);
    }

    function register(address owner, string calldata name, bool resolve) external override(NameService) whenNotPaused onlyMinter returns (uint tokenId) {
        return super._register(owner, name, resolve);
    }

    function register(string calldata name, uint256 deadline, uint256 _mintCount, uint256 price, bytes memory signature) external whenNotPaused payable returns (uint tokenId) {
        require(_mintCount == 0 || getMinted() < _mintCount, "NameService: error mint count");
        require(msg.value >= price, "NameService: insufficient value");
        require(_minters[NameServiceLogic.recoverAddress(address(this), msg.sender, name, deadline, _mintCount, price, signature)], "NameService: invalid signature");
        return super._register(msg.sender, name, false);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(NameService, SemanticSBTUpgradeable)
    returns (string memory)
    {

        return super.tokenURI(tokenId);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(NameService, SemanticSBTUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(NameService, ERC721Upgradeable) virtual {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(NameService, ERC721Upgradeable) virtual {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }
}
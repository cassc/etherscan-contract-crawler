// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import 'erc721a/contracts/ERC721A.sol';
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract HoshiboshiAriesCoupon is ERC1155, Ownable, DefaultOperatorFilterer {

    IERC721A public immutable aries;
    uint[] public ariesTokenIds;
    mapping(uint => bool) public ariesTokenIdsMap;

    string _name;
    string _symbol;

    constructor() ERC1155("https://arweave.net/LVpq7UifkD19phdg8tlbGraW0FEzC6Vrn3w-qsgdx4A/") {
        aries = IERC721A(0x7614632d063fb1f335b36c612f8DFC52E5c62420);
        _name = 'HoshiboshiAriesCoupon';
        _symbol = 'HoshiboshiAriesCoupon';
    }

    function updateNameAndSymbol(string memory name_, string memory symbol_) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        _setURI(baseURI_);
    }

    function mint(address[] calldata to, uint256[] calldata amounts) public virtual onlyOwner {
        for (uint i = 0; i < to.length; i++) {
            _mint(to[i], 0, amounts[i], new bytes(0));
        }
    }

    function requestUpgradeAriesMetaData(uint tokenId) public {
        require(aries.ownerOf(tokenId) == msg.sender, 'Only Owner!');
        require(ariesTokenIdsMap[tokenId] != true, 'Already requested!');
        safeTransferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, 0, 1, new bytes(0));
        unchecked {}
        ariesTokenIds.push(tokenId);
        ariesTokenIdsMap[tokenId] = true;
    }

    function getNeedUpgradeMetadataAriesTokenIds() public view returns (uint[] memory _ariesTokenIds) {
        _ariesTokenIds = ariesTokenIds;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
}
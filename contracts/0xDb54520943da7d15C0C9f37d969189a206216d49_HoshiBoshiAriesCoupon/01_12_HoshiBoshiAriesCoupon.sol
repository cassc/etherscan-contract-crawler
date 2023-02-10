// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import 'erc721a/contracts/ERC721A.sol';

contract HoshiBoshiAriesCoupon is ERC1155, Ownable {

    IERC721A public immutable aries;
    uint[] public ariesTokenIds;
    mapping(uint => bool) public ariesTokenIdsMap;

    constructor() ERC1155("https://arweave.net/LVpq7UifkD19phdg8tlbGraW0FEzC6Vrn3w-qsgdx4A/") {
        aries = IERC721A(0x7614632d063fb1f335b36c612f8DFC52E5c62420);
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
}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

//                   .
//
//                    *
//                  .
//    o
//     \_/\o       O
//    ( Oo)          .
//    (_=-)        *  O
//    /   \              .
//    ||  |\_        o
//    \\  |\.=     o   *
//    {K  |      _________
//     | PP    c(`       ')o
//     | ||      \.     ,/
//     (__\\    _//^---^\\_

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract SerumAirdrop is ERC721A, Ownable {
    uint256 public count;
    uint256 public supply;
    string public baseTokenURI;
    bool public isAirdropLive;
    address public ownerAddr;

    constructor() ERC721A("Genesis Voice Serum", "GVS") {
        supply = 8888;
        count = 0;
        ownerAddr = msg.sender;
    }

    event airdropLiveLog(bool live);
    event burnLog(uint256 tokenId, address owner);

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    //================================================================================//
    function mint(uint256 quantity) external checkSupply(quantity) onlyOwner {
        _mint(msg.sender, quantity);
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function bulkAirdrop(
        address[] calldata holders,
        uint256[] calldata tokenAmount
    ) public payable checkStock(tokenAmount) onlyOwner {
        require(isAirdropLive, "Not Live");

        uint256 _count = count;

        for (uint256 i = 0; i < holders.length; i++) {
            for (uint256 j = 0; j < tokenAmount[i]; j++) {
                safeTransferFrom(msg.sender, holders[i], _count);
                _count++;
            }
        }
        count = _count;
    }

    function toggleAirdropLive() external onlyOwner {
        bool isLive = !isAirdropLive;
        isAirdropLive = isLive;
        emit airdropLiveLog(isAirdropLive);
    }

    modifier checkSupply(uint256 quantity) {
        if (_nextTokenId() == 0) {
            require(totalSupply() + quantity < supply, "Exceed supply");
        } else {
            require(totalSupply() - 1 + quantity < supply, "Exceed supply");
        }
        _;
    }

    modifier checkStock(uint256[] calldata tokenAmount) {
        uint256 sum = 0;
        for (uint256 i = 0; i < tokenAmount.length; i++) {
            sum = sum + tokenAmount[i];
        }
        require(sum <= balanceOf(ownerAddr), "Exceed Stock");

        _;
    }

    //================================================================================//

    function burn(uint256 tokenId) external {
        require(getOwnerOf(tokenId) == msg.sender, "Not owner");
        _burn(tokenId);
        emit burnLog(tokenId, msg.sender);
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    //================================================================================//

    function getOwnerOf(uint256 tokenId) public view returns (address) {
        return ownerOf(tokenId);
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 holdingAmount = balanceOf(owner);
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        uint256[] memory list = new uint256[](holdingAmount);

        unchecked {
            for (uint256 i; i < count; i++) {
                TokenOwnership memory ownership = _ownershipAt(i);

                if (ownership.burned) {
                    continue;
                }

                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }

                if (currOwnershipAddr == owner) {
                    list[tokenIdsIdx++] = i;
                }

                if (tokenIdsIdx == holdingAmount) {
                    break;
                }
            }
        }

        return list;
    }
}
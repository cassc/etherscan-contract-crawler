// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/interfaces/IERC721AQueryable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface z00tzAnchorClub {
    function safeMint(address, uint256) external;
    function safeBurn(uint256) external;
    function ownerOf(uint256 tokenId) external returns (address);
}

interface YachtClub is IERC721A {
    
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

}

contract z00tzMagnumWrapper is IERC721Receiver, Ownable, ReentrancyGuard {

    mapping(address => mapping(uint256 => bool)) public owners;
    
    bool public unwrapActive;
    bool public wrapActive;



    YachtClub YClub;
    z00tzAnchorClub AClub;

    constructor(YachtClub _YClub, z00tzAnchorClub _AClub) {

        YClub = _YClub;
        AClub = _AClub;

    }

    function _msgSenderERC721A() internal view returns (address) {
        return msg.sender;
    } 

    function toggleUnwrap() public onlyOwner {
        unwrapActive = !unwrapActive;
    }

    function togglewrap() public onlyOwner {
        wrapActive = !wrapActive;
    }

    function _getNextUnusedID(address _owner, uint256[] memory _ownedTokens) internal view returns (uint256 index) {

        for (uint256 i = 0; i < _ownedTokens.length; i++) {
            index = _ownedTokens[i];
            if (owners[_owner][index]) {
                continue;
            } else {
                return index;
            }
        }
    }

    function _gety00tArray(address _owner) public view returns(uint256[] memory) {
        
        uint256 numY00ts = YClub.balanceOf(_owner);
        
        if (numY00ts == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](numY00ts);
            for (uint256 i = 0; i < numY00ts; i++) {
                result[i] = YClub.tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
  }


    function z00t(uint256[] memory tokenIds) public nonReentrant {
        for (uint256 i = 0; i< tokenIds.length; i++){
            uint256 tokenId = tokenIds[i];
            require(wrapActive, "Wrap not z00tin, yet...too much girth");
            YClub.safeTransferFrom(_msgSenderERC721A(), address(this), tokenId);
            AClub.safeMint(_msgSenderERC721A(), tokenId );
        }

    }

    function unz00t(uint256[] memory tokenIds) public nonReentrant {
        for (uint256 i = 0; i< tokenIds.length; i++){
            uint256 tokenId = tokenIds[i];
            require(unwrapActive, "unWrap not z00tin");
            require(AClub.ownerOf(tokenId) == _msgSenderERC721A(), "z00tz don't own this");
            YClub.safeTransferFrom(address(this), _msgSenderERC721A(), tokenId);
            AClub.safeBurn(tokenId);
            }
    }

    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}
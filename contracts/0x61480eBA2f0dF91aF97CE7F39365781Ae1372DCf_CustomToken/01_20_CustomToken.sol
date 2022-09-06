// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { LibDiamond } from  "../libraries/LibDiamond.sol";
import '@solidstate/contracts/token/ERC721/enumerable/ERC721Enumerable.sol';
import "../libraries/MyNFTTokenLibrary.sol";
import { AppStorage } from "../libraries/LibAppStorage.sol";
import { ERC721Base } from '@solidstate/contracts/token/ERC721/base/ERC721Base.sol';
import { ERC721BaseStorage } from '@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol';
import { ERC165 } from '@solidstate/contracts/introspection/ERC165.sol';

contract CustomToken is ERC721Enumerable, ERC721Base {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using MyNFTTokenLibrary for uint8;

    AppStorage private s;

    function supportsInterface(bytes4 _interfaceId) external override pure returns (bool) {
        return true;
    }

    function mintInternal(string memory base64Image) internal {
        uint256 _totalSupply = totalSupply();
        uint256 thisTokenId = _totalSupply;
        s.tokenIdToImage[thisTokenId] = base64Image;
        _mint(msg.sender, thisTokenId);
    }

    function mint(string memory base64Image) onlyOwner public {
        return mintInternal(base64Image);
    }

   /**
     * @dev Toggle between render modes, gif or svg.
     *
     * @param _tokenId The tokenId to return the base64 image for.
     */
    function toggleRenderMode(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);
        s.tokenIdToToggleGif[_tokenId] = !s.tokenIdToToggleGif[_tokenId];
    }

   /**
     * @dev Get render modes, true for gif or false for svg.
     *
     * @param _tokenId The tokenId to get the render mode for.
     */
    function getRenderMode(uint256 _tokenId) view public returns (bool) {
      if (s.tokenIdToToggleGif[_tokenId]) {
        return true;
      } else {
        return false;
      }
    }

   /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        require(ERC721BaseStorage.layout().exists(_tokenId));

        string memory thisName = s.name;

        string memory name = string(abi.encodePacked("", thisName, " #", MyNFTTokenLibrary.toString(_tokenId)));
        string memory bio = string(abi.encodePacked("Stored 100% on-chain. ", s.name, " #", MyNFTTokenLibrary.toString(_tokenId)));

        string memory image;

        if (s.tokenIdToToggleGif[_tokenId]) {
            image = tokenIdToGif(_tokenId);
        } else {
            image = tokenIdToSVG(_tokenId);
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    MyNFTTokenLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    name,
                                    '", "description": "',
                                    bio,
                                    '","image": "',
                                    image,
                                    '","attributes": [{"trait_type":"TYPE", "value": "1 OF 1"}]',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function tokenIdToGif(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked("data:image/gif;base64,", s.tokenIdToImage[_tokenId]));
    }


     /**
     * @dev tokenId to SVG function
     */
    function tokenIdToSVG(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                MyNFTTokenLibrary.encode(
                    bytes(abi.encodePacked(
                      '<svg id="svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 1560 1560"><image height="1560" width="1560" href="',
                      tokenIdToGif(_tokenId),
                      '" style="image-rendering:pixelated;"/></svg>'
                    ))
                )
            )
        );
    }


   modifier onlyOwner() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.contractOwner == msg.sender, "only owner");
        _;
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = _balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../util/Ownablearama.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract GoldNugget is ERC721, Ownablearama {
    address public immutable forge;

    IERC1155 public immutable treats;
    uint256 public immutable goldNuggetTreatTokenId;

    uint256 public numMinted;

    string public uri;

    constructor(
        address _forge,
        IERC1155 _treats,
        uint256 _goldNuggetTreatTokenId,
        string memory _uri
    ) ERC721("GoldNugget", "GOLD") {
        forge = _forge;
        treats = _treats;
        goldNuggetTreatTokenId = _goldNuggetTreatTokenId;
        uri = _uri;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator) || operator == forge;
    }

    function mint() external {
        // "burn" the treat token
        treats.safeTransferFrom(
            msg.sender,
            address(0x000000000000000000000000000000000000dEaD),
            goldNuggetTreatTokenId,
            1,
            ""
        );

        uint256 tokenIdToMint = numMinted;
        numMinted++;

        _safeMint(msg.sender, tokenIdToMint);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // all tokens are the same
        return uri;
    }

    function setURI(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    function rescueERC721(
        address token,
        uint256 tokenId,
        address receiver
    ) external onlyOwner {
        IERC721(token).safeTransferFrom(address(this), receiver, tokenId);
    }

    function rescueERC1155(
        address token,
        uint256 tokenId,
        uint256 quantity,
        bytes memory data,
        address receiver
    ) external onlyOwner {
        IERC1155(token).safeTransferFrom(
            address(this),
            receiver,
            tokenId,
            quantity,
            data
        );
    }
}
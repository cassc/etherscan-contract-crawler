// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "@erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HyperNFT_HOS is ERC721A, Ownable {
    string public baseURI;

    constructor() ERC721A("HyperNFT_HOS_1.0", "HHOS1") {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function bulkMint(address[] calldata recipients, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(recipients.length == amounts.length, "length not match");
        for (uint256 i; i < recipients.length; ++i) {
            _mint(recipients[i], amounts[i]);
        }
    }

    function batchTransfer(address recipient, uint256[] calldata tokenIds)
        external
    {
        for (uint256 i; i < tokenIds.length; ++i) {
            transferFrom(msg.sender, recipient, tokenIds[i]);
        }
    }

    function batchTransfer2(
        address[] calldata recipients,
        uint256[] calldata amountPerRecipient,
        uint256[] calldata tokenIds
    )
        external
    {
        require(recipients.length == amountPerRecipient.length, "length not match");
        uint256 tokenIdOffset;
        for (uint256 i; i < recipients.length; ++i) {
            for (uint256 k; k < amountPerRecipient[i]; ++k) {
                transferFrom(msg.sender, recipients[i], tokenIds[tokenIdOffset]);
                ++tokenIdOffset;
            }
        }
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token id not exist");
        return
            bytes(baseURI).length > 0
                ? string.concat(baseURI, Strings.toString(tokenId))
                : "";
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
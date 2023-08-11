// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract PowerWeb3Hongkong is ERC721("Power Web3 Hongkong", "PowerWeb3"), Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public totalSupply;
    string private baseURI_ = "ipfs://Qmc2aY3xVGLsPMfv6bvibP5tfw7xgAdEvkaqK9A1HFv8oQ/";
    uint256 private constant MASK_160 = ((1 << 160) - 1);

    function mint(address to, uint256 tokenId) external onlyOwner {
        unchecked {
            _mint(to, tokenId);
            totalSupply++;
        }
    }

    function batchMint(uint256[] calldata infos) external onlyOwner {
        unchecked {
            uint256 l = infos.length;
            for (uint256 i; i < l; i++) {
                _mint(address(uint160(infos[i] & MASK_160)), (infos[i] >> 160));
            }
            totalSupply += l;
        }
    }

    function tokenURI(uint256 tokenId) public override view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory uri = _baseURI();
        if (bytes(uri).length > 0) {
            if (tokenId > 99) {
                return string(abi.encodePacked(uri, tokenId.toString(), ".json"));
            }
            if (tokenId > 9) {
                return string(abi.encodePacked(uri, "0", tokenId.toString(), ".json"));
            }
            return string(abi.encodePacked(uri, "00", tokenId.toString(), ".json"));
        } else {
            return "";
        }
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI_ = uri;
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return baseURI_;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
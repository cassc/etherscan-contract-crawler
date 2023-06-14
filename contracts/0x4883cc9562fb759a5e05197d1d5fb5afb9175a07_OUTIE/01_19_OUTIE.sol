//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract OUTIE is
    ERC721,
    ERC2981,
    Ownable,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    string private _baseTokenURI;
    uint256 private _nextTokenId = 0;

    constructor() ERC721("IAM_OUTIE", "OUTIE") {
        _setDefaultRoyalty(owner(), 1000);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return string(abi.encodePacked(ERC721.tokenURI(_tokenId), ".json"));
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _nextTokenId;
    }

    function mint(uint256 _quantity, address _address)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _quantity;) {
            _safeMint(_address, _nextTokenId);
            unchecked {
                ++_nextTokenId;
                ++i;
            }
        }
    }

    // only owner
    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }


    // OperatorFilterer
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Royality
    function setRoyalty(address _royaltyAddress, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC721.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}
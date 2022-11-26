// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract UpgradedPet is ERC721A, Ownable, DefaultOperatorFilterer {
    address public distributor;
    string public baseURI;
    uint256 public TOTAL_SUPPLY;
    uint256 public currentTokenId = 1;

    constructor() ERC721A("UpgradedPet", "UpgradedPet") {}
    event UpgradeMint(uint256 indexed _upgradedId, uint256 _petType, uint256 _oldTokenId, uint256 _serumCount);

    // ==== MINT ====

    function teamMint(uint256 quantity) external onlyOwner {
        _mint(msg.sender, quantity);
    }

    function mint(uint256[][3] calldata _tokenIds, address _minter, uint256 _serumCount) external {
        require(msg.sender == distributor, "Not authorised to call");
        uint256 totalQuantity;

        for (uint i = 0; i < _tokenIds.length; i++) {
            totalQuantity += _tokenIds[i].length;
            for (uint j = 0; j < _tokenIds[i].length; j++) {
                emit UpgradeMint(currentTokenId, i, _tokenIds[i][j], _serumCount);
                currentTokenId++;
            }
        }
        _mint(_minter, totalQuantity);
    }

    // ==== SETTERS ====

    function setDistributor(address _address) public onlyOwner {
        distributor = _address;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    // ==== OPENSEA OVERRIDES ====

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ===== UTILS =====

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }
}
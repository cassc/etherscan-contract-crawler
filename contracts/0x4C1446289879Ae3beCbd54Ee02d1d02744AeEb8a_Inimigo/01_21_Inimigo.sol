// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";
import "ERC721A.sol";

contract Inimigo is DefaultOperatorFilterer, ERC721A, Ownable {
    using Address for address;
    using Strings for uint256;

    string private baseURI;
    string private baseExtension = ".json";
    uint256 public maxSupply = 500;
    bool private paused = false;

    string private _contractUri;

    address _contractOwner;

    uint256[] tokenIds;

    constructor() ERC721A("Brazuera - O INIMIGO", "INIMIGO") {
        setBaseURI("https://ipfs.io/ipfs/QmdYJKMFVubttXDSrr7v91Ssz3yb3sYVkXvY2qWJeeB4qH/");
        _contractUri = "https://ipfs.io/ipfs/QmNQxwjn1xnic8SXsiREcczPmxP9vkyV8wjEyzvGrznrZJ";
        _contractOwner = msg.sender;
    } 

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function isPaused() public view returns (bool) {
        return paused;
    }

    function AirDrop(
        address[] memory endUser
    ) public onlyOwner {
        require(!paused, "O contrato pausado");
        require(totalSupply() < maxSupply, "SoldOut");
        tokenIds = new uint256[](endUser.length);

        for (uint i = 0; i < endUser.length; i++) {
            _safeMint(endUser[i], 1);
        }
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractUri = contractURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

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

    function destroy() public onlyOwner {
        require(msg.sender == _contractOwner, "Only the owner can destroy the contract");
        selfdestruct(payable(_contractOwner));
    }

    function burn(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender || msg.sender == _contractOwner, "You can't revoke this token");
        _burn(_tokenId);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ERC721A/ERC721A.sol";

contract Kachousen is ERC721A, Ownable, DefaultOperatorFilterer{
    using Strings for uint256;

    constructor() ERC721A("Kachousen","Kachousen") {}

    uint256 public maxSupply = 3333;
    string public suffixUri = ".json";
    string private _baseTokenURI = "ipfs://bafybeibomq5ns3ugyml56loxir3xutjg36vbsrfo4wk5cxr3pavgsctrr4/";

    event OwnerMint(address indexed to, uint256 indexed quantity);
    event WithdrawETH(uint256 balance);

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setSuffixUri(string calldata _suffix) external onlyOwner {
        suffixUri = _suffix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return
            bytes(_baseURI()).length != 0
                ? string(abi.encodePacked(_baseURI(), _tokenId.toString(), suffixUri))
                : "";
    }

    function batchAirdrop(address[] calldata _addressList) external onlyOwner {
        require(totalSupply() + _addressList.length <= maxSupply, "Exceed the limit of mint amount");
        for (uint256 i = 0; i < _addressList.length; i++) {
            require(_addressList[i] != address(0), "0x");
            _mint(_addressList[i], 1);
        }
    }

    function ownerMint(uint256 _quantity, address _to) external onlyOwner {
        require(_quantity > 0, "Wrong amount of minting");
        require(totalSupply() + _quantity <= maxSupply, "Exceed the limit of mint amount");
        _mint(_to, _quantity);
        emit OwnerMint(_to, _quantity);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool suc, ) = payable(address(owner())).call{value: balance}("");
        require(suc, "fail");
        emit WithdrawETH(balance);
    }

    receive() external payable {}

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
}
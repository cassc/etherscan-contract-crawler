// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./WOLSBT.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract WOLGEN is Ownable, ERC721AQueryable, DefaultOperatorFilterer, ERC2981 {
    using Strings for uint256;
    string baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 2000;
    bool public paused = true;

    WOLSBT public cntAddr;

    constructor(address _cntAddr, string memory _initBaseURI)
        ERC721A("WOLGEN", "WOLGEN")
    {
        require(_cntAddr != address(0x0));
        cntAddr = WOLSBT(_cntAddr);
        setBaseURI(_initBaseURI);

        _setDefaultRoyalty(owner(), 750);
    }

    function getNumberMinted(address senderAddr) public view returns (uint256) {
        return _numberMinted(senderAddr);
    }

    function getClaimCount(address senderAddr) public view returns (uint256) {
        return cntAddr.getTotalMintedCount(senderAddr);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // public
    function claim() public payable returns (uint256) {
        uint256 _claimAmount = getClaimCount(msg.sender);
        uint256 supply = totalSupply();
        require(!paused, "is paused");
        require(_claimAmount > 0, "wrong number");
        require(_numberMinted(msg.sender) == 0, "already minted");
        require(supply + _claimAmount <= maxSupply, "fully minted");

        uint256 nextTokenId = _nextTokenId();
        _mint(msg.sender, _claimAmount);
        return nextTokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(IERC721A, ERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function ownerClaim(uint256 _claimAmount)
        public
        payable
        onlyOwner
        returns (uint256)
    {
        uint256 nextTokenId = _nextTokenId();
        _mint(msg.sender, _claimAmount);
        return nextTokenId;
    }

    // filter
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }
}
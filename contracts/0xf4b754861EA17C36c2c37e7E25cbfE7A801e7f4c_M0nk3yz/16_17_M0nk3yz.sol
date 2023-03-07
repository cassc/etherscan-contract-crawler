// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

////////////    2k total .. first 500 free
////////////    rest at 0.003
/////////// CONTRACT MINT ONLY - BETTER BE QUICK!!!!!

contract M0nk3yz is ERC721, OperatorFilterer, Ownable, ERC2981 {
    bool public operatorFilteringEnabled;
    using Strings for uint256;

    uint256 public maxMintAmountPerTx;
    string public uriSuffix = ".json";
    string public uriPrefix = "ipfs://bafybeiglnwp7l6qaatskqjoydfreiflomwvviyd3olylzqj3xpi6z3t2yy/";
    uint256 public maxSupply;
    bool public minting = false;
    uint256 public cost = 0 ether;
    uint256 public cost1 = 0 ether;
    uint256 public cost2 = 0.002 ether;
    string public hiddenMetadataUri;
    bool public revealed = true;

    constructor() ERC721("Ascii M0nk3yz", "m0nk3y") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 400);
        setCost(0 ether);
        maxSupply = 500;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function swapToCost2() public onlyOwner {
        maxSupply = 2000;
        cost = cost2;
    }

    function swapToCost1() public onlyOwner {
        maxSupply = 500;
        cost = cost1;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function mint(uint32 _count) external payable {
        require(minting, "Minting needs to be enabled to start minting");
        require(_count <= 51, "Exceeds max per transaction.");
        require(msg.value >= cost * _count, "Insufficient funds!");
        uint256 nextTokenId = _owners.length + 1;
        unchecked {
            require(nextTokenId + _count < maxSupply, "Exceeds max supply.");
        }

        for (uint32 i; i < _count; ) {
            _mint(_msgSender(), nextTokenId);
            unchecked {
                ++nextTokenId;
                ++i;
            }
        }
    }

    function admin_mint() public onlyOwner {
        uint256 _mintAmount = 10;
        uint256 nextTokenId = _owners.length + 1;
        unchecked {
            require(
                nextTokenId + _mintAmount < maxSupply,
                "Exceeds max supply."
            );
        }
        for (uint32 i; i < _mintAmount; ) {
            _mint(_msgSender(), nextTokenId);
            unchecked {
                ++nextTokenId;
                ++i;
            }
        }
    }

    function setMinting(bool value) external onlyOwner {
        minting = value;
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

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function _baseURI() internal view returns (string memory) {
        return uriPrefix;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}
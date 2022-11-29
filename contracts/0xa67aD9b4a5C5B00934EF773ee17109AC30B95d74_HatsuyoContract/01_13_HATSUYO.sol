// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "[email protected]/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface OpenSea {
    function proxies(address) external view returns (address);
}

contract Hatsuyo is
    ERC721A("Hatsuyo", "HYO"),
    Ownable,
    ERC2981,
    DefaultOperatorFilterer
{
    
    uint256 public maxMintAmount = 20;
    uint256 public maxSupply = 5000;
    uint256 public costPerNft = 0.015 * 1e18;
    uint256 public nftsForOwner = 50;
    string public metadataFolderIpfsLink;
    uint256 constant presaleSupply = 300;
    string constant baseExtension = ".json";
    uint256 public publicmintActiveTime = 1669917600;

    constructor() {
        _setDefaultRoyalty(msg.sender, 500); // 5.00 %
    }

    // public
    function purchaseTokens(uint256 _mintAmount) public payable {
        require(
            block.timestamp > publicmintActiveTime,
            "the contract is paused"
        );
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(
            supply + _mintAmount + nftsForOwner <= maxSupply,
            "max NFT limit exceeded"
        );
        require(msg.value == costPerNft * _mintAmount, "insufficient funds");

        _safeMint(msg.sender, _mintAmount);
    }

    ///////////////////////////////////
    //       OVERRIDE CODE STARTS    //
    ///////////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataFolderIpfsLink;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
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
                        _toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    //////////////////
    //  ONLY OWNER  //
    //////////////////

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function giftNft(address[] calldata _sendNftsTo, uint256 _howMany)
        external
        onlyOwner
    {
        nftsForOwner -= _sendNftsTo.length * _howMany;

        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _safeMint(_sendNftsTo[i], _howMany);
    }

    function setnftsForOwner(uint256 _newnftsForOwner) public onlyOwner {
        nftsForOwner = _newnftsForOwner;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setCostPerNft(uint256 _newCostPerNft) public onlyOwner {
        costPerNft = _newCostPerNft;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setMetadataFolderIpfsLink(string memory _newMetadataFolderIpfsLink)
        public
        onlyOwner
    {
        metadataFolderIpfsLink = _newMetadataFolderIpfsLink;
    }

    function setSaleActiveTime(uint256 _publicmintActiveTime) public onlyOwner {
        publicmintActiveTime = _publicmintActiveTime;
    }
}

contract NftWhitelistSaleMerkle is Hatsuyo {
    // multiple presale configs
    mapping(uint256 => uint256) public maxMintPresales;
    mapping(uint256 => uint256) public itemPricePresales;
    mapping(uint256 => bytes32) public whitelistMerkleRoots;
    uint256 public presaleActiveTime = 1669831200;

    function _inWhitelist(
        address _owner,
        bytes32[] memory _proof,
        uint256 _rootNumber
    ) private view returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                whitelistMerkleRoots[_rootNumber],
                keccak256(abi.encodePacked(_owner))
            );
    }

    function purchaseTokensWhitelist(
        uint256 _howMany,
        bytes32[] calldata _proof,
        uint256 _rootNumber
    ) external payable {
        require(block.timestamp > presaleActiveTime, "Presale is not active");
        require(
            _inWhitelist(msg.sender, _proof, _rootNumber),
            "You are not in presale"
        );
        require(
            msg.value == _howMany * itemPricePresales[_rootNumber],
            "Try to send more ETH"
        );
        require(
            _numberMinted(msg.sender) + _howMany <=
                maxMintPresales[_rootNumber],
            "Purchase exceeds max allowed"
        );

        _safeMint(msg.sender, _howMany);
    }

    function setPresale(
        uint256 _rootNumber,
        bytes32 _whitelistMerkleRoot,
        uint256 _maxMintPresales,
        uint256 _itemPricePresale
    ) external onlyOwner {
        maxMintPresales[_rootNumber] = _maxMintPresales;
        itemPricePresales[_rootNumber] = _itemPricePresale;
        whitelistMerkleRoots[_rootNumber] = _whitelistMerkleRoot;
    }

    function setPresaleActiveTime(uint256 _presaleActiveTime)
        external
        onlyOwner
    {
        presaleActiveTime = _presaleActiveTime;
    }

    // implementing Operator Filter Registry
    // https://opensea.io/blog/announcements/on-creator-fees
    // https://github.com/ProjectOpenSea/operator-filter-registry#usage

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

contract HatsuyoContract is NftWhitelistSaleMerkle {}
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

contract MobTies is
    ERC721A("Mob Ties by Michael Franzese", "Lion"),
    Ownable,
    ERC2981,
    DefaultOperatorFilterer
{
    bool public revealed = false;
    string public notRevealedMetadataFolderIpfsLink;
    uint256 public maxMintAmount = 20;
    uint256 public maxSupply = 3500;
    uint256 public costPerNft = 0.7 * 1e18;
    uint256 public reservedNfts = 500;
    string public metadataFolderIpfsLink;
    string constant baseExtension = ".json";
    uint256 public publicmintActiveTime = 1670875200;
 
    uint256 public claimSpotsTotalSold = 2422;
    uint256 public claimSpotsTotalClaimed = 0;


    constructor() {
        _setDefaultRoyalty(msg.sender, 750); // 7.5 %
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
        uint256 claimSpotsAvailable = claimSpotsTotalSold -
            claimSpotsTotalClaimed;
        require(
            supply + _mintAmount + reservedNfts + claimSpotsAvailable <=
                maxSupply,
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

        if (revealed == false) return notRevealedMetadataFolderIpfsLink;

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

    /// @notice test before use
    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function giftNft(address[] calldata _sendNftsTo, uint256 _howMany)
        external
        onlyOwner
    {
        reservedNfts -= _sendNftsTo.length * _howMany;

        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _safeMint(_sendNftsTo[i], _howMany);
    }

    function setClaimSpotsTotalClaimed(uint256 _claimSpotsTotalClaimed)
        public
        onlyOwner
    {
        claimSpotsTotalClaimed = _claimSpotsTotalClaimed;
    }

    function setReservedNfts(uint256 _newreservedNfts) public onlyOwner {
        reservedNfts = _newreservedNfts;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function revealFlip() public onlyOwner {
        revealed = !revealed;
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

    function setNotRevealedMetadataFolderIpfsLink(
        string memory _notRevealedMetadataFolderIpfsLink
    ) public onlyOwner {
        notRevealedMetadataFolderIpfsLink = _notRevealedMetadataFolderIpfsLink;
    }

    function setSaleActiveTime(uint256 _publicmintActiveTime) public onlyOwner {
        publicmintActiveTime = _publicmintActiveTime;
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

contract NftWhitelistSaleMerkle is MobTies {
    ///////////////////////////////
    //      CLAIM CODE STARTS    //
    ///////////////////////////////


    mapping(uint256 => bytes32) public whitelistMerkleRoots;
    uint256 public whitelistActiveTime = type(uint256).max;

    function isWLClaimed(address _owner) external view returns (uint256) {
        return _getAux(_owner);
    }

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
        uint256 _claimAmount,
        bytes32[] calldata _proof
    ) external payable {
        require(
            totalSupply() + _claimAmount + reservedNfts <= maxSupply,
            "mint limit exceeded"
        );
        require(block.timestamp > whitelistActiveTime, "WL not active");
        require(_inWhitelist(msg.sender, _proof, _claimAmount), "Not in WL");
        require(_getAux(msg.sender) == 0, "Already claimed"); // 0 = Claim Available
        claimSpotsTotalClaimed += _claimAmount;
        _setAux(msg.sender, 1);
        _safeMint(msg.sender, _claimAmount);
    }

    function setWhitelist(uint256 _rootNumber, bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoots[_rootNumber] = _whitelistMerkleRoot;
    }

    function setAllWhitelists(bytes32[] calldata _whitelistMerkleRoots)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelistMerkleRoots.length; i++)
            whitelistMerkleRoots[i + 1] = _whitelistMerkleRoots[i];
    }

    function setWhitelistActiveTime(uint256 _whitelistActiveTime)
        external
        onlyOwner
    {
        whitelistActiveTime = _whitelistActiveTime;
    }
}

contract MobTiesContract is NftWhitelistSaleMerkle {}
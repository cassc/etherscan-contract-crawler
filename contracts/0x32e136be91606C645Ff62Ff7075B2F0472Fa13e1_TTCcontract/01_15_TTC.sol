// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "[email protected]/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface OpenSea {
    function proxies(address) external view returns (address);
}

contract TycoonTigersClub is ERC721A("TycoonTigersClub", "TTC"), Ownable, ERC2981 {
    using Strings for uint256;

    bool public revealed = false;
    string public notRevealedMetadataFolderIpfsLink;
    uint256 public maxMintAmount = 1;
    uint256 public maxSupply = 3900;
    uint256 public adminMint = 50;
    string public metadataFolderIpfsLink;
    uint256 public addressLimit = 1;
    mapping(address => uint256) public addressMintedBalance;
    string constant baseExtension = ".json";
    uint256 public publicmintActiveTime = 1659160800;

    constructor() {
        _setDefaultRoyalty(msg.sender, 1000); // 10%
    }

    // public
    function purchaseTokens(uint256 _mintAmount) public payable {
        require(block.timestamp > publicmintActiveTime, "The contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "You have to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "Max mint amount per session exceeded");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= addressLimit, "max NFT per address exceeded");
        require(supply + _mintAmount + adminMint <= maxSupply, "Max NFT limit exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, 1);
    }
    }

    ///////////////////////////////////
    //       OVERRIDE CODE STARTS    //
    ///////////////////////////////////

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataFolderIpfsLink;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) return notRevealedMetadataFolderIpfsLink;

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    //////////////////
    //  ONLY OWNER  //
    //////////////////

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function Mint(address[] calldata _sendNftsTo, uint256 _howMany) external onlyOwner {
        adminMint -= _sendNftsTo.length * _howMany;

        for (uint256 i = 0; i < _sendNftsTo.length; i++) _safeMint(_sendNftsTo[i], _howMany);
    }

    function setadminMint(uint256 _newadminMint) public onlyOwner {
        adminMint = _newadminMint;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function revealFlip() public onlyOwner {
        revealed = !revealed;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setaddressLimit(uint256 _limit) public onlyOwner {
    addressLimit = _limit;
    }

    function setMetadataFolderIpfsLink(string memory _newMetadataFolderIpfsLink) public onlyOwner {
        metadataFolderIpfsLink = _newMetadataFolderIpfsLink;
    }

    function setNotRevealedMetadataFolderIpfsLink(string memory _notRevealedMetadataFolderIpfsLink) public onlyOwner {
        notRevealedMetadataFolderIpfsLink = _notRevealedMetadataFolderIpfsLink;
    }

    function setSaleActiveTime(uint256 _publicmintActiveTime) public onlyOwner {
        publicmintActiveTime = _publicmintActiveTime;
    }
}

contract NftWhitelistSaleMerkle is TycoonTigersClub {
    ///////////////////////////////
    //    PRESALE CODE STARTS    //
    ///////////////////////////////

    uint256 public presaleActiveTime = 1659117600;
    uint256 public presaleMaxMint = 2;
    uint256 public presaleAddressLimit = 2;
    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) public presaleClaimedBy;

    function setWhitelist(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function inWhitelist(bytes32[] memory _proof, address _owner) public view returns (bool) {
        return MerkleProof.verify(_proof, whitelistMerkleRoot, keccak256(abi.encodePacked(_owner)));
    }

    function purchaseTokensPresale(uint256 _howMany, bytes32[] calldata _proof) external payable {
        uint256 supply = totalSupply();
        require(supply + _howMany + adminMint <= maxSupply, "Max NFT limit exceeded");

        require(inWhitelist(_proof, msg.sender), "You are not in presale");
        require(block.timestamp > presaleActiveTime, "Presale is not active");

        presaleClaimedBy[msg.sender] += _howMany;

        require(presaleClaimedBy[msg.sender] <= presaleMaxMint, "Max mint amount per session exceeded");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _howMany <= presaleAddressLimit, "max NFT per address exceeded");

        for (uint256 i = 1; i <= _howMany; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, 1);

    }
    }

    // set limit of presale
    function setPresaleMaxMint(uint256 _presaleMaxMint) external onlyOwner {
        presaleMaxMint = _presaleMaxMint;
    }

    function setPresaleAddressLimit(uint256 _limit) public onlyOwner {
    presaleAddressLimit = _limit;
    }

    function setPresaleActiveTime(uint256 _presaleActiveTime) external onlyOwner {
        presaleActiveTime = _presaleActiveTime;
    }
} 

contract NftAutoApproveMarketPlaces is NftWhitelistSaleMerkle {
    ////////////////////////////////
    // AUTO APPROVE MARKETPLACES  //
    ////////////////////////////////

    mapping(address => bool) public projectProxy;

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function isApprovedForAll(address _owner, address _operator) public view override(ERC721A) returns (bool) {
        return
            projectProxy[_operator] || // Auto Approve any Marketplace,
                _operator == OpenSea(0x00000000006c3852cbEf3e08E8dF289169EdE581).proxies(_owner) ||
                _operator == 0xF849de01B080aDC3A814FaBE1E2087475cF2E354 || // Looksrare
                _operator == 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e || // Rarible
                _operator == 0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be // X2Y2
                ? true
                : super.isApprovedForAll(_owner, _operator);
    }
}

contract TTCcontract is NftAutoApproveMarketPlaces {}
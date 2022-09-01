// SPDX-License-Identifier: GPL-3.0
// *Edited and Writed* By Mahmoud Al Homsi https://github.com/codingforwhile

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Xioverse is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json?alt=media";

    uint256 public mintingCost = 1.35 ether;
    uint256 public silverMintingQuota = 0.02025 ether;
    uint256 public goldMintingQuota = 0.0135 ether;

    uint256 public maxSupply = 1000;
    uint256 public maxInvestmentSupply = 250;
    uint256 public minInvMintAmount = 5;
    bool public paused = false;
    bool public isInvestmentMode = true;

    address payable ownerAddress;
    
    address payable public silverKeyPrehistory = payable(0xC40Adb606c61832f724a51f79f0914890Ae9B2b9);
    address payable public silverKeyEgyptianMythology = payable(0xDf72835FBEF9E3a33E682b19924D858c59e41BB7);
    address payable public silverKeyGreekMythology = payable(0x034490e6015F497C6d4b268180A2d28aB7Fd64b8);
    address payable public silverKeyNorseMythology = payable(0xe0fbD383d644CF2b9596c05109ED878705039A55);
    address payable public silverKeyMedievalAge = payable(0x1Ea153739cd009e23926A07e77828BD7233f7524);
    address payable public silverKeyRenaissance = payable(0xF82abfCc9c9E63759563986f3dE1F2C5b31cB2E5);
    address payable public silverKeyIndustrialRevolution = payable(0x08b9B67DdA7080231a8dD3F7446aA8c31317B821);
    address payable public silverKeySteamPunk = payable(0x038a8301bd7a2A8D1AE352496DB8eC888aB836C3);
    address payable public silverKeyCyberPunk = payable(0xb726ab0c2Cf928B002eF5Ad4153C66528bC6a07B);
    address payable public silverKeyCosmos = payable(0x202B26D3F70f5B00aAbe914d19948af7F1FD5470);
    address payable public goldKey = payable(0xF7477482DD51Dcd7D317f9c1Cde9D805C86f94C7);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        ownerAddress = payable(owner());
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function internalKeysWithdraw(uint256 _firstTokenID, uint256 _lastTokenID, uint256 paidEther) internal {
        for (uint256 i = _firstTokenID; i <= _lastTokenID; i++) {
            if (i % 10 == 1) {silverKeyPrehistory.transfer(silverMintingQuota);}
            if (i % 10 == 2) {silverKeyEgyptianMythology.transfer(silverMintingQuota);}
            if (i % 10 == 3) {silverKeyGreekMythology.transfer(silverMintingQuota);}
            if (i % 10 == 4) {silverKeyNorseMythology.transfer(silverMintingQuota);}
            if (i % 10 == 5) {silverKeyMedievalAge.transfer(silverMintingQuota);}
            if (i % 10 == 6) {silverKeyRenaissance.transfer(silverMintingQuota);}
            if (i % 10 == 7) {silverKeyIndustrialRevolution.transfer(silverMintingQuota);}
            if (i % 10 == 8) {silverKeySteamPunk.transfer(silverMintingQuota);}
            if (i % 10 == 9) {silverKeyCyberPunk.transfer(silverMintingQuota);}
            if (i % 10 == 0) {silverKeyCosmos.transfer(silverMintingQuota);}
        }
        uint256 totalGoldQuota = ((_lastTokenID - _firstTokenID)+1)*goldMintingQuota;
        uint256 totalSilverQuota = ((_lastTokenID - _firstTokenID)+1)*silverMintingQuota;
        uint256 restForOwner = paidEther - (totalSilverQuota + totalGoldQuota);
        goldKey.transfer(totalGoldQuota);
        ownerAddress.transfer(restForOwner);
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(msg.value >= mintingCost * _mintAmount);
        if (isInvestmentMode) {
            require(_mintAmount >= minInvMintAmount);
            require(supply + _mintAmount <= maxInvestmentSupply);
        }
        if (!isInvestmentMode) {
            require(_mintAmount > 0);
            require(supply + _mintAmount <= maxSupply);
        }
        for(uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i); 
        }
        internalKeysWithdraw(supply+1, supply+_mintAmount, msg.value);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    // only owner
    function setMaxInvestmentSupply(uint256 _newMaxInvestmentSupply) public onlyOwner () {
        if (_newMaxInvestmentSupply <= maxInvestmentSupply) {
            maxInvestmentSupply = _newMaxInvestmentSupply;
        }
    }

    function setMinInvMintAmount(uint256 _newMinInvMintAmount) public onlyOwner (){
        minInvMintAmount = _newMinInvMintAmount;
    }

    function setCosts(uint256 _newMintingCost, uint256 _newSilverMintingQuota, uint256 _newGoldMintingQuota) public onlyOwner() {
        require ( _newMintingCost > _newSilverMintingQuota + _newGoldMintingQuota);
        mintingCost = _newMintingCost*1000000000;
        silverMintingQuota = _newSilverMintingQuota*1000000000;
        goldMintingQuota = _newGoldMintingQuota*1000000000;
    }

    function setSilverKeyPrehistory(address payable _newAddrressKey) public onlyOwner() {silverKeyPrehistory = payable(_newAddrressKey);}
    function setSilverKeyEgyptianMythology(address payable _newAddrressKey) public onlyOwner() {silverKeyEgyptianMythology = payable(_newAddrressKey);}
    function setSilverKeyGreekMythology(address payable _newAddrressKey) public onlyOwner() {silverKeyGreekMythology = payable(_newAddrressKey);}
    function setSilverKeyNorseMythology(address payable _newAddrressKey) public onlyOwner() {silverKeyNorseMythology = payable(_newAddrressKey);}
    function setSilverKeyMedievalAge(address payable _newAddrressKey) public onlyOwner() {silverKeyMedievalAge = payable(_newAddrressKey);}
    function setSilverKeyRenaissance(address payable _newAddrressKey) public onlyOwner() {silverKeyRenaissance = payable(_newAddrressKey);}
    function setSilverKeyIndustrialRevolution(address payable _newAddrressKey) public onlyOwner() {silverKeyIndustrialRevolution = payable(_newAddrressKey);}
    function setSilverKeySteamPunk(address payable _newAddrressKey) public onlyOwner() {silverKeySteamPunk = payable(_newAddrressKey);}
    function setSilverKeyCyberPunk(address payable _newAddrressKey) public onlyOwner() {silverKeyCyberPunk = payable(_newAddrressKey);}
    function setSilverKeyCosmos(address payable _newAddrressKey) public onlyOwner() {silverKeyCosmos = payable(_newAddrressKey);}
    function setGoldKey(address payable _newAddrressKey) public onlyOwner() {goldKey = payable(_newAddrressKey);}

    function setBaseURI(string memory _newBaseURI) public onlyOwner() {
        baseURI = _newBaseURI;
    }

    function setBaseExtention(string memory _newBaseExtention) public onlyOwner() {
        baseExtension = _newBaseExtention;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function removeInvestmentMode() public onlyOwner {
        isInvestmentMode = false;
    }

    // Updates 
    mapping(uint256 => string) public newtokenURIs;

    function setNewTokenURI(uint256 _tokenID, string memory _newTokenURI) public onlyOwner {
        require(_exists(_tokenID), "URI query for nonexistent token");
        newtokenURIs[_tokenID] = _newTokenURI;
    }

    function adminMint(address _to, uint256 _mintAmount) public payable onlyOwner{
        uint256 supply = totalSupply();
        require(!paused);
        require(msg.value >= mintingCost * _mintAmount);
        require(_mintAmount > 0);
        if (isInvestmentMode) {
            require(supply + _mintAmount <= maxInvestmentSupply);
        }
        if (!isInvestmentMode) {
            require(supply + _mintAmount <= maxSupply);
        }
        for(uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i); 
        }
        internalKeysWithdraw(supply+1, supply+_mintAmount, msg.value);
    }
}
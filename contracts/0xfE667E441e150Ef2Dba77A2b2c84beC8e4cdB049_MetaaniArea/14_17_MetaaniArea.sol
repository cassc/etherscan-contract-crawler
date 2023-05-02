// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./ERC721.sol";

import "./Ownable.sol";

import "./IConataNFT.sol";

import "./IDNA.sol";

// 
contract MetaaniArea is IConataNFT, ERC721, Ownable{
    IDNA public dna;
    uint private _mintedAmount = 0;
    uint private _burnedAmount = 0;
    string private _metadataBaseUri;
    mapping (uint => bool) public claimedTokenMap;
    bool public isOpenClaim = false;
    //
    address constant fundsWallet           = 0x8837391C2634b62C4fCF4f0b01F0772A743A4Cf3;
    address constant fundsRescueSpareKey   = 0xbDc378A75Fe1d1b53AdB3025541174B79474845b;
    address constant fundsRescueDestWallet = 0xeecE4544101f7C7198157c74A1cBfE12aa86718B;

    //
    constructor(
        string memory name, 
        string memory symbol,
        string memory metadataBaseUri,
        address dnaAddr
    ) ERC721(name, symbol) {
        _metadataBaseUri = metadataBaseUri;
        dna = IDNA(dnaAddr);
    }

    
    //
    function mint(bytes calldata data) override(IConataNFT) external payable{
        _claim(data);
    }
    function mint() override(IConataNFT) external payable{
        revert("Not Implement");
    }


    

    
    function isClaimableTokenId(address account, uint tokenId) public view returns(bool) {
        bool isNotMinted = claimedTokenMap[tokenId] == false;
        bool isOwnedDna;
        try dna.ownerOf(tokenId)  returns (address owner) {
            isOwnedDna = owner == account;
        } catch  {
            isOwnedDna = false;
        }
        return isNotMinted && isOwnedDna;
    }

    
    function getDnaTokenIds(address account) public view returns(uint[] memory){
        uint tokenCount = dna.balanceOf(account);
        uint[] memory tokenIds = new uint[](tokenCount);
        for(uint i=0; i < tokenCount; i++){
            uint tokenId = dna.tokenOfOwnerByIndex(account, i);
            tokenIds[i] = tokenId;
        }
        return tokenIds;
    }

    //
    function getClaimableTokenIds(address account) public view returns(uint[] memory){
        uint[] memory tokenIds = getDnaTokenIds(account);

        
        uint count = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (isClaimableTokenId(account, tokenIds[i])) {
                count++;
            }
        }

        
        uint[] memory claimableTokenIds = new uint[](count);
        uint index = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (isClaimableTokenId(account, tokenIds[i])) {
                claimableTokenIds[index] = tokenIds[i];
                index++;
            }
        }
        return claimableTokenIds;
    }

    
    function totalSupply() override(IConataNFT) external view returns(uint256){
        return _mintedAmount - _burnedAmount;
    }

    //
    function burn(uint tokenId, uint amount) override(IConataNFT) external{
        require(_msgSender() == ownerOf(tokenId), "Not Owner Of Token");
        _burn(tokenId);
        _burnedAmount++;
    }

    

    //
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _metadataBaseUri;
    }
    
    // 
    function _claim(bytes calldata data) internal{
        require(isOpenClaim, "Not Open");
        address account = _msgSender();
        (uint[] memory tokenIds) = abi.decode(data, (uint[]));
        //
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(isClaimableTokenId(account, tokenId), "Invalid TokenId");
            _safeMint( account , tokenId);
            claimedTokenMap[tokenId] = true;
            _mintedAmount++;
            emit Minted(account, tokenId);
        }
    }

    

    

    //
    function setDNA(address newAddr) external onlyOwner{
        dna = IDNA(newAddr);
    }

    
    function setIsOpenClaim(bool state) external onlyOwner{
        isOpenClaim = state;
    }


    
    function setURI(string memory metadataBaseUri) override(IConataNFT) external onlyOwner {
        _metadataBaseUri = metadataBaseUri;
    }

    //
    function withdraw() override(IConataNFT) external {
        require(_msgSender() == fundsWallet);
        uint balance = address(this).balance;
        payable(fundsWallet).transfer(balance);
    }
    function withdrawSpare() override(IConataNFT) external {
        require(_msgSender() == fundsRescueSpareKey);
        uint balance = address(this).balance;
        payable(fundsRescueDestWallet).transfer(balance);
    }

}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/IERC721A.sol";

contract TODPortalsCollection01 is ERC721AQueryable, Ownable, PaymentSplitter, Pausable,  ReentrancyGuard {
    using Strings for uint256;
    string private _baseTokenURI;
    IERC721A public todNFT;

    //sale settings
    uint256 public cost = 0.00 ether;
    uint256 public maxSupply = 6000;
    uint256 public maxPublicSupply = 1000;
    uint256 public maxMint = 20;
    uint256 public claimRemainder = 0;
    uint256 public publicMinted;
    bool public publicSaleActive = false;
    bool public claimRemainderActive = false;

    //token claim mapping
    mapping(uint256 => bool) public claimedByTokenId;
    mapping(uint256 => bool) public claimedSecondByTokenId;

    //share settings
    address[] private addressList = [
    //founders wallet
    0xa449A4f67d74de0c4a11A8137AfF77838a277437,
    //dev wallet
    0xc3960f9ea17e0E960E8b1A2F870fe7A6a1954D41
    ];

    uint[] private shareList = [70, 30];

    constructor(
        address _setTodNFTContract
    ) ERC721A("TODPortalsCollection01", "TODPORTAL01") PaymentSplitter(addressList, shareList) {
        todNFT = IERC721A(_setTodNFTContract);
    }

    // public minting
    function mintWithTOD(uint256[] memory TODIds) public nonReentrant {
        require(publicSaleActive, "Public sale has not begun yet");
        require(TODIds.length > 0, "Can not mint 0" );
        for (uint256 i = 0; i < TODIds.length; ++i) {
            require(TODIds[i] >= 1 && TODIds[i] <= 5001, "Token ID invalid");
            require(todNFT.ownerOf(TODIds[i]) == msg.sender, "Not the owner of this ODDY");
            require(claimedByTokenId[TODIds[i]] == false, "You have already claimed for one of these tokens");
            claimedByTokenId[TODIds[i]] = true;
        }
        _mint(msg.sender, TODIds.length);
    }

    function publicMint(uint256 _mintAmount) public payable nonReentrant{
        uint256 s = totalSupply();
        require(publicSaleActive, "Public sale has not begun yet");
        require(_mintAmount > 0, "Can not mint 0" );
        require(_mintAmount <= maxMint, "Can not mint this many" );
        require(publicMinted + _mintAmount <= maxPublicSupply, "Can not go over public supply");
        require(cost * _mintAmount == msg.value, "Wrong amount");
        require(s + _mintAmount <= maxSupply, "Can not go over max supply" );
        publicMinted += _mintAmount;
        _mint(msg.sender, _mintAmount);
        delete s;
    }

    function mintRemainderWithTOD(uint256[] memory TODIds) public nonReentrant {
        uint256 s = totalSupply();
        uint256 claimMintTotal = TODIds.length * claimRemainder;
        require(claimRemainderActive, "Secondary claim not activated");
        require(TODIds.length > 0, "Can not mint 0" );
        require(s + claimMintTotal <= maxSupply, "Can not go over max supply" );
        for (uint256 i = 0; i < TODIds.length; ++i) {
            require(TODIds[i] >= 1 && TODIds[i] <= 5001, "Token ID invalid");
            require(todNFT.ownerOf(TODIds[i]) == msg.sender, "Not the owner of this ODDY");
            require(claimedSecondByTokenId[TODIds[i]] == false, "You have already claimed for one of these tokens");
            claimedSecondByTokenId[TODIds[i]] = true;
        }
        _mint(msg.sender, claimMintTotal);
        delete s;
    }

    //dev minting
    function gift(uint256[] calldata _mintAmount, address[] calldata recipient) external onlyOwner{
        for(uint i = 0; i < recipient.length; ++i){
            require(publicMinted + _mintAmount[i] <= maxPublicSupply, "Can not go over public supply");
            require(_mintAmount[i] > 0, "Can not mint 0");
            publicMinted += _mintAmount[i];
            _mint( recipient[i], _mintAmount[i]);
        }
    }

    // admin functionality
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    function setMaxMint(uint256 _newmaxMint) public onlyOwner {
        maxMint = _newmaxMint;
    }
    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }
    function setMaxPublicSupply(uint256 _newMaxPublicSupply) public onlyOwner {
        maxPublicSupply = _newMaxPublicSupply;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function setPublicSaleStatus(bool _status) public onlyOwner {
        publicSaleActive = _status;
    }
    function setClaimRemainderStatus(bool _status) public onlyOwner {
        claimRemainderActive = _status;
    }
    function setClaimRemainderAmount(uint256 _newClaimRemainder) public onlyOwner {
        claimRemainder = _newClaimRemainder;
    }
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
    function withdrawSplit() public onlyOwner {
        for (uint256 sh = 0; sh < addressList.length; sh++) {
            address payable wallet = payable(addressList[sh]);
            release(wallet);
        }
    }
}
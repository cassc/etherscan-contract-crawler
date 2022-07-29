// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Base64 } from 'base64-sol/base64.sol';
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import './BokkyPooBahsDateTimeLibrary.sol';

contract KemigawaJinjaCollection is ERC721A, Ownable, Pausable {
    struct Claim {
        uint64 amuletType;
        uint64 count;
    }

    struct TokenMetaInfo {
        uint64 amuletType;
        uint256 mintTimestamp;
    }

    address public constant withdrawAddress = 0x2eC92DB165fa3Df089EC1Ae997bFE692ea095EcC;
    uint256 public mintCost = 0.005 ether;

    string public imageURI = 'https://kemigawa.nft-kojiki-project.com/images/';
    string public animationURI = 'https://kemigawa.nft-kojiki-project.com/animations/';
    string public imageExtension = '.png';
    string public animationExtension = '.mp4';

    uint256 public blessingTimeSec = 60 * 60 * 24 * 365;
    uint256 public baseTimestampSecDiff = 60 * 60 * 9;

    uint256 public amuletTypeNum = 10;
    mapping(uint64 => string) public amuletNames;
    mapping(uint64 => string) public amuletDescriptions;
    mapping(uint64 => string) public amuletNamesExpired;
    mapping(uint64 => string) public amuletDescriptionsExpired;

    mapping(uint256 => TokenMetaInfo) private _tokenMetaInfos;

    modifier enoughEth(uint256 quantity) {
        require(msg.value >= mintCost * quantity, "not enough eth");
        _;
    }

    modifier correctAmuletTypes(Claim[] memory claims) {
        for (uint64 index = 0 ; index < claims.length; index++) {
            require(1 <= claims[index].amuletType && claims[index].amuletType <= amuletTypeNum, "incorrect amulet type");
        }
        _;
    }

    modifier existsToken(uint256 tokenId) {
        require(exists(tokenId), "token is not exist");
        _;
    }

    constructor() ERC721A("KemigawaJinjaCollection", "KJC") {
        Claim[] memory claims = new Claim[](amuletTypeNum);
        for (uint64 amuletType = 1; amuletType <= amuletTypeNum; amuletType++) {
            if (amuletType == 6) {
                claims[amuletType - 1] = Claim(amuletType, 280);
            } else {
                claims[amuletType - 1] = Claim(amuletType, 30);
            }
        }

        mintCommon(withdrawAddress, claims);
        _pause();
    }

    function mint(Claim[] memory claims) external payable
        whenNotPaused
        enoughEth(getTotalClaimCount(claims))
    {
        mintCommon(msg.sender, claims);
    }

    function mintCommon(address mintAddress, Claim[] memory claims) private
        correctAmuletTypes(claims)
    {
        uint64 totalClaimCount = getTotalClaimCount(claims);

        _safeMint(mintAddress, totalClaimCount);

        uint64 sum = 0;
        for (uint64 i = 0; i < claims.length; i++) {
            for (uint64 j = 0; j < claims[i].count; j++){
                sum++;
                uint256 tokenId = totalSupply() - totalClaimCount + sum;
                _tokenMetaInfos[tokenId] = TokenMetaInfo(claims[i].amuletType, block.timestamp);
            }
        }
    }

    function getTotalClaimCount(Claim[] memory claims) private pure returns (uint64) {
        uint64 totalClaimCount = 0;
        for (uint64 index = 0; index < claims.length; index++){
            totalClaimCount += claims[index].count;
        }
        return totalClaimCount;
    }

    function encodePackedJson(uint256 tokenId) private view existsToken(tokenId) returns (bytes memory) {
        uint64 amuletType = _tokenMetaInfos[tokenId].amuletType;
        uint256 mintTimestamp = _tokenMetaInfos[tokenId].mintTimestamp;
        if (block.timestamp > mintTimestamp + blessingTimeSec) {
            string memory name = amuletNamesExpired[amuletType];
            string memory description = amuletDescriptionsExpired[amuletType];
            return abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image": "', imageURI, Strings.toString(amuletType), '_expired', imageExtension, '"}');
        } else {
            uint256 baseTimestamp = mintTimestamp + baseTimestampSecDiff;
            string memory name = string(abi.encodePacked(amuletNames[amuletType], ' Minted at ', Strings.toString(BokkyPooBahsDateTimeLibrary.getYear(baseTimestamp)), '/', Strings.toString(BokkyPooBahsDateTimeLibrary.getMonth(baseTimestamp)), '/', Strings.toString(BokkyPooBahsDateTimeLibrary.getDay(baseTimestamp))));
            string memory description = amuletDescriptions[amuletType];
            return abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image": "', imageURI, Strings.toString(amuletType), imageExtension, '", "animation_url": "', animationURI, Strings.toString(amuletType), animationExtension, '"}');
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(encodePackedJson(tokenId)))));
    }

    function getJsonText(uint256 tokenId) public view returns (string memory) {
        return string(encodePackedJson(tokenId));
    }

    function getMintTimestamp(uint256 tokenId) public view virtual existsToken(tokenId) returns (uint256) {
        return _tokenMetaInfos[tokenId].mintTimestamp;
    }

    function getExpireTimestamp(uint256 tokenId) public view virtual existsToken(tokenId) returns (uint256) {
        return _tokenMetaInfos[tokenId].mintTimestamp + blessingTimeSec;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setImageURI(string memory _value) public onlyOwner {
        imageURI = _value;
    }

    function setAnimationURI(string memory _value) public onlyOwner {
        animationURI = _value;
    }

    function setImageExtension(string memory _value) public onlyOwner {
        imageExtension = _value;
    }

    function setAnimationExtension(string memory _value) public onlyOwner {
        animationExtension = _value;
    }

    function setBlessingTimeSec(uint256 _value) public onlyOwner {
        blessingTimeSec = _value;
    }

    function setBaseTimestampSecDiff(uint256 _value) public onlyOwner {
        baseTimestampSecDiff = _value;
    }

    function setAmuletTypeNum(uint256 _value) public onlyOwner {
        amuletTypeNum = _value;
    }

    function setAmuletName(uint64 _type, string memory _value) public onlyOwner {
        amuletNames[_type] = _value;
    }

    function setAmuletDescription(uint64 _type, string memory _value) public onlyOwner {
        amuletDescriptions[_type] = _value;
    }

    function setAmuletNameExpired(uint64 _type, string memory _value) public onlyOwner {
        amuletNamesExpired[_type] = _value;
    }

    function setAmuletDescriptionExpired(uint64 _type, string memory _value) public onlyOwner {
        amuletDescriptionsExpired[_type] = _value;
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
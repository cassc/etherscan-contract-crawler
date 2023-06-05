// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol'; 
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';

contract MetaborgDistributionERC1155 is ERC1155Upgradeable {

    using SafeMathUpgradeable for uint256;
 
    uint private randomizerIndex;
    uint public mangaDistributionIndex;
    address public owner;
    uint private ownerBalance;
    string public name = "Metaborg by Giovanni Motta"; // collection name on Opensea
    
    struct mangaDistributionStruct {
        mapping(address => uint) allowedAddressToMint;
        uint price;
        uint diamondSupply;
        uint goldSupply;
        uint originalSupply;
        uint diamondAssigned;
        uint goldAssigned;
        uint originalAssigned;
        mapping(uint => uint) ERC1155MangaIDs;
    }

    enum mangaVersion {
        NULL,
        ORIGINAL,
        GOLD,
        DIAMOND
    }

    event createDistributionEvent(uint IDDistribution, address indexed creator, uint diamondSupply, uint goldSupply, uint originalSupply, uint ERC1155DiamondID, uint ERC1155GoldID, uint ERC1155OriginalID);
    event withdrawOwnerBalanceEvent(address indexed to, uint amount);

    mapping(uint => mangaDistributionStruct) mangaDistribution;
    mapping(uint => string) IPFSOverrideConnectionURI;

    modifier onlyOwner {
        require(owner == msg.sender, "ONLY_OWNER_CAN_RUN_THIS_FUNCTION");
        _;
    }

    function initialize() initializer public {
        __ERC1155_init("#"); 
        owner = msg.sender;
        mangaDistributionIndex = uint(1);
    }

    // OPENSEA COMPATIBILITY OVERRIDE

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return IPFSOverrideConnectionURI[_tokenId];
    }

    // DISTRIBUTION LOGIC

    function bytesToUint(bytes32 b) public pure returns (uint256){
        uint256 number;
        for(uint i=uint(0);i<b.length;i++){
            number = number + uint8(b[i]);
        }
        return number;
    }

    function getRandom(uint _externalMax) private returns(uint){
        uint internalMax = uint(8160);
        uint randomNumber = bytesToUint(bytes32(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, address(this), randomizerIndex++))));
        return randomNumber.mul(_externalMax).div(internalMax);
    }

    function thresoldMappingMangaVersion(uint _value, uint _diamondSupply, uint _goldSupply, uint _diamondAssigned, uint _goldAssigned) private pure returns(uint){
        uint returnValue;
        uint diamondDynamicThresold = _diamondSupply.sub(_diamondAssigned);
        uint goldDynamicThresold = _goldSupply.sub(_goldAssigned);
        if(_value < diamondDynamicThresold){
            returnValue = uint(mangaVersion.DIAMOND);
        }
        if(diamondDynamicThresold <= _value && _value < goldDynamicThresold){
            returnValue = uint(mangaVersion.GOLD); 
        }
        if(goldDynamicThresold <= _value){
            returnValue = uint(mangaVersion.ORIGINAL);
        }
        return returnValue;
    }

    function getRandomMangaVersion(uint _mangaDistributionID) private returns(uint){
        uint diamondSupply = mangaDistribution[_mangaDistributionID].diamondSupply;
        uint goldSupply = mangaDistribution[_mangaDistributionID].goldSupply;
        uint originalSupply = mangaDistribution[_mangaDistributionID].originalSupply;
        uint diamondAssigned = mangaDistribution[_mangaDistributionID].diamondAssigned;
        uint goldAssigned = mangaDistribution[_mangaDistributionID].goldAssigned;
        uint originalAssigned = mangaDistribution[_mangaDistributionID].originalAssigned;
        uint totalSupply = diamondSupply.add(goldSupply).add(originalSupply);
        uint netSupply = totalSupply.sub(diamondAssigned).sub(goldAssigned).sub(originalAssigned);
        uint randomMangaVersionID = thresoldMappingMangaVersion(getRandom(netSupply.sub(uint(1))), diamondSupply, goldSupply, diamondAssigned, goldAssigned);
        if(randomMangaVersionID == uint(mangaVersion.DIAMOND)) {
            mangaDistribution[_mangaDistributionID].diamondAssigned = diamondAssigned.add(uint(1));
        }
        if(randomMangaVersionID == uint(mangaVersion.GOLD)) {
            mangaDistribution[_mangaDistributionID].goldAssigned = goldAssigned.add(uint(1));
        }
        if(randomMangaVersionID == uint(mangaVersion.ORIGINAL)) {
            mangaDistribution[_mangaDistributionID].originalAssigned = originalAssigned.add(uint(1));
        }
        return randomMangaVersionID;
    }

    function createMangaDistribution(uint _price, uint _diamondSupply, uint _goldSupply, uint _originalSupply, address[] memory _allowedAddressToMint, uint[] memory _quantityList, uint _ERC1155DiamondID, uint _ERC1155GoldID, uint _ERC1155OriginalID, string[] memory IPFSOverrideConnectionList) public onlyOwner returns(uint){
        uint totalSupply = _diamondSupply.add(_goldSupply).add(_originalSupply);
        require(totalSupply > uint(0), "CANT_SET_NULL_DISTRIBUTION");
        require(_allowedAddressToMint.length == _quantityList.length, "DATA_LENGTH_DISMATCH");
        uint sumQuantity = uint(0);
        for(uint quantityIndex = uint(0); quantityIndex < _quantityList.length; quantityIndex++){
            sumQuantity = sumQuantity.add(_quantityList[quantityIndex]);
        }
        require(sumQuantity == totalSupply, "QUANTITY_LENGTH_DISMATCH");
        uint mangaDistributionID = mangaDistributionIndex;
        mangaDistribution[mangaDistributionID].price = _price; // with decimals
        mangaDistribution[mangaDistributionID].diamondSupply = _diamondSupply;
        mangaDistribution[mangaDistributionID].goldSupply = _goldSupply;
        mangaDistribution[mangaDistributionID].originalSupply = _originalSupply;
        mangaDistribution[mangaDistributionID].ERC1155MangaIDs[uint(mangaVersion.DIAMOND)] = _ERC1155DiamondID;
        mangaDistribution[mangaDistributionID].ERC1155MangaIDs[uint(mangaVersion.GOLD)] = _ERC1155GoldID;
        mangaDistribution[mangaDistributionID].ERC1155MangaIDs[uint(mangaVersion.ORIGINAL)] = _ERC1155OriginalID;
        for(uint index = uint(0); index < _allowedAddressToMint.length; index++){
            mangaDistribution[mangaDistributionID].allowedAddressToMint[_allowedAddressToMint[index]] = _quantityList[index];
        }
        if(bytes(IPFSOverrideConnectionURI[_ERC1155DiamondID]).length == uint(0)) { IPFSOverrideConnectionURI[_ERC1155DiamondID] = IPFSOverrideConnectionList[0]; }
        if(bytes(IPFSOverrideConnectionURI[_ERC1155GoldID]).length == uint(0)) { IPFSOverrideConnectionURI[_ERC1155GoldID] = IPFSOverrideConnectionList[1]; }
        if(bytes(IPFSOverrideConnectionURI[_ERC1155OriginalID]).length == uint(0)) { IPFSOverrideConnectionURI[_ERC1155OriginalID] = IPFSOverrideConnectionList[2]; }
        mangaDistributionIndex = mangaDistributionID.add(1);
        emit createDistributionEvent(mangaDistributionID, msg.sender, _diamondSupply, _goldSupply, _originalSupply, _ERC1155DiamondID, _ERC1155GoldID, _ERC1155OriginalID);
        return mangaDistributionID;
    }

    function mintRandomManga(uint _mangaDistributionID) public payable returns(uint){
        uint price = mangaDistribution[_mangaDistributionID].price;
        require(msg.value == price, "PRICE_DISMATCH");
        ownerBalance = ownerBalance.add(price);
        uint allowedMangaToMint = mangaDistribution[_mangaDistributionID].allowedAddressToMint[msg.sender];
        require(allowedMangaToMint > uint(0), "MINT_NOT_ALLOWED");
        mangaDistribution[_mangaDistributionID].allowedAddressToMint[msg.sender] = allowedMangaToMint.sub(uint(1));
        uint mangaIDToAssign = getRandomMangaVersion(_mangaDistributionID);
        _mint(msg.sender, uint(mangaDistribution[_mangaDistributionID].ERC1155MangaIDs[mangaIDToAssign]), uint(1), bytes("0"));
        return mangaIDToAssign;
    }

    function withdrawOwnerBalance(address payable _to) public onlyOwner returns(bool){
        uint balance = ownerBalance;
        ownerBalance = uint(0);
        (bool sent, ) = _to.call{value : balance}("");
        require(sent, "ETHERS_NOT_SENT");
        emit withdrawOwnerBalanceEvent(_to, balance);
        return true;
    }

    function batchDistribution(uint _mangaDistributionID, uint _mangaVersion, address[] memory _addressList, uint[] memory _quantityList) public onlyOwner returns(bool){
        require(mangaDistributionIndex >= _mangaDistributionID, "INVALID_ID_REF");
        require(uint(0) < _mangaVersion && _mangaVersion <= uint(mangaVersion.DIAMOND), "INVALID_MANGA_VERSION");
        require(_addressList.length == _quantityList.length, "DATA_LENGTH_DISMATCH");
        uint assigned;
        uint supply;
        uint total = uint(0);
        for(uint index = uint(0); index < _quantityList.length; index++){
            require(_quantityList[index] > 0, "CANT_SET_ZERO_ELEMENTS");
            total = total.add(_quantityList[index]);
        }
        if(_mangaVersion == uint(mangaVersion.ORIGINAL)) {
            supply = mangaDistribution[_mangaDistributionID].originalSupply;
            assigned = mangaDistribution[_mangaDistributionID].originalAssigned;
            mangaDistribution[_mangaDistributionID].originalAssigned = assigned.add(total);
        }
        if(_mangaVersion == uint(mangaVersion.GOLD)) {
            supply = mangaDistribution[_mangaDistributionID].goldSupply;
            assigned = mangaDistribution[_mangaDistributionID].goldAssigned;     
            mangaDistribution[_mangaDistributionID].goldAssigned = assigned.add(total);
        }
        if(_mangaVersion == uint(mangaVersion.DIAMOND)) {
            supply = mangaDistribution[_mangaDistributionID].diamondSupply;
            assigned = mangaDistribution[_mangaDistributionID].diamondAssigned;   
            mangaDistribution[_mangaDistributionID].diamondAssigned = assigned.add(total);
        }
        require(total <= supply.sub(assigned), "NOT_ENOUGH_MANGA");
        uint allowedMint;
        uint[] memory tmpERC1155MangaIDsArray = new uint[](uint(3));
        tmpERC1155MangaIDsArray[uint(mangaVersion.DIAMOND).sub(uint(1))] = mangaDistribution[_mangaDistributionID].ERC1155MangaIDs[uint(mangaVersion.DIAMOND)];
        tmpERC1155MangaIDsArray[uint(mangaVersion.GOLD).sub(uint(1))] = mangaDistribution[_mangaDistributionID].ERC1155MangaIDs[uint(mangaVersion.GOLD)];
        tmpERC1155MangaIDsArray[uint(mangaVersion.ORIGINAL).sub(uint(1))] = mangaDistribution[_mangaDistributionID].ERC1155MangaIDs[uint(mangaVersion.ORIGINAL)];
        for(uint index = uint(0); index < _addressList.length; index++){
            allowedMint = mangaDistribution[_mangaDistributionID].allowedAddressToMint[_addressList[index]];
            require(allowedMint >= _quantityList[index], "NOT_ENOUGH_ALLOWED_MINT_FOR_SPECIFIC_ADDRESS");
            mangaDistribution[_mangaDistributionID].allowedAddressToMint[_addressList[index]] = allowedMint.sub(_quantityList[index]);
            _mint(_addressList[index], tmpERC1155MangaIDsArray[_mangaVersion.sub(1)], _quantityList[index], bytes("0"));
        }
        return true;
    }

    function getDistributionMetaData(uint _mangaDistributionID) public view returns(uint, uint, uint, uint, uint, uint, uint){
        return (mangaDistribution[_mangaDistributionID].price, mangaDistribution[_mangaDistributionID].diamondSupply, mangaDistribution[_mangaDistributionID].goldSupply, mangaDistribution[_mangaDistributionID].originalSupply, mangaDistribution[_mangaDistributionID].diamondAssigned, mangaDistribution[_mangaDistributionID].goldAssigned, mangaDistribution[_mangaDistributionID].originalAssigned);
    }

    function getAvailableMints(uint _mangaDistributionID, address _address) public view returns(uint){
        return mangaDistribution[_mangaDistributionID].allowedAddressToMint[_address];
    }

    function getERC1155MangaID(uint _mangaDistributionID, uint _mangaVersion) public view returns(uint){
        return mangaDistribution[_mangaDistributionID].ERC1155MangaIDs[_mangaVersion];
    }

    function deleteListOfDistribution(uint[] memory _distributionIDList) public onlyOwner returns(bool){
        for(uint index = uint(0); index < _distributionIDList.length; index++){
            delete mangaDistribution[_distributionIDList[index]];
        }
        return true;
    }

}
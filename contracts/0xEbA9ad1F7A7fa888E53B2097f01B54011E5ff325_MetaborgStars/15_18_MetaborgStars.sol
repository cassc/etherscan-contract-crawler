// SPDX-License-Identifier: MIT
// Smart Contract developed by MT

/*
  __  __ _____ _____  _    ____   ___  ____   ____   ____ _____  _    ____  ____  
 |  \/  | ____|_   _|/ \  | __ ) / _ \|  _ \ / ___| / ___|_   _|/ \  |  _ \/ ___| 
 | |\/| |  _|   | | / _ \ |  _ \| | | | |_) | |  _  \___ \ | | / _ \ | |_) \___ \ 
 | |  | | |___  | |/ ___ \| |_) | |_| |  _ <| |_| |  ___) || |/ ___ \|  _ < ___) |
 |_|  |_|_____| |_/_/   \_\____/ \___/|_| \_\\____| |____/ |_/_/   \_\_| \_\____/ 


*/
pragma solidity ^0.8.13;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol'; 
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol'; 
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol'; 
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MetaborgStars is ERC721Upgradeable, DefaultOperatorFiltererUpgradeable, OwnableUpgradeable {

    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint8;
    using StringsUpgradeable for uint256; 

    uint private randomizerIndex;
    uint private ownerBalance;
    uint8[] private availablePagesArray; 
    uint8[] private availableStarsArray; 
    uint public blockDelay;
    address public ERC1155Address;
    string public baseURI;
    uint8 public visibility;

    /*
        @dev: It will be a waterfall check based on the order specified by priority
    */

    enum visibilityInfo {
        OPEN,
        WHITELISTED,
        OWNER,
        OWNER_OR_WHITELISTED,
        OWNER_AND_WHITELISTED,
        CLOSED
    }

    struct groupPriceStruct {
        uint price1;
        uint pack1;
        uint price2;
        uint pack2;
        uint price3;
        uint pack3;
    }

    mapping(uint => groupPriceStruct) groupPriceMetaData;
    mapping(uint => bytes32) burnToPhysicalEdition;
    mapping(uint => uint) expirationBlock;
    mapping(address => bool) isWhitelisted;

    event initializeDataEvent(uint elements, bytes32 baseURI, address ERC1155Address);
    event withdrawOwnerBalanceEvent(address indexed to, uint amount);
    event setGroupPriceEvent(uint groupID, uint pack1, uint pack2, uint pack3, uint price1, uint price2, uint price3);
    event deletePriceEvent(uint price);
    event setContactPhysicalEditionEvent(uint tokenID, bytes32 email);
    event setBlockDelayEvent(uint oldDelay, uint newDelay);
    event setWhitelistEvent(address indexed to, bool isWhitelisted);
    event revealURIEvent(string oldURI, string newURI);

    function initialize(uint[] memory _availableIDs, uint8[] memory _stars, string memory _baseURI, address _ERC1155Address) initializer public {
        __ERC721_init("Metaborg Five Stars by Giovanni Motta", "Metaborg Five Stars");
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        require(!checkDuplicates(_availableIDs), "ONE_OR_MORE_ID_ALREADY_SET");
        ERC1155Address = _ERC1155Address;
        require(_stars.length < uint(256), "IPFS_LIST_TOO_LONG"); // Due to uint8 and project requirements
        for(uint index = uint(0); index < _stars.length; index++){
            require(_stars[index] >= 0 && _stars[index] <= 5, "STAR_VALUE_NOT_VALID");
            availableStarsArray.push(uint8(_stars[index]));
            availablePagesArray.push(uint8(_availableIDs[index]));
        }
        baseURI = _baseURI;
        emit initializeDataEvent(_stars.length, keccak256((abi.encodePacked(_baseURI))), _ERC1155Address);
    }

    function setWhitelistedAddresses(address[] memory _addresses, bool _toWhitelist) public onlyOwner returns(bool){
        require(_addresses.length > uint(0), "NOT_ENOUGH_ADDRESSES");
        for(uint index = uint(0); index < _addresses.length; index++){
            isWhitelisted[_addresses[index]] = _toWhitelist;
            emit setWhitelistEvent(_addresses[index], _toWhitelist);
        }
        return true;
    }

    /*
        @dev: By default the user group is OPEN
        @usr: We can have 4 cases: 0 (open), 1 (whitelisted), 2 (owner), 3 (whitelisted + owner)
    */
    function getUserGroup(address _address) public view returns(uint8){
        uint result = uint(visibilityInfo.OPEN); // = 0
        uint METABORG_DIAMOND_ID = uint(1);
        uint METABORG_GOLD_ID = uint(2);
        uint METABORG_ORIGINAL_ID = uint(3);
        IERC1155Upgradeable IERC1155 = IERC1155Upgradeable(ERC1155Address);
        require(ERC1155Address != address(0), "ERC1155_NOT_SET");
        isWhitelisted[_address] ? result = result.add(uint(visibilityInfo.WHITELISTED)) : uint(0); // = 1
        (IERC1155.balanceOf(_address, METABORG_DIAMOND_ID) > 0 || IERC1155.balanceOf(_address, METABORG_GOLD_ID) > 0 || IERC1155.balanceOf(_address, METABORG_ORIGINAL_ID) > 0) ? result = result.add(uint(visibilityInfo.OWNER)) : uint(0); // 2
        // = 3 if both
        return uint8(result);
    }
    /*
        @dev: Group ID is equals to 0 (open), 1 (whitelisted), 2 (owner), 3 (whitelisted+owner)
    */
    function setGroupMetaData(uint[] memory _prices, uint[] memory _packs, uint _groupID) public onlyOwner returns(bool){
        require(_prices.length == uint(3), "PRICE_ARRAY_LENGTH_DISMATCH");
        require(_packs.length == uint(3), "PACKS_ARRAY_LENGTH_DISMATCH");
        require(_groupID < uint(visibilityInfo.CLOSED), "GROUP_ID_NOT_VALID");
        groupPriceMetaData[_groupID].pack1 = _packs[0];
        groupPriceMetaData[_groupID].pack2 = _packs[1];
        groupPriceMetaData[_groupID].pack3 = _packs[2];
        groupPriceMetaData[_groupID].price1 = _prices[0];
        groupPriceMetaData[_groupID].price2 = _prices[1];
        groupPriceMetaData[_groupID].price3 = _prices[2];
        emit setGroupPriceEvent(_groupID, _packs[0], _packs[1], _packs[2], _prices[0], _prices[1], _prices[2]);
        return true;
    }

    function setWaitToBurn(uint _blocks) public onlyOwner returns(bool){
        blockDelay = _blocks;
        emit setBlockDelayEvent(blockDelay, _blocks);
        return true;
    }

    function setVisibility(uint8 _visibility) public onlyOwner returns(bool){
        require(visibility != _visibility, "SWITCH_DISMATCH");
        visibility = _visibility;
        return true;
    }

    // OPENSEA COMPATIBILITY OVERRIDE
    // BaseURI Example: "https://<your-gateway>.mypinata.cloud/ipfs/<CID-Folder>/"

    function tokenURI(uint256 _tokenId) public override view returns (string memory) {
        return string(abi.encodePacked(baseURI,_tokenId.toString(),".json"));
    }

    function revealURI(string memory _newBaseURI) public onlyOwner returns(bool){
        string memory oldBaseURI = baseURI;
        baseURI = _newBaseURI;
        emit revealURIEvent(oldBaseURI, _newBaseURI);
        return true;
    }

    // RANDOMIZER LOGIC

    function bytesToUint(bytes32 b) public pure returns (uint256){
        uint256 number;
        for(uint i=uint(0);i<b.length;i++){
            number = number + uint8(b[i]);
        }
        return number;
    }

    function getRandom(uint _externalMax) public returns(uint){ // _externalmax = numberOfElements
        require(_externalMax > 0, "CANT_DIVIDE_BY_ZERO");
        uint randomNumber = bytesToUint(bytes32(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, address(this), randomizerIndex++))));
        return randomNumber.mod(_externalMax);
    }

    function shiftArray8(uint8[] memory _array, uint8[] memory _indexesToDelete) public pure returns(uint8[] memory){ 
        uint k;
        bool f;
        uint8[] memory r = new uint8[](_array.length.sub(_indexesToDelete.length));
        for(uint i = uint(0); i < _array.length; i++){
            for(uint j = uint(0); j < _indexesToDelete.length; j++){
                f || i == _indexesToDelete[j] ? f = true : true; 
            }
            !f ? r[k++] = _array[i]: uint(0);
            f = false;
        }
        return r;
    }
 
    function checkVisibility(uint8 _userGroup) public view returns(bool){
        uint8 tmpVisibility = visibility;
        bool result;
        tmpVisibility == uint8(visibilityInfo.OPEN) && _userGroup <= uint(3) ? result = true : true; // OPEN TO EVERYONE
        tmpVisibility == uint8(visibilityInfo.WHITELISTED) && _userGroup == uint(1) ? result = true : true; // OPEN TO WHITELISTED
        tmpVisibility == uint8(visibilityInfo.OWNER) && _userGroup == uint(2) ? result = true : true; // OPEN TO OWNER
        tmpVisibility == uint8(visibilityInfo.OWNER_OR_WHITELISTED) && _userGroup == uint(1) || _userGroup == uint(2) ? result = true : true; // OPEN TO OWNER OR WHITELISTED
        tmpVisibility == uint8(visibilityInfo.OWNER_AND_WHITELISTED) && _userGroup == uint(3) ? result = true : true; // OPEN TO OWNER AND WHITELISTED
        return result;
    }

    function buyMetaborgStars() public payable returns(uint8[] memory){
        uint8 checkUserGroup = getUserGroup(msg.sender);
        require(checkVisibility(checkUserGroup), "RESTRICTED_FUNCTION");
        // GET METADATA
        (uint8 pack1, uint8 pack2, uint8 pack3, uint price1, uint price2, uint price3) = getAddressMetadata(msg.sender);
        require(pack1 > uint(0), "UNDETECTED_METADATA");
        uint8 packsPagesNumber;
        uint8[] memory tmpPagesAvailable = availablePagesArray;
        uint8[] memory tmpStarsAvailable = availableStarsArray;
        price1 == msg.value ? packsPagesNumber = pack1 : uint8(0);
        price2 == msg.value ? packsPagesNumber = pack2 : uint8(0);
        price3 == msg.value ? packsPagesNumber = pack3 : uint8(0);
        uint8[] memory randomIDList = new uint8[](uint(packsPagesNumber)); 
        require(packsPagesNumber > 0, "NOT_VALID_MSG_VALUE");
        require(tmpPagesAvailable.length >= packsPagesNumber, "NOT_ENOUGH_PAGES_AVAILABLE");
        // BUYING SYSTEM
        bool specialPage;
        uint8 pageID;
        uint stars;
        for(uint index = uint(0); index < packsPagesNumber; index++) {
            (pageID, tmpPagesAvailable, tmpStarsAvailable, stars) = buySinglePageAndGetPageID(tmpPagesAvailable, tmpStarsAvailable, index == packsPagesNumber.sub(1) && !specialPage && (packsPagesNumber == pack2 || packsPagesNumber == pack3), packsPagesNumber == pack3 ? true : false);
            stars == (packsPagesNumber == pack2 ? uint(3) : uint(4)) || stars == ((packsPagesNumber == pack2 ? uint(4) : uint(5))) ? specialPage = true : true; 
            randomIDList[index] = uint8(pageID);
        }
        availablePagesArray = new uint8[](tmpPagesAvailable.length);
        availableStarsArray = new uint8[](tmpStarsAvailable.length);
        availablePagesArray = tmpPagesAvailable;
        availableStarsArray = tmpStarsAvailable;
        ownerBalance = ownerBalance.add(msg.value);
        return randomIDList;
    }    

    function airdropManga(address[] memory _addresses, uint[] memory _IDs) public onlyOwner returns(bool){
        require(!checkDuplicates(_IDs), "ONE_OR_MORE_ID_ALREADY_SET");
        require(_addresses.length == _IDs.length, "LENGHT_DISMATCH");
        for(uint index = uint(0); index < _addresses.length; index++){
            _safeMint(_addresses[index], _IDs[index]);
        }
        return true;
    }

    function getForcedStarArray(uint8[] memory _starsArray, bool _isPackType3) private pure returns(uint8[] memory, uint){
        uint resultIndex = 0;
        for(uint index = uint(0); index < _starsArray.length; index++){
            if(_starsArray[index] == (!_isPackType3 ? uint(3) : uint(4)) || _starsArray[index] == (!_isPackType3 ? uint(4) : uint(5))) {
                _starsArray[resultIndex] = uint8(index);
                resultIndex++;
            }
        }
        return (_starsArray, resultIndex); 
    }

    function buySinglePageAndGetPageID(uint8[] memory _pagesAvailable, uint8[] memory _starsAvailable, bool _forceStar, bool _isPackType3) private returns(uint8, uint8[] memory, uint8[] memory, uint8){ 
        uint8[] memory randomIndex = new uint8[](1);
        uint8[] memory pageID = new uint8[](1);
        if(_forceStar) {
            (uint8[] memory availableForcedPagesArray, uint elements) = getForcedStarArray(_starsAvailable, _isPackType3);
            elements > 0 ? randomIndex[0] = availableForcedPagesArray[getRandom(elements)] : randomIndex[0] = uint8(getRandom(_pagesAvailable.length));    
        } else {
            randomIndex[0] = uint8(getRandom(_pagesAvailable.length));           
        }
        pageID[0] = _pagesAvailable[randomIndex[0]];
        _safeMint(msg.sender, pageID[0]);
        expirationBlock[pageID[0]] = (block.number).add(blockDelay);
        uint8 stars = _starsAvailable[randomIndex[0]];
        return (uint8(pageID[0]), shiftArray8(_pagesAvailable, randomIndex), shiftArray8(_starsAvailable, randomIndex), stars);
    }

    function withdrawOwnerBalance(address payable _to) public onlyOwner returns(bool){
        uint balance = ownerBalance;
        ownerBalance = uint(0);
        (bool sent, ) = _to.call{value : balance}("");
        require(sent, "ETHERS_NOT_SENT");
        emit withdrawOwnerBalanceEvent(_to, balance);
        return true;
    }

    function getAddressMetadata(address _address) public view returns(uint8, uint8, uint8, uint, uint, uint){
        groupPriceStruct memory groupPrice = groupPriceMetaData[getUserGroup(_address)];
        if(groupPrice.price1 == uint(0)) groupPrice = groupPriceMetaData[0]; 
        return (uint8(groupPrice.pack1), uint8(groupPrice.pack2), uint8(groupPrice.pack3), groupPrice.price1, groupPrice.price2, groupPrice.price3);
    }

    function burnAndReceivePhysicalEdition(uint _tokenID, string memory _email) public returns(bool){
        require(expirationBlock[_tokenID] <= block.number, "TOKEN_NOT_EXPIRED_YET");
        _burn(_tokenID); //owner check is inside the function
        bytes32 encryptEmail = keccak256(abi.encodePacked(address(this), _tokenID, _email));
        burnToPhysicalEdition[_tokenID] = encryptEmail;
        emit setContactPhysicalEditionEvent(_tokenID, encryptEmail);
        return true;
    }

    function checkEmail(uint _tokenID, string memory _email) public view returns(bool){
        bool result;
        burnToPhysicalEdition[_tokenID] == keccak256(abi.encodePacked(address(this), _tokenID, _email)) ? result = true : result = false;
        return result;
    }

    function blockToExpiration(uint _tokenID) public view returns(uint){
        uint result;
        uint expiration = expirationBlock[_tokenID];
        expiration <= block.number ? result = 0 : result = expiration.sub(block.number);
        return result;
    }

    function getAvailablePagesNumber() public view returns(uint){
        return availablePagesArray.length;
    }

    function checkDuplicates(uint[] memory _IDs) public view returns(bool){
        bool r;
        bool f;
        for(uint i = uint(0); i < _IDs.length; i++){
            for(uint j = uint(0); j < availablePagesArray.length; j++) f || availablePagesArray[j] == _IDs[i] ? f = true : true;
            r = r || f;
            f = false;
        }
        return r;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}
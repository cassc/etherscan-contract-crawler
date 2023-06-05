// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ContextMixin.sol";
import "./Royalty.sol";

contract HokagoCore is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ContextMixin,
    HasSecondarySaleFees,
    ReentrancyGuard
{

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        HasSecondarySaleFees(new address payable[](0), new uint256[](0))
    {
        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = 800;
        _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
    }


    //Event
    event levelUp(uint256 indexed tokenId, string indexed levelName, uint32 oldLevel, uint32 newLevel);
    event changeCharacterSheet(address indexed changer, uint256 indexed characterNo, string indexed key, string oldValue, string newValue);
    event addDiary(uint256 indexed tokenId, string diaryStr);


    //helper
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }   


    // Withdraw
    function withdrawETH()
        external
        onlyOwner
        nonReentrant
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    // Override
        function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);

        _transactionTimestamp[tokenId] = block.timestamp;
        if(from == address(0)){
            _setRandLevels(tokenId);
        }
        else if (tx.origin != msg.sender) {
            //only caller is contract
            _communicationLevelUp(tokenId);
        }
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        override
        view
        returns(bool isOperator)
    {
        return ERC721.isApprovedForAll(_owner, _operator);
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        virtual
        override(ERC721)
    {
        super.safeTransferFrom(from, to, tokenId);
    }
       
    function _burn(uint256 tokenId)
        internal
        onlyOwner
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory itemName)
        internal
        virtual
        override(ERC721URIStorage)
    {
        super._setTokenURI(tokenId, itemName);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, HasSecondarySaleFees)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) ||
        HasSecondarySaleFees.supportsInterface(interfaceId);
    }


    //CharacterDetail
    struct level{
        uint32 Creativity;
        uint32 Intelligence;
        uint32 Energy;
        uint32 Luck;
        uint32 CommunicationSkills;
    }

    mapping(uint256 => level) private _characterLevels;
    mapping(uint256 => string[]) private _ownerDiaries;
    mapping(uint256 => uint256) private _transactionTimestamp;
    mapping(uint256 => mapping(string => string)) private _characterSheet;

    bool public isLevelUp = false;
    address public fanFictionContract;

    function viewCharacterLevels(uint256 tokenId)
        public
        view
        returns (uint32[] memory)
    {
        uint32[] memory arrayMemory = new uint32[](5);
        arrayMemory[0] = _characterLevels[tokenId].Creativity;
        arrayMemory[1] = _characterLevels[tokenId].Intelligence;
        arrayMemory[2] = _characterLevels[tokenId].Energy;
        arrayMemory[3] = _characterLevels[tokenId].Luck;
        arrayMemory[4] = _characterLevels[tokenId].CommunicationSkills;

        return arrayMemory;
    }

    function viewLevelsByCharacter(uint256 characterNo)
        public
        view
        returns (uint32[] memory)
    {
        uint256 length = 2000;
        uint32[] memory arrayMemory = new uint32[](length);
        uint256 delta = (characterNo-1) * 400;

        for(uint256 i=1; i<=400; i++){
            uint256 baseNo = (i-1) * 5;
            arrayMemory[baseNo+0] = _characterLevels[i+delta].Creativity;
            arrayMemory[baseNo+1] = _characterLevels[i+delta].Intelligence;
            arrayMemory[baseNo+2] = _characterLevels[i+delta].Energy;
            arrayMemory[baseNo+3] = _characterLevels[i+delta].Luck;
            arrayMemory[baseNo+4] = _characterLevels[i+delta].CommunicationSkills;
        }
        return arrayMemory;
    }

    function generateRandLevels(uint256 tokenId)
        public
        view
        returns(uint256[] memory)
    {
        uint256[] memory arrayMemory = new uint256[](5);
        for(uint256 i=0; i<5; i++){
            arrayMemory[i] = uint256(keccak256(abi.encodePacked(address(this), i, tokenId))) % 4;
        }

        return arrayMemory;
    }

    function _setRandLevels(uint256 tokenId) private
    {
        uint256[] memory arrayMemory = new uint256[](5);
        arrayMemory = generateRandLevels(tokenId);

        _characterLevels[tokenId].Creativity = uint32(arrayMemory[0]);
        _characterLevels[tokenId].Intelligence = uint32(arrayMemory[1]);
        _characterLevels[tokenId].Energy = uint32(arrayMemory[2]);
        _characterLevels[tokenId].Luck = uint32(arrayMemory[3]);
        _characterLevels[tokenId].CommunicationSkills = uint32(arrayMemory[4]);
    }

    function viewDiary(uint256 tokenId)
        external
        view
        returns (string[] memory)
    {
        return _ownerDiaries[tokenId];
    }

    function setDiary(uint256 tokenId, string memory diaryStr) external {
        require(_msgSender() == ownerOf(tokenId), "you don't own this token");
        _ownerDiaries[tokenId].push(diaryStr);
        emit addDiary(tokenId, diaryStr);
    }

    function deleteDiary(uint256 tokenId, uint256 arrayNo)
        external
        onlyOwner
    {
        _ownerDiaries[tokenId][arrayNo] = "";
    }   

    
    //LevelUp!
    function startLevelUp()
        external
        onlyOwner
    {
        isLevelUp = true;
    }

    function stopLevelUp()
        external
        onlyOwner
    {
        isLevelUp = false;
    }

    function setFanFictionContractAddress(address contractAddress)
        external
        onlyOwner
    {
        fanFictionContract = contractAddress;
    }

    function devLevelUp(uint256[] memory tokenIds, uint256 abilityNo, uint32 levelUpSize)
        external
        onlyOwner
    {
        for (uint256 i=0; i<tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if(abilityNo == 1){
                _characterLevels[tokenId].Creativity += levelUpSize;
                if(_characterLevels[tokenId].Creativity > 10){
                    _characterLevels[tokenId].Creativity = 10;
                }
            }
            if(abilityNo == 2){
                _characterLevels[tokenId].Intelligence += levelUpSize;
                if(_characterLevels[tokenId].Intelligence > 10){
                    _characterLevels[tokenId].Intelligence = 10;
                }
            }
            if(abilityNo == 3){
                _characterLevels[tokenId].Energy += levelUpSize;
                if(_characterLevels[tokenId].Energy > 10){
                    _characterLevels[tokenId].Energy = 10;
                }
            }
            if(abilityNo == 4){
                uint32 oldLevel = _characterLevels[tokenId].Luck;
                _characterLevels[tokenId].Luck += levelUpSize;
                if(_characterLevels[tokenId].Luck > 10){
                    _characterLevels[tokenId].Luck = 10;
                }
                emit levelUp(tokenId, "Luck", oldLevel, _characterLevels[tokenId].Luck);
            }
            if(abilityNo == 5){
                _characterLevels[tokenId].CommunicationSkills += levelUpSize;
                if(_characterLevels[tokenId].CommunicationSkills > 10){
                    _characterLevels[tokenId].CommunicationSkills = 10;
                }
            }
        }
    }

    function intelligenceLevelUp(uint256 tokenId, uint32 levelUpSize)
        external
        payable
        callerIsUser
    {
        //0.02ETH * LevelUpSize
        uint256 Price = 20000000000000000 * uint256(levelUpSize);
        
        require(isLevelUp, "levelup is not available yet");
        require(msg.value >= Price, "need to send more ETH");
        require(_msgSender() == ownerOf(tokenId), "you don't own this token");
        require((_characterLevels[tokenId].Intelligence + levelUpSize) <= 10, "request levelup size is over max level");

        uint32 oldLevel = _characterLevels[tokenId].Intelligence;
        _characterLevels[tokenId].Intelligence += levelUpSize;

        emit levelUp(tokenId, "Intelligence", oldLevel, _characterLevels[tokenId].Intelligence);
    }

    function _communicationLevelUp(uint256 tokenId) private {
        if(isLevelUp){
            if(_characterLevels[tokenId].CommunicationSkills < 10){
                uint32 oldLevel = _characterLevels[tokenId].CommunicationSkills;
                _characterLevels[tokenId].CommunicationSkills++;
                emit levelUp(tokenId, "CommunicationSkills", oldLevel, _characterLevels[tokenId].CommunicationSkills);
            }
        }
    }

    function energyLevelUp(uint256 tokenId) external {
        require(isLevelUp, "Levelup is not available yet");
        require(_msgSender() == ownerOf(tokenId), "You don't own this token");
        require(_characterLevels[tokenId].Energy < 10, "Already max level");
        
        //30 days
        uint256 period = 2592000;
        uint256 levelUpCount = (block.timestamp - _transactionTimestamp[tokenId]) / period;
        if(levelUpCount > 0){
            uint32 oldLevel = _characterLevels[tokenId].Energy;
            _characterLevels[tokenId].Energy += uint32(levelUpCount);
            if(_characterLevels[tokenId].Energy > 10){
                _characterLevels[tokenId].Energy = 10;
            }
            emit levelUp(tokenId, "Energy", oldLevel, _characterLevels[tokenId].Energy);
        }
    }

    function creativityLevelUp(uint256 tokenId) external {
        require(_msgSender() == fanFictionContract, "Not specific contract");
        if(isLevelUp){
            if(_characterLevels[tokenId].Creativity < 10){
                uint32 oldLevel = _characterLevels[tokenId].Creativity;
                _characterLevels[tokenId].Creativity++;
                emit levelUp(tokenId, "Creativity", oldLevel, _characterLevels[tokenId].Creativity);
            }
        }
    }

    function viewOwnershipPeriod(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        //return ownership period by day(s)
        if(_transactionTimestamp[tokenId] == 0){
            return 0;
        }
        else{
            return (block.timestamp - _transactionTimestamp[tokenId]) / 86400;
        }
    } 


    //CharacterSheet
    function setCharacterSheet(uint256 characterNo, string memory key, string memory value) external {
        bool isTokenOwner = false;
        uint256 lastTokenIndex = balanceOf(_msgSender());
        uint256 startNo = ((characterNo-1) * 400) + 1;
        uint256 endNo = characterNo * 400;
        string memory oldValue;

        for(uint256 i=0; i<lastTokenIndex; i++){
            uint256 tokenId = tokenOfOwnerByIndex(_msgSender(), i);
            if((startNo <= tokenId) && (tokenId <= endNo)){
                isTokenOwner = true;
            }
        }

        require(isTokenOwner, "You don't own this character token");
        oldValue = _characterSheet[characterNo][key];
        _characterSheet[characterNo][key] = value;

        emit changeCharacterSheet(_msgSender(), characterNo, key, oldValue, value);
    }

    function viewCharacterSheet(uint256 characterNo, string memory key)
        public
        view
        returns(string memory)
    {
        return _characterSheet[characterNo][key];
    }
    
    receive() external payable {}
}
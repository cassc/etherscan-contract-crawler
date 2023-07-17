// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {AccessControlEnumerable} from '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {IISBStaticData} from '../interface/IISBStaticData.sol';
import {IISGData} from '../interface/IISGData.sol';

contract ISGData is IISGData, AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
    bytes32 public constant STATUS_SETTER_ROLE = keccak256('STATUS_SETTER_ROLE');
    bytes32 public constant LEVEL_SETTER_ROLE = keccak256('LEVEL_SETTER_ROLE');
    bytes32 public constant CHARACTER_SETTER_ROLE = keccak256('CHARACTER_SETTER_ROLE');

    IISBStaticData.EtherPrices public override etherPrices =
        IISBStaticData.EtherPrices(
            0.06 ether,
            0.059 ether,
            0.058 ether,
            0.055 ether,
            0.055 ether,
            0.054 ether,
            0.053 ether,
            0.050 ether
        );
    IISBStaticData.TokenPrices public override tokenPrices;
    IISBStaticData.Character[] public override characters;
    string[] public override images;
    IISBStaticData.StatusMaster[] public override statusMasters;
    mapping(uint256 => IISBStaticData.Metadata) public override metadatas;

    uint256 public override gen0Supply = 50000;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(STATUS_SETTER_ROLE, _msgSender());
        _setupRole(LEVEL_SETTER_ROLE, _msgSender());
        _setupRole(CHARACTER_SETTER_ROLE, _msgSender());
        statusMasters.push(IISBStaticData.StatusMaster('ATK', true));
        statusMasters.push(IISBStaticData.StatusMaster('DEF', true));
        statusMasters.push(IISBStaticData.StatusMaster('LUK', false));
    }

    function setEtherPrices(IISBStaticData.EtherPrices memory _newPrices)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        etherPrices = _newPrices;
    }

    function setTokenPrices(IISBStaticData.TokenPrices memory _newPrices)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenPrices = _newPrices;
    }

    function setGen0Supply(uint256 _newGen0Supply) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        gen0Supply = _newGen0Supply;
    }

    function addCharactor(IISBStaticData.Character memory _newCharacter)
        external
        override
        onlyRole(CHARACTER_SETTER_ROLE)
    {
        characters.push(_newCharacter);
    }

    function addImage(string memory _newImage) external override onlyRole(CHARACTER_SETTER_ROLE) {
        images.push(_newImage);
    }

    function addStatusMaster(IISBStaticData.StatusMaster memory _newStatus)
        external
        override
        onlyRole(CHARACTER_SETTER_ROLE)
    {
        statusMasters.push(_newStatus);
    }

    function setCharactor(IISBStaticData.Character memory _newCharacter, uint256 id)
        external
        override
        onlyRole(CHARACTER_SETTER_ROLE)
    {
        characters[id] = _newCharacter;
    }

    function setImage(string memory _newImage, uint256 id) external override onlyRole(CHARACTER_SETTER_ROLE) {
        images[id] = _newImage;
    }

    function setCanBuyCharacter(uint16 characterId, bool canBuy) external override onlyRole(CHARACTER_SETTER_ROLE) {
        IISBStaticData.Character memory char = characters[characterId];
        char.canBuy = canBuy;
        characters[characterId] = char;
    }

    function incrementLevel(uint256 tokenId) external override onlyRole(LEVEL_SETTER_ROLE) {
        metadatas[tokenId].level += 1;
    }

    function decrementLevel(uint256 tokenId) external override onlyRole(LEVEL_SETTER_ROLE) {
        if (metadatas[tokenId].level == 1) revert();
        metadatas[tokenId].level -= 1;
    }

    function setLevel(uint256 tokenId, uint16 level) external override onlyRole(LEVEL_SETTER_ROLE) {
        if (level == 0) revert();
        metadatas[tokenId].level = level;
    }

    function addSeed(uint256 tokenId, IISBStaticData.Status memory seed)
        external
        override
        onlyRole(STATUS_SETTER_ROLE)
    {
        metadatas[tokenId].seedHistory.push(seed);
    }

    function getCharactersLength() external view override returns (uint256) {
        return characters.length;
    }

    function getImagesLength() external view override returns (uint256) {
        return images.length;
    }

    function getStatusMastersLength() external view override returns (uint256) {
        return statusMasters.length;
    }

    function getSeedHistory(uint256 tokenId) external view override returns (IISBStaticData.Status[] memory) {
        return metadatas[tokenId].seedHistory;
    }

    function getDefaultStatus(uint16 characterId) external view override returns (IISBStaticData.Status[] memory) {
        return characters[characterId].defaultStatus;
    }

    function getGenneration(uint256 tokenId) public view override returns (IISBStaticData.Generation) {
        if (tokenId <= gen0Supply) {
            return IISBStaticData.Generation.GEN0;
        }
        if (tokenId % 10 == 0) {
            return IISBStaticData.Generation.GEN05;
        }
        return IISBStaticData.Generation.GEN1;
    }

    function getGOVPrice(uint256 length) public view override returns (uint256) {
        if (length < 5) {
            return tokenPrices.GOVPrice1;
        } else if (length < 10) {
            return tokenPrices.GOVPrice2;
        } else if (length < 15) {
            return tokenPrices.GOVPrice3;
        } else {
            return tokenPrices.GOVPrice4;
        }
    }

    function getSINNPrice(uint256 length) public view override returns (uint256) {
        if (length < 5) {
            return tokenPrices.SINNPrice1;
        } else if (length < 10) {
            return tokenPrices.SINNPrice2;
        } else if (length < 15) {
            return tokenPrices.SINNPrice3;
        } else {
            return tokenPrices.SINNPrice4;
        }
    }

    function getPrice(uint256 length) public view override returns (uint256) {
        if (length < 5) {
            return etherPrices.mintPrice1;
        } else if (length < 10) {
            return etherPrices.mintPrice2;
        } else if (length < 15) {
            return etherPrices.mintPrice3;
        } else {
            return etherPrices.mintPrice4;
        }
    }

    function getWLPrice(uint256 length) public view override returns (uint256) {
        if (length < 5) {
            return etherPrices.wlMintPrice1;
        } else if (length < 10) {
            return etherPrices.wlMintPrice2;
        } else if (length < 15) {
            return etherPrices.wlMintPrice3;
        } else {
            return etherPrices.wlMintPrice4;
        }
    }

    function getStatus(uint256 tokenId) public view override returns (uint16[] memory) {
        return getStatus(tokenId, 65535);
    }

    function getStatus(uint256 tokenId, uint16 userLevel) public view override returns (uint16[] memory) {
        IISBStaticData.Character memory char = characters[metadatas[tokenId].characterId];
        uint16[] memory status = new uint16[](statusMasters.length);
        for (uint256 i = 0; i < metadatas[tokenId].seedHistory.length; i++) {
            if (i == metadatas[tokenId].level || i == userLevel) break;
            status[metadatas[tokenId].seedHistory[i].statusId] += metadatas[tokenId].seedHistory[i].status;
        }
        uint16 maxLevel = metadatas[tokenId].level < userLevel ? metadatas[tokenId].level : userLevel;
        for (uint256 i = 0; i < statusMasters.length; i++) {
            if (statusMasters[i].withLevel) {
                status[i] += maxLevel;
            }
        }
        for (uint256 i = 0; i < char.defaultStatus.length; i++) {
            status[char.defaultStatus[i].statusId] += char.defaultStatus[i].status;
        }
        return status;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(AccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }
}
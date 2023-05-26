// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./structs/DragonInfo.sol";
import "./structs/EggInfo.sol";
import "./utils/GenesLib.sol";
import "./utils/Random.sol";
import "./access/BaseAccessControl.sol";
import "./DragonCreator.sol";

contract EggToken is ERC721, BaseAccessControl {

    using SafeMath for uint;
    using Address for address;
    using Counters for Counters.Counter;

    uint constant THRESHOLD_DENOMINATOR = 1e8;

    Counters.Counter private _tokenIds;

    mapping(uint => uint) private _info;
    mapping(uint => string) private _cids;
    mapping(uint => string) private _hatchCids;

    mapping(DragonInfo.Types => uint) private _randomDragonSupply;
    mapping(DragonInfo.Types => uint) private _totalEggSupply;
    mapping(DragonInfo.Types => uint) private _eggCounts;

    uint internal _totalSupply;
    
    uint internal _hatchTime;
    address internal _dragonCreatorAddress;
    address internal _eggMarketAddress;

    string private _defaultMetadataCid;
    
    GenesLib.GenesRange private COMMON_RANGE;
    GenesLib.GenesRange private RARE_RANGE;
    GenesLib.GenesRange private EPIC_RANGE;

    event EggHatched(address indexed operator, uint eggId, uint dragonId);
    
    constructor(
        uint totalEggSply,
        uint totalEpic20EggSply,
        uint totalLegendaryEggSply,
        uint randomLegendaryDragonSply, 
        uint randomEpic20DragonSply, 
        uint randomCommonDragonSply, 
        uint htchTime,
        string memory defaultCid,
        address accessControl,
        address dragonCreator) ERC721("CryptoDragons Eggs", "CDE") BaseAccessControl(accessControl) {
        
        uint totalRandomEggSupply = randomLegendaryDragonSply + randomEpic20DragonSply + randomCommonDragonSply;
        require(totalEggSply == totalEpic20EggSply + totalLegendaryEggSply + totalRandomEggSupply, 
            "EggToken: inconsistent constructor arguments");
        
        _totalSupply = totalEggSply;

        _totalEggSupply[DragonInfo.Types.Unknown] = totalRandomEggSupply;
        _totalEggSupply[DragonInfo.Types.Epic20] = totalEpic20EggSply;
        _totalEggSupply[DragonInfo.Types.Legendary] = totalLegendaryEggSply;
        
        _randomDragonSupply[DragonInfo.Types.Legendary] = randomLegendaryDragonSply;
        _randomDragonSupply[DragonInfo.Types.Epic20] = randomEpic20DragonSply;
        _randomDragonSupply[DragonInfo.Types.Common] = randomCommonDragonSply;
        
        _hatchTime = htchTime; 
        _defaultMetadataCid = defaultCid;

        _dragonCreatorAddress = dragonCreator;

        COMMON_RANGE = GenesLib.GenesRange({from: 0, to: 15});
        RARE_RANGE = GenesLib.GenesRange({from: 15, to: 20});
        EPIC_RANGE = GenesLib.GenesRange({from: 20, to: 25});
    }

    function approveAndCall(address spender, uint256 tokenId, bytes calldata extraData) external returns (bool success) {
        _approve(spender, tokenId);
        (bool _success, ) = 
            spender.call(
                abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes)", 
                _msgSender(), 
                tokenId, 
                address(this), 
                extraData) 
            );
        if(!_success) { 
            revert("EggToken: spender internal error"); 
        }
        return true;
    }

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function totalEggSupply(DragonInfo.Types drgType) public view returns(uint) {
        return _totalEggSupply[drgType];
    }

    function randomDragonSupply(DragonInfo.Types drgType) external view returns(uint) {
        return _randomDragonSupply[drgType];
    }

    function currentEggCount(DragonInfo.Types drgType) public view returns(uint) {
        return _eggCounts[drgType];
    }

    function defaultMetadataCid() public view returns (string memory){
        return _defaultMetadataCid;
    }

    function setDefaultMetadataCid(string calldata newDefaultCid) external onlyRole(COO_ROLE) {
        _defaultMetadataCid = newDefaultCid;
    }

    function setMetadataCids(uint tokenId, string calldata cid, string calldata hatchCid) external onlyRole(COO_ROLE) {
        require(bytes(cid).length >= 46 && bytes(hatchCid).length >= 46, "EggToken: bad CID");
        require(!hasMetadataCids(tokenId), "EggToken: CIDs are already set");
        _cids[tokenId] = cid;
        _hatchCids[tokenId] = hatchCid;
    }

    function hasMetadataCids(uint tokenId) public view returns(bool) {
        return bytes(_hatchCids[tokenId]).length > 0;
    }

    function hatchTime() public view returns(uint) {
        return _hatchTime;
    }

    function setHatchTime(uint newValue) external onlyRole(COO_ROLE) {
        uint previousValue = _hatchTime;
        _hatchTime = newValue;
        emit ValueChanged("hatchTime", previousValue, newValue);
    }

    function dragonCreatorAddress() public view returns(address) {
        return _dragonCreatorAddress;
    }

    function setDragonCreatorAddress(address newAddress) external onlyRole(CEO_ROLE) {
        address previousAddress = _dragonCreatorAddress;
        _dragonCreatorAddress = newAddress;
        emit AddressChanged("dragonCreator", previousAddress, newAddress);
    }

    function eggMarketAddress() public view returns(address) {
        return _eggMarketAddress;
    }

    function setEggMarketAddress(address newAddress) external onlyRole(CEO_ROLE) {
        address previousAddress = _eggMarketAddress;
        _eggMarketAddress = newAddress;
        emit AddressChanged("eggMarket", previousAddress, newAddress);
    }

    function canHatch(uint tokenId) external view returns(bool) {
        EggInfo.Details memory info = eggInfo(tokenId);
        return _canHatch(info);
    }

    function isHatched(uint tokenId) external view returns(bool) {
        EggInfo.Details memory info = eggInfo(tokenId);
        return info.hatchedAt > 0;
    }

    function eggInfo(uint tokenId) public view returns(EggInfo.Details memory) {
        require(_exists(tokenId), "EggToken: nonexistent token");
        return EggInfo.getDetails(_info[tokenId]);
    }

    function _canHatch(EggInfo.Details memory info) internal view returns(bool) {
        return info.hatchedAt == 0 && block.timestamp >= hatchTime();
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        EggInfo.Details memory info = eggInfo(tokenId);
        return string(abi.encodePacked("ipfs://", (info.hatchedAt > 0) ? _hatchCids[tokenId] : _cids[tokenId]));
    }

    function mint(address to, DragonInfo.Types _dragonType) external returns (uint) {
        require(_tokenIds.current() < totalSupply(), "EggToken: supply is exceeded");
        require(hasRole(CEO_ROLE, _msgSender()) || _msgSender() == eggMarketAddress(), 
            "EggToken: not enough privileges to call the method");
        require(to != address(0), "EggToken: wrong address");

        require(_dragonType == DragonInfo.Types.Epic20 
            || _dragonType == DragonInfo.Types.Legendary 
            || _dragonType == DragonInfo.Types.Unknown, "EggToken: wrong dragon type");
        
        require(currentEggCount(_dragonType) < totalEggSupply(_dragonType), 
            "EggToken: total supply for the given dragon type is exceeded");
        
        _eggCounts[_dragonType]++;
        _tokenIds.increment();
        
        uint newTokenId = _tokenIds.current();
        _mint(to, newTokenId);
        
        _info[newTokenId] = EggInfo.getValue(EggInfo.Details({
            mintedAt: block.timestamp,
            dragonType: _dragonType,
            hatchedAt: 0,
            dragonId: 0
        }));
        _cids[newTokenId] = defaultMetadataCid();

        return newTokenId;
    }

    function hatch(uint tokenId) external {
        EggInfo.Details memory info = eggInfo(tokenId);
        require(ownerOf(tokenId) == _msgSender(), "EggToken: hatch caller is not owner");
        require(_canHatch(info), "EggToken: cannot be hatched");

        (DragonInfo.Types dragonType, uint genes) = _randomGenes(info);
        _randomDragonSupply[dragonType]--;

        uint newDragonId = DragonCreator(dragonCreatorAddress()).giveBirth(tokenId, genes, _msgSender());

        info.hatchedAt = block.timestamp;
        info.dragonId = newDragonId;
        _info[tokenId] = EggInfo.getValue(info);

        emit EggHatched(_msgSender(), tokenId, newDragonId);
    }

    function _randomGenes(EggInfo.Details memory info) internal view returns (DragonInfo.Types, uint) {
        DragonInfo.Types t = (info.dragonType == DragonInfo.Types.Unknown) 
            ? _randomDragonType(info.mintedAt ^ block.difficulty ^ block.timestamp) : info.dragonType;
        
        uint genes = GenesLib.randomSetGenesToPositions(
            0, GenesLib.createOrderedRangeArray(COMMON_RANGE.from, COMMON_RANGE.to), 
            Random.rand(info.mintedAt ^ block.number ^ block.difficulty), true);
        
        if (t == DragonInfo.Types.Epic20) {
            genes = GenesLib.randomSetGenesToPositions(
                genes, GenesLib.createOrderedRangeArray(RARE_RANGE.from, RARE_RANGE.to), 
                Random.rand(block.difficulty ^ info.mintedAt ^ block.timestamp), false);
        }
        else if (t == DragonInfo.Types.Legendary) {
            genes = GenesLib.randomSetGenesToPositions(
                genes, GenesLib.createOrderedRangeArray(RARE_RANGE.from, EPIC_RANGE.to), 
                Random.rand(info.mintedAt ^ block.number ^ block.timestamp ^ block.difficulty), false);
        }

        return (t, genes);
    } 
 

    function _randomDragonType(uint salt) internal view returns (DragonInfo.Types) {
        uint remainingLegendarySupply = _randomDragonSupply[DragonInfo.Types.Legendary];
        uint remainingEpic20Supply = _randomDragonSupply[DragonInfo.Types.Epic20];
        uint remainingCommonSupply = _randomDragonSupply[DragonInfo.Types.Common];

        uint remainingTotalSupply = remainingLegendarySupply.add(remainingEpic20Supply).add(remainingCommonSupply);
        
        uint r = Random.rand(salt).mod(THRESHOLD_DENOMINATOR);
        if (r <= _calcDragonThreshold(remainingLegendarySupply, remainingTotalSupply)) {
            return DragonInfo.Types.Legendary;
        }
        else if (r <= _calcDragonThreshold(remainingEpic20Supply, remainingTotalSupply)) {
            return DragonInfo.Types.Epic20;
        }
        else {
            return DragonInfo.Types.Common;
        }
    }

    function _calcDragonThreshold(uint remainingDragonSupply, uint remainingTotalSupply) pure internal returns (uint) {
        return remainingDragonSupply.mul(THRESHOLD_DENOMINATOR).div(remainingTotalSupply);
    }
}
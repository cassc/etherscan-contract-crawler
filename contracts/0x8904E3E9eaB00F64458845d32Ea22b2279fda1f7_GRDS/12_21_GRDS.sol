/*
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░                                ░░
░░                                ░░     
░░             .----.             ░░          
░░          .´        `.          ░░    
░░         /            \         ░░  
░░        .              ·        ░░     
░░        |     GRDS     |        ░░     
░░        '              '        ░░     
░░         \            /         ░░   
░░          `.        .´          ░░ 
░░             ` ''' ´            ░░
░░                                ░░
░░   BURN -> COMBINE -> COMPLETE  ░░
░░                                ░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IGRDS.sol";
import "./GRDSNexus.sol";
import "./interfaces/IERC4906.sol";


contract GRDS is Ownable, ERC721ABurnable, ERC721AQueryable, IERC4906, IGRDS, ReentrancyGuard {

    address _GRDSNexus;
    GRDSNexus _nexusContract;

    error AmountTooHigh();
    error MaxSupplyReached();
    error TokenDoesNotExist();
    error BurnTokensRequired();
    error NotOwnerOfKeep();
    error UsingAlreadyBurnedToken();
    error PublicMintingPaused();
    error ReachedMaxLevel();

    uint public MINTS_PUBLIC = 14000;
    uint MINTS_RESERVE = 444;
    uint public price  = 0.01 ether;

    uint SEED_NONCE = 0;
    uint16[][2] TRAITS;
    mapping(uint => uint32) public singles;
    mapping(uint => uint32[]) public groupings;
    mapping(uint => bool) public burns;

    bool _paused;
    bool cloningToggle;

    constructor() ERC721A("GRDS", "GRDS") {

      TRAITS[0] = [
        1054, 1049, 1025, 1033, 1037,
        825,  829,  809,  789,  793,
        602,  574,  578,  570,  562,
        367,  355,  347,  339,  327,
        132,  124,  116,  108,  100
      ];
      TRAITS[1] = [
        1266, 1204, 1045, 1014, 1014,
        950, 824, 824, 729, 634,
        570, 538, 538, 507, 412,
        348, 253, 253, 222, 222,
        190, 190, 190, 190, 190, 127
      ];

    }

    function setNexus(address _nexusAddress) external onlyOwner {
      _GRDSNexus = _nexusAddress;
      _nexusContract = GRDSNexus(_nexusAddress);
    }

    function lowerPublicAmount(uint16 _amount) external onlyOwner {
        require( _amount < 14000, "Cannot set the public amount higher than 14000");
        MINTS_PUBLIC = _amount;
    }

    function setPrice(uint _newPrice) external onlyOwner {
        price = _newPrice;
    }
    function setCloningState(bool _cloneState) external onlyOwner {
        cloningToggle = _cloneState;
    }

    function checkExistance(uint _tokenID) internal view returns (bool) {
        bool _present = _exists(_tokenID);
        if (!_present) {
            return false;
        }
        return true;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mint(uint _amount) external payable {

        if (!_paused) { revert('PublicMintingPaused'); }

        require(msg.value >= _amount * price, "Not enough eth");
        if (_amount > 50) { revert AmountTooHigh(); }

        uint supply = totalSupply();
        if (supply + _amount > MINTS_PUBLIC) { revert MaxSupplyReached(); }

        uint _firstTokenID = _nextTokenId();

        _mint(msg.sender, _amount);
        assignHashes(_firstTokenID, msg.sender, _amount);
    }

    function reserveMint(uint _amount) external onlyOwner {

        uint supply = totalSupply();

        if (supply != MINTS_PUBLIC) { revert('Cannot mint reserve before all public is minted out'); }
        if (supply + _amount > MINTS_PUBLIC + MINTS_RESERVE) { revert MaxSupplyReached(); }

        uint _firstTokenID = _nextTokenId();

        _mint(msg.sender, _amount);
        assignHashes(_firstTokenID, msg.sender, _amount);
    }

    function merge(uint _toKeepID, uint[] memory _burnsIDs) public {
        if (_burnsIDs.length < 1) { revert BurnTokensRequired(); }
        if (ownerOf(_toKeepID) != msg.sender) { revert NotOwnerOfKeep(); }
        uint _totalCount;
        for (uint i = 0; i < _burnsIDs.length; i++) {
            require(
                ownerOf(_burnsIDs[i]) == msg.sender,
                "Must own all tokens to merge"
            );
            require(
                !burns[_burnsIDs[i]],
                "Cannot merge a token that has been burned"
            );
            require(
                _burnsIDs[i] != _toKeepID,
                "Cannot merge a token with itself"
            );
            if ( groupings[_burnsIDs[i]].length > 0 ) {
                _totalCount += groupings[_burnsIDs[i]].length;
            } else {
                _totalCount++;
            }
        }

        if ( groupings[_toKeepID].length > 0 ) {
            _totalCount += groupings[_toKeepID].length;
            if (_totalCount > 49) { revert ReachedMaxLevel(); }
        } else { 
            _totalCount++; 
            if (_totalCount > 49) { revert ReachedMaxLevel(); }
            groupings[_toKeepID].push(singles[_toKeepID]);
        }

        for (uint i = 0; i < _burnsIDs.length; i++) {
            if (groupings[_burnsIDs[i]].length > 0) {
                extractAndAssignGroup(_toKeepID, groupings[_burnsIDs[i]]);
                burn(_burnsIDs[i]);
                burns[_burnsIDs[i]] = true;
            } else {
                uint32 _s = singles[_burnsIDs[i]];
                groupings[_toKeepID].push(_s);
                burn(_burnsIDs[i]);
                burns[_burnsIDs[i]] = true;
            }
        }
        emit MetadataUpdate(_toKeepID);
    }

    function clone(uint _gIDKeep, uint _gIDBurn) public {
        require( !cloningToggle, 'Cloning is deactivated');
        if (ownerOf(_gIDKeep) != msg.sender) { revert NotOwnerOfKeep(); }
        require( ownerOf(_gIDBurn) == msg.sender, "Must own all tokens to clone" );
        require(!burns[_gIDBurn],"Cannot clone a token that has been burned");
        require(_gIDBurn != _gIDKeep,"Cannot clone a token with itself");
        uint8[5] memory _sizes = [4,9,16,25,36];

        bool _keepSizeValid = false;
        uint _keepSize = groupings[_gIDKeep].length;
        for (uint i = 1; i < _sizes.length; i++) {
            if (_keepSize == _sizes[i]) {
                _keepSizeValid = true; break;
            }
        }
        require(_keepSizeValid, "Keep requirements not met");
        
        bool _burnSizeValid = false;
        uint _burnSize = groupings[_gIDBurn].length;
        for (uint i = 0; i < _sizes.length; i++) {
            if (_burnSize == _sizes[i]) {
                _burnSizeValid = true; break;
            }
        }
        require(_burnSizeValid, "Cloning Requirements not met");
        require( _burnSize <= _keepSize, "Burns size must be LTE Keep size");
        require( _keepSize + _burnSize < 49, "The upper bound is 49");

        uint16 _keepSidHash = uint16(groupings[_gIDKeep][0]);
        for (uint i = 1; i < groupings[_gIDKeep].length; i++) {
            require(uint16(groupings[_gIDKeep][i]) == _keepSidHash, "Only Keep tokens with symbols of the same kind allowed");
        }
        uint8 _i = (2 * getSacrificeValue(_burnSize, _sizes)) - 1;
        for (uint i = 0; i < _i; i++) {
            uint32 _newHash = (groupings[_gIDBurn][i] & 0xFFFF0000) | _keepSidHash;
            groupings[_gIDKeep].push(_newHash);
        }
        burn(_gIDBurn);
        burns[_gIDBurn] = true;
        emit MetadataUpdate(_gIDKeep);
    }

    function getSacrificeValue(uint num, uint8[5] memory numbers) private pure returns (uint8) {
        for (uint i = 0; i < numbers.length; i++) {
            if (numbers[i] == num) {
                return uint8(i) + 1;
            }
        }
        revert("Number not found");
    }




    function getGroupings(uint _tokenID) internal view returns (uint32[] memory) {
        return groupings[_tokenID];
    }
    function getUint32Values(uint32 _packedUint) internal view returns (uint8, uint8) {

        uint8 cid = sampleBuckets(uint16(_packedUint >> 16), 0);
        uint8 sid = sampleBuckets(uint16(_packedUint & 0xFFFF),1);

        return (uint8(cid), uint8(sid));
    }
    function getSingles(uint _tokenID) internal view returns (uint32) {
        return singles[_tokenID];
    }
    function getSinglesValues(uint _tokenID) internal view returns (uint8, uint8) {
        uint32 _s = singles[_tokenID];
        return getUint32Values(_s);
    }

    function getGroupingsValues(uint _tokenID) internal view returns (uint8[] memory, uint8[] memory) {
        uint32[] memory _groupings = groupings[_tokenID];
        uint8[] memory _cids = new uint8[](_groupings.length);
        uint8[] memory _sids = new uint8[](_groupings.length);
        for (uint i = 0; i < _groupings.length; i++) {
            (_cids[i], _sids[i]) = getUint32Values(_groupings[i]);
        }
        return (_cids, _sids);
    }


    function extractAndAssignGroup(uint _toKeepID, uint32[] memory toBeBurnedGrouping) private {
      for (uint i = 0; i < toBeBurnedGrouping.length; i++) {
        uint32 _s = toBeBurnedGrouping[i];
        groupings[_toKeepID].push(_s);
      }
    }

    function sampleBuckets(
        uint16 _randomHash,
        uint8 _bucketIndex
    ) internal view returns (uint8) {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TRAITS[_bucketIndex].length; i++) {
            uint16 thisPercentage = TRAITS[_bucketIndex][i];
            if (
                _randomHash >= currentLowerBound &&
                _randomHash < currentLowerBound + thisPercentage
            ) return i; // returns an uint8 corresponding to the index of the trait
            currentLowerBound = currentLowerBound + thisPercentage;
        }
        revert();
    }

    function assignHashes(uint _t, address _a, uint _amount) private {
        
        uint _nextID = _t;
        uint _c;
        for (uint i = 0; i < _amount; i++) {
            _nextID = _t + i;

            bytes32 _keccak = keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    _nextID,
                    _a,
                    _c,
                    SEED_NONCE
                )
            );

            uint16 cid = uint16(bytes2(_keccak << 128)) % 14444;
            uint16 sid = uint16(bytes2(_keccak)) % 14444;

            singles[_nextID] = (uint32(cid) << 16) | sid;
            
            unchecked { _c++; SEED_NONCE++; }
        }
    }

    function devMint(uint8 _amount) external onlyOwner {
       if (totalSupply() + _amount < 20) {
          _mint(msg.sender, _amount);
       } else {
         revert ("Just a few mints to get things moving");
       }
    }

    function tokenURI(uint _tokenID) public view override(ERC721A, IERC721A) returns (string memory) {
      if (!_exists(_tokenID)) { revert TokenDoesNotExist(); }
      if (groupings[_tokenID].length == 0) {
        (uint8 _cidID, uint8 _sidID) = getSinglesValues(_tokenID);
        GroupingExpanded memory _ge = _nexusContract.expandedSingle(_tokenID, _cidID, _sidID);
        string memory meta = _nexusContract.getMeta(_ge);
        return meta;
      } else {
        (uint8[] memory _cidIDs, uint8[] memory _sidIDs) = getGroupingsValues(_tokenID);
        GroupingExpanded memory _ge = _nexusContract.expandedGrouping(_tokenID, _cidIDs, _sidIDs);
        string memory meta = _nexusContract.getMeta(_ge);
        return meta;
      }
    }

    function checkColors(uint _tokenID) public view returns (string[] memory) {
       if (!_exists(_tokenID)) { revert TokenDoesNotExist(); }
      if (groupings[_tokenID].length == 0) {
        (uint8 _cidID,) = getSinglesValues(_tokenID);
        (string[] memory _color) = _nexusContract.getSingleNames(_cidID, true);
        return _color;
      } else {
        (uint8[] memory _cidIDs,) = getGroupingsValues(_tokenID);
        return _nexusContract.getGroupingNames(_cidIDs,true);
      }
    }
    function checkSymbols(uint _tokenID) public view returns (string[] memory) {
       if (!_exists(_tokenID)) { revert TokenDoesNotExist(); }
      if (groupings[_tokenID].length == 0) {
        (, uint8 _sidID) = getSinglesValues(_tokenID);
        (string[] memory _symbol) = _nexusContract.getSingleNames(_sidID, false);
        return _symbol;
      } else {
        (, uint8[] memory _sidIDs) = getGroupingsValues(_tokenID);
        return _nexusContract.getGroupingNames(_sidIDs,false);
      }
    }

    function matchesQuery(uint _id, bool _withNames) public view returns (bool _b, uint _total,string[] memory _cids,string[] memory _sids) {
        _total = groupings[_id].length;
        _b = true;
        if (_total > 0) {
            uint16 _f = uint16(groupings[_id][0]);
            for (uint i = 1; i < _total; i++) {
                if (uint16(groupings[_id][i]) != _f) {
                    _b = false;
                }
            }
        if (_withNames) {
            if (_total == 0) {
                (uint8 _c,uint8 _s) = getUint32Values(_f);
                _cids = _nexusContract.getSingleNames(_c,true);
                _sids = _nexusContract.getSingleNames(_s,false);
            } else {
                (uint8[] memory _cidIDs, uint8[] memory _sidIDs) = getGroupingsValues(_id);
                _cids = _nexusContract.getGroupingNames(_cidIDs,true);
                _sids = _nexusContract.getGroupingNames(_sidIDs,false);   
            }
          }
        }
    }

    function switchPaused( bool _p) external onlyOwner {
        _paused = _p;
    }

    function withdraw() public onlyOwner nonReentrant {
		(bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent);
	}

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Pausable.sol";

contract TradeSquads is ERC721, Ownable, Pausable {
    event paymentReceived(address indexed _payer, uint256 _value);
    event nftMinted(uint256 indexed _series, uint256 indexed _tokenId, address indexed _owner, uint256 _time, uint256 _rnd);

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 constant maxTraitNumber = 7;
    uint256 constant maxTraitRange = 10;
    uint256 constant secs = 86400;

    uint256[maxTraitRange] public traitRange;
    mapping(uint256 => uint256) traitRangeIndexVal;
    uint256 public rangeNumber;
    uint256 public traitNumber;
    uint256 public claimVal ;  
    string public endpoint ;
    uint256 public deltaHierarchy;
    address public uniqueClaimerA;

    Counters.Counter private _tokenIds;
    Counters.Counter private _seriesCounter;

    struct Series {
        Counters.Counter currentSupply;
        uint256 maxSupply;
        bool enabled;
    }

    struct TokenDetail {
        uint256 tokenSeriesIndex ;
        string tokenName;
        uint256 rNumber;
        uint256 delta;
        uint256 rangeN;
        uint256 traitN;
        uint256 difficulty;
        uint256 timestamp;
        uint256 hierarchySerial;
        uint256 tokenId;
    }

    struct ReqInfo {
        address owner;
        uint256 tokenId;
        uint256 series;
    }

    mapping(uint256 => uint256) traitArr;
    mapping(uint256 => Counters.Counter) hierarchyCounter;
    mapping(uint256 => TokenDetail) tokenDetail;
    Series[] public series;

    constructor(string memory _endpoint) 
        ERC721(
            "TradeSquad",
            "TS"
        )
        public
        {
            endpoint = _endpoint;
            
            series.push(Series(Counters.Counter(0),0,false));
            _seriesCounter.increment();
            series.push(Series(Counters.Counter(0),1,true));
            
            traitNumber = 7;
            deltaHierarchy = 0;
            rangeNumber = 4;

            traitArr[0] = 10;
            traitArr[1] = 10;
            traitArr[2] = 10;
            traitArr[3] = 10;
            traitArr[4] = 10;
            traitArr[5] = 10;
            traitArr[6] = 10;

            traitRange[0] = 2;
            traitRangeIndexVal[0] = 9;

            traitRange[1] = 7;
            traitRangeIndexVal[1] = 8;

            traitRange[2] = 14;
            traitRangeIndexVal[2] = 7;

            traitRange[3] = 22;
            traitRangeIndexVal[3] = 6;

            traitRange[4] = 32;
            traitRangeIndexVal[4] = 5;

            traitRange[5] = 43;
            traitRangeIndexVal[5] = 4;

            traitRange[6] = 55;
            traitRangeIndexVal[6] = 3;

            traitRange[7] = 68;
            traitRangeIndexVal[7] = 2;

            traitRange[8] = 83;
            traitRangeIndexVal[8] = 1;

            traitRange[9] = 99;
            traitRangeIndexVal[9] = 0;

            claimVal=100000000000000000;
        }

    receive() external payable { 
        emit paymentReceived(msg.sender, msg.value);
    }

    function awardItem(uint256 _series, bool _unique) isPaused
        payable
        public
    {      
        uint t=0;
        if(_unique) {
            require(_series==0 && series[_series].enabled && series[_series].currentSupply.current()<series[_series].maxSupply && msg.sender==uniqueClaimerA, "Can't award unique item");
            _tokenIds.increment();
            series[_series].currentSupply.increment();
            tokenDetail[_tokenIds.current()] = TokenDetail(_series, "", 0, 0, 0, 0, 0, 0, 0, _tokenIds.current());
            emit nftMinted(_series, _tokenIds.current(), msg.sender, (block.timestamp-(block.timestamp%secs)), 0);
            _safeMint(msg.sender, _tokenIds.current());
            _setTokenURI(_tokenIds.current(), string(abi.encodePacked(endpoint, _tokenIds.current().toString())));
            uniqueClaimerA = address(0);
        }
        else {
            require(msg.value>=claimVal && _series>0 && series[_series].enabled && series[_series].currentSupply.current() < series[_series].maxSupply, "Can't award item");
            _tokenIds.increment();
            tokenDetail[_tokenIds.current()] = TokenDetail(0, "", 0, 0, 0, 0, 0, 0, 0, _tokenIds.current());
            series[_series].currentSupply.increment();
            tokenDetail[_tokenIds.current()].tokenSeriesIndex = _series;
            tokenDetail[_tokenIds.current()].rNumber = uint256(keccak256(abi.encodePacked(block.difficulty, msg.sender, block.timestamp))).div(_tokenIds.current());
            tokenDetail[_tokenIds.current()].delta = deltaHierarchy ;
            tokenDetail[_tokenIds.current()].difficulty = block.difficulty ;
            tokenDetail[_tokenIds.current()].timestamp = block.timestamp ;
            tokenDetail[_tokenIds.current()].rangeN = rangeNumber ;
            tokenDetail[_tokenIds.current()].traitN = traitNumber ;

            if(tokenDetail[_tokenIds.current()].rangeN==0) {
                t = tokenDetail[_tokenIds.current()].rNumber.mod(traitArr[0]);
                t = t.add(tokenDetail[_tokenIds.current()].delta);
                hierarchyCounter[t].increment();
            }
            else {
                uint256 j=0;
                bool flag=false;
                t = tokenDetail[_tokenIds.current()].rNumber.mod(100);
                while(flag==false) {
                    if(j==maxTraitRange) {
                        t = t.mod(traitArr[0]);
                        flag=true;
                    }
                    else {
                        if(j==0) {
                            if(t>=0 && t<=traitRange[j]) {
                                t = traitRangeIndexVal[j];
                                flag = true;
                            }
                        }
                        else {
                            if(t>traitRange[j.sub(1)] && t<=traitRange[j]) {
                                t = traitRangeIndexVal[j];
                                flag = true;
                            }
                        }
                    }
                    j++;
                }
                t = t.add(deltaHierarchy);
                hierarchyCounter[t].increment();
            }

            tokenDetail[_tokenIds.current()].hierarchySerial = hierarchyCounter[t].current();
            emit nftMinted(_series, _tokenIds.current(), msg.sender, (block.timestamp-(block.timestamp%secs)), tokenDetail[_tokenIds.current()].rNumber);
            _safeMint(msg.sender, _tokenIds.current());
            _setTokenURI(_tokenIds.current(), string(abi.encodePacked(endpoint, _tokenIds.current().toString())));
        }
    }
    
    function setClaimVal(uint256 _value) public onlyOwner isPaused {
        claimVal = _value;
    }

    function setClaimer(address _claimer) public onlyOwner isPaused {
        uniqueClaimerA = _claimer;
    }

    function setDeltaHierarchy(uint256 _delta) public onlyOwner isPaused {
        require(_delta>=0, "Must be higher than 0");
        deltaHierarchy = _delta;
    }

    function setRangeNumber(uint256 _rangeNumber) public onlyOwner isPaused {
        require(_rangeNumber>=0 && _rangeNumber<=maxTraitRange, "Must be higher or equal 0");
        rangeNumber = _rangeNumber ;
    }

    function setRange(uint256 _range, uint256 _rangeVal, uint256 _type) public onlyOwner isPaused {
        require(_range>=0 && _range<maxTraitRange, "This trait doesn't exist");
        traitRange[_range] = _type;
        traitRangeIndexVal[_range] = _rangeVal;
    }

    function setTraitNumber(uint256 _traitNumber) public onlyOwner isPaused {
        require(_traitNumber>0 && _traitNumber<=maxTraitNumber, "Must be higher than 0");
        traitNumber = _traitNumber ;
    }

    function setTrait(uint256 _trait, uint256 _type) public onlyOwner isPaused {
        require(_trait>=0 && _trait<maxTraitNumber, "This trait doesn't exist");
        traitArr[_trait] = _type;
    }

    function setName(uint256 _tokenId, string memory _name) public {
        require(ownerOf(_tokenId)==msg.sender, "Not owner");
        require(bytes(_name).length<=32, "max string length");
        tokenDetail[_tokenId].tokenName = _name;
    }

    function addSeries(uint256 _maxSupply) public onlyOwner isPaused {
        require(_maxSupply>=0, "Must be higher or equal 0");
        _seriesCounter.increment();
        series.push(Series(Counters.Counter(0),_maxSupply,true));
    }
    
    function setSupply(uint256 _series, uint256 _supply) public onlyOwner isPaused {
        require(_supply>series[_series].maxSupply, "Supply error");
        series[_series].maxSupply = _supply;
    }

    function handleSeries(uint256 _seriesIndex, bool _enabled) public onlyOwner isPaused {
        series[_seriesIndex].enabled = _enabled;
    }

    function assetTrait(uint256 _tokenId) public view returns(TokenDetail memory, uint256[maxTraitNumber] memory) {
            uint256 i=0;
            uint256 nRandRes;
            uint256[maxTraitNumber] memory tArr;
            tArr[i] = tokenDetail[_tokenId].rNumber.mod(traitArr[i]);
            if(tokenDetail[_tokenId].rangeN==0) {
                nRandRes = uint256(keccak256(abi.encodePacked(tokenDetail[_tokenId].rNumber)));
                for(i=1; i<tokenDetail[_tokenId].traitN; i++) {
                    tArr[i] = nRandRes.mod(traitArr[i]);
                    tArr[i] = tArr[i].add(tokenDetail[_tokenId].delta);
                    nRandRes = uint256(keccak256(abi.encodePacked(nRandRes)));
                }
            }
            else {
                uint256 j=0;
                bool flag=false;
                tArr[i] = tokenDetail[_tokenId].rNumber.mod(100);
                while(flag==false) {
                    if(j==maxTraitRange) {
                        tArr[i] = tArr[i].mod(traitArr[i]);
                        flag=true;
                    }
                    else {
                        if(j==0) {
                            if(tArr[i]>=0 && tArr[i]<=traitRange[j]) {
                                tArr[i] = traitRangeIndexVal[j];
                                flag = true;
                            }
                        }
                        else {
                            if(tArr[i]>traitRange[j.sub(1)] && tArr[i]<=traitRange[j]) {
                                tArr[i] = traitRangeIndexVal[j];
                                flag = true;
                            }
                        }
                    }
                    j++;
                }
                
                tArr[i] = tArr[i].add(tokenDetail[_tokenId].delta);
                nRandRes = uint256(keccak256(abi.encodePacked(tokenDetail[_tokenId].rNumber)));
                
                for(i=1; i<tokenDetail[_tokenId].traitN; i++) {
                    if(i<rangeNumber) {
                        tArr[i] = nRandRes.mod(100);
                        j=0;
                        flag=false;
                        while(flag==false) {
                            if(j==maxTraitRange) {
                                tArr[i] = tArr[i].mod(traitArr[i]);
                                flag=true;
                            }
                            else {
                                if(j==0) {
                                    if(tArr[i]>=0 && tArr[i]<=traitRange[j]) {
                                        tArr[i] = traitRangeIndexVal[j];
                                        flag = true;
                                    }
                                }
                                else {
                                    if(tArr[i]>traitRange[j.sub(1)] && tArr[i]<=traitRange[j]) {
                                        tArr[i] = traitRangeIndexVal[j];
                                        flag = true;
                                    }
                                }
                            }
                            j++;
                        }
                    }
                    else {
                        tArr[i] = nRandRes.mod(traitArr[i]);
                    }
                    tArr[i] = tArr[i].add(tokenDetail[_tokenId].delta);
                    nRandRes = uint256(keccak256(abi.encodePacked(nRandRes)));
                }
            }

        return(tokenDetail[_tokenId], tArr);
    }

    function seriesCount() public view returns(uint256) {
        return _seriesCounter.current();
    }

    function hierarchyCount(uint256 _hierarchyId) public view returns(uint256) {
        return hierarchyCounter[_hierarchyId].current();
    }

    function seriesByIndex(uint256 _index) public view returns(Series memory) {
        return series[_index];
    }

    function getVaultBalance() public view onlyOwner isPaused returns(uint256) {
        return address(this).balance;
    }

    function sendVaultBalance(uint256 _amount, address payable _receiver) public onlyOwner isPaused {
        require(address(this).balance>= _amount, "Not enought WEI");
        _receiver.transfer(_amount);
    }
}
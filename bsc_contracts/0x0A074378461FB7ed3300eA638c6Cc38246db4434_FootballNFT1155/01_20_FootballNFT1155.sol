// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../utils/EnumerableValues.sol";
import "./interfaces/IFootballNFT1155.sol";
import "../utils/NFTUtils.sol";

interface IRandomSource {
    function genWithWSumDistributionU16Sum(uint16[] memory _sumList) external returns (uint16);
    // function genWithPriorDistributionU16SumList(uint16[] memory _sumList, uint256 _amount) external returns (uint16[] memory);
    // function seedModU16List(uint256 _modulus, uint256 _amount) external returns(uint16[] memory);
    function seedMod(uint256 _modulus) external returns(uint256);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract FootballNFT1155 is ReentrancyGuard, Ownable, ERC1155, IFootballNFT1155, NFTUtils {
    using Address for address;
    using SafeMath for uint256;
    using Strings for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;
    /* ============ State Variables ============ */
    EnumerableSet.AddressSet internal discountWhitelist;

    string public _name = "EDE World Cup 2022"; // Token name
    string public _symbol = "EDEWC2022"; // Token symbol
    string internal uriBase;

    address public wNativeToken;
    address public stakingPool;

    bool public isMintable = false;
    
    //---
    uint16[] public weightDistribution;
    uint16[] public weightDistributionSum;
    uint256[] public mintPrice;

    uint256 public priceBaseFactor = 10000;
    uint256 public constant PRICE_BASE_PRECISION = 10000;
    uint256 public constant PRICE_INTERVAL = 100;
    uint256 public latestPBFInterval = 0;
    
    uint256 public mintedNumber;

    // mapping(address => uint256) private _balances;// Mapping owner address to token count
    mapping(uint256 => address) private _tokenApprovals;// Mapping from token ID to approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals;// Mapping from owner to operator approvals

    string public baseImgURI;// Base token URI
    string public baseType = ".png";// Base token URI
    bool public useTest;

    mapping(uint256 => uint256[]) public tierToTeamIdSet;
    mapping(uint256 => uint256) public override teamIdToTier;
    mapping(uint256 => string) public override teamIdToName;
    mapping(string => uint256) public nameToTeamId;

    uint256 public rewardAmount;
    uint256 public claimedRewardAmount;
    uint256 public reservedAmount;
    uint256 public claimedReservedAmount;

    IRandomSource public randomSource;

    /* ============ Events ============ */
    event Mint(address account, uint256[] tokenID, uint256[] amount, uint256[] Tier);// Add new minter

    constructor(address _nativeToken) ERC1155("https://game.example/api/item/{id}.json") {
        wNativeToken = _nativeToken;
        mintPrice = new uint256[](10);
    }
    receive() external payable {
        require(msg.sender == wNativeToken, "invalid sender");
    }
    
    function setPrice(uint256[] memory _origPriceList, uint256[] memory _discountPriceList)external onlyOwner{
        require(_origPriceList.length == 5 && _discountPriceList.length == 5, "invalid price list");
        for (uint8 i = 0; i < 5; i++){
            require(_origPriceList[i] > 0, "invalid price setting");
            require(_discountPriceList[i] > 0, "invalid disc.price setting");
            mintPrice[i] = _origPriceList[i];
            mintPrice[i + 5] = _discountPriceList[i];
        }
    }

    function setPool(address _stakingPool) external onlyOwner{
        stakingPool = _stakingPool;
    }
    function setURI(string calldata _newURI) external onlyOwner {
        uriBase = _newURI;
        _setURI(_newURI);
    }
    function setType(string calldata baseImgUrl, string calldata newType, bool _useTest) external onlyOwner {
        baseImgURI = baseImgUrl;
        baseType = newType;
        useTest = _useTest;
    } 
    function setTeam(string[]memory _nameList, uint256[] memory _tierList, uint16[] memory _weightList) external onlyOwner{
        require(_weightList.length == 32, "invalid _weight list");
        require(_tierList.length == 32, "invalid _tier list");
        require(_nameList.length == 32, "invalid _name list");
        weightDistribution = new uint16[](32);
        weightDistributionSum = new uint16[](33);
        tierToTeamIdSet[0] = new uint256[](0);
        tierToTeamIdSet[1] = new uint256[](0);
        tierToTeamIdSet[2] = new uint256[](0);
        tierToTeamIdSet[3] = new uint256[](0);
        tierToTeamIdSet[4] = new uint256[](0);
        for (uint16 i = 0; i < 32; i++){
            require(_tierList[i] < 5 && _tierList[i] > 0 , "invalid tier");
            weightDistribution[i] = _weightList[i];
            weightDistributionSum[i+1] = weightDistributionSum[i] + weightDistribution[i];
            teamIdToName[i] = _nameList[i];
            tierToTeamIdSet[_tierList[i]].push(i);
            teamIdToTier[i] =  _tierList[i];
        }
    }

    function claimReserve(bool _usingNative) external onlyOwner{
        uint256 _amountOut = reservedAmount.sub(claimedReservedAmount);
        if (_usingNative){
            IWETH(wNativeToken).withdraw(_amountOut);
            payable(msg.sender).sendValue(_amountOut);
        }
        else{
            IERC20(wNativeToken).safeTransfer(msg.sender, _amountOut);
        }
        claimedReservedAmount = reservedAmount;
    }

    function withdrawToken(address _token, bool _usingNative) external onlyOwner{
        uint256 _amountOut = reservedAmount.sub(claimedReservedAmount);
        if (_usingNative){
            IWETH(wNativeToken).withdraw(_amountOut);
            payable(msg.sender).sendValue(_amountOut);
        }
        else{
            IERC20(_token).safeTransfer(msg.sender, _amountOut);
        }
        claimedReservedAmount = reservedAmount;
    }

    function setRandomSource(address _randomSource) external onlyOwner {
        randomSource = IRandomSource(_randomSource);
    }

    function setMintStatus(bool _status) external onlyOwner {
        isMintable = _status;
    }

    function addWhiteList(address[] memory _accounts, bool _status) external onlyOwner{
        if (_status){
            for(uint16 i = 0; i < _accounts.length; i++)
                if (!discountWhitelist.contains(_accounts[i]))
                    discountWhitelist.add(_accounts[i]);
        }
        else{
            for(uint16 i = 0; i < _accounts.length; i++)
                if (discountWhitelist.contains(_accounts[i]))
                    discountWhitelist.remove(_accounts[i]);
        }
    } 

    function withdrawPoolReward( ) external override nonReentrant returns (uint256) {
        require(msg.sender != address(0) && msg.sender == stakingPool, "invalid address");
        uint256 _amountOut = rewardAmount.sub(claimedRewardAmount);
        claimedRewardAmount = rewardAmount;
        IERC20(wNativeToken).safeTransfer(stakingPool, _amountOut);
        return _amountOut;
    }

    function canWithdrawPoolReward( ) external override view returns (uint256) {
        return rewardAmount.sub(claimedRewardAmount);
    }

    //internal funcs
    function updatePriceBaseFactor( ) internal {
        uint256 cur_gap = (mintedNumber).div(PRICE_INTERVAL);
        if (cur_gap > latestPBFInterval){
            for(uint16 i = 0; i < cur_gap.sub(latestPBFInterval); i++){
                priceBaseFactor = priceBaseFactor.mul(105).div(100);
            }
            latestPBFInterval = cur_gap;
        }
    }

    /* ============ External Functions ============ */
    function getWhitelist( ) public view returns (address[] memory) {
        return discountWhitelist.valuesAt(0, discountWhitelist.length());
    }
    function getMintPrice() public view returns(uint256[] memory){
        return mintPrice;
    }
    function getWeightDistribution() public view returns(uint16[] memory){
        return weightDistribution;
    }
    

    function holdingList(address _account) public view returns (uint256, uint256[] memory) {
        uint256 total = 0;
        uint256[] memory _holdRes = new uint256[](32);
        for (uint8 i = 0; i < 32; i++){
            _holdRes[i] = balanceOf(_account, i);
            total = total.add(_holdRes[i]);
        }
        return (total, _holdRes);
    }


    function getMintCost(address _account, uint256 _amount, uint256 _mintType) public view returns (uint256) {
        return (discountWhitelist.contains(_account) ? mintPrice[5 + _mintType] : mintPrice[0 + _mintType]).mul(_amount).mul(priceBaseFactor).div(PRICE_BASE_PRECISION);
    }

    function isWhitelist(address _account) public view returns (bool) {
        return discountWhitelist.contains(_account);
    }

    function mint(uint256 _amount, uint16 _buyTier) nonReentrant external payable {
        require(isMintable, "mint disabled");
        require(tx.origin == msg.sender && !msg.sender.isContract(), "onlyEOA");
        require(_buyTier >= 0 && _buyTier < 5, "invalid tier");
        address account = msg.sender;
        uint256 _mintCost = getMintCost(account,_amount, _buyTier);
        require(_mintCost > 0, "Invalid mint price"); 
        require( msg.value >= _mintCost, "insufficient mint fee");
        
        IWETH(wNativeToken).deposit{value: msg.value}();
        uint256 _rAmount = _mintCost.mul(9).div(10);
        rewardAmount = rewardAmount.add(_rAmount);
        reservedAmount = reservedAmount.add(msg.value.sub(_rAmount));

        uint256[] memory _mintAmount = new uint256[](32);
        for (uint256 i = 0; i < _amount; i++) {
            uint16 _teamID =  _buyTier == 0 ?
                                randomSource.genWithWSumDistributionU16Sum(weightDistributionSum) 
                                : uint16(tierToTeamIdSet[_buyTier][randomSource.seedMod(uint256(tierToTeamIdSet[_buyTier].length))]);
            require(_teamID>=0 && _teamID < 32, "invalid teamID");//double check
            _mintAmount[_teamID] = _mintAmount[_teamID].add(1);
            mintedNumber = mintedNumber.add(1);
        }
        uint16 nonZeroCount = 0;
        for (uint256 i = 0; i < _mintAmount.length; i++) {
            if (_mintAmount[i] > 0)  nonZeroCount += 1;
        }
        uint256[] memory _ids = new uint256[](nonZeroCount);
        uint256[] memory _amounts = new uint256[](nonZeroCount);
        uint256[] memory _tiers= new uint256[](nonZeroCount);
        uint16 cur_idx = 0;
        for(uint16 i = 0; i < 32; i++){
            if (_mintAmount[i] < 1) continue;
            _ids[cur_idx] = i;
            _amounts[cur_idx] = _mintAmount[i];
            _tiers[cur_idx] = teamIdToTier[i];
            cur_idx += 1;
            // _mint(account, i, _mintAmount[i], "");
        }

        _mintBatch(account, _ids, _amounts, "");
        emit Mint(account, _ids, _amounts, _tiers);

        updatePriceBaseFactor();
    }

    // function burn(address , uint256) external pure {
    //     require(false, "not supported method");
    // }


    /* ============ Util Functions ============ */
    function compileAttributes(uint256 tokenId) internal view returns (string memory) {
        return  string(
                abi.encodePacked(
                    "[",
                    attributeForTypeAndValue(
                        "Tier",
                        Strings.toString(teamIdToTier[tokenId])
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Team",
                        teamIdToName[tokenId]
                    ),
                    "]"
                )
            );
    }

    function uri(uint256 tokenId) public override view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(createJsonString(tokenId)))
                )
            );
    }
    
    function createJsonString(uint256 tokenId) public view returns (string memory) {
        return string(
            abi.encodePacked(
                '{"name": "',
                _name,
                ' #',
                tokenId.toString(),
                '", "description": "The World`s First World Cup 2022 NFT FOMO Game", "image": "',
                baseImgURI,
                useTest ? "Portugal" : teamIdToName[tokenId],
                baseType,
                '", "attributes":',
                compileAttributes(tokenId),
                "}"
            )
        );
    }
}
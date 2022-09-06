// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IController } from "./interfaces/IController.sol";
import { Ownable } from "./Ownable.sol";
import { Oracle } from "./Oracle.sol";

contract Controller is IController, Ownable, Initializable {
    
    uint16 public override minCollateralRatio;
    uint16 public override maxCollateralRatio;
    uint16 public constant override calculationDecimal = 2;    

    uint256 public override ttl;
    uint256 public override lockTime;

    address public override mintContract;
    address public override lockContract;
    
    address public override router;

    // mapping token address to 
    mapping(address => address) public override oracles;

    // mapping token address to AMM pool address
    mapping(address => address) public override pools;
    
    // mapping listing token to collateral token
    mapping(address => address) public override collateralForToken;

    mapping(address => bool) public override acceptedCollateral;

    mapping(address => address) public tokenOwners;

    mapping(address => uint16) public override discountRates;
    
    mapping(address => bool) public override admins;

    uint256 public override royaltyFeeRatio;
    address public override recieverAddress;
    address public override limitOfferContract;

    mapping(address => address) public override tokenForOracle;

    event ListingToken(address indexed tokenAddress, uint256 timestamp);
    event DelistingToken(address indexed tokenAddress, uint256 timestamp);
    event UpdatePrices(address[] tokenAddresses, uint256[] prices);

    constructor() {
    }
    
    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner(), "Only admin");
        _;
    }

    function initialize(uint16 _minCollateralRatio, uint16 _maxCollateralRatio, uint256 _ttl, address _router) external onlyOwner initializer{
        minCollateralRatio = _minCollateralRatio;
        maxCollateralRatio = _maxCollateralRatio;
        ttl = _ttl;
        router = _router;
    }
    
    function setAdmin(address _addr) public onlyOwner {
        admins[_addr] = true;
    }
    
    function revokeAdmin(address _addr) public onlyOwner {
        admins[_addr] = false;
    }

    function setRoyaltyFeeRatio(uint256 _fee) public onlyOwner {
        royaltyFeeRatio = _fee;
    }

    function setRecieverAddress(address _addr) public onlyOwner {
        recieverAddress = _addr;
    }

    function setMinCollateralRatio(uint16 _minCollateralRatio) external onlyOwner {
        minCollateralRatio = _minCollateralRatio;
    }

    function setMaxCollateralRatio(uint16 _maxCollateralRatio) external onlyOwner {
        maxCollateralRatio = _maxCollateralRatio;
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    function setTTL(uint256 _ttl) external onlyOwner {
        ttl = _ttl;
    }

    function setLockTime(uint256 _lockTime) external onlyOwner {
        require(_lockTime >= 300, "Lock time must be at least 5 minutes");
        lockTime = _lockTime;
    }

    function setMintContract(address _mintAddress) external onlyOwner {
        mintContract = _mintAddress;
    }

    function setLockContract(address _lockContract) external onlyOwner {
        lockContract = _lockContract;
    }

    function setLimitOfferContract(address _limitOfferContract) external onlyOwner {
        limitOfferContract = _limitOfferContract;
    }
    
    function setDiscountRate(address _tokenAddress, uint16 _rate) external onlyOwner {
        discountRates[_tokenAddress] = _rate;
    }

    function registerIDOTokens(
        address[] memory tokenAddresses,
        address[] memory oracleAddresses,
        address[] memory poolAddresses,
        address[] memory collateralTokens,
        uint16[] memory discountRate
    ) public onlyAdmin {
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            registerIDOToken(tokenAddresses[i], oracleAddresses[i], poolAddresses[i], collateralTokens[i], discountRate[i]);
        }
    }

    function registerIDOToken(
        address tokenAddress,
        address oracleAddress,
        address poolAddress,
        address collateralToken,
        uint16 discountRate
    ) public onlyAdmin {
        require(tokenAddress != collateralToken, "Duplicate token addresses");
        require(collateralForToken[tokenAddress] == address(0), "Token is already registered");
        require(acceptedCollateral[collateralToken], "Invalid colateral token");
        collateralForToken[tokenAddress] = collateralToken;
        tokenForOracle[oracleAddress] = tokenAddress;
        address token0 = IUniswapV2Pair(poolAddress).token0();
        address token1 = IUniswapV2Pair(poolAddress).token1();
        require(token0 == tokenAddress || token1 == tokenAddress, "Missing token address");
        require(token0 == collateralToken || token1 == collateralToken, "Missing collateral address");
        pools[tokenAddress] = poolAddress;
        oracles[tokenAddress] = oracleAddress;
        tokenOwners[tokenAddress] = msg.sender;
        discountRates[tokenAddress] = discountRate;
        emit ListingToken(tokenAddress, block.timestamp);
    }

    function unregisterToken(address tokenAddress) public onlyAdmin {
        require(collateralForToken[tokenAddress] != address(0), "Token have not been registered");
        collateralForToken[tokenAddress] = address(0);
        pools[tokenAddress] = address(0);
        oracles[tokenAddress] = address(0);
        tokenOwners[tokenAddress] = address(0);
        emit DelistingToken(tokenAddress, block.timestamp);
    }

    function updateIDOToken(
        address tokenAddress,
        address oracleAddress,
        address poolAddress,
        address collateralToken
    ) public onlyAdmin {
        require(collateralForToken[tokenAddress] != address(0), "Token have not been registered");
        require(acceptedCollateral[collateralToken], "Invalid collateral token");
        pools[tokenAddress] = poolAddress;
        oracles[tokenAddress] = oracleAddress;
        tokenForOracle[oracleAddress] = tokenAddress;
    }

    function registerCollateralAsset(address collateralAsset, bool value) public onlyOwner {
        acceptedCollateral[collateralAsset] = value;
    }
    
    function updatePrices(address[] memory tokenAddresses, uint256[] memory targetPrices) public onlyAdmin {
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            Oracle(oracles[tokenAddresses[i]]).update(targetPrices[i]);
        }

        emit UpdatePrices(tokenAddresses, targetPrices);
    }

    function getOraclePrices(address[] memory tokenAddresses) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory targetPrices = new uint256[](tokenAddresses.length);
        uint256[] memory lastUpdated = new uint256[](tokenAddresses.length);
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            (targetPrices[i], lastUpdated[i]) = Oracle(oracles[tokenAddresses[i]]).getTargetValue();
        }
        return(targetPrices, lastUpdated);
    }
}
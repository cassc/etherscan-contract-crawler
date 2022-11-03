// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../../interfaces/IIbAlluo.sol";
import "../../Farming/priceFeedsV2/PriceFeedRouterV2.sol";
import "../../interfaces/IAlluoStrategyV2.sol";

contract StrategyHandler is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable {

    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address public gnosis;
    address public booster;
    address public executor;
    address public exchangeAddress;
    address public priceFeed;

    bool public upgradeStatus;
    uint256 public lastTimeCalculated;

    mapping(string => uint256) public directionNameToId;
    mapping(uint256 => LiquidityDirection) public liquidityDirection;

    // asset id: usd = 0, eur = 1, eth = 2, btc = 3 
    mapping(uint256 => AssetInfo) private assetIdToAssetInfo;

    uint8 public numberOfAssets;

    struct LiquidityDirection {
        address strategyAddress; 
        address entryToken; 
        uint256 assetId;
        uint256 chainId;
        bytes entryData;
        bytes exitData;
        bytes rewardsData;
        uint256 latestAmount;
    }

    struct AssetInfo {
        mapping(uint256 => address) chainIdToPrimaryToken; 
        address ibAlluo;
        EnumerableSetUpgradeable.UintSet activeDirections;
        EnumerableSetUpgradeable.AddressSet needToTransferFrom;
        uint256 amountDeployed; 
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet,
        address _priceFeed,
        address _executor
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract(), "Executor: Not contract");
        gnosis = _multiSigWallet;
        exchangeAddress = 0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec;
        priceFeed = _priceFeed;
        executor = _executor;

        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);

        // For tests only
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function calculateAll() external onlyRole(DEFAULT_ADMIN_ROLE){

        uint256 timePass = block.timestamp - lastTimeCalculated;
        for (uint256 i; i < numberOfAssets; i++) {
            uint256 newAmountDeployed;
            AssetInfo storage info = assetIdToAssetInfo[i];
            for (uint256 j; j < info.activeDirections.length(); j++) {
                LiquidityDirection memory direction = liquidityDirection[info.activeDirections.at(j)];
                uint latestAmount = IAlluoStrategyV2(direction.strategyAddress).getDeployedAmountAndRewards(direction.rewardsData);
                liquidityDirection[info.activeDirections.at(j)].latestAmount = latestAmount;
                newAmountDeployed += latestAmount;
                if(!info.needToTransferFrom.contains(direction.strategyAddress)){
                    info.needToTransferFrom.add(direction.strategyAddress);
                }
            }
            address primaryToken = info.chainIdToPrimaryToken[1];
            for (uint256 j = info.needToTransferFrom.length(); j > 0 ; j--) {
                address strategyAddress = info.needToTransferFrom.at(j-1);
                IAlluoStrategyV2(strategyAddress).withdrawRewards(primaryToken);
                info.needToTransferFrom.remove(strategyAddress);
            }
            (uint256 fiatPrice, uint8 fiatDecimals) = PriceFeedRouterV2(priceFeed).getPrice(primaryToken, i);
            uint256 totalRewardsBalance = IERC20Upgradeable(primaryToken).balanceOf(address(this));
            uint8 primaryDecimals = IERC20MetadataUpgradeable(primaryToken).decimals();
            uint256 totalRewards = PriceFeedRouterV2(priceFeed).decimalsConverter(
                fiatPrice * totalRewardsBalance, 
                fiatDecimals + primaryDecimals, 
                18
            );
            
            uint256 interest = IIbAlluo(info.ibAlluo).annualInterest();
            uint256 expectedAddition = info.amountDeployed * interest * timePass / 31536000  / 10000;
            uint256 expectedFullAmount = info.amountDeployed + expectedAddition;
            uint256 actualAmount = newAmountDeployed + totalRewards;


            if(actualAmount > expectedFullAmount){
            uint256 surplus = actualAmount - expectedFullAmount;

                if(surplus < totalRewards){
                    
                    IERC20Upgradeable(primaryToken).transfer(booster, totalRewardsBalance * surplus  / totalRewards);

                    uint rewardsLeft = IERC20Upgradeable(primaryToken).balanceOf(address(this)); 
                    IERC20Upgradeable(primaryToken).transfer(executor, rewardsLeft);

                    rewardsLeft = PriceFeedRouterV2(priceFeed).decimalsConverter(
                        rewardsLeft, 
                        primaryDecimals, 
                        18
                    );  
                    info.amountDeployed = newAmountDeployed + rewardsLeft;

                }
                else{

                    info.amountDeployed = actualAmount - totalRewards;
                    IERC20Upgradeable(primaryToken).transfer(booster, totalRewardsBalance);

                    //in the future here we will also exit some existing strategy to send to booster
                }

            }
            else{
                IERC20Upgradeable(primaryToken).transfer(executor, totalRewardsBalance);
                info.amountDeployed = actualAmount;

            }
        }
        lastTimeCalculated = block.timestamp;
    }

    function calculateOnlyLp() external onlyRole(DEFAULT_ADMIN_ROLE){

        for (uint256 i; i < numberOfAssets; i++) {
            uint256 newAmountDeployed;
            AssetInfo storage info = assetIdToAssetInfo[i];
            for (uint256 j; j < info.activeDirections.length(); j++) {
                LiquidityDirection memory direction = liquidityDirection[info.activeDirections.at(j)];
                newAmountDeployed += IAlluoStrategyV2(direction.strategyAddress).getDeployedAmount(direction.rewardsData);
            }
            info.amountDeployed = newAmountDeployed;
        }
        lastTimeCalculated = block.timestamp;
    }


    function getCurrentDeployed() external view returns(uint[] memory amounts){
        amounts = new uint[](numberOfAssets);

        for (uint256 i; i < numberOfAssets; i++) {
            uint256 newAmountDeployed;
            AssetInfo storage info = assetIdToAssetInfo[i];
            for (uint256 j; j < info.activeDirections.length(); j++) {
                LiquidityDirection memory direction = liquidityDirection[info.activeDirections.at(j)];
                uint latestAmount = IAlluoStrategyV2(direction.strategyAddress).getDeployedAmount(direction.rewardsData);
                newAmountDeployed += latestAmount;
            }
            address primaryToken = info.chainIdToPrimaryToken[1];
 
            (uint256 fiatPrice, uint8 fiatDecimals) = PriceFeedRouterV2(priceFeed).getPrice(primaryToken, i);
            uint256 totalRewardsBalance = IERC20Upgradeable(primaryToken).balanceOf(address(this));
            uint8 primaryDecimals = IERC20MetadataUpgradeable(primaryToken).decimals();
            uint256 totalRewards = PriceFeedRouterV2(priceFeed).decimalsConverter(
                fiatPrice * totalRewardsBalance, 
                fiatDecimals + primaryDecimals, 
                18
            );
            
            amounts[i] = newAmountDeployed + totalRewards;
        }
    }

    function getLatestDeployed()external view returns(uint[] memory amounts){
        amounts = new uint[](numberOfAssets);
        for (uint256 i; i < numberOfAssets; i++) {
            amounts[i] = assetIdToAssetInfo[i].amountDeployed;
        }
    }

    function adjustTreasury(int256 _delta) public onlyRole(DEFAULT_ADMIN_ROLE) {
        assetIdToAssetInfo[0].amountDeployed = uint(int(assetIdToAssetInfo[0].amountDeployed) + _delta);
        if(_delta > 0){
            address primaryToken = assetIdToAssetInfo[0].chainIdToPrimaryToken[1];
            (uint256 fiatPrice, uint8 fiatDecimals) = PriceFeedRouterV2(priceFeed).getPrice(primaryToken, 0);
            uint exactAmount = (uint(_delta) * 10**fiatDecimals) / fiatPrice;
            uint256 tokenAmount = exactAmount / 10**(18 - IERC20MetadataUpgradeable(primaryToken).decimals());
            IERC20MetadataUpgradeable(primaryToken).safeTransferFrom(gnosis, executor, tokenAmount);
        }
    }

    function getDirectionIdByName(string memory _codeName) external view returns(uint256){
        return directionNameToId[_codeName];
    }

    function getDirectionLatestAmount(uint256 _id) external view returns(uint){
        return liquidityDirection[_id].latestAmount;
    }

    function getLiquidityDirectionByName(string memory _codeName) external view returns(uint256, address, LiquidityDirection memory){
        uint256 directionId = directionNameToId[_codeName];
        LiquidityDirection memory direction = liquidityDirection[directionId];
        address primaryToken = assetIdToAssetInfo[direction.assetId].chainIdToPrimaryToken[direction.chainId];
        return (directionId, primaryToken, direction);
    }

    function getAssetIdByDirectionId(uint256 _id)external view returns(uint){
        return liquidityDirection[_id].assetId;
    }

    function getDirectionFullInfoById(uint256 _id) external view returns(address, LiquidityDirection memory){
        LiquidityDirection memory direction = liquidityDirection[_id];
        address primaryToken = assetIdToAssetInfo[direction.assetId].chainIdToPrimaryToken[direction.chainId];
        return (primaryToken, direction);
    }

    function getLiquidityDirectionById(uint256 _id) external view returns(LiquidityDirection memory){
        return (liquidityDirection[_id]);
    }

    function getPrimaryTokenByAssetId(uint256 _id, uint256 _chainId) external view returns(address){
        return (assetIdToAssetInfo[_id].chainIdToPrimaryToken[_chainId]);
    }


    function setAssetAmount(uint _id,uint amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        assetIdToAssetInfo[_id].amountDeployed = amount;
    }

    function getAssetAmount(uint _id) view public returns(uint){
        return (assetIdToAssetInfo[_id].amountDeployed);
    }

    function addToActiveDirections(uint256 _directionId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if(!assetIdToAssetInfo[liquidityDirection[_directionId].assetId].activeDirections.contains(_directionId)){
            assetIdToAssetInfo[liquidityDirection[_directionId].assetId].activeDirections.add(_directionId);
        }
    }

    function removeFromActiveDirections(uint256 _directionId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        assetIdToAssetInfo[liquidityDirection[_directionId].assetId].activeDirections.remove(_directionId);
        liquidityDirection[_directionId].latestAmount = 0;
    }   

    function setGnosis(address _gnosisAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        gnosis = _gnosisAddress;
    }

    function updateLastTime() public onlyRole(DEFAULT_ADMIN_ROLE) {
        lastTimeCalculated = block.timestamp;
    }

    function setExchangeAddress(address _newExchange) public onlyRole(DEFAULT_ADMIN_ROLE) {
        exchangeAddress = _newExchange;
    }

    function setBoosterAddress(address _newBooster) public onlyRole(DEFAULT_ADMIN_ROLE) {
        booster = _newBooster;
    }

    function setExecutorAddress(address _newExecutor) public onlyRole(DEFAULT_ADMIN_ROLE) {
        executor = _newExecutor;
        _grantRole(DEFAULT_ADMIN_ROLE, _newExecutor);
    }

    function setLiquidityDirection(
        string memory _codeName,
        uint256 _directionId,
        address _strategyAddress, 
        address _entryToken, 
        uint256 _assetId, 
        uint256 _chainId, 
        bytes memory _entryData, 
        bytes memory _exitData,
        bytes memory _rewardsData
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        directionNameToId[_codeName] = _directionId;
        liquidityDirection[_directionId] = LiquidityDirection(
            _strategyAddress, 
            _entryToken, 
            _assetId, 
            _chainId, 
            _entryData, 
            _exitData, 
            _rewardsData,
            0
        );
    }

    function changeNumberOfAssets(uint8 _newNumber) public onlyRole(DEFAULT_ADMIN_ROLE) {
        numberOfAssets = _newNumber;
    }

    function changeAssetInfo(
        uint256 _assetId,
        uint256[] calldata  _chainIds, 
        address[] calldata _chainIdToPrimaryToken,
        address _ibAlluo
    )external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_chainIds.length == _chainIdToPrimaryToken.length);
        assetIdToAssetInfo[_assetId].ibAlluo = _ibAlluo;
        for (uint256 i; i < _chainIds.length; i++) {
            assetIdToAssetInfo[_assetId].chainIdToPrimaryToken[_chainIds[i]] = _chainIdToPrimaryToken[i];
        }
    }

    function grantRole(bytes32 role, address account)
    public
    override
    onlyRole(getRoleAdmin(role)) {
        // if (role == DEFAULT_ADMIN_ROLE) {
        //     require(account.isContract(), "Handler: Not contract");
        // }
        _grantRole(role, account);
    }

    function changeUpgradeStatus(bool _status)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeStatus = _status;
    }


    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override {
        require(upgradeStatus, "Executor: Upgrade not allowed");
        upgradeStatus = false;
    }
}
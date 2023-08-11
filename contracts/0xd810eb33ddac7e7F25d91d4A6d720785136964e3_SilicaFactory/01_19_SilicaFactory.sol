/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
 * */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/silicaFactory/ISilicaFactory.sol";
import "./interfaces/silica/ISilicaV2_1.sol";
import "./interfaces/oracle/IOracle.sol";
import "./interfaces/oracle/oracleEthStaking/IOracleEthStaking.sol";
import "./interfaces/oracle/IOracleRegistry.sol";
import "./interfaces/swapProxy/ISwapProxy.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title  SilicaFactory
 * @notice Factory contract for Silica Account
 * @author Alkimiya Team
 */
contract SilicaFactory is ISilicaFactory {
    error InvalidType();

    uint256 internal constant MINING_SWAP_COMMODITY_TYPE = 0;
    uint256 internal constant ETH_STAKING_COMMODITY_TYPE = 2;

    address public immutable silicaMasterV2;
    address public immutable silicaEthStakingMaster;

    IOracleRegistry immutable oracleRegistry;
    ISwapProxy immutable swapProxy;

    error Unauthorized();

    struct OracleData {
        uint256 networkHashrate;
        uint256 networkReward;
        uint256 lastIndexedDay;
    } // For reward token Silica

    struct OracleEthStakingData {
        uint256 baseRewardPerIncrementPerDay;
        uint256 lastIndexedDay;
    } // For ETH Silica

    modifier onlySwapProxy() {
        if (address(swapProxy) != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    constructor(
        address _silicaMasterV2,
        address _silicaEthStakingMaster,
        address _oracleRegistry,
        address _swapProxy
    ) {
        require(_silicaMasterV2 != address(0), "SilicaV2 master address cannot be zero");
        silicaMasterV2 = _silicaMasterV2;

        require(_silicaEthStakingMaster != address(0), "SilicaEthStakingV2_1 master address cannot be zero");
        silicaEthStakingMaster = _silicaEthStakingMaster;

        require(_oracleRegistry != address(0), "OracleRegistry address cannot be zero");
        oracleRegistry = IOracleRegistry(_oracleRegistry);

        require(_swapProxy != address(0), "SwapProxy address cannot be zero");
        swapProxy = ISwapProxy(_swapProxy);
    }

    /*///////////////////////////////////////////////////////////////
                            Index Data
    //////////////////////////////////////////////////////////////*/

    /// @notice Function to return the Collateral requirement for issuance for a new Mining Swap Silica
    /// @param lastDueDay The final day of contract on which deposit is required
    /// @param hashrate The hashrate 
    /// @param rewardTokenAddress The address of the reward token 
    /// @return miningSwapCollateralRequirement The collateral requirement 
    function getMiningSwapCollateralRequirement(
        uint256 lastDueDay,
        uint256 hashrate,
        address rewardTokenAddress
    ) external view returns (uint256 miningSwapCollateralRequirement) {
        OracleData memory oracleData = _getOracleData(rewardTokenAddress);

        uint256 numDeposits = _getNumDeposits(oracleData.lastIndexedDay, lastDueDay);
        miningSwapCollateralRequirement = (hashrate * oracleData.networkReward * numDeposits) / (oracleData.networkHashrate * 10);
    }

    /// @notice Function to return the Collateral requirement for issuance for a new Staking Swap Silica
    /// @param lastDueDay The final day of contract on which deposit is required
    /// @param stakedAmount The amount that has been staked
    /// @param rewardTokenAddress The address of the reward token
    /// @param decimals The decimals of the reward token 
    function getEthStakingCollateralRequirement(
        uint256 lastDueDay,
        uint256 stakedAmount,
        address rewardTokenAddress,
        uint8 decimals
    ) external view returns (uint256) {
        OracleEthStakingData memory oracleData = _getOracleEthStakingData(rewardTokenAddress);
        uint256 numDeposits = _getNumDeposits(oracleData.lastIndexedDay, lastDueDay);
        return (oracleData.baseRewardPerIncrementPerDay * stakedAmount * numDeposits) / (10**(decimals + 1));
    }

    /// @notice Function to return the Collateral requirement for issuance for a new Mining Swap Silica
    /// @param lastDueDay The final day of contract on which deposit is required
    /// @param hashrate The hashrate 
    /// @param oracleData A instance of the OracleData struct ({ 
        /// networkHashrate:
        /// networkReward:
        /// lastIndexedDate:
    ///})
    /// @return miningSwapCollateralRequirement The collateral requirement
    function _getMiningSwapCollateralRequirement(
        uint256 lastDueDay,
        uint256 hashrate,
        OracleData memory oracleData
    ) internal pure returns (uint256 miningSwapCollateralRequirement) {
        uint256 numDeposits = _getNumDeposits(oracleData.lastIndexedDay, lastDueDay);
        miningSwapCollateralRequirement = (hashrate * oracleData.networkReward * numDeposits) / (oracleData.networkHashrate * 10);
    }

    /// @notice Internal Function to return the Collateral requirement for issuance for a new Staking Swap Silica
    /// @param lastDueDay The final day of contract on which deposit is required
    /// @param stakedAmount The amount that has been staked
    /// @param oracleData An instance of the OracleEthStakingData struct ({
           /// referenceDay:
           /// baseRewardPerIncrementPerDay:
           /// burnFee:
           /// priorityFee:
           /// burnFeeNormalized:
           /// priorityFeeNormalized:
           /// timestamp
    ///})
    function _getEthStakingCollateralRequirement(
        uint256 lastDueDay,
        uint256 stakedAmount,
        OracleEthStakingData memory oracleData,
        uint8 decimals
    ) internal pure returns (uint256 collateralReq) {
        uint256 numDeposits = _getNumDeposits(oracleData.lastIndexedDay, lastDueDay);
        collateralReq = (oracleData.baseRewardPerIncrementPerDay * stakedAmount * numDeposits) / (10**(decimals + 1));
    }

    /// @notice Function to return lastest Mining Oracle data
    /// @param  rewardTokenAddress The address of the reward token
    /// @return data OracleData struct on last indexed day
    function _getOracleData(address rewardTokenAddress) internal view returns (OracleData memory data) {
        OracleData memory oracleData;
        IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardTokenAddress), MINING_SWAP_COMMODITY_TYPE));
        uint256 lastIndexedDay = oracle.getLastIndexedDay();
        (, , uint256 networkHashrate, uint256 networkReward, , , ) = oracle.get(lastIndexedDay);
        oracleData.networkHashrate = networkHashrate;
        oracleData.networkReward = networkReward;
        oracleData.lastIndexedDay = lastIndexedDay;
        data = oracleData;
    }

    /// @notice Function to return lastest Mining Oracle data
    /// @param  rewardTokenAddress The address of the reward token
    /// @return data OraclEthStakingData struct of last indexed day
    function _getOracleEthStakingData(address rewardTokenAddress) internal view returns (OracleEthStakingData memory data) {
        OracleEthStakingData memory oracleData;
        IOracleEthStaking oracleEthStaking = IOracleEthStaking(
            IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardTokenAddress), ETH_STAKING_COMMODITY_TYPE)
        );
        uint256 lastIndexedDay = oracleEthStaking.getLastIndexedDay();
        (, uint256 baseRewardPerIncrementPerDay, , , , , ) = oracleEthStaking.get(lastIndexedDay);

        oracleData.baseRewardPerIncrementPerDay = baseRewardPerIncrementPerDay;
        oracleData.lastIndexedDay = lastIndexedDay;
        data = oracleData;
    }

    /// @notice Function to return the number of deposits the contracts requires
    /// @dev lastDueDay is always greater than lastIndexedDay
    /// @param lastIndexedDay The last day on which oracle data was written to 
    function _getNumDeposits(uint256 lastIndexedDay, uint256 lastDueDay) internal pure returns (uint256) {
        return lastDueDay - lastIndexedDay - 1;
    }

    /*///////////////////////////////////////////////////////////////
                                 Create Silica
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a SilicaV2_1 contract
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount hashrate the seller is selling
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of gH/day
    /// @return address: The address of the contract created
    function createSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice
    ) external returns (address) {
        address newContractAddress = _createSilicaV2_1(
            _rewardTokenAddress,
            _paymentTokenAddress,
            _resourceAmount,
            _lastDueDay,
            _unitPrice,
            msg.sender,
            0
        );
        return newContractAddress;
    }

    /// @notice Creates a SilicaV2_1 contract from SwapProxy
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount hashrate the seller is selling
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of gH/day
    /// @param _sellerAddress the seller address
    /// @param _additionalCollateralPercent - added on top of base 10%,
    ///        e.g. if `additionalCollateralPercent = 20` then you will
    ///        put 30% collateral.
    /// @return address: The address of the contract created
    function proxyCreateSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress,
        uint256 _additionalCollateralPercent
    ) external onlySwapProxy returns (address) {
        address newContractAddress = _createSilicaV2_1(
            _rewardTokenAddress,
            _paymentTokenAddress,
            _resourceAmount,
            _lastDueDay,
            _unitPrice,
            _sellerAddress,
            _additionalCollateralPercent
        );
        return newContractAddress;
    }

    /// @notice Internal function to create a Silica V2.1
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount hashrate the seller is selling
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of gH/day
    /// @param _sellerAddress the address of the resource seller 
    /// @return address: The address of the contract created
    function _createSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress,
        uint256 _additionalCollateralPercent
    ) internal returns (address) {
        require(_additionalCollateralPercent < 1000); // prevent overflow attack
        address newContractAddress = payable(Clones.clone(silicaMasterV2));

        ISilicaV2_1 newSilicaV2 = ISilicaV2_1(newContractAddress);

        OracleData memory oracleData = _getOracleData(_rewardTokenAddress);
        uint256 collateralAmount = _getMiningSwapCollateralRequirement(
          _lastDueDay,
          _resourceAmount,
          oracleData
        );

        ISilicaV2_1.InitializeData memory initializeData;

        initializeData.rewardTokenAddress = _rewardTokenAddress;
        initializeData.paymentTokenAddress = _paymentTokenAddress;
        initializeData.oracleRegistry = address(oracleRegistry);
        initializeData.sellerAddress = _sellerAddress;
        initializeData.dayOfDeployment = oracleData.lastIndexedDay;
        initializeData.lastDueDay = _lastDueDay;
        initializeData.unitPrice = _unitPrice;
        initializeData.resourceAmount = _resourceAmount;
        initializeData.collateralAmount = collateralAmount;
        newSilicaV2.initialize(initializeData);
        SafeERC20.safeTransferFrom(
          IERC20(_rewardTokenAddress),
          _sellerAddress,
          newContractAddress,
          collateralAmount * (10 + _additionalCollateralPercent) / 10
        );

        emit NewSilicaContract(newContractAddress, initializeData, uint16(MINING_SWAP_COMMODITY_TYPE));

        return newContractAddress;
    }

    /// @notice Creates a EthStakingSilicaV2_1 contract
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount Amount of token staked generating the rewards beeing sold by the seller with this contract
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of stakedToken/day
    /// @return address: The address of the contract created
    function createEthStakingSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice
    ) external returns (address) {
        address newContractAddress = _createEthStakingSilicaV2_1(
            _rewardTokenAddress,
            _paymentTokenAddress,
            _resourceAmount,
            _lastDueDay,
            _unitPrice,
            msg.sender,
            0
        );
        return newContractAddress;
    }

    /// @notice Creates a EthStakingSilicaV2_1 contract from SwapProxy
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount Amount of token staked generating the rewards beeing sold by the seller with this contract
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of stakedToken/day
    /// @param _sellerAddress the seller address
    /// @return address: The address of the contract created
    function proxyCreateEthStakingSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress,
        uint256 _additionalCollateralPercent
    ) external onlySwapProxy returns (address) {
        address newContractAddress = _createEthStakingSilicaV2_1(
            _rewardTokenAddress,
            _paymentTokenAddress,
            _resourceAmount,
            _lastDueDay,
            _unitPrice,
            _sellerAddress,
            _additionalCollateralPercent
        );
        return newContractAddress;
    }

    /// @notice Internal function to create a Eth Staking Silica V2.1
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount Amount of token staked generating the rewards beeing sold by the seller with this contract
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of stakedToken/day
    /// @param _sellerAddress the seller address
    /// @return address: The address of the contract created
    function _createEthStakingSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress,
        uint256 _additionalCollateralPercent
    ) internal returns (address) {
        require(_additionalCollateralPercent < 1000); // prevent overflow attack
        address newContractAddress = payable(Clones.clone(silicaEthStakingMaster));
        ISilicaV2_1 newSilicaV2 = ISilicaV2_1(newContractAddress);
        OracleEthStakingData memory oracleData = _getOracleEthStakingData(_rewardTokenAddress);
        uint256 collateralAmount = _getEthStakingCollateralRequirement(
          _lastDueDay,
          _resourceAmount,
          oracleData,
          newSilicaV2.getDecimals()
        );

        ISilicaV2_1.InitializeData memory initializeData;

        initializeData.rewardTokenAddress = _rewardTokenAddress;
        initializeData.paymentTokenAddress = _paymentTokenAddress;
        initializeData.oracleRegistry = address(oracleRegistry);
        initializeData.sellerAddress = _sellerAddress;
        initializeData.dayOfDeployment = oracleData.lastIndexedDay;
        initializeData.lastDueDay = _lastDueDay;
        initializeData.unitPrice = _unitPrice;
        initializeData.resourceAmount = _resourceAmount;
        initializeData.collateralAmount = collateralAmount;
        newSilicaV2.initialize(initializeData);
        SafeERC20.safeTransferFrom(IERC20(_rewardTokenAddress), _sellerAddress, newContractAddress, collateralAmount * (10 + _additionalCollateralPercent) / 10);

        emit NewSilicaContract(newContractAddress, initializeData, uint16(ETH_STAKING_COMMODITY_TYPE));

        return newContractAddress;
    }
}
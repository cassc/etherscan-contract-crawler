// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IAmountsDistributor.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/INetGymStreet.sol";
import "./interfaces/INFTReflection.sol";
import "./interfaces/IBuyAndBurn.sol";

contract DistributeAmounts is OwnableUpgradeable, ReentrancyGuardUpgradeable, IAmountsDistributor {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Operation type constants
    uint8 private constant OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS = 10;
    uint8 private constant OPERATION_TYPE_MINT_MINERS = 20;
    uint8 private constant OPERATION_TYPE_PURCHASE_ELECTRICITY = 30;
    uint8 private constant OPERATION_TYPE_PURCHASE_REPAIR = 40;

    // @notice Wallet addresses
    address public ambassadorWalletAddress;
    address public reserveWalletAddress;
    address public companyWalletAddress;

    // Addresses of Gymstreet smart contracts
    address public nftReflectionPoolAddress;
    address public netGymStreetAddress;
    address public nftRankRewardsAddress;

    // Addresses of GymNet smart contracts
    address public gymTurnoverPoolAddress;
    address public buyAndBurnAddress;

    // Token addresses for interacint with liquidity pools
    address public busdAddress;
    address public wbnbAddress;

    // PancakeSwap router address
    address public routerAddress;

    /// @notice Wallets to be replaced
    address public vBTCBuyAndBurnWallet;
    address public liquidityWallet;

    // @notice Amounts that we keep track of in the Municipality smart contract (in BUSD)
    uint256 public linearBuyAndBurnAmountVBTC;
    uint256 public vbtcLiquidityAmount;

    address public municipalityAddress;
    address public companyWalletMetablocks;

    // @notice Operation Type to percentages
    mapping(uint8 => uint256[10]) public operationTypeToPercentagesMapping;
    address public gymLiquidityWallet;
    address public marketingWallet;
    address public streetLevelPools;
    mapping(address => bool) public whiteListed;

    event NFTContractAddressesSet(address[3] indexed nftContractAddresses);
    event DistributionReceiverAddressesSet(address[12] indexed nftContractAddresses);

    modifier onlyWhiteListed() {
        require(whiteListed[msg.sender], "DistributeAmounts: Only municipalities are authorized to call this function");
        _;
    }

    // @notice Proxy SC support - initialize internal state
    function initialize(
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        // @notice Array index to distribution percentage
        // [0:companyWallet, 1:nftReflectionPool, 2:buyAndBurnVBTC, 3:addLiquidity, 4:buynAndBurnGym,
        // 5:gymTurnoverPool, 6:netGymStreet, 7:reserveWallet, 8:ambassador, 9:nftRankRewards]

        operationTypeToPercentagesMapping[OPERATION_TYPE_MINT_MINERS] = [
            20, // companyWallet
            5, // nftReflectionPool
            7, // buyAndBurnVBTC
            8, // addVBTCLiquidity
            10, // buynAndBurnGym
            3, // gymTurnoverPool
            39, // netGymStreet
            7, // reserveWallet
            5, // ambassador
            23 //nftRankRewards
        ];
        operationTypeToPercentagesMapping[OPERATION_TYPE_PURCHASE_REPAIR] = [
            20, // companyWallet
            5, // nftReflectionPool
            7, // buyAndBurnVBTC
            8, // addVBTCLiquidity
            10, // buynAndBurnGym
            3, // gymTurnoverPool
            39, // netGymStreet
            7, // reserveWallet
            5, // ambassador
            23 //nftRankRewards
        ];
        operationTypeToPercentagesMapping[OPERATION_TYPE_MINT_OR_UPGRADE_PARCELS] = [
            20, // companyWallet
            5, // nftReflectionPool
            6, // buyAndBurnVBTC
            4, // addVBTCLiquidity
            15, // buynAndBurnGym
            3, // gymTurnoverPool
            39, // netGymStreet
            7, // reserveWallet
            5, // ambassador
            23 //nftRankRewards
        ];
        operationTypeToPercentagesMapping[OPERATION_TYPE_PURCHASE_ELECTRICITY] = [
            20, // companyWallet
            0, // nftReflectionPool
            40, // buyAndBurnVBTC
            0, // addVBTCLiquidity
            40, // buynAndBurnGym
            0, // gymTurnoverPool
            0, // netGymStreet
            0, // reserveWallet
            0, // ambassador
            0 //nftRankRewards
        ];
    }

    function distributeAmounts(uint256 _amount, uint8 _operationType, address _user) external onlyWhiteListed {
        _distributeAmounts(_amount, _operationType, _user);
    }

    /// @notice Set contract addresses for all NFTs we currently have
    function setNFTContractAddresses(address[3] calldata _nftContractAddresses) external onlyOwner {
        routerAddress =  _nftContractAddresses[0];
        busdAddress = _nftContractAddresses[1];
        wbnbAddress = _nftContractAddresses[2];

        emit NFTContractAddressesSet( _nftContractAddresses);
    }

    /// @notice Set gymLiquidityWallet
    function setgymLiquidityWallet(address _gymLiquidityWallet) external onlyOwner {
        gymLiquidityWallet =  _gymLiquidityWallet;
    }
    /// @notice Set streetLevelPools
    function setStreetLevelPoolsAddress(address _streetLevelPools) external onlyOwner {
        streetLevelPools =  _streetLevelPools;
    }

    function setWhiteLsitedAddresses(address _address, bool _whiteList) external onlyOwner {
        whiteListed[_address] = _whiteList;
    }
    
    /// @notice Set addresses to all smart contract and wallet addresses we currently distribute the amounts to
    function setDistributionReceiverAddresses(address[12] calldata _distributionReceiverAddresses) external onlyOwner {
        nftReflectionPoolAddress = _distributionReceiverAddresses[0];
        netGymStreetAddress = _distributionReceiverAddresses[1];
        ambassadorWalletAddress = _distributionReceiverAddresses[2];
        reserveWalletAddress = _distributionReceiverAddresses[3];
        companyWalletAddress = _distributionReceiverAddresses[4];
        gymTurnoverPoolAddress =_distributionReceiverAddresses[5];
        buyAndBurnAddress = _distributionReceiverAddresses[6];
        nftRankRewardsAddress = _distributionReceiverAddresses[7];
        vBTCBuyAndBurnWallet = _distributionReceiverAddresses[8];
        liquidityWallet = _distributionReceiverAddresses[9];
        municipalityAddress = _distributionReceiverAddresses[10];
        companyWalletMetablocks = _distributionReceiverAddresses[11];

        emit DistributionReceiverAddressesSet(_distributionReceiverAddresses);
    }

    // @notice Distribution of the received amount
    function _distributeAmounts(uint256 _amount, uint8 _operationType, address _user) private {
        address companyAddress = companyWalletAddress;
        if(
            _operationType == OPERATION_TYPE_MINT_MINERS || 
            _operationType == OPERATION_TYPE_PURCHASE_REPAIR || 
            _operationType == OPERATION_TYPE_PURCHASE_ELECTRICITY
        ){
            companyAddress = companyWalletMetablocks;
        }

        uint256[10] memory distributionPercentages = operationTypeToPercentagesMapping[_operationType];
        // transfer 20% to company Wallet
        _transferAmountTo((_amount * distributionPercentages[0]) / 100, companyAddress);
        // transfer 5% to NFT Reflection pool and distribute according to gGymnet shares
        _distributeNftReflectionPool((_amount * distributionPercentages[1]) / 100);
        // transfer 1% to marketing wallet
        _transferAmountTo((_amount * distributionPercentages[2]) / 100, marketingWallet);

        // transfer 8% or 4% to management wallet for vBTC liquidity
        vbtcLiquidityAmount += (distributionPercentages[3] * _amount) / 100;
        _transferAmountTo((_amount * distributionPercentages[3]) / 100, gymLiquidityWallet);
        // transfer 10% or 15% to Gymnet buyAndBurn adrress / 40% for electricity
        _buyAndBurnGYMNET((distributionPercentages[4] * _amount) / 100);
        // transfer 3% to gym turnover pool address
        _transferAmountTo((_amount * distributionPercentages[5]) / 100, gymTurnoverPoolAddress);
        // transfer 39% to NFTMLM and distribute among referrers accordingly
        _distributeNetGymStreet((_amount * distributionPercentages[6]) / 100, _amount, _user);
        // transfer 0.7% to reserve Wallet
        _transferAmountTo((_amount * distributionPercentages[7]) / 100, reserveWalletAddress);
        // transfer 5% to Ambassador Wallet
        _transferAmountTo((_amount * distributionPercentages[8]) / 100, ambassadorWalletAddress);
        // transfer 2.3% to NFT RankRewards wallet
        _transferAmountTo((distributionPercentages[9] * _amount) / 100, nftRankRewardsAddress);
        // send 3% to Gymstreet Level Pools
        _transferAmountTo((3 * _amount) / 100, streetLevelPools);
    }

    function _distributeNftReflectionPool(uint256 _amount) private {
        if (_amount > 0) {
            _transferAmountTo(_amount, nftReflectionPoolAddress);
            INftReflection(nftReflectionPoolAddress).updatePool(_amount);
        }
    }
    function _buyAndBurnGYMNET(uint256 _buyAndBurnAmountGYM) private {
        IERC20Upgradeable(busdAddress).safeTransfer(buyAndBurnAddress, (_buyAndBurnAmountGYM));
    }


    function _distributeNetGymStreet(
        uint256 _amount,
        uint256 _distributeAmount,
        address _user
    ) private {
        if (_amount > 0) {
            _transferAmountTo(_amount, netGymStreetAddress);
            INetGymStreet(netGymStreetAddress).distributeRewards(
                _distributeAmount,
                busdAddress,
                _user
            );
        }
    }

    /// @notice Transfer the given amount to a specified wallet
    function _transferAmountTo(uint256 _amount, address _walletAddress) private {
        if (_amount > 0) {
            IERC20Upgradeable(busdAddress).safeTransfer(_walletAddress, _amount);
        }
    }

    /// @notice Convert the amounts
    function _convertBUSDtoBNB(uint256 _amount) private returns (uint256) {
        IERC20Upgradeable(busdAddress).safeApprove(routerAddress, _amount);
        return _swapTokens(busdAddress, wbnbAddress, _amount, address(this), block.timestamp + 100);
    }

    /// @notice Swap the given tokens
    function _swapTokens(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        address receiver,
        uint256 deadline
    ) private returns (uint256) {
        require(inputToken != outputToken, "Municipality: Invalid swap path");

        address[] memory path = new address[](2);

        path[0] = inputToken;
        path[1] = outputToken;

        uint256[] memory swapResult = IPancakeRouter02(routerAddress).swapExactTokensForTokens(
            inputAmount,
            0,
            path,
            receiver,
            deadline
        );
        return swapResult[1];
    }

  function setGlobalLineAddress(address _address)  external onlyOwner {
    reserveWalletAddress = _address;
  }

}
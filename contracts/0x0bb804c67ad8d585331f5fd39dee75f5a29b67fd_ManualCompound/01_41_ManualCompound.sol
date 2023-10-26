// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


import "../interfaces/IMasterPenpie.sol";
import "../interfaces/IMasterPenpieMeta.sol";
import "../interfaces/IBaseRewardPool.sol";
import "../interfaces/ILocker.sol";
import { IPendleMarketDepositHelper } from "../interfaces/pendle/IPendleMarketDepositHelper.sol";
import "../interfaces/pendle/IPendleRouter.sol";
import "../interfaces/IConvertor.sol";

contract ManualCompound is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    address public PENDLE;
    address public PENPIE;
    address public pnpLocker;
    address public pendleSwap;
    address public marketDepositHelper;
    address public pendleStaking;
    address public mPendleConverter;
    address public kyBerSwapRouter;
    address private ADDREESS_ZERO = address(0);

    uint256 public constant LIQUIDATE_TO_PENDLE_FINANCE = 1;
    uint256 public constant CONVERT_TO_MPENDLE = 2;

    uint256 public constant MPENDLE_STAKE_MODE = 1;

    IPendleRouter public pendleRouter;
    IMasterPenpie public masterPenpie;

    struct pendleDexApproxParams 
    {
        uint256 guessMin;
        uint256 guessMax;
        uint256 guessOffChain;
        uint256 maxIteration;
        uint256 eps;
    }

    // pendleDexApproxParams public pendledexParams;
   
    mapping(address => bool) public compoundableRewards;

    /* ============ Events ============ */

    event HelperSet(address helper);
    event LockerSet(address locker);
    event RewardTokensAdded(address[] rewardTokens);
    event RewardTokensRemoved(address[] rewardToken);
    event Compounded(address indexed user, uint256 marketLength, uint256 rewardLength);
    event DepositHelperSet(address marketDepositHelper);
    event pendleRouterSet(address pendleRouter);
    event mPendleConerterSet(address mPendleConverter);
    event kyBerSwapRouterSet(address kyBerSwapRouter);
    event PendleSwapSet(address pendleSwap);
    event zapInPendleMarket(address user, uint256 totalAmount, address market, uint256 compoundingMode);
    event convertedToMpendle(address user, address sourceRewardToken,  uint256 totalAmount, uint256 compoundingMode, uint256 mPendleConvertMode);
    event lockedPenpie(address user,address sourceRewardToken, uint256 totalAmount);
    event pendleDexApproxParamsSet( uint256 guessMin, uint256 guessMax, uint256 guessOffChain, uint256 maxIteration, uint256 eps);

    /* ============ Custom Errors ============ */

    error IsNotSmartContractAddress();
    error InputDataLengthMissMatch();
    error InputDataIsNotValide();

    /* ============ Constructor ============ */

    constructor() {
        _disableInitializers();
    }

    function __manualCompound_init(
        address _pendle,
        address _penpie,
        address _masterPenpie,
        address _pendleRouter,
        address _pnplocker,
        address _DepositHelper,
        address _PendleStaking,
        address _mPendleConverter,
        address _kyberSwapRouter,
        address _pendleSwap
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        PENDLE = _pendle;
        PENPIE = _penpie;
        masterPenpie = IMasterPenpie(_masterPenpie);
        pendleRouter = IPendleRouter(_pendleRouter);
        pnpLocker = _pnplocker;
        marketDepositHelper = _DepositHelper;
        pendleStaking = _PendleStaking;
        mPendleConverter = _mPendleConverter;
        kyBerSwapRouter = _kyberSwapRouter;
        pendleSwap = _pendleSwap;
    }

   
    /* ============ External Functions ============ */

    function setPendleRouter(
        address _pendleRouter
    ) external onlyOwner {
        if(!Address.isContract(_pendleRouter)) revert IsNotSmartContractAddress();

        pendleRouter = IPendleRouter(_pendleRouter);

        emit pendleRouterSet(_pendleRouter);
    }

    function setLocker(
        address _pnplocker
    ) external onlyOwner {
        if(!Address.isContract(_pnplocker)) revert IsNotSmartContractAddress();

        pnpLocker = _pnplocker;
        emit LockerSet(_pnplocker);
    }

    function setDepositHelper(address _DepositHelper) external onlyOwner {
        if(!Address.isContract(_DepositHelper)) revert IsNotSmartContractAddress();

        marketDepositHelper = _DepositHelper;
        emit DepositHelperSet(marketDepositHelper);
    }

    function setPendleStaking(address _PendleStaking) external onlyOwner {
        if(!Address.isContract(_PendleStaking)) revert IsNotSmartContractAddress();

        pendleStaking = _PendleStaking;
        emit DepositHelperSet(pendleStaking);
    }

     function setMPendleConverter(address _mPendleConverter) external onlyOwner {
        if(!Address.isContract(_mPendleConverter)) revert IsNotSmartContractAddress();

        mPendleConverter = _mPendleConverter;
        emit DepositHelperSet(mPendleConverter);
    }

    function setKyberSwapRouter(address _kyberSwapRouter) external onlyOwner {
        if(!Address.isContract(_kyberSwapRouter)) revert IsNotSmartContractAddress();

        kyBerSwapRouter = _kyberSwapRouter;
        emit kyBerSwapRouterSet(kyBerSwapRouter);
    }
    
    function setPendleSwap(address _pendleSwap) external onlyOwner {
        if(!Address.isContract(_pendleSwap)) revert IsNotSmartContractAddress();

        pendleSwap = _pendleSwap;
        emit PendleSwapSet(pendleSwap);
    }

    function setRewardTokensAsCompoundable(
        address[] calldata  _rewardTokenAddress
    ) external onlyOwner {
        uint256 tokensLength = _rewardTokenAddress.length;

        for(uint256 i = 0;i < tokensLength; )
        {
            compoundableRewards[_rewardTokenAddress[i]] = true;
            unchecked{ i++; }
        }
        
        emit RewardTokensAdded(_rewardTokenAddress);
    }

    function removeRewardTokensAsCompoundable(
        address[] calldata _rewardTokenAddress
    ) external onlyOwner {
        uint256 tokensLength = _rewardTokenAddress.length;

        for(uint256 i = 0;i < tokensLength; )
        {
            compoundableRewards[_rewardTokenAddress[i]] = false;
            unchecked{ i++; }
        }
        
        emit RewardTokensRemoved( _rewardTokenAddress);
    }

    function isRewardCompudable( address _tokenAddress ) external view returns(bool)
    {
        return compoundableRewards[_tokenAddress];
    }

    // receive() external payable {}

 function compound(
        address[] memory _lps,
        address[][] memory _rewards,
        bytes[] memory _kyBarExectCallData,
        address[] memory baseTokens,
        uint256[] memory compoundingMode,
        pendleDexApproxParams memory _pdexparams
    ) external {

        if(_rewards.length != _lps.length) revert InputDataLengthMissMatch();
        if(baseTokens.length != _kyBarExectCallData.length) revert InputDataLengthMissMatch();

        uint256  userTotalPendleRewardToSendBack;
        uint256 userTotalPendleRewardToConvertMpendle;
        uint256[] memory userPendleRewardsForCurrentMarket = new uint256[](_lps.length);

        for(uint256 k; k < _lps.length;k++)
        {
            (,,,userPendleRewardsForCurrentMarket[k]) =  masterPenpie.pendingTokens(_lps[k], msg.sender, PENDLE);
        }
    
        if(compoundingMode.length != userPendleRewardsForCurrentMarket.length) revert InputDataLengthMissMatch();

        masterPenpie.multiclaimOnBehalf(
                _lps,
                _rewards,
                msg.sender
        );  
        
        for (uint256 i; i < _lps.length;i++) {
                            
                for (uint j; j < _rewards[i].length;j++) {
                   
                    address _rewardTokenAddress  = _rewards[i][j];
                    uint256 receivedBalance = IERC20(_rewardTokenAddress).balanceOf(
                        address(this)
                    );

                    if(receivedBalance == 0) continue;

                    if (!compoundableRewards[_rewardTokenAddress]) {
                            IERC20(_rewardTokenAddress).safeTransfer(
                                msg.sender,
                                receivedBalance
                            );
                    }

                    if (_rewardTokenAddress == PENDLE) {
                        if(compoundingMode[i] == LIQUIDATE_TO_PENDLE_FINANCE)
                        {
                            IERC20(PENDLE).safeApprove(address(pendleRouter),userPendleRewardsForCurrentMarket[i]);
                            _ZapInToPendleMarket(userPendleRewardsForCurrentMarket[i], _lps[i], baseTokens[i], _kyBarExectCallData[i], _pdexparams );
                        }
                        else if( compoundingMode[i] == CONVERT_TO_MPENDLE )
                        {
                            userTotalPendleRewardToConvertMpendle += userPendleRewardsForCurrentMarket[i];
                        }
                        else
                        {
                            userTotalPendleRewardToSendBack += userPendleRewardsForCurrentMarket[i];
                        }
                    } 
                    else if (_rewardTokenAddress == PENPIE) {
                            _lockPenpie(receivedBalance);
                    } 
                    else {
                        IERC20(_rewardTokenAddress).safeTransfer(
                            msg.sender,
                            receivedBalance
                        );
                    }   
                }
        }
        
        if(userTotalPendleRewardToConvertMpendle != 0) _convertToMPendle(userTotalPendleRewardToConvertMpendle);
        if(userTotalPendleRewardToSendBack != 0 ) IERC20(PENDLE).safeTransfer( msg.sender, userTotalPendleRewardToSendBack );
       
        emit Compounded(msg.sender, _lps.length, _rewards.length);
    }

    /* ============ Internel Functions ============ */

    function _lockPenpie( uint256 _receivedRewardBalance) internal
    {
        IERC20(PENPIE).safeApprove(
            pnpLocker,
            _receivedRewardBalance
        );

        ILocker(pnpLocker).lockFor(
            _receivedRewardBalance,
            msg.sender
        );
     
        emit lockedPenpie(msg.sender, PENPIE,  _receivedRewardBalance );
    }

    function _convertToMPendle(uint256 _receivedRewardBalance) internal
    {
            IERC20(PENDLE).safeApprove(mPendleConverter, _receivedRewardBalance);
            IConvertor(mPendleConverter).convert(msg.sender, _receivedRewardBalance, MPENDLE_STAKE_MODE);
            emit convertedToMpendle(msg.sender, PENDLE, _receivedRewardBalance, CONVERT_TO_MPENDLE, MPENDLE_STAKE_MODE);
    }

    function _ZapInToPendleMarket( uint256 pendleRewardAmount, address _market, address _baseToken, bytes memory exectCallData, pendleDexApproxParams memory _pdexparams) internal
    {     
        (uint256 netLpOut, ) =  pendleRouter.addLiquiditySingleToken
        ( 
            address(this),
            _market,
            type(uint256).min,
            IPendleRouter.ApproxParams(
                _pdexparams.guessMin,   
                _pdexparams.guessMax,   
                _pdexparams.guessOffChain,   
                _pdexparams.maxIteration,   
                _pdexparams.eps
            ),
            IPendleRouter.TokenInput(
                PENDLE,
                pendleRewardAmount,
                _baseToken,
                ADDREESS_ZERO,
                pendleSwap,
                IPendleRouter.SwapData(
                    IPendleRouter.SwapType.KYBERSWAP,
                    kyBerSwapRouter,
                    exectCallData,
                    false
                )     
            )
        );
        IERC20(_market).safeApprove(
            pendleStaking,
            netLpOut
        );
        IPendleMarketDepositHelper(marketDepositHelper).depositMarketFor(
            _market,
            msg.sender,
            netLpOut
        );
        
        emit zapInPendleMarket( msg.sender, pendleRewardAmount, _market, LIQUIDATE_TO_PENDLE_FINANCE);

    }
}
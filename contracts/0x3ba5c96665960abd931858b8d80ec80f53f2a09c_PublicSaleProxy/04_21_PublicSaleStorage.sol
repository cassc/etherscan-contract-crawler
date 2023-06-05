//SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILockTOS.sol";
import "../libraries/LibPublicSale.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract PublicSaleStorage  {
    /// @dev flag for pause proxy
    bool public pauseProxy;

    uint256 public snapshot = 0;
    uint256 public deployTime;              //contract 배포된 시간
    uint256 public delayTime;               //contract와 snapshot사이 시간

    uint256 public startAddWhiteTime = 0;
    uint256 public endAddWhiteTime = 0;
    uint256 public startExclusiveTime = 0;
    uint256 public endExclusiveTime = 0;

    uint256 public startDepositTime = 0;        //청약 시작시간
    uint256 public endDepositTime = 0;          //청약 끝시간

    uint256 public startClaimTime = 0;

    uint256 public totalUsers = 0;              //전체 세일 참여자 (라운드1,라운드2 포함, 유니크)
    uint256 public totalRound1Users = 0;         //라운드 1 참여자
    uint256 public totalRound2Users = 0;         //라운드 2 참여자
    uint256 public totalRound2UsersClaim = 0;    //라운드 2 참여자중 claim한사람

    uint256 public totalExSaleAmount = 0;       //총 exclu 실제 판매토큰 양 (exclusive)
    uint256 public totalExPurchasedAmount = 0;  //총 지불토큰 받은 양 (exclusive)

    uint256 public totalDepositAmount;          //총 청약 한 양 (openSale)

    uint256 public totalExpectSaleAmount;       //예정된 판매토큰 양 (exclusive)
    uint256 public totalExpectOpenSaleAmount;   //예정된 판매 토큰량 (opensale)

    uint256 public saleTokenPrice;  //판매하는 토큰(DOC)
    uint256 public payTokenPrice;   //받는 토큰(TON)

    uint256 public claimInterval; //클레임 간격 (epochtime)
    uint256 public claimPeriod;   //클레임 횟수
    uint256 public claimFirst;    //초기 클레임 percents

    uint256 public hardCap;       //hardcap 수량 (ton 기준)
    uint256 public changeTOS;     //ton -> tos로 변경하는 %
    uint256 public minPer;        //변경하는 % min
    uint256 public maxPer;        //변경하는 % max

    uint256 public stanTier1;     //최소 기준 Tier1
    uint256 public stanTier2;     //최소 기준 Tier2
    uint256 public stanTier3;     //최소 기준 Tier3
    uint256 public stanTier4;     //최소 기준 Tier4

    address public liquidityVaultAddress; //liquidityVault의 Address
    ISwapRouter public uniswapRouter;
    uint24 public constant poolFee = 3000;

    address public getTokenOwner;
    address public wton;
    address public getToken;

    IERC20 public saleToken;
    IERC20 public tos;
    ILockTOS public sTOS;

    address[] public depositors;
    address[] public whitelists;

    bool public adminWithdraw; //withdraw 실행여부

    uint256 public totalClaimCounts;
    uint256[] public claimTimes;
    uint256[] public claimPercents; 

    mapping (address => LibPublicSale.UserInfoEx) public usersEx;
    mapping (address => LibPublicSale.UserInfoOpen) public usersOpen;
    mapping (address => LibPublicSale.UserClaim) public usersClaim;

    mapping (uint => uint256) public tiers;         //티어별 가격 설정
    mapping (uint => uint256) public tiersAccount;  //티어별 화이트리스트 참여자 숫자 기록
    mapping (uint => uint256) public tiersExAccount;  //티어별 exclusiveSale 참여자 숫자 기록
    mapping (uint => uint256) public tiersPercents;  //티어별 퍼센트 기록
}
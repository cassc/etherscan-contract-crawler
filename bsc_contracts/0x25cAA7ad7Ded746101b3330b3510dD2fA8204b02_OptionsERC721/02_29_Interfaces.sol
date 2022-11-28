// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./IOptionsERC721.sol";
import "./IOptionsVaultERC20.sol";
import "./IOptionsVaultFactory.sol";
import "./IReferrals.sol";
import "../libraries/OptionsLib.sol";
import "./IOptionsHealthCheck.sol";

import "hardhat/console.sol";

interface IOracle {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function latestRoundData() external view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface ERC20Decimals {
    function decimals() external returns (uint8);
} 

interface IStructs {

    struct InputParams {
        address holder;
        uint256 period; 
        uint256 optionSize;
        uint256 strike;
        uint256 currentPrice;
        IStructs.OptionType optionType;
        uint vaultId; 
        IOracle oracle;
        address referrer;
        IOptionsVaultERC20 vault;
        IStructs.OracleResponse oracleResponse;
    }

    struct CalcParams {
        int256 findStrike;     //strike % from current price in basis points
        uint256 matchFee;       
        uint256 matchPeriod;
        uint256 matchPeriodPos;                
        uint256 matchStrikePos;  
        int relativeStrikeFee;      
        int relativePeriodFee;         
        // IOptionsVaultERC20 vault;       
    }    

    struct Fees {
        uint256 total;
        uint256 protocolFee;
        uint256 referFee;
        uint256 intrinsicFee;
        uint256 extrinsicFee;
        uint256 vaultFee;
    }

    enum State {Inactive, Active, Exercised, Expired}
    enum OptionType {Invalid, Put, Call}
    enum BoolState {FalseMutable, TrueMutable, FalseImmutable, TrueImmutable}
    enum SetVariableType {VaultOwner,VaultFeeRecipient,GrantVaultOperatorRole,RevokeVaultOperatorRole,GrantLPWhitelistRole,RevokeLPWhitelistRole, GrantBuyerWhitelistRole,RevokeBuyerWhitelistRole,
    VaultFeeCalc, IpfsHash, ReadOnly, MaxInvest, WithdrawDelayPeriod, LPOpenToPublic, BuyerWhitelistOnly, CollateralizationRatio, OracleWhitelisted, CollateralTokenWhitelisted, CreateVaultIsPermissionless, OracleIsPermissionless, CollateralTokenIsPermissionless, ProtocolFeeCalc,
    Referrals,TokenPairWhitelisted,SwapServiceWhitelisted,CreateVaultWhitelisted, ProtocolFee, ProtocolFeeRecipient, AutoExercisePeriod, WithdrawDelayPeriodLocked, OracleEnabledLocked, VaultFee, VaultFeeCalcLocked, OptionsHealthCheck}

    struct Option  {
        State state;
        address holder;
        uint256 strike;
        uint256 optionSize;
        Fees premium;
        uint256 expiration;
        OptionType optionType;
        uint256 vaultId;
        IOracle oracle;
        address referredBy;
    }

    struct PricePoint{
        int256 strike;
        uint256 fee;
    }

    struct OracleResponse {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }
}

interface IFeeCalcs {
    // function getFees(address holder, uint256 period, uint256 optionSize, uint256 strike, uint256 currentPrice, IStructs.OptionType optionType, uint vaultId, IOracle oracle) external view returns (IStructs.Fees memory fees_);
    function getFees(IStructs.InputParams memory inParams) external view returns (IStructs.Fees memory fees_);
    
}
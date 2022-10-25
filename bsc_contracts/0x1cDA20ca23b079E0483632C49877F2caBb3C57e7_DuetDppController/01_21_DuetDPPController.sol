// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { UniversalERC20 } from "./lib/UniversalERC20.sol";
import { DecimalMath } from "./lib/DecimalMath.sol";

import { Adminable } from "./lib/Adminable.sol";
import { IDODOV2 } from "./interfaces/IDODOV2.sol";
import { IDPPOracleAdmin } from "./interfaces/IDPPOracleAdmin.sol";
import { IDPPOracle } from "./interfaces/IDPPOracle.sol";
import { IWETH } from "./interfaces/IWETH.sol";
import { IOracle } from "./external/interfaces/IOracle.sol";

import { DuetDppLpFunding } from "./DuetDppLpFunding.sol";

/// @title DppController
/// @author So. Lu
/// @notice Use this contract to control dpp state(onlyAdmin), withdraw and deposit lps
contract DuetDppController is Adminable, DuetDppLpFunding {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20Metadata;
    using SafeERC20 for IERC20Metadata;

    address public _WETH_;
    bool flagInit = false;

    /// minBaseReserve for frontrun protection, reset function default param, no use
    /// minQuoteReserve for frontrun protection, reset function default param, no use
    uint256 public minBaseReserve = 0;
    uint256 public minQuoteReserve = 0;

    modifier judgeExpired(uint256 deadLine) {
        require(deadLine >= block.timestamp, "Duet Dpp Controller: EXPIRED");
        _;
    }

    modifier notInitialized() {
        require(flagInit == false, "have been initialized");
        flagInit = true;
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    function init(
        address admin,
        address dppAddress,
        address dppAdminAddress,
        address weth
    ) external notInitialized {
        // 改init
        _WETH_ = weth;
        _DPP_ADDRESS_ = dppAddress;
        _DPP_ADMIN_ADDRESS_ = dppAdminAddress;
        _setAdmin(admin);

        // load pool info
        _BASE_TOKEN_ = IERC20Metadata(IDODOV2(_DPP_ADDRESS_)._BASE_TOKEN_());
        _QUOTE_TOKEN_ = IERC20Metadata(IDODOV2(_DPP_ADDRESS_)._QUOTE_TOKEN_());
        _updateDppInfo();

        string memory connect = "-";
        string memory suffix = "DuetLP_";

        name = string(abi.encodePacked(suffix, _BASE_TOKEN_.symbol(), connect, _QUOTE_TOKEN_.symbol()));
        symbol = "Duet-LP";
        decimals = _BASE_TOKEN_.decimals();

        // ============================== Permit ====================================
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_THIS = address(this);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        bytes32 _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        _CACHED_DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
        // ==========================================================================
    }

    // ========= change DPP Oracle and Parameters , onlyAdmin ==========

    /// @notice change price I
    /// @param newI new price I of dpp pool, unit is 10 ** [18+ quote - base]
    /// @param minBaseReserve_ for frontrun protection,
    /// @param minQuoteReserve_ for frontrun protection
    function tunePrice(
        uint256 newI,
        uint256 minBaseReserve_,
        uint256 minQuoteReserve_
    ) external onlyAdmin returns (bool) {
        IDPPOracleAdmin(_DPP_ADMIN_ADDRESS_).tunePrice(newI, minBaseReserve_, minQuoteReserve_);
        _updateDppInfo();
        return true;
    }

    /// @notice change params for dpp pool
    /// @param newLpFeeRate lp fee rate for dpp pool, unit is 10**18, range in [0, 10**18],eg 3,00000,00000,00000 = 0.003 = 0.3%
    /// @param newI new price I of dpp pool, unit is 10 ** [18+ quote - base]
    /// @param newK a param for swap curve, limit in [0，10**18], unit is  10**18，0 is stable price curve，10**18 is bonding curve like uni
    /// @param minBaseReserve_ for frontrun protection,
    /// @param minQuoteReserve_ for frontrun protection
    function tuneParameters(
        uint256 newLpFeeRate,
        uint256 newI,
        uint256 newK,
        uint256 minBaseReserve_,
        uint256 minQuoteReserve_
    ) external onlyAdmin returns (bool) {
        IDPPOracleAdmin(_DPP_ADMIN_ADDRESS_).tuneParameters(
            newLpFeeRate,
            newI,
            newK,
            minBaseReserve_,
            minQuoteReserve_
        );
        _updateDppInfo();
        return true;
    }

    /// @notice change oracle address
    function changeOracle(address newOracle) external onlyAdmin {
        require(IOracle(newOracle).prices(address(_BASE_TOKEN_)) > 0, "Duet Dpp Controller: invalid oracle price");
        IDPPOracleAdmin(_DPP_ADMIN_ADDRESS_).changeOracle(newOracle);
    }

    function enableOracle() external onlyAdmin {
        address _O_ = IDPPOracle(_DPP_ADDRESS_)._O_();
        require(IOracle(_O_).prices(address(_BASE_TOKEN_)) > 0, "Duet Dpp Controller: invalid oracle price");
        IDPPOracleAdmin(_DPP_ADMIN_ADDRESS_).enableOracle();
    }

    /// @notice disable oracle and set new I
    function disableOracle(uint256 newI) external onlyAdmin {
        require(newI > 0, "Duet Dpp Controller: invaild new I");
        IDPPOracleAdmin(_DPP_ADMIN_ADDRESS_).disableOracle(newI);
    }

    /// @notice use for freeze dppAdmin to change params, while swap is normal
    function setFreezeTimestamp(uint256 timestamp_) external onlyAdmin {
        IDPPOracleAdmin(_DPP_ADMIN_ADDRESS_).setFreezeTimestamp(timestamp_);
    }

    /// @notice change default minBaseReserve and minQuoteReserve
    function changeMinRes(uint256 newBaseR_, uint256 newQuoteR_) external onlyAdmin {
        minBaseReserve = newBaseR_;
        minQuoteReserve = newQuoteR_;
    }

    // =========== deal with LP ===============

    /// @notice add dpp liquidity
    /// @param baseInAmount users declare adding base amount
    /// @param quoteInAmount users declare adding quote amount
    /// @param baseMinAmount slippage protection, baseInAmount *(1 - slippage)
    /// @param quoteMinAmount slippage protection, quoteInAmount *(1 - slippage)
    /// @param flag describe token type, 0 - ERC20, 1 - baseInETH, 2 - quoteInETH
    /// @param deadLine time limit
    function addDuetDppLiquidity(
        uint256 baseInAmount,
        uint256 quoteInAmount,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        uint8 flag,
        uint256 deadLine
    )
        external
        payable
        nonReentrant
        judgeExpired(deadLine)
        returns (
            uint256 shares,
            uint256 baseAdjustedInAmount,
            uint256 quoteAdjustedInAmount
        )
    {
        // oracle check
        address _O_ = IDPPOracle(_DPP_ADDRESS_)._O_();
        require(IOracle(_O_).prices(address(_BASE_TOKEN_)) > 0, "Duet Dpp Controller: invalid oracle price");
        require(IDPPOracle(_DPP_ADDRESS_)._IS_ORACLE_ENABLED(), "Duet Dpp Controller: oracle dpp disabled");

        (baseAdjustedInAmount, quoteAdjustedInAmount) = _adjustedAddLiquidityInAmount(baseInAmount, quoteInAmount, 3);
        require(
            baseAdjustedInAmount >= baseMinAmount && quoteAdjustedInAmount >= quoteMinAmount,
            "Duet Dpp Controller: deposit amount is not enough"
        );

        _deposit(msg.sender, _DPP_ADDRESS_, address(_BASE_TOKEN_), baseAdjustedInAmount, flag == 1);
        _deposit(msg.sender, _DPP_ADDRESS_, address(_QUOTE_TOKEN_), quoteAdjustedInAmount, flag == 2);

        //mint lp tokens to users

        (shares, , ) = _buyShares(msg.sender);
        // reset dpp pool
        require(
            IDODOV2(IDODOV2(_DPP_ADDRESS_)._OWNER_()).reset(
                address(this),
                _LP_FEE_RATE_,
                _I_,
                _K_,
                0, //baseOutAmount, add liquidity so outAmount is 0
                0, //quoteOutAmount, add liquidity so outAmount is 0
                minBaseReserve, // minBaseReserve
                minQuoteReserve // minQuoteReserve
            ),
            "Duet Dpp Controller: Reset Failed"
        );

        // refund dust eth
        if (flag == 1 && msg.value > baseAdjustedInAmount) {
            payable(msg.sender).transfer(msg.value - baseAdjustedInAmount);
        }
        if (flag == 2 && msg.value > quoteAdjustedInAmount) {
            payable(msg.sender).transfer(msg.value - quoteAdjustedInAmount);
        }
    }

    /// @notice remove dpp liquidity
    /// @param shareAmount users withdraw lp amount
    /// @param baseMinAmount slippage protection, baseOutAmount *(1 - slippage)
    /// @param quoteMinAmount slippage protection, quoteOutAmount *(1 - slippage)
    /// @param flag describe token type, 0 - ERC20, 3 - baseOutETH, 4 - quoteOutETH
    /// @param deadLine time limit
    function removeDuetDppLiquidity(
        uint256 shareAmount,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        uint8 flag,
        uint256 deadLine
    )
        external
        nonReentrant
        judgeExpired(deadLine)
        returns (
            uint256 shares,
            uint256 baseOutAmount,
            uint256 quoteOutAmount
        )
    {
        // oracle check
        address _O_ = IDPPOracle(_DPP_ADDRESS_)._O_();
        require(IOracle(_O_).prices(address(_BASE_TOKEN_)) > 0, "Duet Dpp Controller: invalid oracle price");
        require(IDPPOracle(_DPP_ADDRESS_)._IS_ORACLE_ENABLED(), "Duet Dpp Controller: oracle dpp disabled");

        //mint lp tokens to users
        (baseOutAmount, quoteOutAmount) = _sellShares(shareAmount, msg.sender, baseMinAmount, quoteMinAmount);
        // reset dpp pool
        require(
            IDODOV2(IDODOV2(_DPP_ADDRESS_)._OWNER_()).reset(
                address(this),
                _LP_FEE_RATE_,
                _I_,
                _K_,
                baseOutAmount,
                quoteOutAmount,
                minBaseReserve,
                minQuoteReserve
            ),
            "Duet Dpp Controller: Reset Failed"
        );

        _withdraw(payable(msg.sender), address(_BASE_TOKEN_), baseOutAmount, flag == 3);
        _withdraw(payable(msg.sender), address(_QUOTE_TOKEN_), quoteOutAmount, flag == 4);
        shares = shareAmount;
    }

    function _adjustedAddLiquidityInAmount(
        uint256 baseInAmount,
        uint256 quoteInAmount,
        uint8 flag // flag=0 is baseIn fixed, flag=1 is quoteIn fixed， flag = 3 is naturally compare
    ) internal view returns (uint256 baseAdjustedInAmount, uint256 quoteAdjustedInAmount) {
        (uint256 baseReserve, uint256 quoteReserve) = IDODOV2(_DPP_ADDRESS_).getVaultReserve();
        if (quoteReserve == 0 && baseReserve == 0) {
            // when initialize, just support query quoteInAmount
            require(msg.sender == admin, "Duet Dpp Controller: Must initialized by admin");
            // Must initialized by admin
            baseAdjustedInAmount = baseInAmount;
            if (flag != 3) {
                (uint256 i, , , , , , ) = IDODOV2(_DPP_ADDRESS_).getPMMStateForCall();
                quoteAdjustedInAmount = DecimalMath.mulFloor(baseInAmount, i);
            } else {
                quoteAdjustedInAmount = quoteInAmount;
            }
        }
        if (quoteReserve == 0 && baseReserve > 0) {
            baseAdjustedInAmount = baseInAmount;
            quoteAdjustedInAmount = 0;
        }
        if (quoteReserve > 0 && baseReserve > 0) {
            uint256 baseInFix = (quoteInAmount * baseReserve) / quoteReserve;
            uint256 quoteInFix = (baseInAmount * quoteReserve) / baseReserve;
            if ((flag == 3 && quoteInFix <= quoteInAmount) || flag == 0) {
                baseAdjustedInAmount = baseInAmount;
                quoteAdjustedInAmount = quoteInFix;
            } else {
                quoteAdjustedInAmount = quoteInAmount;
                baseAdjustedInAmount = baseInFix;
            }
        }
    }

    /// @notice enter baseInAmount cal outAmount, when initialize, just support query quoteInAmount
    function recommendQuoteInAmount(uint256 baseInAmount_)
        external
        view
        returns (uint256 baseAdjustedInAmount, uint256 quoteAdjustedInAmount)
    {
        return _adjustedAddLiquidityInAmount(baseInAmount_, 0, 0);
    }

    /// @notice enter quoteInAmount cal outBaseAmount, when initialize, this function will return 0, just support recommendQuoteInAmount
    function recommendBaseInAmount(uint256 quoteInAmount_)
        external
        view
        returns (uint256 baseAdjustedInAmount, uint256 quoteAdjustedInAmount)
    {
        return _adjustedAddLiquidityInAmount(0, quoteInAmount_, 1);
    }

    /// @notice enter lp amount  cal baseAmount and quoteAmount
    function recommendBaseAndQuote(uint256 shareAmount_)
        external
        view
        returns (uint256 baseAmount, uint256 quoteAmount)
    {
        (uint256 baseBalance, uint256 quoteBalance) = IDODOV2(_DPP_ADDRESS_).getVaultReserve();
        uint256 totalShares = totalSupply;

        baseAmount = baseBalance.mul(shareAmount_).div(totalShares);
        quoteAmount = quoteBalance.mul(shareAmount_).div(totalShares);
    }

    // ================= internal ====================

    function _updateDppInfo() internal {
        _LP_FEE_RATE_ = IDODOV2(_DPP_ADDRESS_)._LP_FEE_RATE_();
        _K_ = IDODOV2(_DPP_ADDRESS_)._K_();
        _I_ = IDODOV2(_DPP_ADDRESS_)._I_();
    }

    function _deposit(
        address from,
        address to,
        address token,
        uint256 amount,
        bool isETH
    ) internal {
        if (isETH) {
            if (amount > 0) {
                require(msg.value >= amount, "ETH_VALUE_WRONG");
                // case:msg.value > adjustAmount
                IWETH(_WETH_).deposit{ value: amount }();
                if (to != address(this)) SafeERC20.safeTransfer(IERC20Metadata(_WETH_), to, amount);
            }
        } else {
            if (amount > 0) {
                IERC20Metadata(token).safeTransferFrom(from, to, amount);
            }
        }
    }

    function _withdraw(
        address payable to,
        address token,
        uint256 amount,
        bool isETH
    ) internal {
        if (isETH) {
            if (amount > 0) {
                IWETH(_WETH_).withdraw(amount);
                to.transfer(amount);
            }
        } else {
            if (amount > 0) {
                IERC20Metadata(token).safeTransfer(to, amount);
            }
        }
    }

    // =================================================

    function addressToShortString(address _addr) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(8);
        for (uint256 i = 0; i < 4; i++) {
            str[i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[1 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}
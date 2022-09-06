// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IFundAccount, Nav, LpDetail, LpAction, FundCreateParams} from "../interfaces/fund/IFundAccount.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IFundFilter} from "../interfaces/fund/IFundFilter.sol";
import {Errors} from "../libraries/Errors.sol";
import {IWETH9} from "../interfaces/external/IWETH9.sol";

contract FundAccount is IFundAccount, Initializable {
    using SafeERC20 for IERC20;
    using Address for address;

    // Contract version
    uint256 public constant version = 1;

    // FundManager
    address public manager;
    address public weth9;
    IFundFilter public fundFilter;

    // Block time when the account was opened
    uint256 public override since;

    // Block time when the account was closed
    uint256 public override closed;

    // Fund create params
    string public override name;
    address public override gp;
    uint256 public override managementFee;
    uint256 public override carriedInterest;
    address public override underlyingToken;
    address public initiator;
    uint256 public initiatorAmount;
    address public recipient;
    uint256 public recipientMinAmount;
    address[] private _allowedProtocols;
    address[] private _allowedTokens;
    mapping(address => bool) public override isProtocolAllowed;
    mapping(address => bool) public override isTokenAllowed;

    // Fund runtime data
    uint256 public override totalUnit;
    uint256 public override totalCarryInterestAmount;
    uint256 public override lastUpdateManagementFeeAmount;
    uint256 private lastUpdateManagementFeeTime;
    address[] private _lps;
    mapping(address => LpDetail) private _lpDetails;

    receive() external payable {}

    //////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////// VIEW FUNCTIONS ///////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    function ethBalance() external view override returns (uint256) {
        return address(this).balance;
    }

    function totalManagementFeeAmount() external view override returns (uint256) {
        return lastUpdateManagementFeeAmount + _calcManagementFeeFromLastUpdate(_calcTotalValue());
    }

    function allowedProtocols() external view override returns (address[] memory) {
        return _allowedProtocols;
    }

    function allowedTokens() external view override returns (address[] memory) {
        return _allowedTokens;
    }

    function lpList() external view override returns (address[] memory) {
        return _lps;
    }

    function lpDetailInfo(address addr) external view override returns (LpDetail memory) {
        return _lpDetails[addr];
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////// FUND MANAGER ONLY //////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    // Caller restricted for manager only
    modifier onlyManager() {
        require(msg.sender == manager, Errors.NotManager);
        _;
    }

    function initialize(FundCreateParams memory params) external override initializer {
        manager = msg.sender;
        weth9 = IFundManager(manager).weth9();
        fundFilter = IFundManager(manager).fundFilter();
        since = block.timestamp;

        name = params.name;
        gp = params.gp;
        managementFee = params.managementFee;
        carriedInterest = params.carriedInterest;
        underlyingToken = params.underlyingToken;
        initiator = params.initiator;
        initiatorAmount = params.initiatorAmount;
        recipient = params.recipient;
        recipientMinAmount = params.recipientMinAmount;
        _allowedProtocols = params.allowedProtocols;
        _allowedTokens = params.allowedTokens;

        for (uint256 i = 0; i < _allowedProtocols.length; i++) {
            isProtocolAllowed[_allowedProtocols[i]] = true;
        }
        for (uint256 i = 0; i < _allowedTokens.length; i++) {
            isTokenAllowed[_allowedTokens[i]] = true;
        }
    }

    /// @dev Approve token for 3rd party contract
    /// @param token ERC20 token for allowance
    /// @param spender 3rd party contract address
    /// @param amount Allowance amount
    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external override onlyManager {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    /// @dev Transfers tokens from account to provided address
    /// @param token ERC20 token address which should be transferred from this account
    /// @param to Address of recipient
    /// @param amount Amount to be transferred
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external override onlyManager {
        IERC20(token).safeTransfer(to, amount);
    }

    /// @dev setApprovalForAll of token in the account
    /// @param token ERC721 token address
    /// @param spender Approval to address
    /// @param approved approve all or not
    function setTokenApprovalForAll(
        address token,
        address spender,
        bool approved
    ) external override onlyManager {
        IERC721(token).setApprovalForAll(spender, approved);
    }

    /// @dev Executes financial order on 3rd party service
    /// @param target Contract address which should be called
    /// @param data Call data which should be sent
    function execute(
        address target,
        bytes memory data,
        uint256 value
    ) external override onlyManager returns (bytes memory) {
        return target.functionCallWithValue(data, value);
    }

    function updateName(string memory newName) external onlyManager {
        name = newName;
    }

    function buy(address lp, uint256 amount) external onlyManager {
        Nav memory nav = _updateManagementFeeAndCalcNav();
        _buy(lp, amount, nav);
    }

    function sell(address lp, uint256 ratio) external onlyManager {
        Nav memory nav = _updateManagementFeeAndCalcNav();
        (uint256 dao, uint256 carry) = _sell(lp, ratio, nav);
        _transfer(fundFilter.daoAddress(), dao);
        _transfer(gp, carry);
    }

    function close() external onlyManager {
        closed = block.timestamp;
        Nav memory nav = _updateManagementFeeAndCalcNav();
        uint256 daoSum;
        for (uint256 i = 0; i < _lps.length; i++) {
            (uint256 dao, ) = _sell(_lps[i], 10000, nav);
            daoSum += dao;
        }
        _transfer(fundFilter.daoAddress(), daoSum);
        _collect(true);
    }

    function collect() external onlyManager {
        _updateManagementFeeAmount(_calcTotalValue());
        _collect(false);
    }

    function wrapWETH9() external onlyManager {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            IWETH9(weth9).deposit{value: balance}();
        }
    }

    function unwrapWETH9() external onlyManager {
        uint256 balance = IWETH9(weth9).balanceOf(address(this));
        if (balance > 0) {
            IWETH9(weth9).withdraw(balance);
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////// PRIVATE FUNCTIONS //////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    function _calcTotalValue() private view returns (uint256) {
        if (closed > 0) {
            return _underlyingBalance();
        } else {
            return IFundManager(manager).calcTotalValue(address(this));
        }
    }

    function _calcManagementFeeFromLastUpdate(uint256 _totalValue) private view returns (uint256) {
        return (_totalValue * managementFee * (block.timestamp - lastUpdateManagementFeeTime)) / (1e4 * 365 * 86400);
    }

    function _updateManagementFeeAmount(uint256 _totalValue) private returns (uint256 recent) {
        recent = _calcManagementFeeFromLastUpdate(_totalValue);
        lastUpdateManagementFeeAmount += recent;
        lastUpdateManagementFeeTime = block.timestamp;
    }

    function _updateManagementFeeAndCalcNav() private returns (Nav memory nav) {
        uint256 totalValue = _calcTotalValue();
        uint256 recentFee = _updateManagementFeeAmount(totalValue);
        nav = Nav(totalValue - recentFee, totalUnit);
    }

    function _buy(
        address lp,
        uint256 amount,
        Nav memory nav
    ) private {
        // Calc unit from amount & nav
        uint256 unit;
        if (totalUnit == 0) {
            // account first buy (nav = 1)
            unit = amount;
        } else {
            unit = (amount * nav.totalUnit) / nav.totalValue;
        }

        // Update lpDetail
        LpDetail storage lpDetail = _lpDetails[lp];
        if (lpDetail.totalUnit == 0) {
            // lp first buy
            if (lp != initiator) {
                require(amount >= recipientMinAmount, Errors.NotEnoughBuyAmount);
            }
            _lps.push(lp);
        }
        lpDetail.lpActions.push(LpAction(1, amount, unit, block.timestamp, 0, 0, 0, 0));
        lpDetail.totalUnit += unit;
        lpDetail.totalAmount += amount;

        // Update account
        totalUnit += unit;
    }

    function _sell(
        address lp,
        uint256 ratio,
        Nav memory nav
    ) private returns (uint256 dao, uint256 carry) {
        // Calc unit from ratio & lp's holding units
        LpDetail storage lpDetail = _lpDetails[lp];
        uint256 unit = (lpDetail.totalUnit * ratio) / 1e4;

        // Calc amount from unit & nav
        uint256 amount = (nav.totalValue * unit) / nav.totalUnit;

        // Calc principal from unit & lp's holding nav
        uint256 base = (lpDetail.totalAmount * unit) / lpDetail.totalUnit;

        // Calc gain/loss detail from amount & base
        uint256 gain;
        uint256 loss;
        if (amount >= base) {
            gain = amount - base;
            dao = (gain * fundFilter.daoProfit()) / 1e4;
            carry = ((gain - dao) * carriedInterest) / 1e4;
        } else {
            loss = base - amount;
        }

        // Update lpDetail
        lpDetail.lpActions.push(LpAction(2, amount, unit, block.timestamp, gain, loss, carry, dao));
        lpDetail.totalUnit -= unit;
        lpDetail.totalAmount -= base;

        // Update account
        totalUnit -= unit;
        totalCarryInterestAmount += carry;

        // Transfer
        if (lp != gp) {
            _transfer(lp, amount - dao - carry);
        } else {
            // merge transfers for gp
            carry = amount - dao;
        }
    }

    function _collect(bool allBalance) private {
        uint256 collectAmount;
        if (allBalance) {
            collectAmount = _underlyingBalance();
        } else {
            collectAmount = lastUpdateManagementFeeAmount;
        }
        lastUpdateManagementFeeAmount = 0;
        _transfer(gp, collectAmount);
    }

    function _underlyingBalance() private view returns (uint256) {
        if (underlyingToken == weth9) {
            return address(this).balance;
        } else {
            return IERC20(underlyingToken).balanceOf(address(this));
        }
    }

    function _transfer(address to, uint256 value) private {
        if (value > 0) {
            if (underlyingToken == weth9) {
                if (to.code.length > 0) {
                    // Smart contract may refuse to receive ETH
                    // This will block execution of closing account
                    // So send WETH to smart contract instead
                    IWETH9(weth9).deposit{value: value}();
                    IERC20(weth9).safeTransfer(to, value);
                } else {
                    payable(to).transfer(value);
                }
            } else {
                IERC20(underlyingToken).safeTransfer(to, value);
            }
        }
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Decimal} from "./utils/Decimal.sol";
import {IExchangeWrapper} from "./interface/IExchangeWrapper.sol";
import {IInsuranceFund} from "./interface/IInsuranceFund.sol";
import {DecimalERC20} from "./utils/DecimalERC20.sol";
import {IAmm} from "./interface/IAmm.sol";

contract InsuranceFund is IInsuranceFund, OwnableUpgradeable, DecimalERC20 {
    using Decimal for Decimal.decimal;

    //
    // EVENTS
    //

    event Withdrawn(address indexed withdrawer, uint256 amount);
    event ShutdownAllAmms(uint256 indexed blockNumber);
    event AmmAdded(address indexed amm);
    event AmmRemoved(address indexed amm);

    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//

    mapping(address => uint256) private ammMap;
    IAmm[] public amms;
    IERC20 public override quoteToken;

    // contract dependencies
    IExchangeWrapper public exchange;
    IERC20 public palmToken;
    address public beneficiary;

    modifier requireNonZeroAddress(address _addr) {
        require(_addr != address(0), "InsuranceFund: zero address");
        _;
    }

    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //
    // FUNCTIONS
    //

    function initialize(address _quoteToken)
        external
        initializer
        requireNonZeroAddress(_quoteToken)
    {
        __Ownable_init();

        quoteToken = IERC20(_quoteToken);
    }

    /**
     * @dev only owner can call
     * @param _amm IAmm address
     */
    function addAmm(IAmm _amm)
        external
        onlyOwner
        requireNonZeroAddress(address(_amm))
    {
        require(!isExistedAmm(_amm), "InsuranceFund: amm already added");
        amms.push(_amm);
        ammMap[address(_amm)] = amms.length;
        emit AmmAdded(address(_amm));
    }

    /**
     * @dev only owner can call. no need to call
     * @param _amm IAmm address
     */
    function removeAmm(IAmm _amm) external onlyOwner {
        require(isExistedAmm(_amm), "InsuranceFund: amm not existed");
        uint256 idx = ammMap[address(_amm)];
        uint256 ammLength = amms.length;
        amms[idx - 1] = amms[ammLength - 1];
        delete ammMap[address(_amm)];
        ammMap[address(amms[idx - 1])] = idx;
        amms.pop();
        emit AmmRemoved(address(_amm));
    }

    /**
     * @notice shutdown all Amms when fatal error happens
     * @dev only owner can call. Emit `ShutdownAllAmms` event
     */
    function shutdownAllAmm() external onlyOwner {
        for (uint256 i; i < amms.length; i++) {
            amms[i].shutdown();
        }
        emit ShutdownAllAmms(block.number);
    }

    /**
     * @notice withdraw quote token to caller
     * @param _amount the amount of quoteToken caller want to withdraw
     */
    function withdraw(Decimal.decimal calldata _amount) external override {
        require(
            beneficiary == _msgSender(),
            "InsuranceFund: caller is not beneficiary"
        );
        require(_amount.toUint() != 0, "InsuranceFund: zero amount");

        Decimal.decimal memory quoteBalance = _quoteBalanceOf();
        if (
            _amount.toUint() > quoteBalance.toUint() &&
            address(exchange) != address(0)
        ) {
            Decimal.decimal memory insufficientAmount = _amount.subD(
                quoteBalance
            );
            _swapEnoughQuoteAmount(insufficientAmount);
            quoteBalance = _quoteBalanceOf();
        }
        require(
            quoteBalance.toUint() >= _amount.toUint(),
            "InsuranceFund: Fund not enough"
        );

        _transfer(quoteToken, _msgSender(), _amount);
        emit Withdrawn(_msgSender(), _amount.toUint());
    }

    //
    // SETTER
    //

    function setExchange(address _exchange)
        external
        onlyOwner
        requireNonZeroAddress(_exchange)
    {
        exchange = IExchangeWrapper(_exchange);
    }

    function setBeneficiary(address _beneficiary)
        external
        onlyOwner
        requireNonZeroAddress(_beneficiary)
    {
        beneficiary = _beneficiary;
    }

    function setPalmToken(address _palmToken)
        external
        onlyOwner
        requireNonZeroAddress(_palmToken)
    {
        palmToken = IERC20(_palmToken);
    }

    //
    // INTERNAL FUNCTIONS
    //

    function _swapEnoughQuoteAmount(Decimal.decimal memory _requiredQuoteAmount)
        internal
    {
        // swap palm token to quote token
        Decimal.decimal memory requiredPerpAmount = exchange.getOutputPrice(
            palmToken,
            quoteToken,
            _requiredQuoteAmount
        );

        _approve(palmToken, address(exchange), requiredPerpAmount);
        exchange.swapInput(
            palmToken,
            quoteToken,
            requiredPerpAmount,
            _requiredQuoteAmount
        );
    }

    //
    // VIEW
    //
    function isExistedAmm(IAmm _amm) public view override returns (bool) {
        return ammMap[address(_amm)] != 0;
    }

    function getAllAmms() external view override returns (IAmm[] memory) {
        return amms;
    }

    function _quoteBalanceOf() internal view returns (Decimal.decimal memory) {
        return _balanceOf(quoteToken, address(this));
    }
}
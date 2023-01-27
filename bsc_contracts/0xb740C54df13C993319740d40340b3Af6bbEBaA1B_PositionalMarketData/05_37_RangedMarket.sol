// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/utils/SafeERC20.sol";

// Internal references
import "./RangedPosition.sol";
import "./RangedMarketsAMM.sol";
import "../interfaces/IPositionalMarket.sol";
import "../interfaces/IPositionalMarketManager.sol";

contract RangedMarket {
    using SafeERC20 for IERC20;

    enum Position {In, Out}

    IPositionalMarket public leftMarket;
    IPositionalMarket public rightMarket;

    struct Positions {
        RangedPosition inp;
        RangedPosition outp;
    }

    Positions public positions;

    RangedMarketsAMM public rangedMarketsAMM;

    bool public resolved = false;

    uint finalPrice;

    /* ========== CONSTRUCTOR ========== */

    bool public initialized = false;

    function initialize(
        address _leftMarket,
        address _rightMarket,
        address _in,
        address _out,
        address _rangedMarketsAMM
    ) external {
        require(!initialized, "Ranged Market already initialized");
        initialized = true;
        leftMarket = IPositionalMarket(_leftMarket);
        rightMarket = IPositionalMarket(_rightMarket);
        positions.inp = RangedPosition(_in);
        positions.outp = RangedPosition(_out);
        rangedMarketsAMM = RangedMarketsAMM(_rangedMarketsAMM);
    }

    function mint(
        uint value,
        Position _position,
        address minter
    ) external onlyAMM {
        if (value == 0) {
            return;
        }
        _mint(minter, value, _position);
    }

    function _mint(
        address minter,
        uint amount,
        Position _position
    ) internal {
        if (_position == Position.In) {
            positions.inp.mint(minter, amount);
        } else {
            positions.outp.mint(minter, amount);
        }
        emit Mint(minter, amount, _position);
    }

    function burnIn(uint value, address claimant) external onlyAMM {
        if (value == 0) {
            return;
        }
        (IPosition up, ) = IPositionalMarket(leftMarket).getOptions();
        IERC20(address(up)).safeTransfer(msg.sender, value / 2);

        (, IPosition down1) = IPositionalMarket(rightMarket).getOptions();
        IERC20(address(down1)).safeTransfer(msg.sender, value / 2);

        positions.inp.burn(claimant, value);
        emit Burn(claimant, value, Position.In);
    }

    function burnOut(uint value, address claimant) external onlyAMM {
        if (value == 0) {
            return;
        }
        (, IPosition down) = IPositionalMarket(leftMarket).getOptions();
        IERC20(address(down)).safeTransfer(msg.sender, value);

        (IPosition up1, ) = IPositionalMarket(rightMarket).getOptions();
        IERC20(address(up1)).safeTransfer(msg.sender, value);

        positions.outp.burn(claimant, value);

        emit Burn(claimant, value, Position.Out);
    }

    function canExercisePositions() external view returns (bool) {
        if (!leftMarket.resolved() && !leftMarket.canResolve()) {
            return false;
        }
        if (!rightMarket.resolved() && !rightMarket.canResolve()) {
            return false;
        }

        uint inBalance = positions.inp.balanceOf(msg.sender);
        uint outBalance = positions.outp.balanceOf(msg.sender);

        if (inBalance == 0 && outBalance == 0) {
            return false;
        }

        return true;
    }

    function exercisePositions() external {
        if (leftMarket.canResolve()) {
            IPositionalMarketManager(rangedMarketsAMM.thalesAmm().manager()).resolveMarket(address(leftMarket));
        }
        if (rightMarket.canResolve()) {
            IPositionalMarketManager(rangedMarketsAMM.thalesAmm().manager()).resolveMarket(address(rightMarket));
        }
        require(leftMarket.resolved() && rightMarket.resolved(), "Left or Right market not resolved yet!");

        uint inBalance = positions.inp.balanceOf(msg.sender);
        uint outBalance = positions.outp.balanceOf(msg.sender);

        require(inBalance != 0 || outBalance != 0, "Nothing to exercise");

        if (!resolved) {
            resolveMarket();
        }

        // Each option only needs to be exercised if the account holds any of it.
        if (inBalance != 0) {
            positions.inp.burn(msg.sender, inBalance);
        }
        if (outBalance != 0) {
            positions.outp.burn(msg.sender, outBalance);
        }

        Position curResult = Position.Out;
        if ((leftMarket.result() == IPositionalMarket.Side.Up) && (rightMarket.result() == IPositionalMarket.Side.Down)) {
            curResult = Position.In;
        }

        // Only pay out the side that won.
        uint payout = (curResult == Position.In) ? inBalance : outBalance;
        if (payout != 0) {
            rangedMarketsAMM.transferSusdTo(
                msg.sender,
                IPositionalMarketManager(rangedMarketsAMM.thalesAmm().manager()).transformCollateral(payout)
            );
        }
        emit Exercised(msg.sender, payout, curResult);
    }

    function canResolve() external view returns (bool) {
        // The markets must be resolved
        if (!leftMarket.resolved() && !leftMarket.canResolve()) {
            return false;
        }
        if (!rightMarket.resolved() && !rightMarket.canResolve()) {
            return false;
        }

        return !resolved;
    }

    function resolveMarket() public {
        // The markets must be resolved
        if (leftMarket.canResolve()) {
            IPositionalMarketManager(rangedMarketsAMM.thalesAmm().manager()).resolveMarket(address(leftMarket));
        }
        if (rightMarket.canResolve()) {
            IPositionalMarketManager(rangedMarketsAMM.thalesAmm().manager()).resolveMarket(address(rightMarket));
        }
        require(leftMarket.resolved() && rightMarket.resolved(), "Left or Right market not resolved yet!");
        require(!resolved, "Already resolved!");

        if (positions.inp.totalSupply() > 0 || positions.outp.totalSupply() > 0) {
            leftMarket.exerciseOptions();
            rightMarket.exerciseOptions();
        }
        resolved = true;

        if (rangedMarketsAMM.sUSD().balanceOf(address(this)) > 0) {
            rangedMarketsAMM.sUSD().transfer(address(rangedMarketsAMM), rangedMarketsAMM.sUSD().balanceOf(address(this)));
        }

        (, , uint _finalPrice) = leftMarket.getOracleDetails();
        finalPrice = _finalPrice;
        emit Resolved(result(), finalPrice);
    }

    function result() public view returns (Position resultToReturn) {
        resultToReturn = Position.Out;
        if ((leftMarket.result() == IPositionalMarket.Side.Up) && (rightMarket.result() == IPositionalMarket.Side.Down)) {
            resultToReturn = Position.In;
        }
    }

    function withdrawCollateral(address recipient) external onlyAMM {
        rangedMarketsAMM.sUSD().transfer(recipient, rangedMarketsAMM.sUSD().balanceOf(address(this)));
    }

    modifier onlyAMM {
        require(msg.sender == address(rangedMarketsAMM), "only the AMM may perform these methods");
        _;
    }

    event Mint(address minter, uint amount, Position _position);
    event Burn(address burner, uint amount, Position _position);
    event Exercised(address exerciser, uint amount, Position _position);
    event Resolved(Position winningPosition, uint finalPrice);
}
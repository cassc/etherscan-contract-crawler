//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../utils/Constants.sol';
import '../../interfaces/IZunami.sol';
import '../../interfaces/IStrategy.sol';

//import "hardhat/console.sol";

contract ClaimingStrat is Ownable {
    using SafeERC20 for IERC20Metadata;

    IZunami public zunami;
    IERC20Metadata[3] public tokens;

    uint256 public managementFees = 0;

    uint256[3] public decimalsMultipliers;

    struct Claim {
        address claimer;
        uint256 balance;
        uint256 batch;
        bool withdrew;
    }

    uint256 public totalBalance;
    uint256 public currentBatch = 1;

    mapping(address => Claim) public claims;

    mapping(uint256 => uint256) public batchesTotalBalance;
    mapping(uint256 => bool) public batchesFinished;
    mapping(uint256 => uint256[3]) public batchesAmounts;

    event NewBatchStarted(uint256 previousBatch, uint256 newBatch);
    event BatchFinished(uint256 batchFinished, uint256[3] totalBatchAmounts);

    event ClaimCreated(address indexed claimer, uint256 balance);
    event ClaimRequested(address indexed claimer, uint256 inBatch);
    event ClaimWithdrew(address indexed claimer, uint256[3] tokenAmounts);

    modifier onlyZunami() {
        require(_msgSender() == address(zunami), 'must be called by Zunami contract');
        _;
    }

    constructor(IERC20Metadata[3] memory _tokens) {
        tokens = _tokens;

        for (uint256 i; i < 3; i++) {
            decimalsMultipliers[i] = calcTokenDecimalsMultiplier(_tokens[i]);
        }
    }

    function startNewBatch() external onlyOwner {
        require(
            currentBatch == 1 || (currentBatch > 1 && batchesFinished[currentBatch - 1]),
            "Not finished previous batch"
        );
        currentBatch += 1;
        emit NewBatchStarted(currentBatch - 1, currentBatch);
    }

    function finishPreviousBatch(uint256[3] memory _batchAmounts) external onlyOwner {
        require(_batchAmounts[0] > 0 || _batchAmounts[1] > 0 || _batchAmounts[2] > 0, "Wrong amounts");
        uint256 previousBatch = currentBatch - 1;
        require(currentBatch > 1 && !batchesFinished[previousBatch], "Not started second or already finished");
        batchesFinished[previousBatch] = true;
        batchesAmounts[previousBatch] = _batchAmounts;
        emit BatchFinished(previousBatch, _batchAmounts);
    }

    function createClaims(address[] memory _claimers, uint256[] memory _balances) external onlyOwner {
        require(_claimers.length == _balances.length, "Wrong length");
        for(uint256 i = 0; i < _claimers.length; i++) {
            address claimer = _claimers[i];
            uint256 balance = _balances[i];
            require(claims[claimer].balance == 0, "Doubled claim");
            require(balance > 0, "Zero balance");
            require(claimer != address(0), "Zero claimer");
            totalBalance += balance;
            claims[claimer] = Claim(claimer, balance, 0, false);
            emit ClaimCreated(claimer, balance);
        }
    }

    function requestClaim() external {
        address claimer = msg.sender;
        Claim storage claim = claims[claimer];
        require(claim.balance != 0, "Wrong claimer");
        require(claim.batch == 0, "Requested claim");
        claim.batch = currentBatch;
        batchesTotalBalance[currentBatch] += claim.balance;
        emit ClaimRequested(claimer, currentBatch);
    }

    function canWithdrawClaim() external view returns(bool) {
        address claimer = msg.sender;
        Claim memory claim = claims[claimer];
        return (claim.balance != 0)
            && (claim.batch != 0)
            && (!claim.withdrew)
            && (batchesFinished[claim.batch]);
    }

    function withdrawClaim() external {
        address claimer = msg.sender;
        Claim storage claim = claims[claimer];
        require(claim.balance != 0, "Wrong claimer");
        require(claim.batch != 0, "Not requested claim");
        require(!claim.withdrew, "Claim was withdrew");
        require(batchesFinished[claim.batch], "Not finished batch");
        claim.withdrew = true;
        uint256[3] memory tokenAmounts = transferPortionTokensToBatch(
            claimer,
            claim.batch,
            Math.mulDiv(claim.balance, 1e18, batchesTotalBalance[claim.batch], Math.Rounding.Down)
        );

        emit ClaimWithdrew(claimer, tokenAmounts);
    }

    function transferPortionTokensToBatch(address claimer, uint256 batch, uint256 batchProportion) internal returns(uint256[3] memory transfersAmountOut){
        uint256[3] memory batchAmounts = batchesAmounts[batch];
        for (uint256 i = 0; i < 3; i++) {
            uint256 batchAmount = batchAmounts[i];
            if(batchAmount == 0) continue;
            transfersAmountOut[i] = Math.mulDiv(batchAmount, batchProportion, 1e18, Math.Rounding.Down);
            if (transfersAmountOut[i] > 0) {
                tokens[i].safeTransfer(claimer, transfersAmountOut[i]);
            }
        }
    }

    // Zunami strategy interface
    function withdrawAll() external onlyZunami {
        transferAllTokensTo(address(zunami));
    }

    function transferAllTokensTo(address withdrawer) internal {
        uint256 tokenStratBalance;
        IERC20Metadata token_;
        for (uint256 i = 0; i < 3; i++) {
            token_ = tokens[i];
            tokenStratBalance = token_.balanceOf(address(this));
            if (tokenStratBalance > 0) {
                token_.safeTransfer(withdrawer, tokenStratBalance);
            }
        }
    }

    function deposit(uint256[3] memory amounts) external returns (uint256) {
        uint256 depositedAmount;
        for (uint256 i = 0; i < 3; i++) {
            if (amounts[i] > 0) {
                depositedAmount += amounts[i] * decimalsMultipliers[i];
            }
        }

        return depositedAmount;
    }

    function withdraw(
        address withdrawer,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[3] memory,
        uint256,
        uint128
    ) external virtual onlyZunami returns (bool) {
        revert();
    }

    function calcTokenDecimalsMultiplier(IERC20Metadata token) internal view returns (uint256) {
        uint8 decimals = token.decimals();
        require(decimals <= 18, 'Zunami: wrong token decimals');
        if (decimals == 18) return 1;
        unchecked{
            return 10**(18 - decimals);
        }
    }

    function autoCompound() public onlyZunami {}

    function totalHoldings() public view virtual returns (uint256) {
        uint256 tokensHoldings = 0;
        for (uint256 i = 0; i < 3; i++) {
            tokensHoldings += tokens[i].balanceOf(address(this)) * decimalsMultipliers[i];
        }
        return tokensHoldings;
    }

    function renounceOwnership() public view override onlyOwner {
        revert('The strategy must have an owner');
    }

    function setZunami(address zunamiAddr) external onlyOwner {
        zunami = IZunami(zunamiAddr);
    }

    function withdrawStuckToken(IERC20Metadata _token) external onlyOwner {
        uint256 tokenBalance = _token.balanceOf(address(this));
        if (tokenBalance > 0) {
            _token.safeTransfer(_msgSender(), tokenBalance);
        }
    }

    function claimManagementFees() external returns (uint256) {
        return 0;
    }
}
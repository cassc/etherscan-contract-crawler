//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/ILiquidityGaugeStrat.sol";
import "../../interfaces/IAngleMerkleDistributor.sol";

interface IAngleVault {
    function liquidityGauge() external returns(address);
}

contract AngleMerklClaimer {
    using SafeERC20 for ERC20;

    error NOT_ALLOWED();
    error FEE_TOO_HIGH();

    address public governance;
    IAngleMerkleDistributor public merkleDistributor = IAngleMerkleDistributor(
        0x3Ef3D8bA38EBe18DB133cEc108f4D14CE00Dd9Ae
    ); 

    // FEE
    uint256 public constant BASE_FEE = 10_000;
    address public daoRecipient;
    uint256 public daoFee = 200; // 2%
    address public accRecipient;
    uint256 public accFee = 800; // 8%
    address public veSdtFeeRecipient;
    uint256 public veSdtFeeFee = 500; // 5%
    uint256 public claimerFee = 50; // 0.5%

    event Earn(uint256 _gaugeAmount, uint256 _daoPart, uint256 _accPart, uint256 _veSdtFeePart, uint256 _claimerPart);
    event DaoRecipientSet(address _oldR, address _newR);
    event AccRecipientSet(address _oldR, address _newR);
    event VeSdtFeeRecipientSet(address _oldR, address _newR);
    event DaoFeeSet(uint256 _oldF, uint256 _newF);
    event AccFeeSet(uint256 _oldF, uint256 _newF);
    event VeSdtFeeFeeSet(uint256 _oldF, uint256 _newF);
    event ClaimerFeeSet(uint256 _oldF, uint256 _newF);

    constructor(
        address _governance, 
        address _daoRecipient, 
        address _accRecipient, 
        address _veSdtFeeRecipient
    ) {
        governance = _governance;
        daoRecipient = _daoRecipient;
        accRecipient = _accRecipient;
        veSdtFeeRecipient = _veSdtFeeRecipient;
    }

    /// @notice function to claim and notify the ANGLE reward via merkle
    /// @param _proofs merkle proofs
    /// @param _vault vault to claim the reward for 
    /// @param _token reward token
    /// @param _amount amount to notify
    function claimAndNotify(
        bytes32[][] calldata _proofs,
        address _vault,
        address _token,
        uint256 _amount
    ) external {
        address[] memory users = new address[](1);
        users[0] = _vault;
        address[] memory tokens = new address[](1);
        tokens[0] = _token;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;
        // the reward will be send to the vault
        uint256 balanceBefore = ERC20(_token).balanceOf(_vault);
        merkleDistributor.claim(users, tokens, amounts, _proofs);
        uint256 reward = ERC20(_token).balanceOf(_vault) - balanceBefore;
        if (reward > 0) {
            // transfer reward from vault to here
            ERC20(_token).transferFrom(_vault, address(this), reward);
            uint256 rewardToNotify = _chargeFees(_token, reward);
            address liquidityGauge = IAngleVault(_vault).liquidityGauge();
            ERC20(_token).approve(liquidityGauge, rewardToNotify);
            ILiquidityGaugeStrat(liquidityGauge).deposit_reward_token(_token, rewardToNotify);
        }
    }

    /// @notice internal function to calculate fees and sent them to recipients 
    /// @param _token token to charge fees 
    /// @param _amount total amount to charge fees 
    function _chargeFees(address _token, uint256 _amount) internal returns (uint256 amountToNotify) {
        uint256 daoPart;
        uint256 accPart;
        uint256 veSdtFeePart;
        uint256 claimerPart;
        if (daoFee > 0) {
            daoPart = (_amount * daoFee) / BASE_FEE;
            ERC20(_token).safeTransfer(daoRecipient, daoPart);
        }
        if (accFee > 0) {
            accPart = (_amount * accFee) / BASE_FEE;
            ERC20(_token).safeTransfer(accRecipient, accPart);
        }
        if (veSdtFeeFee > 0) {
            veSdtFeePart = (_amount * veSdtFeeFee) / BASE_FEE;
            ERC20(_token).safeTransfer(veSdtFeeRecipient, veSdtFeePart);
        } 
        if (claimerFee > 0) {
            claimerPart = (_amount * claimerFee) / BASE_FEE;
            ERC20(_token).safeTransfer(msg.sender, claimerPart);
        }
        amountToNotify = _amount - daoPart - accPart - veSdtFeePart - claimerPart;
        emit Earn(amountToNotify, daoPart, accPart, veSdtFeePart, claimerPart);
    }

    /// @notice function to set the dao fee recipient
    /// @param _daoRecipient recipient address
    function setDaoRecipient(address _daoRecipient) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        emit DaoRecipientSet(daoRecipient, _daoRecipient);
        daoRecipient = _daoRecipient;
    }

    /// @notice function to set the accumulator fee recipient
    /// @param _accRecipient recipient address
    function setAccRecipient(address _accRecipient) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        emit AccRecipientSet(accRecipient, _accRecipient);
        accRecipient = _accRecipient;
    }

    /// @notice function to set the veSdtFee fee recipient
    /// @param _veSdtFeeRecipient recipient address
    function setVeSdtFeeRecipient(address _veSdtFeeRecipient) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        emit VeSdtFeeRecipientSet(veSdtFeeRecipient, _veSdtFeeRecipient);
        veSdtFeeRecipient = _veSdtFeeRecipient;
    }

    /// @notice function to set the fees reserved for the dao
    /// @param _daoFee fee amount (10000 = 100%)
    function setDaoFee(uint256 _daoFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_daoFee > BASE_FEE) revert FEE_TOO_HIGH();
        if (_daoFee + accFee + veSdtFeeFee + claimerFee > BASE_FEE) revert FEE_TOO_HIGH();
        emit DaoFeeSet(daoFee, _daoFee);
        daoFee = _daoFee;
    }

    /// @notice function to set the fees reserved for the accumulator
    /// @param _accFee fee amount (10000 = 100%)
    function setAccFee(uint256 _accFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_accFee > BASE_FEE) revert FEE_TOO_HIGH();
        if (_accFee + veSdtFeeFee + daoFee + claimerFee > BASE_FEE) revert FEE_TOO_HIGH();
        emit AccFeeSet(accFee, _accFee);
        accFee = _accFee;
    }

    /// @notice function to set the fees reserved for the veSdtFee
    /// @param _veSdtFeeFee fee amount (10000 = 100%)
    function setVeSdtFeeFee(uint256 _veSdtFeeFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_veSdtFeeFee > BASE_FEE) revert FEE_TOO_HIGH();
        if (_veSdtFeeFee + accFee + daoFee + claimerFee > BASE_FEE) revert FEE_TOO_HIGH();
        emit VeSdtFeeFeeSet(veSdtFeeFee, _veSdtFeeFee);
        veSdtFeeFee = _veSdtFeeFee;
    }

     /// @notice function to set the fees reserved for the claimer (msg.sender)
    /// @param _claimerFee fee amount (10000 = 100%)
    function setClaimerFee(uint256 _claimerFee) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        if (_claimerFee > BASE_FEE) revert FEE_TOO_HIGH();
        if (_claimerFee + accFee + daoFee + veSdtFeeFee > BASE_FEE) revert FEE_TOO_HIGH();
        emit ClaimerFeeSet(claimerFee, _claimerFee);
        claimerFee = _claimerFee;
    }

    /// @notice function to set the governance
    /// @param _governance governance address
    function setGovernance(address _governance) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        governance = _governance;
    }

    /// @notice function to set a new merkle distributor
    /// @param _merkleDistributor distributor address 
    function setMerkleDistributor(address _merkleDistributor) external {
        if (msg.sender != governance) revert NOT_ALLOWED();
        merkleDistributor = IAngleMerkleDistributor(_merkleDistributor);
    }
}
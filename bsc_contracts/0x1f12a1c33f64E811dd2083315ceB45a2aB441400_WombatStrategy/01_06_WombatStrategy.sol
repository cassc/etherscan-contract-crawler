// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./IStrategy.sol";
import "../protocols/BnbX/IStakeManager.sol";
import "../protocols/Wombat/IWombatPool.sol";
import "../protocols/Wombat/IWombatMaster.sol";

contract WombatStrategy is IStrategy {
    IERC20Upgradeable public bnbX;
    IStakeManager public stakeManager;
    IWombatPool public wombatPool;
    IWombatMaster public wombatMaster;

    // Accounting
    uint256 public totalDepositsInBnb;
    uint256 public totalDepositsInBnbX;
    uint256 public totalWombatLP;
    uint256 public totalRewardsInBnbX;
    mapping(address => uint256) public userDepositsInBnb;
    mapping(address => uint256) public userBalances;

    constructor(
        address _bnbX,
        address _stakeManager,
        address _wombatPool,
        address _wombatMaster
    ) {
        bnbX = IERC20Upgradeable(_bnbX);
        stakeManager = IStakeManager(_stakeManager);
        wombatPool = IWombatPool(_wombatPool);
        wombatMaster = IWombatMaster(_wombatMaster);
    }

    // 1. Deposit BNB
    // 2. Convert BNB -> BNBX through Stader StakeManager
    // 3. Deposit BNBX to Wombat Pool. Receive Wombat LP token
    // 4. Deposit and stake Wombat LP token to Wombat Master
    function deposit() external payable override {
        require(msg.value > 0, "Zero BNB");

        uint256 depositInBnb = msg.value;
        uint256 bnbxAmountBefore = bnbX.balanceOf(address(this));
        stakeManager.deposit{value: depositInBnb}();
        uint256 bnbxAmountAfter = bnbX.balanceOf(address(this)) -
            bnbxAmountBefore;

        // Deposit bnbX to Wombat Liquidity Pool and get Wombat Liquidity Pool token back
        require(bnbxAmountAfter > bnbxAmountBefore, "No new bnbx minted");
        uint256 bnbxAmount = bnbxAmountAfter - bnbxAmountBefore;
        bnbX.approve(address(wombatPool), bnbxAmount);
        uint256 wombatLPAmount = wombatPool.deposit(
            address(bnbX),
            bnbxAmount,
            0,
            address(this),
            block.timestamp,
            false // Is is an experimental feature therefore we do it ourselves below.
        );

        // Deposit and stake Wombat Liquidity Pool token on Wombat Master
        uint256 pid = wombatMaster.getAssetPid(address(bnbX));
        wombatMaster.deposit(pid, wombatLPAmount);

        totalDepositsInBnb += depositInBnb;
        totalDepositsInBnbX += bnbxAmount;
        totalWombatLP += wombatLPAmount;
        userDepositsInBnb[msg.sender] += depositInBnb;
        userBalances[msg.sender] += convertBnbToVault(depositInBnb);
    }

    // 1. Convert Vault balance to BnbX
    // 2. Convert BnbX to Bnb
    function withdraw(uint256 _amount) external override returns (uint256) {
        uint256 amountInBnbX = _withdrawInBnbX(_amount);

        return amountInBnbX;
    }

    // 1. Withdraw Vault in BnbX
    // 2. Send BnbX to user
    function withdrawInBnbX(uint256 _amount) external returns (uint256) {
        uint256 amountInBnbX = _withdrawInBnbX(_amount);
        bnbX.transfer(msg.sender, amountInBnbX);

        return amountInBnbX;
    }

    // 1. Convert Vault balance to Wombat LP token amount
    // 2. Withdraw Wombat LP token from Wombat Master
    // 3. Withdraw BNBX from Wombat Pool via sending the Wombat LP token
    function _withdrawInBnbX(uint256 _amount) private returns (uint256) {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");

        userBalances[msg.sender] -= _amount;
        uint256 pid = wombatMaster.getAssetPid(address(bnbX));
        wombatMaster.withdraw(pid, _amount);
        uint256 amountInBnbXBefore = bnbX.balanceOf(address(this));
        uint256 bnbxAmount = wombatPool.withdraw(
            address(bnbX),
            _amount,
            0,
            address(this),
            block.timestamp
        );
        require(
            amountInBnbXBefore - bnbxAmount == bnbX.balanceOf(address(this)),
            "Invalid bnbx amount"
        );

        return bnbxAmount;
    }

    function harvest() external override returns (uint256) {
        // Deposit and stake Wombat Liquidity Pool token on Wombat Master
        uint256 pid = wombatMaster.getAssetPid(address(bnbX));
        (uint256 pending, uint256[] memory rewards) = wombatMaster.deposit(
            pid,
            0
        );
        return pending;
    }

    function convertBnbToVault(uint256 _amount) public view returns (uint256) {
        uint256 amountInBnbX = stakeManager.convertBnbToBnbX(_amount);
        return
            (amountInBnbX * totalDepositsInBnbX) /
            (totalDepositsInBnbX + totalRewardsInBnbX);
    }

    function convertVaultToBnbX(uint256 _amount) public view returns (uint256) {
        return
            (_amount * (totalDepositsInBnbX + totalRewardsInBnbX)) /
            totalDepositsInBnbX;
    }
}
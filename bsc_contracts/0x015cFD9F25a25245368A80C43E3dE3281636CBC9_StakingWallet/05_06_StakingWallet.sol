//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStakingWallet.sol";
import 'hardhat/console.sol';

contract StakingWallet is Ownable {
    address public stakingContract;
    uint256 public totalStakedBalance;
    uint256 public minAmountReflection = 1 * 10**9;

    IStakingWallet public reflectionsDistributor;
    IERC20 public immutable stakeToken;

    event LogDeposit(address user, uint256 amount);
    event LogWithdrawal(address user, uint256 amount);
    event LogSetStakingContract(address stakingContract);
    event LogSetMinAmountReflection(uint256 minAmountReflection);
    event LogSetReflectionsDistributor(address reflectionsDistributor);

    constructor(
        IERC20 _stakeToken,
        address _stakingContract
    ) {
        stakeToken = _stakeToken;
        stakingContract = _stakingContract;
    }

    /**
     * @dev Throws if called by any account other than the owner or deployer.
     */
    modifier onlyStakingContract() {
        require(
            _msgSender() == stakingContract,
            "StakingTresuary: caller is not the stakingContract"
        );
        _;
    }

    function transferReflections() internal {
        uint256 reflections = stakeToken.balanceOf(address(this)) -
            totalStakedBalance;

        /**
         * @notice Transfers accumulated reflections to the reflectionsDistributor
         * if the amount is reached
         */
        if (reflections >= minAmountReflection) {
            require(
                stakeToken.transfer(
                    address(reflectionsDistributor),
                    reflections
                ),
                "Transfer fail"
            );
        }
    }

    function deposit(address staker, uint256 amount) external onlyStakingContract {
        transferReflections();
        require(
            stakeToken.transferFrom(stakingContract, address(this), amount),
            "TransferFrom fail"
        );
        totalStakedBalance += amount;
        reflectionsDistributor.deposit(staker, amount);

        emit LogDeposit(staker, amount);
    }

    function withdraw(address staker, uint256 amount)
        external
        onlyStakingContract
    {
        transferReflections();

        require(stakeToken.transfer(staker, amount), "Transfer fail");
        totalStakedBalance -= amount;

        reflectionsDistributor.withdraw(staker, amount);
        emit LogWithdrawal(staker, amount);
    }

    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
        emit LogSetStakingContract(stakingContract);
    }

    function setMinAmountReflection(uint256 _minAmountReflection)
        external
        onlyOwner
    {
        minAmountReflection = _minAmountReflection;
        emit LogSetMinAmountReflection(minAmountReflection);
    }

    function setReflectionsDistributor(
        IStakingWallet _reflectionsDistributor
    ) external onlyOwner {
        reflectionsDistributor = _reflectionsDistributor;
        emit LogSetReflectionsDistributor(address(reflectionsDistributor));
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract Kranz is ERC20, Ownable {
    using SafeMath for uint256;

    // Default percent to charge on each transfer (Note: 1e18 == 100%)
    uint256 private _transactionFeePercent;
    // Default percent to charge when selling tokens (Note: 1e18 == 100%)
    uint256 private _transactionFeePercentDex;

    // DEX (Uniswap or PancakeSwap) address to use when check if is a seller transfer (i.e. V2 Pair / V3 Pool address)
    // mitigated - Contract only permits a single DEX address
    mapping(address => bool) dexAddresses;

    // Timelcok feature
    enum Functions {
        FEE,
        FEE_DEX,
        FEE_DIST
    }
    uint256 private constant _TIMELOCK = 1 days;
    mapping(Functions => uint256) public currentTimelocks;
    mapping(Functions => bool) public hasPendingFee;

    // Fee Beneficiaries
    address public _rewardWallet;
    address public _developerWallet;
    address public _liquidityWallet;

    // Percent distribution among wallets and burn
    // Note: The sum of these four values should be 100% (1e18)
    uint256 public _burnPercent;
    uint256 public _rewardWalletFeePercent;
    uint256 public _developerWalletFeePercent;
    uint256 public _liquidityWalletFeePercent;

    // Proposal Variables
    uint256 private _pendingTransactionFeePercent;
    uint256 private _pendingTransactionFeePercentDex;

    uint256 private _pendingBurnPercent;
    uint256 private _pendingRewardWalletFeePercent;
    uint256 private _pendingDeveloperWalletFeePercent;
    uint256 private _pendingLiquidityWalletFeePercent;
    uint256 private _feeUpdateTimestamp;

    constructor(
        uint256 initialSupply,
        address tokensBeneficiary,
        address rewardWallet,
        address developerWallet,
        address liquidityWallet
    ) ERC20("Kranz Token", "KRZ") {
        _mint(tokensBeneficiary, initialSupply);

        _transactionFeePercent = 1e16; // 1%
        _transactionFeePercentDex = 3e16; // 3%

        _rewardWallet = rewardWallet;
        _developerWallet = developerWallet;
        _liquidityWallet = liquidityWallet;

        _burnPercent = 5e17; // 50%
        _rewardWalletFeePercent = 1e17; // 10%
        _developerWalletFeePercent = 3e17; // 30%
        _liquidityWalletFeePercent = 1e17; // 10%

        // initialize timelock conditions
        currentTimelocks[Functions.FEE] = 0;
        currentTimelocks[Functions.FEE_DEX] = 0;
        currentTimelocks[Functions.FEE_DIST] = 0;

        hasPendingFee[Functions.FEE] = false;
        hasPendingFee[Functions.FEE_DEX] = false;
        hasPendingFee[Functions.FEE_DIST] = false;
    }

    // TODO: Mitigate Contract owner from front-run transfers with fee changes
    // Consider modifing fees with a time lock approach. An initial transaction could specify the new fees,
    // and a subsequent transaction (which must be more than a fixed number of blocks later) can then update the fees.

    // Transfer functions with fee charging
    //

    function transfer(address recipient, uint256 amount)
        public
        override
        updateFees()
        returns (bool)
    {
        _transferWithFee(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override updateFees() returns (bool) {
        _transferWithFee(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function _transferWithFee(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 feeToCharge;

        if (dexAddresses[recipient]) {
            feeToCharge = amount.mul(_transactionFeePercentDex).div(1e18);
        } else {
            feeToCharge = amount.mul(_transactionFeePercent).div(1e18);
        }

        uint256 amountAfterFee = amount.sub(feeToCharge);

        (
            uint256 toReward,
            uint256 toDeveloper,
            uint256 toLiquidity,
            uint256 toBurn
        ) = calculateFeeDistribution(feeToCharge);

        _transfer(sender, 0x000000000000000000000000000000000000dEaD, toBurn);
        _transfer(sender, _rewardWallet, toReward);
        _transfer(sender, _developerWallet, toDeveloper);
        _transfer(sender, _liquidityWallet, toLiquidity);
        _transfer(sender, recipient, amountAfterFee);
    }

    // Note: run this code before transfers (from modifier or function's body)
    modifier updateFees() {
        setTransactionFee();
        setTransactionFeeDex();
        setFeeDistribution();
        _;
    }

    // Getters for Current Transaction fees / distributions

    function getCurrentTransactionFee() public view returns (uint256) {
        return _transactionFeePercent;
    }

    function getCurrentTransactionFeeDex() public view returns (uint256) {
        return _transactionFeePercentDex;
    }

    function getCurrentFeeDistribution()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _burnPercent,
            _rewardWalletFeePercent,
            _developerWalletFeePercent,
            _liquidityWalletFeePercent
        );
    }

    // Getters for Pending Transaction fees / distributions

    function getPendingTransactionFee() public view returns (uint256) {
        return _pendingTransactionFeePercent;
    }

    function getPendingTransactionFeeDex() public view returns (uint256) {
        return _pendingTransactionFeePercentDex;
    }

    function getPendingFeeDistribution()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _pendingBurnPercent,
            _pendingRewardWalletFeePercent,
            _pendingDeveloperWalletFeePercent,
            _pendingLiquidityWalletFeePercent
        );
    }

    // Getters for Pending Transaction fees / distributions

    function getPendingTransactionFeeTime() public view returns (uint256) {
        return currentTimelocks[Functions.FEE];
    }

    function getPendingTransactionFeeDexTime() public view returns (uint256) {
        return currentTimelocks[Functions.FEE_DEX];
    }

    function getPendingFeeDistributionTime() public view returns (uint256) {
        return currentTimelocks[Functions.FEE_DIST];
    }

    // Calculate Fee distributions

    function calculateFeeDistribution(uint256 amount)
        private
        view
        returns (
            uint256 toReward,
            uint256 toDeveloper,
            uint256 toLiquidity,
            uint256 toBurn
        )
    {
        toReward = amount.mul(_rewardWalletFeePercent).div(1e18);
        toDeveloper = amount.mul(_developerWalletFeePercent).div(1e18);
        toLiquidity = amount.mul(_liquidityWalletFeePercent).div(1e18);

        // fixed (mitigated - transfer less than expected)
        toBurn = amount.sub(toReward).sub(toDeveloper).sub(toLiquidity);
    }

    //
    // Administration setter functions
    //

    function proposeTransactionFee(uint256 fee) public onlyOwner {
        require(
            fee >= 0 && fee <= 5e16,
            "Kranz: transaction fee should be >= 0 and <= 5%"
        );
        require(
            !hasPendingFee[Functions.FEE],
            "Kranz: There is a pending fee change already."
        );
        require(
            currentTimelocks[Functions.FEE] == 0,
            "Current Timelock is already initialized with a value"
        );

        _pendingTransactionFeePercent = fee;

        // intialize timelock conditions
        currentTimelocks[Functions.FEE] = block.timestamp + _TIMELOCK; // resets timelock with future timestamp that it will be unlocked
        hasPendingFee[Functions.FEE] = true;
    }

    function proposeTransactionFeeDex(uint256 fee) public onlyOwner {
        require(
            fee >= 0 && fee <= 5e16,
            "Krans: sell transaction fee should be >= 0 and <= 5%"
        );
        require(
            !hasPendingFee[Functions.FEE_DEX],
            "Kranz: There is a pending dex fee change already."
        );
        require(
            currentTimelocks[Functions.FEE_DEX] == 0,
            "Current Timelock is already initialized with a value"
        );

        _pendingTransactionFeePercentDex = fee;

        // intialize timelock conditions
        currentTimelocks[Functions.FEE_DEX] = block.timestamp + _TIMELOCK; // resets timelock with future timestamp that it will be unlocked
        hasPendingFee[Functions.FEE_DEX] = true;
    }

    function proposeFeeDistribution(
        uint256 burnPercent,
        uint256 rewardWalletFeePercent,
        uint256 developerWalletFeePercent,
        uint256 liquidityWalletFeePercent
    ) public onlyOwner {
        require(
            burnPercent
            .add(rewardWalletFeePercent)
            .add(developerWalletFeePercent)
            .add(liquidityWalletFeePercent) == 1e18,
            "Kranz: The sum of distribuition should be 100%"
        );
        require(
            !hasPendingFee[Functions.FEE_DIST],
            "Kranz: There is a pending dsitribution fee change already."
        );
        require(
            currentTimelocks[Functions.FEE_DIST] == 0,
            "Current Timelock is already initialized with a value"
        );

        _pendingBurnPercent = burnPercent;
        _pendingRewardWalletFeePercent = rewardWalletFeePercent;
        _pendingDeveloperWalletFeePercent = developerWalletFeePercent;
        _pendingLiquidityWalletFeePercent = liquidityWalletFeePercent;

        // intialize timelock conditions
        currentTimelocks[Functions.FEE_DIST] = block.timestamp + _TIMELOCK;
        hasPendingFee[Functions.FEE_DIST] = true;
    }

    function setTransactionFee() private {
        if (
            hasPendingFee[Functions.FEE] == true &&
            currentTimelocks[Functions.FEE] <= block.timestamp
        ) {
            _transactionFeePercent = _pendingTransactionFeePercent;

            // reset timelock conditions
            currentTimelocks[Functions.FEE] = 0;
            hasPendingFee[Functions.FEE] = false;
        }
    }

    function setTransactionFeeDex() private {
        if (
            hasPendingFee[Functions.FEE_DEX] == true &&
            currentTimelocks[Functions.FEE_DEX] <= block.timestamp
        ) {
            _transactionFeePercentDex = _pendingTransactionFeePercentDex;

            // reset timelock conditions
            currentTimelocks[Functions.FEE_DEX] = 0;
            hasPendingFee[Functions.FEE_DEX] = false;
        }
    }

    function setFeeDistribution() private {
        if (
            hasPendingFee[Functions.FEE_DIST] == true &&
            currentTimelocks[Functions.FEE_DIST] <= block.timestamp
        ) {
            _burnPercent = _pendingBurnPercent;
            _rewardWalletFeePercent = _pendingRewardWalletFeePercent;
            _developerWalletFeePercent = _pendingDeveloperWalletFeePercent;
            _liquidityWalletFeePercent = _pendingLiquidityWalletFeePercent;

            // reset timelock conditions
            currentTimelocks[Functions.FEE_DIST] = 0;
            hasPendingFee[Functions.FEE_DIST] = false;
        }
    }

    function setDeveloperWalletAddress(address devAddress) public onlyOwner {
        require(
            devAddress != address(0),
            "Kranz: devAddress cannot be zero address"
        );
        _developerWallet = devAddress;
    }

    function setRewardWalletAddress(address rewardAddress) public onlyOwner {
        require(
            rewardAddress != address(0),
            "Kranz: rewardAddress cannot be zero address"
        );
        _rewardWallet = rewardAddress;
    }

    function setLiquidityWalletAddress(address liquidityAddress)
        public
        onlyOwner
    {
        require(
            liquidityAddress != address(0),
            "Kranz: liquidityAddress cannot be zero address"
        );
        _liquidityWallet = liquidityAddress;
    }

    function addDexAddress(address dexAddress) public onlyOwner {
        dexAddresses[dexAddress] = true;
    }

    function removeDexAddress(address dexAddress) public onlyOwner {
        require(
            dexAddresses[dexAddress] == true,
            "The DEX address you're trying to remove does not exist or already has been removed"
        );
        dexAddresses[dexAddress] = false;
    }
}
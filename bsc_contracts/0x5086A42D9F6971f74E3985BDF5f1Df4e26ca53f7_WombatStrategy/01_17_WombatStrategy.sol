// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./IStrategy.sol";
import "../protocols/BnbX/IStakeManager.sol";
import "../protocols/Wombat/IWombatPool.sol";
import "../protocols/Wombat/IWombatMaster.sol";
import "../protocols/Wombat/IWombatRouter.sol";

contract WombatStrategy is
    IStrategy,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    // WBNB (mainnet): 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    // WBNB (testnet): 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
    IERC20Upgradeable public wbnb;
    IERC20Upgradeable public bnbX;
    IStakeManager public stakeManager;
    IWombatPool public wombatPool;
    IWombatMaster public wombatMaster;
    IWombatRouter public wombatRouter;
    address public strategist;
    address public rewards;

    // Accounting
    uint256 public totalShares;
    uint256 public totalInWombatLP;
    mapping(address => uint256) public userDepositsInBnb;
    mapping(address => uint256) public userBalances;

    function initialize(
        address _wbnb,
        address _bnbX,
        address _stakeManager,
        address _wombatPool,
        address _wombatMaster,
        address _wombatRouter,
        address _strategist,
        address _rewards
    ) external initializer {
        __AccessControl_init();
        __Pausable_init();

        require(
            (_wbnb != address(0) &&
                _bnbX != address(0) &&
                _stakeManager != address(0) &&
                _wombatPool != address(0) &&
                _wombatMaster != address(0) &&
                _wombatRouter != address(0) &&
                _strategist != address(0) &&
                _rewards != address(0)),
            "zero address provided"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _strategist);

        wbnb = IERC20Upgradeable(_wbnb);
        bnbX = IERC20Upgradeable(_bnbX);
        stakeManager = IStakeManager(_stakeManager);
        wombatPool = IWombatPool(_wombatPool);
        wombatMaster = IWombatMaster(_wombatMaster);
        wombatRouter = IWombatRouter(_wombatRouter);
        rewards = _rewards;
    }

    // 1. Deposit BNB
    // 2. Convert BNB -> BNBX through Stader StakeManager
    // 3. Deposit BNBX to Wombat Pool. Receive Wombat LP token
    // 4. Deposit and stake Wombat LP token to Wombat Master
    function deposit() external payable override whenNotPaused {
        require(msg.value > 0, "Zero BNB");

        uint256 depositInBnb = msg.value;
        uint256 bnbxAmountBefore = bnbX.balanceOf(address(this));
        stakeManager.deposit{value: depositInBnb}();
        uint256 bnbxAmountAfter = bnbX.balanceOf(address(this)) -
            bnbxAmountBefore;

        // Deposit bnbX to Wombat Liquidity Pool and get Wombat Liquidity Pool token back
        require(bnbxAmountAfter > bnbxAmountBefore, "No new bnbx minted");
        uint256 bnbxAmount = bnbxAmountAfter - bnbxAmountBefore;
        uint256 wombatLPAmount = _depositWombat(bnbxAmount);

        uint256 depositInVault = convertBnbToVault(depositInBnb);
        totalInWombatLP += wombatLPAmount;
        userDepositsInBnb[msg.sender] += depositInBnb;
        totalShares += depositInVault;
        userBalances[msg.sender] += depositInVault;

        emit Deposit(msg.sender, depositInBnb);
    }

    function _depositWombat(uint256 _amount) private returns (uint256) {
        bnbX.approve(address(wombatPool), _amount);
        uint256 wombatLPAmount = wombatPool.deposit(
            address(bnbX),
            _amount,
            0,
            address(this),
            block.timestamp,
            false // Is is an experimental feature therefore we do it ourselves below.
        );

        IERC20Upgradeable(wombatPool.addressOfAsset(address(bnbX))).approve(
            address(wombatMaster),
            wombatLPAmount
        );
        // Deposit and stake Wombat Liquidity Pool token on Wombat Master
        uint256 pid = wombatMaster.getAssetPid(
            wombatPool.addressOfAsset(address(bnbX))
        );
        wombatMaster.deposit(pid, wombatLPAmount);

        return wombatLPAmount;
    }

    // 1. Convert Vault balance to BnbX
    // 2. Convert BnbX to Bnb
    function withdraw(uint256 _amount)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        uint256 amountInBnbX = _withdrawInBnbX(_amount);

        // Swap through Wombat Router
        bnbX.approve(address(wombatRouter), amountInBnbX);
        address[] memory tokenPath = new address[](2);
        tokenPath[0] = address(bnbX);
        tokenPath[1] = address(wbnb);
        address[] memory poolPath = new address[](1);
        poolPath[0] = address(wombatPool);
        uint256 amountInBnb = wombatRouter.swapExactTokensForNative(
            tokenPath,
            poolPath,
            amountInBnbX,
            0,
            msg.sender,
            block.timestamp
        );

        emit Withdraw(msg.sender, amountInBnb);
        return amountInBnb;
    }

    // 1. Withdraw Vault in BnbX
    // 2. Send BnbX to user
    function withdrawInBnbX(uint256 _amount)
        external
        whenNotPaused
        returns (uint256)
    {
        uint256 amountInBnbX = _withdrawInBnbX(_amount);
        bnbX.transfer(msg.sender, amountInBnbX);

        return amountInBnbX;
    }

    // 1. Convert Vault balance to Wombat LP token amount
    // 2. Withdraw Wombat LP token from Wombat Master
    // 3. Withdraw BNBX from Wombat Pool via sending the Wombat LP token
    function _withdrawInBnbX(uint256 _amount) private returns (uint256) {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");

        totalShares -= _amount;
        userBalances[msg.sender] -= _amount;
        uint256 pid = wombatMaster.getAssetPid(
            wombatPool.addressOfAsset(address(bnbX))
        );
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

    function harvest() external override whenNotPaused returns (uint256) {
        // Deposit and stake Wombat Liquidity Pool token on Wombat Master
        uint256 pid = wombatMaster.getAssetPid(address(bnbX));
        wombatMaster.depositFor(pid, 0, rewards);

        emit Harvest();
        return 0;
    }

    function depositRewards(uint256 _amount) external whenNotPaused {
        bnbX.transferFrom(msg.sender, address(this), _amount);
        uint256 amountInWombatLP = _depositWombat(_amount);
        totalInWombatLP += amountInWombatLP;

        emit DepositRewards(msg.sender, _amount);
    }

    function setRewards(address _rewards)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_rewards != address(0), "zero address provided");

        rewards = _rewards;
        emit SetRewards(_rewards);
    }

    function togglePause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused() ? _unpause() : _pause();
    }

    function convertBnbToVault(uint256 _amount) public view returns (uint256) {
        uint256 amountInBnbX = stakeManager.convertBnbToBnbX(_amount);
        uint256 amountInWombatLP = _convertBnbXToVault(amountInBnbX);

        uint256 _totalShares = totalShares == 0 ? 1 : totalShares;
        uint256 _totalInWombatLP = totalInWombatLP == 0 ? 1 : totalInWombatLP;
        return (amountInWombatLP * _totalShares) / _totalInWombatLP;
    }

    function _convertBnbXToVault(uint256 _amount)
        private
        view
        returns (uint256)
    {
        (uint256 _amountInWombatLP, uint256 _reward) = wombatPool
            .quotePotentialDeposit(address(bnbX), _amount);
        return _amountInWombatLP;
    }

    function convertVaultToBnbX(uint256 _amount) public view returns (uint256) {
        uint256 _totalShares = totalShares == 0 ? 1 : totalShares;
        uint256 _totalInWombatLP = totalInWombatLP == 0 ? 1 : totalInWombatLP;

        uint256 amountInWombatLP = (_amount * _totalInWombatLP) / _totalShares;
        return _convertVaultToBnbX(amountInWombatLP);
    }

    function _convertVaultToBnbX(uint256 _amount)
        private
        view
        returns (uint256)
    {
        (uint256 _amountInBnbX, uint256 _fee) = wombatPool
            .quotePotentialDeposit(address(bnbX), _amount);

        return _amountInBnbX;
    }

    function getContracts()
        external
        view
        returns (
            address _wbnb,
            address _bnbX,
            address _wombatPool,
            address _wombatMaster,
            address _wombatRouter
        )
    {
        _wbnb = address(wbnb);
        _bnbX = address(bnbX);
        _wombatPool = address(wombatPool);
        _wombatMaster = address(wombatMaster);
        _wombatRouter = address(wombatRouter);
    }
}
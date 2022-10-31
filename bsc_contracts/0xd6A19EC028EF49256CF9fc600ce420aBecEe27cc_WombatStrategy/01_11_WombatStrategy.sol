// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./IStrategy.sol";
import "../protocols/BnbX/IStakeManager.sol";
import "../protocols/Wombat/IWombatPool.sol";
import "../protocols/Wombat/IWombatMaster.sol";
import "../protocols/Wombat/IWombatRouter.sol";

contract WombatStrategy is IStrategy, Initializable, PausableUpgradeable {
    event SetWombatRouter(address indexed _address);
    event SetWombatMaster(address indexed _address);
    event SetWombatPool(address indexed _address);
    event SetBnbX(address indexed _address);
    event SetWbnb(address indexed _address);
    event SetStakeManager(address indexed _address);
    event SetManager(address indexed _address);
    event ProposeManager(address indexed _address);
    event SetPriceSlippageBps(uint256 _amount);

    // WBNB (mainnet): 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    // WBNB (testnet): 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
    IERC20Upgradeable public wbnb;
    IERC20Upgradeable public bnbX;
    IStakeManager public stakeManager;
    IWombatPool public wombatPool;
    IWombatMaster public wombatMaster;
    IWombatRouter public wombatRouter;
    address public manager;
    address public rewards;
    address public proposedManager;
    uint256 public priceSlippageBps;

    // Accounting
    uint256 public totalShares;
    uint256 public totalInLP;
    mapping(address => uint256) public userShares;

    function initialize(
        address _wbnb,
        address _bnbX,
        address _stakeManager,
        address _wombatPool,
        address _wombatMaster,
        address _wombatRouter,
        address _rewards,
        uint256 _priceSlippageBps
    ) external initializer {
        __Pausable_init();

        manager = msg.sender;
        setWbnb(_wbnb);
        setBnbX(_bnbX);
        setStakeManager(_stakeManager);
        setWombatPool(_wombatPool);
        setWombatMaster(_wombatMaster);
        setWombatRouter(_wombatRouter);
        setRewards(_rewards);
        setPriceSlippageBps(_priceSlippageBps);
    }

    // 1. Deposit BNB
    // 2. Convert BNB -> BNBX through Stader StakeManager
    // 3. Deposit BNBX to Wombat Pool. Receive Wombat LP token
    // 4. Deposit and stake Wombat LP token to Wombat Master
    function deposit() external payable override whenNotPaused {
        (
            uint256 amountInBnb,
            ,
            uint256 amountInLP,
            uint256 amountInShares
        ) = _stake();
        totalInLP += amountInLP;
        totalShares += amountInShares;
        userShares[msg.sender] += amountInShares;

        emit Deposit(msg.sender, amountInBnb);
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
        uint256 maxAmountOut = estimateBnbXToBnb(amountInBnbX);
        uint256 minAmountOut = maxAmountOut -
            (maxAmountOut * priceSlippageBps) /
            10000;
        uint256 amountInBnb = wombatRouter.swapExactTokensForNative(
            tokenPath,
            poolPath,
            amountInBnbX,
            minAmountOut,
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

    function harvest() external override whenNotPaused returns (uint256) {
        uint256 pid = wombatMaster.getAssetPid(address(bnbX));
        wombatMaster.deposit(pid, 0);

        emit Harvest();
        return 0;
    }

    function depositRewards() external payable onlyManager whenNotPaused {
        (uint256 amountInBnb, , uint256 amountInLP, ) = _stake();
        totalInLP += amountInLP;

        emit DepositRewards(msg.sender, amountInBnb, amountInLP);
    }

    function withdrawRewards(address _token)
        external
        onlyManager
        whenNotPaused
    {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(rewards, balance);

        emit WithdrawRewards(rewards, _token, balance);
    }

    function togglePause() external onlyManager {
        paused() ? _unpause() : _pause();
    }

    //
    // Setters
    //
    function proposeManager(address _manager) external onlyManager {
        require(manager != _manager, "Old address == new address");
        require(_manager != address(0), "zero address provided");

        proposedManager = _manager;

        emit ProposeManager(_manager);
    }

    function acceptManager() external {
        require(
            msg.sender == proposedManager,
            "Accessible only by Proposed Manager"
        );

        manager = proposedManager;
        proposedManager = address(0);

        emit SetManager(manager);
    }

    function setRewards(address _rewards) public onlyManager {
        require(_rewards != address(0), "zero address provided");

        rewards = _rewards;
        emit SetRewards(_rewards);
    }

    function setStakeManager(address _stakeManager) public onlyManager {
        require(_stakeManager != address(0), "zero address provided");

        stakeManager = IStakeManager(_stakeManager);
        emit SetStakeManager(_stakeManager);
    }

    function setWbnb(address _wbnb) public onlyManager {
        require(_wbnb != address(0), "zero address provided");

        wbnb = IERC20Upgradeable(_wbnb);
        emit SetWbnb(_wbnb);
    }

    function setBnbX(address _bnbX) public onlyManager {
        require(_bnbX != address(0), "zero address provided");

        bnbX = IERC20Upgradeable(_bnbX);
        emit SetBnbX(_bnbX);
    }

    function setWombatPool(address _wombatPool) public onlyManager {
        require(_wombatPool != address(0), "zero address provided");

        wombatPool = IWombatPool(_wombatPool);
        emit SetWombatPool(_wombatPool);
    }

    function setWombatMaster(address _wombatMaster) public onlyManager {
        require(_wombatMaster != address(0), "zero address provided");

        wombatMaster = IWombatMaster(_wombatMaster);
        emit SetWombatMaster(_wombatMaster);
    }

    function setWombatRouter(address _wombatRouter) public onlyManager {
        require(_wombatRouter != address(0), "zero address provided");

        wombatRouter = IWombatRouter(_wombatRouter);
        emit SetWombatRouter(_wombatRouter);
    }

    function setPriceSlippageBps(uint256 _priceSlippageBps) public onlyManager {
        require(
            _priceSlippageBps <= 10000,
            "_priceSlippageBps must not exceed 10000 (100%)"
        );

        priceSlippageBps = _priceSlippageBps;
        emit SetPriceSlippageBps(priceSlippageBps);
    }

    //
    // Views
    //
    function estimateBnbXToBnb(uint256 _amountInBnbX)
        public
        view
        returns (uint256)
    {
        address[] memory tokenPath = new address[](2);
        tokenPath[0] = address(bnbX);
        tokenPath[1] = address(wbnb);
        address[] memory poolPath = new address[](1);
        poolPath[0] = address(wombatPool);
        (uint256 amountInBnb, ) = wombatRouter.getAmountOut(
            tokenPath,
            poolPath,
            int256(_amountInBnbX)
        );

        return amountInBnb;
    }

    function convertBnbToShares(uint256 _amount) public view returns (uint256) {
        uint256 amountInBnbX = stakeManager.convertBnbToBnbX(_amount);
        uint256 amountInLP = _convertBnbXToLP(amountInBnbX);

        uint256 _totalShares = totalShares == 0 ? 1 : totalShares;
        uint256 _totalInLP = totalInLP == 0 ? 1 : totalInLP;
        return (amountInLP * _totalShares) / _totalInLP;
    }

    function convertSharesToBnbX(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 _totalShares = totalShares == 0 ? 1 : totalShares;
        uint256 _totalInLP = totalInLP == 0 ? 1 : totalInLP;

        uint256 amountInLP = (_amount * _totalInLP) / _totalShares;
        return _convertLPToBnbX(amountInLP);
    }

    function getContracts()
        external
        view
        returns (
            address _wbnb,
            address _bnbX,
            address _stakeManager,
            address _wombatPool,
            address _wombatMaster,
            address _wombatRouter
        )
    {
        _wbnb = address(wbnb);
        _bnbX = address(bnbX);
        _stakeManager = address(stakeManager);
        _wombatPool = address(wombatPool);
        _wombatMaster = address(wombatMaster);
        _wombatRouter = address(wombatRouter);
    }

    function _stake()
        private
        returns (
            uint256 amountInBnb,
            uint256 amountInBnbX,
            uint256 amountInLP,
            uint256 amountInShares
        )
    {
        amountInBnb = msg.value;
        amountInBnbX = _depositBnbX();
        amountInLP = _depositWombat(amountInBnbX);
        amountInShares = convertBnbToShares(amountInBnb);
    }

    // Deposit bnbX to Wombat Liquidity Pool and receive Wombat Liquidity Pool token
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

    // Deposit bnb to StakeManager and receive bnbX token
    function _depositBnbX() private returns (uint256) {
        require(msg.value > 0, "Zero BNB");

        uint256 bnbxAmountBefore = bnbX.balanceOf(address(this));
        stakeManager.deposit{value: msg.value}();
        uint256 bnbxAmountAfter = bnbX.balanceOf(address(this)) -
            bnbxAmountBefore;

        require(bnbxAmountAfter > bnbxAmountBefore, "No new bnbx minted");
        return bnbxAmountAfter - bnbxAmountBefore;
    }

    // 1. Convert Vault balance to Wombat LP token amount
    // 2. Withdraw Wombat LP token from Wombat Master
    // 3. Withdraw BNBX from Wombat Pool via sending the Wombat LP token
    function _withdrawInBnbX(uint256 _amount) private returns (uint256) {
        require(userShares[msg.sender] >= _amount, "Insufficient balance");

        uint256 amountInLP = _convertSharesToLP(_amount);
        totalShares -= _amount;
        userShares[msg.sender] -= _amount;
        totalInLP -= amountInLP;

        uint256 pid = wombatMaster.getAssetPid(
            wombatPool.addressOfAsset(address(bnbX))
        );
        wombatMaster.withdraw(pid, amountInLP);
        uint256 amountInBnbXBefore = bnbX.balanceOf(address(this));
        IERC20Upgradeable(wombatPool.addressOfAsset(address(bnbX))).approve(
            address(wombatPool),
            amountInLP
        );
        uint256 bnbxAmount = wombatPool.withdraw(
            address(bnbX),
            amountInLP,
            0,
            address(this),
            block.timestamp
        );
        require(
            amountInBnbXBefore + bnbxAmount == bnbX.balanceOf(address(this)),
            "Invalid bnbx amount"
        );

        return bnbxAmount;
    }

    function _convertBnbXToLP(uint256 _amount) private view returns (uint256) {
        (uint256 _amountInLP, ) = wombatPool.quotePotentialDeposit(
            address(bnbX),
            _amount
        );
        return _amountInLP;
    }

    function _convertLPToBnbX(uint256 _amount) private view returns (uint256) {
        (uint256 _amountInBnbX, ) = wombatPool.quotePotentialWithdraw(
            address(bnbX),
            _amount
        );

        return _amountInBnbX;
    }

    function _convertSharesToLP(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return (_amount * totalInLP) / totalShares;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Accessible only by Manager");
        _;
    }
}
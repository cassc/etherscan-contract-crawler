// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./Farms.sol";

contract MagicVault is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;
    bool internal locked;

    address public treasury; //treasury account, where 3% of fees in BUSD will be diverted.
    address public burningVault; //burning vault, where 2% of fees in BUSD will be diverted.

    uint256 public treasuryFee = 300; //treasury fee. all txn will be assessed a 3% fee and diverted to treasury.
    uint256 public vaultFee = 200; //burning vault fee. all txn will be assessed a 2% fee and diverted to the vault.
    uint256 public depositFee = treasuryFee.add(vaultFee); //total deposit fee
    uint256 public performanceFee = 2500;

    uint256 public pid = 0; //the poolId. Initiated to 0.

    IERC20 public busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 public crystal = IERC20(0xa1A5AD28C250B9383c360c0f69aD57D70379851e);
    IERC20 public diamond = IERC20(0xcAE4F3977c084aB12B73a920e670e1665B3fA7D5);
    DIARewardPool public farms =
        DIARewardPool(0xb2C5A04A71426756FCAbD0439E3738373C0A5064);
    address public router;
    IUniswapV2Pair public pair;

    struct UserInfo {
        uint256 busdInvested; //amount busd invested, net of totalFees.
        uint256 crystalsAllotted; //amount of crystal provided to mint LPs.
        uint256 lpsPlanted; //amount of LPs net of fees.
        uint256 rewardDebt; //reward calculation from Farms
    }

    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. DIAs to distribute per block.
        uint256 lastRewardTime; // Last time that DIAs distribution occurs.
        uint256 accDIAPerShare; // Accumulated DIAs per share, times 1e18. See below.
        bool isStarted; // if lastRewardTime has passed
        uint256 depositFee; // deposit fee
        uint256 withdrawFee; // withdraw fee
    }

    PoolInfo public copiedPoolInfo;
    mapping(address => UserInfo) public userInfo;

    modifier noReentrant() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    event MagicDeposit(address indexed user, uint256 indexed pid, uint256 busdInvested, uint256 crystalsAllotted, uint256 lpsPlanted);
    event MagicWithdrawl(address indexed user, uint256 indexed pid, uint256 busdInvested, uint256 diaRewardSent);
    event CrystalsAdded(address indexed user, uint256 addedAmount);

    constructor(
        address _uniswapRouter,
        address _treasury,
        address _burningVault
    ) {
        router = _uniswapRouter;
        treasury = _treasury;
        burningVault = _burningVault;

        pair = IUniswapV2Pair(
            IUniswapV2Factory(IUniswapV2Router02(router).factory()).getPair(
                address(busd),
                address(crystal)
            )
        );
    }

    function fundVaultWithCrystals(uint256 amountToFund)
        public
        onlyOwner
        returns (uint256)
    {
        require(amountToFund > 0, "low funds to transfer");

        require(crystal.balanceOf(msg.sender) >= amountToFund, "low balance");

        require(
            amountToFund <= crystal.allowance(msg.sender, address(this)),
            "allowance"
        );

        crystal.safeTransferFrom(msg.sender, address(this), amountToFund);

        emit CrystalsAdded(msg.sender, amountToFund);
        return crystal.balanceOf(address(this));
    }

    function setPoolId(uint256 newPoolId) public onlyOwner returns (uint256) {
        require(newPoolId != pid, 'Unchanged PoolID');
        pid = newPoolId;
        getPoolInfo();
        return pid;
    }

    function setPerformanceFee(uint256 newFee) public onlyOwner returns (uint256){
        require(performanceFee != newFee, 'Unchanged Performance Fee');
        performanceFee = newFee;
        return performanceFee;
    }

    function setDepositTreasuryFee(uint256 newFee) public onlyOwner returns(uint256) {
        require(treasuryFee != newFee, 'Unchanged Treasury Fee');
        treasuryFee = newFee;
        return treasuryFee;
    }

    function setDepositVaultFee(uint256 newFee) public onlyOwner returns(uint256) {
        require(vaultFee != newFee, 'Unchanged Vault Fee');
        vaultFee = newFee;
        return vaultFee;
    }

    function setTreasuryAccount(address newAddress) public onlyOwner returns(address){
        require(newAddress != address(0) && newAddress != address(this));
        require(treasury != newAddress, 'Unchanged Treasury');
        treasury = newAddress;
        return treasury;
    }

    function setBurningVaultAccount(address newAddress) public onlyOwner returns(address){
        require(newAddress != address(0) && newAddress != address(this));
        require(burningVault != newAddress, 'Unchanged Burning Vault');
        burningVault = newAddress;
        return burningVault;
    }

    function ownerWithdrawCrystals() public onlyOwner {
        crystal.safeTransfer(msg.sender, crystal.balanceOf(address(this)));
    }

    function ownerWithdrawBUSD() public onlyOwner {
        busd.safeTransfer(msg.sender, busd.balanceOf(address(this)));
    }

    function ownerWithdrawDiamonds() public onlyOwner {
        diamond.safeTransfer(msg.sender, diamond.balanceOf(address(this)));
    }

    function ownerWithdrawLPs() public onlyOwner {
        require(pair.transfer(msg.sender, pair.balanceOf(address(this))));
    }

    function depositBUSD(uint256 amountToDeposit) noReentrant public {
        UserInfo storage user = userInfo[msg.sender];
        require(amountToDeposit > 0, 'Invalid Amount');

        require(busd.balanceOf(msg.sender) >= amountToDeposit, 'Insufficient Amount');

        require(amountToDeposit <= busd.allowance(msg.sender, address(this)), 'Allowance');

        (uint256 _feeToTake, uint256 _netAmountOfDeposit) = takeFee(
            amountToDeposit,
            depositFee
        );

        require(forwardFees(_feeToTake), 'Fee Forwarding');

        uint256 beforeBusdBalance = busd.balanceOf(address(this));

        busd.safeTransferFrom(msg.sender, address(this), _netAmountOfDeposit);

        require(busd.balanceOf(address(this)).sub(beforeBusdBalance) == _netAmountOfDeposit, 'Deposit Mismatch');

        uint256 crystalsNeeded = matchingCrystalsToBUSD(_netAmountOfDeposit);

        require(
            crystal.balanceOf(address(this)) >= crystalsNeeded,
            "Insufficient CRS"
        );

        (uint256 liquidity, bool liquidityAdded) = addLiquidity(_netAmountOfDeposit, crystalsNeeded);

        require(liquidityAdded, 'Liqudity Mismatch');

        require(makeDeposit(liquidity), 'Farming Error');

        user.lpsPlanted = user.lpsPlanted.add(calculatePlantedLPs(liquidity));
        user.busdInvested = user.busdInvested.add(_netAmountOfDeposit);
        user.crystalsAllotted = user.crystalsAllotted.add(crystalsNeeded);
        user.rewardDebt = user.lpsPlanted.mul(copiedPoolInfo.accDIAPerShare).div(1e18);

        emit MagicDeposit(msg.sender, pid, _netAmountOfDeposit, crystalsNeeded, user.lpsPlanted);
    }

    function withdrawBUSD(uint256 amountToWithdraw) noReentrant public {
        uint256 busdToSend;
        UserInfo storage user = userInfo[msg.sender];
        uint256 lpsBefore = pair.balanceOf(address(this));

        require(amountToWithdraw > 0 && amountToWithdraw <= user.lpsPlanted, "Insufficient Withdrawl");

        farms.withdraw(pid, amountToWithdraw);

        uint256 lpsAfter = pair.balanceOf(address(this));

        require((lpsAfter.sub(lpsBefore)) == amountToWithdraw, 'Withdraw Mismatch');

        uint256 rewardsToPay = pendingShare(msg.sender);
        uint256 diamondsOnHand = diamond.balanceOf(address(this));

        require(rewardsToPay <= diamondsOnHand, "Insufficient Diamonds");

        (uint256 busdReceived, bool liquidityWithdrawn) = removeLiquidity(amountToWithdraw);

        require(liquidityWithdrawn, 'Liqudity Mismatch');

        if(busdReceived > user.busdInvested && performanceFee > 0){
            uint256 busdGain = busdReceived.sub(user.busdInvested);
            uint256 fee = busdGain.mul(performanceFee).div(10000);
            busd.safeTransfer(treasury, fee);
            busdToSend = busdToSend.sub(fee);
        } else {
            busdToSend = busdReceived;
        }

        user.busdInvested = 0;
        user.crystalsAllotted = 0;
        user.lpsPlanted = 0;
        user.rewardDebt = 0;

        busd.safeTransfer(msg.sender, busdToSend);
        diamond.safeTransfer(msg.sender, rewardsToPay);

        emit MagicWithdrawl(msg.sender, pid, busdToSend, rewardsToPay);
    }

    function takeFee(uint256 amountIn, uint256 fee)
        internal
        pure
        returns (uint256, uint256)
    {
        require(amountIn >= 0, "Not enough funds sent");
        uint256 feeToTake = amountIn.mul(fee).div(10000);
        return (feeToTake, amountIn.sub(feeToTake));
    }

    function forwardFees(uint256 amountToForward) internal returns (bool) {
        uint256 toTrasury = amountToForward.mul(treasuryFee).div( depositFee);
        uint256 toVault = amountToForward.mul(vaultFee).div(depositFee);
        busd.safeTransferFrom(msg.sender, treasury, toTrasury);
        busd.safeTransferFrom(msg.sender, burningVault, toVault);
        return true;
    }

    function matchingCrystalsToBUSD(uint256 busdAmountToMatch)
        internal
        view
        returns (uint256)
    {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair
            .getReserves();

        return ((reserve0 * busdAmountToMatch) / reserve1);
    }

    function addLiquidity(uint256 _netAmountOfDeposit, uint256 crystalsNeeded) internal returns (uint256, bool) {
        busd.approve(address(router), _netAmountOfDeposit);

        crystal.approve(address(router), crystalsNeeded);

        uint256 lpBefore = pair.balanceOf(address(this));

        ( , , uint256 liquidity) = IUniswapV2Router02(router).addLiquidity(
            address(busd),
            address(crystal),
            _netAmountOfDeposit,
            crystalsNeeded,
            _netAmountOfDeposit.mul(9900).div(10000),
            crystalsNeeded.mul(9900).div(10000),
            address(this),
            block.timestamp.add(600)
        );

        return (liquidity, ((pair.balanceOf(address(this)).sub(lpBefore)) == liquidity));
    }

    function removeLiquidity(uint256 amountToRemove) internal returns(uint256, bool) {
        pair.approve(address(router), amountToRemove);

        uint256 busdBefore = busd.balanceOf(address(this));

        ( uint256 busdReceived, uint256 crystalsReceived) = IUniswapV2Router02(router).removeLiquidity(
            address(busd),
            address(crystal),
            amountToRemove,
            0,
            0,
            address(this),
            block.timestamp + 600
        );

        uint256 busdAfter = busd.balanceOf(address(this));

        return ((busdAfter.sub(busdBefore)), ((busdAfter.sub(busdBefore)) == busdReceived));
    }

    function makeDeposit(uint256 amountLPsToDeposit) internal returns (bool){
        require(pair.approve(address(farms), amountLPsToDeposit), 'LPs Approval');

        farms.deposit(pid, amountLPsToDeposit);

        getPoolInfo();

        return true;
    }

    function calculatePlantedLPs(uint256 lpsDesposited) internal view returns(uint256) {
        if (copiedPoolInfo.depositFee > 0) {
            uint256 feeAmount = lpsDesposited.mul(copiedPoolInfo.depositFee).div(10000);
            return lpsDesposited.sub(feeAmount);
        } else {
            return lpsDesposited;
        }

    }

    function getPoolInfo() public returns (PoolInfo memory) {
        (
            IERC20 token,
            uint256 allocPoint,
            uint256 lastRewardTime,
            uint256 accDIAPerShare,
            bool isStarted,
            uint256 _depositFee,
            uint256 withdrawFee
        ) = farms.poolInfo(pid);

        copiedPoolInfo = PoolInfo({
            token: token,
            allocPoint: allocPoint,
            lastRewardTime: lastRewardTime,
            accDIAPerShare: accDIAPerShare,
            isStarted: isStarted,
            depositFee: _depositFee,
            withdrawFee: withdrawFee
        });

        return copiedPoolInfo;
    }

    function pendingShare(address _user) public returns (uint256) {
        PoolInfo memory pool = getPoolInfo();
        UserInfo memory user = userInfo[_user];
        uint256 accDIAPerShare = pool.accDIAPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(farms));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = farms.getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 _diamondReward = _generatedReward.mul(pool.allocPoint).div(
                farms.totalAllocPoint()
            );
            accDIAPerShare = accDIAPerShare.add(
                _diamondReward.mul(1e18).div(tokenSupply)
            );
        }

        return
            user.lpsPlanted.mul(accDIAPerShare).div(1e18).sub(user.rewardDebt);
    }
}
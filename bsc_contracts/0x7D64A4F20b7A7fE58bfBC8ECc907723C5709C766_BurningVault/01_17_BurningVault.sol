// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Farms.sol";

contract BurningVault is EIP712, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;
    bool internal locked;

    uint256 public pid = 0; //the poolId. Initiated to 0.
    address public cSigner;

    IERC20 public busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 public crystal = IERC20(0xa1A5AD28C250B9383c360c0f69aD57D70379851e);
    IERC20 public diamond = IERC20(0xcAE4F3977c084aB12B73a920e670e1665B3fA7D5);
    DIARewardPool public farms =
        DIARewardPool(0xb2C5A04A71426756FCAbD0439E3738373C0A5064);
    address public router;
    IUniswapV2Pair public pair;

    struct UserInfo {
        uint256 busdInvested; //amount busd invested, net of totalFees.
        uint256 crystalsInvested; //amount of crystal provided to mint LPs.
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

    bytes32 public constant TXN_CALL_HASH_TYPE =
        keccak256(
            "TWAP(uint256 _twap,uint256 _nonce,uint256 _fee)"
        );
    uint256 public nonce = 0;
    mapping(address => UserInfo) public userInfo;

    modifier noReentrant() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    event BurningVaultInvestment(address indexed user, uint256 indexed pid, uint256 busdInvested, uint256 crystalsAllotted, uint256 lpsPlanted);
    event BurningVaultWithdrawal(address indexed user, uint256 indexed pid, uint256 busdInvested, uint256 crystalsAllotted, uint256 diaRewardSent);

    constructor(
        address _uniswapRouter,
        address _signer,
        string memory _name,
        string memory _version
    ) EIP712(_name, _version) {
        router = _uniswapRouter;
        cSigner = _signer;
        pair = IUniswapV2Pair(
            IUniswapV2Factory(IUniswapV2Router02(router).factory()).getPair(
                address(busd),
                address(crystal)
            )
        );
    }

    function setPoolId(uint256 newPoolId) public onlyOwner returns (uint256) {
        require(newPoolId != pid, 'Unchanged PoolID');
        pid = newPoolId;
        getPoolInfo();
        return pid;
    }

    function setSigner(address newSigner) public onlyOwner returns (bool){
        require(newSigner != cSigner, 'Unchanged Signer');
        require(newSigner != address(this), 'Unique Signer Req.');
        require(newSigner != address(0), 'Unnique Signer Req.');

        cSigner = newSigner;
        return true;
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

    function depositBUSD(bytes memory _signature, uint256 _twap, uint256 _nonce, uint256 _fee, uint256 amountToDeposit) noReentrant public {
        UserInfo storage user = userInfo[msg.sender];
        require(amountToDeposit > 0, 'Invalid Amount');

        require(busd.balanceOf(msg.sender) >= amountToDeposit, 'Insufficient Amount');
        
        require(_nonce == nonce, 'Invalid Signature (time)');

        require(isSignatureValid(_signature, _twap, _nonce, _fee), 'Invalid Signature');

        require(_twap >= 100, 'Deposits Halted'); 

        require(amountToDeposit <= busd.allowance(msg.sender, address(this)), 'Allowance');

        uint256 beforeBusdBalance = busd.balanceOf(address(this));

        busd.safeTransferFrom(msg.sender, address(this), amountToDeposit);

        require(busd.balanceOf(address(this)).sub(beforeBusdBalance) == amountToDeposit, 'Deposit Mismatch');

        uint256 busdInvestable = amountToDeposit.div(2);

        uint256 busdPurchasble = amountToDeposit.sub(busdInvestable);

        (uint256 crystalsReceived, bool purchaseMade) = makeDEXPurchase(busdPurchasble);

        require(purchaseMade, 'Purchsse Failed');

        (uint256 liquidity, bool liquidityAdded) = addLiquidity(busdInvestable, crystalsReceived);

        require(liquidityAdded, 'Add Liquidtiy Mismatch');

        require(makeDeposit(liquidity), 'Farming Error');

        user.lpsPlanted = user.lpsPlanted.add(calculatePlantedLPs(liquidity));
        user.busdInvested = user.busdInvested.add(busdInvestable);
        user.crystalsInvested = user.crystalsInvested.add(crystalsReceived);
        user.rewardDebt = user.lpsPlanted.mul(copiedPoolInfo.accDIAPerShare).div(1e18);

        nonce++;

        emit BurningVaultInvestment(msg.sender, pid, busdInvestable, crystalsReceived, user.lpsPlanted);
    }

    function withdrawBUSD(bytes memory _signature, uint256 _twap, uint256 _nonce, uint256 _fee, uint256 amountToWithdraw) noReentrant public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 lpsBefore = pair.balanceOf(address(this));

        require(amountToWithdraw > 0 && amountToWithdraw <= user.lpsPlanted, "Insufficient Withdrawl");

        require(_fee >= 0 && _fee <= 10000, 'Withdrawal Fee Invalid'); 

        require(_nonce == nonce, 'Invalid Signature (time)');

        require(isSignatureValid(_signature, _twap, _nonce, _fee), 'Invalid Signature');

        farms.withdraw(pid, amountToWithdraw);

        uint256 lpsAfter = pair.balanceOf(address(this));

        require((lpsAfter.sub(lpsBefore)) == amountToWithdraw, 'Withdraw Mismatch');

        uint256 rewardsToPay = pendingShare(msg.sender);
        uint256 diamondsOnHand = diamond.balanceOf(address(this));

        require(rewardsToPay <= diamondsOnHand, "Insufficient Diamonds");

        if(_fee > 0){
            amountToWithdraw = amountToWithdraw.mul(_fee).div(10000);
        }

        (uint256 busdReceived, uint256 crystalReceived, bool liquidityWithdrawn) = removeLiquidity(amountToWithdraw);

        require(liquidityWithdrawn, 'Liqudity Mismatch');

        user.busdInvested = 0;
        user.crystalsInvested = 0;
        user.lpsPlanted = 0;
        user.rewardDebt = 0;

        nonce++;

        busd.safeTransfer(msg.sender, busdReceived);
        crystal.safeTransfer(msg.sender, crystalReceived);
        diamond.safeTransfer(msg.sender, rewardsToPay);

        if(busd.balanceOf(address(this)) > rewardsToPay) {
            busd.safeTransfer(msg.sender, rewardsToPay);
        }

        emit BurningVaultWithdrawal(msg.sender, pid, busdReceived, crystalReceived, rewardsToPay);
    }

    function isSignatureValid(bytes memory _signature, uint256 _twap, uint256 _nonce, uint256 _fee) view internal returns(bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    TXN_CALL_HASH_TYPE,
                    _twap,
                    _nonce,
                    _fee
                )
            )
        );
        address _signer = ECDSA.recover(digest, _signature);

        return _signer == cSigner;
    }

    function makeDEXPurchase(uint256 purchaseAmount) internal returns (uint256, bool) {
        address[] memory path = new address[](2);
        path[0] = address(busd);
        path[1] = address(crystal);

        busd.approve(address(router), purchaseAmount);

        uint256 beforeCrystalBalance = crystal.balanceOf(address(this));

        (uint[] memory amounts) = IUniswapV2Router02(router).swapExactTokensForTokens(
            purchaseAmount,
            0,
            path,
            address(this),
            block.timestamp.add(600)
        );

        return (crystal.balanceOf(address(this)).sub(beforeCrystalBalance), true);
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

    function makeDeposit(uint256 amountLPsToDeposit) internal returns (bool){
        require(pair.approve(address(farms), amountLPsToDeposit), 'LPs Approval');

        farms.deposit(pid, amountLPsToDeposit);

        getPoolInfo();

        return true;
    }

    function removeLiquidity(uint256 amountToRemove) internal returns(uint256, uint256, bool) {
        pair.approve(address(router), amountToRemove);

        uint256 busdBefore = busd.balanceOf(address(this));
        uint256 crystalsBefore = crystal.balanceOf(address(this));

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
        uint256 crystalsAfter = crystal.balanceOf(address(this));
        
        return ((busdAfter.sub(busdBefore)), (crystalsAfter.sub(crystalsBefore)), ((busdAfter.sub(busdBefore)) == busdReceived));
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
            uint256 depositFee,
            uint256 withdrawFee
        ) = farms.poolInfo(pid);

        copiedPoolInfo = PoolInfo({
            token: token,
            allocPoint: allocPoint,
            lastRewardTime: lastRewardTime,
            accDIAPerShare: accDIAPerShare,
            isStarted: isStarted,
            depositFee: depositFee,
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
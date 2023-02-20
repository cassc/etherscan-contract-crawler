import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IFees.sol";
import "./interfaces/ISwapHelper.sol";
import "./interfaces/IRibbonVault.sol";
import "./proxies/S9Proxy.sol";

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

contract S9Strategy is Ownable {
    address immutable swapRouter;
    address immutable feeContract;
    address constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant rbn = 0x6123B0049F904d730dB3C36a31167D9d4121fA6B;

    constructor(address swapRouter_, address feeContract_) {
        swapRouter = swapRouter_;
        feeContract = feeContract_;
    }

    uint256 public constant strategyId = 14;

    //modifiers
    modifier whitelistedToken(address token) {
        require(
            IFees(feeContract).whitelistedDepositCurrencies(strategyId, token),
            "whitelistedToken: Invalid token"
        );
        _;
    }

    //mappings
    //user => user proxy
    mapping(address => address) public depositors;

    //vault address => whitelist status
    mapping(address => bool) public vaultWhitelist;

    //valutAsset => vaultAssetSwapHelper
    mapping(address => address) public swapHelper;

    //events
    event Deposit(
        address user,
        address tokenIn,
        address vault,
        uint256 amountIn
    );

    event QueueWithdraw(address user, address vault, uint256 amount);

    event Withdraw(
        address user,
        address tokenOut,
        address vault,
        uint256 amount,
        uint256 fee
    );

    event Claim(address user, address vault, uint256 amonut);

    event Stake(address user, address vault, uint256 amount);

    event ProxyCreation(address user, address proxy);

    //getters

    //returns the amounts in the different deposit states
    //@dev return amounts are in shares except avaliableInstant, multiply with pricePerShare to get USDC amount

    //locked amount currently generating yield
    //pending amount not generating yield, waiting to be available
    //avaliableClaim is amount that has gone through an epoch and has been initiateWithdraw
    //availableInstant amount are deposits that have not gone through an epoch that can be withdrawn
    function getDepositData(address user, address vault)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        address vaultAsset;
        uint256 locked;
        uint256 pending;
        uint256 avaliableInstant;
        uint256 avaliableClaim;
        uint256 pricePerShare;
        uint256 withdrawPricePerShare;
        uint256 vaultRound;
        uint256 currentLoanTermLength;

        IRibbonVault rv = IRibbonVault(vault);
        (, vaultAsset, , ) = rv.vaultParams();
        //depositReciept is only updated when initiateWithdraw is called
        //In native token
        (vaultRound, , , , , , , , ) = getVaultState(vault);
        avaliableInstant = _getDepositReciepts(
            vault,
            vaultRound,
            depositors[user]
        );
        (
            ,
            pending,
            avaliableClaim,
            withdrawPricePerShare
        ) = _getWithdrawReciepts(vault, vaultRound, depositors[user]);
        pricePerShare = rv.pricePerShare();
        (uint256 heldByAccount, uint256 heldByVault) = rv.shareBalances(
            depositors[user]
        );
        uint256 stakedInGauge = IERC20(IRibbonVault(vault).liquidityGauge())
            .balanceOf(depositors[user]);
        locked = heldByAccount + heldByVault + stakedInGauge;
        (, , currentLoanTermLength, , , , , ) = rv.allocationState();
        return (
            //asset token used by the vault
            vaultAsset,
            //generating yield denotes shares are currently locked in round
            //shares generating yield, before initateWithdraw
            locked,
            //shares generating yield, after initiateWithdraw before completeWithdraw
            pending,
            //token not generating yield, pending instantWithdraw
            avaliableInstant,
            //shares not generating yield, after round end before comepleteWithdraw
            //@dev to only take this parameter for v1
            avaliableClaim,
            //the price per share of the last round, used to calculate token value for locked
            pricePerShare,
            //the price per share of the initiate withdraw round, used to calculate token value for avaliableClaim
            withdrawPricePerShare,
            currentLoanTermLength,
            //can user stake
            heldByAccount + heldByVault
        );
    }

    //direct proxy method to vaultState
    function getVaultState(address vault)
        public
        view
        returns (
            uint16,
            uint104,
            uint104,
            uint128,
            uint128,
            uint64,
            uint64,
            uint128,
            uint256
        )
    {
        (
            uint16 round,
            uint104 lockedAmount,
            uint104 lastLockedAmount,
            uint128 totalPending,
            uint128 queuedWithdrawShares,
            uint64 lastEpochTime,
            uint64 lastOptionPurchaseTime,
            uint128 optionsBoughtInRound,
            uint256 amtFundsReturned
        ) = IRibbonVault(vault).vaultState();
        return (
            round,
            lockedAmount,
            lastLockedAmount,
            totalPending,
            queuedWithdrawShares,
            lastEpochTime,
            lastOptionPurchaseTime,
            optionsBoughtInRound,
            amtFundsReturned
        );
    }

    //write
    function depositToken(
        address tokenIn,
        address vault,
        uint256 amount,
        uint256 minAmountOut
    ) public payable whitelistedToken(tokenIn) {
        require(
            IFees(feeContract).depositStatus(strategyId),
            "depositToken: depositsStopped"
        );
        require(vaultWhitelist[vault], "depositToken: vaultWhitelist");
        address proxy = depositors[msg.sender];
        if (proxy == address(0)) {
            //mint proxy if not exists
            S9Proxy newProxy = new S9Proxy(msg.sender);
            proxy = address(newProxy);
            depositors[msg.sender] = proxy;
            emit ProxyCreation(msg.sender, proxy);
        }
        address vaultAsset;
        (, vaultAsset, , ) = IRibbonVault(vault).vaultParams();
        emit Deposit(msg.sender, tokenIn, vault, amount);
        //swap
        if (tokenIn != vaultAsset) {
            if (msg.value == 0) {
                IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
            } else {
                //convert eth to weth
                (bool success, ) = payable(wethAddress).call{value: msg.value}(
                    ""
                );
                require(success, "depositToken: Send ETH fail");
                tokenIn = wethAddress;
            }
            
            //swap
            if(swapHelper[vaultAsset]!=address(0)){                
                if(tokenIn!=wethAddress){
                    IERC20(tokenIn).approve(swapRouter, amount);
                    amount=ISwapRouter(swapRouter).swapTokenForToken(
                        tokenIn,
                        wethAddress,
                        amount,
                        1,
                        address(this));
                }
                //swap to vaultAsset
                IERC20(wethAddress).approve(swapHelper[vaultAsset], amount);                                
                amount=ISwapHelper(swapHelper[vaultAsset]).swap(
                    wethAddress,
                    vaultAsset,
                    amount,
                    minAmountOut,
                    proxy
                );
            }else{                
                IERC20(tokenIn).approve(swapRouter, amount);
                amount = ISwapRouter(swapRouter).swapTokenForToken(
                    tokenIn,
                    vaultAsset,
                    amount,
                    minAmountOut,
                    proxy
                );
            }
        } else {
            IERC20(vaultAsset).transferFrom(msg.sender, proxy, amount);
        }
        S9Proxy(depositors[msg.sender]).deposit(vault, vaultAsset, amount);
    }

    //@dev only the amount here should be in shares
    function queueWithdraw(address vault, uint256 amount) external {
        S9Proxy(depositors[msg.sender]).queueWithdraw(vault, amount);
        emit QueueWithdraw(msg.sender, vault, amount);
    }

    //@dev pass address(0) for ETH
    function withdrawToken(
        address tokenOut,
        address vault,
        uint256 requestAmtToken,
        uint256 minAmountOut,
        address feeToken
    ) external whitelistedToken(tokenOut) {
        address _tokenOut = tokenOut != address(0) ? tokenOut : wethAddress;
        address vaultAsset;

        (, vaultAsset, , ) = IRibbonVault(vault).vaultParams();
        (uint256 vaultRound, , , , , , , , ) = getVaultState(vault);
        uint256 instantAmt = _getDepositReciepts(
            vault,
            vaultRound,
            depositors[msg.sender]
        );
        S9Proxy(depositors[msg.sender]).withdraw(
            vault,
            vaultAsset,
            requestAmtToken,
            instantAmt
        );
        uint256 result = IERC20(vaultAsset).balanceOf(address(this));
        //We redeposit if there is excess
        if (result > requestAmtToken) {
            uint256 redepositAmt = result - requestAmtToken;
            //We transfer to proxy
            IERC20(vaultAsset).transfer(depositors[msg.sender], redepositAmt);
            S9Proxy(depositors[msg.sender]).deposit(
                vault,
                vaultAsset,
                redepositAmt
            );
            result = requestAmtToken;
        }
        uint256 fee = (IFees(feeContract).calcFee(
            strategyId,
            msg.sender,
            feeToken
        ) * result) / 1000;
        IERC20(vaultAsset).transfer(
            IFees(feeContract).feeCollector(strategyId),
            fee
        );
        result = IERC20(vaultAsset).balanceOf(address(this));
        if (swapHelper[vaultAsset] != address(0)) {
            //expected to always swap to weth
            IERC20(vaultAsset).approve(swapHelper[vaultAsset], result);
            result = ISwapHelper(swapHelper[vaultAsset]).swap(
                vaultAsset,
                wethAddress,
                result,
                minAmountOut,
                address(this)
            );
            vaultAsset = wethAddress;
        }
        if (_tokenOut != vaultAsset) {
            //swap
            IERC20(vaultAsset).approve(swapRouter, result);
            result = ISwapRouter(swapRouter).swapTokenForToken(
                vaultAsset,
                _tokenOut,
                result,
                1,
                address(this)
            );
        }
        require(result >= minAmountOut, "withdrawToken: minAmountOut");
        _sendToken(tokenOut, msg.sender, IERC20(_tokenOut).balanceOf(address(this)));        
        //fee is in valutAsset
        emit Withdraw(msg.sender, tokenOut, vault, result, fee);
    }

    function stake(address vault) external {
        (uint256 heldByAccount, uint256 heldByVault) = IRibbonVault(vault)
            .shareBalances(depositors[msg.sender]);
        S9Proxy(depositors[msg.sender]).stake(
            vault,
            heldByAccount + heldByVault
        );
        emit Stake(msg.sender, vault, heldByAccount + heldByVault);
    }

    //@dev pass tokenOut as rbn to avoid swap
    //@dev pass tokenOut as address(0) for native ETH
    function claim(
        address vault,
        address tokenOut,
        uint256 minAmountOut
    ) external whitelistedToken(tokenOut) {
        address gauge = IRibbonVault(vault).liquidityGauge();
        address to = tokenOut == rbn ? msg.sender : address(this);
        uint256 amount = S9Proxy(depositors[msg.sender]).claim(gauge, to);
        emit Claim(msg.sender, vault, amount);
        if (tokenOut != rbn) {
            address _tokenOut = tokenOut!=address(0)?tokenOut:wethAddress;
            if(swapHelper[rbn]!=address(0)){
                IERC20(rbn).approve(swapHelper[rbn], amount);
                //swap to token
                amount=ISwapHelper(swapHelper[rbn]).swap(
                    rbn,
                    _tokenOut,
                    amount,
                    minAmountOut,
                    tokenOut!=address(0)?msg.sender:address(this)
                );
            }else{
                IERC20(rbn).approve(swapRouter, amount);
                //swap to token
                amount=ISwapRouter(swapRouter).swapTokenForToken(
                    rbn,
                    _tokenOut,
                    amount,
                    minAmountOut,
                    tokenOut!=address(0)?msg.sender:address(this)
                );
            }
            if(tokenOut==address(0)){
                _sendToken(tokenOut, msg.sender, amount);
            }
        }
    }

    function emergencyWithdraw(address vault) external {
        require(!IFees(feeContract).depositStatus(strategyId));
        (, address vaultAsset, , ) = IRibbonVault(vault).vaultParams();
        (uint256 vaultRound, , , , , , , , ) = getVaultState(vault);
        uint256 amount = _getDepositReciepts(
            vault,
            vaultRound,
            depositors[msg.sender]
        );
        S9Proxy(depositors[msg.sender]).emergencyWithdraw(
            vault,
            vaultAsset,
            amount
        );
    }

    function toggleVaultWhitelist(address[] calldata vaults, bool state)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < vaults.length; i++) {
            vaultWhitelist[vaults[i]] = state;
        }
    }

    function setHelper(address token, address helper) external onlyOwner {
        swapHelper[token] = helper;
    }

    //internal writes
    function _sendToken(address tokenOut, address to, uint amount) internal {
         if (tokenOut != address(0)) {
            IERC20(tokenOut).transfer(to, amount);
        } else {
            //unwrap eth
            IWETH(wethAddress).withdraw(amount);
            (bool sent, ) = payable(to).call{value: amount}("");
            require(sent, "_sendToken: send ETH fail");
        }        
    }

    //internal reads
    function _getDepositReciepts(
        address vault,
        uint256 vaultRound,
        address user
    ) internal view returns (uint256) {
        uint256 available;
        (uint256 round, uint256 depositAmount, ) = IRibbonVault(vault)
            .depositReceipts(user);
        if (vaultRound == round) {
            available += depositAmount;
        }
        return available;
    }

    function _getWithdrawReciepts(
        address vault,
        uint256 vaultRound,
        address user
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 pending;
        uint256 avaliableClaim;
        IRibbonVault rv = IRibbonVault(vault);
        (uint256 round, uint256 withdrawAmount) = rv.withdrawals(user);
        //only pending or avaliableClaim will be possible
        //initiating withdraw when avaliableClaim > 0 will revert
        if (vaultRound > round) {
            avaliableClaim += withdrawAmount;
        }
        if (vaultRound == round) {
            pending += withdrawAmount;
        }
        uint256 withdrawPricePerShare = rv.roundPricePerShare(round);
        return (round, pending, avaliableClaim, withdrawPricePerShare);
    }

    receive() external payable {}
}
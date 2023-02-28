// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ICheckDec.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IRouterV2.sol";

import "../token/MyToken.sol";
import "../utils/FeeReducer.sol";


/**
 * @title The magical MyWrapper contract.
 * @author int(200/0), slidingpanda
 */
contract MyWrapper is Ownable, ReentrancyGuard {
    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event AddedLiquidity(address LiquidityToken);

    using SafeERC20 for IERC20;

    IERC20 public pegToken;
    MyToken public myToken;

    address public myShareToken;
    address public stakingFactory;

    // bsc mainnet
    address public constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    // bsc testnet
    // address constant public ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    // address constant public FACTORY = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc;
    // address constant public WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    FeeReducer public feeReducer;

    bool public isActive;

    mapping(address => bool) public isWhitelisted;

    /**
     * Sets the contract owner and the myToken:Token relation.
	 *
     * @param pegTokenAddr address of the ERC20 token
     * @param myShareTokenAddr address of the myShare Token
     * @param daoWallet_ address of the DAO wallet for the myToken
     * @param myName name of the created myToken
     * @param mySymbol symbol of the created myToken
     * @param owner_ owner of the created myToken
     * @param feeReducerAddr address of the feeReducer
     * @param stakingFactoryAddr address of the stakingFactory
     */
    constructor(
        address pegTokenAddr,
        address myShareTokenAddr,
        address daoWallet_,
        string memory myName,
        string memory mySymbol,
        address owner_,
        address feeReducerAddr,
        address stakingFactoryAddr
    ) public {
        uint8 decimals = CheckDec(pegTokenAddr).decimals();
        myToken = new MyToken(myName, mySymbol, decimals, pegTokenAddr, daoWallet_, myShareTokenAddr);
        myToken.transferOwnership(owner_);
        transferOwnership(owner_);

        myShareToken = myShareTokenAddr;

        pegToken = IERC20(pegTokenAddr);
        feeReducer = FeeReducer(feeReducerAddr);
        stakingFactory = stakingFactoryAddr;
    }

    /**
     * Connects the feeReducer contract with the myWrapper contract.
	 *
     * @notice - When changing the feeReducer contract, it is necessary that the new one has the states of the old one
     *         - Otherwise the user will lose the reduction
	 *
     * @param newAddr address of the new feeReducer contract
     */
    function setFeeReducer(address newAddr) external onlyOwner {
        feeReducer = FeeReducer(newAddr);
    }

    /**
     * Changes the address of the stakingFactory.
	 *
     * @param newAddr address of the new stakingFactory contract
     */
    function setFactory(address newAddr) external onlyOwner {
        stakingFactory = newAddr;
    }

    /**
     * Returns the myToken address.
	 *
     * @return address myToken address
     */
    function myTokenAddr() public view returns (address) {
        return address(myToken);
    }

    /**
     * Whitelists an address for minting.
	 *
     * @param inAddr address
     * @param toSet determines if address should be whitelisted
     */
    function setWhitelist(address inAddr, bool toSet) external onlyOwner {
        isWhitelisted[inAddr] = toSet;
    }

    /**
     * Toggles the possibility to buy over the wrapper.
	 *
     * @return bool isActive after the toggle
     */
    function toggleActivity() external onlyOwner returns (bool) {
        isActive = !isActive;
        return isActive;
    }

    /**
     * Mints new myTokens with the sent ERC20 tokens.
	 *
     * @param tokenAmount buy amount
     * @return bool 'true' if not reverted
     */
    function deposit(uint256 tokenAmount) external nonReentrant returns (bool) {
        require(isWhitelisted[msg.sender] == true, "Only whitelisted addresses can mint myXXX");
        require(isActive == true, "The deposit function is not activated");
        require(address(pegToken) != WETH, "Please use the depositETH() function");

        IERC20(pegToken).safeTransferFrom(msg.sender, address(this), tokenAmount);

        myToken.mint(msg.sender, tokenAmount);
        emit Deposit(msg.sender, tokenAmount);

        return true;
    }

    /**
     * Mints new myTokens for the sent native tokens.
	 *
     * @return bool 'true' if not reverted
     */
    function depositETH() external payable nonReentrant returns (bool) {
        require(isWhitelisted[msg.sender] == true, "Only whitelisted addresses can mint myXXX");
        require(isActive == true, "The deposit function is not activated");
        require(address(pegToken) == WETH, "Please use the deposit() function");

        myToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);

        return true;
    }

    /**
     * Burns myTokens and sends the corresponding ERC20 or native tokens.
	 *
     * @notice - Addresses which are not reduced in any way will have a fee of 1%
     *         - Addresses which are holding myShare tokens will have a fee of 0.5%
     *         - Users of the feeReducer will have a fee of 0.1%
     *         - Whitelisted addresses can withdraw without any fees
     *         - The fees are added completely to the feeReserve of the myToken
	 *
     * @param tokenAmount withdraw amount
	 * @return bool 'true' if not reverted
     */
    function withdraw(uint256 tokenAmount) external nonReentrant returns (bool) {
        require(myToken.totalSupply() >= tokenAmount, "Amount exceeds myWrapper balance");

        uint256 fee = tokenAmount / 100;
        (, uint256 feeMulti) = userFee(msg.sender);

        feeMulti = isWhitelisted[msg.sender] ? 0 : feeMulti;
        fee = (fee * feeMulti) / 10;

        uint256 afterFee = tokenAmount - fee;

        if (fee > 0) {
            myToken.fountainWrapper(fee, msg.sender);
        }

        myToken.burn(msg.sender, afterFee);

        if (address(pegToken) == WETH) {
            require(address(this).balance >= tokenAmount, "Too few pegged tokens locked");

            (bool sent,) = msg.sender.call{value: afterFee}("");
		
            require(sent, "Failed to send ETH");
        } else {
            require(pegToken.balanceOf(address(this)) >= tokenAmount, "Too few pegged tokens locked");

            IERC20(pegToken).safeTransfer(msg.sender, afterFee);
        }

        emit Withdraw(msg.sender, afterFee);

        return true;
    }

    /**
     * Returns the possible fee multiplicators.
	 *
     * @notice The calculation: "amount * feeMultiX / 10" and feeMultiX can be resolved like this:
	 *			- Wrapper withdraw / LP zap in (base 1%):
     *				Holding     50% fees
     *				FeeReducer  10% fees
     *			- myToken transaction:
     *				Holding     90% fees
     *				FeeReducer  50% fees
	 *
     * @param user address which is checked
     * @return feeMultiToken fee multiplier for the myToken
     * @return feeMultiWrapper fee multiplier for withdrawing
     */
    function userFee(address user) public view returns (uint256 feeMultiToken, uint256 feeMultiWrapper) {
        (feeMultiToken, feeMultiWrapper) = feeReducer.feeMultiplier(user);
    }

    /**
     * Checks which type of liquidity is meant to be added: Only non-native tokens are possible while the pegToken can be the native token, but not the pair token.
	 *
     * @notice - Only the owner() can add "new" liquidity for the first time
     *         - Otherwise users could compromise the sync array length
     *         - To add native tokens the amountB needs to be zero because the message value is taken instead
	 *
     * @param token pair token (not the pegged token or the myToken)
     * @param amountA pair token amount (not the pegged token or the myToken)
     * @param amountB myToken amount and/or pegToken
     * @param slippage in thousandths (1/1000)
     * @return lpTokenAddr address of the lp token
     */
    function addERCLiq(address token, uint256 amountA, uint256 amountB, uint256 slippage) external payable nonReentrant returns (address lpTokenAddr) {
        require(token != WETH, "Please use addETHLiq()");

        address liqPair = IFactory(FACTORY).getPair(token, myTokenAddr());

        if (address(pegToken) == WETH) {
            amountB = msg.value;
        } else {
            require(msg.value == 0, "Do not send ETH if not needed");
        }

        if (liqPair != address(0) && myToken.isLP(liqPair) == true) {
            lpTokenAddr = _addERCLiq(token, amountA, amountB, slippage);

            emit AddedLiquidity(lpTokenAddr);
        } else if (liqPair == address(0)) {
            require(msg.sender == owner(), "Only DAO can add new LPs");

            lpTokenAddr = _addERCLiq(token, amountA, amountB, slippage);
            myToken.addSyncAddr(lpTokenAddr);
            
            emit AddedLiquidity(lpTokenAddr);
        } else if (myToken.isLP(liqPair) == false) {
            require(msg.sender == owner(), "Only DAO can add LPs to sync");

            lpTokenAddr = _addERCLiq(token, amountA, amountB, slippage);
            myToken.addSyncAddr(lpTokenAddr);

            emit AddedLiquidity(lpTokenAddr);
        }
    }

    /**
     * Adds a sync address to the myToken.
	 *
     * @notice - Is also called if the owner creates a new lp token or if the LP already exists, but it is not set so far from addERCLiq/addETHLiq
     *         - Pools need to be synced from reflows
	 *
     * @param newLp lp token to add to the sync array
     */
    function addSync(address newLp) external onlyOwner {
        myToken.addSyncAddr(newLp);
    }

    /**
     * Adds liquidity for a myToken to pancake swap.
	 *
     * @notice - Only the owner() can add "new" liquidity for the first time
     *         - Otherwise users could compromise the sync array length
     *         - To add native tokens the amountB needs to be zero because the message value is taken instead
	 *
     * @param token pair token (not the pegged token or the myToken)
     * @param amountA pair token amount (not the pegged token or the myToken)
     * @param amountB myToken amount and/or pegToken
     * @param slippage in thousandths (1/1000)
     * @return lpTokenAddr address of the lp token
     */
    function _addERCLiq(address token, uint256 amountA, uint256 amountB, uint256 slippage) internal returns (address lpTokenAddr) {
        if (address(pegToken) != WETH) {
            pegToken.safeTransferFrom(msg.sender, address(this), amountB);
        }
		
        IERC20(token).safeTransferFrom(msg.sender, address(this), amountA);
        myToken.mint(address(this), amountB);

        IERC20(token).approve(ROUTER, amountA);
        myToken.approve(ROUTER, amountB);

        uint256 minAmountA = amountA - ((amountA * slippage) / 1000);
        uint256 minAmountB = amountB - ((amountB * slippage) / 1000);

        (
            uint256 addedAmountA,
            uint256 addedAmountB,
            uint256 lpAmount
        ) = IRouterV2(ROUTER).addLiquidity(
                token,
                address(myToken),
                amountA,
                amountB,
                minAmountA,
                minAmountB,
                address(this),
                block.timestamp
            );

        if (amountA > addedAmountA) {
            uint256 sendBackA = amountA - addedAmountA;
            IERC20(token).safeTransfer(msg.sender, sendBackA);
        }

        if (amountB > addedAmountB) {
            uint256 sendBackB = amountB - addedAmountB;
            myToken.burn(address(this), sendBackB);

            if (address(pegToken) != WETH) {
                pegToken.safeTransfer(msg.sender, sendBackB);
            } else {
                (bool sent,) = msg.sender.call{value: sendBackB}("");
		
                require(sent, "Failed to send ETH");
            }
        }

        uint256 fee = lpAmount / 100;
        (, uint256 feeMulti) = userFee(msg.sender);

        fee = (fee * feeMulti) / 10;
        uint256 afterFee = lpAmount - fee;

        lpTokenAddr = IFactory(FACTORY).getPair(token, myTokenAddr());

        IERC20(lpTokenAddr).safeTransfer(msg.sender, afterFee);
        IERC20(lpTokenAddr).safeTransfer(address(1), fee);
    }

    /**
     * Checks which type of liquidity is meant to be added: Only non-native tokens are possible while the pegToken can be the native token, but not the pair token.
	 *
     * @notice - Only the owner() can add "new" liquidity for the first time
     *         - Otherwise users could compromise the sync array length
     *         - To add native tokens the amountB needs to be zero because the message value is taken instead
	 *
     * @param amountA pair token amount (not the pegged token or the myToken)
     * @param amountB myToken amount and/or pegToken
     * @param slippage in thousandths (1/1000)
     * @return lpTokenAddr address of the lp token
     */
    function addETHLiq(uint256 amountA, uint256 amountB, uint256 slippage) external payable nonReentrant returns (address lpTokenAddr) {
        require(msg.value > 0, "Sending ETH it is needed");

        address liqPair = IFactory(FACTORY).getPair(WETH, myTokenAddr());

        if (address(pegToken) == WETH) {
            amountA = msg.value / 2;
            amountB = msg.value - amountA;
        } else {
            require(amountB != 0, "PegToken amount should be > 0");

            amountA = msg.value;
        }

        if (liqPair != address(0) && myToken.isLP(liqPair) == true) {
            lpTokenAddr = _addETHLiq(amountA, amountB, slippage);

            emit AddedLiquidity(lpTokenAddr);
        } else if (liqPair == address(0)) {
            require(msg.sender == owner(), "Only DAO can add new LPs");

            lpTokenAddr = _addETHLiq(amountA, amountB, slippage);
            myToken.addSyncAddr(lpTokenAddr);

            emit AddedLiquidity(lpTokenAddr);
        } else if (myToken.isLP(liqPair) == false) {
            require(msg.sender == owner(), "Only DAO can add LPs to sync");

            lpTokenAddr = _addETHLiq(amountA, amountB, slippage);
            myToken.addSyncAddr(lpTokenAddr);

            emit AddedLiquidity(lpTokenAddr);
        }
    }

    /**
     * Adds liquidity for a myToken to pancake swap.
	 *
     * @notice - Only the owner() can add "new" liquidity for the first time
     *         - Otherwise users could compromise the sync array length
     *         - To add native tokens the amountB needs to be zero because the message value is taken instead
	 *
     * @param amountA pair token amount (not the pegged token or the myToken)
     * @param amountB myToken amount and/or pegToken
     * @param slippage in thousandths (1/1000)
     * @return lpTokenAddr address of the lp token
     */
    function _addETHLiq(uint256 amountA, uint256 amountB, uint256 slippage) internal returns (address lpTokenAddr) {
        if (address(pegToken) != WETH) {
            pegToken.safeTransferFrom(msg.sender, address(this), amountB);
        }

        myToken.mint(address(this), amountB);
        myToken.approve(ROUTER, amountB);

        uint256 minAmountA = amountA - ((amountA * slippage) / 1000);
        uint256 minAmountB = amountB - ((amountB * slippage) / 1000);

        (
            uint256 addedTENAmount,
            uint256 addedETHAmount,
            uint256 lpAmount
        ) = IRouterV2(ROUTER).addLiquidityETH{value: amountA}(
                address(myToken),
                amountB,
                minAmountA,
                minAmountB,
                address(this),
                block.timestamp
            );

        uint256 wethBack;
        if (amountA > addedETHAmount) {
            wethBack = amountA - addedETHAmount;
        }

        if (amountB > addedTENAmount) {
            uint256 sendBackB = amountB - addedTENAmount;
            myToken.burn(address(this), sendBackB);

            if (address(pegToken) == WETH) {
                wethBack += sendBackB;
            } else {
                pegToken.safeTransfer(msg.sender, sendBackB);
            }
        }

        if (wethBack > 0) {
            (bool sent,) = msg.sender.call{value: wethBack}("");
		
            require(sent, "Failed to send ETH");
        }

        uint256 fee = lpAmount / 100;
        (, uint256 feeMulti) = userFee(msg.sender);

        fee = (fee * feeMulti) / 10;

        uint256 afterFee = lpAmount - fee;
        lpTokenAddr = IFactory(FACTORY).getPair(WETH, myTokenAddr());

        IERC20(lpTokenAddr).safeTransfer(msg.sender, afterFee);
        IERC20(lpTokenAddr).safeTransfer(address(1), fee);
    }

    /**
     * Calls the reduced method of the feeReducer except if the address is an LP of the myToken.
	 * Otherwise someone could send myShare tokens to the LP and reduce the fee for everyone who is swapping with the LP.
	 *
     * @param user address which is checked
     * @return reduced 'true' if checking is reduced
     */
    function isReduced(address user) public view returns (bool reduced) {
        if (myToken.isLP(user) == false) {
            reduced = feeReducer.isReduced(user);
        }
    }

    /**
     * Makes it possible to change the wrapper and transfer the pegToken amount to the new contract.
	 *
     * @notice The new wrapper needs to be set on the myToken first for having a small barrier against malicious/wrong useage.
	 *
     * @param newWrapper address which is checked
     */
    function changeWrapper(address newWrapper) external onlyOwner {
        require(myToken.wrapper() == newWrapper, "The new wrapper needs to be set on the myToken first");

        if (address(pegToken) == WETH) {
            (bool sent,) = newWrapper.call{value: address(this).balance}("");
		
            require(sent, "Failed to send ETH");
        } else {
            IERC20(pegToken).safeTransfer(newWrapper, pegToken.balanceOf(address(this)));
        }
    }

    /**
     * Gives the owner the possibility to withdraw tokens which are airdroped or send by mistake to this contract, except the staked tokens.
     *
     * @notice - This contract uses native tokens, so it is possible to withdraw the wrapped version of it (not myToken version)
	 *
     * @param to recipient of the tokens
     * @param tokenAddr token contract
     */
    function daoWithdrawERC(address to, address tokenAddr) external onlyOwner {
        require((   address(pegToken) == tokenAddr && tokenAddr == WETH) ||
                    address(pegToken) != tokenAddr,
                    "You cannot withdraw the staked tokens");

        IERC20(tokenAddr).safeTransfer(to, IERC20(tokenAddr).balanceOf(address(this)));
    }

    /**
     * Gives the owner the possibility to withdraw ETH which are airdroped or send by mistake to this contract.
     *
     * @param to recipient of the tokens
     */
    function daoWithdrawETH(address to) external onlyOwner {
        require(address(pegToken) != WETH, "You cannot withdraw the staked tokens");
        (bool sent,) = to.call{value: address(this).balance}("");
		
        require(sent, "Failed to send ETH");
    }

    /**
     * Receives native token.
     */
    receive() external payable {
        // ...
    }
}
// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./UniswapInterfaces.sol";


contract StratManager is Ownable, Pausable {
    using SafeERC20 for IERC20;

    uint256 constant public MAX_FEE = 1000;

    /**
     * @dev Contracts:
     * {safeFarm} - Address of the safeFarm that controls the strategy's funds.
     * {unirouter} - Address of exchange to execute swaps.
     */
    address public safeFarm;
    address public unirouter;

    address public want;
    address public output;
    address public wbnb;

    address[] public outputToWbnbRoute;

    // Fee
    uint256 public poolFee = 30; // 3%

    uint256 public callFee = 0;
    address public callFeeRecipient;
    // strategistFee = (100% - callFee - frfiFee)

    uint256 public frfiFee = 0;
    address public frfiFeeRecipient;

    address public strategistFeeRecipient;

    uint256 public safeFarmFee = 0;
    address public safeFarmFeeRecipient;

    uint256 public treasuryFee = 0;
    address public treasuryFeeRecipient;

    uint256 public systemFee = 0;
    address public systemFeeRecipient;

    /**
     * @dev Event that is fired each time someone harvests the strat.
     */
    event StratHarvest(address indexed harvester);
    event ChargedFees(uint256 callFees, uint256 frfiFees, uint256 strategistFees);
    event SafeSwap(address indexed tokenAddress, address indexed account, uint256 amount);

    /**
     * @dev Initializes the base strategy.
     * @param _unirouter router to use for swaps
     */
    constructor(
        address _unirouter,
        address _want,
        address _output,
        address _wbnb,

        address _callFeeRecipient,
        address _frfiFeeRecipient,
        address _strategistFeeRecipient,

        address _safeFarmFeeRecipient,

        address _treasuryFeeRecipient,
        address _systemFeeRecipient
    ) {
        unirouter = _unirouter;

        want = _want;
        output = _output;
        wbnb = _wbnb;

        if (output != wbnb) {
            outputToWbnbRoute = [output, wbnb];
        }

        callFeeRecipient = _callFeeRecipient;
        frfiFeeRecipient = _frfiFeeRecipient;
        strategistFeeRecipient = _strategistFeeRecipient;

        safeFarmFeeRecipient = _safeFarmFeeRecipient;

        treasuryFeeRecipient = _treasuryFeeRecipient;
        systemFeeRecipient = _systemFeeRecipient;
    }

    // verifies that the caller is not a contract.
    modifier onlyEOA() {
        require(
            msg.sender == tx.origin
            || msg.sender == address(safeFarm)
            , "!EOA");
        _;
    }
    modifier onlySafeFarm() {
        require(msg.sender == address(safeFarm), "!safeFarm");
        _;
    }

// RESTRICTED FUNCTIONS

    /*function initialize(address _safeFarm) public onlyOwner {
        safeFarm = _safeFarm;
    }*/

    function migrate(address newSafeFarm) external onlySafeFarm {
        safeFarm = newSafeFarm;
    }

    function pause() public onlyOwner {
        _pause();
        _removeAllowances();
    }

    function unpause() external onlyOwner {
        _unpause();
        _giveAllowances();
        deposit();
    }


    /**
     * @dev Updates router that will be used for swaps.
     * @param _unirouter new unirouter address.
     */
    function setUnirouter(address _unirouter) external onlyOwner {
        _removeAllowances();
        unirouter = _unirouter;
        _giveAllowances();
    }

    function setPoolFee(uint256 _poolFee) external onlyOwner {
        poolFee = _poolFee;
    }

    function setCallFee(uint256 _callFee, address _callFeeRecipient) external onlyOwner {
        callFee = _callFee;
        callFeeRecipient = _callFeeRecipient;
    }

    function setFrfiFee(uint256 _frfiFee, address _frfiFeeRecipient) external onlyOwner {
        frfiFee = _frfiFee;
        frfiFeeRecipient = _frfiFeeRecipient;
    }

    function setWithdrawFees(
        uint256 _systemFee,
        uint256 _treasuryFee,
        address _systemFeeRecipient,
        address _treasuryFeeRecipient
    ) external onlyOwner {
        require(_systemFeeRecipient != address(0), "systemFeeRecipient the zero address");
        require(_treasuryFeeRecipient != address(0), "treasuryFeeRecipient the zero address");

        systemFee = _systemFee;
        systemFeeRecipient = _systemFeeRecipient;
        treasuryFee = _treasuryFee;
        treasuryFeeRecipient = _treasuryFeeRecipient;
    }

    function setSafeFarmFee(
        uint256 _safeFarmFee,
        address _safeFarmFeeRecipient
    ) external onlyOwner {
        require(_safeFarmFeeRecipient != address(0), "safeFarmFeeRecipient the zero address");

        safeFarmFee = _safeFarmFee;
        safeFarmFeeRecipient = _safeFarmFeeRecipient;
    }

// PUBLIC VIEW FUNCTIONS

    // calculate shares amount by total
    function calcSharesAmount(
        uint256 share, uint256 totalShares
    ) public view returns (uint256 amount) {
        amount = balanceOf() * share / totalShares;
        return amount;
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // calculate the total underlaying 'want' held by the strat + pool + pending reward.
    function balance() public view virtual returns (uint256) {
        return balanceOfWant() + balanceOf() + pendingReward();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates SafeFarmFee by amount
    function safeFarmFeeAmount(uint256 amount) public view returns (uint256) {
        return (amount * safeFarmFee / MAX_FEE);
    }

// INTERNAL FUNCTIONS

    function _chargeFees() internal returns (uint256) {
        uint256 allBal = IERC20(output).balanceOf(address(this));
        if (allBal == 0) return 0;

        uint256 toNative = allBal * poolFee / MAX_FEE;
        if (output != wbnb) {
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(
                toNative,
                0,
                outputToWbnbRoute,
                address(this),
                block.timestamp
            );
        }

        uint256 nativeBal = IERC20(wbnb).balanceOf(address(this));
        _sendPoolFees(nativeBal);

        return (allBal - toNative);
    }

    function _sendPoolFees(uint256 nativeBal) internal {
        uint256 callFeeAmount = nativeBal * callFee / MAX_FEE;
        if (callFeeAmount > 0) {
            IERC20(wbnb).safeTransfer(callFeeRecipient, callFeeAmount);
        }

        uint256 frfiFeeAmount = nativeBal * frfiFee / MAX_FEE;
        if (frfiFeeAmount > 0) {
            IERC20(wbnb).safeTransfer(frfiFeeRecipient, frfiFeeAmount);
        }

        uint256 strategistFeeAmount = nativeBal - callFeeAmount - frfiFeeAmount;
        if (strategistFeeAmount > 0) {
            IERC20(wbnb).safeTransfer(strategistFeeRecipient, strategistFeeAmount);
        }

        emit ChargedFees(callFeeAmount, frfiFeeAmount, strategistFeeAmount);
    }

    function _safeSwap(
        address account, uint256 amount, address[] memory route,
        uint256 feeAdd
    ) internal {
        address tokenB = route[route.length - 1];
        uint256 amountB;
        if (route.length == 1 || tokenB == want) {
            amountB = amount;
        }
        else {
            uint[] memory amounts = IUniswapRouterETH(unirouter).swapExactTokensForTokens(
                amount,
                0,
                route,
                address(this),
                block.timestamp
            );
            amountB = amounts[amounts.length - 1];
        }

        uint256 feeAmount = safeFarmFeeAmount(amountB) + feeAdd;
        require(amountB > feeAmount, "low profit amount");

        uint256 withdrawalAmount = amountB - feeAmount;

        IERC20(tokenB).safeTransfer(account, withdrawalAmount);
        if (feeAmount > 0) {
            IERC20(tokenB).safeTransfer(safeFarmFeeRecipient, feeAmount);
        }

        emit SafeSwap(tokenB, account, withdrawalAmount);
    }

    function _getWantBalance(uint256 amount) internal returns(uint256 wantBal) {
        wantBal = balanceOfWant();

        if (wantBal < amount) {
            _withdrawAmountOfWant(amount - wantBal);
            wantBal = balanceOfWant();
        }

        if (wantBal > amount) {
            wantBal = amount;
        }

        return wantBal;
    }

// VIRTUAL

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view virtual returns (uint256) {}
    function pendingReward() public view virtual returns (uint256) {}

    function deposit() public virtual whenNotPaused {}

    function _withdrawAmountOfWant(uint256 amount) internal virtual {}

    function _giveAllowances() internal virtual {}
    function _removeAllowances() internal virtual {}
}
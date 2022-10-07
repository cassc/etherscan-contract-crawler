// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./UniswapInterfaces.sol";


contract StratManager is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 constant public MAX_FEE = 1000;

    /**
     * @dev Contracts:
     * {keeper} - Address to manage a few lower risk features of the strat
     * {safeFarm} - Address of the safeFarm that controls the strategy's funds.
     * {unirouter} - Address of exchange to execute swaps.
     */
    address public keeper;
    address public unirouter;
    address public safeFarm;

    address public want;
    address public output;
    address public wbnb;

    address[] public outputToWbnbRoute;

    // Fee
    uint256 public poolFee = 23; // 2.3%

    uint256 public callFee;
    address public callFeeRecipient;
    // strategistFee = (100% - callFee - frfiFee)

    uint256 public frfiFee;
    address public frfiFeeRecipient;

    uint256 public systemFee;
    address public systemFeeRecipient;

    uint256 public treasuryFee;
    address public treasuryFeeRecipient;

    uint256 public safeFarmFee;
    address public safeFarmFeeRecipient;

    address public strategistFeeRecipient;

    /**
     * @dev Event that is fired each time someone harvests the strat.
     */
    event StratHarvest(address indexed harvester);
    event ChargedFees(uint256 callFees, uint256 frfiFees, uint256 strategistFees);
    event SafeSwap(address tokenAddress, address account, uint256 amount);

    /**
     * @dev Initializes the base strategy.
     * @param _keeper address to use as alternative owner.
     * @param _unirouter router to use for swaps
     */
    constructor(
        address _keeper,
        address _unirouter,
        address _want,
        address _output,
        address _wbnb,

        uint256 _callFee,
        uint256 _frfiFee,
        // strategistFee = (100% - callFee - frfiFee)

        address _callFeeRecipient,
        address _frfiFeeRecipient,
        address _strategistFeeRecipient

    ) {
        keeper = _keeper;
        unirouter = _unirouter;

        want = _want;
        output = _output;
        wbnb = _wbnb;

        if (output != wbnb) {
            outputToWbnbRoute = [output, wbnb];
        }

        callFee = _callFee;
        callFeeRecipient = _callFeeRecipient;
        frfiFee = _frfiFee;
        frfiFeeRecipient = _frfiFeeRecipient;
        strategistFeeRecipient = _strategistFeeRecipient;
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    // verifies that the caller is not a contract.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }
    modifier onlySafeFarm() {
        require(msg.sender == address(safeFarm), "!safeFarm");
        _;
    }

    // RESTRICTED FUNCTIONS

    function migrate(address newSafeFarm) external onlySafeFarm {
        safeFarm = newSafeFarm;
    }

    /*function initialize(address _safeFarm) public onlyOwner {
        safeFarm = _safeFarm;
    }*/

    /**
     * @dev Updates address of the strat keeper.
     * @param _keeper new keeper address.
     */
    function setKeeper(address _keeper) external onlyManager {
        keeper = _keeper;
    }

    /**
     * @dev Updates router that will be used for swaps.
     * @param _unirouter new unirouter address.
     */
    function setUnirouter(address _unirouter) external onlyOwner {
        unirouter = _unirouter;
    }

    function setPoolFee(uint256 _poolFee) external onlyOwner {
        poolFee = _poolFee;
    }

    function setCallFee(uint256 _callFee) external onlyOwner {
        callFee = _callFee;
    }

    function setFrfiFee(uint256 _frfiFee) external onlyOwner {
        frfiFee = _frfiFee;
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

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }


    function _chargeFees() internal returns (uint256) {
        uint256 allBal = IERC20(output).balanceOf(address(this));
        uint256 toNative = allBal.mul(poolFee).div(MAX_FEE);
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

        uint256 callFeeAmount = nativeBal.mul(callFee).div(MAX_FEE);
        if (callFeeAmount > 0) {
            IERC20(wbnb).safeTransfer(callFeeRecipient, callFeeAmount);
        }

        uint256 frfiFeeAmount = nativeBal.mul(frfiFee).div(MAX_FEE);
        if (frfiFeeAmount > 0) {
            IERC20(wbnb).safeTransfer(frfiFeeRecipient, frfiFeeAmount);
        }

        uint256 strategistFeeAmount = nativeBal.sub(callFeeAmount).sub(frfiFeeAmount);
        if (strategistFeeAmount > 0) {
            IERC20(wbnb).safeTransfer(strategistFeeRecipient, strategistFeeAmount);
        }

        emit ChargedFees(callFeeAmount, frfiFeeAmount, strategistFeeAmount);
        return (allBal - toNative);
    }

    function _safeSwap(
        address account, uint256 amount, address[] memory route,
        uint256 feeAdd
    ) internal {
        address tokenB = route[route.length - 1];
        uint256 amountB;
        if (tokenB == want) {
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

        uint256 feeAmount = safeFarmFeeAmount(amountB).add(feeAdd);
        require(amountB > feeAmount, "low profit amount");

        uint256 withdrawalAmount = amountB.sub(feeAmount);

        IERC20(tokenB).safeTransfer(account, withdrawalAmount);
        if (feeAmount > 0) {
            IERC20(tokenB).safeTransfer(safeFarmFeeRecipient, feeAmount);
        }

        emit SafeSwap(tokenB, account, withdrawalAmount);
    }

    function safeFarmFeeAmount(uint256 amount) public view returns (uint256) {
        return amount.mul(safeFarmFee).div(MAX_FEE);
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

    function _withdrawAmountOfWant(uint256 amount) internal virtual {}
}
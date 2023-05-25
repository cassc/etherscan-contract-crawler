// SPDX-License-Identifier: UNLICENSED
// Copyright 2023 Shipyard Software, Inc.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/SanctionsList.sol";

contract ClipperProtocolDeposit is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    uint256 private constant ONE_IN_TEN_DECIMALS = 1e10;
    uint256 private constant MAXIMUM_DAO_WITHDRAWAL_IN_TEN_DECIMALS = ONE_IN_TEN_DECIMALS/20;
    uint256 private constant MINIMUM_DURATION_BETWEEN_DAO_FEE_WITHDRAWAL = 7 days;

    address public immutable CLIPPER_EXCHANGE;
    address public immutable SANCTIONS_REGISTRY;

    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    uint256 public lastDaoWithdrawal;

    event LPWithdrawn(
        address indexed depositor,
        uint256 clipperLPWithdrawn,
        uint256 shadowTokensBurned
    );

    event LPDeposited(
        address indexed depositor,
        uint256 clipperLPDeposited,
        uint256 shadowTokensMinted
    );

    event FeesTaken(
        uint256 entitledFeesInDollars,
        uint256 averagePoolBalanceInDollars,
        uint256 tokensTransferred
    );

    error DAOFeeSplitTooMuch();
    error DAOFeeSplitTooSoon();
    error InvalidWithdrawal();
    error ZeroAddressShadowTokenOperation();
    error SanctionedSender();

    modifier onlyUnsanctionedSenders {
        if(SanctionsList(SANCTIONS_REGISTRY).isSanctioned(msg.sender)){
            revert SanctionedSender();
        }
        _;
    }


    constructor(address theExchange, address theSanctionsContract) {
        CLIPPER_EXCHANGE = theExchange;
        SANCTIONS_REGISTRY = theSanctionsContract;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        if(account == address(0)){
            revert ZeroAddressShadowTokenOperation();
        }

        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _burn(address account, uint256 amount) internal virtual {
        if(account == address(0)){
            revert ZeroAddressShadowTokenOperation();
        }

        uint256 accountBalance = _balances[account];
        if(accountBalance < amount){
            revert InvalidWithdrawal();
        }
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
    }

    function _tokensForAlreadyMadeLPDeposit(uint256 amount) internal view returns (uint256) {
        uint256 balanceBeforeDeposit = _lpTokenBalance()-amount;
        // totalSupply check avoids issues around sending in more tokens first
        uint256 _supply = totalSupply();
        if(balanceBeforeDeposit==0 || _supply ==0){
            return amount;
        } else {
            return (amount*_supply)/balanceBeforeDeposit;
        }
    }

    function _lpTokensFromBurn(uint256 burnAmount) internal view returns (uint256) {
        uint256 _supply = totalSupply();
        if(_supply > 0){
            return (burnAmount*_lpTokenBalance())/_supply;
        } else {
            return 0;
        }
    }

    function _lpTokenBalance() internal view returns (uint256) {
        return IERC20(CLIPPER_EXCHANGE).balanceOf(address(this));
    }

    function takeFees(uint256 entitledFeesInDollars, uint256 averagePoolBalanceInDollars) external onlyOwner {
        // calculate fraction in base ten
        uint256 theFraction = (ONE_IN_TEN_DECIMALS*entitledFeesInDollars)/averagePoolBalanceInDollars;
        // Check: less than the max?
        if(theFraction > MAXIMUM_DAO_WITHDRAWAL_IN_TEN_DECIMALS) {
            revert DAOFeeSplitTooMuch();
        }
        // Check: OK to send?
        if(block.timestamp < lastDaoWithdrawal+MINIMUM_DURATION_BETWEEN_DAO_FEE_WITHDRAWAL){
            revert DAOFeeSplitTooSoon();
        }
        // Effects
        lastDaoWithdrawal = block.timestamp;

        // Interactions
        uint256 tokensToTransfer = (theFraction*_lpTokenBalance())/ONE_IN_TEN_DECIMALS;
        IERC20(CLIPPER_EXCHANGE).safeTransfer(msg.sender, tokensToTransfer);
        
        emit FeesTaken(entitledFeesInDollars, averagePoolBalanceInDollars, tokensToTransfer);
    }

    // Allows for proxy and helper contracts to deposit on behalf of the user
    function depositClipperLPFor(address account, uint256 amountOfClipperLP) public nonReentrant onlyUnsanctionedSenders {
        IERC20(CLIPPER_EXCHANGE).safeTransferFrom(msg.sender, address(this), amountOfClipperLP);

        uint256 shadowTokensMinted = _tokensForAlreadyMadeLPDeposit(amountOfClipperLP);
        _mint(account, shadowTokensMinted);

        emit LPDeposited(account, amountOfClipperLP, shadowTokensMinted);
    }

    function depositClipperLP(uint256 amountOfClipperLP) external {
        depositClipperLPFor(msg.sender, amountOfClipperLP);
    }

    function currentEffectiveLPTokenBalanceForUser(address user) external view returns (uint256) {
        uint256 _myDeposit = balanceOf(user);
        return _lpTokensFromBurn(_myDeposit);
    }

    function _withdraw(uint256 shadowTokensToBurn) internal {
        if(shadowTokensToBurn == 0){
            revert InvalidWithdrawal();
        }
        uint256 clipperLPtoWithdraw = _lpTokensFromBurn(shadowTokensToBurn);
        // Effects. Reverts if burn is too much.
        _burn(msg.sender, shadowTokensToBurn);

        // Interactions
        IERC20(CLIPPER_EXCHANGE).safeTransfer(msg.sender, clipperLPtoWithdraw);

        emit LPWithdrawn(msg.sender, clipperLPtoWithdraw, shadowTokensToBurn);
    }

    function withdraw() external nonReentrant {
        // Checks
        uint256 _myDeposit = balanceOf(msg.sender);
        _withdraw(_myDeposit);
    }

    function withdrawPartial(uint256 shadowTokensToBurn) external nonReentrant {
        _withdraw(shadowTokensToBurn);
    }

}
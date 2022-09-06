//SPDX-License-Identifier: Copyright 2022 Shipyard Software, Inc.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ClipperCommonExchange.sol";
import "./interfaces/SanctionsList.sol";

contract FeeSplit is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    uint256 private constant ONE_IN_TEN_DECIMALS = 1e10;
    uint256 private constant MAXIMUM_DAO_WITHDRAWAL_IN_TEN_DECIMALS = ONE_IN_TEN_DECIMALS/20;
    uint256 private constant MINIMUM_DURATION_BETWEEN_DAO_FEE_WITHDRAWAL = 7 days;
    address private constant CLIPPER_ETH_SIGIL = address(0);

    address payable public immutable CLIPPER_EXCHANGE;
    address public immutable SANCTIONS_REGISTRY;

    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    uint256 public lastDaoWithdrawal;

    modifier onlyUnsanctionedSenders {
        require(!SanctionsList(SANCTIONS_REGISTRY).isSanctioned(msg.sender), "Sanctioned sender");
        _;
    }

    event LPWithdrawn(
        address indexed depositor,
        uint256 depositAmount,
        uint256 withdrawnTokens
    );

    event LPDeposited(
        address indexed depositor,
        uint256 depositAmount
    );

    event FeesTaken(
        uint256 entitledFeesInDollars,
        uint256 averagePoolBalanceInDollars,
        uint256 tokensTransferred
    );

    constructor(address theExchange, address theSanctionsContract) {
        CLIPPER_EXCHANGE = payable(theExchange);
        SANCTIONS_REGISTRY = theSanctionsContract;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
    }

    function _tokensForAlreadyMadeLPDeposit(uint256 amount) internal view returns (uint256) {
        uint256 balanceBeforeDeposit = _lpTokenBalance()-amount;
        // totalSupply check avoids issues around sending in more tokens first 
        if(balanceBeforeDeposit==0 || totalSupply()==0){
            return amount;
        } else {
            return (amount*totalSupply())/balanceBeforeDeposit;
        }
    }

    function _lpTokensFromBurn(uint256 burnAmount) internal view returns (uint256) {
        return (burnAmount*_lpTokenBalance())/totalSupply();
    }

    function _lpTokenBalance() internal view returns (uint256) {
        return IERC20(CLIPPER_EXCHANGE).balanceOf(address(this));
    }

    function takeFees(uint256 entitledFeesInDollars, uint256 averagePoolBalanceInDollars) external onlyOwner {
        // calculate fraction in base ten
        uint256 theFraction = (ONE_IN_TEN_DECIMALS*entitledFeesInDollars)/averagePoolBalanceInDollars;
        // Check: less than the max?
        require(theFraction <= MAXIMUM_DAO_WITHDRAWAL_IN_TEN_DECIMALS, "Too much");
        // Check: OK to send?
        require(block.timestamp >= lastDaoWithdrawal+MINIMUM_DURATION_BETWEEN_DAO_FEE_WITHDRAWAL, "Too soon");
        // Effects
        lastDaoWithdrawal = block.timestamp;

        // Interactions
        uint256 tokensToTransfer = (theFraction*_lpTokenBalance())/ONE_IN_TEN_DECIMALS;
        IERC20(CLIPPER_EXCHANGE).safeTransfer(msg.sender, tokensToTransfer);
        
        emit FeesTaken(entitledFeesInDollars, averagePoolBalanceInDollars, tokensToTransfer);
    }

    function depositClipperLP(uint256 amount) external nonReentrant onlyUnsanctionedSenders {
        IERC20(CLIPPER_EXCHANGE).safeTransferFrom(msg.sender, address(this), amount);
    
        _mint(msg.sender, _tokensForAlreadyMadeLPDeposit(amount));

        emit LPDeposited(msg.sender, amount);
    }

    // Use CLIPPER_ETH_SIGIL if depositing raw native token as msg.value
    function depositClipperAsset(address clipperAsset, uint256 depositAmount, uint256 poolTokens, uint256 goodUntil, ClipperCommonExchange.Signature memory theSignature) external payable nonReentrant onlyUnsanctionedSenders {
        if(clipperAsset != CLIPPER_ETH_SIGIL){
            IERC20(clipperAsset).safeTransferFrom(msg.sender, CLIPPER_EXCHANGE, depositAmount);
        } else {
            clipperAsset = ClipperCommonExchange(CLIPPER_EXCHANGE).WRAPPER_CONTRACT();
        }
        ClipperCommonExchange(CLIPPER_EXCHANGE).depositSingleAsset{ value:msg.value }(address(this), clipperAsset, depositAmount, 0, poolTokens, goodUntil, theSignature);
    
        _mint(msg.sender, _tokensForAlreadyMadeLPDeposit(poolTokens));

        emit LPDeposited(msg.sender, poolTokens);
    }

    function currentEffectiveLPTokenBalanceForUser(address user) external view returns (uint256) {
        uint256 _myDeposit = balanceOf(user);
        return _lpTokensFromBurn(_myDeposit);
    }

    function _withdraw(uint256 amount) internal {
        require(amount > 0, "Withdrawal amount must be positive");
        uint256 tokensToWithdraw = _lpTokensFromBurn(amount);
        // Effects. Reverts if burn is too much.
        _burn(msg.sender, amount);

        // Interactions
        IERC20(CLIPPER_EXCHANGE).safeTransfer(msg.sender, tokensToWithdraw);

        emit LPWithdrawn(msg.sender, amount, tokensToWithdraw);
    }

    function withdraw() external nonReentrant {
        // Checks
        uint256 _myDeposit = balanceOf(msg.sender);
        _withdraw(_myDeposit);
    }

    function withdrawPartial(uint256 amount) external nonReentrant {
        _withdraw(amount);
    }

}
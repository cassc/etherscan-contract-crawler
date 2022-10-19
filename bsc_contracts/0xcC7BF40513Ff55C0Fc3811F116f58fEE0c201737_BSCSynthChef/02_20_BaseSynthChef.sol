// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.15;

import "../Lender.sol";
import "../PausableAccessControl.sol";
import "../interfaces/IEntangleDEXWrapper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

abstract contract BaseSynthChef is PausableAccessControl, Lender {
    using SafeERC20 for IERC20;

    struct TokenAmount {
        uint256 amount;
        address token;
    }

    IEntangleDEXWrapper public DEXWrapper;
    address public stablecoin;
    address[] internal rewardTokens;
    address public feeCollector;

    uint256 fee;
    uint256 feeRate = 1000000;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    event Deposit(uint256 indexed pid, uint256 amount, uint256 opId);
    event Withdraw(uint256 indexed pid, uint256 amount, uint256 opId);
    event Compound(uint256 indexed pid, uint256 amountStable);

    constructor(
        address _DEXWrapper,
        address _stablecoin,
        address[] memory _rewardTokens,
        uint256 _fee,
        address _feeCollector
    ) {
        DEXWrapper = IEntangleDEXWrapper(_DEXWrapper);
        stablecoin = _stablecoin;
        rewardTokens = _rewardTokens;
        fee = _fee;
        feeCollector = _feeCollector;

        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(BORROWER_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, address(this)); // needed for calling this.deposit in compound
        _setupRole(OWNER_ROLE, msg.sender);
    }

    function deposit(
        uint256 _pid,
        address _tokenFrom,
        uint256 _amount,
        uint256 _opId
    ) public onlyRole(ADMIN_ROLE) whenNotPaused {
        if (msg.sender != address(this))
            IERC20(_tokenFrom).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 amountLPs = _addLiquidity(_pid, _tokenFrom, _amount);
        _depositToFarm(_pid, amountLPs);
        emit Deposit(_pid, _amount, _opId);
    }

    function withdraw(
        uint256 _pid,
        address _toToken,
        uint256 _amount,
        address _to,
        uint256 _opId
    ) public onlyRole(ADMIN_ROLE) whenNotPaused {
        uint256 _stablecoinAmount = _previewConvertTokens(_toToken, address(stablecoin), _amount);
        uint256 _amountLP = _convertStablecoinAmountToLPAmount(_pid, _stablecoinAmount);
        _withdrawFromFarm(_pid, _amountLP);
        TokenAmount[] memory tokens = _removeLiquidity(_pid, _amountLP);
        uint256 tokenAmount = 0;
        for (uint i = 0; i < tokens.length; i++) {
            tokenAmount += _convertTokens(
                tokens[i].token,
                _toToken,
                tokens[i].amount
            );
        }
        IERC20(_toToken).safeTransfer(_to, tokenAmount);
        emit Withdraw(_pid, _amount, _opId);
    }

    function compound(uint256 _pid) public onlyRole(ADMIN_ROLE) whenNotPaused {
        _harvest(_pid);
        for (uint i = 0; i < rewardTokens.length; i++) {
            uint256 balance = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (balance > 0) {
                uint256 feeAmount = (balance * fee) / feeRate;
                this.deposit(
                    _pid,
                    address(rewardTokens[i]),
                    balance - feeAmount,
                    0
                );
                IERC20(rewardTokens[i]).safeTransfer(feeCollector, feeAmount);
            }
        }
        emit Compound(_pid, getBalanceOnFarm(_pid));
    }

    function convertTokenToStablecoin(address _tokenAddress, uint256 _amount)
        internal
        view
        returns (uint256 amountStable)
    {
        if (_tokenAddress == stablecoin) return _amount;
        return _previewConvertTokens(_tokenAddress, stablecoin, _amount);
    }

    function convertStablecoinToToken(
        address _tokenAddress,
        uint256 _amountStablecoin
    ) internal view returns (uint256 amountToken) {
        if (_tokenAddress == stablecoin) return _amountStablecoin;
        return
            _previewConvertTokens(stablecoin, _tokenAddress, _amountStablecoin);
    }

    function getBalanceOnFarm(uint256 _pid)
        public
        view
        returns (uint256 totalAmount)
    {
        TokenAmount[] memory tokens = _getTokensInLP(_pid);
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i].amount > 0) {
                totalAmount += convertTokenToStablecoin(
                    tokens[i].token,
                    tokens[i].amount
                );
            }
        }
    }

    function _convertStablecoinAmountToLPAmount(uint256 _pid, uint256 _amount) internal view returns(uint256 amountLP) {
        uint256 totalLPAmount = getLPAmountOnFarm(_pid);
        uint256 totalStablecoinAmount = getBalanceOnFarm(_pid);
        return totalLPAmount * _amount / totalStablecoinAmount;
    }

    function _harvest(uint256 _pid) internal virtual;

    function _withdrawFromFarm(uint256 _pid, uint256 _amount) internal virtual;

    function _depositToFarm(uint256 _pid, uint256 _amount) internal virtual;

    function _removeLiquidity(uint256 _pid, uint256 _amount)
        internal
        virtual
        returns (TokenAmount[] memory tokenAmounts);

    function _addLiquidity(
        uint256 _pid,
        address _tokenFrom,
        uint256 _amount
    ) internal virtual returns (uint256 LPAmount);

    function _getTokensInLP(uint256 _pid)
        internal
        view
        virtual
        returns (TokenAmount[] memory tokens);
    
    function getLPAmountOnFarm(uint256 _pid)
        public
        view
        virtual
        returns (uint256 amount);

    function _convertTokens(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (from == to) return amount;
        if (
            IERC20(from).allowance(address(this), address(DEXWrapper)) < amount
        ) {
            IERC20(from).safeIncreaseAllowance(address(DEXWrapper), type(uint256).max);
        }
        return DEXWrapper.convert(from, to, amount);
    }

    function _previewConvertTokens(
        address from,
        address to,
        uint256 amount
    ) internal view returns (uint256) {
        return DEXWrapper.previewConvert(from, to, amount);
    }

    function setFee(uint256 _fee) public onlyRole(ADMIN_ROLE) {
        fee = _fee;
    }

    function setFeeCollector(address _feeCollector)
        public
        onlyRole(ADMIN_ROLE)
    {
        feeCollector = _feeCollector;
    }

    function setRewardTokens(address[] memory _rewardTokens)
        public
        onlyRole(ADMIN_ROLE)
    {
        rewardTokens = _rewardTokens;
    }

    function setDEXWrapper(IEntangleDEXWrapper _DEXWrapper)
        public
        onlyRole(ADMIN_ROLE)
    {
        DEXWrapper = _DEXWrapper;
    }
}
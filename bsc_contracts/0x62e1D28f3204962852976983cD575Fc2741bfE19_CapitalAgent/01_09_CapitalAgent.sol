// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISalesPolicy.sol";
import "./interfaces/IExchangeAgent.sol";
import "./interfaces/ISingleSidedInsurancePool.sol";
import "./interfaces/ICapitalAgent.sol";

contract CapitalAgent is ICapitalAgent, ReentrancyGuard, Ownable {
    address public exchangeAgent;
    address public salesPolicyFactory;
    address public USDC_TOKEN;
    address public operator;

    struct PoolInfo {
        uint256 totalCapital;
        uint256 SCR;
        address currency;
        bool exist;
    }

    struct PolicyInfo {
        address policy;
        uint256 utilizedAmount;
        bool exist;
    }

    mapping(address => PoolInfo) public poolInfo;
    address[] private poolList;

    PolicyInfo public policyInfo;

    uint256 public totalUtilizedAmount;

    uint256 public MCR;
    uint256 public MLR;

    uint256 public CALC_PRECISION = 1e18;

    mapping(address => bool) public poolWhiteList;

    event LogAddPool(address indexed _ssip, address _currency, uint256 _scr);
    event LogRemovePool(address indexed _ssip);
    event LogSetPolicy(address indexed _salesPolicy);
    event LogRemovePolicy(address indexed _salesPolicy);
    event LogUpdatePoolCapital(address indexed _ssip, uint256 _poolCapital, uint256 _totalCapital);
    event LogUpdatePolicyCoverage(
        address indexed _policy,
        uint256 _amount,
        uint256 _policyUtilized,
        uint256 _totalUtilizedAmount
    );
    event LogUpdatePolicyExpired(address indexed _policy, uint256 _policyTokenId);
    event LogMarkToClaimPolicy(address indexed _policy, uint256 _policyTokenId);
    event LogSetMCR(address indexed _owner, address indexed _capitalAgent, uint256 _MCR);
    event LogSetMLR(address indexed _owner, address indexed _capitalAgent, uint256 _MLR);
    event LogSetSCR(address indexed _owner, address indexed _capitalAgent, address indexed _pool, uint256 _SCR);
    event LogSetExchangeAgent(address indexed _owner, address indexed _capitalAgent, address _exchangeAgent);
    event LogSetSalesPolicyFactory(address indexed _factory);
    event LogAddPoolWhiteList(address indexed _pool);
    event LogRemovePoolWhiteList(address indexed _pool);
    event LogSetOperator(address indexed _operator);

    constructor(
        address _exchangeAgent,
        address _USDC_TOKEN,
        address _multiSigWallet,
        address _operator
    ) {
        require(_exchangeAgent != address(0), "UnoRe: zero exchangeAgent address");
        require(_USDC_TOKEN != address(0), "UnoRe: zero USDC address");
        require(_multiSigWallet != address(0), "UnoRe: zero multisigwallet address");
        exchangeAgent = _exchangeAgent;
        USDC_TOKEN = _USDC_TOKEN;
        operator = _operator;
        transferOwnership(_multiSigWallet);
    }

    modifier onlyPoolWhiteList() {
        require(poolWhiteList[msg.sender], "UnoRe: Capital Agent Forbidden");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "UnoRe: Capital Agent Forbidden");
        _;
    }

    function setSalesPolicyFactory(address _factory) external onlyOwner nonReentrant {
        require(_factory != address(0), "UnoRe: zero factory address");
        salesPolicyFactory = _factory;
        emit LogSetSalesPolicyFactory(_factory);
    }

    function setOperator(address _operator) external onlyOwner nonReentrant {
        require(_operator != address(0), "UnoRe: zero operator address");
        operator = _operator;
        emit LogSetOperator(_operator);
    }

    function addPoolWhiteList(address _pool) external onlyOwner nonReentrant {
        require(_pool != address(0), "UnoRe: zero pool address");
        require(!poolWhiteList[_pool], "UnoRe: white list already");
        poolWhiteList[_pool] = true;
        emit LogAddPoolWhiteList(_pool);
    }

    function removePoolWhiteList(address _pool) external onlyOwner nonReentrant {
        require(_pool != address(0), "UnoRe: zero pool address");
        require(poolWhiteList[_pool], "UnoRe: no white list");
        poolWhiteList[_pool] = false;
        emit LogRemovePoolWhiteList(_pool);
    }

    function addPool(
        address _ssip,
        address _currency,
        uint256 _scr
    ) external override onlyPoolWhiteList {
        require(_ssip != address(0), "UnoRe: zero address");
        require(!poolInfo[_ssip].exist, "UnoRe: already exist pool");
        poolInfo[_ssip] = PoolInfo({totalCapital: 0, currency: _currency, SCR: _scr, exist: true});
        poolList.push(_ssip);

        emit LogAddPool(_ssip, _currency, _scr);
    }

    function addPoolByAdmin(
        address _ssip,
        address _currency,
        uint256 _scr,
        uint256 _initCapital
    ) external onlyOwner {
        require(_ssip != address(0), "UnoRe: zero address");
        require(!poolInfo[_ssip].exist, "UnoRe: already exist pool");
        poolInfo[_ssip] = PoolInfo({totalCapital: _initCapital, currency: _currency, SCR: _scr, exist: true});
        poolList.push(_ssip);

        emit LogAddPool(_ssip, _currency, _scr);
    }

    function removePool(address _ssip) external onlyOwner nonReentrant {
        require(_ssip != address(0), "UnoRe: zero address");
        require(poolInfo[_ssip].exist, "UnoRe: no exit pool");
        delete poolInfo[_ssip];
        for (uint256 ii = 0; ii < poolList.length; ii++) {
            if (poolList[ii] == _ssip) {
                poolList[ii] = poolList[poolList.length - 1];
                poolList.pop();
                return;
            }
        }
        emit LogRemovePool(_ssip);
    }

    function setPolicy(address _policy) external override nonReentrant {
        require(salesPolicyFactory != address(0), "UnoRe: not set factory address yet");
        require(salesPolicyFactory == msg.sender, "UnoRe: only salesPolicyFactory can call");
        policyInfo = PolicyInfo({policy: _policy, utilizedAmount: 0, exist: true});

        emit LogSetPolicy(_policy);
    }

    function setPolicyByAdmin(address _policy) external onlyOwner nonReentrant {
        require(_policy != address(0), "UnoRe: zero address");
        policyInfo = PolicyInfo({policy: _policy, utilizedAmount: 0, exist: true});

        emit LogSetPolicy(_policy);
    }

    function removePolicy() external onlyOwner nonReentrant {
        require(policyInfo.exist, "UnoRe: no exit pool");
        totalUtilizedAmount = 0;
        address _policy = policyInfo.policy;
        policyInfo.policy = address(0);
        policyInfo.exist = false;
        policyInfo.utilizedAmount = 0;
        emit LogRemovePolicy(_policy);
    }

    function SSIPWithdraw(uint256 _withdrawAmount) external override nonReentrant {
        require(poolInfo[msg.sender].exist, "UnoRe: no exist ssip");
        require(_checkCapitalByMCRAndSCR(msg.sender, _withdrawAmount), "UnoRe: minimum capital underflow");
        _updatePoolCapital(msg.sender, _withdrawAmount, false);
    }

    function SSIPPolicyCaim(
        uint256 _withdrawAmount,
        uint256 _policyId,
        bool _isFinished
    ) external override nonReentrant {
        require(poolInfo[msg.sender].exist, "UnoRe: no exist ssip");
        _updatePoolCapital(msg.sender, _withdrawAmount, false);
        if (_isFinished) {
            _markToClaimPolicy(_policyId);
        }
    }

    function SSIPStaking(uint256 _stakingAmount) external override nonReentrant {
        require(poolInfo[msg.sender].exist, "UnoRe: no exist ssip");
        _updatePoolCapital(msg.sender, _stakingAmount, true);
    }

    function checkCapitalByMCR(address _pool, uint256 _withdrawAmount) external view override returns (bool) {
        return _checkCapitalByMCRAndSCR(_pool, _withdrawAmount);
    }

    function checkCoverageByMLR(uint256 _coverageAmount) external view override returns (bool) {
        return _checkCoverageByMLR(_coverageAmount);
    }

    function policySale(uint256 _coverageAmount) external override nonReentrant {
        require(msg.sender == policyInfo.policy, "UnoRe: only salesPolicy can call");
        require(policyInfo.exist, "UnoRe: no exist policy");
        require(_checkCoverageByMLR(_coverageAmount), "UnoRe: maximum leverage overflow");
        _updatePolicyCoverage(_coverageAmount, true);
    }

    function updatePolicyStatus(uint256 _policyId) external override nonReentrant {
        require(policyInfo.policy != address(0), "UnoRe: no exist salesPolicy");
        (uint256 _coverageAmount, uint256 _coverageDuration, uint256 _coverStartAt) = ISalesPolicy(policyInfo.policy)
            .getPolicyData(_policyId);
        bool isExpired = block.timestamp >= _coverageDuration + _coverStartAt;
        if (isExpired) {
            _updatePolicyCoverage(_coverageAmount, false);
            ISalesPolicy(policyInfo.policy).updatePolicyExpired(_policyId);
            emit LogUpdatePolicyExpired(policyInfo.policy, _policyId);
        }
    }

    function markToClaimPolicy(uint256 _policyId) external onlyOwner nonReentrant {
        _markToClaimPolicy(_policyId);
    }

    function _markToClaimPolicy(uint256 _policyId) private {
        require(policyInfo.policy != address(0), "UnoRe: no exist salesPolicy");
        (uint256 _coverageAmount, , ) = ISalesPolicy(policyInfo.policy).getPolicyData(_policyId);
        _updatePolicyCoverage(_coverageAmount, false);
        ISalesPolicy(policyInfo.policy).markToClaim(_policyId);
        emit LogMarkToClaimPolicy(policyInfo.policy, _policyId);
    }

    function _updatePoolCapital(
        address _pool,
        uint256 _amount,
        bool isAdd
    ) private {
        if (!isAdd) {
            require(poolInfo[_pool].totalCapital >= _amount, "UnoRe: pool capital overflow");
        }
        poolInfo[_pool].totalCapital = isAdd ? poolInfo[_pool].totalCapital + _amount : poolInfo[_pool].totalCapital - _amount;
        emit LogUpdatePoolCapital(_pool, poolInfo[_pool].totalCapital, totalCapitalStaked());
    }

    function _updatePolicyCoverage(uint256 _amount, bool isAdd) private {
        if (!isAdd) {
            require(policyInfo.utilizedAmount >= _amount, "UnoRe: policy coverage overflow");
        }
        policyInfo.utilizedAmount = isAdd ? policyInfo.utilizedAmount + _amount : policyInfo.utilizedAmount - _amount;
        totalUtilizedAmount = isAdd ? totalUtilizedAmount + _amount : totalUtilizedAmount - _amount;
        emit LogUpdatePolicyCoverage(policyInfo.policy, _amount, policyInfo.utilizedAmount, totalUtilizedAmount);
    }

    function _checkCapitalByMCRAndSCR(address _pool, uint256 _withdrawAmount) private view returns (bool) {
        address currency = poolInfo[_pool].currency;
        uint256 withdrawAmountInUSDC = _getUSDCValue(currency, _withdrawAmount);
        uint256 poolCapitalInUSDC = _getUSDCValue(currency, poolInfo[_pool].totalCapital);
        uint256 totalCapital = totalCapitalStaked();
        bool isMCRPass = totalCapital - withdrawAmountInUSDC >= (totalCapital * MCR) / CALC_PRECISION;
        bool isSCRPass = poolCapitalInUSDC - withdrawAmountInUSDC >= poolInfo[_pool].SCR;
        return isMCRPass && isSCRPass;
    }

    function _checkCoverageByMLR(uint256 _newCoverageAmount) private view returns (bool) {
        return totalUtilizedAmount + _newCoverageAmount <= (totalCapitalStaked() * MLR) / CALC_PRECISION;
    }

    function _getUSDCValue(address _currency, uint256 _amount) private view returns (uint256 convertedAmount) {
        if (_currency == USDC_TOKEN) {
            convertedAmount = _amount;
        } else {
            convertedAmount = _currency != address(0)
                ? IExchangeAgent(exchangeAgent).getNeededTokenAmount(_currency, USDC_TOKEN, _amount)
                : IExchangeAgent(exchangeAgent).getTokenAmountForETH(USDC_TOKEN, _amount);
        }
    }

    function totalCapitalStaked() public view returns (uint256) {
        uint256 totalCapital;
        for (uint256 ii = 0; ii < poolList.length; ii++) {
            address currency = poolInfo[poolList[ii]].currency;
            uint256 poolCapitalInUSDC = _getUSDCValue(currency, poolInfo[poolList[ii]].totalCapital);
            totalCapital += poolCapitalInUSDC;
        }
        return totalCapital;
    }

    function setMCR(uint256 _MCR) external onlyOperator nonReentrant {
        require(_MCR > 0, "UnoRe: zero mcr");
        MCR = _MCR;
        emit LogSetMCR(msg.sender, address(this), _MCR);
    }

    function setMLR(uint256 _MLR) external onlyOperator nonReentrant {
        require(_MLR > 0, "UnoRe: zero mlr");
        MLR = _MLR;
        emit LogSetMLR(msg.sender, address(this), _MLR);
    }

    function setSCR(uint256 _SCR, address _pool) external onlyOperator nonReentrant {
        require(_SCR > 0, "UnoRe: zero scr");
        poolInfo[_pool].SCR = _SCR;
        emit LogSetSCR(msg.sender, address(this), _pool, _SCR);
    }

    function setExchangeAgent(address _exchangeAgent) external onlyOwner nonReentrant {
        require(_exchangeAgent != address(0), "UnoRe: zero address");
        exchangeAgent = _exchangeAgent;
        emit LogSetExchangeAgent(msg.sender, address(this), _exchangeAgent);
    }
}
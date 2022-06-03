pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

import './libraries/FullMath.sol';

contract RubicSymbiosisProxy is ReentrancyGuard, AccessControl, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    address public metaRouter;
    address public gateway;
    uint256 public RubicFee;
    mapping(address => uint256) public availableRubicFee;

    mapping(address => mapping(address => uint256)) public amountOfIntegrator;
    mapping(address => uint256) public integratorFee;
    mapping(address => uint256) public platformShare;

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), 'RubicSymbiosisProxy: Caller is not in admin role');
        _;
    }

    modifier onlyManager() {
        require(isManager(msg.sender) || isAdmin(msg.sender), 'RubicSymbiosisProxy: Caller is not in manager role');
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, 'RubicSymbiosisProxy: only EOA');
        _;
    }

    constructor(
        uint256 _fee,
        address _metaRouter,
        address _gateway
    ) {
        require(_fee <= 1e6);

        RubicFee = _fee;
        metaRouter = _metaRouter;
        gateway = _gateway;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function SymbiosisCall(
        IERC20 inputToken,
        uint256 totalInputAmount,
        address integrator,
        bytes memory data
    ) external onlyEOA whenNotPaused {
        inputToken.transferFrom(msg.sender, address(this), totalInputAmount);

        uint256 inputAmount = _calculateFee(integrator, totalInputAmount, address(inputToken));

        uint256 _allowance = inputToken.allowance(address(this), gateway);
        if (_allowance < totalInputAmount) {
            if (_allowance == 0) {
                inputToken.safeApprove(gateway, type(uint256).max);
            } else {
                try inputToken.approve(gateway, type(uint256).max) returns (bool res) {
                    require(res == true, 'RubicSymbiosisProxy: approve failed');
                } catch {
                    inputToken.safeApprove(gateway, 0);
                    inputToken.safeApprove(gateway, type(uint256).max);
                }
            }
        }

        uint256 balanceBefore = inputToken.balanceOf(address(this));

        Address.functionCall(metaRouter, data);

        require(
            (balanceBefore - inputToken.balanceOf(address(this))) == inputAmount,
            'RubicSymbiosisProxy: different amount spent'
        );
    }

    function SymbiosisCallWithNative(address integrator, bytes memory data) external payable onlyEOA whenNotPaused {
        uint256 inputAmount = _calculateFee(integrator, msg.value, address(0));

        Address.functionCallWithValue(metaRouter, data, inputAmount);
    }

    function setRubicFee(uint256 _fee) external onlyManager {
        require(_fee <= 1e6);
        RubicFee = _fee;
    }

    function setMetaRouter(address _metaRouter) external onlyManager {
        require(_metaRouter != address(0));

        metaRouter = _metaRouter;
    }

    function setGateway(address _gateway) external onlyManager {
        require(_gateway != address(0));

        gateway = _gateway;
    }

    function setIntegratorFee(
        address _provider,
        uint256 _fee,
        uint256 _platformShare
    ) external onlyManager {
        require(_fee <= 1000000, 'RubicSymbiosisProxy: fee too high');

        integratorFee[_provider] = _fee;
        platformShare[_provider] = _platformShare;
    }

    function transferAdmin(address _newAdmin) external onlyAdmin {
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    function collectIntegratorFee(address _token) external nonReentrant {
        uint256 amount = amountOfIntegrator[_token][msg.sender];
        require(amount > 0, 'RubicSymbiosisProxy: amount is zero');

        amountOfIntegrator[_token][msg.sender] = 0;

        if (_token == address(0)) {
            Address.sendValue(payable(msg.sender), amount);
        } else {
            IERC20(_token).transfer(msg.sender, amount);
        }
    }

    function collectIntegratorFee(address _token, address _provider) external onlyManager {
        uint256 amount = amountOfIntegrator[_token][_provider];
        require(amount > 0, 'RubicSymbiosisProxy: amount is zero');

        amountOfIntegrator[_token][_provider] = 0;

        if (_token == address(0)) {
            Address.sendValue(payable(_provider), amount);
        } else {
            IERC20(_token).transfer(_provider, amount);
        }
    }

    function collectRubicFee(address _token) external onlyManager {
        uint256 amount = availableRubicFee[_token];
        require(amount > 0, 'RubicSymbiosisProxy: amount is zero');

        availableRubicFee[_token] = 0;

        if (_token == address(0)) {
            Address.sendValue(payable(msg.sender), amount);
        } else {
            IERC20(_token).transfer(msg.sender, amount);
        }
    }

    function pauseExecution() external onlyManager {
        _pause();
    }

    function unpauseExecution() external onlyManager {
        _unpause();
    }

    function isManager(address _who) public view returns (bool) {
        return (hasRole(MANAGER_ROLE, _who));
    }

    function isAdmin(address _who) public view returns (bool) {
        return (hasRole(DEFAULT_ADMIN_ROLE, _who));
    }

    function _calculateFee(
        address integrator,
        uint256 amountWithFee,
        address token
    ) private returns (uint256 amountWithoutFee) {
        if (integrator != address(0)) {
            uint256 integratorPercent = integratorFee[integrator];

            if (integratorPercent > 0) {
                uint256 platformPercent = platformShare[integrator];

                uint256 _integratorAndProtocolFee = FullMath.mulDiv(amountWithFee, integratorPercent, 1e6);

                uint256 _platformFee = FullMath.mulDiv(_integratorAndProtocolFee, platformPercent, 1e6);

                amountOfIntegrator[token][integrator] += _integratorAndProtocolFee - _platformFee;
                availableRubicFee[token] += _platformFee;

                amountWithoutFee = amountWithFee - _integratorAndProtocolFee;
            } else {
                amountWithoutFee = amountWithFee;
            }
        } else {
            amountWithoutFee = FullMath.mulDiv(amountWithFee, 1e6 - RubicFee, 1e6);

            availableRubicFee[token] += amountWithFee - amountWithoutFee;
        }
    }
}
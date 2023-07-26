// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "./interface/IVault.sol";
import "./interface/IRouter.sol";

/// @title Glitter Finance base vault
/// @author Ackee Blockchain
/// @notice Base contract for Glitter Finance vaults
abstract contract BaseVault is Ownable2StepUpgradeable, IVault {
    bytes32 public constant CONTRACT_ID = keccak256("GlitterVault");
    uint16 public constant FEE_DENOMINATOR = 10000;

    IRouter public router;
    address public recoverer;

    uint256 public minDeposit;
    uint256 public maxDeposit;
    uint256 public fees;

    constructor() initializer {}

    modifier onlyRouter() {
        require(
            msg.sender == address(router),
            "Vault: caller is not the router"
        );
        _;
    }

    modifier onlyRecoverer() {
        require(msg.sender == recoverer, "Vault: caller is not the recoverer");
        _;
    }

    /// @notice Initializer function
    /// @param _router Router address
    /// @param _owner Owner address
    /// @param _recoverer Recoverer address
    function __BaseVault_initialize(
        IRouter _router,
        address _owner,
        address _recoverer
    ) public initializer {
        require(_owner != address(0), "Vault: owner is zero-address");
        require(_recoverer != address(0), "Vault: recoverer is zero-address");
        __Ownable2Step_init();
        _transferOwnership(_owner);
        _setRouter(_router);
        _setMaxDeposit(type(uint256).max);
        recoverer = _recoverer;
    }

    /// @notice Set parameters
    /// @param _minDeposit Minimum deposit
    /// @param _maxDeposit Maximum deposit
    function setParams(
        uint256 _minDeposit,
        uint256 _maxDeposit
    ) external onlyOwner {
        _setMinDeposit(_minDeposit);
        _setMaxDeposit(_maxDeposit);
    }

    /// @notice Set minimum deposit
    /// @param _minDeposit Minimum deposit
    function setMinDeposit(uint256 _minDeposit) external onlyOwner {
        _setMinDeposit(_minDeposit);
    }

    /// @notice Set minimum deposit (private)
    /// @param _minDeposit Minimum deposit
    function _setMinDeposit(uint256 _minDeposit) private {
        require(
            _minDeposit <= maxDeposit,
            "Vault: value is higher than max deposit"
        );
        minDeposit = _minDeposit;
        emit SetMinDeposit(minDeposit);
    }

    /// @notice Set maximum deposit
    /// @param _maxDeposit Minimum deposit
    function setMaxDeposit(uint256 _maxDeposit) external onlyOwner {
        _setMaxDeposit(_maxDeposit);
    }

    /// @notice Set maximum deposit (private)
    /// @param _maxDeposit Minimum deposit
    function _setMaxDeposit(uint256 _maxDeposit) private {
        require(
            _maxDeposit >= minDeposit,
            "Vault: value is lower than min deposit"
        );
        maxDeposit = _maxDeposit;
        emit SetMaxDeposit(minDeposit);
    }

    /// @notice Set router
    /// @param _router Router address
    function setRouter(IRouter _router) external onlyRecoverer {
        require(!router.isActive(), "Vault: router is active");
        _setRouter(_router);
    }

    /// @notice Set router (private)
    /// @param _router Router address
    function _setRouter(IRouter _router) private {
        require(
            _router.CONTRACT_ID() == keccak256("GlitterRouter"),
            "Vault: invalid router contract"
        );
        router = _router;
        emit SetRouter(address(router));
    }

    /// @notice Collect acumulated fees from the contract
    function collectFees() external payable onlyOwner {
        uint256 tmpFees = fees;
        fees = 0;
        _releaseImpl(router.feeCollector(), tmpFees);
    }

    /// @notice Deposit tokens into the vault
    /// @param _from Sender address
    /// @param _amount Token amount
    function deposit(
        address _from,
        uint256 _amount
    ) external payable onlyRouter {
        require(
            _amount >= minDeposit,
            "Vault: amount is lower than min deposit"
        );
        require(
            _amount <= maxDeposit,
            "Vault: amount is higher than max deposit"
        );
        _depositImpl(_from, _amount);
    }

    /// @notice Release tokens from the vault
    /// @param _to Destination address
    /// @param _amount Amount of tokens
    /// @param _feeRate Fee rate
    function release(
        address _to,
        uint256 _amount,
        uint16 _feeRate
    ) external payable onlyRouter {
        uint256 txFee = (_amount * _feeRate) / FEE_DENOMINATOR;
        fees += txFee;
        _releaseImpl(_to, _amount - txFee);
    }

    /// @notice Refund tokens from the vault
    /// @param _to Destination address
    /// @param _amount Amount of tokens
    function refund(address _to, uint256 _amount) external payable onlyRouter {
        _releaseImpl(_to, _amount);
    }

    /// @notice Abstract deposit function
    /// @param _from Sender address
    /// @param _amount Token amount
    function _depositImpl(address _from, uint256 _amount) internal virtual;

    /// @notice Abstract release function
    /// @param _to Destination address
    /// @param _amount Token amount
    function _releaseImpl(address _to, uint256 _amount) internal virtual;

    function renounceOwnership() public override onlyOwner {
        revert("Vault: renounceOwnership is disabled");
    }

    uint256[44] private __gap;
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/ITreasury.sol";
import "./lib/TransferHelper.sol";
import "./Validatable.sol";

/**
 *  @title  Dev Treasury Contract
 *
 *  @author IHeart Team
 *
 *  @notice This smart contract create the treasury for Operation. This contract initially store
 *          all assets and using for purchase in marketplace operation.
 */
contract Treasury is ITreasury, Validatable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant DENOMINATOR = 1e4;

    address public daoAddress; /// HLP DAO wallet
    address public operationAddress; /// Operation wallet
    address public claimPoolAddress; /// HLP Claim Pool

    uint256 public daoPercent; /// HLP DAO percent
    uint256 public operationPercent; /// Operation percent
    uint256 public claimPoolPercent; /// HLP Claim Pool percent

    event SetDAOAddress(address indexed oldValue, address indexed newValue);
    event SetOperationAddress(address indexed oldValue, address indexed newValue);
    event SetHLPClaimPoolAddress(address indexed oldValue, address indexed newValue);
    event Split(
        address indexed paymentToken,
        address daoAddress,
        uint256 daoAmount,
        address operationAddress,
        uint256 operationAmount,
        address claimPoolAddress,
        uint256 claimPoolAmount
    );
    event SetTreasuryPercent(uint256 daoPercent, uint256 operationPercent, uint256 claimPoolPercent);

    /**
     * @notice Initialize new logic contract.
     * @dev    Replace for constructor function
     * @param _admin Address of admin contract
     * @param _daoAddress Address of DAO
     * @param _operationAddress Address of operation
     * @param _claimPoolAddress Address of claim pool
     * @param _daoPercent Percent of DAO
     * @param _operationPercent Percent of operation
     * @param _claimPoolPercent Percent of claim pool
     */
    function initialize(
        IAdmin _admin,
        address _daoAddress,
        address _operationAddress,
        address _claimPoolAddress,
        uint256 _daoPercent,
        uint256 _operationPercent,
        uint256 _claimPoolPercent
    )
        public
        initializer
        notZeroAddress(address(_admin))
        notZeroAddress(_daoAddress)
        notZeroAddress(_operationAddress)
        notZeroAddress(_claimPoolAddress)
    {
        __Validatable_init(_admin);
        __ReentrancyGuard_init();

        if (admin.treasury() == address(0)) {
            admin.registerTreasury();
        }
        daoAddress = _daoAddress;
        operationAddress = _operationAddress;
        claimPoolAddress = _claimPoolAddress;

        _setTreasuryPercent(_daoPercent, _operationPercent, _claimPoolPercent);
    }

    /**
     * @notice Used to receive native token
     */
    receive() external payable {}

    /**
     * @notice
     * Set the new DAO address
     * Caution need to discuss with the dev before updating the new state
     *
     * @param _dao New DAO address
     *
     * emit {SetDAOAddress} events
     */
    function setDAOAddress(address _dao) external onlyAdmin notZeroAddress(_dao) {
        address oldValue = daoAddress;
        daoAddress = _dao;
        emit SetDAOAddress(oldValue, _dao);
    }

    /**
     * @notice
     * Set the new Operation address
     * Caution need to discuss with the dev before updating the new state
     *
     * @param _operation New Operation address
     *
     * emit {SetOperationAddress} events
     */
    function setOperationAddress(address _operation) external onlyAdmin notZeroAddress(_operation) {
        address oldValue = operationAddress;
        operationAddress = _operation;
        emit SetOperationAddress(oldValue, _operation);
    }

    /**
     * @notice
     * Set the new ClaimPool contract address
     * Caution need to discuss with the dev before updating the new state
     *
     * @param _claimPool New claim pool contract address
     *
     * emit {SetHLPClaimPoolAddress} events
     */
    function setHLPClaimPoolAddress(address _claimPool) external onlyAdmin notZeroAddress(_claimPool) {
        address oldValue = claimPoolAddress;
        claimPoolAddress = _claimPool;
        emit SetHLPClaimPoolAddress(oldValue, _claimPool);
    }

    /**
     * @notice set new percent for treasury actor
     * @dev Only admin can call this function
     * @param _daoPercent DAO percent
     * @param _operationPercent Operation percent
     * @param _claimPoolPercent Claim pool percent
     *
     * emit {SetTreasuryPercent} event
     */
    function setTreasuryPercent(
        uint256 _daoPercent,
        uint256 _operationPercent,
        uint256 _claimPoolPercent
    ) external onlyAdmin {
        _setTreasuryPercent(_daoPercent, _operationPercent, _claimPoolPercent);

        emit SetTreasuryPercent(_daoPercent, _operationPercent, _claimPoolPercent);
    }

    /**
     *  @notice Split amount to 3 pool address.
     *
     *  @dev    Everyone can call this function.
     *
     *  @param  _paymentToken    address of payment to split
     *
     *  emit {Split} events
     */
    function split(address _paymentToken) external nonReentrant {
        // Calculate portion of each fund.
        uint256 totalAmount = _paymentToken != address(0)
            ? IERC20Upgradeable(_paymentToken).balanceOf(address(this))
            : address(this).balance;
        require(totalAmount > 0, "Nothing to split");
        uint256 daoAmount = (totalAmount * daoPercent) / DENOMINATOR;
        uint256 operationAmount = (totalAmount * operationPercent) / DENOMINATOR;
        uint256 claimPoolAmount = totalAmount - (daoAmount + operationAmount);

        if (daoAmount > 0) {
            TransferHelper._transferToken(_paymentToken, daoAmount, address(this), daoAddress);
        }

        if (operationAmount > 0) {
            TransferHelper._transferToken(_paymentToken, operationAmount, address(this), operationAddress);
        }

        if (claimPoolAmount > 0) {
            TransferHelper._transferToken(_paymentToken, claimPoolAmount, address(this), claimPoolAddress);
        }

        emit Split(
            _paymentToken,
            daoAddress,
            daoAmount,
            operationAddress,
            operationAmount,
            claimPoolAddress,
            claimPoolAmount
        );
    }

    /**
     * @notice set new percent for treasury
     * @param _daoPercent percent of dao
     * @param _operationPercent percent of operation
     * @param _claimPoolPercent percent of claim pool
     */
    function _setTreasuryPercent(uint256 _daoPercent, uint256 _operationPercent, uint256 _claimPoolPercent) private {
        require(
            _daoPercent + _operationPercent + _claimPoolPercent == DENOMINATOR,
            "The total percentage must be equal to 100%"
        );

        daoPercent = _daoPercent;
        operationPercent = _operationPercent;
        claimPoolPercent = _claimPoolPercent;
    }
}
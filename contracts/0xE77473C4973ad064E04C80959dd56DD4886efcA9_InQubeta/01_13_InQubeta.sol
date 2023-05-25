// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../interfaces/IFeeCollector.sol";

contract InQubeta is ERC20, ERC20Burnable, AccessControl {
    /// @notice Precision for mathematical calculations with percents. 100% === 10000
    uint256 private constant PRECISION = 100_00;
    /// @notice Access Control fee collector role hash
    bytes32 public constant FEE_DISTRIBUTION_ROLE =
        keccak256("FEE_DISTRIBUTION_ROLE");
    /// @notice fee collector address
    address public feeCollector;
    /// @notice the percentage of the fee charged for the purchase of the token
    uint256 public buyFee;
    /// @notice the percentage of the fee charged for the selling of the token
    uint256 public sellFee;
    /// @notice bool value, if true, fees is enabled, if false, disabled
    bool public isEnabledFees;
    /// @notice pair mapping, if true the pair is added and fees are charged,
    /// if false, no fees are charged
    mapping(address => bool) public pairs;

    /// ================================ Errors ================================ ///

    /// @dev - address is not a contract;
    error IsNotContract(string err);
    ///@dev returned if passed zero address
    error ZeroAddress(string err);
    ///@dev returned if passed zero amount
    error ZeroAmount(string err);
    ///@dev returned if the set percentage is equal to or greater than PRECISION
    error HighValue(string err);
    ///@dev returned if the pair address already exists
    error ExistsAddress(string err);
    ///@dev returned if the value already assigned
    error ExistsValue(string err);
    ///@dev returned if the pair address has not been added
    error NotFoundAddress(string err);
    ///@dev returned if the caller dont have access to function
    error AccessIsDenied(string err);

    /// ================================ Events ================================ ///

    ///@dev emitted when owner add new pair
    event AddPair(
        address indexed addressPair,
        bool enabled,
        uint256 indexed timestamp
    );
    ///@dev emitted when owner set fee percents
    event SetFees(uint256 buyFee, uint256 sellFee, uint256 indexed timestamp);
    ///@dev emitted when owner update fee collector address
    event UpdateFeeCollector(
        address indexed feeCollector,
        uint256 indexed timestamp
    );
    ///@dev emitted when fees enabled
    event EnableFees(bool indexed enabled, uint256 indexed timestamp);
    ///@dev emitted when fees disabled
    event DisableFees(bool indexed enabled, uint256 indexed timestamp);
    ///@dev emitted when owner disable pair address
    event RemovePair(
        address indexed addressPair,
        bool disable,
        uint256 indexed timestamp
    );
    ///@dev emitted when buy fee is updated for all pairs
    event UpdateBuyFee(uint256 buyFee, uint256 indexed timestamp);
    ///@dev emitted when sell fee is updated for all pairs
    event UpdateSellFee(uint256 buyFee, uint256 indexed timestamp);

    constructor(
        address _admin, /// contract owner
        uint256 _initialSupply, /// total supply of tokens
        uint256 _buyFee, /// buy fee percent. 5% * 100 = 500
        uint256 _sellFee, /// buy fee percent. 10% * 100 = 1000
        address _feeCollector /// fee collector contract addrees
    ) ERC20("InQubeta", "QUBE") checkMaxFee(_buyFee, _sellFee) {
        if (_feeCollector == address(0) || _admin == address(0)) {
            revert ZeroAddress("InQubeta: Zero address");
        }
        if (!Address.isContract(_feeCollector)) {
            revert IsNotContract("InQubeta: Fee collector is not a contract");
        }

        _mint(_admin, _initialSupply);
        feeCollector = _feeCollector;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(FEE_DISTRIBUTION_ROLE, _admin);
        _grantRole(FEE_DISTRIBUTION_ROLE, _feeCollector);

        buyFee = _buyFee;
        sellFee = _sellFee;
        isEnabledFees = true;
    }

    /**
    @dev the modifier checks whether the commission percentages 
    are within the allowed range
    */
    modifier checkMaxFee(uint256 _buyFee, uint256 _sellFee) {
        if (_buyFee >= PRECISION || _sellFee >= PRECISION) {
            revert HighValue("InQubeta: Fee value is too high");
        }
        _;
    }

    /**
     * @notice The function performs an ERC20 transfer, but with some modifications. In the event
     *  that the token will be sent to the pool that is added to our contract, the sell commission
     *  will be charged from the number of tokens sent. If the token will
     *  be sent from the pool, the buy fee will be charged from the number of tokens sent.
     * If it is a normal transfer that is not sent to or from the pool,
     * it will work as a standard ERC20 transfer
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        return _transferFrom(msg.sender, to, amount);
    }

    /**
     * @notice The function performs an ERC20 transferFrom, but with some modifications. In the event
     *  that the token will be sent to the pool that is added to our contract, the sell commission
     *  will be charged from the number of tokens sent. If the token will
     *  be sent from the pool, the buy fee will be charged from the number of tokens sent.
     *  If it is a normal transferFrom that is not sent to or from the pool,
     *  it will work as a standard ERC20 transferFrom.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        return _transferFrom(from, to, amount);
    }

    /**
     * @notice The function adds a new pair from which commissions will be charged
     * for the purchase and sale of our token. Only the owner can call.
     * @param addressPair - pair address
     */
    function addPair(
        address addressPair
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (addressPair == address(0)) {
            revert ZeroAddress("InQubeta: Zero address");
        }

        if (pairs[addressPair]) {
            revert ExistsAddress("InQubeta: Address already exists");
        }

        pairs[addressPair] = true;
        emit AddPair(addressPair, true, block.timestamp);
    }

    /**
     * @notice The function performs disabling pool.
     * Only the owner can call.
     * @param addressPair - pair address
     */
    function removePair(
        address addressPair
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (addressPair == address(0)) {
            revert ZeroAddress("InQubeta: Zero address");
        }

        pairs[addressPair] = false;
        emit RemovePair(addressPair, false, block.timestamp);
    }

    /**
     * @notice The function performs disabling buy and sell fees.
     * Only the default admin or fee collector can call it.
     */
    function disableFees() external onlyRole(FEE_DISTRIBUTION_ROLE) {
        isEnabledFees = false;
        emit DisableFees(false, block.timestamp);
    }

    /**
     * @notice The function performs enabling buy and sell fees.
     * Only the default admin or fee collector can call it.
     */
    function enableFees() external onlyRole(FEE_DISTRIBUTION_ROLE) {
        isEnabledFees = true;
        emit EnableFees(true, block.timestamp);
    }

    /**
     * @notice The function updates the buy fee percentage.
     * Only the owner can call.
     * @param _buyFee - sell fee percent
     */
    function updateBuyFee(
        uint256 _buyFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_buyFee >= PRECISION) {
            revert HighValue("InQubeta: Fee value is too high");
        }

        buyFee = _buyFee;
        emit UpdateBuyFee(_buyFee, block.timestamp);
    }

    /**
     * @notice The function updates the sell fee percentage.
     * Only the owner can call.
     * @param _sellFee - sell fee percent
     */
    function updateSellFee(
        uint256 _sellFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_sellFee >= PRECISION) {
            revert HighValue("InQubeta: Fee value is too high");
        }

        sellFee = _sellFee;
        emit UpdateSellFee(_sellFee, block.timestamp);
    }

    /**
     * @notice The function updates the settings of commission percentages
     * for buying and selling. Only the owner can call.
     * @param _buyFee - buy fee percent
     * @param _sellFee - sell fee percent
     */
    function updateFeesPercents(
        uint256 _buyFee,
        uint256 _sellFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) checkMaxFee(_buyFee, _sellFee) {
        buyFee = _buyFee;
        sellFee = _sellFee;

        emit SetFees(_buyFee, _sellFee, block.timestamp);
    }

    /**
     * @notice The function updates the address that receives all commissions.
     * Only the owner can call.
     * @param newFeeCollector - new fee collector address
     */
    function updateFeeCollector(
        address newFeeCollector
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newFeeCollector == address(0)) {
            revert ZeroAddress("InQubeta: Zero address");
        }
        if (newFeeCollector == feeCollector) {
            revert ExistsAddress("InQubeta: No new address specified");
        }
        if (!Address.isContract(newFeeCollector)) {
            revert IsNotContract("InQubeta: Fee collector is not a contract");
        }
        revokeRole(FEE_DISTRIBUTION_ROLE, feeCollector);
        feeCollector = newFeeCollector;
        grantRole(FEE_DISTRIBUTION_ROLE, newFeeCollector);

        emit UpdateFeeCollector(newFeeCollector, block.timestamp);
    }

    /**
     * @notice Internal function that implements the logic of token transfer and the logic of fee collection.
     */
    function _transferFrom(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (isEnabledFees) {
            if (pairs[to]) {
                uint256 fee = (amount * sellFee) / PRECISION;
                uint256 transferAmount = amount - fee;
                _transfer(from, feeCollector, fee);
                _transfer(from, to, transferAmount);
                IFeeCollector(feeCollector).recordSellFee(fee);
            } else if (pairs[from]) {
                uint256 fee = (amount * buyFee) / PRECISION;
                _transfer(from, to, amount);
                _transfer(to, feeCollector, fee);
                IFeeCollector(feeCollector).recordBuyFee(fee);
            } else {
                _transfer(from, to, amount);
            }
        } else {
            _transfer(from, to, amount);
        }
        return true;
    }
}
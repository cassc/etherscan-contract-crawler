pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./libraries/ECDSAOffsetRecovery.sol";
import "./libraries/FullMath.sol";

contract BridgeBase is AccessControlUpgradeable, PausableUpgradeable, ECDSAOffsetRecovery {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant DENOMINATOR = 1e6;
    uint256 public constant SIGNATURE_LENGTH = 65;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    uint256 public minConfirmationSignatures; // TODO: remove?

    mapping(uint256 => uint256) public feeAmountOfBlockchain;
    mapping(uint256 => uint256) public blockchainCryptoFee;

    mapping(address => uint256) public integratorFee; // TODO: check whether integrator is valid
    mapping(address => uint256) public platformShare;

    mapping(bytes32 => SwapStatus) public processedTransactions;

    EnumerableSetUpgradeable.AddressSet internal availableRouters; // TODO: setter

    enum SwapStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }
    
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), 'BridgeBase: not an admin');
        _;
    }

    modifier onlyManagerAndAdmin() {
        require(isManager(msg.sender) || isAdmin(msg.sender), 'BridgeBase: not a manager');
        _;
    }

    modifier onlyRelayer() {
        require(isRelayer(msg.sender), 'BridgeBase: not a relayer');
        _;
    }

    modifier anyRole() {
        require(
            isManager(msg.sender) ||
            isRelayer(msg.sender),
            'BridgeBase: no role');
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, 'BridgeBase: only EOA');
        _;
    }

    function __BridgeBaseInit(
        uint256[] memory _blockchainIDs,
        uint256[] memory _cryptoFees,
        uint256[] memory _platformFees,
        address[] memory _routers
    ) internal onlyInitializing {
        __Pausable_init_unchained();

        require(
            _cryptoFees.length == _platformFees.length,
            'BridgeBase: fees length mismatch'
        );

        for (uint256 i; i < _cryptoFees.length; i++) {
            blockchainCryptoFee[_blockchainIDs[i]] = _cryptoFees[i];
            feeAmountOfBlockchain[_blockchainIDs[i]] = _platformFees[i];
        }

        for (uint256 i; i < _routers.length; i++) {
            availableRouters.add(_routers[i]);
        }

        minConfirmationSignatures = 3;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver
    ) internal virtual {
        if (_token == address(0)) {
            AddressUpgradeable.sendValue(payable(_receiver), _amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
        }
    }

    /// CONTROL FUNCTIONS ///

    function pauseExecution() external onlyManagerAndAdmin { // TODO: add blockchain pause
        _pause();
    }

    function unpauseExecution() external onlyManagerAndAdmin {
        _unpause();
    }

    function collectCryptoFee(address payable _to) external onlyManagerAndAdmin {
        _to.transfer(address(this).balance);
    }

    function setIntegratorFee(
        address _integrator,
        uint256 _fee,
        uint256 _platformShare
    ) external onlyManagerAndAdmin {
        require(_fee <= 1000000, 'BridgeBase: fee too high');

        integratorFee[_integrator] = _fee;
        platformShare[_integrator] = _platformShare;
    }

    /**
     * @dev Changes tokens values for blockchains in feeAmountOfBlockchain variables
     * @notice tokens is represented as hundredths of a bip, i.e. 1e-6
     * @param _blockchainID ID of the blockchain
     * @param _feeAmount Fee amount to subtract from transfer amount
     */
    function setFeeAmountOfBlockchain(uint256 _blockchainID, uint256 _feeAmount)
        external
        onlyManagerAndAdmin
    {
        feeAmountOfBlockchain[_blockchainID] = _feeAmount;
    }

    /**
     * @dev Changes crypto tokens values for blockchains in blockchainCryptoFee variables
     * @param _blockchainID ID of the blockchain
     * @param _feeAmount Fee amount of native token that must be sent in init call
     */
    function setCryptoFeeOfBlockchain(uint256 _blockchainID, uint256 _feeAmount)
        external
        anyRole
    {
        blockchainCryptoFee[_blockchainID] = _feeAmount;
    }

    /**
     * @dev Changes requirement for minimal amount of signatures to validate on transfer
     * @param _minConfirmationSignatures Number of signatures to verify
     */
    function setMinConfirmationSignatures(uint256 _minConfirmationSignatures)
        external
        onlyAdmin
    {
        require(
            _minConfirmationSignatures > 0,
            "BridgeBase: min = 1"
        );
        minConfirmationSignatures = _minConfirmationSignatures;
    }

    function transferAdmin(address _newAdmin) external onlyAdmin {
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    /**
     * @dev Function changes values associated with certain originalTxHash
     * @param _id ID of the transaction to change
     * @param _statusCode Associated status
     */
    function changeTxStatus(bytes32 _id, SwapStatus _statusCode)
        external
        onlyRelayer
    {
        require(
            _statusCode != SwapStatus.Null,
            "BridgeBase: cant set to Null"
        );
        require(
            processedTransactions[_id] != SwapStatus.Succeeded &&
            processedTransactions[_id] != SwapStatus.Fallback,
            "BridgeBase: unchangeable"
        );

        processedTransactions[_id] = _statusCode;
    }

    /// VIEW FUNCTIONS ///

    function getAvailableRouters() external view returns(address[] memory) {
        return availableRouters.values();
    }

    /**
     * @dev Function to check if address is belongs to manager role
     * @param _who Address to check
     */
    function isManager(address _who) public view returns (bool) {
        return (hasRole(MANAGER_ROLE, _who));
    }

    /**
     * @dev Function to check if address is belongs to default admin role
     * @param _who Address to check
     */
    function isAdmin(address _who) public view returns (bool) {
        return (hasRole(DEFAULT_ADMIN_ROLE, _who));
    }

    /**
     * @dev Function to check if address is belongs to relayer role
     * @param _who Address to check
     */
    function isRelayer(address _who) public view returns (bool) {
        return hasRole(RELAYER_ROLE, _who);
    }

    /**
     * @dev Function to check if address is belongs to validator role
     * @param _who Address to check
     */
    function isValidator(address _who) public view returns (bool) {
        return hasRole(VALIDATOR_ROLE, _who);
    }

    /// UTILS ///

    function smartApprove(
        address _tokenIn,
        uint256 _amount,
        address _to
    ) internal {
        IERC20Upgradeable tokenIn = IERC20Upgradeable(_tokenIn);
        uint256 _allowance = tokenIn.allowance(address(this), _to);
        if (_allowance < _amount) {
            if (_allowance == 0) {
                tokenIn.safeApprove(_to, type(uint256).max);
            } else {
                try tokenIn.approve(_to, type(uint256).max) returns (bool res) {
                    require(res == true, 'BridgeBase: approve failed');
                } catch {
                    tokenIn.safeApprove(_to, 0);
                    tokenIn.safeApprove(_to, type(uint256).max);
                }
            }
        }
    }

    /**
     * @dev Plain fallback function to receive crypto
     */
    receive() external payable {}

    /**
     * @dev Plain fallback function to receive crypto
     */
    fallback() external payable {}
}
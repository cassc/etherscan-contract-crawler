// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@debridge-finance/debridge-contracts-v1/contracts/interfaces/IDeBridgeGate.sol";
import "@debridge-finance/debridge-contracts-v1/contracts/libraries/SignatureUtil.sol";
import "../interfaces/IERC20Permit.sol";
import "../libraries/BytesLib.sol";
import "../libraries/DlnOrderLib.sol";

abstract contract DlnBase is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;
    using SignatureUtil for bytes;

    /* ========== CONSTANTS ========== */

    /// @dev Basis points or bps, set to 10 000 (equal to 1/10000). Used to express relative values (fees)
    uint256 public constant BPS_DENOMINATOR = 10000;

    /// @dev Role allowed to stop transfers
    bytes32 public constant GOVMONITORING_ROLE =
        keccak256("GOVMONITORING_ROLE");

    uint256 public constant MAX_ADDRESS_LENGTH = 255;
    uint256 public constant EVM_ADDRESS_LENGTH = 20;
    uint256 public constant SOLANA_ADDRESS_LENGTH = 32;

    /* ========== STATE VARIABLES ========== */

    // @dev Maps chainId => type of chain engine
    mapping(uint256 => ChainEngine) public chainEngines;

    IDeBridgeGate public deBridgeGate;

    /* ========== ENUMS ========== */

    enum ChainEngine {
        UNDEFINED, //0
        EVM, // 1
        SOLANA // 2
    }

    /* ========== STRUCTS ========== */

    struct ExternalCall {
        uint256 executionFee;
        // uint256 flags;
        bytes fallbackAddress;
        bytes data;
    }

    /* ========== ERRORS ========== */

    error AdminBadRole();
    error CallProxyBadRole();
    error GovMonitoringBadRole();
    error NativeSenderBadRole(bytes nativeSender, uint256 chainIdFrom);
    error MismatchedTransferAmount();
    error MismatchedOrderId();
    error WrongAddressLength();
    error ZeroAddress();
    error ProposedFeeTooHigh();
    error NotSupportedDstChain();
    error EthTransferFailed();
    error Unauthorized();
    error IncorrectOrderStatus();
    error WrongChain();
    error WrongArgument();
    error UnknownEngine();
    
    /* ========== EVENTS ========== */

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    modifier onlyGovMonitoring() {
        if (!hasRole(GOVMONITORING_ROLE, msg.sender))
            revert GovMonitoringBadRole();
        _;
    }

    /* ========== CONSTRUCTOR  ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __DlnBase_init(IDeBridgeGate _deBridgeGate) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __DlnBase_init_unchained(_deBridgeGate);
    }

    function __DlnBase_init_unchained(IDeBridgeGate _deBridgeGate)
        internal
        initializer
    {
        deBridgeGate = _deBridgeGate;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== ADMIN METHODS ========== */

    /// @dev Stop all protocol.
    function pause() external onlyGovMonitoring {
        _pause();
    }

    /// @dev Unlock protocol.
    function unpause() external onlyAdmin {
        _unpause();
    }

    /* ========== INTERNAL ========== */

    function _executePermit(address _tokenAddress, bytes memory _permitEnvelope)
        internal
    {
        if (_permitEnvelope.length > 0) {
            uint256 permitAmount = BytesLib.toUint256(_permitEnvelope, 0);
            uint256 deadline = BytesLib.toUint256(_permitEnvelope, 32);
            (bytes32 r, bytes32 s, uint8 v) = _permitEnvelope.parseSignature(64);
            IERC20Permit(_tokenAddress).permit(
                msg.sender,
                address(this),
                permitAmount,
                deadline,
                v,
                r,
                s
            );
        }
    }

    /// @dev Safe transfer tokens and check that receiver will receive exact amount (check only if to != from)
    function _safeTransferFrom(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20Upgradeable token = IERC20Upgradeable(_tokenAddress);
        uint256 balanceBefore = token.balanceOf(_to);
        token.safeTransferFrom(_from, _to, _amount);
        // Received real amount
        uint256 receivedAmount = token.balanceOf(_to) - balanceBefore;
        if (_from != _to && _amount != receivedAmount) revert MismatchedTransferAmount();
    }

    /*
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert EthTransferFailed();
    }

    /// @dev Transfer ETH or token
    /// @param tokenAddress address(0) to transfer ETH
    /// @param to  recipient of the transfer
    /// @param value the amount to send
    function _safeTransferEthOrToken(address tokenAddress, address to, uint256 value) internal {
        if (tokenAddress == address(0)) {
            _safeTransferETH(to, value);
        }
        else {
             IERC20Upgradeable(tokenAddress).safeTransfer(to, value);
        }
    }

    function _encodeOrder(DlnOrderLib.Order memory _order)
        internal
        pure
        returns (bytes memory encoded)
    {
        {
            if (
                _order.makerSrc.length > MAX_ADDRESS_LENGTH ||
                _order.giveTokenAddress.length > MAX_ADDRESS_LENGTH ||
                _order.takeTokenAddress.length > MAX_ADDRESS_LENGTH ||
                _order.receiverDst.length > MAX_ADDRESS_LENGTH ||
                _order.givePatchAuthoritySrc.length > MAX_ADDRESS_LENGTH ||
                _order.allowedTakerDst.length > MAX_ADDRESS_LENGTH ||
                _order.allowedCancelBeneficiarySrc.length > MAX_ADDRESS_LENGTH
            ) revert WrongAddressLength();
        }
        // | Bytes | Bits | Field                                                |
        // | ----- | ---- | ---------------------------------------------------- |
        // | 8     | 64   | Nonce
        // | 1     | 8    | Maker Src Address Size (!=0)                         |
        // | N     | 8*N  | Maker Src Address                                              |
        // | 32    | 256  | Give Chain Id                                        |
        // | 1     | 8    | Give Token Address Size (!=0)                        |
        // | N     | 8*N  | Give Token Address                                   |
        // | 32    | 256  | Give Amount                                          |
        // | 32    | 256  | Take Chain Id                                        |
        // | 1     | 8    | Take Token Address Size (!=0)                        |
        // | N     | 8*N  | Take Token Address                                   |
        // | 32    | 256  | Take Amount                                          |                         |
        // | 1     | 8    | Receiver Dst Address Size (!=0)                      |
        // | N     | 8*N  | Receiver Dst Address                                 |
        // | 1     | 8    | Give Patch Authority Address Size (!=0)              |
        // | N     | 8*N  | Give Patch Authority Address                         |
        // | 1     | 8    | Order Authority Address Dst Size (!=0)               |
        // | N     | 8*N  | Order Authority Address Dst                     |
        // | 1     | 8    | Allowed Taker Dst Address Size                       |
        // | N     | 8*N  | * Allowed Taker Address Dst                          |
        // | 1     | 8    | Allowed Cancel Beneficiary Src Address Size          |
        // | N     | 8*N  | * Allowed Cancel Beneficiary Address Src             |
        // | 1     | 8    | Is External Call Presented 0x0 - Not, != 0x0 - Yes   |
        // | 32    | 256  | * Execution Fee                                      |
        // | 1     | 8    | * Fallback Address Dst Address Size (!=1)            |
        // | N     | 8*N  | * Fallback Address Dst Address                       |
        // | 32    | 256  | * External Call Hash

        encoded = abi.encodePacked(
            _order.makerOrderNonce,
            (uint8)(_order.makerSrc.length),
            _order.makerSrc
        );
        {
            encoded = abi.encodePacked(
                encoded,
                _order.giveChainId,
                (uint8)(_order.giveTokenAddress.length),
                _order.giveTokenAddress,
                _order.giveAmount,
                _order.takeChainId
            );
        }
        //Avoid stack to deep
        {
            encoded = abi.encodePacked(
                encoded,
                (uint8)(_order.takeTokenAddress.length),
                _order.takeTokenAddress,
                _order.takeAmount,
                (uint8)(_order.receiverDst.length),
                _order.receiverDst
            );
        }
        {
            encoded = abi.encodePacked(
                encoded,
                (uint8)(_order.givePatchAuthoritySrc.length),
                _order.givePatchAuthoritySrc,
                (uint8)(_order.orderAuthorityAddressDst.length),
                _order.orderAuthorityAddressDst
            );
        }
        {
            encoded = abi.encodePacked(
                encoded,
                (uint8)(_order.allowedTakerDst.length),
                _order.allowedTakerDst,
                (uint8)(_order.allowedCancelBeneficiarySrc.length),
                _order.allowedCancelBeneficiarySrc,
                _order.externalCall.length > 0
            );
        }
        if (_order.externalCall.length > 0) {
            ExternalCall memory externalCall = abi.decode(
                _order.externalCall,
                (ExternalCall)
            );
            if (externalCall.fallbackAddress.length > MAX_ADDRESS_LENGTH) revert WrongAddressLength();

            encoded = abi.encodePacked(
                encoded,
                externalCall.executionFee,
                (uint8)(externalCall.fallbackAddress.length),
                externalCall.fallbackAddress,
                keccak256(externalCall.data)
            );
        }
        return encoded;
    }

    // ============ VIEWS ============

    function getOrderId(DlnOrderLib.Order memory _order) public pure returns (bytes32) {
        return keccak256(_encodeOrder(_order));
    }

    /// @dev Get current chain id
    function getChainId() public view virtual returns (uint256 cid) {
        assembly {
            cid := chainid()
        }
    }
}
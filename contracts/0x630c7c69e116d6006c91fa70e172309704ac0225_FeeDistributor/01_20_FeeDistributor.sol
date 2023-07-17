// SPDX-License-Identifier: UNLICESNED
pragma solidity ^0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { PullPaymentUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IFeeDistributor } from "./interfaces/IFeeDistributor.sol";

error FeeCountLimitExceeded(uint256 feeCount);
error UnsupportedToken(bytes32 feeToken);

contract FeeDistributor is
    IFeeDistributor,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    PullPaymentUpgradeable
{
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant VERSION = "1.0.0";
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    uint256 public constant DEFAULT_FEE_COUNT_LIMIT = 20;

    bytes32 public nativeToken;
    // contractAddress => feeCountLimit
    mapping(address => uint256) public feeCountLimits;
    // tokenSymbol => tokenAddress
    mapping(bytes32 => address) public tokenAddresses;

    event FeeCountLimitSet(uint256 feeCountLimit);
    event NativeTokenSet(bytes32 indexed nativeToken);
    event TokenAddressSet(bytes32 tokenSymbol, address tokenAddress);
    event FeesDistributed(uint256 feeCount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(bytes32 nativeToken_) external initializer {
        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();
        PullPaymentUpgradeable.__PullPayment_init();

        nativeToken = nativeToken_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {
        _asyncTransfer(msg.sender, msg.value);
    }

    function setNativeToken(bytes32 nativeToken_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nativeToken = nativeToken_;
        emit NativeTokenSet(nativeToken_);
    }

    function setFeeCountLimit(address contractAddress, uint256 feeCountLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeCountLimits[contractAddress] = feeCountLimit;
        emit FeeCountLimitSet(feeCountLimit);
    }

    function setTokenAddress(bytes32 tokenSymbol, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenAddresses[tokenSymbol] = tokenAddress;
        emit TokenAddressSet(tokenSymbol, tokenAddress);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._unpause();
    }

    /* solhint-disable avoid-tx-origin */
    function distributeFees(
        Fee[] calldata fees
    ) external payable nonReentrant whenNotPaused onlyRole(DISTRIBUTOR_ROLE) {
        uint256 feeCount = fees.length;
        uint256 contractFeeCountLimit = feeCountLimits[msg.sender];
        uint256 feeCountLimit = contractFeeCountLimit > 0 ? contractFeeCountLimit : DEFAULT_FEE_COUNT_LIMIT;
        if (feeCount > feeCountLimit) {
            revert FeeCountLimitExceeded(feeCount);
        }

        bytes32 nativeToken_ = nativeToken;
        uint256 totalNativeTokenFee = 0;

        for (uint i = 0; i < feeCount; ) {
            Fee calldata fee = fees[i];
            if (fee.token == nativeToken_) {
                fee.payee.sendValue(fee.amount);
                totalNativeTokenFee += fee.amount;
            } else {
                address tokenAddress = tokenAddresses[fee.token];
                if (tokenAddress == address(0)) {
                    revert UnsupportedToken(fee.token);
                }
                // slither-disable-next-line arbitrary-send-erc20
                IERC20Upgradeable(tokenAddress).safeTransferFrom(tx.origin, fee.payee, fee.amount);
            }
            unchecked {
                i++;
            }
        }

        if (msg.value > totalNativeTokenFee) {
            _asyncTransfer(tx.origin, msg.value - totalNativeTokenFee);
        }

        emit FeesDistributed(feeCount);
    }
    /* solhint-enable avoid-tx-origin */
}
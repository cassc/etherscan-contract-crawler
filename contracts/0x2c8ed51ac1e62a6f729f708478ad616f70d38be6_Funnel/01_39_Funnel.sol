// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Address } from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { IERC1363Receiver } from "lib/openzeppelin-contracts/contracts/interfaces/IERC1363Receiver.sol";
import { Strings } from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import { Initializable } from "lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { IFunnel } from "./interfaces/IFunnel.sol";
import { IERC5827 } from "./interfaces/IERC5827.sol";
import { IERC5827Proxy } from "./interfaces/IERC5827Proxy.sol";
import { IERC5827Spender } from "./interfaces/IERC5827Spender.sol";
import { IERC5827Payable } from "./interfaces/IERC5827Payable.sol";
import { IFunnelErrors } from "./interfaces/IFunnelErrors.sol";
import { MetaTxContext } from "./lib/MetaTxContext.sol";
import { NativeMetaTransaction } from "./lib/NativeMetaTransaction.sol";
import { MathUtil } from "./lib/MathUtil.sol";

/// @title Funnel contracts for ERC20
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
/// @notice This contract is a funnel for ERC20 tokens. It enforces renewable allowances
contract Funnel is IFunnel, NativeMetaTransaction, MetaTxContext, Initializable, IFunnelErrors {
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////
    ///                      EIP-5827 STORAGE
    //////////////////////////////////////////////////////////////

    /// address of the base token (e.g. USDC, DAI, WETH)
    IERC20 private _baseToken;

    /// @notice RenewableAllowance struct that is stored on the contract
    /// @param maxAmount The maximum amount of allowance possible
    /// @param remaining The remaining allowance left at the last updated time
    /// @param recoveryRate The rate at which the allowance recovers
    /// @param lastUpdated Timestamp that the allowance is last updated.
    /// @dev The actual remaining allowance at any point of time must be derived from recoveryRate, lastUpdated and maxAmount.
    /// See getter function for implementation details.
    struct RenewableAllowance {
        uint256 maxAmount;
        uint256 remaining;
        uint192 recoveryRate;
        uint64 lastUpdated;
    }

    // owner => spender => renewableAllowance
    mapping(address => mapping(address => RenewableAllowance)) public rAllowance;

    //////////////////////////////////////////////////////////////
    ///                        EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////

    /// INITIAL_CHAIN_ID to be set during initiailisation
    /// @dev This value will not change
    uint256 internal INITIAL_CHAIN_ID;

    /// INITIAL_DOMAIN_SEPARATOR to be set during initiailisation
    /// @dev This value will not change
    bytes32 internal INITIAL_DOMAIN_SEPARATOR;

    /// constant for the given struct type that do not need to be runtime computed. Required for EIP712-typed data
    bytes32 internal constant PERMIT_RENEWABLE_TYPEHASH =
        keccak256(
            "PermitRenewable(address owner,address spender,uint256 value,uint256 recoveryRate,uint256 nonce,uint256 deadline)"
        );

    /// constant for the given struct type that do not need to be runtime computed. Required for EIP712-typed data
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @inheritdoc IFunnel
    function initialize(address _token) external initializer {
        if (_token == address(0)) {
            revert InvalidAddress({ _input: _token });
        }
        _baseToken = IERC20(_token);

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// @dev Fallback function
    /// implemented entirely in `_fallback`.
    fallback() external {
        _fallback(address(_baseToken));
    }

    /// @notice Sets fixed allowance with signed approval.
    /// @dev The address cannot be zero
    /// @param owner The address of the token owner
    /// @param spender The address of the spender.
    /// @param value fixed amount to approve
    /// @param deadline deadline for the approvals in the future
    /// @param v, r, s valid `secp256k1` signature from `owner` over the EIP712-formatted function arguments.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (deadline < block.timestamp) {
            revert PermitExpired();
        }

        uint256 nonce;
        unchecked {
            nonce = _nonces[owner]++;
        }

        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));

        _verifySig(owner, hashStruct, v, r, s);

        _approve(owner, spender, value, 0);
    }

    /// @notice Sets renewable allowance with signed approval.
    /// @dev The address cannot be zero
    /// @param owner The address of the token owner
    /// @param spender The address of the spender.
    /// @param value fixed amount to approve
    /// @param recoveryRate recovery rate for the renewable allowance
    /// @param deadline deadline for the approvals in the future
    /// @param v, r, s valid `secp256k1` signature from `owner` over the EIP712-formatted function arguments.
    function permitRenewable(
        address owner,
        address spender,
        uint256 value,
        uint256 recoveryRate,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (deadline < block.timestamp) {
            revert PermitExpired();
        }
        uint256 nonce;
        unchecked {
            nonce = _nonces[owner]++;
        }

        bytes32 hashStruct = keccak256(
            abi.encode(PERMIT_RENEWABLE_TYPEHASH, owner, spender, value, recoveryRate, nonce, deadline)
        );

        _verifySig(owner, hashStruct, v, r, s);

        _approve(owner, spender, value, recoveryRate);
    }

    /// @inheritdoc IERC5827
    function approve(address _spender, uint256 _value) external returns (bool success) {
        _approve(_msgSender(), _spender, _value, 0);
        return true;
    }

    /// @inheritdoc IERC5827
    function approveRenewable(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate
    ) external returns (bool success) {
        _approve(_msgSender(), _spender, _value, _recoveryRate);
        return true;
    }

    /// @inheritdoc IERC5827Payable
    function approveRenewableAndCall(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate,
        bytes calldata data
    ) external returns (bool) {
        _approve(_msgSender(), _spender, _value, _recoveryRate);

        // if there is an issue in the checks, it should revert within the function
        _checkOnApprovalReceived(_spender, _value, _recoveryRate, data);
        return true;
    }

    /// @inheritdoc IERC5827
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        uint256 remainingAllowance = _remainingAllowance(from, _msgSender());
        if (remainingAllowance < amount) {
            revert InsufficientRenewableAllowance({ available: remainingAllowance });
        }

        if (remainingAllowance != type(uint256).max) {
            rAllowance[from][_msgSender()].remaining = remainingAllowance - amount;
            rAllowance[from][_msgSender()].lastUpdated = uint64(block.timestamp);
        }

        _baseToken.safeTransferFrom(from, to, amount);
        return true;
    }

    /// @inheritdoc IERC5827Payable
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool) {
        transferFrom(from, to, value);
        _checkOnTransferReceived(from, to, value, data);
        return true;
    }

    /// @notice Transfer tokens from the sender to the recipient
    /// @param to The address of the recipient
    /// @param amount uint256 The amount of tokens to be transferred
    function transfer(address to, uint256 amount) external returns (bool) {
        _baseToken.safeTransferFrom(_msgSender(), to, amount);
        return true;
    }

    /// =================================================================
    ///                 Getter Functions
    /// =================================================================

    /// @notice fetch approved max amount and recovery rate
    /// @param _owner The address of the owner
    /// @param _spender The address of the spender
    /// @return amount initial and maximum allowance given to spender
    /// @return recoveryRate recovery amount per second
    function renewableAllowance(address _owner, address _spender)
        external
        view
        returns (uint256 amount, uint256 recoveryRate)
    {
        RenewableAllowance memory a = rAllowance[_owner][_spender];
        return (a.maxAmount, a.recoveryRate);
    }

    /// @inheritdoc IERC5827
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        uint256 _baseAllowance = _baseToken.allowance(_owner, address(this));
        uint256 _renewableAllowance = _remainingAllowance(_owner, _spender);
        return _baseAllowance < _renewableAllowance ? _baseAllowance : _renewableAllowance;
    }

    /// @inheritdoc IERC5827Proxy
    function baseToken() external view returns (address) {
        return address(_baseToken);
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) external view returns (uint256 balance) {
        return _baseToken.balanceOf(account);
    }

    /// @inheritdoc IERC20
    function totalSupply() external view returns (uint256) {
        return _baseToken.totalSupply();
    }

    /// @notice Gets the name of the token
    /// @dev Fallback to token address if not found
    function name() public view returns (string memory) {
        string memory _name;
        (bool success, bytes memory result) = address(_baseToken).staticcall(abi.encodeWithSignature("name()"));

        if (success && result.length > 0) {
            _name = abi.decode(result, (string));
        } else {
            _name = Strings.toHexString(uint160(address(_baseToken)), 20);
        }

        return string.concat(_name, " (funnel)");
    }

    /// @notice Gets the domain separator
    /// @dev DOMAIN_SEPARATOR should be unique to the contract and chain to prevent replay attacks from
    /// other domains, and satisfy the requirements of EIP-712
    /// @return bytes32 the domain separator
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. See https://eips.ethereum.org/EIPS/eip-165
    /// @return `true` if the contract implements `interfaceID`
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC5827).interfaceId ||
            interfaceId == type(IERC5827Payable).interfaceId ||
            interfaceId == type(IERC5827Proxy).interfaceId;
    }

    /// =================================================================
    ///                 Internal Functions
    /// =================================================================

    /// @notice Fallback implementation
    /// @dev Delegates execution to an implementation contract (i.e. base token)
    /// This is a low level function that doesn't return to its internal call site.
    /// It will return to the external caller whatever the implementation returns.
    /// @param implementation Address to delegate.
    function _fallback(address implementation) internal view {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := staticcall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // staticcall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// @notice Internal function to process the approve
    /// Updates the mapping of `RenewableAllowance`
    /// @dev recoveryRate must be lesser than the value
    /// @param _owner The address of the owner
    /// @param _spender The address of the spender
    /// @param _value The amount of tokens to be approved
    /// @param _recoveryRate The amount of tokens to be recovered per second
    function _approve(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _recoveryRate
    ) internal {
        if (_recoveryRate > _value) {
            revert RecoveryRateExceeded();
        }

        rAllowance[_owner][_spender] = RenewableAllowance({
            maxAmount: _value,
            remaining: _value,
            recoveryRate: uint192(_recoveryRate),
            lastUpdated: uint64(block.timestamp)
        });
        emit Approval(_owner, _spender, _value);
        emit RenewableApproval(_owner, _spender, _value, _recoveryRate);
    }

    /// @notice Internal function to invoke {IERC1363Receiver-onTransferReceived} on a target address
    /// The call is not executed if the target address is not a contract
    /// @param from address Representing the previous owner of the given token amount
    /// @param recipient address Target address that will receive the tokens
    /// @param value uint256 The amount tokens to be transferred
    /// @param data bytes Optional data to send along with the call
    function _checkOnTransferReceived(
        address from,
        address recipient,
        uint256 value,
        bytes memory data
    ) internal {
        if (!Address.isContract(recipient)) {
            revert NotContractError();
        }

        try
            IERC1363Receiver(recipient).onTransferReceived(
                _msgSender(), // operator
                from,
                value,
                data
            )
        returns (bytes4 retVal) {
            if (retVal != IERC1363Receiver.onTransferReceived.selector) {
                revert InvalidReturnSelector();
            }
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                // Attempted to transfer to a non-IERC1363Receiver implementer
                revert NotIERC1363Receiver();
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /// @notice Internal function that is called after `approve` function.
    /// `onRenewableApprovalReceived` may revert. Function also checks if the address called is a IERC5827Spender
    /// @param _spender The address which will spend the funds
    /// @param _value The amount of tokens to be spent
    /// @param _recoveryRate The amount of tokens to be recovered per second
    /// @param data bytes Additional data with no specified format
    function _checkOnApprovalReceived(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate,
        bytes memory data
    ) internal {
        if (!Address.isContract(_spender)) {
            revert NotContractError();
        }

        try IERC5827Spender(_spender).onRenewableApprovalReceived(_msgSender(), _value, _recoveryRate, data) returns (
            bytes4 retVal
        ) {
            if (retVal != IERC5827Spender.onRenewableApprovalReceived.selector) {
                revert InvalidReturnSelector();
            }
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                // attempting to approve a non IERC5827Spender implementer
                revert NotIERC5827Spender();
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /// @notice fetch remaining allowance between _owner and _spender while accounting for base token allowance.
    /// @param _owner address of the owner
    /// @param _spender address of spender
    /// @return remaining allowance left
    function _remainingAllowance(address _owner, address _spender) private view returns (uint256) {
        RenewableAllowance memory a = rAllowance[_owner][_spender];

        uint256 recovered = uint256(a.recoveryRate) * uint64(block.timestamp - a.lastUpdated);
        uint256 remainingAllowance = MathUtil.saturatingAdd(a.remaining, recovered);

        return remainingAllowance > a.maxAmount ? a.maxAmount : remainingAllowance;
    }

    /// @notice compute the domain separator that is required for the approve by signature functionality
    /// Stops replay attacks from happening because of approvals on different contracts on different chains
    /// @dev Reference https://eips.ethereum.org/EIPS/eip-712
    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name())),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}
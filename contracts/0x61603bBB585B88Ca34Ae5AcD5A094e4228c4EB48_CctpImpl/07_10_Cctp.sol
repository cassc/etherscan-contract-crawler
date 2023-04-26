// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../helpers/errors.sol";
import "../ImplBase.sol";
import "../interfaces/cctp.sol";

contract CctpImpl is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    TokenMessenger public immutable tokenMessenger;
    address public immutable feeCollector;
    bytes32 constant CCTP = keccak256("cctp");

    event CctpBridgeSend(
        uint256 indexed integratorId
    );

    event SocketBridge(
        uint256 amount,
        address token,
        uint256 toChainId,
        bytes32 bridgeName,
        address sender,
        address receiver,
        bytes32 metadata
    );

    /// @notice Liquidity pool manager address and registry address required.
    constructor(
        TokenMessenger _tokenMessenger,
        address _feeCollector,
        address _registry
    ) ImplBase(_registry) {
        tokenMessenger = _tokenMessenger;
        feeCollector = _feeCollector;
    }

    /**
    // @notice Function responsible for cross chain transfer of supported assets from l2
    // to supported l2 and l1 chains. 
    // @dev Liquidity should be checked before calling this function. 
    // @param _amount amount to be sent.
    // @param _from senders address.
    // @param _receiverAddress receivers address.
    // @param _token token address on the source chain. 
    // param _data extra data that is required, not required in the case of Hyphen. 
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes memory _data // _data
    ) external payable override onlyRegistry nonReentrant {
        (uint32 destinationDomain, uint256 feeAmount, uint256 integratorId) = abi.decode(
            _data,
            (uint32, uint256, uint256)
        );
        if (_token == NATIVE_TOKEN_ADDRESS) {
            revert("Native token transfer not supported");
        }
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(
            address(tokenMessenger),
            _amount - feeAmount
        );
        IERC20(_token).transfer(feeCollector, feeAmount);
        tokenMessenger.depositForBurn(
            _amount - feeAmount,
            destinationDomain,
            bytes32(uint256(uint160(_receiverAddress))),
            _token
        );
        emit CctpBridgeSend(integratorId);
        emit SocketBridge(
            _amount,
            _token,
            _toChainId,
            CCTP,
            _from,
            _receiverAddress,
            bytes32(0)
        );
    }
}
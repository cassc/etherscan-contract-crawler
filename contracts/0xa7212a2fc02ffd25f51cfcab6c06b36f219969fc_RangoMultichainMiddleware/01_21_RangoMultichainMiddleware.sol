// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../../libraries/LibInterchain.sol";
import "../../utils/ReentrancyGuard.sol";
import "../base/RangoBaseInterchainMiddleware.sol";
import "../../interfaces/IMultichainRouter.sol";

/// @title The middleware contract that handles Rango's receive messages from Multichain.
/// @author George
/// @dev Note that this is not a facet and should be deployed separately.
contract RangoMultichainMiddleware is IRango, ReentrancyGuard, RangoBaseInterchainMiddleware, IAnycallProxy {

    /// @dev keccak256("exchange.rango.middleware.multichain")
    bytes32 internal constant MULTICHAIN_MIDDLEWARE_NAMESPACE = hex"0cf42af0773e60b292a649b87f9ceddb660d6e8bd489c0347d90c178f1d6ee6a";

    struct RangoMultichainMiddlewareStorage {
        /// @notice Addresses that can call exec on this contract
        mapping(address => bool) multichainExecutors;
    }

    function initMultichainMiddleware(
        address _owner,
        address _weth,
        address[] memory _executors
    ) external onlyOwner {
        initBaseMiddleware(_owner, address(0), _weth);
        if (_executors.length > 0)
            addMultichainExecutorsInternal(_executors);
    }

    /// Events
    /// @notice Notifies that some new router addresses are whitelisted
    /// @param _addresses The newly whitelisted addresses
    event MultichainExecutorsAdded(address[] _addresses);

    /// @notice Notifies that some router addresses are blacklisted
    /// @param _addresses The addresses that are removed
    event MultichainExecutorsRemoved(address[] _addresses);

    /// Only permit allowed executors
    modifier onlyAllowedExecutors(){
        require(getRangoMultichainMiddlewareStorage().multichainExecutors[msg.sender] == true, "not allowed");
        _;
    }

    /// External Functions
    /// @notice Adds a list of new addresses to the whitelisted MultichainOrg executors
    /// @param _executors The list of new executors
    function addMultichainExecutors(address[] memory _executors) public onlyOwner {
        addMultichainExecutorsInternal(_executors);
    }

    /// @notice Removes a list of executors from the whitelisted addresses
    /// @param _executors The list of addresses that should be deprecated
    function removeMultichainExecutors(address[] calldata _executors) external onlyOwner {
        removeMultichainExecutorsInternal(_executors);
    }


    /// @inheritdoc IAnycallProxy
    function exec(
        address token,
        address receiver,
        uint256 amount,
        bytes calldata data
    ) external payable nonReentrant onlyAllowedExecutors returns (bool success, bytes memory result){
        Interchain.RangoInterChainMessage memory m = abi.decode((data), (Interchain.RangoInterChainMessage));
        (address receivedToken, uint dstAmount, IRango.CrossChainOperationStatus status) = LibInterchain.handleDestinationMessage(token, amount, m);
        success = status == CrossChainOperationStatus.Succeeded;
        result = "";
        emit RangoBridgeCompleted(
            m.requestId,
            receivedToken,
            m.originalSender,
            m.recipient,
            dstAmount,
            status,
            m.dAppTag
        );
    }

    /// Private and Internal
    function addMultichainExecutorsInternal(address[] memory _executors) private {
        RangoMultichainMiddlewareStorage storage s = getRangoMultichainMiddlewareStorage();

        address tmpAddr;
        for (uint i = 0; i < _executors.length; i++) {
            tmpAddr = _executors[i];
            require(tmpAddr != address(0), "Invalid Executor Address");
            s.multichainExecutors[tmpAddr] = true;
        }
        emit MultichainExecutorsAdded(_executors);
    }

    function removeMultichainExecutorsInternal(address[] calldata _executors) private {
        RangoMultichainMiddlewareStorage storage s = getRangoMultichainMiddlewareStorage();
        for (uint i = 0; i < _executors.length; i++) {
            delete s.multichainExecutors[_executors[i]];
        }
        emit MultichainExecutorsRemoved(_executors);
    }


    /// @dev fetch local storage
    function getRangoMultichainMiddlewareStorage() private pure returns (RangoMultichainMiddlewareStorage storage s) {
        bytes32 namespace = MULTICHAIN_MIDDLEWARE_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}
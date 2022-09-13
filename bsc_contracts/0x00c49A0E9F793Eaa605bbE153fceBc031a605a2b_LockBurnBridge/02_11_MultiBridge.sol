// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

import "./Controller.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title MultiBridge: A contract for cross-chain transfers of a token
/// @author Empire Capital (Splnty)
/// @notice This contract allows for users to transfer tokens from one chain to another
/// @dev Supports the tracking of cross-chain transfers via hash-based IDs, ensures users fund the necessary gas cost for the migration based on a flag
abstract contract MultiBridge is Controller {
    using SafeERC20 for ERC20;
    using Address for address payable;

    mapping(uint256 => bool) public isSupportedChain;

    struct CrossChainTransfer {
        address to;
        bool processed;
        uint88 gasPrice;
        uint256 amount;
        uint256 chain;
    }

    // Numeric flag for processed inward transfers
    uint256 internal constant PROCESSED = type(uint256).max;
    // Gas Costs
    // - Process gas cost
    uint256 private constant PROCESS_COST = 65990;
    // - Unlock gas cost
    uint256 private constant UNLOCK_COST = 152982;

    // Holding all pending cross chain transfer info
    // - ID of cross chain transfers
    uint256 internal crossChainTransfer;
    // - Enforce funding supply from users
    bool internal forceFunding = true;
    // - Outward transfer data
    mapping(uint256 => CrossChainTransfer) public outwardTransfers;
    // - Inward gas price funding, used as a flag for processed txs via `PROCESSED`
    mapping(bytes32 => uint256) public inwardTransferFunding;

    event CrossChainTransferLocked(address indexed from, uint256 i);
    event CrossChainTransferProcessed(
        address indexed to,
        uint256 amount,
        uint256 chain
    );
    event CrossChainUnlockFundsReceived(
        address indexed to,
        uint256 amount,
        uint256 chain,
        uint256 orderId
    );
    event CrossChainTransferUnlocked(
        address indexed to,
        uint256 amount,
        uint256 chain
    );

    modifier validChain(uint256 chain) {
        _validChain(chain);
        _;
    }

    modifier validFunding() {
        _validFunding();
        _;
    }

    /// @param chainList Chain IDs of blockchains that are supported by the bridge
    constructor(uint256[] memory chainList)
        Controller()
    {
        for (uint256 i = 0; i < chainList.length; i++) {
            isSupportedChain[chainList[i]] = true;
        }
    }

    /// @notice Changes forceFunding to `_forceFunding`
    /// @dev When forceFunding = true, user pays for gas on transfers. When false, contract pays for gas.
    /// @param _forceFunding Toggles if forceFunding is enabled or not
    function setForceFunding(bool _forceFunding) external onlyOwner {
        forceFunding = _forceFunding;
    }

    /// @dev Adds/removes a chain to the list of supported chains
    /// @param _chainId The chain ID of the blockchain to add/remove to the supported chain list
    /// @param _whiteList Toggles if the chain is supported or not
    function whiteListChain(uint256 _chainId, bool _whiteList)
        external
        onlyOwner
    {
        isSupportedChain[_chainId] = _whiteList;
    }

    /// @dev Processes the bridge transaction to register on the other chain
    /// @dev Called by server after it catches event CrossChainTransferLocked
    /// @param i The bridge nonce
    function process(uint256 i) external onlyOperator {
        CrossChainTransfer memory cct = outwardTransfers[i];
        outwardTransfers[i].processed = true;
        if (forceFunding) {
            payable(msg.sender).sendValue(cct.gasPrice * PROCESS_COST);
        } else {
            cct.gasPrice = 0;
        }
        emit CrossChainTransferProcessed(cct.to, cct.amount, cct.chain);
    }

    /// @notice Bridge Tx `i` on `satelliteChain`: Receive `amount` of EMPIRE at address `to`
    /// @dev Called by the server to complete unlock of tokens on receiving chain
    /// @param satelliteChain The chain that tokens are being received from
    /// @param i The bridge nonce for the current transaction
    /// @param to The address that will receive the tokens
    /// @param amount The amount of tokens that are being received
    function fundUnlock(
        uint256 satelliteChain,
        uint256 i,
        address to,
        uint256 amount
    ) external payable {
        uint256 funds = msg.value / UNLOCK_COST;
        require(
            funds != 0,
            "MultiBridge::fundUnlock: Incorrect amount of funds supplied"
        );
        bytes32 h = keccak256(abi.encode(satelliteChain, i, to, amount));
        require(
            inwardTransferFunding[h] != PROCESSED,
            "MultiBridge::fundUnlock: Transaction already unlocked"
        );
        require(
            inwardTransferFunding[h] == 0,
            "MultiBridge::fundUnlock: Funding already provided"
        );
        inwardTransferFunding[h] = funds;
        emit CrossChainUnlockFundsReceived(to, amount, satelliteChain, i);
    }

    /// @dev Checks that chain of chain ID:`chain` is supported by the bridge
    /// @param chain The chain ID to check
    function _validChain(uint256 chain) private view {
        require(
            isSupportedChain[chain],
            "MultiBridge::lock: Invalid chain specified"
        );
    }

    /// @notice Checks that the user is providing enough gas to fund cross chain transfer.
    /// @dev Used in the validFunding modifier on the lock function. Not used if forceFunding = false.
    function _validFunding() private view {
        require(
            !forceFunding || tx.gasprice * PROCESS_COST <= msg.value,
            "MultiBridge::lock: Insufficient funds provided to fund migration"
        );
    }

    /// @dev Used by server to check that event CrossChainTransferProcessed fired correctly
    /// @param satelliteChain The chain that tokens are being received from
    /// @param i The bridge nonce for the checked transaction
    /// @param to The address that will receive the tokens
    /// @param amount The amount of tokens that are being transferred
    function checkTxProcessed(
        uint256 satelliteChain,
        uint256 i,
        address to,
        uint256 amount
    ) external view returns (bool) {
        return
            inwardTransferFunding[
                keccak256(abi.encode(satelliteChain, i, to, amount))
            ] == PROCESSED;
    }

    /// @notice Transfers `amount` of EMPIRE to address `to` on chain `chain`
    /// @dev Called by user to begin a cross chain transfer, locking tokens on outbund chain
    /// @param to The address that will receive the tokens
    /// @param amount The amount of tokens that are being sent
    /// @param chain The chain ID of the blockchain that the tokens are being sent to	
    function lock(
        address to,
        uint256 amount,
        uint256 chain
    ) external payable virtual;

    /// @notice Bridge Tx `i` on `satelliteChain`: Receive `amount` of EMPIRE at address `to`
    /// @dev Called by the server after catching event CrossChainUnlockFundsReceived to complete unlock of tokens
    /// @param satelliteChain The chain that tokens are being received from
    /// @param i The bridge nonce for the current transaction
    /// @param to The address that will receive the tokens
    /// @param amount The amount of tokens that are being received
    function unlock(
        uint256 satelliteChain,
        uint256 i,
        address to,
        uint256 amount
    ) external virtual;

    /// @notice Checks that the input 'n' is less than 32 bits
    /// @dev Saves gas by reducing a uin256 to a uint88
    /// @param n The gas price of the lock function when doing a cross chain transfer
    /// @param errorMessage The error message to display in case of fail
    /// @return Returns back the input uin256 in uint88 form
    function safe88(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint88)
    {
        require(n < type(uint88).max, errorMessage);
        return uint88(n);
    }
    
}
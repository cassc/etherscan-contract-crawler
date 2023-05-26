// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.2;

import "AccessControl.sol";
import "Pausable.sol";
import "SafeERC20.sol";
import "ERC20.sol";
import "ECDSA.sol";
import { Address } from "Address.sol";
import { Supervisor } from "Supervisor.sol";
import { IERC20MintBurnable } from "IERC20MintBurnable.sol";

/// @title XYCrossChainRelay relays token across different chains. It also inherits from ERC-20, which
/// serves as the redeemable tokens. Tokens are minted when liquidity is deposited and are burnt when
/// liquidity is withdrawn
contract XYCrossChainRelay is ERC20, AccessControl, Pausable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20MintBurnable;
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */

    address public constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Roles in this contract
    // Owner: the admin of `ROLE_MANAGER`
    bytes32 public constant ROLE_OWNER = keccak256("ROLE_OWNER");
    // Manager: able to pause/unpause contract
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
    // Staff: able to relay cross chain requests
    bytes32 public constant ROLE_STAFF = keccak256("ROLE_STAFF");

    /* ========== STATE VARIABLES ========== */

    uint32 public immutable thisChainId;
    // If `token` is Primitive Token, which means the token is not mint/burnable by us.
    // We can only transfer `token`s.
    bool public immutable isPrimitive;
    // A contract that supervises each cross chain relay by providing signatures
    Supervisor public immutable supervisor;
    // Token to be bridged
    address public immutable token;

    // If this flag is true, token bridge will be able to mint redeemable token to receiver when there is no liquidity during completeCrossChainRequest.
    // Otherwise, tx will fail when there is no liqiuidity.
    bool public isAbleToMintIfNoLiquidity;
    // Treasury where cross chain fees are sent to
    address public treasury;
    address public pendingTreasury;

    // Max amount of `token` allowed in each cross chain request
    uint256 public maxCrossChainAmount;

    // Number of the cross chain requests
    uint256 public numCrossChainRequests;

    // Mapping of completed cross chain requests: source chain id => request id => request
    mapping (uint32 => mapping (uint256 => bool)) public completedCrossChainRequest;

    /* ========== CONSTRUCTOR ========== */

    /// @param chainId The ID of this chain, passed in as param for easier configuration for testing
    /// @param _treasury The Treasury address
    /// @param _supervisor The Supervisor address
    /// @param owner The owner address
    /// @param manager The manager address
    /// @param staff The staff address
    /// @param _token The token address
    /// @param _isPrimitive Is `_token` primitive token (which we don't have mint/burn privilege)
    /// @param _maxCrossChainAmount Max cross chain amount
    /// @param _redeemableTokenName The name of the Redeemable Token
    /// @param _redeemableTokenSymbol The symbol of the Redeemable Token
    constructor(
        uint32 chainId,
        address _treasury,
        address _supervisor,
        address owner,
        address manager,
        address staff,
        address _token,
        bool _isPrimitive,
        uint256 _maxCrossChainAmount,
        string memory _redeemableTokenName,
        string memory _redeemableTokenSymbol
    ) ERC20(_redeemableTokenName, _redeemableTokenSymbol) {
        require(Address.isContract(_supervisor), "ERR_SUPERVISOR_NOT_CONTRACT");
        supervisor = Supervisor(_supervisor);
        // Token can only be either native (ETHER_ADDRESS) or ERC-20 token
        if (_token != ETHER_ADDRESS) {
            require(Address.isContract(_token), "ERR_TOKEN_NOT_CONTRACT");
        } else {
            // If it's native token, it must be primitive since we cannot mint/burn it
            require(_isPrimitive, "ERR_NATIVE_TOKEN_NOT_PRIMITIVE");
        }
        // Token can only be either native (ETHER_ADDRESS) or ERC-20 token
        token = _token;

        thisChainId = chainId;
        isPrimitive = _isPrimitive;

        treasury = _treasury;
        maxCrossChainAmount = _maxCrossChainAmount;

        _setRoleAdmin(ROLE_OWNER, ROLE_OWNER);
        _setRoleAdmin(ROLE_MANAGER, ROLE_OWNER);
        _setRoleAdmin(ROLE_STAFF, ROLE_MANAGER);
        _setupRole(ROLE_OWNER, owner);
        _setupRole(ROLE_MANAGER, manager);
        _setupRole(ROLE_STAFF, staff);
    }

    /* ========== MODIFIERS ========== */
    modifier onlyPrimitiveToken() {
        require(isPrimitive, "ERR_NOT_PRIMITIVE_TOKEN");
        _;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /// @notice Transfer ERC-20 token from user and check balance change
    /// @param sender The address to transfer token from
    /// @param amount Amount of the token to be transferred
    function _safeTransferAssetFrom(address sender, uint256 amount) private {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(sender, address(this), amount);
        bal = IERC20(token).balanceOf(address(this)) - bal;
        require(bal == amount, "ERR_AMOUNT_NOT_ENOUGH");
    }

    /// @notice Unified transfer interface for native token and ERC20 token
    /// @param _token Address of the token. Can be either `ETH_ADDRESS` for native token or ERC-20 token address
    /// @param receiver The address to receive token
    /// @param amount Amount of the token to be transferred
    function _safeTransferTokenUnified(address _token, address receiver, uint256 amount) private {
        if (_token == ETHER_ADDRESS) {
            payable(receiver).transfer(amount);
        } else {
            IERC20(_token).safeTransfer(receiver, amount);
        }
    }

    /// @notice Unified get balance interface for native token and ERC20 token
    /// @param _token Address of the token. Can be either `ETH_ADDRESS` for native token or ERC-20 token address
    function _getTokenBalanceUnified(address _token) view private returns (uint256) {
        if (_token == ETHER_ADDRESS)  {
            return address(this).balance;
        } else {
            return IERC20(_token).balanceOf(address(this));
        }
    }

    /* ========== RESTRICTED FUNCTIONS (TREASURY) ========== */

    function proposeNewTreasury(address newTreasury) external {
        require(msg.sender == treasury, "ERR_NOT_TREASURY");
        pendingTreasury = newTreasury;
        emit NewTreasuryProposed(newTreasury);
    }

    function acceptNewTreasury() external {
        require(msg.sender == pendingTreasury, "ERR_NOT_PENDING_TREASURY");
        pendingTreasury = address(0);
        treasury = msg.sender;
        emit NewTreasuryAccepted(msg.sender);
    }

    /* ========== RESTRICTED FUNCTIONS (OWNER) ========== */

    /// @notice Rescue fund accidentally sent to this contract. Token can be rescued only if it's not `token`
    /// @param tokens List of token address to rescue
    function rescue(IERC20[] memory tokens) external onlyRole(ROLE_OWNER) {
        for (uint256 i; i < tokens.length; i++) {
            IERC20 _token = tokens[i];
            require(token != address(_token), "ERR_CAN_NOT_RESCUE_BRIDGE_TOKEN");
            uint256 _tokenBalance = _getTokenBalanceUnified(address(_token));
            _safeTransferTokenUnified(address(_token), msg.sender, _tokenBalance);
        }
    }

    /* ========== RESTRICTED FUNCTIONS (MANAGER) ========== */

    /// @notice Pause the contract (could be executed only by manager)
    function pause() external onlyRole(ROLE_MANAGER) {
        _pause();
    }

    /// @notice Unpause the contract (could be executed only by manager)
    function unpause() external onlyRole(ROLE_MANAGER) {
        _unpause();
    }

    /// @notice Set max cross chain amount (could be executed only by manager)
    /// @param newMaxCrossChainAmount New max cross chain amount
    function setMaxCrossChainAmount(uint256 newMaxCrossChainAmount) external onlyRole(ROLE_MANAGER) {
        maxCrossChainAmount = newMaxCrossChainAmount;
    }

    /// @notice Set isAbleToMintIfNoLiquidity flag
    /// @param _set Switch on or off isAbleToMintIfNoLiquidity
    function setIsAbleToMintIfNoLiquidity(bool _set) external onlyPrimitiveToken onlyRole(ROLE_MANAGER) {
        isAbleToMintIfNoLiquidity = _set;
        emit IsAbleToMintIfNoLiquiditySet(msg.sender, _set);
    }

    /* ========== RESTRICTED FUNCTIONS (STAFF) ========== */

    /// @notice Complete a cross chain request
    /// @param requestId ID of the cross chain request on the source chain
    /// @param sourceChainId Chain Id of the source chain
    /// @param receiver Receiver of the `token`
    /// @param amount Amount of `token`
    /// @param fee Fee amount (denominated in `token`)
    /// @param signatures Signatures of validators
    function completeCrossChainRequest(uint256 requestId, uint32 sourceChainId, address receiver, uint256 amount, uint256 fee, bytes[] memory signatures) external whenNotPaused onlyRole(ROLE_STAFF) {
        require(!completedCrossChainRequest[sourceChainId][requestId], "ERR_CROSS_CHAIN_REQUEST_ALREADY_COMPLETE");
        require(amount > fee, "ERR_FEE_GREATER_THAN_AMOUNT");
        require(amount <= maxCrossChainAmount, "ERR_INVALID_CROSS_CHAIN_AMOUNT");

        bytes32 sigId = keccak256(abi.encodePacked(supervisor.VALIDATE_XY_CROSS_CHAIN_IDENTIFIER(), address(this), sourceChainId, thisChainId, requestId, receiver, amount, fee));
        bytes32 sigIdHash = sigId.toEthSignedMessageHash();
        supervisor.checkSignatures(sigIdHash, signatures);
        uint256 amountSubFee = amount - fee;

        bool isRedeemableTokenMinted = false;
        if (isPrimitive) {
            if (checkBridgeLiquidityEnough(amount)) {
                _safeTransferTokenUnified(token, receiver, amountSubFee);
                _safeTransferTokenUnified(token, treasury, fee);
            } else {
                require(isAbleToMintIfNoLiquidity, "ERR_NO_MINT_WHEN_NO_LIQUIDITY");
                isRedeemableTokenMinted = true;
                // Mint redeemable token to receiver
                _mint(receiver, amountSubFee);
                _mint(treasury, fee);
            }
        } else {
            IERC20MintBurnable(token).mint(receiver, amountSubFee);
            IERC20MintBurnable(token).mint(treasury, fee);
        }

        completedCrossChainRequest[sourceChainId][requestId] = true;
        emit CrossChainCompleted(requestId, sourceChainId, thisChainId, receiver, amount, fee, isRedeemableTokenMinted);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice check if token bridge liquidity is enough
    /// @param amount Amount of `token`
    function checkBridgeLiquidityEnough(uint256 amount) public view returns (bool) {
        uint256 balance = _getTokenBalanceUnified(token);
        return (amount <= balance);
    }

    /* ========== WRITE FUNCTIONS ========== */

    /// @notice Request to bridge `token` cross chain
    /// @param destChainId Chain Id of the destination chain
    /// @param receiver Receiver of the `token` on destination chain
    /// @param amount Amount of `token` to send cross chain
    function requestCrossChain(uint32 destChainId, address receiver, uint256 amount) external payable whenNotPaused {
        require(amount > 0 && amount <= maxCrossChainAmount, "ERR_INVALID_CROSS_CHAIN_AMOUNT");

        uint256 id = numCrossChainRequests++;
        // Transfer token from sender
        if (token == ETHER_ADDRESS) {
            require(msg.value == amount, "ERR_MSG_VALUE_AMOUNT_MISMATCHED");
        } else {
            require(msg.value == 0, "ERR_EXPECTED_ZERO_MSG_VALUE");
            _safeTransferAssetFrom(msg.sender, amount);
            if (!isPrimitive) {
                IERC20MintBurnable(token).burn(amount);
            }
        }

        emit CrossChainRequested(id, thisChainId, destChainId, msg.sender, receiver, amount);
    }

    function deposit(uint256 amount) payable external whenNotPaused onlyPrimitiveToken {
        require(amount > 0, "ERR_ZERO_AMOUNT");
        // Transfer token from depositor
        if (token == ETHER_ADDRESS) {
            require(msg.value == amount, "ERR_MSG_VALUE_AMOUNT_MISMATCHED");
        } else {
            require(msg.value == 0, "ERR_EXPECTED_ZERO_MSG_VALUE");
            _safeTransferAssetFrom(msg.sender, amount);
        }

        // Mint 1:1 LP token to depositor
        _mint(msg.sender, amount);
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external whenNotPaused onlyPrimitiveToken {
        require(amount > 0, "ERR_ZERO_AMOUNT");
        // Burn withdrawer LP token
        _burn(msg.sender, amount);
        // Transfer 1:1 token to withdrawer.
        _safeTransferTokenUnified(token, msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /* ========== EVENTS ========== */

    event NewTreasuryProposed(address newTreasury);
    event NewTreasuryAccepted(address newTreasury);
    event CrossChainRequested(uint256 indexed requestId, uint32 sourceChainId, uint32 indexed destChainId, address indexed sender, address receiver, uint256 amount);
    event CrossChainCompleted(uint256 indexed requestId, uint32 indexed sourceChainId, uint32 destChainId, address indexed receiver, uint256 amount, uint256 fee, bool isRedeemableTokenMinted);
    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed sender, uint256 amount);
    event IsAbleToMintIfNoLiquiditySet(address sender, bool isSet);
}
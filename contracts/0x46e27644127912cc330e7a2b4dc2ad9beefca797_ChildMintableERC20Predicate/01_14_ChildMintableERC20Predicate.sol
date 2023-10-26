// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/root/IChildMintableERC20Predicate.sol";
import "../interfaces/child/IChildERC20.sol";
import "../interfaces/IStateSender.sol";

/**
    @title ChildMintableERC20Predicate
    @author Polygon Technology (@QEDK)
    @notice Enables ERC20 token deposits and withdrawals across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract ChildMintableERC20Predicate is Initializable, IChildMintableERC20Predicate {
    using SafeERC20 for IERC20;

    IStateSender public stateSender;
    address public exitHelper;
    address public rootERC20Predicate;
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");

    mapping(address => address) public rootTokenToChildToken;

    /**
     * @notice Initialization function for ChildMintableERC20Predicate
     * @param newStateSender Address of StateSender to send deposit information to
     * @param newExitHelper Address of ExitHelper to receive withdrawal information from
     * @param newRootERC20Predicate Address of root ERC20 predicate to communicate with
     * @dev Can only be called once.
     */
    function initialize(
        address newStateSender,
        address newExitHelper,
        address newRootERC20Predicate,
        address newChildTokenTemplate
    ) external virtual initializer {
        _initialize(newStateSender, newExitHelper, newRootERC20Predicate, newChildTokenTemplate);
    }

    /**
     * @notice Function to be used for token deposits
     * @param sender Address of the sender on the root chain
     * @param data Data sent by the sender
     * @dev Can be extended to include other signatures for more functionality
     */
    function onL2StateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == exitHelper, "ChildMintableERC20Predicate: ONLY_STATE_RECEIVER");
        require(sender == rootERC20Predicate, "ChildMintableERC20Predicate: ONLY_ROOT_PREDICATE");

        if (bytes32(data[:32]) == DEPOSIT_SIG) {
            _beforeTokenDeposit();
            _deposit(data[32:]);
            _afterTokenDeposit();
        } else if (bytes32(data[:32]) == MAP_TOKEN_SIG) {
            _mapToken(data);
        } else {
            revert("ChildMintableERC20Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @notice Function to withdraw tokens from the withdrawer to themselves on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param amount Amount to withdraw
     */
    function withdraw(IChildERC20 childToken, uint256 amount) external {
        _beforeTokenWithdraw();
        _withdraw(childToken, msg.sender, amount);
        _afterTokenWithdraw();
    }

    /**
     * @notice Function to withdraw tokens from the withdrawer to another address on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param receiver Address of the receiver on the root chain
     * @param amount Amount to withdraw
     */
    function withdrawTo(IChildERC20 childToken, address receiver, uint256 amount) external {
        _beforeTokenWithdraw();
        _withdraw(childToken, receiver, amount);
        _afterTokenWithdraw();
    }

    /**
     * @notice Internal initialization function for ChildERC20Predicate
     * @param newStateSender Address of L2StateSender to send exit information to
     * @param newExitHelper Address of StateReceiver to receive deposit information from
     * @param newRootERC20Predicate Address of root ERC20 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @dev Can be called multiple times.
     */
    function _initialize(
        address newStateSender,
        address newExitHelper,
        address newRootERC20Predicate,
        address newChildTokenTemplate
    ) internal {
        require(
            newStateSender != address(0) &&
                newExitHelper != address(0) &&
                newRootERC20Predicate != address(0) &&
                newChildTokenTemplate != address(0),
            "ChildMintableERC20Predicate: BAD_INITIALIZATION"
        );
        stateSender = IStateSender(newStateSender);
        exitHelper = newExitHelper;
        rootERC20Predicate = newRootERC20Predicate;
        childTokenTemplate = newChildTokenTemplate;
    }

    // solhint-disable no-empty-blocks
    function _beforeTokenDeposit() internal virtual {}

    // slither-disable-next-line dead-code
    function _beforeTokenWithdraw() internal virtual {}

    function _afterTokenDeposit() internal virtual {}

    function _afterTokenWithdraw() internal virtual {}

    function _withdraw(IChildERC20 childToken, address receiver, uint256 amount) private {
        require(address(childToken).code.length != 0, "ChildMintableERC20Predicate: NOT_CONTRACT");

        address rootToken = childToken.rootToken();

        require(rootTokenToChildToken[rootToken] == address(childToken), "ChildMintableERC20Predicate: UNMAPPED_TOKEN");
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(childToken.predicate() == address(this));

        require(childToken.burn(msg.sender, amount), "ChildMintableERC20Predicate: BURN_FAILED");
        stateSender.syncState(rootERC20Predicate, abi.encode(WITHDRAW_SIG, rootToken, msg.sender, receiver, amount));

        // slither-disable-next-line reentrancy-events
        emit MintableERC20Withdraw(rootToken, address(childToken), msg.sender, receiver, amount);
    }

    function _deposit(bytes calldata data) private {
        (address depositToken, address depositor, address receiver, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256)
        );

        IChildERC20 childToken = IChildERC20(rootTokenToChildToken[depositToken]);

        require(address(childToken) != address(0), "ChildMintableERC20Predicate: UNMAPPED_TOKEN");
        assert(address(childToken).code.length != 0);

        address rootToken = IChildERC20(childToken).rootToken();

        // a mapped child token should match deposited token
        assert(rootToken == depositToken);
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(IChildERC20(childToken).predicate() == address(this));

        require(IChildERC20(childToken).mint(receiver, amount), "ChildMintableERC20Predicate: MINT_FAILED");

        // slither-disable-next-line reentrancy-events
        emit MintableERC20Deposit(depositToken, address(childToken), depositor, receiver, amount);
    }

    /**
     * @notice Function to be used for mapping a root token to a child token
     * @dev Allows for 1-to-1 mappings for any root token to a child token
     */
    function _mapToken(bytes calldata data) private {
        (, address rootToken, string memory name, string memory symbol, uint8 decimals) = abi.decode(
            data,
            (bytes32, address, string, string, uint8)
        );
        assert(rootToken != address(0)); // invariant since root predicate performs the same check
        assert(rootTokenToChildToken[rootToken] == address(0)); // invariant since root predicate performs the same check
        IChildERC20 childToken = IChildERC20(
            Clones.cloneDeterministic(childTokenTemplate, keccak256(abi.encodePacked(rootToken)))
        );
        rootTokenToChildToken[rootToken] = address(childToken);
        childToken.initialize(rootToken, name, symbol, decimals);

        // slither-disable-next-line reentrancy-events
        emit MintableTokenMapped(rootToken, address(childToken));
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
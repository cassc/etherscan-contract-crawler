// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./Rebalancer.sol";
import "../interfaces/IWETH.sol";

contract PositionManager is Rebalancer, EIP712, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // address => bitmap holding used withdrawal nonces
    mapping(address => BitMaps.BitMap) internal usedNonces;

    mapping(address => bool) public registeredAssets;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _DEPOSIT_PERMIT_TYPEHASH =
        keccak256("DepositPermit(address asset,address beneficiary,uint256 amount,uint256 nonce,uint256 deadline)");
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _WITHDRAW_PERMIT_TYPEHASH =
        keccak256("WithdrawPermit(address asset,address beneficiary,uint256 amount,uint256 nonce,uint256 deadline)");

    enum SigAction {
        Deposit,
        Withdraw
    }

    event PositionManagerDeposited(address asset, address beneficiary, uint256 amount, uint256 nonce);
    event PositionManagerWithdrawn(address asset, address beneficiary, uint256 amount, uint256 nonce);
    event NewAssetManagerSet(address newAssetManager);
    event AssetRegistrationManaged(address token, bool status);

    modifier requireNonZero(address asset, uint256 amount) {
        require(asset != address(0), "asset not set");
        require(amount > 0, "amount is zero");

        _;
    }

    constructor() EIP712("PositionManager", "1") {}

    /// @dev wrap native token for deposit
    /// @param wethAddress chain specific address to wrap native token
    /// @param nonce the user nonce for deposits.
    /// @param deadline the number of the last block where the deposit is accepted.
    /// @param signature ECDSA signature.
    function depositAndWrapNativeToken(
        address wethAddress,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external payable requireNonZero(wethAddress, msg.value) {
        require(registeredAssets[wethAddress], "wrapped asset not registered");

        uint256 amount = msg.value;

        uint256 balanceBefore = IERC20(wethAddress).balanceOf(address(this));

        _validateSig(msg.sender, wethAddress, amount, nonce, deadline, signature, SigAction.Deposit);

        IWETH(wethAddress).deposit{value: amount}();

        uint256 balanceAfter = IERC20(wethAddress).balanceOf(address(this));

        require(balanceAfter - balanceBefore == amount, "deposit failed");

        emit PositionManagerDeposited(wethAddress, msg.sender, amount, nonce);
    }

    /// @dev Supplies ERC20 asset
    /// @param asset ERC20 address
    /// @param amount The amount to be supplied
    /// @param nonce the user nonce for deposits.
    /// @param deadline the number of the last block where the deposit is accepted.
    /// @param signature ECDSA signature.
    function depositInPositionManager(
        address asset,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external requireNonZero(asset, amount) {
        require(registeredAssets[asset], "asset not registered");
        require(IERC20(asset).allowance(msg.sender, address(this)) >= amount, "insufficient allowance");

        _validateSig(msg.sender, asset, amount, nonce, deadline, signature, SigAction.Deposit);

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        emit PositionManagerDeposited(asset, msg.sender, amount, nonce);
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @dev withdraw native tokens by unwrapping them
    /// @param wethAddress chain specific address to wrap native token
    /// @param amount The amount to be withdrawn
    /// @param nonce the user nonce.
    /// @param deadline the number of the last block where the withdraw is accepted.
    /// @param signature ECDSA signature.
    function withdrawAndUnwrapNativeToken(
        address wethAddress,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external payable nonReentrant requireNonZero(wethAddress, amount) {
        require(registeredAssets[wethAddress], "wrapped asset not registered");

        _validateSig(msg.sender, wethAddress, amount, nonce, deadline, signature, SigAction.Withdraw);

        uint256 balanceBefore = IERC20(wethAddress).balanceOf(address(this));
        // unwrap weth and send native token to user
        IWETH(wethAddress).withdraw(amount);
        uint256 balanceAfter = IERC20(wethAddress).balanceOf(address(this));
        require(balanceBefore - balanceAfter == amount, "withdraw failed");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "transfer failed");

        emit PositionManagerWithdrawn(wethAddress, msg.sender, amount, nonce);
    }

    // Function to receive Ether. msg.data must be empty. Used when withdrawing native tokens
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /// @dev Withdraw ERC20 or native asset permitted by assetManager
    /// @param asset the address of the asset to be withdrawn.
    /// @param amount the amount to withdraw.
    /// @param nonce the user nonce for withdrawls.
    /// @param deadline the number of the last block where the withdraw is accepted.
    /// @param signature ECDSA signature.
    function withdrawFromPositionManager(
        address asset,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external nonReentrant requireNonZero(asset, amount) {
        _validateSig(msg.sender, asset, amount, nonce, deadline, signature, SigAction.Withdraw);

        IERC20(asset).safeTransfer(msg.sender, amount);

        emit PositionManagerWithdrawn(asset, msg.sender, amount, nonce);
    }

    /// private functions

    /// @notice withdraws from position manager
    function _validateSig(
        address _beneficiary,
        address _asset,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature,
        SigAction _action
    ) private {
        require(block.number <= _deadline, "expired deadline");

        // nonce was not used before
        require(!BitMaps.get(usedNonces[_beneficiary], _nonce), "Invalid nonce");

        bytes32 permitHash = _action == SigAction.Deposit ? _DEPOSIT_PERMIT_TYPEHASH : _WITHDRAW_PERMIT_TYPEHASH;

        bytes32 structHash = keccak256(abi.encode(permitHash, _asset, _beneficiary, _amount, _nonce, _deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, _signature);
        require(signer == rebalanceManager, "invalid signature");

        // mark nonce as being used
        BitMaps.set(usedNonces[_beneficiary], _nonce);
    }

    // restricted Only called as rebalance manager

    /// @notice rebalance manager check happens in _withdrawForRebalance
    function withdrawAsRebalanceManager(address[] calldata tokens, uint256[] calldata amounts) external {
        super._withdrawForRebalance(tokens, amounts);
    }

    /// @notice rebalance manager check happens _rebalance
    function rebalance(address[] calldata tokens, uint256[] calldata amounts) external {
        super._rebalance(tokens, amounts);
    }

    /// @dev set register addresses. Only called by asset manager
    /// @param tokens array of token addresses
    /// @param statuses array of bools to set status of token
    function manageAssetRegister(address[] calldata tokens, bool[] calldata statuses) external onlyRebalanceManager {
        require(tokens.length == statuses.length, "incorrect params length");

        uint256 length = tokens.length;

        for (uint256 i = 0; i < length; ) {
            registeredAssets[tokens[i]] = statuses[i];

            emit AssetRegistrationManaged(tokens[i], statuses[i]);

            unchecked {
                ++i;
            }
        }
    }
}
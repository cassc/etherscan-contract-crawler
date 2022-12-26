// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './interfaces/ISwapRouter.sol';

contract CoinmapDex is EIP712, Ownable, Pausable {
    using SafeERC20 for IERC20;

    enum OrderStatus {
        OPEN,
        FILLED,
        CANCELED
    }

    struct Order {
        address maker;
        address payToken;
        address buyToken;
        uint256 payAmount;
        uint256 buyAmount;
        uint256 deadline;
        bytes32 salt;
    }

    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            'Order(address maker,address payToken,address buyToken,uint256 payAmount,uint256 buyAmount,uint256 deadline,bytes32 salt)'
        );
    uint256 public constant MAX_FEE = 500; // 5%

    ISwapRouter public swapRouter;
    address public feeTo;
    uint256 public feeRate;

    mapping(address => mapping(bytes32 => bool)) public makerSaltUsed;

    event UpdateStatus(address indexed maker, bytes32 salt, OrderStatus status);
    event UpdateFeeTo(address indexed newFeeTo);
    event UpdateFeeRate(uint256 indexed newFeeRate);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);

    /**
     * @notice Constructor
     * @param _swapRouter: pancake router address
     * @param _feeTo: address to collect fee
     * @param _feeRate: fee rate (100 = 1%, 500 = 5%, 5 = 0.05%)
     */
    constructor(
        ISwapRouter _swapRouter,
        address _feeTo,
        uint256 _feeRate
    ) public EIP712('CoinmapDex', '1') {
        require(_feeRate < MAX_FEE, 'CMD001');
        swapRouter = _swapRouter;
        feeTo = _feeTo;
        feeRate = _feeRate;
    }

    /**
     * @notice Execute an order
     * @param signer: address of order signer
     * @param order: order information
     * @param signature: order signature
     * @param paths: path to execute the order
     * @dev Order maker must have allowance for this contract of at least order payAmount.
     */
    function executeOrder(
        address signer,
        Order calldata order,
        bytes calldata signature,
        address[] calldata paths
    ) external whenNotPaused {
        require(!makerSaltUsed[order.maker][order.salt], 'CMD001');
        require(isValidSigner(order.maker, signer), 'CMD002');
        require(verify(signer, order, signature), 'CMD003');
        require(paths[0] == order.payToken, 'CMD004');
        require(paths[paths.length - 1] == order.buyToken, 'CMD005');
        makerSaltUsed[order.maker][order.salt] = true;

        uint256 payAmount = swapRouter.getAmountsIn(order.buyAmount, paths)[0];
        uint256 feeAmount = (payAmount * feeRate) / 10000;
        require(payAmount + feeAmount <= order.payAmount, 'CMD006');
        IERC20(paths[0]).safeTransferFrom(order.maker, address(this), payAmount + feeAmount);
        IERC20(paths[0]).safeApprove(address(swapRouter), payAmount);
        uint256[] memory amounts = swapRouter.swapTokensForExactTokens(
            order.buyAmount,
            order.payAmount,
            paths,
            order.maker,
            order.deadline
        );
        require(amounts[amounts.length - 1] >= order.buyAmount, 'CMD007');
        IERC20(paths[0]).safeTransfer(feeTo, feeAmount);
        emit UpdateStatus(order.maker, order.salt, OrderStatus.FILLED);
    }

    /**
     * @notice Cancel an order
     * @param maker: address of order maker
     * @param salt: salt of order to cancel
     */
    function cancelOrder(address maker, bytes32 salt) external {
        require(!makerSaltUsed[maker][salt], 'CMD001');
        require(isValidSigner(maker, msg.sender), 'CMD002');
        makerSaltUsed[maker][salt] = true;
        emit UpdateStatus(maker, salt, OrderStatus.CANCELED);
    }

    /**
     * @notice Set new address to collect fee
     * @param _feeTo: address to collect fee
     */
    function setFeeTo(address _feeTo) external onlyOwner {
        require(_feeTo != address(0), 'CMD001');
        feeTo = _feeTo;
        emit UpdateFeeTo(feeTo);
    }

    /**
     * @notice Set new fee rate
     * @param _feeRate: new fee rate (100 = 1%, 500 = 5%, 5 = 0.05%)
     */
    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate < MAX_FEE, 'CMD001');
        feeRate = _feeRate;
        emit UpdateFeeRate(feeRate);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Verify that the order was signed by the signer
     * @param signer: address to signer
     * @param order: order information
     * @param signature: order signature
     */
    function verify(
        address signer,
        Order calldata order,
        bytes calldata signature
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(hashOrder(order));
        return signer == ECDSA.recover(digest, signature);
    }

    function hashOrder(Order calldata order) public pure returns (bytes32) {
        return keccak256(abi.encode(ORDER_TYPEHASH, order));
    }

    function isValidSigner(address maker, address signer) public pure returns (bool) {
        return signer == maker;
    }
}
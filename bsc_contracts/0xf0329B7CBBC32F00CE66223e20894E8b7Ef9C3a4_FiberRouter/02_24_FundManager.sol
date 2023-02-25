// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../common/signature/SigCheckable.sol";
import "../common/SafeAmount.sol";
import "../common/WithAdmin.sol";
import "../taxing/IGeneralTaxDistributor.sol";
import "hardhat/console.sol";

contract FundManager is SigCheckable, WithAdmin {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public router;
    uint256 constant MAX_FEE = 0.1 * 10000; // 10% max fee
    string constant NAME = "FUND MANAGER";
    string constant VERSION = "000.004";
    bytes32 constant WITHDRAW_SIGNED_METHOD =
        keccak256(
            "WithdrawSigned(address token,address payee,uint256 amount,bytes32 salt)"
        );

    mapping(address => bool) public signers;
    mapping(address => uint256) public fees;
    mapping(address => mapping(uint256 => address)) public allowedTargets;
    mapping(address => mapping(string => string)) public nonEvmAllowedTargets;
    address public feeDistributor;
    mapping(address => bool) public isFoundryAsset;
    mapping(address => mapping(address => uint256)) private liquidities;

    event TransferBySignature(
        address signer,
        address receiver,
        address token,
        uint256 amount,
        uint256 fee
    );
    event BridgeLiquidityAdded(address actor, address token, uint256 amount);
    event BridgeLiquidityRemoved(address actor, address token, uint256 amount);
    event BridgeSwap(
        address from,
        address indexed token,
        uint256 targetNetwork,
        address targetToken,
        address targetAddrdess,
        uint256 amount
    );
    event nonEvmBridgeSwap(
        address from,
        address indexed token,
        string targetNetwork,
        string targetToken,
        string targetAddrdess,
        uint256 amount
    );

    modifier onlyRouter() {
        require(msg.sender == router, "BP: Only router method");
        _;
    }

    //initialize function is constructor for upgradeable smart contract
    function initialize() external initializer {
        __EIP712_init(NAME, VERSION);
        __Ownable_init();
    }

    /**
     @dev only callable by admin
     @param _router fiber router address
     @notice set the fiber router address
    */
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "BP: router requried");
        router = _router;
    }

    /**
     @dev only callable by admin
     @param _signer signer's address
     @notice set the signer address
    */
    function addSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Bad signer");
        signers[_signer] = true;
    }

    /**
     @dev only callable by admin
     @param _signer signer's address
     @notice remove address from a signers
    */
    function removeSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Bad signer");
        delete signers[_signer];
    }

    /**
     @dev only callable by admin
     @param _feeDistributor fee distributor's address
     @notice add address as an fee distributor
    */
    function setFeeDistributor(address _feeDistributor) external onlyOwner {
        feeDistributor = _feeDistributor;
    }

    /**
     @dev only callable by admin
     @param token token as a fee
     @param fee10000 fee
     @notice set fee against a specific token
     */
    function setFee(address token, uint256 fee10000) external onlyAdmin {
        require(token != address(0), "Bad token");
        require(fee10000 <= MAX_FEE, "Fee too large");
        fees[token] = fee10000;
    }

    /**
     @dev only callable by admin
     @param token token need set against target
     @param chainId the target chain id
     @param targetToken target token address
     @notice allow target against token
     */
    function allowTarget(
        address token,
        uint256 chainId,
        address targetToken
    ) external onlyAdmin {
        require(token != address(0), "Bad token");
        require(targetToken != address(0), "Bad targetToken");
        require(chainId != 0, "Bad chainId");
        allowedTargets[token][chainId] = targetToken;
    }

    /**
     @dev only callable by admin
     @param token token need set against target
     @param chainId the target chain id
     @param targetToken target token address
     @notice allow target against token
     */
    function nonEvmAllowTarget(
        address token,
        string memory chainId,
        string memory targetToken
    ) external onlyAdmin {
        require(token != address(0), "Bad token");
        nonEvmAllowedTargets[token][chainId] = targetToken;
    }

    /**
     @dev only callable by admin
     @param token token need remove against target
     @param chainId the target chain id
     @notice allow disallow target against token
     */
    function disallowTarget(address token, uint256 chainId) external onlyAdmin {
        require(token != address(0), "Bad token");
        require(chainId != 0, "Bad chainId");
        delete allowedTargets[token][chainId];
    }

    /**
     @dev only callable by admin
     @param token token need remove against target
     @param chainId the target chain id
     @notice allow disallow target against token
     */
    function nonEvmDisallowTarget(address token, string memory chainId)
        external
        onlyAdmin
    {
        require(token != address(0), "Bad token");
        delete nonEvmAllowedTargets[token][chainId];
    }

    /**
     @dev only callable by admin
     @param token token need to added as foundry asset
     @notice allow disallow target against token
     */
    function addFoundryAsset(address token) external onlyAdmin {
        require(token != address(0), "Bad token");
        isFoundryAsset[token] = true;
    }

    /**
     @dev only callable by admin
     @param token token need to remove as foundry asset
     @notice allow disallow target against token
     */
    function removeFoundryAsset(address token) external onlyAdmin {
        require(token != address(0), "Bad token");
        isFoundryAsset[token] = false;
    }

    /**
     @dev publically swap
     @param token the tokens want to swap
     @param amount the amount to be swapped
     @param targetNetwork target network the to network
     @param targetToken the end token address
     @notice only callable by router
     */
    function swap(
        address token,
        uint256 amount,
        uint256 targetNetwork,
        address targetToken
    ) external onlyRouter returns (uint256) {
        return
            _swap(
                msg.sender,
                token,
                amount,
                targetNetwork,
                targetToken,
                msg.sender
            );
    }

    /**
     @dev publically swap
     @param token the tokens want to swap
     @param amount the amount to be swapped
     @param targetNetwork target network the to network
     @param targetToken the end token address
     @notice only callable by router
     */
    function swapToAddress(
        address token,
        uint256 amount,
        uint256 targetNetwork,
        address targetToken,
        address targetAddress
    ) external onlyRouter returns (uint256) {
        require(
            targetAddress != address(0),
            "BridgePool: targetAddress is required"
        );
        return
            _swap(
                msg.sender,
                token,
                amount,
                targetNetwork,
                targetToken,
                targetAddress
            );
    }

    /**
     @dev publically swap 
     @param token the tokens want to swap
     @param amount the amount to be swapped
     @param targetNetwork target network the to network
     @param targetToken the end token address
     @notice only callable by router
     */
    function nonEvmSwapToAddress(
        address token,
        uint256 amount,
        string memory targetNetwork,
        string memory targetToken,
        string memory targetAddress
    ) external onlyRouter returns (uint256) {
        return
            _nonEvmSwap(
                msg.sender,
                token,
                amount,
                targetNetwork,
                targetToken,
                targetAddress
            );
    }

    /**
     @dev callable by only router
     @param token the tokens want to withdraw
     @param payee address of beneficiary
     @param amount the amount to be withdrawn
     @param salt a random bytes32
     @param signature multisig formated signature
     @notice secure with signature verification
     */
    function withdrawSigned(
        address token,
        address payee,
        uint256 amount,
        bytes32 salt,
        bytes memory signature
    ) external onlyRouter returns (uint256) {
        require(token != address(0), "BP: bad token");
        require(payee != address(0), "BP: bad payee");
        require(salt != 0, "BP: bad salt");
        require(amount != 0, "BP: bad amount");
        bytes32 message = withdrawSignedMessage(token, payee, amount, salt);
        address _signer = signerUnique(message, signature);
        console.log(_signer);
        require(signers[_signer], "BridgePool: Invalid signer");

        uint256 fee = 0;
        address _feeDistributor = feeDistributor;
        if (_feeDistributor != address(0)) {
            fee = (amount * fees[token]) / 10000;
            amount = amount - fee;
            if (fee != 0) {
                IERC20Upgradeable(token).safeTransfer(_feeDistributor, fee);
                IGeneralTaxDistributor(_feeDistributor).distributeTax(token);
            }
        }
        IERC20Upgradeable(token).safeTransfer(payee, amount);
        emit TransferBySignature(_signer, payee, token, amount, fee);
        return amount;
    }

    /**
     @dev add liquidity in the contract
     @param token the token we want to add the liquidity
     @param amount of liquidity
     @notice this should be our foundry token
    */
    function addLiquidity(address token, uint256 amount) external {
        require(amount != 0, "Amount must be positive");
        require(token != address(0), "Bad token");
        require(
            isFoundryAsset[token] == true,
            "Only foundry assets can be added"
        );
        amount = SafeAmount.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );
        liquidities[token][msg.sender] =
            liquidities[token][msg.sender] +
            amount;
        emit BridgeLiquidityAdded(msg.sender, token, amount);
    }

    /**
     @dev remove liquidity in the contract
     @param token the token we want to remove the liquidity
     @param amount of liquidity to be removed
     @notice this should be our foundry token
    */
    function removeLiquidityIfPossible(address token, uint256 amount)
        external
        returns (uint256)
    {
        require(amount != 0, "Amount must be positive");
        require(token != address(0), "Bad token");
        require(
            isFoundryAsset[token] == true,
            "Only foundry assets can be removed"
        );
        uint256 liq = liquidities[token][msg.sender];
        require(liq >= amount, "Not enough liquidity");
        uint256 balance = IERC20Upgradeable(token).balanceOf(address(this));
        uint256 actualLiq = balance > amount ? amount : balance;
        liquidities[token][msg.sender] =
            liquidities[token][msg.sender] -
            actualLiq;
        if (actualLiq != 0) {
            IERC20Upgradeable(token).safeTransfer(msg.sender, actualLiq);
            emit BridgeLiquidityRemoved(msg.sender, token, amount);
        }
        return actualLiq;
    }

    /**
     @dev callable by only router
     @param token the tokens want to withdraw
     @param payee address of beneficiary
     @param amount the amount to be withdrawn
     @param salt a random bytes32
     @param signature multisig formated signature
     @notice used to verify signature
     */
    function withdrawSignedVerify(
        address token,
        address payee,
        uint256 amount,
        bytes32 salt,
        bytes calldata signature
    ) external view returns (bytes32, address) {
        bytes32 message = withdrawSignedMessage(token, payee, amount, salt);
        (bytes32 digest, address _signer) = signer(message, signature);
        return (digest, _signer);
    }

    /**
     @dev get liquidity in the contract
     @param token the token we want to get the liquidity
     @param liquidityAdder address who add the liquidity
     @notice this should be our foundry token
    */
    function liquidity(address token, address liquidityAdder)
        external
        view
        returns (uint256)
    {
        return liquidities[token][liquidityAdder];
    }

    /**
     @dev publically swap
     @param token the tokens want to swap
     @param amount the amount to be swapped
     @param targetNetwork target network the to network
     @param targetToken the end token address
     @notice only internally callable
     */
    function _swap(
        address from,
        address token,
        uint256 amount,
        uint256 targetNetwork,
        address targetToken,
        address targetAddress
    ) internal returns (uint256) {
        require(from != address(0), "BP: bad from");
        require(token != address(0), "BP: bad token");
        require(targetNetwork != 0, "BP: targetNetwork is requried");
        require(targetToken != address(0), "BP: bad target token");
        require(amount != 0, "BP: bad amount");
        require(
            allowedTargets[token][targetNetwork] == targetToken,
            "BP: target not allowed"
        );
        amount = SafeAmount.safeTransferFrom(
            token,
            from,
            address(this),
            amount
        );
        emit BridgeSwap(
            from,
            token,
            targetNetwork,
            targetToken,
            targetAddress,
            amount
        );
        return amount;
    }

    /**
     @dev publically swap
     @param token the tokens want to swap
     @param amount the amount to be swapped
     @param targetNetwork target network the to network
     @param targetToken the end token address
     @notice only internally callable
     */
    function _nonEvmSwap(
        address from,
        address token,
        uint256 amount,
        string memory targetNetwork,
        string memory targetToken,
        string memory targetAddress
    ) internal returns (uint256) {
        require(from != address(0), "BP: bad from");
        require(token != address(0), "BP: bad token");
        require(amount != 0, "BP: bad amount");
        require(
            keccak256(
                abi.encodePacked(nonEvmAllowedTargets[token][targetNetwork])
            ) == keccak256(abi.encodePacked(targetToken)),
            "BP: target not allowed"
        );
        amount = SafeAmount.safeTransferFrom(
            token,
            from,
            address(this),
            amount
        );
        emit nonEvmBridgeSwap(
            from,
            token,
            targetNetwork,
            targetToken,
            targetAddress,
            amount
        );
        return amount;
    }

    /**
     @dev callable by only router
     @param token the tokens want to withdraw
     @param payee address of beneficiary
     @param amount the amount to be withdrawn
     @param salt a random bytes32
     @notice create message hash only internally callable
     */
    function withdrawSignedMessage(
        address token,
        address payee,
        uint256 amount,
        bytes32 salt
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(WITHDRAW_SIGNED_METHOD, token, payee, amount, salt)
            );
    }
}
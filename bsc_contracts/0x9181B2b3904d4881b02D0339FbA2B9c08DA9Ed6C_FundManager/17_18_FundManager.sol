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
    string constant NAME = "FERRUM_TOKEN_BRIDGE_POOL";
    string constant VERSION = "000.004";
    bytes32 constant WITHDRAW_SIGNED_METHOD =
        keccak256(
            "WithdrawSigned(address token,address payee,uint256 amount,bytes32 salt)"
        );

    event TransferBySignature(
        address signer,
        address receiver,
        address token,
        uint256 amount
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

    mapping(address => bool) public signers;
    mapping(address => mapping(address => uint256)) private liquidities;
    mapping(address => uint256) public fees;
    mapping(address => mapping(uint256 => address)) public allowedTargets;
    mapping(address => mapping(string => string)) public nonEvmAllowedTargets;
    address public feeDistributor;
    mapping(address => bool) public isFoundryAsset;

    modifier onlyRouter() {
        require(msg.sender == router, "BP: Only router method");
        _;
    }

    //initialize function is constructor for upgradeable smart contract
    function initialize() public initializer {
        __EIP712_init(NAME, VERSION);
        __Ownable_init();
    }

    /**
     *************** Owner only operations ***************
     */

    /*
     @notice sets the router
     */
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "BP: router requried");
        router = _router;
    }

    function addSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Bad signer");
        signers[_signer] = true;
    }

    function removeSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Bad signer");
        delete signers[_signer];
    }

    function setFeeDistributor(address _feeDistributor) external onlyOwner {
        require(_feeDistributor != address(0), "Bad FeeDistributor");
        feeDistributor = _feeDistributor;
    }

    /**
     *************** Admin operations ***************
     */

    function setFee(address token, uint256 fee10000) external onlyAdmin {
        require(token != address(0), "Bad token");
        require(fee10000 <= MAX_FEE, "Fee too large");
        fees[token] = fee10000;
    }

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

    function nonEvmAllowTarget(
        address token,
        string memory chainId,
        string memory targetToken
    ) external onlyAdmin {
        require(token != address(0), "Bad token");
        nonEvmAllowedTargets[token][chainId] = targetToken;
    }

    function disallowTarget(address token, uint256 chainId) external onlyAdmin {
        require(token != address(0), "Bad token");
        require(chainId != 0, "Bad chainId");
        delete allowedTargets[token][chainId];
    }
    
    function nonEvmDisallowTarget(address token, string memory chainId) external onlyAdmin {
        require(token != address(0), "Bad token");
        delete nonEvmAllowedTargets[token][chainId];
    }

    function addFoundryAsset(address token) external onlyAdmin {
        require(token != address(0), "Bad token");
        isFoundryAsset[token] = true;
    }

    function removeFoundryAsset(address token) external onlyAdmin {
        require(token != address(0), "Bad token");
        isFoundryAsset[token] = false;
    }

    /**
     *************** Public operations ***************
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
            
            keccak256(abi.encodePacked(nonEvmAllowedTargets[token][targetNetwork])) == keccak256(abi.encodePacked(targetToken)),
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

        // uint256 fee = 0;
        // address _feeDistributor = feeDistributor;
        // if (_feeDistributor != address(0)) {
        //     fee = (amount * fees[token]) / 10000;
        //     amount = amount - fee;
        //     if (fee != 0) {
        //         IERC20Upgradeable(token).safeTransfer(_feeDistributor, fee);
        //         IGeneralTaxDistributor(_feeDistributor).distributeTax(token);
        //     }
        // }
        IERC20Upgradeable(token).safeTransfer(payee, amount);
        emit TransferBySignature(_signer, payee, token, amount);
        return amount;
    }

    function withdraw(
        address token,
        address payee,
        uint256 amount
    ) external onlyRouter returns (uint256) {
        require(token != address(0), "BP: bad token");
        require(payee != address(0), "BP: bad payee");
        require(amount != 0, "BP: bad amount");
        require(isFoundryAsset[token] == true, "token is not foundry asset");
        uint256 contractBalance = IERC20Upgradeable(token).balanceOf(
            address(this)
        );
        require(
            contractBalance >= amount,
            "insufficient foundry asset liquidity amount"
        );
        IERC20Upgradeable(token).safeTransfer(payee, amount);
        return amount;
    }

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

    function liquidity(address token, address liquidityAdder)
        public
        view
        returns (uint256)
    {
        return liquidities[token][liquidityAdder];
    }
}
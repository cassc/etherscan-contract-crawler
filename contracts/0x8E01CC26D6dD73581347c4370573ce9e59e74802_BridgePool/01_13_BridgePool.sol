// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../common/signature/SigCheckable.sol";
import "../common/SafeAmount.sol";
import "../common/WithAdmin.sol";
import "../taxing/IGeneralTaxDistributor.sol";

contract BridgePool is SigCheckable, WithAdmin {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event TransferBySignature(address signer,
        address receiver,
        address token,
        uint256 amount,
        uint256 fee);
    event BridgeLiquidityAdded(address actor, address token, uint256 amount);
    event BridgeLiquidityRemoved(address actor, address token, uint256 amount);
    event BridgeSwap(address from,
        address indexed token,
        uint256 targetNetwork,
        address targetToken,
        address targetAddrdess,
        uint256 amount);

    string constant NAME = "FERRUM_TOKEN_BRIDGE_POOL";
    string constant VERSION = "000.003";
    bytes32 constant WITHDRAW_SIGNED_METHOD =
        keccak256("WithdrawSigned(address token,address payee,uint256 amount,bytes32 salt)");
    mapping(address => bool) public signers;
    mapping(address=>mapping(address=>uint256)) private liquidities;
    mapping(address=>uint256) public fees;
	mapping(address=>mapping(uint256=>address)) public allowedTargets;
    address public feeDistributor;

    constructor () EIP712(NAME, VERSION) { }

	/**
	 *************** Owner only operations ***************
	 */

    function addSigner(address _signer) external onlyOwner() {
        require(_signer != address(0), "Bad signer");
        signers[_signer] = true;
    }

    function removeSigner(address _signer) external onlyOwner() {
        require(_signer != address(0), "Bad signer");
        delete signers[_signer];
    }

    function setFeeDistributor(address _feeDistributor) external onlyOwner() {
        feeDistributor = _feeDistributor;
    }

	/**
	 *************** Admin operations ***************
	 */

    function setFee(address token, uint256 fee10000) external onlyAdmin() {
        require(token != address(0), "Bad token");
        fees[token] = fee10000;
    }

	function allowTarget(address token, uint256 chainId, address targetToken) external onlyAdmin() {
		allowedTargets[token][chainId] = targetToken;
	}

	function disallowTarget(address token, uint256 chainId) external onlyAdmin() {
		delete allowedTargets[token][chainId];
	}

	/**
	 *************** Public operations ***************
	 */

    function swap(address token, uint256 amount, uint256 targetNetwork, address targetToken)
    external returns(uint256) {
        return _swap(msg.sender, token, amount, targetNetwork, targetToken, msg.sender);
    }

    function swapToAddress(address token,
        uint256 amount,
        uint256 targetNetwork,
        address targetToken,
        address targetAddress)
    external returns(uint256) {
        require(targetAddress != address(0), "BridgePool: targetAddress is required");
        return _swap(msg.sender, token, amount, targetNetwork, targetToken, targetAddress);
    }

    function _swap(address from, address token, uint256 amount, uint256 targetNetwork,
        address targetToken, address targetAddress) internal returns(uint256) {
		require(targetNetwork != 0, "BP: targetNetwork is requried");
		require(allowedTargets[token][targetNetwork] == targetToken, "BP: target not allowed");
        amount = SafeAmount.safeTransferFrom(token, from, address(this), amount);
        emit BridgeSwap(from, token, targetNetwork, targetToken, targetAddress, amount);
        return amount;
    }

    function withdrawSigned(
            address token,
            address payee,
            uint256 amount,
            bytes32 salt,
            bytes memory signature)
    external returns(uint256) {
        bytes32 message = withdrawSignedMessage(token, payee, amount, salt);
        address _signer = signerUnique(message, signature);
        require(signers[_signer], "BridgePool: Invalid signer");

        uint256 fee = 0;
        address _feeDistributor = feeDistributor;
        if (_feeDistributor != address(0)) {
            fee = amount.mul(fees[token]).div(10000);
            amount = amount.sub(fee);
            if (fee != 0) {
                IERC20(token).safeTransfer(_feeDistributor, fee);
                IGeneralTaxDistributor(_feeDistributor).distributeTax(token, msg.sender);
            }
        }
        IERC20(token).safeTransfer(payee, amount);
        emit TransferBySignature(_signer, payee, token, amount, fee);
        return amount;
    }

    function withdrawSignedVerify(
            address token,
            address payee,
            uint256 amount,
            bytes32 salt,
            bytes calldata signature)
    external view returns (bytes32, address) {
        bytes32 message = withdrawSignedMessage(token, payee, amount, salt);
        (bytes32 digest, address _signer) = signer(message, signature);
        return (digest, _signer);
    }

    function withdrawSignedMessage(
            address token,
            address payee,
            uint256 amount,
            bytes32 salt)
    internal pure returns (bytes32) {
        return keccak256(abi.encode(
          WITHDRAW_SIGNED_METHOD,
          token,
          payee,
          amount,
          salt
        ));
    }

    function addLiquidity(address token, uint256 amount) external {
        require(amount != 0, "Amount must be positive");
        require(token != address(0), "Bad token");
        amount = SafeAmount.safeTransferFrom(token, msg.sender, address(this), amount);
        liquidities[token][msg.sender] = liquidities[token][msg.sender].add(amount);
        emit BridgeLiquidityAdded(msg.sender, token, amount);
    }

    function removeLiquidityIfPossible(address token, uint256 amount) external returns (uint256) {
        require(amount != 0, "Amount must be positive");
        require(token != address(0), "Bad token");
        uint256 liq = liquidities[token][msg.sender];
        require(liq >= amount, "Not enough liquidity");
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 actualLiq = balance > amount ? amount : balance;
        liquidities[token][msg.sender] = liquidities[token][msg.sender].sub(actualLiq);
        if (actualLiq != 0) {
            IERC20(token).safeTransfer(msg.sender, actualLiq);
            emit BridgeLiquidityRemoved(msg.sender, token, amount);
        }
        return actualLiq;
    }

    function liquidity(address token, address liquidityAdder) public view returns (uint256) {
        return liquidities[token][liquidityAdder];
    }
}
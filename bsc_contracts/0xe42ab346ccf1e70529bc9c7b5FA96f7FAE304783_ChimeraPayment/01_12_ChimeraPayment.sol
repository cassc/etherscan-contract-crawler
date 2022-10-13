// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

// solhint-disable not-rely-on-time, max-states-count

// inheritance
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interface/IChimeraPayment.sol";

// libs
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

// interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract ChimeraPayment is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IChimeraPayment {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public override operator;

    // user => erc20 token => balance
    mapping(address => mapping(address => uint256)) public override balance;
    mapping(uint256 => bool) public override usedNonces;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // constructor
    function initialize(address operator_) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        operator = operator_;
    }

    function setOperator(address newOperator_) external onlyOwner {
        emit SetOperator({
            sender_: msg.sender,
            oldOperator_: operator,
            newOperator_: newOperator_,
            timestamp_: block.timestamp
        });

        operator = newOperator_;
    }

    function openPlan(
        address token_,
        address[] memory target_,
        uint256[] memory amount_,
        string memory userName_,
        uint256 plan_,
        uint256 nonce_,
        bytes memory operatorSign
    ) external override nonReentrant {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, token_, target_, amount_, userName_, plan_, nonce_));

        bytes32 hash = ECDSAUpgradeable.toEthSignedMessageHash(message);

        address signer = ECDSAUpgradeable.recover(hash, operatorSign);
        require(signer == operator, "ChimeraPayment: invalid signature");

        require(target_.length > 0 && target_.length == amount_.length, "ChimeraPayment: wrong args length");
        require(!usedNonces[nonce_], "ChimeraPayment: nonce already used");

        uint256 totalAmount;
        for (uint256 i = 0; i < target_.length; i++) {
            totalAmount = totalAmount.add(amount_[i]);
            balance[target_[i]][token_] = balance[target_[i]][token_].add(amount_[i]);
        }

        IERC20Upgradeable(token_).safeTransferFrom(msg.sender, address(this), totalAmount);

        usedNonces[nonce_] = true;

        emit OpenPlan({
            user_: msg.sender,
            token_: token_,
            target_: target_,
            amount_: amount_,
            userName_: userName_,
            plan_: plan_,
            nonce_: nonce_,
            operatorSign_: operatorSign,
            timestamp_: block.timestamp
        });
    }

    function claimReward(address token_) external override nonReentrant returns (uint256 claimResult_) {
        uint256 currentBalance = balance[msg.sender][token_];
        balance[msg.sender][token_] = 0;

        require(currentBalance > 0, "ChimeraPayment: zero token balance");

        IERC20Upgradeable(token_).safeTransfer(msg.sender, currentBalance);

        emit ClaimReward({
            user_: msg.sender,
            token_: token_,
            claimResult_: currentBalance,
            timestamp_: block.timestamp
        });

        return currentBalance;
    }

    function prepareMsg(
        address user,
        address token_,
        address[] memory target_,
        uint256[] memory amount_,
        string memory userName_,
        uint256 plan_,
        uint256 nonce_
    ) external pure returns (bytes32, bytes32) {
        bytes32 message = keccak256(abi.encodePacked(user, token_, target_, amount_, userName_, plan_, nonce_));

        bytes32 hash = ECDSAUpgradeable.toEthSignedMessageHash(message);

        return (message, hash);
    }
}
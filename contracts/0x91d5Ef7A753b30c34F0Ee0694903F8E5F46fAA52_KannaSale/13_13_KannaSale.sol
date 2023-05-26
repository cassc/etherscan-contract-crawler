// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 *
 *   __                                               .__
 *  |  | ___\|/_    ____   ____ _\|/_    _______\|/_  |  |   ____
 *  |  |/ /\__  \  /    \ /    \\__  \  /  ___/\__  \ |  | _/ __ \
 *  |    <  / __ \|   |  \   |  \/ __ \_\___ \  / __ \|  |_\  ___/
 *  |__|_ \(____  /___|  /___|  (____  /____  >(____  /____/\___  >
 *       \/     \/     \/     \/     \/     \/      \/          \/
 *
 *  @title KNN Sale for KNN Token
 *  @author KANNA Team
 *  @custom:github  https://github.com/kanna-coin
 *  @custom:site https://kannacoin.io
 *  @custom:discord https://discord.gg/V5KDU8DKCh
 */
contract KannaSale is Ownable, AccessControl {
    IERC20 public immutable knnToken;
    AggregatorV3Interface public immutable priceAggregator;

    bytes32 public constant CLAIM_MANAGER_ROLE = keccak256("CLAIM_MANAGER_ROLE");

    bytes32 private constant _CLAIM_TYPEHASH =
        keccak256("Claim(address recipient,uint256 amountInKNN,uint256 ref,uint256 nonce)");

    uint256 public constant USD_AGGREGATOR_DECIMALS = 1e8;
    uint256 public constant KNN_DECIMALS = 1e18;
    uint256 public immutable knnPriceInUSD;
    uint256 public knnLocked;

    mapping(address => uint256) private nonces;
    mapping(uint256 => bool) private claims;

    event Purchase(
        address indexed holder,
        uint256 amountInWEI,
        uint256 knnPriceInUSD,
        uint256 ethPriceInUSD,
        uint256 indexed amountInKNN
    );

    event Claim(address indexed holder, uint256 indexed ref, uint256 amountInKNN);
    event Lock(uint256 indexed ref, uint256 amountInKNN);
    event Unlock(uint256 indexed ref, uint256 amountInKNN);

    event Withdraw(address indexed recipient, uint256 amount);

    constructor(address _knnToken, address _priceAggregator, uint256 targetQuotation) {
        require(address(_knnToken) != address(0), "Invalid token address");
        require(address(_priceAggregator) != address(0), "Invalid price aggregator address");
        require(targetQuotation > 0, "Invalid quotation");

        knnToken = IERC20(_knnToken);
        priceAggregator = AggregatorV3Interface(_priceAggregator);
        knnPriceInUSD = targetQuotation;
    }

    modifier positiveAmount(uint256 amount) {
        require(amount > 0, "Invalid amount");
        _;
    }

    /**
     * @dev Grants `CLAIM_MANAGER_ROLE` to a `claimManager` account.
     *
     * If `claimManager` account had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function addClaimManager(address claimManager) external onlyOwner {
        _grantRole(CLAIM_MANAGER_ROLE, claimManager);
    }

    /**
     * @dev Removes `CLAIM_MANAGER_ROLE` from a `claimManager` account.
     *
     * If `claimManager` had been granted `CLAIM_MANAGER_ROLE`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function removeClaimManager(address claimManager) external onlyOwner {
        _revokeRole(CLAIM_MANAGER_ROLE, claimManager);
    }

    /**
     * @dev Withdraw ETH from sold tokens
     */
    function withdraw(address payable recipient) external onlyOwner {
        uint256 amount = address(this).balance;
        recipient.transfer(amount);

        emit Withdraw(recipient, amount);
    }

    /**
     * @dev Retrieves available supply
     */
    function availableSupply() public view returns (uint256) {
        return knnToken.balanceOf(address(this)) - knnLocked;
    }

    /**
     * @dev Decrease Total Supply
     *
     */
    function lockSupply(
        uint256 amountInKNN,
        uint256 ref
    ) external onlyRole(CLAIM_MANAGER_ROLE) positiveAmount(amountInKNN) {
        require(availableSupply() >= amountInKNN, "Insufficient supply!");

        knnLocked += amountInKNN;

        emit Lock(ref, amountInKNN);
    }

    /**
     * @dev Decrease Supply Locked
     *
     */
    function unlockSupply(
        uint256 amountInKNN,
        uint256 ref
    ) external onlyRole(CLAIM_MANAGER_ROLE) positiveAmount(amountInKNN) {
        require(knnLocked >= amountInKNN, "Insufficient locked supply!");

        knnLocked -= amountInKNN;

        emit Unlock(ref, amountInKNN);
    }

    /**
     * @dev release claimed tokens to recipient
     */
    function claim(address recipient, uint256 amountInKNN, uint256 ref) external onlyRole(CLAIM_MANAGER_ROLE) {
        require(availableSupply() >= amountInKNN, "Insufficient available supply");

        _claim(recipient, amountInKNN, ref);
    }

    /**
     * @dev claim message hash
     */
    function claimHash(address recipient, uint256 amountInKNN, uint256 ref) public view returns (bytes32, uint256) {
        require(address(recipient) != address(0), "Invalid address");
        require(amountInKNN > 0, "Invalid amount");
        require(claims[ref] == false, "Already claimed");

        uint256 nonce = nonces[recipient];

        bytes32 hash = keccak256(abi.encode(_CLAIM_TYPEHASH, recipient, amountInKNN, ref, nonce));

        return (hash, nonce);
    }

    /**
     * @dev release claimed locked tokens to recipient
     */
    function claimLocked(
        address recipient,
        uint256 amountInKNN,
        uint256 ref,
        bytes memory signature,
        uint256 nonce
    ) external {
        require(knnLocked >= amountInKNN, "Insufficient locked amount");

        bytes32 signedMessage = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encode(_CLAIM_TYPEHASH, recipient, amountInKNN, ref, nonce))
        );

        address signer = ECDSA.recover(signedMessage, signature);

        _checkRole(CLAIM_MANAGER_ROLE, signer);

        _claim(recipient, amountInKNN, ref);

        knnLocked -= amountInKNN;
        nonces[recipient] = nonce + 1;
    }

    /**
     * @dev Return non-sold tokens and ends sale
     *
     */
    function end(address leftoverRecipient) external onlyOwner {
        uint256 leftover = availableSupply();
        if (leftover > 0) knnToken.transfer(leftoverRecipient, leftover);
    }

    /**
     * @dev Converts a given amount {amountInKNN} to WEI
     */
    function convertToWEI(uint256 amountInKNN) public view positiveAmount(amountInKNN) returns (uint256, uint256) {
        (, int256 answer, , , ) = priceAggregator.latestRoundData();

        uint256 ethPriceInUSD = SafeCast.toUint256(answer);
        require(ethPriceInUSD > 0, "Invalid round answer");

        return ((amountInKNN * knnPriceInUSD) / ethPriceInUSD, ethPriceInUSD);
    }

    /**
     * @dev Converts a given amount {amountInWEI} to KNN
     */
    function convertToKNN(uint256 amountInWEI) public view positiveAmount(amountInWEI) returns (uint256, uint256) {
        (, int256 answer, , , ) = priceAggregator.latestRoundData();

        uint256 ethPriceInUSD = SafeCast.toUint256(answer);
        require(ethPriceInUSD > 0, "Invalid round answer");

        return ((amountInWEI * ethPriceInUSD) / knnPriceInUSD, ethPriceInUSD);
    }

    /**
     * @dev Allows users to buy tokens for ETH
     * See {tokenQuotation} for unitPrice.
     *
     * Emits a {Purchase} event.
     */
    function buyTokens() external payable {
        require(msg.value > USD_AGGREGATOR_DECIMALS, "Invalid amount");

        (uint256 finalAmount, uint256 ethPriceInUSD) = convertToKNN(msg.value);

        require(availableSupply() >= finalAmount, "Insufficient supply!");

        knnToken.transfer(msg.sender, finalAmount);

        emit Purchase(msg.sender, msg.value, knnPriceInUSD, ethPriceInUSD, finalAmount);
    }

    function _claim(address recipient, uint256 amountInKNN, uint256 ref) internal virtual positiveAmount(amountInKNN) {
        require(address(recipient) != address(0), "Invalid address");
        require(claims[ref] == false, "Already claimed");

        knnToken.transfer(recipient, amountInKNN);

        claims[ref] = true;

        emit Claim(recipient, ref, amountInKNN);
    }
}
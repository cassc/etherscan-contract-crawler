// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IConverterLogic.sol";

contract EnergyBurning is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    address private _signer;
    IConverterLogic public energyConverter;
    IERC20 public lpToken;

    uint256 public maxClaimsPerTx;
    uint256 public maxLPAmountPerVoid;
    uint256 public energyAmountPerClaim;
    uint256 public lpTokenAmountPerClaim;

    mapping(address => uint256) public nonces;
    // Voidpool id => total claimed LP amount
    mapping(uint256 => uint256) public claimedLP;

    event EnergyBurned(address indexed addr, uint256 claimAmount, uint256 energyAmountBurned);
    event LpTokenWithdrawn(address indexed addr, uint256 amount);

    constructor(
        address multisig,
        address signer,
        address _energyConverter,
        address _lpToken,
        uint256 _maxClaimPerTx,
        uint256 _maxLPAmountPerVoid,
        uint256 _energyAmountPerClaim,
        uint256 _lpTokenAmountPerClaim
    ) {
        _signer = signer;
        energyConverter = IConverterLogic(_energyConverter);
        lpToken = IERC20(_lpToken);
        maxClaimsPerTx = _maxClaimPerTx;
        maxLPAmountPerVoid = _maxLPAmountPerVoid;
        energyAmountPerClaim = _energyAmountPerClaim;
        lpTokenAmountPerClaim = _lpTokenAmountPerClaim;
        _transferOwnership(multisig);
    }

    /**
     * @dev Encode arguments to generate a hash, which will be used for validating signatures
     * @param walletAddress The user's wallet address
     * @param nonce The nonce id of the wallet address
     * @param voidId The void id to fill in
     * @param claimAmount The amount of claims
     * @return Encoded hash
     */
    function _getHash(
        address walletAddress,
        uint256 nonce,
        uint256 voidId,
        uint256 claimAmount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(walletAddress, nonce, voidId, claimAmount));
    }

    /**
     * @dev To verify the `token` is signed by the _signer
     * @param _hash The encoded hash used for signature
     * @param _signature The signature passed from the caller
     * @return Verification result
     */
    function _verify(bytes32 _hash, bytes calldata _signature) internal view returns (bool) {
        return (_recover(_hash, _signature) == _signer);
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address should be equal to the _signer wallet address
     * @param _hash The encoded hash used for signature
     * @param _signature The signature passed from the caller
     * @return The recovered address
     */
    function _recover(bytes32 _hash, bytes calldata _signature) internal pure returns (address) {
        return _hash.toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @dev To validate the `signature` is signed by the _signer
     * @param walletAddress The wallet address that is validating signature
     * @param nonce The nonce id of the wallet address
     * @param voidId The void id to fill in
     * @param claimAmount The amount of claims
     * @param _signature The signature passed from the caller
     * @return Validation result
     */
    function validateSignature(
        address walletAddress,
        uint256 nonce,
        uint256 voidId,
        uint256 claimAmount,
        bytes calldata _signature
    ) public view returns (bool) {
        return _verify(_getHash(walletAddress, nonce, voidId, claimAmount), _signature);
    }

    /**
     * @dev Burn asto energy to fill voids and claim LP tokens as a reward
     * @dev Only use this funcition **BEFORE** Continuous Genome Mining release
     * @dev only callable when not paused
     * @param voidId The void id to fill in
     * @param amount The amount of claims
     * @param _signature The signature passed from the caller
     */
    function claim(
        uint256 voidId,
        uint256 amount,
        bytes calldata _signature
    ) external whenNotPaused nonReentrant {
        require(validateSignature(msg.sender, nonces[msg.sender], voidId, amount, _signature), "Invalid signature");
        require(amount < maxClaimsPerTx + 1, "Exceeded max claim limit");

        uint256 periodId = energyConverter.getCurrentPeriodId();
        uint256 energyToBurn = amount * energyAmountPerClaim;
        uint256 rewardToSend = amount * lpTokenAmountPerClaim;
        require(claimedLP[voidId] + rewardToSend <= maxLPAmountPerVoid, "Exceeded max LP limit");

        nonces[msg.sender]++;
        claimedLP[voidId] += rewardToSend;

        energyConverter.useEnergy(msg.sender, periodId - 1, energyToBurn);
        lpToken.safeTransfer(msg.sender, rewardToSend);

        emit EnergyBurned(msg.sender, amount, energyToBurn);
    }

    /**
     * @dev Burn asto energy to fill voids and claim LP tokens as a reward
     * @dev Only use this funcition **AFTER** Continuous Genome Mining release
     * @dev only callable when not paused
     * @param voidId The void id to fill in
     * @param amount The amount of claims
     * @param _signature The signature passed from the caller
     */
    function claimLP(
        uint256 voidId,
        uint256 amount,
        bytes calldata _signature
    ) external whenNotPaused nonReentrant {
        require(validateSignature(msg.sender, nonces[msg.sender], voidId, amount, _signature), "Invalid signature");
        require(amount < maxClaimsPerTx + 1, "Exceeded max claim limit");

        uint256 energyToBurn = amount * energyAmountPerClaim;
        uint256 rewardToSend = amount * lpTokenAmountPerClaim;
        require(claimedLP[voidId] + rewardToSend <= maxLPAmountPerVoid, "Exceeded max LP limit");

        nonces[msg.sender]++;
        claimedLP[voidId] += rewardToSend;

        energyConverter.useEnergy(msg.sender, energyToBurn);
        lpToken.safeTransfer(msg.sender, rewardToSend);

        emit EnergyBurned(msg.sender, amount, energyToBurn);
    }

    /**
     * @dev Get the maximum claim amount per void
     * @return The maximum claim amount per void
     */
    function getMaxClaimPerVoid() external view returns (uint256) {
        return maxLPAmountPerVoid / lpTokenAmountPerClaim;
    }

    /**
     * @dev Claim counter for void `voidId`
     * @param voidId The void id to the counter
     * @return Current claimed amount in void
     */
    function getClaimedCount(uint256 voidId) external view returns (uint256) {
        return claimedLP[voidId] / lpTokenAmountPerClaim;
    }

    /**
     * @dev Check if the void `voidId` is filled. No more claims are allowed if it returns true
     * @param voidId The void id to check
     * @return Filled status
     */
    function isFilled(uint256 voidId) external view returns (bool) {
        return claimedLP[voidId] >= maxLPAmountPerVoid;
    }

    /**
     * @dev Withdraw LP token left in the contract to a specified address
     * @param _recipient Recipient of the transfer
     * @param _amount Token amount to withdraw
     */
    function withdraw(address _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Wrong address");
        lpToken.safeTransfer(_recipient, _amount);

        emit LpTokenWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Setter for energyConverter
     */
    function setEnergyConverter(address _addr) external onlyOwner {
        energyConverter = IConverterLogic(_addr);
    }

    /**
     * @dev Setter for lpToken
     */
    function setLpToken(address _addr) external onlyOwner {
        lpToken = IERC20(_addr);
    }

    /**
     * @dev Setter for signer
     */
    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    /**
     * @dev Set the maximum number of voids to fill in at once
     * @param _amount Maximum number of voids to fill in at once
     */
    function setMaxClaimPerTx(uint256 _amount) external onlyOwner whenPaused {
        maxClaimsPerTx = _amount;
    }

    /**
     * @dev Set the maximum claimable LP token amount per void
     * @param _amount Maximum number of LP tokens to claim in one void
     */
    function setMaxLPAmountPerVoid(uint256 _amount) external onlyOwner whenPaused {
        maxLPAmountPerVoid = _amount;
    }

    /**
     * @dev Set the amount of asto energy to burn for filling in a void
     * @param _amount Amount of asto energy to burn for filling in a void
     */
    function setAstoEnergyAmountPerClaim(uint256 _amount) external onlyOwner whenPaused {
        energyAmountPerClaim = _amount;
    }

    /**
     * @dev Set the amount of LP token that user gets rewarded at the cost of filling in a void
     * @param _amount Amount of LP token reward for filling in a void
     */
    function setLpTokenAmountPerClaim(uint256 _amount) external onlyOwner whenPaused {
        lpTokenAmountPerClaim = _amount;
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// The Staking Contract
interface IStakingContract {
    function calculateTokensEarned(address addr) external view returns (uint256);
}

/**
 * DEAL is a rewards token for the Planetary Property Association.
 * It is NOT an investment and NOT meant to be traded for financial gain.
 * DEAL tokens can only be minted by approved minting contracts.
 */
contract Deal is ERC20, Ownable {
    using ECDSA for bytes32;

    string public constant NAME = "PPA Deal Token";
    string public constant SYMBOL = "DEAL";
    IStakingContract[] public stakingContracts;

    // All stats about a specific user.
    struct UserStats {
        uint256 tokensWithdrawn;
        uint256 tokensDeposited;
    }

    event Withdrawal(
        address account,
        uint256 amount
    );

    event Deposit(
        address account,
        uint256 amount
    );

    mapping(address => UserStats) public userStatsByAddress;

    mapping(uint256 => bool) public nonceUsedMap;

    address public signerAddress;

    bool public supplyLocked = false;

    constructor() public ERC20(NAME, SYMBOL) {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /**
     * Get total tokens earned for the given address across all staking contracts.
     */
    function getTotalTokensEarned(address addr) public view returns (uint256) {
        uint256 num = 0;
        for (uint256 i = 0; i < stakingContracts.length; i++) {
            num += stakingContracts[i].calculateTokensEarned(addr);
        }
        return num;
    }

    /**
     * Withdraw the tokens the user has earned. This requires a signature from signingAddress. The number of
     * withdrawable tokens is the sum of all tokens earned from staking and all tokens deposited, minus any
     * tokens spent in the offchain marketplace, minus any tokens already withdrawn.
     *
     * The numTokensSpentInMarketplace is reported by signingAddress and verified by the signature. The signer
     * uses expiryBlockHeight to ensure that the user cannot hoard signatures and use them later on after spending
     * even more in the marketplace. The offchain marketplace will likely be frozen for the user until expiryBlockHeight.
     */
    function withdrawTokens(
        uint256 numTokensToWithdraw, // The number of the tokens the user wants to withdraw.
        uint256 numTokensSpentInMarketplace, // The total number of tokens the user has spent so far in the offchain marketplace.
        uint256 expiryBlockHeight, // The provided signature is only valid until this block height.
        uint256 nonce, // Unique nonce for the signature.
        bytes memory signature // Signed by signerAddress.
    ) public {
        require(!supplyLocked, "Supply is locked");
        require(!nonceUsedMap[nonce], "Used nonce");
        nonceUsedMap[nonce] = true;
        require(block.number <= expiryBlockHeight, "Signature has expired");
        bytes32 inputHash = keccak256(
            abi.encodePacked(
                msg.sender,
                numTokensToWithdraw,
                numTokensSpentInMarketplace,
                expiryBlockHeight,
                nonce
            )
        );
        bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
        address recoveredAddress = ethSignedMessageHash.recover(signature);
        require(recoveredAddress == signerAddress, "Wrong signature");

        uint256 totalTokensEarned = getTotalTokensEarned(msg.sender);
        UserStats storage userStats = userStatsByAddress[msg.sender];

        require(
            totalTokensEarned +
                userStats.tokensDeposited -
                userStats.tokensWithdrawn -
                numTokensSpentInMarketplace >=
                numTokensToWithdraw,
            "Trying to withdraw more tokens than user has"
        );

        userStats.tokensWithdrawn += numTokensToWithdraw;
        _mint(msg.sender, numTokensToWithdraw);

        emit Withdrawal(msg.sender, numTokensToWithdraw);
    }

    /**
     * Deposit tokens into a users account. Behind the scenes this burns the tokens from the sender and credits
     * the virtual "tokensDeposited" account for the beneficiary.
     */
    function depositTokens(address toAddress, uint256 numTokens) public {
        _burn(msg.sender, numTokens);
        userStatsByAddress[toAddress].tokensDeposited += numTokens;
        emit Deposit(toAddress, numTokens);
    }

    function setSignerAddress(address newAddress) public onlyOwner {
        signerAddress = newAddress;
    }

    function addStakingContract(address newAddress) public onlyOwner {
        stakingContracts.push(IStakingContract(newAddress));
    }

    function replaceStakingContract(uint256 index, address newAddress)
        public
        onlyOwner
    {
        stakingContracts[index] = IStakingContract(newAddress);
    }

    // PERMANENT! There is no way to undo this.
    function lockSupply() public onlyOwner {
        supplyLocked = true;
    }
}
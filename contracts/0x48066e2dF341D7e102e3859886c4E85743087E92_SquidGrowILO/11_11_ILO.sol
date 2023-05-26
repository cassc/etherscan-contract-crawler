// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Custom error thrown when the provided amount is less then zero.
 */
error InvalidAmount();

/**
 * @dev Custom error thrown when the total max contribution is reached.
 */
error MaxContributionReached();

/**
 * @dev Custom error thrown when an individuals max contribution is reached.
 */
error IndividualMaxContributionReached();

/**
 * @dev Custom error thrown when the Public sale is not active.
 */
error PublicSaleNotActive();

/**
 * @dev Custom error thrown when the Whitelist sale is not active.
 */
error WhitelistSaleNotActive();

/**
 * @dev Custom error thrown when the user attempting to mint is not whitelisted
 */
error NotWhitelisted();

/**
 * @dev Custom error thrown when a user attempts to claim a second time.
 */
error AlreadyClaimed();

/**
 * @dev Custom error thrown when a user attempts to claim while the airdrop is not active
 */
error ClaimNotActive();

/**
 * @dev Custom error thrown when a user attempts to claim while not being eligible for the airdrop
 */
error IsNotWhitelisted();

/**
 * @dev Custom error thrown when a input is out of range
 */
error OutOfRange();

/**
 * @dev Custom error thrown when the inputed address is the zero address
 */
error IsZeroAddress();

contract SquidGrowILO is ReentrancyGuard, Ownable, ERC20 {
    using Address for *;
    using SafeERC20 for ERC20;

    /**
     * @dev Enum defining the possible status values for the ILO contract.
     *      - Closed: 0
     *      - Whitelist: 1
     *      - Public: 2
     */
    enum ILOStatus {
        Closed,
        Whitelist,
        Public
    }

    /**
     * @dev The current claim status of the airdrop.
     */
    bool public claimable = false;

    /**
     * @dev The bitmap that tracks claims for the airdrop.
     */
    mapping(uint256 => uint256) private claimedBitMap;

    /**
     * @dev The current status of the ILO contract.
     */
    ILOStatus public status;

    /**
     * @dev The address of the token being used for the ILO.
     */
    address public squidGrowToken;

    /**
     * @dev The maximum contribution amount in ETH that users can contribute to the ILO.
     */
    uint256 public maxContribution = 106e18;

    /**
     * @dev The exchange rate between 1 token and 1 ETH for the ILO.
     */
    uint256 public exchangeRate = 1690140845076; // 0.0059153 ETH per token scaled by 10^7 for precision

    /**
     * @dev The total amount of ETH contributed to the ILO.
     */
    uint256 public totalContributions;

    /**
     * @dev The total number of tokens that have been minted and sent to contributors.
     */
    uint256 public totalContributionsTokens;

    /**
     * @dev The Merkle root used for the ILO's whitelist.
     */
    bytes32 public merkleRoot;

    /**
     * @dev The discount applied to the token price for the ILO, represented in base points (e.g. 500 = 5%).
     */
    uint256 public discount = 500;

    /**
     * @dev Mapping of the amount of contributions made by whitelisted users.
     */
    mapping(address => uint256) public whitelistContributions;

    /**
     * @dev Mapping of the amount of contributions made by public users.
     */
    mapping(address => uint256) public publicContributions;

    /**
     * @dev Emitted when the merkle root for the ILO is set.
     * @param merkleRoot The new merkle root.
     */
    event MerkleRootSet(bytes32 merkleRoot);

    /**
     * @dev Emitted when a contribution is made to the ILO.
     * @param amount The amount of tokens contributed.
     * @param contributor The address of the contributor.
     */
    event Contribution(uint amount, address contributor);

    /**
     * @dev Emitted when the maximum contribution amount is set for the ILO.
     * @param amount The new maximum contribution amount.
     */
    event MaxContributionSet(uint amount);

    /**
     * @dev Emitted when the token price is set for the ILO.
     * @param price The new token price.
     */
    event PriceSet(uint256 price);

    /**
     * @dev Emitted when the status of the ILO is set.
     * @param _saleStatus The new status of the ILO.
     */
    event ILOStatusSet(uint256 _saleStatus);

    /**
     * @dev Emitted when the discount for the ILO is set.
     * @param _discount The new discount for the ILO.
     */
    event SetDiscount(uint256 _discount);

    /**
     * @dev Emitted when the bonus tokens for trading in are set.
     * @param _bonusForTrade The new bonus percentage for trading in your tokens
     */
    event SetBonusForTradeIn(uint256 _bonusForTrade);

    /**
     * @dev Emitted when the owner withdraws the contributions.
     * @param _contributionWithdrawn The amount of contributions withdrawn
     */
    event ContributionsWithdrawn(uint256 _contributionWithdrawn);

    /**
     * @dev Emitted when the owner deposits tokens for the airdrop.
     * @param _amount The amount of tokens deposited
     */
    event TokensDepositedForAirdrop(uint256 _amount);

    /**
     * @dev Emitted when the owner withdraws
     * @param _amount The amount of tokens withdrawn
     */
    event TokensWithdrawn(address _address, uint256 _amount);

    /**
     * @dev Emitted when a user claims their airdrop tokens.
     * @param _address The address of the user
     * @param _amount The amount of tokens withdrawn
     */
    event AirdropClaimed(address _address, uint256 _amount);

    /**
     * @dev Emitted when owner sets _claimable to true
     * @param _claimable The new claimable status
     */
    event SetClaimable(bool _claimable);

    /**
     * @dev Emitted when owner sets _squidGrowAddress
     * @param _squidGrowAddress The new squidgrow address
     */
    event SquidGrowAddressSet(address _squidGrowAddress);

    constructor(
        address _squidGrowToken
    ) ERC20("SquidGrow AirDrop IOU", "SGIOU") {
        if (_squidGrowToken == address(0)) revert IsZeroAddress();
        squidGrowToken = _squidGrowToken;
    }

    /**
     * @dev Sets the discount for the ILO.
     * @param _discount The new discount to be set.
     */
    function setDiscount(uint256 _discount) external onlyOwner {
        if (_discount > 10000) revert OutOfRange();
        discount = _discount;
        emit SetDiscount(discount);
    }

    /**
     * @dev Sets the squidgrow token for the ILO.
     * @param _squidGrowToken The new token address
     */
    function setSquidGrowToken(address _squidGrowToken) external onlyOwner {
        if (_squidGrowToken == address(0)) revert IsZeroAddress();
        squidGrowToken = _squidGrowToken;
        emit SquidGrowAddressSet(squidGrowToken);
    }

    /**
     * @dev Sets the status of the ILO.
     * @param _status The new status to be set.
     */
    function setILOStatus(ILOStatus _status) external onlyOwner {
        status = _status;
        emit ILOStatusSet(uint256(status));
    }

    /**
     * @dev Sets the merkle root for the ILO.
     * @param _merkleRoot The new merkle root to be set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootSet(merkleRoot);
    }

    /**
     * @dev Sets the maximum contribution amount for the ILO.
     * @param _maxContribution The new maximum contribution amount to be set.
     * @dev Reverts if the new maximum contribution is less than or equal to zero.
     */
    function setMaxContribution(uint256 _maxContribution) external onlyOwner {
        if (_maxContribution == 0) revert InvalidAmount();
        maxContribution = _maxContribution;
        emit MaxContributionSet(maxContribution);
    }

    /**
     * @dev Sets the exchange rate for the ILO.
     * @param _exchangeRate The new exchange rate to be set.
     * @dev Reverts if the exchange rate is less than or equal to zero.
     */
    function setExchangeRate(uint256 _exchangeRate) external onlyOwner {
        if (_exchangeRate == 0) revert InvalidAmount();
        exchangeRate = _exchangeRate;
        emit PriceSet(exchangeRate);
    }

    /**
     * @dev Checks if the given address is whitelisted for the ILO using a Merkle proof.
     * @param _merkleProof The Merkle proof to check the address against.
     * @param _address The address to check for whitelisting.
     * @return true if the address is whitelisted, false otherwise.
     */
    function isWhitelisted(
        bytes32[] calldata _merkleProof,
        address _address
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev Internal function to mint and send tokens to the user based on their contribution.
     * @return tokenAmount that have been minted and sent to the user.
     * @dev Reverts if the sent ether value is less than or equal to zero.
     * @dev Reverts if the sent ether value exceeds the maximum contribution limit.
     * @dev Reverts if the calculated token amount to be minted exceeds the available balance.
     * @dev Reverts if the total contribution amount for the user exceeds the individual maximum contribution limit.
     * @dev Emits a `Contribution` event with the number of tokens and the contributor's address.
     */
    function sendTokens() internal returns (uint256 tokenAmount) {
        if (msg.value == 0) revert InvalidAmount();

        if (
            publicContributions[msg.sender] +
                whitelistContributions[msg.sender] +
                msg.value >
            maxContribution
        ) revert IndividualMaxContributionReached();

        // Calculate the number of tokens to be minted based on the amount of ether sent by the user and the exchange rate
        tokenAmount = (msg.value * exchangeRate) / 10 ** 10;

        // Apply the discount
        uint256 discountedTokenAmount = (tokenAmount * discount) / 10000;
        tokenAmount += discountedTokenAmount;

        totalContributionsTokens += tokenAmount;
        totalContributions += msg.value;

        if (tokenAmount > ERC20(squidGrowToken).balanceOf(address(this)))
            revert MaxContributionReached();
        // Transfer the tokens to the user
        ERC20(squidGrowToken).safeTransfer(msg.sender, tokenAmount);
        emit Contribution(tokenAmount, msg.sender);
    }

    /**
     * @dev Allows users to contribute to the ILO during the public sale period.
     * @return tokenAmount that have been minted and sent to the user.
     * @dev Reverts if the ILO status is not set to `Public`.
     * @dev Uses the `sendTokens` internal function to mint and send tokens to the user based on their contribution.
     * @dev Emits a `Contribution` event with the number of tokens and the contributor's address.
     */
    function publicContribution()
        external
        payable
        nonReentrant
        returns (uint256 tokenAmount)
    {
        if (publicContributions[msg.sender] >= maxContribution)
            revert IndividualMaxContributionReached();
        if (status != ILOStatus.Public) revert PublicSaleNotActive();
        publicContributions[msg.sender] += msg.value;
        tokenAmount = sendTokens();
    }

    /**
     * @dev Allows whitelisted users to contribute to the ILO during the whitelist sale period using a Merkle proof.
     * @param _merkleProof The Merkle proof to check the user's address against.
     * @return tokenAmount that have been minted and sent to the user.
     * @dev Reverts if the ILO status is not set to `Whitelist`.
     * @dev Reverts if the user's address is not whitelisted.
     * @dev Reverts if the total contribution amount for the user exceeds the individual maximum contribution limit.
     * @dev Uses the `sendTokens` internal function to mint and send tokens to the user based on their contribution.
     * @dev Emits a `Contribution` event with the number of tokens and the contributor's address.
     */
    function whitelistContribution(
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant returns (uint256 tokenAmount) {
        if (whitelistContributions[msg.sender] >= maxContribution)
            revert IndividualMaxContributionReached();
        if (status != ILOStatus.Whitelist) revert WhitelistSaleNotActive();
        if (!isWhitelisted(_merkleProof, msg.sender)) revert NotWhitelisted();

        whitelistContributions[msg.sender] += msg.value;
        tokenAmount = sendTokens();
    }

    /**
     * @dev Allows the owner of the contract to withdraw the total contribution amount.
     * @dev Sends the entire balance of the contract to the owner's address.
     * @dev Reverts if the caller is not the owner of the contract.
     */
    function withdrawContribtions() external onlyOwner {
        payable(owner()).sendValue(address(this).balance);
        emit ContributionsWithdrawn(address(this).balance);
    }

    /**
     * @dev Allows the owner of the contract to withdraw any remaining tokens in the contract.
     * @dev Transfers the entire balance of the contract's `squidGrowtoken` tokens to the owner's address.
     * @dev Reverts if the caller is not the owner of the contract.
     * @dev Reverts if the token transfer fails.
     */
    function withdrawTokens() external onlyOwner {
        ERC20(squidGrowToken).safeTransfer(
            msg.sender,
            ERC20(squidGrowToken).balanceOf(address(this))
        );
        emit TokensWithdrawn(
            squidGrowToken,
            ERC20(squidGrowToken).balanceOf(address(this))
        );
    }

    /**
     * @dev Allows the owner of the contract to emergency withdraw any ERC20 tokens held by the contract.
     * @param token The address of the ERC20 token to withdraw.
     * @dev Transfers the entire balance of the specified token held by the contract to the owner's address.
     * @dev Reverts if the caller is not the owner of the contract.
     * @dev Reverts if the token transfer from the contract fails.
     */
    function emergencyWithdraw(address token) external onlyOwner {
        ERC20(token).safeTransfer(
            msg.sender,
            ERC20(token).balanceOf(address(this))
        );
        emit TokensWithdrawn(token, ERC20(token).balanceOf(address(this)));
    }

    ////   ----------  Trade IN   ----------   ////
    uint256 public bonusForTradeIn = 300;

    /**
     * @dev Sets the bonus for trade in.
     * @param _bonusForTradeIn The new bonus for trade in to be set.
     */
    function setBonusForTradeIn(uint256 _bonusForTradeIn) external onlyOwner {
        if (_bonusForTradeIn > 10000) revert OutOfRange();
        bonusForTradeIn = _bonusForTradeIn;
        emit SetBonusForTradeIn(_bonusForTradeIn);
    }

    /**
     * @dev Allows the users to offer their tokens in exchange for an IOU to a later airdrop on ETH with a 3% bonus.
     * @param amount The amount of tokens to offer.
     * @dev Transfers the tokens from the user to the contract and mints the IOU tokens to the user.
     */
    function depositTokensForAirdrop(uint256 amount) external nonReentrant {
        ERC20(squidGrowToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        uint256 extraTokens = (amount * bonusForTradeIn) / 10000;
        uint256 amountToMint = amount + extraTokens;
        _mint(msg.sender, amountToMint);
        emit TokensDepositedForAirdrop(amount);
    }

    /**
     * @dev Overrides the `decimals` function to set the number of decimals to 19. Same as the SquidGrow Token on BSC
     */
    function decimals() public view virtual override returns (uint8) {
        return 19;
    }

    /**
     * @dev Sets the claimable variable, which determines if the airdrop is currently claimable.
     * @param _claimable Whether the airdrop should be claimable or not.
     */
    function setClaimable(bool _claimable) external onlyOwner {
        claimable = _claimable;
        emit SetClaimable(_claimable);
    }

    /**
     * @dev Checks if a specific index has been claimed.
     * @param index The index to check.
     * @return A boolean indicating whether the index has been claimed or not.
     */
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @dev Sets a specific index as claimed.
     * @param index The index to set as claimed.
     */
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /**
     * @dev Claims the airdrop for a specific index, transferring the specified amount of tokens to the caller.
     * @param index The index of the airdrop to claim.
     * @param amount The amount of tokens to claim.
     * @param merkleProof The Merkle proof for the claim.
     */
    function claimAirdrop(
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (isClaimed(index)) {
            revert AlreadyClaimed();
        }

        if (!claimable) {
            revert ClaimNotActive();
        }

        if (!isWhitelistedForAirdrop(index, msg.sender, amount, merkleProof)) {
            revert IsNotWhitelisted();
        }

        _setClaimed(index);

        ERC20(squidGrowToken).safeTransfer(msg.sender, amount);

        emit AirdropClaimed(msg.sender, amount);
    }

    /**
     * @dev Checks if an account is whitelisted for the airdrop.
     * @param index The index of the airdrop.
     * @param account The account to check.
     * @param amount The amount of tokens.
     * @param merkleProof The Merkle proof for the claim.
     * @return A boolean indicating whether the account is whitelisted or not.
     */
    function isWhitelistedForAirdrop(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        bool isValidProof = MerkleProof.verifyCalldata(
            merkleProof,
            merkleRoot,
            leaf
        );
        return isValidProof;
    }
}
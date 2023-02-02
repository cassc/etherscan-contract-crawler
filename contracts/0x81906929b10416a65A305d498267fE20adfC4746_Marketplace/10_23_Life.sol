// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ManageLife.sol";
import "./MLInvestorsNFT.sol";

/**
 * @notice An ERC-20 contract for ManageLife.
 * Token Symbol: MLIFE ($MLIFE)
 * This contract manages token rewards issued to ManageLife homeowners and investors.
 * This contract also handles native token functions (EIP20 Token Standard).
 *
 * @author https://managelife.co
 */
contract Life is ERC20, Ownable, Pausable {
    /**
     * @notice Mapping to get the start of staking for each NFTs.
     * Start of stake data is in UNIX timestamp form.
     */
    mapping(uint256 => uint64) public startOfStakingRewards;

    /// @notice Maximum token supply
    uint256 public constant MAX_SUPPLY = 5000000000000000000000000000;

    /// Instance of the MLIFE NFT contract
    ManageLife private _manageLifeToken;

    /// Instance of the NFTi contract
    ManageLifeInvestorsNFT private _investorsNft;

    /// Set initial token supply before deploying.
    constructor() ERC20("ManageLife Token", "MLIFE") {
        _mint(msg.sender, 2000000000000000000000000000);
    }

    event StakingClaimed(address indexed claimaint, uint256 tokenId);
    event TokensBurned(address indexed burnFrom, uint256 amount);

    /// @notice Security feature to Pause smart contracts transactions
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /// @notice Unpausing the Paused transactions feature.
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    /**
     * @notice Set the MLIFE's NFT contract address.
     * @dev Important to set this after deployment.
     * @param manageLifeToken_ Address of the MLIFE NFT contract
     */
    function setManageLifeToken(
        address manageLifeToken_
    ) external onlyOwner whenNotPaused {
        _manageLifeToken = ManageLife(manageLifeToken_);
    }

    /**
     * @notice Set the NFTi contract address.
     * @dev Important to set this after deployment.
     * @param investorsNft_ Contract address of NFTi contract.
     */
    function setNftiToken(
        address investorsNft_
    ) external onlyOwner whenNotPaused {
        _investorsNft = ManageLifeInvestorsNFT(investorsNft_);
    }

    /**
     * @notice Return the MLIFE's contract address.
     * @dev If set, this will return the MLIFE contract address
     * @return address
     */
    function manageLifeToken() external view returns (address) {
        return address(_manageLifeToken);
    }

    /**
     * @notice Return the NFTi's contract address.
     * @dev If set, this will return the NFTi contract address.
     * @return  address
     */
    function manageLifeInvestorsNft() external view returns (address) {
        return address(_investorsNft);
    }

    /**
     * @notice Initialize the Staking for an NFT.
     *
     * @dev Reverts if the caller is not the MLIFE contract address,
     * MLIFE contact address is not set and if the contract is on-paused status.
     *
     * @param tokenId TokenId of the NFT to start stake.
     */
    function initStakingRewards(uint256 tokenId) external whenNotPaused {
        require(
            address(_manageLifeToken) != address(0),
            "ManageLife token is not set"
        );
        // Making sure the one who will trigger this function is only the ManageLife NFT contract.
        require(
            msg.sender == address(_manageLifeToken),
            "Only ManageLife token"
        );
        startOfStakingRewards[tokenId] = uint64(block.timestamp);
    }

    /**
     * @notice Update the start of stake of an NFT.
     *
     * @dev Since staking reward is based on time, this function will
     * reset the stake start of an NFT that just recently claimed a token reward.
     * This will be also an on-demand operation where the admins needs to reset
     * the start of stake of an NFT, based off UNIX time.
     *
     * @param tokenId TokenID of an NFT.
     * @param newStartDate New start of stake of an NFT. This param should be based on
     * UNIX timestamp and into uint64 type.
     */
    function updateStartOfStaking(
        uint256 tokenId,
        uint64 newStartDate
    ) external {
        require(
            msg.sender == owner() || msg.sender == address(_manageLifeToken),
            "Ony admins can execute this operation"
        );
        startOfStakingRewards[tokenId] = newStartDate;
    }

    /**
     * @notice Returns the claimable $LIFE token of an NFT.
     *
     * @dev MLifeNFT contract is dependent on this function in calculating
     * the estimated staking rewards of an MLifeNFT.
     * Formula in calculating the reward:
     * Rewards = Current timestamp - StartOfStake timestamp * Life token issuance rate.
     *
     * @param tokenId MLifeNFT's tokenId.
     * @return uint256
     */
    function claimableStakingRewards(
        uint256 tokenId
    ) public view returns (uint256) {
        if (uint64(block.timestamp) < startOfStakingRewards[tokenId]) {
            return 0;
        }
        return
            (uint64(block.timestamp) - startOfStakingRewards[tokenId]) *
            _manageLifeToken.lifeTokenIssuanceRate(tokenId);
    }

    /**
     * @notice Burns $MLIFE token from a sender's account. Assuming that sender holds $MLIFE tokens.
     * @param amount Amount to burn.
     */
    function burnLifeTokens(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @notice Function to mint additional token supply.
     *
     * @dev Newly minted amount will be credited to the contract owner.
     * Prevents minting of new tokens if 5B supply is reached.
     *
     * @param _amount Additional amount to be minted.
     */
    function mint(uint256 _amount) external onlyOwner isMaxSupply(_amount) {
        _mint(msg.sender, _amount);
    }

    /**
     * @notice Mint $MLIFE token rewards for NFTi Investors.
     *
     * @dev MLifeNFTi contract depends on this function to mint $LIFE
     * token rewards to investors. Newly minted tokens here will be
     * credited directly to the investor's wallet address and NOT on the admin wallet.
     * Minting new token supply if 5B LIFE token supply is reached.
     *
     * @param investorAddress Wallet address of the investor.
     * @param _amount Amount to be minted on the investor's address. Amount is based on the
     * calculated staking rewards from MLifeNFTi contract.
     */
    function mintInvestorsRewards(
        address investorAddress,
        uint256 _amount
    ) external isMaxSupply(_amount) {
        _mint(investorAddress, _amount);
    }

    /**
     * @notice Claim $MLIFE token staking rewards.
     *
     * @dev MLifeNFT's rewards issuance is reliant on this function.
     * Once the user claim the rewards, this function will mint the
     * tokens directly on the homeowner's wallet.
     * Notes:
     * - ML's admin or deployer wallet cannot claim $LIFE rewards.
     * - Setting the MLifeNFT contract address is prerequisite in running this function.
     * - This function can only be called by MLifeNFT holders.
     * - A percentage of the token reward will be burned. Percentage will be determined by the ML admin.
     * - Burn call will be handled separately by the frontend app.
     *
     * @param tokenId MLifeNFT's tokenId.
     */
    function claimStakingRewards(uint256 tokenId) public whenNotPaused {
        /*** @notice Variable containers that holds the claimable amounts of the user. */
        uint256 rewards = claimableStakingRewards(tokenId);

        require(
            address(_manageLifeToken) != address(0),
            "ManageLife token is not set"
        );

        /// @dev Making sure that admin wallet will not own token rewards.
        require(
            _manageLifeToken.ownerOf(tokenId) != owner(),
            "Platform wallet cannot claim"
        );

        /// @dev Making sure that only admin and MLifeNFT owners will claim the rewards.
        require(
            msg.sender == owner() ||
                msg.sender == _manageLifeToken.ownerOf(tokenId) ||
                msg.sender == address(_manageLifeToken),
            "Unauthorized."
        );

        /// @dev Adding require check to comply with the maximum token supply.
        require(totalSupply() + rewards <= MAX_SUPPLY, "$LIFE supply is maxed");

        /**
         * @dev If the answer on the above questions are true,
         * mint new ERC20 $LIFE tokens. Claimable amount will be minted on the property owner.
         * At the same time, a percentage of the claimed reward will be burned
         * which will be handled separately by the frontend app.
         */
        _mint(_manageLifeToken.ownerOf(tokenId), rewards);

        /**
         * @dev Resetting the startOfStakingsRewards of the token to make
         * sure their claimable rewards will reset as well.
         */
        startOfStakingRewards[tokenId] = uint64(block.timestamp);
        emit StakingClaimed(msg.sender, rewards);
    }

    /**
     * @notice Custom access modifier to make sure that the caller of transactions are member of ML.
     * @dev This identifies if the caller is an MLifeNFT or MLifeNFTi holder.
     * @param tokenId TokenId of the NFT that needs to be checked.
     */
    modifier onlyMembers(uint256 tokenId) {
        require(
            msg.sender == _manageLifeToken.ownerOf(tokenId) ||
                msg.sender == _investorsNft.ownerOf(tokenId),
            "Only NFT holders can execute this"
        );
        _;
    }

    /**
     * @notice Custom access modifier to make sure minting will not exceed.
     * @dev This makes sure that the $MLIFE max supply is 5B.
     * @param amount new amount to be minted.
     */
    modifier isMaxSupply(uint256 amount) {
        require(totalSupply() + amount <= MAX_SUPPLY, "$LIFE supply is maxed");
        _;
    }
}
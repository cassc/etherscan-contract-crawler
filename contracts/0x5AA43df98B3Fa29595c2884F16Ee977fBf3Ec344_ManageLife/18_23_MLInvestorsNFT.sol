// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./Life.sol";

/**
 * @notice ManageLife Investor (ERC-721) contract for ManageLife Investors.
 * Owning this NFT represents a investment in ManageLife's properties in real life.
 * NFT Symbol: MLifeNFTi
 *
 * @author https://managelife.co
 */
contract ManageLifeInvestorsNFT is ERC721A, Ownable {
    /// Life token instance
    Life public lifeToken;

    /// Mapping of NFTi tokenId to their issuance rates
    mapping(uint256 => uint256) private _lifeTokenIssuanceRate;

    /// Mapping of NFTi tokenId to their start of staking
    mapping(uint256 => uint64) public stakingRewards;

    /// Mapping of NFTi tokenId to their unlock dates
    mapping(uint256 => uint256) public unlockDate;

    /// @notice Public base URI of ML's NFTs
    string public baseUri = "https://iweb3api.managelifeapi.co/api/v1/nfts/";

    event BaseURIUpdated(string _newURIAddress);
    event StakingClaimed(address indexed claimaint, uint256 tokenId);
    event TokenBurned(address indexed burnFrom, uint256 amount);

    event TokenIssuanceRateUpdates(
        uint256 indexed tokenId,
        uint256 newLifeTokenIssuanceRate
    );
    event StakingInitiated(uint256 indexed tokenId);
    event BurnedNft(uint256 tokenId);

    constructor() ERC721A("ManageLife Investor", "MLifeNFTi") {}

    /**
     * @notice Mint new NFTis.
     * @param quantity Number of NFTis to be minted.
     */
    function mint(uint256 quantity) external onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    /**
     * @notice Function to change the base URI of the NFTs.
     * @dev Giving the ML Admins an options in the future to change the URI of NFTs.
     * @param newBaseUri New URI string.
     */
    function setBaseURI(string memory newBaseUri) external onlyOwner {
        baseUri = newBaseUri;
        emit BaseURIUpdated(newBaseUri);
    }

    /**
     * @notice Set the Life token contract address.
     * @dev Important to set this after deployment in order to build integration with
     * the ERC20 contract.
     * @param lifeToken_ $LIFE token contract address.
     */
    function setLifeToken(address lifeToken_) external onlyOwner {
        lifeToken = Life(lifeToken_);
    }

    /**
     * @notice Query the life token issuance rate of an NFTi.
     * @dev Default token issuance rate of NFTi is set by admins once the NFTi is
     * issued to investor. Issuance rates varies per NFTi and is maintained by ML admins.
     * @param   tokenId NFTi's tokenId.
     * @return  uint256
     */
    function lifeTokenIssuanceRate(
        uint256 tokenId
    ) external view returns (uint256) {
        return _lifeTokenIssuanceRate[tokenId];
    }

    /**
     * @notice Update life token issuance rate of an NFTi.
     *
     * @dev Updated issuance rate will be provided manually by ML admins.
     * If an NFTi has an accumulated rewards already, the reward will be transferred
     * first to the holder before updating the issuance rate.
     *
     * @param tokenId NFTi's tokenId.
     * @param newLifeTokenIssuanceRate New issuance rate as provided by ML admins.
     */
    function updateLifeTokenIssuanceRate(
        uint256 tokenId,
        uint256 newLifeTokenIssuanceRate
    ) external onlyOwner {
        /// Transfer first the exisiting reward to the NFTi holder before rate update takes place.
        lifeToken.mintInvestorsRewards(
            ownerOf(tokenId),
            checkClaimableStakingRewards(tokenId)
        );

        /// Resetting the start of stake to current time to halt the reward accumulation in the meantime.
        stakingRewards[tokenId] = uint64(block.timestamp);

        /// Once all rewards has been minted to the owner, reset the lifeTokenIssuance rate
        _lifeTokenIssuanceRate[tokenId] = newLifeTokenIssuanceRate;
        emit TokenIssuanceRateUpdates(tokenId, newLifeTokenIssuanceRate);
    }

    /**
     * @notice Initialize the staking reward for an NFTi.
     *
     * @dev This will be triggered by the transfer hook and requires that
     * the MLifeNTi contract should be set.
     *
     * @param tokenId TokenId of NFTi to be set.
     */
    function initStakingRewards(uint256 tokenId) internal onlyOwner {
        require(
            address(lifeToken) != address(0),
            "ManageLife Token is not set"
        );

        stakingRewards[tokenId] = uint64(block.timestamp);
        emit StakingInitiated(tokenId);
    }

    /**
     * @notice Function to issue an NFT to investors for the first time. Should be used by ML admins only.
     *
     * @dev Admins will be able to set an initial issuance rate for the NFT and initiate their staking.
     * If the NFT has already an accumulated rewards, admins will not be able to transfer it to other address.
     * Once this has been issued to an investor, the NFTi will be locked up by default for 1 year. At this period,
     * the NFTi will not be able to be transfer to any contract or wallet address. Lock up period can be updated
     * by admin wallet.
     *
     * @param to Address to issue the NFT
     * @param tokenId TokenId to be issued.
     * @param lifeTokenIssuanceRate_ Token issuance rate. Will be based on ML's mortgrage payment book.
     */
    function issueNftToInvestor(
        address to,
        uint256 tokenId,
        uint256 lifeTokenIssuanceRate_
    ) external onlyOwner {
        _lifeTokenIssuanceRate[tokenId] = lifeTokenIssuanceRate_;
        safeTransferFrom(msg.sender, to, tokenId);

        /// Setting lock up dates to 365 days (12 months) as default.
        unlockDate[tokenId] = uint64(block.timestamp) + 365 days;

        /// Initialiaze Staking.
        initStakingRewards(tokenId);
    }

    /// @notice Function to check the claimable staking reward of an NFT
    function checkClaimableStakingRewards(
        uint256 tokenId
    ) public view returns (uint256) {
        return
            (uint64(block.timestamp) - stakingRewards[tokenId]) *
            _lifeTokenIssuanceRate[tokenId];
    }

    /**
     * @notice Claim $LIFE token staking rewards.
     *
     * @dev The rewards will be directly minted on the caller address.
     * Once success, the timestamp of _stakingRewards for that tokenId will be reset.
     *
     * @param tokenId TokenId of the NFT.
     */
    function claimStakingRewards(uint256 tokenId) public onlyInvestor(tokenId) {
        /// Making sure that ML wallet will not claim the reward
        require(msg.sender != owner(), "Platform wallet cannot claim");

        uint256 rewards = checkClaimableStakingRewards(tokenId);

        /// Mint the claimable $LIFE reward to the investor address.
        lifeToken.mintInvestorsRewards(msg.sender, rewards);

        /// @notice Record new timestamp data to reset the staking rewards data
        stakingRewards[tokenId] = uint64(block.timestamp);
        emit StakingClaimed(msg.sender, tokenId);
    }

    /**
     * @notice Transfer NFTi function
     * @dev This transfer operation checks for some requirements before it
     * successfully proceed.
     * Requirements:
     * - Sender must be the NFTi owner
     * - NFTi should have no or have finished the locked up period.
     *
     * @param to Receiver of NFTi
     * @param tokenId NFTi tokenId to be sent.
     */
    function transferNft(address to, uint256 tokenId) external {
        require(
            msg.sender == ownerOf(tokenId),
            "Error: You must be the owner of this NFT"
        );

        if (msg.sender == owner()) {
            safeTransferFrom(msg.sender, to, tokenId);
        } else {
            // Before transferring the NFT to new owner, make sure that NFT has finished it's locked up period
            require(
                block.timestamp >= unlockDate[tokenId],
                "Error: NFT hasn't finished locked up period"
            );
            /// @dev If the NFT has a pending reward greater than 100 $LIFE tokens, it should be claimed first before transferring
            require(
                checkClaimableStakingRewards(tokenId) > 100,
                "Has claimable reward"
            );

            safeTransferFrom(msg.sender, to, tokenId);
        }

        /// @dev If the locked up period has been completed, reset the time to unlock of the said NFT to default 365 days
        unlockDate[tokenId] = uint64(block.timestamp) + 365 days;
    }

    /**
     * @notice Return the NFTi to ML wallet.
     *
     * @dev Use case - The investment period has been completed for a specificc NFTi
     * and the asset needs to be returned. The investor should also clear the lockup
     * period of the NFT so that the admins can transfer it to anyone at anytime. In
     * an event that the NFTi has a claimable reward during the execution of this
     * operation, the reward will be transferred first to the investor.
     *
     * @param tokenId NFTi's tokenId.
     */
    function returnNftToML(uint256 tokenId) external {
        require(
            msg.sender == ownerOf(tokenId),
            "Error: You must be the owner of this NFT"
        );
        /// If the NFT has a pending reward, it should be claimed first before transferring
        if (checkClaimableStakingRewards(tokenId) >= 0) {
            claimStakingRewards(tokenId);
        }
        /// Resetting the unlock date to remove the lock up period
        unlockDate[tokenId] = block.timestamp;
        safeTransferFrom(msg.sender, owner(), tokenId);
    }

    /***
     * @notice Function to update the lockdate of an NFT
     * @param tokenId TokenId of an NFT
     * @param _newLockDate Unix timestamp of the new lock date
     */
    function setLockDate(
        uint256 tokenId,
        uint256 _newLockDate
    ) external onlyOwner {
        unlockDate[tokenId] = _newLockDate;
    }

    /***
     * @notice Function to burn an NFTi.
     *
     * @dev Use case of this is if the investor failed to return the NFTi to ML for
     * certain period of time and circumstances, ML admin will burn the NFTi and replace it in circulation.
     * Another use-case is if the property has exited the ManageLife program.
     *
     * @param tokenId TokenId of an NFT
     */
    function burnNFt(uint256 tokenId) external onlyOwner {
        super._burn(tokenId);
        emit BurnedNft(tokenId);
    }

    /***
     * @notice Function to brute force retrieving the NFTi from a holder
     * @param tokenId TokenId of an NFT
     * @dev Requirements:
     *  - The holder of an NFT should give an approval for all (setApprovalForAll()) to the contract address,
     * in order for the function below to run successfully. This will be implemented on the frontend app.
     */
    function forceClaimNft(uint256 tokenId) external onlyOwner {
        super.transferFrom(ownerOf(tokenId), msg.sender, tokenId);
    }

    /// @dev Modifier checks to see if the token holder is an NFTi investor
    modifier onlyInvestor(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "Only for NFTIs owner");
        _;
    }
}
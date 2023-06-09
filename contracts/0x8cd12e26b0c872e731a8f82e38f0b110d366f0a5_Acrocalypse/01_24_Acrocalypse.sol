// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Acrocalypse is
    ERC721Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    string public baseURI;
    uint256 public maxSupply;
    uint256 public maxClaimPerTransaction;

    address private acrocalypseV1Address;

    // allow rewards until
    uint256 public allowRewardsEarningsUntil;

    // signer address for verification
    address public signerAddress;

    // paper token address
    IERC20 public paperTokenAddress;

    // Token Staking
    struct StakedToken {
        address owner;
        uint256 tokenId;
        uint256 stakePool;
        uint256 rewardsPerDay;
        uint256 pool1RewardsPerDay;
        uint256 creationTime;
        uint256 lockedUntilTime;
        uint256 lastClaimTime;
    }

    // Mapping to store all the tokens staked
    mapping(uint256 => StakedToken) public stakedTokens;

    uint256 public totalStaked;
    uint256 public totalPool1Staked;
    uint256 public totalPool2Staked;
    uint256 public totalPool3Staked;

    bool public enablePool1Staking;
    bool public enablePool2Staking;
    bool public enablePool3Staking;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(address _acrocalypseV1Address, address _paperTokenAddress) external initializer {
        __ERC721_init("Acrocalypse", "ACROC");
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();

        signerAddress = _msgSender();
        allowRewardsEarningsUntil = block.timestamp + 730 * 86400; // solhint-disable-line not-rely-on-time

        acrocalypseV1Address = _acrocalypseV1Address;
        paperTokenAddress = IERC20(_paperTokenAddress);

        baseURI = "ipfs://QmbEvQcsUzLdosWJpNXeCWxMYgfd595P9BRDWEqzAUuVQu/";
        maxSupply = 10420;
        maxClaimPerTransaction = 50;

        enablePool1Staking = true;
        enablePool2Staking = true;
        enablePool3Staking = true;
    }

    //external
    fallback() external payable {}

    receive() external payable {} // solhint-disable-line no-empty-blocks

    modifier callerIsUser() {
        require(!_isContract(_msgSender()), "Contract not allowed");
        // solhint-disable-next-line avoid-tx-origin
        require(_msgSender() == tx.origin, "Proxy contract not allowed");
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Function to exchange v1 CROC NFT to v2
     */
    function claimV1NFT(uint256[] calldata tokenIds) external nonReentrant whenNotPaused callerIsUser {
        require(tokenIds.length <= maxClaimPerTransaction, "Beyond max claim limit");

        // Transfer and mint
        _claimV1NFT(tokenIds);
    }

    /**
     * @dev function to let admin mint for a wallet
     */
    function mintOwner(uint256[] calldata tokenIds, address to) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(to, tokenIds[i]);
        }
    }

    /**
     * @dev Function to exchange v1 CROC NFT to v2 and also stake at the same time
     */
    function claimAndStakeV1NFT(
        bytes memory signature,
        uint256 stakePool,
        uint256[] calldata tokenIds,
        uint256[] calldata rewardsPerDay,
        uint256[] calldata pool1RewardsPerDay
    ) external nonReentrant whenNotPaused callerIsUser {
        require(tokenIds.length <= maxClaimPerTransaction, "Beyond max claim limit");

        // Transfer and mint
        _claimV1NFT(tokenIds);

        // Stake tokens
        stake(signature, stakePool, tokenIds, rewardsPerDay, pool1RewardsPerDay);
    }

    function _claimV1NFT(uint256[] memory tokenIds) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(acrocalypseV1Address).transferFrom(_msgSender(), address(this), tokenIds[i]);
            _mint(_msgSender(), tokenIds[i]);
        }
    }

    /**
     * @dev function to stake NFTs
     */
    function stake(
        bytes memory signature,
        uint256 stakePool,
        uint256[] memory tokenIds,
        uint256[] memory rewardsPerDay,
        uint256[] memory pool1RewardsPerDay
    ) public payable whenNotPaused callerIsUser {
        require(block.timestamp < allowRewardsEarningsUntil, "Staking period expired"); // solhint-disable-line not-rely-on-time
        bytes32 hash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(abi.encodePacked(_msgSender(), stakePool, tokenIds, rewardsPerDay, pool1RewardsPerDay))
        );

        if (stakePool == 1) {
            require(enablePool1Staking, "Staking disabled");
        } else if (stakePool == 2) {
            require(enablePool2Staking, "Staking disabled");
        } else if (stakePool == 3) {
            require(enablePool3Staking, "Staking disabled");
        }

        // verifying the signature
        require(ECDSAUpgradeable.recover(hash, signature) == signerAddress, "Invalid Access");

        // token validation
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // validating the token ids if already staked or not
            require(stakedTokens[tokenIds[i]].owner == address(0), "Token ID already staked");

            // validating the token ownership
            require(ownerOf(tokenIds[i]) == _msgSender(), "Token owner mismatch");

            uint256 lockedDays = 7; // pool 1
            uint256 lockedDaysTimePeriod = 604800;

            if (stakePool == 1) {
                totalPool1Staked++;
            } else if (stakePool == 2) {
                // pool 2
                lockedDays = 45;
                lockedDaysTimePeriod = 3888000;
                totalPool2Staked++;
            } else if (stakePool == 3) {
                // pool 3
                lockedDays = 90;
                lockedDaysTimePeriod = 7776000;
                totalPool3Staked++;
            }

            uint256 lockedUntil = block.timestamp + lockedDaysTimePeriod; // solhint-disable-line not-rely-on-time
            if (lockedUntil > allowRewardsEarningsUntil) {
                lockedUntil = allowRewardsEarningsUntil;
            }

            stakedTokens[tokenIds[i]] = StakedToken({
                owner: _msgSender(),
                tokenId: tokenIds[i],
                stakePool: stakePool,
                rewardsPerDay: rewardsPerDay[i],
                pool1RewardsPerDay: pool1RewardsPerDay[i],
                creationTime: block.timestamp, // solhint-disable-line not-rely-on-time
                lastClaimTime: 0,
                lockedUntilTime: lockedUntil
            });
        }

        totalStaked += tokenIds.length;
    }

    function claim(uint256[] calldata tokenIds) external payable whenNotPaused callerIsUser {
        require(_claim(tokenIds, _msgSender(), false), "Error Claiming");
    }

    function claimAndUnstake(uint256[] calldata tokenIds) external payable whenNotPaused callerIsUser {
        bool claimStatus = _claim(tokenIds, _msgSender(), true);
        require(claimStatus, "Error Claiming");

        bool unstakeStatus = _unstake(tokenIds, _msgSender(), false);
        require(unstakeStatus, "Error Unstaking");
    }

    function unstakeAdmin(uint256[] calldata tokenIds) external onlyOwner {
        require(_unstake(tokenIds, address(0), true), "Error Unstaking");
    }

    function _claim(uint256[] memory tokenIds, address senderAddress, bool isUnstaking) internal returns (bool) {
        require(tokenIds.length > 0, "Token Ids not set");

        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            StakedToken memory sToken = stakedTokens[tokenIds[i]];

            // slither-disable-next-line incorrect-equality
            require(sToken.owner == senderAddress, "Invalid Token Access");

            totalRewards += calculateTokenUnclaimedRewards(tokenIds[i]);

            if (!isUnstaking) {
                // slither-disable-next-line incorrect-equality
                if (sToken.stakePool == 1) {
                    // extending the lock time by 7 days
                    uint256 lockedUntil = block.timestamp + 604800; // solhint-disable-line not-rely-on-time
                    if (lockedUntil > allowRewardsEarningsUntil) {
                        lockedUntil = allowRewardsEarningsUntil;
                    }
                    sToken.lockedUntilTime = lockedUntil;
                }

                sToken.lastClaimTime = block.timestamp; // solhint-disable-line not-rely-on-time
                stakedTokens[tokenIds[i]] = sToken;
            }
        }

        // Transfer the $PAPER Tokens
        bool success = paperTokenAddress.transfer(senderAddress, totalRewards.div(86400));
        require(success, "Unable to transfer tokens");

        return true;
    }

    function _unstake(uint256[] memory tokenIds, address senderAddress, bool isAdmin) internal returns (bool) {
        require(tokenIds.length > 0, "Token Ids not set");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            StakedToken memory sToken = stakedTokens[tokenIds[i]];
            require(sToken.owner != address(0), "Token not staked");

            // only the Owner of the token or Admin can do unstaking
            if (!isAdmin) {
                // slither-disable-next-line incorrect-equality
                require(sToken.owner == senderAddress, "Invalid Token Access");
                require(sToken.lockedUntilTime <= block.timestamp, "Unable to unstake a locked token"); // solhint-disable-line not-rely-on-time
            }

            if (sToken.stakePool == 1) {
                totalPool1Staked--;
            } else if (sToken.stakePool == 2) {
                totalPool2Staked--;
            } else if (sToken.stakePool == 3) {
                totalPool3Staked--;
            }

            totalStaked--;
            delete stakedTokens[tokenIds[i]];
        }

        return true;
    }

    function calculateTokenUnclaimedRewards(uint256 tokenId) public view returns (uint256) {
        StakedToken memory sToken = stakedTokens[tokenId];
        require(sToken.owner != address(0), "Unstaked Token");

        // solhint-disable-next-line not-rely-on-time
        uint256 currentTimestamp = block.timestamp;
        uint256 rewardsUntilTimestamp = currentTimestamp > allowRewardsEarningsUntil ? allowRewardsEarningsUntil : currentTimestamp;

        uint256 claimStartTimestamp = sToken.lastClaimTime > 0 ? sToken.lastClaimTime : sToken.creationTime;
        // lastClaimTime is always updated with block.timestamp after claim
        if (claimStartTimestamp > rewardsUntilTimestamp) {
            claimStartTimestamp = rewardsUntilTimestamp;
        }

        uint256 timeDifference = 0;
        uint256 totalRewards = 0;

        if (sToken.stakePool == 2 || sToken.stakePool == 3) {
            if (rewardsUntilTimestamp <= sToken.lockedUntilTime) {
                timeDifference = rewardsUntilTimestamp - claimStartTimestamp;
                totalRewards = timeDifference.mul(sToken.rewardsPerDay);
            } else {
                if (claimStartTimestamp <= sToken.lockedUntilTime) {
                    timeDifference = sToken.lockedUntilTime - claimStartTimestamp;
                    totalRewards = timeDifference.mul(sToken.rewardsPerDay);

                    timeDifference = rewardsUntilTimestamp - sToken.lockedUntilTime;
                    totalRewards += timeDifference.mul(sToken.pool1RewardsPerDay);
                } else {
                    timeDifference = rewardsUntilTimestamp - claimStartTimestamp;
                    totalRewards = timeDifference.mul(sToken.pool1RewardsPerDay);
                }
            }
        } else if (sToken.stakePool == 1) {
            timeDifference = rewardsUntilTimestamp - claimStartTimestamp;
            totalRewards = timeDifference.mul(sToken.rewardsPerDay);
        }

        return totalRewards;
    }

    function stakedOwnerTokens(address owner) external view returns (StakedToken[] memory) {
        require(owner != address(0), "zero address");

        uint256 ownerTokenCount = balanceOf(owner);
        uint256 ownerStakedCount = 0;

        StakedToken[] memory ownerStakedTokens = new StakedToken[](ownerTokenCount);

        for (uint256 i = 0; i <= maxSupply && ownerStakedCount < ownerTokenCount; ++i) {
            if (stakedTokens[i].owner == owner) {
                ownerStakedTokens[ownerStakedCount] = stakedTokens[i];
                ownerStakedCount++;
            }
        }

        if (ownerTokenCount == ownerStakedCount) {
            return ownerStakedTokens;
        }

        StakedToken[] memory finalStakedTokens = new StakedToken[](ownerStakedCount);
        for (uint256 i = 0; i < ownerStakedCount; ++i) {
            if (ownerStakedTokens[i].owner == owner) {
                finalStakedTokens[i] = ownerStakedTokens[i];
            }
        }

        return finalStakedTokens;
    }

    function checkTokensStakedStatus(uint256[] calldata tokenIds) external view returns (bool[] memory stakedStatus) {
        require(tokenIds.length > 0 && tokenIds.length <= maxSupply, "Token Ids not set");

        bool[] memory tokenIdsStakedStatus = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (stakedTokens[tokenIds[i]].owner != address(0)) {
                tokenIdsStakedStatus[i] = true;
            }
        }
        return tokenIdsStakedStatus;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function getTotalStakedCounters()
        external
        view
        returns (uint256 _totalStaked, uint256 _totalPool1Staked, uint256 _totalPool2Staked, uint256 _totalPool3Staked)
    {
        return (totalStaked, totalPool1Staked, totalPool2Staked, totalPool3Staked);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBaseTokenUri(string memory newBaseTokenUri) external onlyOwner {
        baseURI = newBaseTokenUri;
    }

    /**
     * @notice It allows the admin to set the signer address
     * @dev Only callable by owner.
     */
    function setSignerAddress(address newSignerAddress) external onlyOwner {
        if (address(newSignerAddress) != address(0)) {
            signerAddress = newSignerAddress;
        }
    }

    /**
     * @notice It allows the admin to set the contract address of V1 NFT
     * @dev Only callable by owner.
     */
    function setAcrocalypseV1Address(address newV1Address) external onlyOwner {
        if (address(newV1Address) != address(0)) {
            acrocalypseV1Address = newV1Address;
        }
    }

    function setPaperTokenAddress(address newAddress) external onlyOwner {
        if (address(newAddress) != address(0)) {
            paperTokenAddress = IERC20(newAddress);
        }
    }

    /**
     * @notice It allows the admin to set the max NFTs that be claimed in one transaction
     * @dev Only callable by owner.
     */
    function setMaxClaimPerTransaction(uint256 _maxClaimPerTransaction) external onlyOwner {
        maxClaimPerTransaction = _maxClaimPerTransaction;
    }

    function setTotalStakedCounters(
        uint256 _totalStaked,
        uint256 _totalPool1Staked,
        uint256 _totalPool2Staked,
        uint256 _totalPool3Staked
    ) external onlyOwner {
        totalStaked = _totalStaked;
        totalPool1Staked = _totalPool1Staked;
        totalPool2Staked = _totalPool2Staked;
        totalPool3Staked = _totalPool3Staked;
    }

    function setAllowRewardsEarningUntil(uint256 newAllowRewardsEarningsUntil) external onlyOwner {
        allowRewardsEarningsUntil = newAllowRewardsEarningsUntil;
    }

    function setEnablePool1Staking(bool _enablePoolStaking) external onlyOwner {
        enablePool1Staking = _enablePoolStaking;
    }

    function setEnablePool2Staking(bool _enablePoolStaking) external onlyOwner {
        enablePool2Staking = _enablePoolStaking;
    }

    function setEnablePool3Staking(bool _enablePoolStaking) external onlyOwner {
        enablePool3Staking = _enablePoolStaking;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param tokenAddress: the address of the token to withdraw
     * @param tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20Upgradeable(tokenAddress).safeTransfer(address(_msgSender()), tokenAmount);
    }

    function withdraw(uint256 percentWithdrawl) external onlyOwner {
        require(address(this).balance > 0, "No funds available");
        require(percentWithdrawl > 0 && percentWithdrawl <= 100, "Invalid Withdrawl percent");

        AddressUpgradeable.sendValue(payable(owner()), (address(this).balance * percentWithdrawl) / 100);
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        // slither-disable-next-line assembly
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function _beforeTokenTransfer(address from, address, uint256 tokenId, uint256) internal virtual override {
        // burning and transfer scenario when token is staked
        if (from != address(0)) {
            StakedToken memory sToken = stakedTokens[tokenId];
            require(sToken.owner == address(0), "Token staked");
        }
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
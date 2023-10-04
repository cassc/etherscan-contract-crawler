pragma solidity ^0.8.9;

import "./SupplyController.sol";
import "solmate/src/auth/Owned.sol";
import "./AuraToken.sol";
import "./FukushimaFishNFT.sol";
import "./FukushimaFishData.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract AuraSupplyControllerV1 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    SupplyController
{
    error SupplyLimitReached();
    error SeeminglyStrangeMaths();
    error NoTokensClaimable();

    // 0.054 $RAD / day
    uint256 constant NONE = 0.054 ether;

    // 0.304 $RAD / day
    uint256 constant LOW = 0.304 ether;

    // 0.75 $RAD / day
    uint256 constant MED = 0.75 ether;

    // 3 $RAD / day
    uint256 constant HIGH = 3 ether;

    // 10 $RAD / day
    uint256 constant DANGER = 10 ether;

    // 20 $RAD / day
    uint256 constant REACTOR = 20 ether;

    // The max supply of the token is 5 million (ether, 18 decimals)
    uint256 constant MAX_SUPPLY = 5_000_000 ether;

    struct ClaimData {
        uint256 lastClaimedTime;
        bool claimedBefore;
    }

    // token id => time last transferred
    mapping(uint256 => ClaimData) public lastClaimed;

    uint256 constant LEGACY_CONTRACT_SUPPLY_CUTOFF = 323;

    FukushimaFishNFT public oldFukushimaFish;
    FukushimaFishNFT public fukushimaFish;
    FukushimaFishData public data;

    AuraSupplyControllerV1 public oldSupplyController;

    AuraToken public token;

    bool public claimingOpen;

    function initialize(
        FukushimaFishNFT _fukushimaFish,
        FukushimaFishData _data,
        AuraToken _token
    ) external initializer {
        __Ownable_init();

        fukushimaFish = _fukushimaFish;
        token = _token;
        data = _data;
    }

    function setLastClaimed(
        uint256 tokenId,
        uint256 timestamp
    ) public onlyOwner {
        lastClaimed[tokenId] = ClaimData(timestamp, true);
    }

    function setLegacyContract(address addr) external onlyOwner {
        oldFukushimaFish = FukushimaFishNFT(addr);
    }

    function setOldSupplyController(address addr) external onlyOwner {
        oldSupplyController = AuraSupplyControllerV1(addr);
    }

    function setDataContract(FukushimaFishData _data) external onlyOwner {
        data = data;
    }

    function setClaimingOpen(bool b) external onlyOwner {
        claimingOpen = b;
    }

    function initializeToken(
        uint256 encodedData,
        uint256 path,
        bytes32[] calldata proof
    ) external {
        require(!data.isTokenInitiated(uint16(encodedData)));
        data.initTokenData(encodedData, path, proof);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function getMaxSupply() external pure override returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
      Claims the tokens
     */
    function claim(uint256 tokenId) external override {
        require(
            fukushimaFish.ownerOf(tokenId) == msg.sender,
            "you do not own this NFT"
        );
        uint256 amountClaimable = this.getClaimableTokens(address(0), tokenId);

        if (amountClaimable == 0) revert NoTokensClaimable();

        // if amount claimable +  total Supply pushes it over the edge.
        // only let them claim the amount up to the limit.
        uint256 newTokenSupply = amountClaimable + token.totalSupply();

        // we have like multiple sanity checks because i'm paranoid.
        // This lets them claim UP to the amount left.
        // assuming it is less than or equal to the original amount claimable.
        if (newTokenSupply >= MAX_SUPPLY) {
            uint256 diff = MAX_SUPPLY - token.totalSupply();

            if (diff > amountClaimable) revert SeeminglyStrangeMaths();
            if (diff == 0) revert SupplyLimitReached();

            if (diff <= amountClaimable) {
                amountClaimable = diff;
            }
        }

        token.mint(msg.sender, amountClaimable);

        if (!lastClaimed[tokenId].claimedBefore) {
            lastClaimed[tokenId] = ClaimData(block.timestamp, true);
        } else {
            lastClaimed[tokenId].lastClaimedTime = block.timestamp;
        }

        emit Claimed(msg.sender, tokenId, amountClaimable);
    }

    function getClaimableTokensID(
        uint256 tokenId
    ) external view returns (uint256) {
        return this.getClaimableTokens(address(0), tokenId);
    }

    function getLastClaimed(
        address addr,
        uint256 tokenId
    ) external view override returns (uint256) {
        uint256 timeSinceLastClaim = 0;

        if (address(oldSupplyController) != address(0)) {
            uint256 lastClaimed = oldSupplyController.getLastClaimed(
                addr,
                tokenId
            );

            if (lastClaimed != 0) {
                timeSinceLastClaim = lastClaimed;
            }
        }


        if (!lastClaimed[tokenId].claimedBefore && timeSinceLastClaim == 0) {
            timeSinceLastClaim = getMintTime(tokenId);
        } else {
            uint256 thisLastClaimed = lastClaimed[tokenId].lastClaimedTime;

            if (thisLastClaimed > timeSinceLastClaim) {
                timeSinceLastClaim = thisLastClaimed;
            }
        }

        return timeSinceLastClaim;
    }

    /**
       Gets the claimable tokens available for a given NFT
     */
    function getClaimableTokens(
        address _ignored,
        uint256 tokenId
    ) external view override returns (uint256) {
        // if the supply ever reaches the maximum supply we want to disable token generation
        if (
            token.totalSupply() >= MAX_SUPPLY ||
            !claimingOpen ||
            !fukushimaFish.exists(tokenId)
        ) {
            return 0;
        }

        uint256 timeSinceLastClaim = this.getLastClaimed(_ignored, tokenId);

        uint256 daysSince = (block.timestamp - timeSinceLastClaim) / 1 days;
        return data.getAuraYieldForToken(tokenId) * daysSince;
    }

    function getMintTime(uint256 tokenId) internal view returns (uint256) {
        if (
            tokenId <= LEGACY_CONTRACT_SUPPLY_CUTOFF &&
            address(oldFukushimaFish) != address(0)
        ) {
            return oldFukushimaFish.getMintTime(tokenId);
        }
        return fukushimaFish.getMintTime(tokenId);
    }

    /**
        Determines based on certain criteria if minting (anything that is able to generate new tokens) is allowed.

        e.g. We have a fixed supply and the current token count would surpass the max amount
     */
    function isMintingAllowed() external view override returns (bool) {
        return claimingOpen && token.totalSupply() < MAX_SUPPLY;
    }

    /**
       Determines based on certain criteria if burning is allowed.  
     */
    function isBurningAllowed() external view override returns (bool) {
        return false;
    }

    function onPostTransfer(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) external override {
        require(msg.sender == address(fukushimaFish), "NOT ALLOWED");
    }

    // Only the contract owner is allowed to upgrade this contract.
    // This will fail if the contract owner does not upgrade
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}
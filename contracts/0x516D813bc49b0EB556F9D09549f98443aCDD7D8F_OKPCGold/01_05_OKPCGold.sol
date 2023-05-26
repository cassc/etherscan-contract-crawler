/*

          
            .oooooo.   oooo    oooo ooooooooo.     .oooooo.     
           d8P'  `Y8b  `888   .8P'  `888   `Y88.  d8P'  `Y8b    
          888      888  888  d8'     888   .d88' 888            
          888      888  88888[       888ooo88P'  888            
          888      888  888`88b.     888         888            
          `88b    d88'  888  `88b.   888         `88b    ooo    
           `Y8bood8P'  o888o  o888o o888o         `Y8bood8P'    
          
          
            .oooooo.      .oooooo.   ooooo        oooooooooo.   
           d8P'  `Y8b    d8P'  `Y8b  `888'        `888'   `Y8b  
          888           888      888  888          888      888 
          888           888      888  888          888      888 
          888     ooooo 888      888  888          888      888 
          `88.    .88'  `88b    d88'  888       o  888     d88' 
           `Y8bood8P'    `Y8bood8P'  o888ooooood8 o888bood8P'   
          
           
          
           𝙰𝙽 𝙴𝚇𝚃𝙴𝙽𝚂𝙸𝙾𝙽 𝚃𝙾 𝙾𝙺𝙿𝙲 𝙶𝙰𝙻𝙻𝙴𝚁𝚈 𝙰𝚁𝚃𝚆𝙾𝚁𝙺 #𝟼𝟿: "𝙰𝙸𝚁𝙳𝚁𝙾𝙿"

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";
import "./interfaces/IOKPC.sol";
import "./interfaces/IOKPCMarketplace.sol";

/** 
@title OKPC Gold
@author shahruz.eth
*/

contract OKPCGold is Owned, ERC20 {
    // @dev Core OKPC contract
    IOKPC public immutable OKPC;

    // @dev Claim config
    uint256 public constant OKPC_CLAIM_MAX = 1_024;
    uint256 public constant AIRDROP_CLAIM = 10_000;

    // @dev Screen staking config
    uint256 public SCREEN_STAKING_INTERVAL = 64 days;
    uint256 public SCREEN_STAKING_REWARD = 256;

    // @dev Claim registry
    bool public CLAIMABLE;
    struct OKPCClaim {
        bool okpcClaimed;
        bool artworkClaimed;
        uint128 stakingLastClaimed;
    }
    mapping(uint256 => OKPCClaim) public okpcClaims;
    error ClaimNotOpen();
    error NoOKGLDClaimable();

    // @dev Modifiers
    modifier ifClaimable() {
        if (!CLAIMABLE) revert ClaimNotOpen();
        _;
    }

    // @dev Constructor
    constructor(IOKPC okpcAddress)
        Owned(msg.sender)
        ERC20("OKPC GOLD", "OKGLD", 18)
    {
        OKPC = okpcAddress;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  CLAIM ALL                                 */
    /* -------------------------------------------------------------------------- */

    // @notice Claim all eligible OKGLD for an OKPC.
    // @param pcId An OKPC tokenId. Reverts if the token is not owned by the caller.
    function claim(uint256 pcId) external ifClaimable {
        if (OKPC.ownerOf(pcId) != msg.sender) revert NoOKGLDClaimable();
        uint256 amount;
        amount += _claimForOKPC(pcId);
        amount += _claimForArtwork(pcId);
        amount += _claimForScreenStaking(pcId);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @notice Claim all eligible OKGLD for a set of OKPCs.
    // @param pcIds An array of OKPC tokenIds. Tokens not owned by the caller are skipped.
    function claim(uint256[] calldata pcIds) external ifClaimable {
        uint256 amount;
        for (uint256 i; i < pcIds.length; i++)
            if (OKPC.ownerOf(pcIds[i]) == msg.sender) {
                amount += _claimForOKPC(pcIds[i]);
                amount += _claimForArtwork(pcIds[i]);
                amount += _claimForScreenStaking(pcIds[i]);
            }
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @notice Calculate the total amount of OKGLD an OKPC is eligible to claim.
    // @param pcId An OKPC tokenId.
    function claimableAmount(uint256 pcId)
        public
        view
        returns (uint256 amount)
    {
        return
            claimableAmountForOKPC(pcId) +
            claimableAmountForArtwork(pcId) +
            claimableAmountForScreenStaking(pcId);
    }

    // @notice Calculate the total amount of OKGLD a set of OKPCs are eligible to claim.
    // @param pcIds An array of OKPC tokenIds.
    function claimableAmount(uint256[] calldata pcIds)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmount(pcIds[i]);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 OKPC CLAIM                                 */
    /* -------------------------------------------------------------------------- */

    // @notice Claim OKGLD for an OKPC, based on its clock speed and amount of art collected.
    // @param pcId An OKPC tokenId. Reverts if the token is not owned by the caller.
    function claimForOKPC(uint256 pcId) external ifClaimable {
        if (OKPC.ownerOf(pcId) != msg.sender) revert NoOKGLDClaimable();
        uint256 amount = _claimForOKPC(pcId);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @notice Claim OKGLD for a set of OKPCs, based on their clock speeds and amounts of art collected.
    // @param pcIds An array of OKPC tokenIds. Tokens not owned by the caller are skipped.
    function claimForOKPC(uint256[] calldata pcIds) external ifClaimable {
        uint256 amount;
        for (uint256 i; i < pcIds.length; i++)
            if (OKPC.ownerOf(pcIds[i]) == msg.sender)
                amount += _claimForOKPC(pcIds[i]);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @dev Calculate the amount of OKGLD an OKPC is eligible to claim, based on its clock speed and amount of art collected.
    // @dev Register the claimed OKPC using its tokenId to lock future claims.
    function _claimForOKPC(uint256 pcId) private returns (uint256 amount) {
        amount = claimableAmountForOKPC(pcId);
        if (amount > 0) okpcClaims[pcId].okpcClaimed = true;
    }

    // @notice Calculate the amount of OKGLD an OKPC is eligible to claim, based on its clock speed and amount of art collected.
    // @param pcId An OKPC tokenId.
    function claimableAmountForOKPC(uint256 pcId)
        public
        view
        returns (uint256 amount)
    {
        return claimableAmountForOKPC(pcId, 0);
    }

    // @notice Calculate the amount of OKGLD a set of OKPCs is eligible to claim, based on its clock speed and amount of art collected.
    // @param pcIds An array of OKPC tokenIds.
    function claimableAmountForOKPC(uint256[] calldata pcIds)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmountForOKPC(pcIds[i], 0);
    }

    // @notice Calculate the projected amount of OKGLD a set of OKPCs will be eligible to claim after a specified number of blocks, based on their clock speeds and amount of art collected.
    // @param pcIds An array of OKPC tokenIds.
    // @param afterBlocks An optional number of blocks to skip ahead for projected clock speed scores.
    function claimableAmountForOKPC(
        uint256[] calldata pcIds,
        uint256 afterBlocks
    ) public view returns (uint256 amount) {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmountForOKPC(pcIds[i], afterBlocks);
    }

    // @notice Calculate the projected amount of OKGLD an OKPC will be eligible to claim after a specified number of blocks, based on its clock speed and amount of art collected.
    // @param pcId An OKPC tokenId.
    // @param afterBlocks An optional number of blocks to skip ahead for projected clock speed scores.
    function claimableAmountForOKPC(uint256 pcId, uint256 afterBlocks)
        public
        view
        returns (uint256 amount)
    {
        if (okpcClaims[pcId].okpcClaimed == false) {
            uint256 artCount = OKPC.artCountForOKPC(pcId);
            uint256 total = (clockSpeedProjected(pcId, afterBlocks) / 2) *
                2**(artCount > 3 ? 3 : artCount);
            amount = total > OKPC_CLAIM_MAX ? OKPC_CLAIM_MAX : total;
        }
    }

    // @notice Calculate the projected clock speed of an OKPC after a specified number of blocks.
    // @param pcId An OKPC tokenId.
    // @param afterBlocks A number of blocks to skip ahead.
    function clockSpeedProjected(uint256 pcId, uint256 afterBlocks)
        public
        view
        returns (uint256)
    {
        (uint256 savedSpeed, uint256 lastBlock, , ) = OKPC.clockSpeedData(pcId);
        if (lastBlock == 0) return 1;
        uint256 delta = block.number + afterBlocks - lastBlock;
        uint256 multiplier = delta / 200_000;
        uint256 clockSpeedMaxMultiplier = OKPC.clockSpeedMaxMultiplier();
        if (multiplier > clockSpeedMaxMultiplier)
            multiplier = clockSpeedMaxMultiplier;
        uint256 total = savedSpeed + ((delta * (multiplier + 1)) / 10_000);
        if (total < 1) total = 1;
        return total;
    }

    // @notice Calculate the projected clock speed of a set of OKPCs after a specified number of blocks.
    // @param pcIds An array of OKPC tokenIds.
    // @param afterBlocks A number of blocks to skip ahead.
    function clockSpeedProjected(uint256[] calldata pcIds, uint256 afterBlocks)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](pcIds.length);
        for (uint256 i; i < pcIds.length; i++)
            result[i] = clockSpeedProjected(pcIds[i], afterBlocks);
        return result;
    }

    /* -------------------------------------------------------------------------- */
    /*                                ARTWORK CLAIM                               */
    /* -------------------------------------------------------------------------- */

    // @notice Claim OKGLD for an OKPC that has collected the AIRDROP artwork from the Gallery.
    // @param pcId An OKPC tokenId. Reverts if the token is not owned by the caller.
    function claimForArtwork(uint256 pcId) external ifClaimable {
        if (OKPC.ownerOf(pcId) != msg.sender) revert NoOKGLDClaimable();
        uint256 amount = _claimForArtwork(pcId);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @notice Claim OKGLD for a set of OKPCs that have collected the AIRDROP artwork from the Gallery.
    // @param pcIds An array of OKPC tokenIds. Tokens not owned by the caller are skipped.
    function claimForArtwork(uint256[] calldata pcIds) external ifClaimable {
        uint256 amount;
        for (uint256 i; i < pcIds.length; i++)
            if (OKPC.ownerOf(pcIds[i]) == msg.sender)
                amount += _claimForArtwork(pcIds[i]);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @dev Calculate the amount of OKGLD an OKPC is eligible to claim, based on collecting the AIRDROP artwork from the Gallery.
    // @dev Register the artwork claim using its tokenId to lock future claims.
    function _claimForArtwork(uint256 pcId) private returns (uint256 amount) {
        amount = claimableAmountForArtwork(pcId);
        if (amount > 0) okpcClaims[pcId].artworkClaimed = true;
    }

    // @notice Calculate the amount of OKGLD an OKPC is eligible to claim, based on collecting the AIRDROP artwork from the Gallery.
    // @param pcId An OKPC tokenId.
    function claimableAmountForArtwork(uint256 pcId)
        public
        view
        returns (uint256 amount)
    {
        if (
            okpcClaims[pcId].artworkClaimed == false &&
            OKPC.artCollectedByOKPC(pcId, 69)
        ) {
            if (
                OKPC.marketplaceAddress() == address(0) ||
                IOKPCMarketplace(OKPC.marketplaceAddress()).didMint(pcId, 69)
            ) amount = AIRDROP_CLAIM;
        }
    }

    // @notice Calculate the amount of OKGLD a set of OKPCs is eligible to claim, based on collecting the AIRDROP artwork from the Gallery.
    // @param pcId An array of OKPC tokenIds.
    function claimableAmountForArtwork(uint256[] calldata pcIds)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmountForArtwork(pcIds[i]);
    }

    /* -------------------------------------------------------------------------- */
    /*                               SCREEN STAKING                               */
    /* -------------------------------------------------------------------------- */

    // @notice Claim OKGLD for an OKPC that is continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcId An OKPC tokenId. Reverts if the token is not owned by the caller.
    function claimForScreenStaking(uint256 pcId) external ifClaimable {
        if (OKPC.ownerOf(pcId) != msg.sender) revert NoOKGLDClaimable();
        uint256 amount = _claimForScreenStaking(pcId);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @notice Claim OKGLD for a set of OKPCs that are continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcIds A set of OKPC tokenIds. Tokens not owned by the caller are skipped.
    function claimForScreenStaking(uint256[] calldata pcIds)
        external
        ifClaimable
    {
        uint256 amount;
        for (uint256 i; i < pcIds.length; i++)
            if (OKPC.ownerOf(pcIds[i]) == msg.sender)
                amount += _claimForScreenStaking(pcIds[i]);
        if (amount == 0) revert NoOKGLDClaimable();
        _mint(msg.sender, amount * 10**decimals);
    }

    // @dev Calculate the amount of OKGLD an OKPC is eligible to claim, based on continuously displaying the AIRDROP artwork from the Gallery.
    // @dev Register the screen staking claim to reset the clock.
    function _claimForScreenStaking(uint256 pcId)
        private
        returns (uint256 amount)
    {
        amount = claimableAmountForScreenStaking(pcId);
        if (amount > 0)
            okpcClaims[pcId].stakingLastClaimed = uint128(block.timestamp);
    }

    // @notice Calculate the amount of OKGLD an OKPC is eligible to claim, based on continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcId An OKPC tokenId.
    function claimableAmountForScreenStaking(uint256 pcId)
        public
        view
        returns (uint256 amount)
    {
        return claimableAmountForScreenStaking(pcId, 0);
    }

    // @notice Calculate the amount of OKGLD a set of OKPCs is eligible to claim, based on continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcIds An array of OKPC tokenIds.
    function claimableAmountForScreenStaking(uint256[] calldata pcIds)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmountForScreenStaking(pcIds[i]);
    }

    // @notice Calculate the projected amount of OKGLD an OKPC will be eligible to claim after a specified number of seconds, based on continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcId An OKPC tokenId.
    // @param afterTime An optional number of seconds to skip ahead for projected screen staking rewards.
    function claimableAmountForScreenStaking(uint256 pcId, uint256 afterTime)
        public
        view
        returns (uint256 amount)
    {
        if (OKPC.activeArtForOKPC(pcId) != 69) return 0;
        (, , , uint256 artLastChanged) = OKPC.clockSpeedData(pcId);
        uint256 previous = (
            okpcClaims[pcId].stakingLastClaimed > artLastChanged
                ? okpcClaims[pcId].stakingLastClaimed
                : artLastChanged
        );
        if (block.timestamp + afterTime >= previous + SCREEN_STAKING_INTERVAL)
            amount =
                SCREEN_STAKING_REWARD *
                ((block.timestamp + afterTime - previous) /
                    SCREEN_STAKING_INTERVAL);
    }

    // @notice Calculate the projected amount of OKGLD a set of OKPCs will be eligible to claim after a specified number of seconds, based on continuously displaying the AIRDROP artwork from the Gallery.
    // @param pcIds An array of OKPC tokenIds.
    // @param afterTime An optional number of seconds to skip ahead for projected screen staking rewards.
    function claimableAmountForScreenStaking(
        uint256[] calldata pcIds,
        uint256 afterTime
    ) public view returns (uint256 amount) {
        for (uint256 i; i < pcIds.length; i++)
            amount += claimableAmountForScreenStaking(pcIds[i], afterTime);
    }

    /* -------------------------------------------------------------------------- */
    /*                               TOKEN FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    // @notice Burn tokens and decrease the totalSupply.
    // @param amount An amount of tokens to burn.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    OWNER                                   */
    /* -------------------------------------------------------------------------- */

    // @notice Turn the ability to claim on or off. Owner only.
    function setClaimable(bool claimable) external onlyOwner {
        CLAIMABLE = claimable;
    }

    // @notice Adjust the screen staking configuration. Owner only.
    function setScreenStakingConfig(
        uint256 screenStakingInterval,
        uint256 screenStakingReward
    ) external onlyOwner {
        SCREEN_STAKING_INTERVAL = screenStakingInterval;
        SCREEN_STAKING_REWARD = screenStakingReward;
    }
}
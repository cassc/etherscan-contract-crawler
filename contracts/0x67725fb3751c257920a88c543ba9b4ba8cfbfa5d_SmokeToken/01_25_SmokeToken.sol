// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/**
 * @dev Extends standard ERC20 contract from OpenZeppelin
 */
contract SmokeToken is ERC20PresetMinterPauser("Smoke", "SMOKE"), ReentrancyGuard {
    /// @notice Start timestamp from contract deployment    
    uint256 public immutable emissionStart;
    /// @notice End date for Smoke emissions to Dormant Dragons holders
    uint256 public immutable emissionEnd;

    /// @dev Contract address for Dormant Dragon holders
    address private _nftAddress;


    /// @dev A record of last claimed timestamp for Dormtant Dragons
    mapping(uint256 => uint256) private _lastClaim;

    /**
     * @param emissionStartTimestamp Timestamp of reveal period
     */
    constructor(uint256 emissionStartTimestamp) {
        emissionStart = emissionStartTimestamp;
        emissionEnd = emissionStartTimestamp + (getInterval(1800));

        mint(0x0Ac8ee50498f45E58d6Af385bB6B6192661b8956, 9000000 * perToken());
    }
    
    function setNFTAddress(address nftAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_nftAddress == address(0), "Already set");
        _nftAddress = nftAddress;
    }

    function getLastClaim(uint256 tokenId) public view returns (uint256) {
        require(tokenId <= ERC721Enumerable(_nftAddress).totalSupply(), "NFT at index not been minted");
        require(ERC721Enumerable(_nftAddress).ownerOf(tokenId) != address(0), "Owner cannot be 0 address");
        uint256 lastClaimed = uint256(_lastClaim[tokenId]) != 0 ? uint256(_lastClaim[tokenId]) : emissionStart;
        return lastClaimed;
    }

    function getClaimableFromLastOwed(uint256 tokenId) public view returns (uint256) {
        require(getTime() > emissionStart, "Emission has not started yet");
        uint256 lastClaimed = getLastClaim(tokenId);
        require(lastClaimed < emissionEnd, "Claiming finished");
        /** @dev days = delta epoch / day */
        uint256 owed = caclulateOwed(
            /** how many days have gone past since last claimed */
            getDay(emissionStart, lastClaimed),
            /** how many days have gone past since emission start */
            getDay(emissionStart, getTime())
        );
        require(owed != 0, "No claimable smoke");
        return owed * perToken();
    }

    function getDay(uint256 first, uint256 second) public pure returns (uint256) {
        return (second - first) / getInterval(1);
    }

    function claimAll(uint256[] memory tokenIndices) external nonReentrant returns (uint256) {
        uint256 totalClaimQty = 0;
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            // Duplicate token index check
            for (uint256 j = i + 1; j < tokenIndices.length; j++) {
                require(tokenIndices[i] != tokenIndices[j], "Duplicate token index");
            }            
            uint256 tokenIndex = tokenIndices[i];     
            require(ERC721Enumerable(_nftAddress).ownerOf(tokenIndex) == _msgSender(), "Sender is not the owner");
            uint256 claimQty = getClaimableFromLastOwed(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty + claimQty;
                _lastClaim[tokenIndex] = getTime();
            }
        }

        require(totalClaimQty != 0, "No accumulated SMOKE");
        _mint(_msgSender(), totalClaimQty);
        return totalClaimQty;
    }

    function perToken() internal pure virtual returns (uint256) {
        return 1 ether;
    }

    function claim(uint256 tokenId) external nonReentrant returns (uint256){
        require(ERC721Enumerable(_nftAddress).ownerOf(tokenId) == _msgSender(), "Sender is not the owner");
        uint256 owed = getClaimableFromLastOwed(tokenId);          
        _mint(_msgSender(), owed);
        _lastClaim[tokenId] = getTime();
        return owed;
    }

    /**
        @dev 
        to find owed = total owed since start - claimed tokens  
     */
    function caclulateOwed(uint256 lastClaimed, uint256 totalDays) public pure returns (uint256) {
        uint256 accrued = totalDays - lastClaimed;
        if(accrued >= 1800) {
            return totalEmissions(1800) - totalEmissions(lastClaimed);
        }
        return totalEmissions(totalDays) - totalEmissions(lastClaimed);
    }

    function getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function getInterval(uint qty) internal pure virtual returns (uint256) {
        return qty * 1 days;
    }

    /**
        @dev 
        10 Smokes a day for 180 days = 1800 (180 days)
        8 Smokes a day for 180 days = 1440 (360 days)
        6 Smokes a day for 180 days = 1080 (540 days)
        4 Smokes a day for 180 days = 720 (720 days)
        2 Smokes a day for 180 days = 360 (900 days) 

        Total = 5400 smoke per dragon
        5400 * 5000 (no. of NFTs) = 27,000,000

        2 smokes a day for 900 more days
        900 * 2 * 5000 = 9,000,000

        36,000,000 total smokes created
     */
    function totalEmissions(uint256 totalDays) public pure returns (uint256) {
        require(totalDays <= 1800, "Exceeds timeline");
        if(totalDays <= 180) return 10 * (totalDays);
        // 10 * 180 + 8 * (totalDays - 180);
        if(totalDays <= 360) return 1800 + 8 * (totalDays - 180);
        // 10 * 180 + 8 * 180 + 6 * (totalDays - 360);
        if(totalDays <= 540) return 3240 + 6 * (totalDays - 360);
        // 10 * 180 + 8 * 180 + 6 * 180 + 4 * (totalDays - 540);
        if(totalDays <= 720) return 4320 + 4 * (totalDays - 540);
        // 10 * 180 + 8 * 180 + 6 * 180 + 4 * 180 + 2 * (totalDays - 720);
        return 5040 + 2 * (totalDays - 720);
    }
}
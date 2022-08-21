///@author WOK
///@dev This contract controls dripping and minting of TEMPURA.
///@dev Dripping occurs via Yakuza Elite - Gen Yakuza must mint tokens due to lack of transfer hooks or staking.
///@dev S/O to OxBeans for GIGADRIP

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./GIGADRIP.sol";

contract Tempura is Ownable, GIGADRIP20, ReentrancyGuard {
    uint256 public constant BASE_RATE = 2 ether;

    address public yakuzaElite;

    bool public claimAllowed;

    uint256 public startTime;
    uint256 public endTime;

    mapping(uint256 => uint256) public lastClaim;
    mapping(address => uint256) private userIndex;

    address[] public accruers;

    IERC721 public constant YAKUZA_GEN = IERC721(0x0EE1448F200e6e65E9bad7A335E3FFb674c0f68C);

    constructor() GIGADRIP20("Tempura", "TEMPURA", 18, 167000000000000) {
        startTime = block.timestamp + 100 days;
    }

    /*==============================================================
    ==                    Dripping Functions                      ==
    ==============================================================*/

    function startDripping(address addr, uint128 multiplier) external {
        require(
            msg.sender == yakuzaElite || msg.sender == owner(),
            "Dripping can only be modified by Yakuza Elite contract or owner"
        );
        if (_accruers[addr].multiplier == 0) {
            userIndex[addr] = accruers.length;
            accruers.push(addr);
        }
        if (block.timestamp < endTime) _startDripping(addr, multiplier);
    }

    function stopDripping(address addr, uint128 multiplier) external {
        require(
            msg.sender == yakuzaElite || msg.sender == owner(),
            "Dripping can only be modified by Yakuza Elite contract or owner"
        );
        if (block.timestamp < endTime) _stopDripping(addr, multiplier);
        if (_accruers[addr].multiplier == 0) {
            accruers[userIndex[addr]] = accruers[accruers.length - 1];
            accruers.pop();
        }
    }

    function burn(address from, uint256 value) external {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - value;

        _burn(from, value);
    }

    /*==============================================================
    ==                    Gen Yield Functions                     ==
    ==============================================================*/

    function claimReward(uint256 _tokenId) external nonReentrant {
        require(claimAllowed, "Claiming is not live.");
        require(
            YAKUZA_GEN.ownerOf(_tokenId) == msg.sender,
            "Caller does not own the token being claimed for."
        );
        uint256 unclaimedReward = computeUnclaimedReward(_tokenId);
        lastClaim[_tokenId] = block.timestamp;
        _mint(msg.sender, unclaimedReward);
    }

    function claimRewards(uint256[] calldata _tokenIds) external nonReentrant {
        require(claimAllowed, "Claiming is not live.");
        uint256 totalUnclaimedRewards = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(
                YAKUZA_GEN.ownerOf(_tokenId) == msg.sender,
                "Caller does not own the token being claimed for."
            );
            uint256 unclaimedReward = computeUnclaimedReward(_tokenId);
            totalUnclaimedRewards = totalUnclaimedRewards + unclaimedReward;
            lastClaim[_tokenId] = block.timestamp;
        }
        _mint(msg.sender, totalUnclaimedRewards);
    }

    function getUnclaimedRewardAmount(uint256 _tokenId) public view returns (uint256) {
        uint256 unclaimedReward = computeUnclaimedReward(_tokenId);
        return unclaimedReward;
    }

    function getUnclaimedRewardsAmount(uint256[] calldata _tokenIds)
        public
        view
        returns (uint256)
    {
        uint256 totalUnclaimedRewards = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedReward(_tokenIds[i]);
        }
        return totalUnclaimedRewards;
    }

    function getLastClaimedTime(uint256 _tokenId) public view returns (uint256) {
        return lastClaim[_tokenId];
    }

    function computeAccumulatedReward(
        uint256 _lastClaimDate,
        uint256 _baseRate,
        uint256 currentTime
    ) internal pure returns (uint256) {
        require(
            currentTime > _lastClaimDate,
            "Last claim date must be smaller than block timestamp"
        );

        uint256 secondsElapsed = currentTime - _lastClaimDate;
        uint256 accumulatedReward = (secondsElapsed * _baseRate) / 1 days;

        return accumulatedReward;
    }

    function computeUnclaimedReward(uint256 _tokenId) internal view returns (uint256) {
        YAKUZA_GEN.ownerOf(_tokenId);

        uint256 lastClaimDate = lastClaim[_tokenId];

        if (lastClaimDate != uint256(0)) {
            return computeAccumulatedReward(lastClaimDate, BASE_RATE, block.timestamp);
        } else if (block.timestamp < endTime) {
            uint256 totalReward = computeAccumulatedReward(startTime, BASE_RATE, block.timestamp);
            return totalReward;
        } else {
            uint256 totalReward = computeAccumulatedReward(lastClaimDate, BASE_RATE, endTime);
            return totalReward;
        }
    }

    /*==============================================================
    ==                    Only Owner Functions                    ==
    ==============================================================*/

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function setYakuzaElite(address yakuzaEliteAddress) external onlyOwner {
        yakuzaElite = yakuzaEliteAddress;
    }

    function startYield() external onlyOwner {
        startTime = block.timestamp;
        endTime = block.timestamp + 730 days;
    }

    function stopAllDrips() external onlyOwner {
        require(block.timestamp > endTime, "Cannot stop the drip yet.");
        for (uint256 i; i < accruers.length; i++) {
            address _addr = accruers[i];
            _stopDripping(_addr, _accruers[_addr].multiplier);
        }
    }

    function toggleClaim() external onlyOwner {
        claimAllowed = !claimAllowed;
    }
}
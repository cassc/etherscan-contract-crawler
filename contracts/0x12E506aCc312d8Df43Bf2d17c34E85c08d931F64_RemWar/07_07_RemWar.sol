// SPDX-License-Identifier: MIT
// RemWar Contracts v0.2

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IRem64.sol";

// Game Ownership
error TestModeOff();

// Rem alive status
error RemDead();

// Friendly Fire
error NoFriendlyFire();

// Shot Price Checker
error InvalidShotPrice();
error PaidTooMuch();

// War not started
error WarNotStarted();
error WarStarted();
error WarOver();

contract RemWar is Ownable, ReentrancyGuard {

    // Initialization and constructor
    IRem64 Rem64;
    using SafeMath for uint256;

    constructor(address rem64Address) {
        Rem64 = IRem64(rem64Address);
    }

    /// -------------------------------------
    /// ❌ Test Mode is just for automated
    ///    testing.
    /// -------------------------------------

    bool testModeOff = false;

    modifier notTestMode() {
        if (testModeOff == true) {
            revert TestModeOff();
        }
        _;
    }

    // One way function, rip 🪦
    function disableTestMode() public onlyOwner {
        testModeOff = true;
    }

    /// -------------------------------------
    /// 😵 Alive Or Dead
    /// -------------------------------------

    //ToDo: figure out what default value is and name accordingly;
    mapping(uint256 => bool) public remDead;

    function getRemDead(uint256 tokenId) public view returns (bool) {
        return remDead[tokenId];
    }

    // Owner override for killing Rem64, used for testing.
    function killRem(uint256 tokenId) public onlyOwner notTestMode {
        remDead[tokenId] = true;
    }

    // Function to kill Rem64 fr fr
    function killRemFr(uint256 tokenId) private {
        remDead[tokenId] = true;
    }

    /// -------------------------------------
    /// 💰 Bounties
    /// -------------------------------------

    // Token Bounty
    mapping(uint256 => uint256) public remBounty;

    function getRemBounty(uint256 tokenId) public view returns (uint256) {
        return remBounty[tokenId];
    }

    // Faction Bounty
    uint256[] public factionBounty = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    function getFactionBounty(uint256 index) public view returns (uint256) {
        return factionBounty[index];
    }

    // Owner override for checking RemBounty, used for testing.
    function changeRemBounty(uint256 tokenId, uint256 bounty)
        public
        onlyOwner
        notTestMode
    {
        remBounty[tokenId] = bounty;
    }

    /// -------------------------------------
    /// 🔫 Shooting
    /// -------------------------------------

    event Shot(uint256 shotta, uint256 target, uint256 amount);

    event Killed(uint256 shotta, uint256 target);

    // REMI64 KILL COUNT VANITY METRIC
    mapping(uint256 => uint256) public killCount;

    // MODIFIERS FOR SHOOTING
    modifier checkAlive(uint256 tokenId) {
        if (remDead[tokenId] == true) {
            revert RemDead();
        }
        _;
    }

    modifier minShotPrice(uint256 shotPrice) {
        if (shotPrice < 0.001 ether) {
            revert InvalidShotPrice();
        }
        _;
    }

    // Check to make sure caller owns the shooter to claim
    modifier shooterIsOwned(uint256 tokenId, address sender) {
        if (Rem64.ownerOf(tokenId) != sender) {
            revert("not owner of");
        }
        _;
    }

    modifier checkFriendlyFire(uint256 shotta, uint256 target) {
        if (Rem64.getFaction(shotta) == Rem64.getFaction(target)) {
            revert NoFriendlyFire();
        }
        _;
    }

    // Helper functions to add/subtract from Rem64 and
    // associated faction.
    function addToBounty(uint256 tokenId, uint256 bounty) private {
        remBounty[tokenId] += bounty;
        factionBounty[Rem64.getFaction(tokenId)] += bounty;
    }

    function subFromBounty(uint256 tokenId, uint256 bounty) private {
        remBounty[tokenId] -= bounty;
        factionBounty[Rem64.getFaction(tokenId)] -= bounty;
    }

    // Helper function to add shooter to has shot list
    // and increment faction shooter counter
    mapping(uint256 => bool) public hasShot;

    uint256[] factionShooterCount = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    function shottaAdd(uint256 tokenId) private {
        hasShot[tokenId] = true;
        factionShooterCount[Rem64.getFaction(tokenId)] += 1;
    }

    // REAL KILLAS 💧🩸 call this function
    function shootRem(uint256 shotta, uint256 target)
        public
        payable
        warOn
        warNotOver
        checkAlive(shotta)
        checkAlive(target)
        shooterIsOwned(shotta, msg.sender)
        checkFriendlyFire(shotta, target)
        minShotPrice(msg.value)
    {
        uint256 shotPrice = msg.value;
        require((shotPrice % 0.001 ether) == 0, "NOT A MULTIPLE OF MIN SHOT");
        
        //Split payment
        FINAL_BOUNTY += Math.mulDiv(shotPrice, 57, 100);
        SHOOTER_BOUNTY += Math.mulDiv(shotPrice, 10, 100);
        DEV_TOTAL += Math.mulDiv(shotPrice, 33, 100);

        // Initial check to see if rem
        // is instantly killed.
        if (remBounty[target] == 0) {
            killRemFr(target);
            addToBounty(shotta, shotPrice);
            killCount[shotta] += 1;
            shottaAdd(shotta);
            emit Killed(shotta, target);
            return;
        } else {
            // Branch that deals with real
            // killa logic.

            // Check to make sure you aren't
            // shooting more than the bounty
            // you can collect. This is good
            // guy 👮 code in case someone
            // snipes your target, or you
            // miscalculate.
            if (remBounty[target] < shotPrice) {
                revert PaidTooMuch();
            }

            // He's clapped 👏 but still moving.
            if (remBounty[target] > shotPrice) {
                uint256 damage = Math.mulDiv(shotPrice, shotPrice, remBounty[target]);
                addToBounty(shotta, shotPrice + damage);
                subFromBounty(target, damage);
                shottaAdd(shotta);
                emit Shot(shotta, target, shotPrice);
                return;
            }

            // Headshot 🎯
            if (remBounty[target] == shotPrice) {
                subFromBounty(target, shotPrice);
                addToBounty(shotta, shotPrice * 2);
                killRemFr(target);
                killCount[shotta] += 1;
                shottaAdd(shotta);
                emit Killed(shotta, target);
                return;
            }
        }
    }

    /// -------------------------------------
    /// 💣 WAR DECLARED
    /// -------------------------------------

    bool war = false;
    uint256 startDate;
    uint256 endDate;

    function getWarStatus() view public returns (bool) {
        return war;
    }

    modifier warOn() {
        if (war == false) {
            revert WarNotStarted();
        }
        _;
    }

    modifier warNotOver() {
        if (war == true && block.timestamp > endDate) {
            revert WarOver();
        }
        _;
    }

    modifier warOff() {
        if (war == true) {
            revert WarStarted();
        }
        _;
    }

    modifier warNeverStarted() {
        if (endDate != 0) {
            revert WarStarted();
        }
        _;
    }

    function startWar(uint256 endingDate)
        public
        onlyOwner
        warOff
        warNeverStarted
    {
        startDate = block.timestamp;
        endDate = endingDate;
        war = true;
    }

    /// -------------------------------------
    /// 💣 WAR ENDED
    /// -------------------------------------

    // Variables to hold the paid totals for withdrawal;
    uint256 public FINAL_BOUNTY;
    uint256 public SHOOTER_BOUNTY;
    uint256 public DEV_TOTAL;

    // PUBLIC function anyone can call to end the
    // war. BUT it has to be called after the
    // official end date, and only if the war
    // is still on going. Consider this a
    // public service should dev team be unable
    // to call off the war.
    function endWarOfficially() public warOn {
        if (war == true && block.timestamp > endDate) {
            war = false;
            determineWinningFaction();
        }
    }

    uint256 public winningFactionCount = 0;

    function getWinningFactionCount() view public returns (uint256) {
        return winningFactionCount;
    }

    function determineWinningFaction() private {
        uint256 largest = 0; 
        uint256 i;

        for(i = 0; i < factionBounty.length; i++){
            if(factionBounty[i] > largest) {
                largest = factionBounty[i]; 
            } 
        }

        for(i = 0; i < factionBounty.length; i++){
            if(factionBounty[i] == largest) {
                winningFactionCount += 1;
            } 
        }

        FINAL_BOUNTY = Math.mulDiv(FINAL_BOUNTY, 1, winningFactionCount);
        SHOOTER_BOUNTY = Math.mulDiv(SHOOTER_BOUNTY, 1, winningFactionCount);
    }


    // WITHDRAW FOR DEV - 33%
    function withdrawDevWarProceeds() external onlyOwner warOff {
        require(address(this).balance > 0, "Nothing to release");
        require(DEV_TOTAL > 0, "Already Claimed");
        (bool success, ) = payable(owner()).call{value: DEV_TOTAL}("");
        DEV_TOTAL = 0;
        require(success, "withdraw failed");
    }

    // Modifier to ensure token's faction
    // won for a claim.
    modifier tokenWon(uint256 tokenId) {
        uint256 faction = Rem64.getFaction(tokenId);
        uint256 factionAmount = factionBounty[faction];

        for (uint256 i = 0; i < factionBounty.length; i++) {
            if (factionBounty[i] > factionAmount) {
                revert("Faction didn't win");
            }
        }
        _;
    }

    // modifier for SHOOTER CLAIM - 10%
    mapping(uint256 => bool) public shooterClaimed;

    // Claim 10% for having fired a shot and being on the
    // the winning faction

    function shooterClaim(uint256 tokenId)
        public
        warOff
        tokenWon(tokenId)
        shooterIsOwned(tokenId, msg.sender)
        nonReentrant
    {
        require(hasShot[tokenId] == true, "Shooter never shot");
        require(shooterClaimed[tokenId] != true, "Already Claimed");

        uint256 numberOfShooters = factionShooterCount[Rem64.getFaction(tokenId)];
        uint256 withdrawAmount = Math.mulDiv(SHOOTER_BOUNTY, 1, numberOfShooters);

        (bool success, ) = payable(address(msg.sender)).call{
            value: withdrawAmount
        }("");

        shooterClaimed[tokenId] = true;
        require(success, "withdraw failed");
    }

    // modifier for SOLDIER CLAIM
    // FINAL BOUNTY * (FACTION BOUNTY/TOKEN BOUTNY)
    mapping(uint256 => bool) public soldierClaimed;

    modifier soldierClaimedCheck(uint256 tokenId) {
        if (soldierClaimed[tokenId] == true) {
            revert("Soldier already claimed");
        }
        _;
    }

    // Claim the full bounty the shooter has accumulated
    // throughout play

    function getPotentialWinnings(uint256 tokenId) view public returns (uint256){
        uint256 faction = Rem64.getFaction(tokenId);
        uint256 facBounty = factionBounty[faction];
        return Math.mulDiv(FINAL_BOUNTY, remBounty[tokenId],facBounty);
    }

    function soldierClaim(uint256 tokenId)
        public
        warOff
        tokenWon(tokenId)
        checkAlive(tokenId)
        soldierClaimedCheck(tokenId)
        shooterIsOwned(tokenId, msg.sender)
        nonReentrant
    {
        require(address(this).balance > 0, "Nothing to release");

        uint256 faction = Rem64.getFaction(tokenId);

        uint256 facBounty = factionBounty[faction];

        uint256 withdrawAmount = Math.mulDiv(FINAL_BOUNTY, remBounty[tokenId],facBounty);

        (bool success, ) = payable(address(msg.sender)).call{
            value: withdrawAmount
        }("");

        soldierClaimed[tokenId] = true;

        require(success, "withdraw failed");
    }
}
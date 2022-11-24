// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVault {
    struct Participant {
        uint256 startTime;
        uint256 balance;
        address referrer;
        uint256 deposited;
        uint256 compounded;
        uint256 claimed;
        uint256 taxed;
        uint256 awarded;
        bool negative;
        bool penalized;
        bool maxed;
        bool banned;
        bool teamWallet;
        bool complete;
        uint256 maxedRate;
        uint256 availableRewards;
        uint256 lastRewardUpdate;
        uint256 directReferrals;
        uint256 airdropSent;
        uint256 airdropReceived;
    }
    function addressBook (  ) external view returns ( address );
    function airdrop ( address to_, uint256 amount_ ) external returns ( bool );
    function availableRewards ( address participant_ ) external view returns ( uint256 );
    function claim (  ) external returns ( bool );
    function claimPrecheck ( address participant_ ) external view returns ( uint256 );
    function compound (  ) external returns ( bool );
    function autoCompound( address participant_ ) external returns ( bool );
    function deposit ( uint256 quantity_, address referrer_ ) external returns ( bool );
    function deposit ( uint256 quantity_ ) external returns ( bool );
    function depositFor ( address participant_, uint256 quantity_ ) external returns ( bool );
    function depositFor ( address participant_, uint256 quantity_, address referrer_ ) external returns ( bool );
    function getParticipant ( address participant_ ) external returns ( Participant memory );
    function initialize (  ) external;
    function maxPayout ( address participant_ ) external view returns ( uint256 );
    function maxThreshold (  ) external view returns ( uint256 );
    function owner (  ) external view returns ( address );
    function participantBalance ( address participant_ ) external view returns ( uint256 );
    function participantMaxed ( address participant_ ) external view returns ( bool );
    function participantStatus ( address participant_ ) external view returns ( uint256 );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function remainingPayout ( address participant_ ) external view returns ( uint256 );
    function renounceOwnership (  ) external;
    function rewardRate ( address participant_ ) external view returns ( uint256 );
    function setAddressBook ( address address_ ) external;
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function updateLookbackPeriods ( uint256 lookbackPeriods_ ) external;
    function updateMaxPayout ( uint256 maxPayout_ ) external;
    function updateMaxReturn ( uint256 maxReturn_ ) external;
    function updateNegativeClaims ( uint256 negativeClaims_ ) external;
    function updateNeutralClaims ( uint256 neutralClaims_ ) external;
    function updatePenaltyClaims ( uint256 penaltyClaims_ ) external;
    function updatePenaltyLookbackPeriods ( uint256 penaltyLookbackPeriods_ ) external;
    function updatePeriod ( uint256 period_ ) external;
    function updateRate ( uint256 claims_, uint256 rate_ ) external;
    function updateReferrer ( address referrer_ ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}
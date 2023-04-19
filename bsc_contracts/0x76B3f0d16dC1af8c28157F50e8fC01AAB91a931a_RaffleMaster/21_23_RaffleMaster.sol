// SPDX-License-Identifier: MIT
//    _   _   _   _   _   _   _   _     _   _   _   _   _   _   _
//   / \ / \ / \ / \ / \ / \ / \ / \   / \ / \ / \ / \ / \ / \ / \
//  ( S | i | d | e | K | i | c | k ) ( F | i | n | a | n | c | e )
//   \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ \_/
//    _   _   _   _     _   _   _   _   _   _   _   _   _   _     _   _   _     _   _   _   _   _   _   _   _   _   _   _
//   / \ / \ / \ / \   / \ / \ / \ / \ / \ / \ / \ / \ / \ / \   / \ / \ / \   / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \
//  ( W | e | b | 3 ) ( C | o | n | s | u | l | t | i | n | g ) ( a | n | d ) ( D | e | v | e | l | o | p | m | e | n | t )
//   \_/ \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/   \_/ \_/ \_/   \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import string openzep
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
// import non re-entrant
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./IDripRaffleNFT.sol";
import "./VRFConsumerBaseV2Upgradeable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./IFountain.sol";
import "./IFaucet.sol";
import "./IPancakeRouter02.sol";
import "./IPancakeFactory.sol";

contract RaffleMaster is
    Initializable,
    VRFConsumerBaseV2Upgradeable,
    OwnableUpgradeable,
    ERC1155Upgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
        uint256 level;
        uint256 raffleId;
    }

    struct Level {
        uint256 level;
        uint256 buyIn;
        uint256 currentMint;
        uint256 currentRaffle;
    }
    mapping(uint256 => Level) public levels;

    // map level -> raffle -> entrants
    mapping(uint256 => mapping(uint256 => address[])) public raffleEntries;
    // mapp level -> address -> entries
    mapping(address => uint256) public entriesByAddress;
    mapping(uint256 => mapping(address => uint256)) public entriesByLevelAddress;
    mapping(uint256 => address[]) public entrantsByLevelArray;
    // map level -> raffle -> winners
    mapping(uint256 => mapping(uint256 => address[])) public raffleWinners;
    // map level -> raffle -> refAddress -> points
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        public referralPoints;
    // map level -> raffle -> totalPoints
    mapping(uint256 => mapping(uint256 => uint256)) totalReferralPoints;
    mapping(address => bool) public isReferrer;
    address[] private referrerArray;

    ///
    mapping(address => uint256) public totalReferralEarnings;
    // map address -> level -> earnings
    mapping(address => mapping(uint256 => uint256))
        public totalReferralEarningsByLevel;
    mapping(address => uint256) public totalUSDCEarnings;
    // map address -> level -> earnings
    mapping(address => mapping(uint256 => uint256))
        public totalUSDCEarningsByLevel;
    mapping(address => uint256) public totalTokenEarnings;
    // map address -> level -> earnings
    mapping(address => mapping(uint256 => uint256))
        public totalTokenEarningsByLevel;

    // total claimed
    mapping(address => uint256) public totalUSDCClaim;
    mapping(address => uint256) public lastClaimTime;

    mapping(uint256 => RequestStatus) public s_requests;
    // map requestId -> level
    mapping(uint256 => uint256) public s_requestLevels;
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;

    string public name;
    string public symbol;
    string private contractUri;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint256 private lastRequestLevel;
    bytes32 keyHash;
    uint32 callbackGasLimit; //20,000 gas per number generated
    uint16 requestConfirmations;
    uint32 numWords; //generate 60 random numbers

    address public paymentToken;

    address[] public team;
    uint256[] teamCuts;

    uint256 public totalSupply;

    IFountain public fountain;
    IFaucet public faucet;
    IPancakeRouter02 router;
    IERC20 public dripToken;

    event Mint(
        address indexed to,
        uint256 indexed mintAmount,
        uint256 indexed level
    );
    event DrawRaffle(
        address from,
        uint256 indexed level,
        uint256 indexed raffleNumber
    );
    event RaffleComplete(
        address[] indexed winners,
        uint256[] indexed winAmounts,
        uint256[] indexed tokenIds
    );
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event WinnersSelected(address[] winners);
    event WinnersPaid(address[] winners);
    event RaffleStarted(uint256 level, uint256 raffleNumber);
    event RaffleEnded(uint256 level, uint256 raffleNumber);
    event RaffleCancelled(uint256 level, uint256 raffleNumber);

    function initialize(
        uint64 _subscriptionId,
        bytes32 _keyhash,
        address _coordinator,
        string memory _uri,
        address _fountain,
        address _faucet,
        IERC20 _dripToken,
        address _router,
        address _paymentToken,
        string memory _name, 
        string memory _symbol,
        string memory _contractUri
    ) public initializer {
        __ERC1155_init(_uri);
        __Ownable_init();
        __VRFConsumer_init(_coordinator);

        name = _name;
        symbol = _symbol;
        contractUri = _contractUri;

        s_subscriptionId = _subscriptionId;
        keyHash = _keyhash;
        COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
        levels[1] = Level(1, 100000000000000000, 0, 1);
        levels[2] = Level(2, 250000000000000000, 0, 1);
        levels[3] = Level(3, 500000000000000000, 0, 1);
        levels[4] = Level(4, 100000000000000000, 0, 1);

        callbackGasLimit = 1000000; //20,000 gas per number generated
        requestConfirmations = 3;
        numWords = 3; // testing with 3 prod = 60 generate 60 random numbers

        totalSupply = 5; // TEST , PROD = 500

        fountain = IFountain(_fountain);
        faucet = IFaucet(_faucet);
        dripToken = _dripToken;
        router = IPancakeRouter02(_router);
        paymentToken = _paymentToken;

        //approve BUSD for pancake router
        IERC20(_paymentToken).approve(address(router), type(uint256).max);
        //approve drip for faucet
        IERC20(_dripToken).approve(address(faucet), type(uint256).max);
    }

    //deposit function with ability to deposit to multiple levels
    function deposit(
        uint256 level,
        uint256 mintAmount,
        address referral
    ) public {
        //check if level is valid
        require(level > 0 && level < 5, "Invalid level");
        // check iFaucet upline is set
        (
            address upline,
            uint256 deposit_time,
            uint256 deposits,
            uint256 payouts,
            uint256 direct_bonus,
            uint256 match_bonus,
            uint256 last_airdrop
        ) = faucet.userInfo(msg.sender);

        require(upline != address(0), "Upline not set");
        require(team.length > 0, "Team not set");
        require(team.length == teamCuts.length, "Team cuts not set");
        require(paymentToken != address(0), "Payment token not set");

        // set Level variable
        Level memory _level = levels[level];

        // check if mintAmount goes over mint threshold
        require(
            mintAmount + _level.currentMint <= totalSupply,
            // combine text with variable
            string(
                abi.encodePacked(
                    "Amount exceeds threshold: ",
                    StringsUpgradeable.toString(totalSupply)
                )
            )
        );

        IERC20(paymentToken).transferFrom(
            msg.sender,
            address(this),
            (_level.buyIn * mintAmount)
        );

        _mint(msg.sender, (level - 1), mintAmount, "");

        entriesByAddress[msg.sender] += mintAmount;
        entriesByLevelAddress[level][msg.sender] += mintAmount;

        if (referral == address(0) || referral == msg.sender) {
            referralPoints[level][_level.currentRaffle][team[0]] += (_level
                .buyIn * mintAmount);
            totalReferralPoints[level][_level.currentRaffle] += (_level.buyIn *
                mintAmount);

            if (isReferrer[team[0]] == false) {
                isReferrer[team[0]] = true;
                referrerArray.push(msg.sender);
            }
        } else {
            referralPoints[level][_level.currentRaffle][msg.sender] += (_level
                .buyIn * mintAmount);
            referralPoints[level][_level.currentRaffle][referral] += (_level
                .buyIn * mintAmount);
            totalReferralPoints[level][_level.currentRaffle] += ((_level.buyIn *
                mintAmount) + (_level.buyIn * mintAmount));

            if (isReferrer[msg.sender] == false) {
                isReferrer[msg.sender] = true;
                referrerArray.push(msg.sender);
            }
        }

        if (entriesByLevelAddress[level][msg.sender] <= 0) {
            entrantsByLevelArray[level].push(msg.sender);
        }

        for (uint256 i = 0; i < mintAmount; i++) {
            levels[level].currentMint++;
            //track entries by level -> currentRaffle -> address
            raffleEntries[level][levels[level].currentRaffle].push(msg.sender);
        }

        emit Mint(msg.sender, mintAmount, level);
    }

    // draw raffle
    function drawRaffle(uint256 level) public {
        // check each level if totalSupply is reached
        require(level > 0 && level < 5, "Invalid level");
        require(
            levels[level].currentMint == totalSupply,
            "Mint threshold not reached"
        );

        if (lastRequestId > 0) {
            require(
                s_requests[lastRequestId].fulfilled,
                "Previous drawing not complete"
            );
            require(s_requests[lastRequestId].level == level, "Invalid level");
        }

        Level memory _level = levels[level];

        if (_level.currentMint % totalSupply == 0) {
            //request random numbers from chainlink
            requestRandomWords(level);
            lastRequestLevel = level;
        }

        emit DrawRaffle(msg.sender, level, _level.currentRaffle);
    }

    function payoutMarketingAndReferrals(uint256 level) internal {
        // team cuts and length =
        require(team.length == teamCuts.length, "Invalid team");

        // payout referrals 3% of collection
        // referralEarnings = 3% of collection
        uint256 referralEarnings = ((levels[level].buyIn * totalSupply) *
            3) / 100; //(.03%)

        for(uint256 i = 0; i < referrerArray.length; i++) {
            address referrer = referrerArray[i];
            uint256 referrerPoints = referralPoints[level][levels[level].currentRaffle][referrer];
            uint256 referrerCut = (referralEarnings * referrerPoints) / totalReferralPoints[level][levels[level].currentRaffle];
            totalUSDCEarnings[referrer] += referrerCut;
        }

        //teamEarnings = 20% of collectionnTotals[level]
        uint256 teamEarnings = ((levels[level].buyIn * totalSupply) * 155) /
            500; //(.31%)

        for (uint256 i = 0; i < team.length; i++) {
            totalUSDCEarnings[team[i]] += (teamEarnings * teamCuts[i]) / 100;
        }
    }

    function payoutWinners(uint256 level) public {
        require(level > 0 && level < 5, "Invalid level");
        require(
            levels[level].currentMint == totalSupply,
            "Mint threshold not reached"
        );

        require(
            s_requests[lastRequestId].fulfilled,
            "Previous drawing not complete"
        );

        require(s_requests[lastRequestId].level == level, "Invalid level");

        Level memory _level = levels[level];
        uint256 raffleId = _level.currentRaffle;
        uint256[] memory _randomWords = s_requests[lastRequestId].randomWords;

        for (uint256 i = 0; i < _randomWords.length; i++) {
            uint256 winnerIndex = (_randomWords[i] % totalSupply) + 1;
            //select winner using random number and rafle entry
            address winner = raffleEntries[lastRequestLevel][
                _level.currentRaffle
            ][winnerIndex];
            //push to raffleWinners mapping
            raffleWinners[level][raffleId].push(winner);
        }

        uint256 totalCollected = _level.buyIn * totalSupply;

        // call swapToDrip with 66% of totalCollected
        if (level < 4) {
            uint256 dripBought = swapToDrip((totalCollected * 66) / 100);
            airdropWinnings(dripBought, _level.currentRaffle, level);
        } else {
            airdropUsdcWinnings(
                (totalCollected * 66) / 100,
                _level.currentRaffle,
                level
            );
        }

        levels[level].currentRaffle++;
        levels[level].currentMint = 0;

        //pay out marketing and team
        payoutMarketingAndReferrals(level);
        recycleEntries(level);

        //emit winners paid
        emit WinnersPaid(raffleWinners[level][raffleId]);
    }

    function requestRandomWords(
        uint256 level
    ) internal returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            level: level,
            raffleId: levels[level].currentRaffle
        });

        requestIds.push(requestId);
        lastRequestId = requestId;

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        require(!s_requests[_requestId].fulfilled, "request already fulfilled");

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) public view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function swapToDrip(uint256 _amount) internal returns (uint256) {
        //swap busd to bnb
        address[] memory path = new address[](2);
        path[0] = paymentToken;
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        ///get bnb balance
        uint256 bnbBalance = address(this).balance;
        //check drip price
        uint256 dripPrice = fountain.getBnbToTokenInputPrice(bnbBalance);
        //slippage = 5%
        uint256 min_tokens = (dripPrice * 95) / 100;
        uint256 dripBought = fountain.bnbToTokenSwapInput{value: bnbBalance}(
            min_tokens
        );
        return dripBought;
    }

    // write function airdropUsdcWinnings
    function airdropUsdcWinnings(
        uint256 _usdc,
        uint256 _raffleId,
        uint256 _level
    ) internal {
        // airdrop IERC20(paymentToken).transfer to raffleWinners[_level][_raffleId]
        uint256 totalWinners = raffleWinners[_level][_raffleId].length;

        uint256 bottom = 40;
        uint256 middle = 5;

        // Calculate percentage allocations
        uint256 firstFiftyShare = (_usdc * 8) / 33; // .2424242424%
        uint256 nextFiveShare = (_usdc * 5) / 33; // .1515151515%
        uint256[] memory shares = new uint256[](5);
        shares[0] = (_usdc * 1) / 33; // .0303030303%
        shares[1] = (_usdc * 2) / 33; // .0606060606%
        shares[2] = (_usdc * 3) / 33; // .0909090909%
        shares[3] = (_usdc * 4) / 33; // .1212121212%
        shares[4] = (_usdc * 10) / 33; // .3030303030%

        // Distribute winnings
        for (uint256 i = 0; i < totalWinners; i++) {
            address winner = raffleWinners[_level][_raffleId][i];
            if (i < bottom) {
                totalUSDCEarnings[winner] += firstFiftyShare / bottom;
            } else if (i < (bottom + middle)) {
                totalUSDCEarnings[winner] += nextFiveShare / middle;
            } else {
                totalUSDCEarnings[winner] += shares[
                    (i - (bottom + middle)) - 1
                ];
            }
        }
    }

    function airdropWinnings(
        uint256 _drip,
        uint256 _raffleId,
        uint256 _level
    ) internal {
        uint256 totalWinners = raffleWinners[_level][_raffleId].length;

        uint256 bottom = 40;
        uint256 middle = 5;

        // Calculate percentage allocations
        uint256 firstFiftyShare = (_drip * 8) / 33; // .2424242424%
        uint256 nextFiveShare = (_drip * 5) / 33; // .1515151515%
        uint256[] memory shares = new uint256[](5);
        shares[0] = (_drip * 1) / 33; // .0303030303%
        shares[1] = (_drip * 2) / 33; // .0606060606%
        shares[2] = (_drip * 3) / 33; // .0909090909%
        shares[3] = (_drip * 4) / 33; // .1212121212%
        shares[4] = (_drip * 10) / 33; // .3030303030%

        // Distribute winnings
        for (uint256 i = 0; i < totalWinners; i++) {
            address winner = raffleWinners[_level][_raffleId][i];
            if (i < bottom) {
                faucet.airdrop(winner, firstFiftyShare / bottom);
            } else if (i < (bottom + middle)) {
                faucet.airdrop(winner, nextFiveShare / middle);
            } else {
                // top winners
                faucet.airdrop(winner, shares[(i - (bottom + middle)) - 1]);
            }
        }
    }

    function recycleEntries(uint256 _level) internal {
        // Recycle entries
        for (uint256 i = 0; i < entrantsByLevelArray[_level].length; i++) {
            uint256 entriesForLevel = entriesByLevelAddress[_level][
                entrantsByLevelArray[_level][i]
            ];

            if (entriesForLevel >= 10) {
                // Reduce entries by a factor of 10, rounding down any decimals
                entriesByLevelAddress[_level][entrantsByLevelArray[_level][i]] =
                    entriesForLevel /
                    10;
            } else {
                // Set entries to 0 if less than 10
                entriesByLevelAddress[_level][
                    entrantsByLevelArray[_level][i]
                ] = 0;
            }
        }
    }

    function claimEarnings() public {
        require(totalUSDCEarnings[msg.sender] > 0, "No earnings to claim");

        uint256 earnings = totalUSDCEarnings[msg.sender];

        uint256 unpaid = earnings - totalUSDCClaim[msg.sender];

        require(unpaid > 0, "No earnings to claim");

        lastClaimTime[msg.sender] = block.timestamp;
        totalUSDCClaim[msg.sender] += unpaid;

        IERC20(paymentToken).transfer(msg.sender, unpaid);
    }

    function updateTeam(
        address[] memory _team,
        uint256[] memory _teamCuts
    ) public onlyOwner {
        // make sure set marketing wallet in this array
        require(
            _team.length == _teamCuts.length,
            "Team and cuts must be same length"
        );

        // require team cuts add up to 100
        uint256 totalCuts = 0;
        for (uint256 i = 0; i < _teamCuts.length; i++) {
            totalCuts += _teamCuts[i];
        }
        require(totalCuts == 100, "Team cuts must add up to 100");

        team = _team;
        teamCuts = _teamCuts;
    }

    function updateGasLimit(uint32 _callbackGasLimit) public onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function updatePaymentToken(address _paymentToken) public onlyOwner {
        paymentToken = _paymentToken;
        //call approval
        IERC20(paymentToken).approve(address(router), type(uint256).max);
    }

    function updateLevelPrice(uint256 _level, uint256 _price) public onlyOwner {
        levels[_level].buyIn = _price;
    }

    function updateKeyHash(bytes32 _keyHash) public onlyOwner {
        keyHash = _keyHash;
    }

    function updateSubscriptionId(uint64 _subscriptionId) public onlyOwner {
        s_subscriptionId = _subscriptionId;
    }

    function updateLastRequestId(uint256 _lastRequestId) public onlyOwner {
        lastRequestId = _lastRequestId;
    }

    function getTeam() public view returns (address[] memory) {
        return team;
    }

    function recoverTokens(address _token) public onlyOwner {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        contractUri = _uri;
    }

    // required for swaps
    receive() external payable {}

    fallback() external payable {}
}
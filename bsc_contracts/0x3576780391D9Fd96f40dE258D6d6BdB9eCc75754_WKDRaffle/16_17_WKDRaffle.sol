// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {WKDVRFManager} from "./WKDVRFManager.sol";
import {IWKDRaffle} from "./interfaces/IWKDRaffle.sol";
import {IWKDNFT} from "./interfaces/IWKDNFT.sol";
import {IRouter, IFactory} from "./interfaces/utils.sol";

error Winners_Too_Few();
error Too_Many_Winners();
error Cannot_Process_At_This_Time();
error Exceeds_Allowable();
error Insufficient_Payment();
error Refund_Failed();
error Transfer_Failed();
error Invalid_Address_Detected();
error Nothing_To_Claim();
error Too_Early();
error Invalid_Pair();
error Price_Too_Low();
error Amount_Too_High();
error Same_As_Before();
error Withdraw_Pending_Claim();
error Inaccurate_Raffle_State(uint256 expected, uint256 actual);
error Used_RequestId();
error VRF_Funding_Failed();

contract WKDRaffle is AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter public cycleCounter;
    IWKDNFT public immutable _wkdNFT;
    WKDVRFManager public wkdVRFManager;

    event ClaimReferralBonus(address ref, uint256 amount);
    event ClaimWinPrize(address account, uint256 amount, uint256 tokensBurnt);
    event StartCycle(uint256 cycleId, uint256 price, uint256 winsPer20);
    event JoinedCycle(uint256 cycleId, address account, uint256 entryId);
    event DAOChanged(address from, address to);
    event PlatformChanged(address from, address to);
    event TopCadreChanged(address from, address to);
    event DrawResult(
        uint256 cycleId,
        uint256 currentDraw,
        uint256 targetDrawCount,
        uint256 currentWiners,
        uint256 subId,
        uint256 requestId
    );
    event PostDrawCall(uint256 cycleId, uint256 entries, uint256 winners);
    event BuyBackAndBurn(address router, uint256 bnbAmount, uint256 wkdAmount);
    event ReadyForDraws(
        uint256 cycleId,
        uint256 entries,
        uint256 prize,
        uint256 daoRake,
        uint256 buyBackRake
    );
    event VRFManagerUpdated(address wkdVrfManager, uint64 subscriptionId);
    event OperationFailedWithString(string reasonString);
    event OperationFailedWithData(bytes reasonData);

    address private _dao;
    address private _platform;
    address private _topCadre;

    address public immutable WKD;
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    uint256 private constant MIN_WINS_PER_20 = 3;
    uint256 private constant MAX_WINS_PER_20 = 5;
    uint256 private constant MAX_SIZE = 2000;
    uint256 private constant MAX_MINT = 200;
    uint256 private constant SAMPLE_SIZE = 20;
    bytes32 public constant RAFFLE_MANAGER = keccak256("RAFFLE_MANAGER");
    bytes32 public constant ADMIN = keccak256("ADMIN"); // multisig2
    uint256 public constant WINNERS_PCT = 50;
    uint256 public constant REF_PCT = 5;
    uint256 private constant VRF_FUNDING_AMOUNT = 0.2 ether;
    uint256 public constant TOP_RANK_PCT = 3;
    uint256 public constant DAO_PCT = 12;
    uint256 public constant BUY_BACK_PCT = 15;
    uint256 public constant PLATFORM_PCT = 15;

    uint256 private _topCadreFund;
    uint256 private _buybackAndBurnFund;
    uint256 private _referralFund;
    uint256 private _platformFund;
    uint256 private _daoFund;
    uint256 public lastBurnAt;
    uint256 public lastRequestId;
    uint256 public lastRequestMadeAt;
    uint64 public subscriptionId;

    mapping(address => address) private _referrals;
    mapping(address => address[]) private _myRefs;
    mapping(address => uint256) private _winnersRake;
    // referral bonus tracker
    mapping(address => uint256) private _refRake;
    mapping(uint256 => Cycle) private _cycles;
    mapping(uint256 => Draw) private _draws;
    // guaranty unique indexes are selected during draws
    mapping(uint256 => mapping(uint256 => bool)) private _drawnIndexForCycle;
    mapping(uint256 => address[]) private _entries;
    mapping(address => bool) private _existing;
    mapping(uint256 => bool) public usedReqIds;
    // tracks number of mints per cycle for each account
    mapping(uint256 => mapping(address => uint256)) private _mints;
    // tracks a winners pending winning cycle
    mapping(address => Win) private _cycleOfPendingRewardFor;

    struct Win {
        bool exists;
        uint256 cycle;
    }
    enum Status {
        CLOSED,
        OPEN,
        DRAWING_WINNERS,
        POST_DRAW
    }
    struct Cycle {
        uint256 price;
        uint256 openedAt;
        uint256 expectedWins;
        uint256 possibleWinsBasedOnEntry;
        uint256 prize;
        uint256 rakePerRef;
    }
    struct Draw {
        uint256 current;
        uint256 target;
        uint256[] winners;
    }

    Status private _status;

    // multisig1
    constructor(
        address multisig,
        address wkdNFT,
        address payable wkdVrfManager,
        address wkdAddress,
        uint64 subId
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, multisig);
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(RAFFLE_MANAGER, DEFAULT_ADMIN_ROLE);
        _wkdNFT = IWKDNFT(wkdNFT);
        wkdVRFManager = WKDVRFManager(wkdVrfManager);
        WKD = wkdAddress;
        subscriptionId = subId;
    }

    /// @notice show the current state of the contract circuit
    function status() external view returns (uint256) {
        return uint256(_status);
    }

    /// @notice validation of inputs when creating a new cycle
    function _preStartCheck(uint256 winsPer20) internal view {
        if (winsPer20 < MIN_WINS_PER_20) revert Winners_Too_Few();
        if (winsPer20 > MAX_WINS_PER_20) revert Too_Many_Winners();
        if (_status != Status.CLOSED)
            revert Inaccurate_Raffle_State({
                expected: uint256(Status.CLOSED),
                actual: uint256(_status)
            });
    }

    /// @notice to create a new cycle
    /// @dev contract must be in a CLOSED state, winsPer20 must be from 3 to 5
    function startCycle(
        uint256 price,
        uint256 winsPer20
    ) external onlyRole(RAFFLE_MANAGER) {
        if (price == 0) revert Price_Too_Low();
        _preStartCheck(winsPer20);
        cycleCounter.increment();
        uint256 cycleId = cycleCounter.current();
        _cycles[cycleId].price = price;
        _cycles[cycleId].expectedWins = 100 * winsPer20;
        _cycles[cycleId].openedAt = block.timestamp;
        _status = Status.OPEN;
        emit StartCycle(cycleId, price, winsPer20);
    }

    /// @notice gets the information about a cycle given its id
    function showCycle(uint256 cycleId) external view returns (Cycle memory) {
        return _cycles[cycleId];
    }

    /// @notice lets an account join the current cycle
    /// @dev for easy tracking of pending wins, it is important
    /// for accounts to claim their pending wins before joining again
    /// this can be resolved easily from the client but added check
    /// is provided in case user connects through other interfaces
    /// @param account address of the beneficiary of the minted token
    /// @param referral address of the referee
    /// @param amount number of tokens to be minted, multiples of of the price of minting 1 token in this cycle
    function join(
        address account,
        address referral,
        uint256 amount
    ) external payable nonReentrant {
        (uint256 totalPendingAmount, ) = unclaimedBNB(account);
        if (totalPendingAmount != 0) revert Withdraw_Pending_Claim();
        uint256 cycleId = cycleCounter.current();
        Cycle memory cycle = _cycles[cycleId];
        if (_status != Status.OPEN)
            revert Inaccurate_Raffle_State({
                expected: uint256(Status.OPEN),
                actual: uint256(_status)
            });
        uint256 _value = msg.value;
        (uint256 mintableQty, uint256 refund) = _checkMintableFor(
            account,
            amount,
            _value,
            _entries[cycleId].length,
            cycleId,
            cycle.price
        );
        _joinCycleFor(account, referral, cycleId, mintableQty, refund);
    }

    /// @notice util function to check if an account is not minting more than 10% of the available
    /// @dev when an account is overpaying, this function calculates the refund
    function _checkMintableFor(
        address account,
        uint256 desiredMintAmount,
        uint256 value,
        uint256 entryCount,
        uint256 cycleId,
        uint256 price
    ) internal view returns (uint256 mintableQty, uint256 refund) {
        if (desiredMintAmount > MAX_MINT) revert Amount_Too_High();
        mintableQty = MAX_MINT - _mints[cycleId][account];
        if (mintableQty == 0) revert Exceeds_Allowable();
        if (desiredMintAmount <= mintableQty) {
            mintableQty = desiredMintAmount;
        }
        uint256 possibleTotal = entryCount + mintableQty;
        if (possibleTotal > MAX_SIZE) {
            mintableQty = MAX_SIZE - entryCount;
        }
        uint256 requiredAmount = mintableQty * price;
        if (value < requiredAmount) revert Insufficient_Payment();
        if (value > requiredAmount) {
            refund = value - requiredAmount;
        }
    }

    /// @notice util function to process the minting call
    function _joinCycleFor(
        address account,
        address ref,
        uint256 cycleId,
        uint256 mintableQty,
        uint256 refund
    ) internal {
        _wkdNFT.mint(account, mintableQty);
        if (mintableQty > 0) {
            if (!_existing[account]) {
                _referrals[account] = ref;
                _existing[account] = true;
                _myRefs[ref].push(account);
            }
            for (uint256 i = 0; i < mintableQty; ) {
                // winners are selected based on the index of
                // the entry in the array
                _entries[cycleId].push(account);
                unchecked {
                    i++; // cannot overflow due to loop constraint
                }
            }
            _mints[cycleId][account] += mintableQty;
            emit JoinedCycle(cycleId, account, mintableQty);
        }
        if (refund > 0) {
            (bool ok, ) = _msgSender().call{value: refund}("");
            if (!ok) revert Refund_Failed();
        }
    }

    /// @notice used by the {RAFFLE_MANAGER} to end a cycle in preparation for starting the draws
    /// @dev the function emite {RequiredRandomRequest} that should be used to know how many
    /// requests to the VRFManager will be required to draw all winners
    function processForWinners() external onlyRole(RAFFLE_MANAGER) {
        uint256 cycleId = cycleCounter.current();
        if (_status != Status.OPEN)
            revert Inaccurate_Raffle_State({
                expected: uint256(Status.OPEN),
                actual: uint256(_status)
            });

        (
            uint256 prize,
            uint256 prizePerWin,
            uint256 daoRake,
            uint256 platformRake,
            uint256 buyBackRake,
            uint256 refRake,
            uint256 rakePerRef,
            uint256 topCadreRake,
            uint256 possibleWinners
        ) = winningPrize(cycleId);

        _cycles[cycleId].prize = prizePerWin;
        _cycles[cycleId].rakePerRef = rakePerRef;
        _cycles[cycleId].possibleWinsBasedOnEntry = possibleWinners;

        // unchecked {
        // at worst, incoming values are 0 if total pay is 1 wei,
        // never going to happen, but still..
        _topCadreFund += topCadreRake;
        _buybackAndBurnFund += buyBackRake;
        _referralFund += refRake;
        _platformFund += platformRake;
        _daoFund += daoRake;
        // }
        uint256 drawCount = possibleWinners / 100; // batch of random numbers
        _draws[cycleId].target = drawCount == 0 ? 1 : drawCount; // we need at least 1 draw
        _status = Status.DRAWING_WINNERS;
        emit ReadyForDraws(
            cycleId,
            _entries[cycleId].length,
            prize,
            daoRake,
            buyBackRake
        );
    }

    /// @dev util function to check some parameters are available beofore proceeding to draw winners
    function _preDrawCheck(uint256 cycleId) internal view {
        if (_status != Status.OPEN)
            revert Inaccurate_Raffle_State({
                expected: uint256(Status.OPEN),
                actual: uint256(_status)
            });
        if (_entries[cycleId].length % 20 != 0)
            revert Cannot_Process_At_This_Time();
    }

    function requestRandomWordsForCycle() external onlyRole(RAFFLE_MANAGER) {
        if (_status != Status.DRAWING_WINNERS)
            revert Inaccurate_Raffle_State({
                expected: uint256(Status.DRAWING_WINNERS),
                actual: uint256(_status)
            });
        // will replace the previous one
        // raffle manager must ensure enough time has
        // passed in-between calls and there is no
        if (block.timestamp < (lastRequestMadeAt + 5 minutes))
            revert Too_Early();

        try
            wkdVRFManager.requestRandomWords(
                subscriptionId,
                2500000 /* Use max callback gas limit*/,
                100 /* number of words */,
                3 /* number of confirmations */
            )
        returns (uint256 requestId) {
            lastRequestId = requestId;
            lastRequestMadeAt = block.timestamp;
        } catch Error(string memory revertReason) {
            emit OperationFailedWithString(revertReason);
        } catch (bytes memory returnData) {
            emit OperationFailedWithData(returnData);
        }
    }

    /// @notice shows the available funds in the contract shared to different beneficiaries
    function availableFunds()
        external
        view
        returns (
            uint256 topCadre,
            uint256 buybackAndBurn,
            uint256 referralFund,
            uint256 platform,
            uint256 dao
        )
    {
        return (
            _topCadreFund,
            _buybackAndBurnFund,
            _referralFund,
            _platformFund,
            _daoFund
        );
    }

    /// @notice computes the winning prize of a given cycle
    /// @param cycleId id of the cycle of interest
    function winningPrize(
        uint256 cycleId
    )
        public
        view
        returns (
            uint256 prize,
            uint256 prizePerWin,
            uint256 daoRake,
            uint256 platformRake,
            uint256 buyBackRake,
            uint256 refRake,
            uint256 rakePerRef,
            uint256 topRankersRake,
            uint256 possibleWinners
        )
    {
        Cycle memory cycle = _cycles[cycleId];
        uint256 entryCount = _entries[cycleId].length;
        uint256 totalPay = entryCount * cycle.price;
        uint256 roundToNext20 = entryCount % SAMPLE_SIZE;
        if (roundToNext20 != 0) {
            entryCount = entryCount + (SAMPLE_SIZE - roundToNext20);
        }
        prize = (totalPay * WINNERS_PCT) / 100;
        possibleWinners =
            ((entryCount / SAMPLE_SIZE) * cycle.expectedWins) /
            100;
        prizePerWin = prize / possibleWinners;
        daoRake = (totalPay * DAO_PCT) / 100;
        platformRake = (totalPay * PLATFORM_PCT) / 100;
        buyBackRake = (totalPay * BUY_BACK_PCT) / 100;
        refRake = (totalPay * REF_PCT) / 100;
        rakePerRef = refRake / possibleWinners;
        topRankersRake = (totalPay * TOP_RANK_PCT) / 100;
    }

    /// @notice used by the {RAFFLE_MANAGER} to draw winners from the on-going cycle
    function drawWinners() external onlyRole(RAFFLE_MANAGER) {
        if (_status != Status.DRAWING_WINNERS)
            revert Inaccurate_Raffle_State({
                expected: uint256(Status.DRAWING_WINNERS),
                actual: uint256(_status)
            });
        uint256 cycleId = cycleCounter.current();
        _creditWinnersAndReferrals(cycleId);
    }

    /// @dev uses random words generated from the vrf manager to credit players
    /// it will never choose a winning number more than once
    /// winner is selected based on the index from the _entries[cycleId] array
    /// Can emit {RequiredRandomRequest} in case all winners aren't selected
    /// due to duplicated numbers from VRF call
    function _creditWinnersAndReferrals(uint256 cycleId) internal {
        Cycle memory cycle = _cycles[cycleId];
        uint256 expectedWinners = cycle.possibleWinsBasedOnEntry;
        address[] memory entries = _entries[cycleId];
        if (usedReqIds[lastRequestId]) revert Used_RequestId();
        (bool fulfilled, uint256[] memory randomWords) = wkdVRFManager
            .getRequestStatus(lastRequestId);
        if (fulfilled) {
            uint256 rakePerRef = cycle.rakePerRef;
            uint256 prize = cycle.prize;
            for (uint256 i = 0; i < randomWords.length; ) {
                uint256 n = randomWords[i] % entries.length;
                if (!_drawnIndexForCycle[cycleId][n]) {
                    _drawnIndexForCycle[cycleId][n] = true; // ensures number isn't selected twice
                    address winner = entries[n];
                    // for any unforseen reason
                    if (winner != address(0)) {
                        if (!_cycleOfPendingRewardFor[winner].exists) {
                            _cycleOfPendingRewardFor[winner].cycle = cycleId;
                            _cycleOfPendingRewardFor[winner].exists = true;
                        }
                        address referee = _referrals[winner];
                        if (referee != address(0)) {
                            _referralFund -= rakePerRef;
                            _refRake[referee] += rakePerRef;
                        }
                        _winnersRake[winner] += prize;
                        _draws[cycleId].winners.push(n); // for winner index verification
                    }
                }
                if (_draws[cycleId].winners.length == expectedWinners) {
                    _status = Status.POST_DRAW;
                    break;
                }
                i++;
            }
            if (_status != Status.POST_DRAW) {
                // request for more random numbers
                // if all winners haven't been selected at this point,
                // increase target by one
                _draws[cycleId].target++;
            }
            _draws[cycleId].current++;
            usedReqIds[lastRequestId] = true;
            Draw memory draw = _draws[cycleId];
            emit DrawResult(
                cycleId,
                draw.current,
                draw.target,
                draw.winners.length,
                subscriptionId,
                lastRequestId
            );
        }
        // silently pass without doing anything,
        // try again after some time
    }

    /// @notice used by {RAFFLE_MANAGER} to complete the cycle and close it, transferring funds to
    /// specially configured addreses such as the DAO
    function postDrawCall(
        bool fundVRFManager
    ) external nonReentrant onlyRole(RAFFLE_MANAGER) {
        if (_status != Status.POST_DRAW)
            revert Inaccurate_Raffle_State({
                expected: uint256(Status.POST_DRAW),
                actual: uint256(_status)
            });
        uint256 platformAmount = _platformFund;
        uint256 daoAmount = _daoFund;
        uint256 topCadreAmount = _topCadreFund;
        uint256 referralAmount = _referralFund; // unclaimed funds
        _topCadreFund = 0;
        _referralFund = 0;
        _platformFund = 0;
        _daoFund = 0;
        if (fundVRFManager) {
            if (platformAmount < VRF_FUNDING_AMOUNT)
                revert VRF_Funding_Failed();
            platformAmount -= VRF_FUNDING_AMOUNT;
            _closingCycleFundTransferTo(
                address(wkdVRFManager),
                VRF_FUNDING_AMOUNT
            );
        }
        _closingCycleFundTransferTo(_dao, daoAmount);
        _closingCycleFundTransferTo(_platform, platformAmount);
        _closingCycleFundTransferTo(_topCadre, topCadreAmount + referralAmount); // send unclaimed referral bonus along with top cadre
        _status = Status.CLOSED;
        uint256 cycleId = cycleCounter.current();
        emit PostDrawCall(
            cycleId,
            _entries[cycleId].length,
            _draws[cycleId].winners.length
        );
    }

    function _closingCycleFundTransferTo(
        address account,
        uint256 amount
    ) internal {
        (bool ok, ) = account.call{value: amount}("");
        if (!ok) revert Transfer_Failed();
    }

    /// @notice for {RAFFLE_MANAGER} to  perform buy backoperations
    function buyAndBurn(
        IRouter router
    ) external nonReentrant onlyRole(RAFFLE_MANAGER) {
        uint256 moment = block.timestamp;
        if (moment < (lastBurnAt + 7 days)) revert Too_Early();
        uint256 burnAmount = _buybackAndBurnFund;
        _buybackAndBurnFund = 0;
        address factory = router.factory();
        address weth = router.WETH();
        address pair = IFactory(factory).getPair(weth, WKD);
        if (pair == address(0)) revert Invalid_Pair();
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = WKD;
        uint256[] memory outs = router.getAmountsOut(burnAmount, path);

        try
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: burnAmount
            }(outs[1], path, BURN_ADDRESS, moment + 5 minutes)
        {
            lastBurnAt = moment;
            emit BuyBackAndBurn(address(router), outs[0], outs[1]);
        } catch Error(string memory revertReason) {
            emit OperationFailedWithString(revertReason);
        } catch (bytes memory returnData) {
            emit OperationFailedWithData(returnData);
        }
    }

    /// @notice shows the referral bonus for a given address
    function pendingReferralBonus(
        address account
    ) external view returns (uint256) {
        return _refRake[account];
    }

    /// @notice shows the total pending winning amount for an address and the amount of
    /// tokens required to burn for the claim to be withdrawn.
    /// @param account is the address under consideration
    function unclaimedBNB(
        address account
    ) public view returns (uint256 totalPendingAmount, uint256 tokensRequired) {
        totalPendingAmount = _winnersRake[account];
        uint256 winCycle = _cycleOfPendingRewardFor[account].cycle;
        if (winCycle != 0) {
            Cycle memory cycle = _cycles[winCycle];
            tokensRequired = totalPendingAmount / cycle.prize; // should be multiples of the prize won, otherwise, is zero
        }
    }

    /// @notice used to claim the referral bomus available for an address
    function claimReferralBonus() external nonReentrant {
        address to = _msgSender();
        uint256 amount = _refRake[to];
        if (amount == 0) revert Nothing_To_Claim();
        _refRake[to] = 0;
        (bool ok, ) = to.call{value: amount}("");
        if (!ok) revert Transfer_Failed();
        emit ClaimReferralBonus(to, amount);
    }

    /// @notice to claim the price.
    /// @dev cycleId must be provided because the price for each token is differnt in all cycles.
    /// a winning token is burnt during claim
    function claimPrize(address account) external nonReentrant {
        (uint256 totalPendingAmount, uint256 tokensRequired) = unclaimedBNB(
            account
        );
        if (totalPendingAmount != 0) {
            _claimPrize(account, totalPendingAmount, tokensRequired);
        }
    }

    function _claimPrize(
        address account,
        uint256 totalPendingAmount,
        uint256 tokensRequired
    ) internal {
        _wkdNFT.burnWinningTokens(account, tokensRequired);
        // clear storage
        delete _cycleOfPendingRewardFor[account];
        delete _winnersRake[account];
        (bool ok, ) = account.call{value: totalPendingAmount}("");
        if (!ok) revert Transfer_Failed();
        emit ClaimWinPrize(account, totalPendingAmount, tokensRequired);
    }

    /// @notice shows all the entries in a given cycle
    function showEntriesFor(
        uint256 cycleId
    ) external view returns (address[] memory entries) {
        entries = _entries[cycleId];
    }

    /// @notice get information about the draw on a cycle
    function showDrawFor(uint256 cycleId) external view returns (Draw memory) {
        return _draws[cycleId];
    }

    /// @notice shows the referee of an account
    function showReferralFor(address account) external view returns (address) {
        return _referrals[account];
    }

    /// @notice used to set the DAO address as specified by the {ADMIN}
    function updateDAO(address dao) external onlyRole(ADMIN) {
        if (dao == address(0)) revert Invalid_Address_Detected();
        emit DAOChanged(_dao, dao);
        _dao = dao;
    }

    /// @notice used to set the Platform address as specified by the {ADMIN}
    function updatePlatform(address platform) external onlyRole(ADMIN) {
        if (platform == address(0)) revert Invalid_Address_Detected();
        emit PlatformChanged(_platform, platform);
        _platform = platform;
    }

    /// @notice used to set the Top Cadre (contract) address as specified by the {ADMIN}
    function updateTopCadre(address topCadre) external onlyRole(ADMIN) {
        if (topCadre == address(0)) revert Invalid_Address_Detected();
        emit TopCadreChanged(_topCadre, topCadre);
        _topCadre = topCadre;
    }

    /// @notice used to set the vrf manager as specified by the {ADMIN}
    function updateVRFManager(
        address payable vrfManager,
        uint64 subId
    ) public onlyRole(ADMIN) {
        if (address(wkdVRFManager) == vrfManager && subscriptionId == subId)
            revert Same_As_Before();
        if (vrfManager == address(0)) revert Invalid_Address_Detected();
        emit VRFManagerUpdated(vrfManager, subId);
        wkdVRFManager = WKDVRFManager(vrfManager);
        subscriptionId = subId;
    }

    function showMyReferrals(
        address account
    ) external view returns (address[] memory myReferrals) {
        return _myRefs[account];
    }

    /// @notice shows the DAO wallet and the top cadre contract wallets
    function showManagementWallets()
        external
        view
        returns (address dao, address pplatform, address topcadre)
    {
        return (_dao, _platform, _topCadre);
    }

    /// @notice shows the version number of this contract
    function version() external pure returns (string memory) {
        return "v1";
    }
}
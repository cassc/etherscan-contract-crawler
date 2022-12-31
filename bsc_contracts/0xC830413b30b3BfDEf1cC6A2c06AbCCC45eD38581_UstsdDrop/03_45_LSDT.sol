// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./libs/IterableArrayWithoutDuplicateKeys.sol";
import "./libs/AmmLibrary.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IAmmPair.sol";
import "./CzUstsdReserves.sol";
import "./LSDTRewards.sol";

//import "hardhat/console.sol";

contract LSDT is
    ERC20PresetFixedSupply,
    VRFConsumerBaseV2,
    KeeperCompatibleInterface,
    Ownable
{
    using SafeERC20 for IERC20;
    using IterableArrayWithoutDuplicateKeys for IterableArrayWithoutDuplicateKeys.Map;
    enum UPKEEP_TYPE {
        REQUEST_VRF,
        MINT
    }

    //VRF properties
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    uint64 s_subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit = 50000;
    uint16 requestConfirmations = 3;
    uint256 public randomWord;
    uint256 public vrfRequestId;
    //Token properties
    uint256 public burnBps = 800;
    uint256 public taxBps = 200;
    mapping(address => bool) public isExempt;
    IAmmPair public ammCzusdPair;
    CZUsd public czusd;
    uint256 public baseCzusdLocked;
    //Ticket properties
    uint256 public constant MAX_ADDRESS_TICKETS = 200;
    IterableArrayWithoutDuplicateKeys.Map[MAX_ADDRESS_TICKETS +
        1] ticketBuckets;
    mapping(address => bool) public addressHasWon; //ALSO: set to true for addresses which are not eligible to win.
    mapping(address => uint256) public addressTickets;
    uint256 public totalTickets = 0;
    uint256 public tokensPerTicket = 1 ether;
    //USTSD Reward properties
    uint256 public czusdLockPerReward = 80 ether;
    uint256 public lastUstsdRewardEpoch;
    uint256 public totalUstsdRewarded;
    uint256 public totalCzusdSpent;
    uint256 public ustsdRewardPeriod = 30 hours;
    CzUstsdReserves czustsdReserves;
    JsonNftTemplate ustsdNft;
    address public rewardDistributor;
    //State
    bool public state_isVrfPending;
    bool public state_isRandomWordReady;
    //Tracking
    IterableArrayWithoutDuplicateKeys.Map trackedAddresses;

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _link,
        bytes32 _gweiKeyHash,
        CzUstsdReserves _czustsdReserves,
        JsonNftTemplate _ustsdNft,
        IAmmFactory _factory,
        CZUsd _czusd,
        uint256 _baseCzusdLocked
    )
        ERC20PresetFixedSupply(
            "Lucky Silver Dollar Token",
            "LSDT",
            10000 ether,
            msg.sender
        )
        VRFConsumerBaseV2(_vrfCoordinator)
        Ownable()
    {
        keyHash = _gweiKeyHash;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_link);
        s_subscriptionId = _subscriptionId;

        setLastUstsdRewardEpoch(block.timestamp);
        setCzustsdReserves(_czustsdReserves);
        setUstsdNft(_ustsdNft);
        setBaseCzusdLocked(_baseCzusdLocked);
        setRewardDistributor(
            address(new LSDTRewards(msg.sender, IERC20(this), _ustsdNft))
        );

        czusd = _czusd;
        ammCzusdPair = IAmmPair(
            _factory.createPair(address(this), address(czusd))
        );

        setHasWon(address(ammCzusdPair), true);
        setHasWon(msg.sender, true);
        setHasWon(rewardDistributor, true);
        setIsExempt(rewardDistributor, true);
        setIsExempt(msg.sender, true);
    }

    function setHasWon(address _for, bool _to) public onlyOwner {
        addressHasWon[_for] = _to;
        _updateAccount(_for);
    }

    function setCzustsdReserves(CzUstsdReserves _to) public onlyOwner {
        czustsdReserves = _to;
    }

    function setUstsdNft(JsonNftTemplate _to) public onlyOwner {
        ustsdNft = _to;
    }

    function setLastUstsdRewardEpoch(uint256 _to) public onlyOwner {
        lastUstsdRewardEpoch = _to;
    }

    function setTotalUstsdRewarded(uint256 _to) public onlyOwner {
        totalUstsdRewarded = _to;
    }

    function setTotalCzusdSpent(uint256 _to) public onlyOwner {
        totalCzusdSpent = _to;
    }

    function setTokensPerTicket(uint256 _to) public onlyOwner {
        tokensPerTicket = _to;
    }

    function setIsExempt(address _for, bool _to) public onlyOwner {
        isExempt[_for] = _to;
    }

    function setBaseCzusdLocked(uint256 _to) public onlyOwner {
        baseCzusdLocked = _to;
    }

    function setCzusdLockPerReward(uint256 _to) public onlyOwner {
        czusdLockPerReward = _to;
    }

    function setUstsdRewardPeriodPeriod(uint256 _to) public onlyOwner {
        ustsdRewardPeriod = _to;
    }

    function setRewardDistributor(address _to) public onlyOwner {
        rewardDistributor = _to;
    }

    function ustsdToReward() public view returns (uint256 rabbitMintCount_) {
        return ((lockedCzusd() - baseCzusdLocked - totalCzusdSpent) /
            czusdLockPerReward);
    }

    function lockedCzusd() public view returns (uint256 lockedCzusd_) {
        bool czusdIsToken0 = ammCzusdPair.token0() == address(czusd);
        (uint112 reserve0, uint112 reserve1, ) = ammCzusdPair.getReserves();
        uint256 lockedLP = ammCzusdPair.balanceOf(address(this));
        uint256 totalLP = ammCzusdPair.totalSupply();

        uint256 lockedLpCzusdBal = ((czusdIsToken0 ? reserve0 : reserve1) *
            lockedLP) / totalLP;
        uint256 lockedLpLsdtBal = ((czusdIsToken0 ? reserve1 : reserve0) *
            lockedLP) / totalLP;

        if (lockedLpLsdtBal == totalSupply()) {
            lockedCzusd_ = lockedLpCzusdBal;
        } else {
            lockedCzusd_ =
                lockedLpCzusdBal -
                (
                    AmmLibrary.getAmountOut(
                        totalSupply() - lockedLpLsdtBal,
                        lockedLpLsdtBal,
                        lockedLpCzusdBal
                    )
                );
        }
    }

    function fulfillRandomWords(uint256, uint256[] memory _randomWords)
        internal
        override
    {
        randomWord = _randomWords[0];
        state_isVrfPending = false;
        state_isRandomWordReady = true;
    }

    function _requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        vrfRequestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );
    }

    function getWinner(uint256 _word) public view returns (address winner_) {
        uint256 bucketRoll = 1 + (_word % totalTickets);
        uint256 winningBucketIndex = 0;
        uint256 accumulator;
        while (accumulator < bucketRoll) {
            winningBucketIndex++;
            accumulator += ((ticketBuckets[winningBucketIndex].size()) *
                winningBucketIndex);
        }
        IterableArrayWithoutDuplicateKeys.Map storage bucket = ticketBuckets[
            winningBucketIndex
        ];
        uint256 accountRoll = _word % bucket.size();
        winner_ = bucket.getKeyAtIndex(accountRoll);
    }

    //KEEPER CHAINLINK
    function checkUpkeep(bytes calldata checkData)
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        UPKEEP_TYPE upkeepType = abi.decode(checkData, (UPKEEP_TYPE));
        performData = checkData;
        if (upkeepType == UPKEEP_TYPE.REQUEST_VRF) {
            upkeepNeeded = _isUpkeepAllowedRequestVrf();
        }
        if (upkeepType == UPKEEP_TYPE.MINT) {
            upkeepNeeded = _isUpkeepAllowedMint();
        }
    }

    function _isUpkeepAllowedRequestVrf() internal view returns (bool) {
        return
            ustsdToReward() > 0 &&
            (block.timestamp > (ustsdRewardPeriod + lastUstsdRewardEpoch)) &&
            !state_isVrfPending &&
            !state_isRandomWordReady &&
            totalTickets > 0;
    }

    function _isUpkeepAllowedMint() internal view returns (bool) {
        return
            (ustsdToReward() > 0) &&
            (block.timestamp > (ustsdRewardPeriod + lastUstsdRewardEpoch)) &&
            state_isRandomWordReady &&
            totalTickets > 0;
    }

    function performUpkeep(bytes calldata performData) external override {
        UPKEEP_TYPE upkeepType = abi.decode(performData, (UPKEEP_TYPE));
        if (upkeepType == UPKEEP_TYPE.REQUEST_VRF) {
            _performUpkeepRequestVrf();
        }
        if (upkeepType == UPKEEP_TYPE.MINT) {
            _performUpkeepReward();
        }
    }

    function _performUpkeepRequestVrf() internal {
        require(
            _isUpkeepAllowedRequestVrf(),
            "LSDT: Request VRF Upkeep not allowed"
        );
        state_isVrfPending = true;
        _requestRandomWords();
    }

    function _performUpkeepReward() internal {
        require(_isUpkeepAllowedMint(), "LSDT: Mint Upkeep not allowed");
        state_isRandomWordReady = false;
        setLastUstsdRewardEpoch(block.timestamp);
        totalUstsdRewarded++;

        address winner = getWinner(randomWord);

        //Buy and send USTSD from reserves to winner
        //Requires permission to mint czusd
        uint256 rewardId = ustsdNft.tokenOfOwnerByIndex(
            address(czustsdReserves),
            randomWord % ustsdNft.balanceOf(address(czustsdReserves))
        );
        SilverDollarTypePriceSheet ustsdPriceOracle = czustsdReserves
            .USTSD_PRICE_ORACLE();
        uint256 priceWad = _centsToWad(
            ustsdPriceOracle.getCoinNftPriceCents(
                JsonNftTemplate(ustsdNft),
                rewardId
            )
        );
        uint256 czFeesWad = _centsToWad(czustsdReserves.buyFeeCzCents()) +
            ((priceWad * uint256(czustsdReserves.buyFeeCzBP())) / 10000);
        uint256 rcFeesWad = ((priceWad * czustsdReserves.buyFeeRcBP()) / 10000);
        uint256 totalPriceWad = priceWad + czFeesWad + rcFeesWad;
        czusd.mint(address(this), totalPriceWad);
        uint256[] memory toBuy = new uint256[](1);
        toBuy[0] = rewardId;
        czustsdReserves.buy(toBuy, CzUstsdReserves.CURRENCY.CZUSD);

        totalCzusdSpent += totalPriceWad;
        ustsdNft.transferFrom(address(this), winner, rewardId);
        addressHasWon[winner] = true;
        _updateAccount(winner);
    }

    function _deleteAccount(address _account, uint256 _prevTickets) internal {
        //console.log("Deleting", _account, _prevTickets);
        //Update bucket index and reorder bucket
        totalTickets -= _prevTickets;
        trackedAddresses.remove(_account);
        addressTickets[_account] = 0;
        ticketBuckets[_prevTickets].remove(_account);
    }

    function _updateAccount(address _account) internal {
        uint256 previousTickets = addressTickets[_account];
        uint256 currentTickets = 0;
        if (!addressHasWon[_account]) {
            uint256 ticketBal = balanceOf(_account) / tokensPerTicket;
            currentTickets = ticketBal > MAX_ADDRESS_TICKETS
                ? MAX_ADDRESS_TICKETS
                : ticketBal;
        }
        //console.log("Updating", _account, previousTickets, currentTickets);
        if (previousTickets != currentTickets) {
            if (currentTickets == 0) {
                //Account is no longer playing
                _deleteAccount(_account, previousTickets);
            } else if (previousTickets == 0) {
                //New account
                ticketBuckets[currentTickets].add(_account);
                addressTickets[_account] = currentTickets;
                totalTickets += currentTickets;
            } else {
                //Account is active but has a different amount of tickets.
                ticketBuckets[previousTickets].remove(_account);
                ticketBuckets[currentTickets].add(_account);
                addressTickets[_account] = currentTickets;
                totalTickets = totalTickets + currentTickets - previousTickets;
            }
        } else if (currentTickets == 0) {
            //no longer need to track this address - no change and 0 tickets
            trackedAddresses.remove(_account);
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        //Handle burn
        if (isExempt[sender] || isExempt[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 totalFeeWad = (amount * (burnBps + taxBps)) / 10000;
            uint256 burnAmount = (amount * burnBps) / 10000;
            if (burnAmount > 0) super._burn(sender, burnAmount);
            if (totalFeeWad - burnAmount > 0) {
                super._transfer(
                    sender,
                    rewardDistributor,
                    totalFeeWad - burnAmount
                );
            }
            super._transfer(sender, recipient, amount - totalFeeWad);
        }

        _updateAccount(sender);
        _updateAccount(recipient);
    }

    function _centsToWad(uint32 _cents) internal pure returns (uint256 wad_) {
        return (uint256(_cents) * 1 ether) / 100;
    }

    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }
}
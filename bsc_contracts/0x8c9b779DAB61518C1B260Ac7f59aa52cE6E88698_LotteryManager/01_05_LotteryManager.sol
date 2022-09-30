//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Cloneable.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IVRF.sol";

interface ILotteryClone {
    function setWinner(address winner_) external;
    function __init__() external;
}

contract LotteryManager is Cloneable, Ownable, VRFConsumerBaseV2 {

    // Funding Receivers
    address public immutable feeDatabase;

    // current lottery clone implementation
    address public implementation;

    // current lotto contract
    address public currentLotto;

    // Lotto History
    struct History {
        address winner;
        address lottoClone;
    }

    // Lotto ID => Lotto History
    mapping ( uint256 => History ) public lottoHistory;

    // Current Lotto ID
    uint256 public currentLottoID;

    // Lotto Details
    uint256 public startingCostPerTicket     = 2 * 10**16;
    uint256 public costIncreasePerTimePeriod = 1 * 10**16;
    uint256 public timePeriodForCostIncrease = 1 days;
    uint256 public lottoDuration             = 7 days;

    // When Last Lotto Began
    uint256 public lastLottoStartTime;

    // current ticket ID
    uint256 public currentTicketID;
    mapping ( uint256 => address ) public ticketToUser;

    // House Wallet
    address public houseWallet;

    // House Edge
    uint256 public houseEdge      = 10;
    uint256 public nobodyWinsEdge = 10;

    // VRF Coordinator
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 private s_subscriptionId;

    // testnet BNB coordinator
    address private immutable vrfCoordinator;// = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 private immutable keyHash;// = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;

    // chainlink request IDs
    uint256 private newLottoRequestID;

    // gas limit to call function
    uint32 public gasToCallRandom = 1_000_000;

    // Events
    event WinnerChosen(address winner, address lotto);
    event HouseWins(address lotto);
    event LotteryRolledOver();

    constructor(
        uint64 subscriptionId,   // 1815 testnet
        address vrfCoordinator_, // 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f testnet
        bytes32 keyHash_,        // 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314 testnet
        address house_,
        address implementation_,
        address feeDatabase_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        // setup chainlink
        keyHash = keyHash_;
        vrfCoordinator = vrfCoordinator_;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
        s_subscriptionId = subscriptionId;
        houseWallet = house_;
        implementation = implementation_;
        feeDatabase = feeDatabase_;
    }

    /**
        Sets Gas Limits for VRF Callback
     */
    function setGasLimits(uint32 gasToCallRandom_) external onlyOwner {
        gasToCallRandom = gasToCallRandom_;
    }

    /**
        Sets Subscription ID for VRF Callback
     */
    function setSubscriptionId(uint64 subscriptionId_) external onlyOwner {
       s_subscriptionId = subscriptionId_;
    }

    function setImplementation(address newImplementation) external onlyOwner {
        implementation = newImplementation;
    }

    function init() external onlyOwner {
        require(
            currentLotto == address(0) && lastLottoStartTime == 0,
            'Lotto Already Set'
        );

        // generate new lotto clone
        currentLotto = Cloneable(implementation).clone();
        ILotteryClone(currentLotto).__init__();
        lastLottoStartTime = block.timestamp;
    }

    function setStartingTicketCost(uint256 newCost) external onlyOwner {
        startingCostPerTicket = newCost;
    }

    function setLottoDuration(uint256 newDuration) external onlyOwner {
        lottoDuration = newDuration;
    }

    function setCostIncreasePerTimePeriod(uint256 increasePerPeriod) external onlyOwner {
        costIncreasePerTimePeriod = increasePerPeriod;
    }

    function setTimePeriodForCostIncrease(uint256 newTimePeriod) external onlyOwner {
        timePeriodForCostIncrease = newTimePeriod;
    }

    function setHouseWallet(address newWallet) external onlyOwner {
        houseWallet = newWallet;
    }

    function setHouseEdge(uint256 newEdge) external onlyOwner {
        require(
            newEdge <= 10,
            'House Edge Too Large'
        );
        houseEdge = newEdge;
    }

    function setNobodyWinsEdge(uint256 nobodyWinsEdge_) external onlyOwner {
        require(
            nobodyWinsEdge_ <= 10,
            'House Edge Too Large'
        );
        nobodyWinsEdge = nobodyWinsEdge_;
    }

    function resetLottoTime() external onlyOwner {
        lastLottoStartTime = block.timestamp;
    }

    function buyTickets(uint256 numTickets) external payable {
        require(
            numTickets * currentTicketCost() <= msg.value,
            'Incorrect Value Sent'
        );
        address user = msg.sender;

        for (uint i = 0; i < numTickets;) {

            ticketToUser[currentTicketID] = user;
            currentTicketID++;

            unchecked {
                ++i;
            }
        }

        // platform fees
        _send(feeDatabase, address(this).balance);
    }

    function newLotto() external {
        require(
            lastLottoStartTime > 0,
            'Lotto Has Not Been Initialized'
        );
        require(
            timeUntilNewLotto() == 0,
            'Not Time For New Lotto'
        );

        _newLotto();        
    }


    /**
        Registers A New Lotto
        Changes The Day Timer
        Distributes Winnings
     */
    function _newLotto() internal {

        // reset day timer
        lastLottoStartTime = block.timestamp;

        // get random number and send rewards when callback is executed
        // the callback is called "fulfillRandomWords"
        // this will revert if VRF subscription is not set and funded.
        newLottoRequestID = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            3, // number of block confirmations before returning random value
            gasToCallRandom, // callback gas limit is dependent num of random values & gas used in callback
            2 // the number of random results to return
        );
    }

    /**
        Chainlink's callback to provide us with randomness
     */
    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {

        if (requestId == newLottoRequestID) {

            // determine if house wins or no one wins
            uint winIndex = randomWords[1] % 100;
            bool houseWins = winIndex < houseEdge;
            bool noOneWins = winIndex >= houseEdge && winIndex < (houseEdge + nobodyWinsEdge);

            // select the winner based on edge, or the random number generated
            address winner;
            if (houseWins) {
                winner = houseWallet;
            } else if (noOneWins) {
                winner = address(0);
            } else {
                winner = currentTicketID > 0 ? ticketToUser[randomWords[0] % currentTicketID] : address(0);
            }
            
            // set winner
            if (winner != address(0)) {

                // Emit Winning Event
                if (winner == houseWallet) {
                    emit HouseWins(currentLotto);
                } else {
                    emit WinnerChosen(winner, currentLotto);
                }

                // save history
                lottoHistory[currentLottoID].winner = winner;
                lottoHistory[currentLottoID].lottoClone = currentLotto;

                // set lotto winner
                ILotteryClone(currentLotto).setWinner(winner);

                // generate new lotto clone
                currentLotto = Cloneable(implementation).clone();
                ILotteryClone(currentLotto).__init__();

                // reset lotto time again
                lastLottoStartTime = block.timestamp;
                
                // increment the current lotto ID
                currentLottoID++;           
            } else {
                emit LotteryRolledOver();
            }
            
            // reset ticket IDs back to 0
            delete currentTicketID;

        }
    }


    function currentTicketCost() public view returns (uint256) {
        uint256 epochsSinceLastLotto = block.timestamp > lastLottoStartTime ? ( block.timestamp - lastLottoStartTime ) / timePeriodForCostIncrease : 0;
        return startingCostPerTicket + ( epochsSinceLastLotto * costIncreasePerTimePeriod );
    }

    function timeUntilNewLotto() public view returns (uint256) {
        uint endTime = lastLottoStartTime + lottoDuration;
        return block.timestamp >= endTime ? 0 : endTime - block.timestamp;
    }

    function getOdds(address user) public view returns (uint256, uint256, uint256, uint256) {

        uint nTickets;
        for (uint i = 0; i < currentTicketID;) {

            if (ticketToUser[i] == user) {
                nTickets++;
            }

            unchecked {
                ++i;
            }
        }
        return (nTickets, currentTicketID, houseEdge, nobodyWinsEdge);
    }

    function getPastWinnersAndLottoContracts(uint256 numWinners) external view returns (address[] memory, address[] memory) {
        address[] memory winners = new address[](numWinners);
        address[] memory lottoClones = new address[](numWinners);
        uint start = currentLottoID - 1;
        uint end = currentLottoID - numWinners;
        uint count = 0;
        for (uint i = start; i >= end;) {
            winners[count] = lottoHistory[i].winner;
            lottoClones[count] = lottoHistory[i].lottoClone;
            unchecked { --i; ++count; }
        }
        return ( winners, lottoClones );
    }

    receive() external payable{
        (bool s,) = payable(currentLotto).call{value: address(this).balance}("");
        require(s);
    }

    function sendToLotto(address token, uint256 amount) external {
        IERC20(token).transferFrom(
            msg.sender,
            currentLotto,
            amount
        );
    }

    function _send(address to, uint256 amount) internal {
        if (to == address(this) || to == address(0)) {
            return;
        }
        (bool s,) = payable(to).call{value: amount}("");
        require(s, 'ETH Transfer Failure');
    }
}
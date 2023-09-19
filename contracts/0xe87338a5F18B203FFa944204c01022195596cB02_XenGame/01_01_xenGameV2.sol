// SPDX-License-Identifier: MIT

/*


██╗  ██╗███████╗███╗   ██╗ ██████╗  █████╗ ███╗   ███╗███████╗
╚██╗██╔╝██╔════╝████╗  ██║██╔════╝ ██╔══██╗████╗ ████║██╔════╝
 ╚███╔╝ █████╗  ██╔██╗ ██║██║  ███╗███████║██╔████╔██║█████╗  
 ██╔██╗ ██╔══╝  ██║╚██╗██║██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██╔╝ ██╗███████╗██║ ╚████║╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
                                                              
*/

pragma solidity ^0.8.17;

interface IXENnftContract {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface INFTRegistry {
    function registerNFT(uint256 tokenId) external;
    function isNFTRegistered(uint256 tokenId) external view returns (bool);
    function addToPool() external payable;
}

interface XENBurn {
    function deposit() external payable returns (bool);
}

interface IPlayerNameRegistry {
    function registerPlayerName(address _address, string memory _name) external payable;
    function getPlayerAddress(string memory _name) external view returns (address);
    function getPlayerFirstName(address playerAddress) external view returns (string memory);
}

contract XenGame {
    IXENnftContract public nftContract;
    INFTRegistry public nftRegistry;
    XENBurn public xenBurn;
    IPlayerNameRegistry private playerNameRegistry;

    uint256 constant KEY_RESET_PERCENTAGE = 1; // 0.001% or 1 basis point
    uint256 constant NAME_REGISTRATION_FEE = 20000000000000000; // 0.02 Ether in Wei
    uint256 constant KEY_PRICE_INCREMENT_PERCENTAGE = 10; // 0.099% or approx 10 basis points
    uint256 constant REFERRAL_REWARD_PERCENTAGE = 1000; // 10% or 1000 basis points
    uint256 constant NFT_POOL_PERCENTAGE = 500; // 5% or 500 basis points
    uint256 constant ROUND_GAP = 24 hours;// 24 hours round gap
    uint256 constant EARLY_BUYIN_DURATION = 300; // *********************************************************** updated to 5 min  

    uint256 constant KEYS_FUND_PERCENTAGE = 5000; // 50% or 5000 basis points
    uint256 constant JACKPOT_PERCENTAGE = 3000; // 30% or 3000 basis points
    uint256 constant BURN_FUND_PERCENTAGE = 1500; // 15% or 1500 basis points
    uint256 constant APEX_FUND_PERCENTAGE = 500; // 5% or 5000 basis points
    uint256 constant PRECISION = 10 ** 18;
    address private playerNames;

    struct Player {
        mapping(uint256 => uint256) keyCount; //round to keys
        mapping(uint256 => uint256) burntKeys;
        mapping(uint256 => uint256) earlyBuyinPoints; // Track early buyin points for each round
        uint256 referralRewards;
        string lastReferrer; // Track last referrer name
        mapping(uint256 => uint256) lastRewardRatio; // New variable
        uint256 keyRewards;
        uint256 numberOfReferrals; 
    }

    struct Round {
        uint256 totalKeys ;
        uint256 burntKeys; 
        
        uint256 start;
        uint256 end;
        address activePlayer;
        bool ended;
        bool isEarlyBuyin;
        uint256 keysFunds; // ETH dedicated to key holders
        uint256 jackpot; // ETH for the jackpot
        uint256 earlyBuyinEth; // Total ETH received during the early buy-in period
        uint256 lastKeyPrice; // The last key price for this round
        uint256 rewardRatio;
        uint256 BurntKeyFunds;
        uint256 uniquePlayers;
        address[] playerAddresses;
        
    }

    uint256 public currentRound = 0;
    mapping(address => Player) public players;
    mapping(uint256 => Round) public rounds;
    mapping(uint256 => mapping(address => bool)) public isPlayerInRound;
    mapping(string => address) public nameToAddress;
    mapping(address => mapping(uint256 => bool)) public earlyKeysReceived;

    constructor(
        address _nftContractAddress,
        address _nftRegistryAddress,
        address _xenBurnContract,
        address _playerNameRegistryAddress,
        uint256 _startTime
    ) {
        nftContract = IXENnftContract(_nftContractAddress);
        nftRegistry = INFTRegistry(_nftRegistryAddress);
        xenBurn = XENBurn(_xenBurnContract);
        playerNameRegistry = IPlayerNameRegistry(_playerNameRegistryAddress);
        playerNames = _playerNameRegistryAddress;

        currentRound = 1;        
        rounds[currentRound].start = _startTime;     
        rounds[currentRound].end = rounds[currentRound].start + 12 hours;         
        rounds[currentRound].ended = false;
        
    }

    /**
    * @dev Allows a player to buy keys with a referral.
    * @param _referrerName The name of the referrer.
    * @param _numberOfKeys The number of keys to purchase.
    */
    function buyWithReferral(string memory _referrerName, uint256 _numberOfKeys) public payable {
        Player storage player = players[msg.sender];

        // Get the player and referrer information
        string memory referrerName = bytes(_referrerName).length > 0 ? _referrerName : player.lastReferrer;
        address referrer = playerNameRegistry.getPlayerAddress(referrerName);

        Round storage round = rounds[currentRound];

            // Check if the player is not already in the current round
            if (!isPlayerInRound[currentRound][msg.sender]) {
                // Add the player address to the list of player addresses for the current round
                round.playerAddresses.push(msg.sender);
                // Set isPlayerInRound to true for the current player in the current round
                isPlayerInRound[currentRound][msg.sender] = true;
                // Increment the uniquePlayers count for the current round
                round.uniquePlayers++;
            }

            // Calculate the referral reward as a percentage of the incoming ETH
            uint256 referralReward = (msg.value * REFERRAL_REWARD_PERCENTAGE) / 10000; // 10% of the incoming ETH

            if (referralReward > 0) {
                // Added check here to ensure referral reward is greater than 0
                uint256 splitReward = referralReward / 2; // Split the referral reward

                // Add half of the referral reward to the referrer's stored rewards
                players[referrer].referralRewards += splitReward;
                players[referrer].numberOfReferrals++;

                if (referrer != address(0)){
                // Add the other half of the referral reward to the player's stored rewards
                player.referralRewards += splitReward;
                }

                emit ReferralPaid(msg.sender, referrer, splitReward, block.timestamp);
            }

            
            if (_numberOfKeys > 0) {
                buyCoreWithKeys(msg.value, _numberOfKeys);
            } else {
                buyCore(msg.value);
            }

            // Set the referrer name for the player
            player.lastReferrer = referrerName;
        
    }

    /**
    * @dev Handles the core logic of purchasing keys based on the amount of ETH sent.
    * @param _amount The amount of ETH sent by the player.
    */
    function buyCore(uint256 _amount) private {
        // Check if the round is active or has ended
        require(isRoundActive() || isRoundEnded(), "Cannot purchase keys during the round gap");

        uint256 _roundId = currentRound;
        Round storage round = rounds[currentRound];

        // If the round has ended and there are no total keys, set a new end time for the round
        if (isRoundEnded()) {

            if (round.totalKeys == 0){
                round.end = block.timestamp + 600;
                players[msg.sender].keyRewards += _amount;
                return;
            }

            endRound();
            startNewRound();
            players[msg.sender].keyRewards += _amount;
            return;
        }

        // If the round is active
        if (isRoundActive()) {
            if (block.timestamp <= round.start + EARLY_BUYIN_DURATION) {
                // If we are in the early buy-in period, follow early buy-in logic
                buyCoreEarly(_amount);
            } else if (!round.ended) {
                
                // Check if this is the first transaction after the early buy-in period
                if (round.isEarlyBuyin) {
                    updateTotalKeysForRound();
                    finalizeEarlyBuyinPeriod();
                }

                // Check if the last key price exceeds the jackpot threshold and reset it if necessary
                if (round.lastKeyPrice > calculateJackpotThreshold()) {
                    uint256 newPrice = resetPrice();
                    round.lastKeyPrice = newPrice;
                    emit PriceReset(msg.sender, newPrice, block.timestamp);
                }

                // Calculate the maximum number of keys to purchase and the total cost
                (uint256 maxKeysToPurchase, uint256 totalCost) = calculateMaxKeysToPurchase(_amount);
                    uint256 remainingEth = _amount - totalCost;

                // Transfer any remaining ETH back to the player and store it in their key rewards
                if (remainingEth > 0) {
                    players[msg.sender].keyRewards += remainingEth;
                }

                // Process users rewards for the current round
                processRewards(_roundId);

                // Set the last reward ratio for the player in the current round
                if (players[msg.sender].lastRewardRatio[_roundId] == 0) {
                    players[msg.sender].lastRewardRatio[_roundId] = round.rewardRatio;
                }

                // Process the key purchase with the maximum number of keys and total cost
                processKeyPurchase(maxKeysToPurchase, totalCost);

                // Set the active player for the round
                round.activePlayer = msg.sender;

                // Adjust the end time of the round based on the number of keys purchased
                adjustRoundEndTime(maxKeysToPurchase);
            }
        } 
    }

    /**
    * @dev Handles the core logic of purchasing keys with a specified number of keys and amount of ETH.
    * @param _amount The amount of ETH sent by the player.
    * @param _numberOfKeys The number of keys to purchase.
    */
    function buyCoreWithKeys(uint256 _amount, uint256 _numberOfKeys) private {
        // Check if the round is active or has ended\
        require(isRoundActive() || isRoundEnded(), "Cannot purchase keys during the round gap");

        uint256 _roundId = currentRound;
        Round storage round = rounds[currentRound];
        // If the round has ended and there are no total keys, set a new end time for the round
        if (isRoundEnded()) {

            if (round.totalKeys == 0){
                round.end = block.timestamp + 600;
                players[msg.sender].keyRewards += _amount;
                return;
            }
            
            // End the current round and start a new one
            endRound();
            startNewRound();
            players[msg.sender].keyRewards += _amount;
            return;
        }

        if (isRoundActive()) {

            if (block.timestamp <= round.start + EARLY_BUYIN_DURATION) {
                // If we are in the early buy-in period, follow early buy-in logic
                buyCoreEarly(_amount);
            } else if (!round.ended) {
                // Check if this is the first transaction after the early buy-in period
                if (round.isEarlyBuyin) {
                    updateTotalKeysForRound();
                    finalizeEarlyBuyinPeriod();
                }

                // Check if the last key price exceeds the jackpot threshold and reset it if necessary
                if (round.lastKeyPrice > calculateJackpotThreshold()) {
                    uint256 newPrice = resetPrice();
                    round.lastKeyPrice = newPrice;
                    emit PriceReset(msg.sender, newPrice, block.timestamp);

                }

                // Calculate cost for _numberOfKeys
                uint256 cost = calculatePriceForKeys(_numberOfKeys);
                require(cost <= _amount, "Not enough ETH to buy the specified number of keys");

                // Calculate the remaining ETH after the key purchase
                uint256 remainingEth = _amount - cost;

                // Process user rewards for the current round
                processRewards(_roundId);

                // Set the last reward ratio for the player in the current round if first user key buy. 
                if (players[msg.sender].lastRewardRatio[_roundId] == 0) {
                    players[msg.sender].lastRewardRatio[_roundId] = round.rewardRatio;
                }

                // Process the key purchase with the specified number of keys and cost
                processKeyPurchase(_numberOfKeys, cost);

                // Set the active player for the round
                round.activePlayer = msg.sender;

                // Adjust the end time of the round based on the number of keys purchased
                adjustRoundEndTime(_numberOfKeys);

                // Transfer any remaining ETH back to the player and store it in their key rewards
                if (remainingEth > 0) {
                    players[msg.sender].keyRewards += remainingEth;
                }
            }
        } 
    }

    /**
    * @dev Allows a player to purchase keys using their accumulated rewards.
    */
    function buyKeysWithRewards() public {
        // Check if the current round is active
        require(isRoundActive(), "Round is not active");

        Player storage player = players[msg.sender];

        // Check for any early keys
        checkForEarlyKeys();

        // Calculate the player's rewards
        uint256 reward = (
            (player.keyCount[currentRound] / 1 ether)
                * (rounds[currentRound].rewardRatio - player.lastRewardRatio[currentRound])
        ); // using full keys for reward calc

        // Add any keyRewards to the calculated reward
        reward += player.keyRewards;

        // Reset player's keyRewards
        player.keyRewards = 0;

        require(reward > 0, "No rewards to buy keys with");

        // Reset player's lastRewardRatio for the round
        player.lastRewardRatio[currentRound] = rounds[currentRound].rewardRatio; //

        // Calculate max keys that can be purchased with the reward
        (uint256 maxKeysToPurchase,) = calculateMaxKeysToPurchase(reward);

        // Make sure there are enough rewards to purchase at least one key
        require(maxKeysToPurchase > 0, "Not enough rewards to purchase any keys");

        // Buy keys using rewards
        buyCore(reward);
    }

    /**
    * @dev Handles the logic of purchasing keys during the early buy-in period.
    * @param _amount The amount of ETH sent by the player.
    */
    function buyCoreEarly(uint256 _amount) private {
        // Accumulate the ETH and track the user's early buy-in points

        // Calculate the referral reward as a percentage of the incoming ETH
        uint256 referralReward = (_amount * REFERRAL_REWARD_PERCENTAGE) / 10000;

        // Check if the player's last referrer is not valid, and halve the referral reward
        if (playerNameRegistry.getPlayerAddress(players[msg.sender].lastReferrer) == address(0)){
            referralReward = (referralReward / 2);
        }

        // Calculate the amount of ETH without the referral reward
        uint256 amount = _amount - referralReward;

        // Accumulate the amount of ETH sent during the early buy-in period
        rounds[currentRound].earlyBuyinEth += amount;

        // Accumulate the early buy-in points for the player
        players[msg.sender].earlyBuyinPoints[currentRound] += amount;

        // Set the last reward ratio for the player in the current round to 1
        players[msg.sender].lastRewardRatio[currentRound] = 1;

        // Set isEarlyBuyin to true to indicate the early buy-in period is active
        rounds[currentRound].isEarlyBuyin = true;
    }

    /**
    * @dev Fallback function to handle incoming ETH payments and execute buy or withdraw rewards logic.
    */
fallback() external payable {
    // If the incoming value is 0, withdraw rewards for all rounds
    if (msg.value == 0) {
        for (uint256 i = 1; i <= currentRound; i++) {
            withdrawRewards(i);
        }
    }
    // Call buyWithReferral function with empty referrer name and 0 number of keys
    buyWithReferral("", 0);
}

/**
    * @dev Receive function to handle incoming ETH payments and execute buy or withdraw rewards logic.
    */
receive() external payable {
    // If the incoming value is 0, withdraw rewards for all rounds
    if (msg.value == 0) {
        for (uint256 i = 1; i <= currentRound; i++) {
            withdrawRewards(i);
        }
    }
    // Call buyWithReferral function with empty referrer name and 0 number of keys
    buyWithReferral("", 0);
}

    /**
    * @dev Checks if the current round is active.
    * @return bool indicating whether the round is active or not.
    */
    function isRoundActive() public view returns (bool) {
        uint256 _roundId = currentRound;
        return block.timestamp >= rounds[_roundId].start && block.timestamp < rounds[_roundId].end;
    }

    /**
    * @dev Checks if the current round has ended.
    * @return bool indicating whether the round has ended or not.
    */
    function isRoundEnded() public view returns (bool) {
        uint256 _roundId = currentRound;
        return block.timestamp >= rounds[_roundId].end;
    }

    /**
    * @dev Updates the total number of keys for the current round.
    * If there was early buy-in ETH, it adds 10,000,000 keys. Otherwise, it adds 1 key.
    */
    function updateTotalKeysForRound() private {
        // Check if there was early buy-in ETH        
        if (rounds[currentRound].earlyBuyinEth > 0) {
            // Add 10,000,000 keys to the total keys count for the round
            rounds[currentRound].totalKeys += 10000000 ether;

        } else {

            // Add 1 key to the total keys count for the round if no early buyin.
            rounds[currentRound].totalKeys += 1 ether;
        }
    }

    /**
    * @dev Finalizes the early buy-in period by setting necessary variables and adding early buy-in funds to the jackpot.
    */
    function finalizeEarlyBuyinPeriod() private {
        // Set isEarlyBuyin to false to signify the early buy-in period is over
        Round storage round = rounds[currentRound];
        
        round.isEarlyBuyin = false;

        // Calculate the last key price for the round
        if (round.earlyBuyinEth > 0) {
            round.lastKeyPrice = round.earlyBuyinEth / (10 ** 7); // using full keys
        } else {
            round.lastKeyPrice = 0.000000009 ether; // Set to 0.000000009 ether if there is no early buying ETH or no keys purchased
        }

        // Set the reward ratio to a low non-zero value
        round.rewardRatio = 1; 

        // Add early buy-in funds to the jackpot
        round.jackpot += round.earlyBuyinEth;
    }

    /**
    * @dev Calculates the maximum number of keys that can be purchased and the total cost within a given amount of ETH.
    * @param _amount The amount of ETH to spend on keys.
    * @return maxKeys The maximum number of keys that can be purchased.
    * @return totalCost The total cost in ETH to purchase the maximum number of keys.
    */
    function calculateMaxKeysToPurchase(uint256 _amount) public view returns (uint256 maxKeys, uint256 totalCost) {
        uint256 initialKeyPrice = getKeyPrice();
        uint256 left = 0;
        uint256 right = _amount / initialKeyPrice;
        uint256 _totalCost;

        while (left < right) {
            uint256 mid = (left + right + 1) / 2;
            _totalCost = calculatePriceForKeys(mid);

            if (_totalCost <= _amount) {
                left = mid;
            } else {
                right = mid - 1;
            }
        }

        maxKeys = left;
        _totalCost = calculatePriceForKeys(left);

        return (maxKeys, _totalCost);
    }

    /**
    * @dev Calculates the total price for a specified number of keys based on the current key price.
    * @param _keys The number of keys to calculate the price for.
    * @return totalPrice The total price in ETH for the specified number of keys.
    */
    function calculatePriceForKeys(uint256 _keys) public view returns (uint256 totalPrice) {
        uint256 initialKeyPrice = getKeyPrice();
        uint256 increasePerKey = 0.000000009 ether;

         // Calculate the total price based on the number of keys
        if (_keys <= 1) {
            totalPrice = initialKeyPrice * _keys;
        } else {
            uint256 lastPrice = initialKeyPrice + ((_keys - 1) * increasePerKey);
            totalPrice = (_keys * (initialKeyPrice + lastPrice)) / 2;
        }

        return totalPrice;
    }

    /**
    * @dev Handles the purchase of keys by a player and updates relevant data.
    * @param maxKeysToPurchase The maximum number of keys to purchase.
    * @param _amount The amount of ETH sent by the player.
    */
    function processKeyPurchase(uint256 maxKeysToPurchase, uint256 _amount) private {
        // Check if the amount is greater than or equal to 0
        require(_amount > 0, "Not enough Ether to purchase keys");

        // Calculate the fractional keys based on the maximum number of keys to purchase
        uint256 fractionalKeys = maxKeysToPurchase * 1 ether;
        Round storage round = rounds[currentRound];

        // Increase the player's key count for the current round
        players[msg.sender].keyCount[currentRound] += fractionalKeys;

        // Reset the last reward ratio for the player in the current round
        players[msg.sender].lastRewardRatio[currentRound] = round.rewardRatio; // reset fallback in case user has gap betewwn burn and next buyin. 

        // Increase the total keys for the current round
        round.totalKeys += fractionalKeys;

        // Calculate the final key price based on the last key price and the increase per key
        uint256 finalKeyPrice = round.lastKeyPrice;
        uint256 increasePerKey = 0.000000009 ether;
        finalKeyPrice += increasePerKey * maxKeysToPurchase;

        // Update the last key price for the current round
        round.lastKeyPrice = finalKeyPrice;

        // Distribute the funds to different purposes (keys funds, jackpot, etc.)
        distributeFunds(_amount);

        emit BuyAndDistribute(msg.sender,  maxKeysToPurchase, finalKeyPrice,  block.timestamp);
    }

    /**
    * @dev Burns the keys owned by a player in a specific round.
    * @param player The address of the player.
    * @param roundNumber The round number in which to burn the keys.
    */
    function BurnKeys(address player, uint roundNumber) private {
        
        // Check if the round number is the current round
        if (roundNumber == currentRound) {
            uint256 Keys = players[player].keyCount[roundNumber];

            // Reset the key count of the player for the specific round
            players[player].keyCount[roundNumber] = 0;

            // Update the burnt keys count for the player and round
            players[player].burntKeys[roundNumber]+= Keys;
            rounds[roundNumber].totalKeys -= Keys;
            rounds[roundNumber].burntKeys += Keys;

            
            emit KeyBurn(player,  Keys,  block.timestamp);
        }
    }

    /**
    * @dev Checks if the player has early buy-in points for the current round and adds early keys if applicable.
    */
    function checkForEarlyKeys() private {

        // Check if the player has early buy-in points and has not received early keys for the current round
        if (players[msg.sender].earlyBuyinPoints[currentRound] > 0 && !earlyKeysReceived[msg.sender][currentRound]) {

            // Calculate early keys based on the amount of early ETH sent
            uint256 totalPoints = rounds[currentRound].earlyBuyinEth;
            uint256 playerPoints = players[msg.sender].earlyBuyinPoints[currentRound];
            uint256 earlyKeys = ((playerPoints * 10_000_000) / totalPoints) * 1 ether;

            // Add the early keys to the player's key count for the current round
            players[msg.sender].keyCount[currentRound] += earlyKeys;
            
            // Mark that early keys were received for this round
            earlyKeysReceived[msg.sender][currentRound] = true;
        }
    }

    /**
    * @dev Adjusts the end time of the current round based on the maximum number of keys purchased.
    * @param maxKeysToPurchase The maximum number of keys purchased in the current transaction.
    */
    function adjustRoundEndTime(uint256 maxKeysToPurchase) private {
        // Calculate the time extension based on the maximum keys purchased
        uint256 timeExtension = maxKeysToPurchase * 30 seconds;

        // Set the maximum end time as the current timestamp plus 2 hours
        uint256 maxEndTime = block.timestamp + 12 hours;

        // Adjust the end time of the current round by adding the time extension, capped at the maximum end time
        rounds[currentRound].end = min(rounds[currentRound].end + timeExtension, maxEndTime);
    }

    /**
    * @dev Retrieves the current key price for the active round.
    * @return The current key price.
    */
    function getKeyPrice() public view returns (uint256) {
        uint256 _roundId = currentRound;

        // Use the last key price set for this round, whether it's from the Early Buy-in period or elsewhere
        return rounds[_roundId].lastKeyPrice;
    }

    /**
    * @dev Calculates the jackpot threshold as a percentage of the current round's jackpot.
    * @return The jackpot threshold.
    */
    function calculateJackpotThreshold() private view returns (uint256) {
        uint256 _roundId = currentRound;

        // Calculate the jackpot threshold as 0.0001% of the jackpot
        return rounds[_roundId].jackpot / 1000000; 
    }

    /**
    * @dev Resets the key price by dividing the current round's jackpot by 10 million.
    * @return The new key price after resetting.
    */
    function resetPrice() private view returns (uint256) {
        uint256 _roundId = currentRound;
        return rounds[_roundId].jackpot / 10000000; 
    }

    /**
    * @dev Updates the reward ratio for a specific round based on the amount of ETH received.
    * @param _amount The amount of ETH received.
    * @param _roundNumber The round number to update the reward ratio for.
    */
    function updateRoundRatio(uint256 _amount, uint256 _roundNumber) private {

        // Calculate the reward ratio by dividing the amount by the total keys in the current round
        rounds[_roundNumber].rewardRatio += (_amount / (rounds[currentRound].totalKeys / 1 ether));
    }

    /**
    * @dev Distributes the incoming ETH to different funds and updates the reward ratio.
    * @param _amount The amount of ETH received.
    */
    function distributeFunds(uint256 _amount) private {
        // Calculate the referral reward as a percentage of the incoming ETH
        uint256 referralReward = (_amount * REFERRAL_REWARD_PERCENTAGE) / 10000;

        // Check if the last referrer is not registered and adjust the referral reward
        if (playerNameRegistry.getPlayerAddress(players[msg.sender].lastReferrer) == address(0)){
            referralReward = (referralReward / 2);
        }

        // Calculate the remaining amount after deducting the referral reward
        uint256 amount = _amount - referralReward;

        // Calculate the keys fund as a percentage of the remaining amount
        uint256 keysFund = (amount * KEYS_FUND_PERCENTAGE) / 10000;

        // Update the reward ratio for the current round based on the keys fund
        updateRoundRatio(keysFund, currentRound);
        
        // Calculate the jackpot as a percentage of the remaining amount
        uint256 jackpot = (amount * JACKPOT_PERCENTAGE) / 10000;

        // Add the jackpot to the current round's jackpot
        rounds[currentRound].jackpot += jackpot;

        // Calculate the apex fund as a percentage of the remaining amount
        uint256 apexFund = (amount * APEX_FUND_PERCENTAGE) / 10000;

        // Transfer the apex fund to the nftRegistry
        nftRegistry.addToPool{value: apexFund}();

        // Calculate the burn fund as a percentage of the remaining amount
        uint256 burnFund = (amount * BURN_FUND_PERCENTAGE) / 10000;

        // Deposit the burn fund to the xenBurn contract
        xenBurn.deposit{value: burnFund}();

        
    }

    /**
    * @dev Allows a player to register a name by paying the registration fee.
    * @param name The name to register.
    */
    function registerPlayerName(string memory name) public payable {
        // Check if the player has provided enough funds to register the name
        require(msg.value >= NAME_REGISTRATION_FEE, "Insufficient funds to register the name.");

        // Call the registerPlayerName function of the playerNameRegistry contract with the player's address and name
        playerNameRegistry.registerPlayerName{value: msg.value}(msg.sender, name);

        emit PlayerNameRegistered(msg.sender, name, block.timestamp);

    }

    /**
    * @dev Allows the owner of an NFT to register it.
    * @param tokenId The ID of the NFT to register.
    */
    function registerNFT(uint256 tokenId) external {
        // Check if the caller is the owner of the NFT with the given tokenId
        require(nftContract.ownerOf(tokenId) == msg.sender, "You don't own this NFT.");

        // Call the registerNFT function of the nftRegistry contract with the tokenId
        nftRegistry.registerNFT(tokenId);
    }

    /**
    * @dev Processes the rewards for the specified round and adds them to the player's keyRewards.
    * @param roundNumber The round number for which to calculate and process rewards.
    */
    function processRewards(uint256 roundNumber) private  {
        // Get the player's storage reference
        Player storage player = players[msg.sender];

        // Check for early keys received during the early buy-in period
        checkForEarlyKeys();

        // Only calculate rewards if player has at least one key
        if (player.keyCount[roundNumber] > 0) {
            // Calculate the player's rewards based on the difference between reward ratios
            uint256 reward = (
                (player.keyCount[roundNumber] / 1 ether)
                    * (rounds[roundNumber].rewardRatio - player.lastRewardRatio[roundNumber])
            ); 

            // Update the player's last reward ratio to the current round's ratio
            player.lastRewardRatio[roundNumber] = rounds[roundNumber].rewardRatio;

            // Add the calculated reward to the player's keyRewards
            player.keyRewards += reward;
        }
    }

    
/**
    * @dev Allows the player to withdraw their rewards for the specified round.
    * @param roundNumber The round number for which to withdraw rewards.
    */
function withdrawRewards(uint256 roundNumber) public {
    // Get the player's storage reference
    Player storage player = players[msg.sender];

    // Convert the player's address to a payable address
    address payable senderPayable = payable(msg.sender);  

    // Check for early keys received during the early buy-in period
    checkForEarlyKeys();

    // Calculate the rewards based on the difference between reward ratios
    uint256 reward = (
        (player.keyCount[roundNumber] / 1 ether)
            * (rounds[roundNumber].rewardRatio - player.lastRewardRatio[roundNumber])
    );

    // Update the player's last reward ratio to the current round's ratio
    player.lastRewardRatio[roundNumber] = rounds[roundNumber].rewardRatio;

    // Add the unpreprocessed keyRewards to the processed rewards
    reward += player.keyRewards;

    // Reset the player's keyRewards
    player.keyRewards = 0;

    // Burn the player's past keys for the current round
    if (roundNumber == currentRound){
        BurnKeys(msg.sender, roundNumber);

    }
    

    if (reward > 0) {
        // Transfer the rewards
        senderPayable.transfer(reward);

        emit RewardsWithdrawn(msg.sender, reward, block.timestamp);
    }
}

    /**
    * @dev Allows a player to withdraw their referral rewards.
    */
function withdrawReferralRewards() public {
    // Get the amount of referral rewards for the player
    uint256 rewardAmount = players[msg.sender].referralRewards;
    require(rewardAmount > 0, "No referral rewards to withdraw");

    // Check that the player has a registered name
    string memory playerName = getPlayerName(msg.sender);
    require(bytes(playerName).length > 0, "Player has no registered names");

    // Convert the player's address to a payable address
    address payable senderPayable = payable(msg.sender); 

    // Reset the player's referral rewards 
    players[msg.sender].referralRewards = 0;

    // transfer the rewards
    senderPayable.transfer(rewardAmount);

    emit ReferralRewardsWithdrawn(msg.sender, rewardAmount, block.timestamp);

    rewardAmount = players[address(0)].referralRewards;
    if (rewardAmount > 0){
        players[address(0)].referralRewards = 0;
        (bool success, ) = payable(playerNames).call{value: rewardAmount}("");
        require(success, "Transfer failed.");

    }
}

    /**
    * @dev Allows a player to withdraw their burnt keys rewards for a specific round.
    * @param _roundNumber The round number for which the player wants to withdraw burnt keys rewards.
    */
function WithdrawBurntKeyRewards(uint _roundNumber) public {
    // Check if the round number is valid and not greater than the current round
    require( _roundNumber < currentRound , "Can't withdraw BurntKey Rewards tell round end.");

    // Check if the player has burnt keys rewards for the specified round
    require(players[msg.sender].burntKeys[_roundNumber] > 0 , "Player has no burnt Keys rewards.");

    // Calculate the reward amount based on the player's burnt keys and the burnt key funds for the round
    uint256 reward = ((players[msg.sender].burntKeys[_roundNumber] * rounds[_roundNumber].BurntKeyFunds) / rounds[_roundNumber].burntKeys);

    // Reset the burnt keys rewards for the player
    players[msg.sender].burntKeys[_roundNumber] = 0;

    // Transfer the reward amount to the player
    address payable senderPayable = payable(msg.sender);
    senderPayable.transfer(reward);

    emit BurnKeysRewardWithdraw(msg.sender, reward, _roundNumber, block.timestamp);


}

    /**
    * @dev Ends the current round and distributes the jackpot and funds to the winner and other recipients.
    */
    function endRound() private {
        // Get the current round
        Round storage round = rounds[currentRound];

        // Check if the current timestamp is after the round end time
        require(block.timestamp >= round.end, "Round has not yet ended.");

        // Identify the winner as the last person to have bought a key
        address winner = round.activePlayer;

        // Divide the jackpot
        uint256 jackpot = round.jackpot;
        uint256 winnerShare = (jackpot * 50) / 100; // 50%
        uint256 burntKeysFundsShare = (jackpot * 20) / 100; // 20%
        uint256 currentRoundNftShare = (jackpot * 20) / 100; // 20%
        uint256 nextRoundJackpot = (jackpot * 10) / 100; // 10%

        // Transfer to the winner
        players[winner].keyRewards += winnerShare;
        

        // Add to the burntKeysFunds share to the Burnt keys
        round.BurntKeyFunds += burntKeysFundsShare;

        // Set the starting jackpot for the next round
        rounds[currentRound + 1].jackpot = nextRoundJackpot;

        // Send to the NFT contract
        nftRegistry.addToPool{value: currentRoundNftShare}();

        round.ended = true;

        emit RoundEnded(currentRound, winner, jackpot, winnerShare, burntKeysFundsShare, currentRoundNftShare, nextRoundJackpot, block.timestamp);
    }

    /**
    * @dev Starts a new round by incrementing the current round number and setting the start and end times.
    */
    function startNewRound() private {
        // Increment the current round number
        currentRound += 1;

        // Set the start time of the new round by adding ROUND_GAP to the current timestamp
        rounds[currentRound].start = block.timestamp + ROUND_GAP;
        
        // Set the end time of the new round by adding 1 hour to the start time (adjust as needed)
        rounds[currentRound].end = rounds[currentRound].start + 12 hours; 

        // Reset the "ended" flag for the new round
        rounds[currentRound].ended = false;

       
        emit NewRoundStarted(currentRound, rounds[currentRound].start, rounds[currentRound].end);
    }

    /**
    * @dev Calculates the pending rewards for a player in a specific round.
    * @param playerAddress The address of the player.
    * @param roundNumber The round number.
    * @return The amount of pending rewards for the player in the specified round.
    */
    function getPendingRewards(address playerAddress, uint256 roundNumber) public view returns (uint256) {
        // Get the player and round information
        Player storage player = players[playerAddress];

        // Calculate the pending rewards based on the player's key count and the difference in reward ratio
        uint256 pendingRewards = (
            (player.keyCount[roundNumber] / 1 ether)
                * (rounds[roundNumber].rewardRatio - player.lastRewardRatio[roundNumber])
        );

        // Add the unprocessed keyRewards to the pending rewards

        if (roundNumber < currentRound){

            return pendingRewards;

        } else{

            pendingRewards += player.keyRewards;
            return pendingRewards;

        }

        
    }


    function getPlayerKeysCount(address playerAddress, uint256 _round) public view returns (uint256) {
        Player storage player = players[playerAddress];

        if (player.earlyBuyinPoints[_round] > 0 && !earlyKeysReceived[playerAddress][_round]) {
            // Calculate early keys based on the amount of early ETH sent
            uint256 totalPoints = rounds[_round].earlyBuyinEth;
            uint256 playerPoints = players[playerAddress].earlyBuyinPoints[_round];

            uint256 earlyKeys = ((playerPoints * 10_000_000) / totalPoints) * 1 ether;

            return (player.keyCount[_round] + earlyKeys);
        } else {
            return player.keyCount[_round];
        }
    }

    function getPlayerName(address playerAddress) public view returns (string memory) {
        return playerNameRegistry.getPlayerFirstName(playerAddress);
    }

    

    function getRoundTotalKeys(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].totalKeys;
    }

    function getRoundBurntKeys(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].burntKeys;
    }

    

    

    function getRoundEnd(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].end;
    }

    function getRoundActivePlayer(uint256 roundId) public view returns (address) {
        return rounds[roundId].activePlayer;
    }

    function getRoundEnded(uint256 roundId) public view returns (bool) {
        return rounds[roundId].ended;
    }

    function getRoundIsEarlyBuyin(uint256 roundId) public view returns (bool) {
        return rounds[roundId].isEarlyBuyin;
    }

    function getRoundKeysFunds(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].keysFunds;
    }

    function getRoundJackpot(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].jackpot;
    }

    function getRoundEarlyBuyinEth(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].earlyBuyinEth;
    }

    function getRoundLastKeyPrice(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].lastKeyPrice;
    }

    function getRoundRewardRatio(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].rewardRatio;
    }

    function getRoundBurntKeyFunds(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].BurntKeyFunds;
    }

    function getRoundUniquePlayers(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].uniquePlayers;
    }

    function getRoundPlayerAddresses(uint256 roundId) public view returns (address[] memory) {
        return rounds[roundId].playerAddresses;
    }

    function getRoundIsPlayerInRound(uint256 roundId, address player) public view returns (bool) {
        return isPlayerInRound[roundId][player];
    }

    function getPlayerInfo(address playerAddress, uint256 roundNumber)
        public
        view
        returns (
            uint256 keyCount, 
            uint256 earlyBuyinPoints, 
            uint256 referralRewards, 
            uint256 lastRewardRatio,
            uint256 keyRewards,
            uint256 numberOfReferrals
        )
    {
        keyCount = getPlayerKeysCount(playerAddress, roundNumber);
        earlyBuyinPoints = players[playerAddress].earlyBuyinPoints[roundNumber];
        referralRewards = players[playerAddress].referralRewards;
        lastRewardRatio = players[playerAddress].lastRewardRatio[roundNumber];
        keyRewards = getPendingRewards(playerAddress,  roundNumber);
        numberOfReferrals = players[playerAddress].numberOfReferrals;
    }

    function getPlayerKeyCount(address playerAddress, uint256 round) public view returns (uint256) {
        return players[playerAddress].keyCount[round];
    }

    function getPlayerBurntKeys(address playerAddress, uint256 round) public view returns (uint256) {
        return players[playerAddress].burntKeys[round];
    }

    function getPlayerEarlyBuyinPoints(address playerAddress, uint256 round) public view returns (uint256) {
        return players[playerAddress].earlyBuyinPoints[round];
    }

    function getlastRewardRatio(address playerAddress, uint256 round) public view returns (uint256) {
        return players[playerAddress].lastRewardRatio[round];
    }

    function getRoundStart(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].start;
    }

    function getRoundEarlyBuyin(uint256 roundId) public view returns (uint256) {
        return rounds[roundId].earlyBuyinEth;
    }

    function getUniquePlayers(uint256 round) public view returns (uint256) {
        return rounds[round].uniquePlayers;
    }

    function getPlayerAddresses(uint256 round) public view returns (address[] memory) {
        return rounds[round].playerAddresses;
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    event BuyAndDistribute(address buyer, uint256 amount, uint256 keyPrice, uint256 timestamp);
    event ReferralRewardsWithdrawn(address indexed player, uint256 amount, uint256 timestamp);
    event RewardsWithdrawn(address indexed player, uint256 amount, uint256 timestamp);
    event RoundEnded(uint256 roundId, address winner, uint256 jackpot, uint256 winnerShare, uint256 keysFundsShare, uint256 currentRoundNftShare, uint256 nextRoundJackpot, uint256 timestamp);
    event NewRoundStarted(uint256 roundId, uint256 startTimestamp, uint256 endTimestamp);
    event PlayerNameRegistered(address player, string name, uint256 timestamp);
    event ReferralPaid(address player, address referrer, uint256 amount, uint256 timestamp);
    event KeyBurn(address player, uint256 Keys, uint256 timestamp);
    event BurnKeysRewardWithdraw(address player, uint256 reward, uint256 RoundNumber, uint256 timestamp);
    event PriceReset(address player, uint256 newPrice, uint256 timestamp);

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

/**
* @dev Interface for ChainLink Oracle BNB/USD. 
*/
interface AggregatorV3Interface {
    function latestRoundData() external view returns (
      uint80 roundId,
      int answer,
      uint startedAt,
      uint updatedAt,
      uint80 answeredInRound
    );
}

/**
 * @notice Interface for Pancakeswap Liquidity Pair used to calculate price at {getTokenPrice} function.
*/
interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP plus fee exclusion feature and liquidity pair address.
 */
interface IERC20 {
    function _pancakeV2Pair() external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function isExcludedFromFee(address account) external view returns(bool);
    function getTokensBought(address user) external view returns(uint);
}

interface IDAO{
    function saveUserTierLimit(address user) external;
}

/**
 * @title AutoCrypto App
 * @author AutoCrypto
 * @notice This contracts stores user and tier data for the investment app.
 */
contract AutoCryptoApp is Initializable, UUPSUpgradeable {

    IAccessControlUpgradeable private timelock;
    bytes32 private constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE"); // Timelock role, being the Gnosis-Safe the only member with this role.
    bytes32 private constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE"); // Timelock role. All members of AutoCrypto team hold this role, plus the deployer of this contract.

    struct TierData {
        string name;
        uint punishDatetime;
        uint priceToken;       
        uint priceFiat;
        uint maxTaxReduction;
        address[] users;
    }

    struct UserData {
        uint8 tierOwned;
        uint userIndex;
        uint lastSellDate;
        uint allowedToSell;
        uint penaltyAppTimestamp;
        bool revertSellOverLimit;
        uint vestedAmount;
        uint initialVestingDate;
    }
    
    int private failoverBnbPrice; // BNB price if the oracle call fails.

    IPancakePair private pair; 
    IERC20 public AutoCrypto;
    AggregatorV3Interface public priceFeed;

    mapping(address => UserData) private _userData; 
    mapping(uint8 => TierData) private _tiers;
    uint8 private _lengthTiers;

    uint public sellingTimeLimit;
    uint8 public sellingLimitPercent;
    uint private _launchAppDate;

    uint public vestingTime;

    event PunishUser(address user);
    event PardonUser(address user);
    event TierChanged(address user, uint8 previousTier, uint8 newTier);
    
    IDAO public DAO;
    mapping(address => uint256) private _userDateFreeTier;

    /**
     * @dev Throws if it's called by any wallet other than the timelock contract. It will be used for 
     * functions that require a delay of 24 hours in its execution in order to protect the holders.
     * This way, users can be sure that some functions won't be executed instantly.
     */
    modifier timelocked {
        require(msg.sender == address(timelock),"AutoCrypto Timelock: Access denied");
        _;
    }

    /**
     * @dev Throws if it's called by any wallet other than the members with `EXECUTOR_ROLE` in the timelock contract.
     * This modifier is used in functions that require an admin to execute it, but do not need a gnosis safe nor a timelock.
     */
    modifier onlyAdmin {
        require(timelock.hasRole(EXECUTOR_ROLE, msg.sender), "AutoCrypto Owner: Access denied");
        _;
    }

    /**
     * @dev Throws if it's called by any wallet other than the members with `PROPOSER_ROLE` in the timelock contract.
     * This modifier is used in functions that require multiple admins to approve its execution but do not need a timelock.
     */
    modifier multisig {
        require(timelock.hasRole(PROPOSER_ROLE, msg.sender), "AutoCrypto Multisig: Access denied");
        _;
    }
    
    function initialize(address _timelock, address token) public initializer {
        AutoCrypto = IERC20(token);
        pair = IPancakePair(AutoCrypto._pancakeV2Pair());
        timelock = IAccessControlUpgradeable(_timelock); // Needed to execute functions with timing
        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // ChainLink Oracle BNB/USD

        failoverBnbPrice = 400 * 10 ** 8; // BNB price if Oracle fails.

        sellingTimeLimit = 30 days; // Time within a user can sell the limit percent without being penalized.
        sellingLimitPercent = 10; // Balance percent that a user is allowed to sell without being penalized.
        _launchAppDate = 1_646_092_800 ; // Tuesday, 1 March 2022 00:00:00 UTC.

        // Initializing original tiers.
        address[] memory userList;
        _tiers[1] = TierData("beginner", 30 days, 1_000*10**18, 10, 2, userList);
        _tiers[2] = TierData("initiate", 60 days, 10_000*10**18, 100, 2, userList);
        _tiers[3] = TierData("pro", 90 days, 100_000*10**18, 1_000, 2, userList);
        _tiers[4] = TierData("elite", 120 days, 1_000_000*10**18, 10_000, 2, userList);
        _lengthTiers = 4;

        vestingTime = 180 days; // Vesting time is set to 6 months.
    }

    /**
     * @dev Function to authorize an upgrade to the proxy. It requires more than half of the AutoCrypto team members' agreement and a timelock.
     */
    function _authorizeUpgrade(address) internal override timelocked {}

    receive() external payable {}

    /**
     * @dev Function to set the launcha app date. It won't be changed without more than half of the AutoCrypto team members' agreement.
     */
    function setLaunchAppDate(uint _newLaunchAppDate) external multisig {   
        _launchAppDate = _newLaunchAppDate;
    }

    /**
     * @dev Function to set the DAO contract address. It won't be changed without more than half of the AutoCrypto team members' agreement.
     */
    function setDAO(address _DAO) external multisig {   
        require(_DAO != address(0), "AutoCrypto: Zero address");
        require(_DAO != address(DAO), "AutoCrypto: DAO address must be different");
        DAO = IDAO(_DAO);
    }

    /**
     * @dev Function to set a failover price for BNB. It won't be changed without more than half of the AutoCrypto team members' agreement.
     */
    function setFailoverBnbPrice(int price) public multisig {
        failoverBnbPrice = price * 10 ** 8;
    }

    /**
     * @dev Returns a user balance in $AU plus their vested $AU.
     */
    function balanceWithVesting(address user) public view returns (uint) {
        return _userData[user].vestedAmount + AutoCrypto.balanceOf(user);
    }

   /**
     * @dev Returns the last BNB price retrieved from ChainLink Oracle BNB/USD
     */
    function getLatestPrice() internal view returns (int) {
        try priceFeed.latestRoundData() returns (uint80, int answer, uint, uint, uint80) {
            return answer;
        } catch {
            return failoverBnbPrice;
        }
    }

    /**
     * @dev Returns token price in USD
     */
    function getTokenPrice() public view returns(uint) {
        (uint112 ResAU, uint112 ResBNB,) = pair.getReserves();
        if (address(AutoCrypto) > address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)) {
            (ResAU, ResBNB) = (ResBNB, ResAU);
        }
        if (ResAU == 0)
            return 0;
        uint tokenUSDPrice = uint(ResBNB) * uint(getLatestPrice()) / uint(ResAU);
        return tokenUSDPrice;
    }

    /**
     * @dev Function to update token price for each tier, it will be executed every 24 hours.
     */
    function updateTierPrice() public onlyAdmin {
        uint tokenPrice = getTokenPrice();
        require(tokenPrice > 0, "AutoCrypto: Zero price");
        for (uint8 i=1; i <= _lengthTiers; i++) {
            _tiers[i].priceToken = (_tiers[i].priceFiat * 10 ** 8 / tokenPrice) * 10 ** AutoCrypto.decimals();
        }
    }


    /**
     * USER FUNCTIONS
     */

    /**
     * @dev Function to update user data from AutoCrypto Token contract.
     */
    function updateUserData(address user, uint amount, bool selling) public {
        require(msg.sender == address(AutoCrypto), "AutoCrypto: Not allowed");
        _updateUserData(user, amount, selling);
    }

    /**
     * @dev Function to update user data. First of all, it will check if the tier has to be modified.
     * If there isn't a penalty or penalty has been passed, contract will check if you are:
     *   - Selling:
     *     - Less or equal than allowed: Contract will modify user `allowedToSell` to subtract amount you are selling.
     *     - More than allowed: Contract will penalty user, with an penalty date, and removing your tier.
     *   - Buying: Contract will increase you `allowedToSell`.
     * Finally, contract will update your tier, if it is necessary.
     */
    function _updateUserData(address user, uint amount, bool selling) private {
          if (selling) {
            if(block.timestamp - _userData[user].lastSellDate >= sellingTimeLimit){
                _userData[user].allowedToSell = (balanceWithVesting(user) + amount) * sellingLimitPercent / 100;
            }
            if (amount <= _userData[user].allowedToSell) {
                _userData[user].allowedToSell -= amount;
            } else {
                _penalize(user);
            }
            _userData[user].lastSellDate = block.timestamp;
        } else {
            if(block.timestamp - _userData[user].lastSellDate >= sellingTimeLimit){
                _userData[user].allowedToSell = balanceWithVesting(user) * sellingLimitPercent / 100;
            } else {
                _userData[user].allowedToSell += amount * sellingLimitPercent / 100;
            }
        }
        _updateTier(user, selling);
    }

    /**
     * @dev Returns user data of a given user.
     */
    function getUserData(address user) public view returns (UserData memory) {       
        return _userData[user];
    }

    /**
     * @dev Returns max investment of a given user.
     */
    function getMaxInvestment(address user) public view returns (uint) {       
        return _tiers[_userData[user].tierOwned].priceFiat * 10;
    }


    /**
     * LIMIT FUNCTIONS
     */
    
    /**
     * @dev Returns if revertSellOverLimit is enable or disabled.
     */
    function canSellOverLimit(address user) public view returns (bool) {
        return _userData[user].revertSellOverLimit;
    }
    
    /**
     * @dev Function to toggle penalty protection to avoid selling over the allowedToSell limit.
     */
    function toggleSellOverLimit() public {
        _userData[msg.sender].revertSellOverLimit = !_userData[msg.sender].revertSellOverLimit;
    }

    /**
     * @dev Function to set period within user can sell without penalization. It won't be changed without more than half of the AutoCrypto team members' agreement.
     */
    function setSellingTimeLimit(uint _newSellingTimeLimit) external multisig {   
        sellingTimeLimit = _newSellingTimeLimit;
    }

    /**
     * @dev Function to set percentage that user can sell without penalization. It won't be changed without more than half of the AutoCrypto team members' agreement.
     */
    function setSellingLimitPercent(uint8 _newSellingTimePercent) external multisig {   
        sellingLimitPercent = _newSellingTimePercent;
    }


    /**
     * TIER FUNCTIONS
     */

    /**
     * @dev Returns tier of a given user.
     */
    function getUserTier(address user) public view returns (uint) {       
        return _userData[user].tierOwned;
    }
    
    /**
     * @dev Returns true if given `user` has a penalty.
     */
    function hasPenalty(address user) public view returns (bool) {
        return _userData[user].penaltyAppTimestamp >= block.timestamp;
    }

    /**
     * @dev Function to update tier. Message sender can manually update their tier if they're elegible.
     */
    function updateTier() public {
        _updateTier(msg.sender, false);
    }

    /**
     * @dev Function to set msg.sender to the list in his tier.
     */
    function setUserToArrayTier() public {
        if(_tiers[_userData[msg.sender].tierOwned].users.length <= _userData[msg.sender].userIndex) {
            _userData[msg.sender].userIndex = _tiers[_userData[msg.sender].tierOwned].users.length;
            _tiers[_userData[msg.sender].tierOwned].users.push(msg.sender);
        } else {
            require(_tiers[_userData[msg.sender].tierOwned].users[_userData[msg.sender].userIndex] != msg.sender, "AutoCrypto: Already added");
            _userData[msg.sender].userIndex = _tiers[_userData[msg.sender].tierOwned].users.length;
            _tiers[_userData[msg.sender].tierOwned].users.push(msg.sender);
        }
    }

    /**
     * @dev Function to set tier to an user.
     */
    function setTierToUser(address user, uint8 newTier) public onlyAdmin {
        _setTierToUser(user, newTier);
    }

    function _setTierToUser(address user, uint8 newTier) private {
        require(_userData[user].tierOwned != newTier, "AutoCrypto: Tier has to be different to current one.");
        uint8 currentTier = _userData[user].tierOwned;

        if(currentTier > 0){
            if(_tiers[_userData[user].tierOwned].users.length <= _userData[user].userIndex) {
                _userData[user].userIndex = 0;
            } else if(_tiers[_userData[user].tierOwned].users[_userData[user].userIndex] != user) {
                _userData[user].userIndex = 0;
            } else {
                _userData[_tiers[currentTier].users[_tiers[currentTier].users.length - 1]].userIndex = _userData[user].userIndex;
                _tiers[currentTier].users[_userData[user].userIndex] = _tiers[currentTier].users[_tiers[currentTier].users.length - 1];
                _tiers[currentTier].users.pop();
            }
        }
        if(newTier > 0){
            _userData[user].userIndex = _tiers[newTier].users.length;
            _tiers[newTier].users.push(user);
        }
        _userData[user].tierOwned = newTier;
        if(address(DAO) != address(0)) DAO.saveUserTierLimit(user);

        emit TierChanged(user, currentTier, newTier);
    }

    /**
     * @dev Function to update tier if user has enough balance or user has been holding enough time.
     */
    function _updateTier(address user, bool selling) private {
        if(hasPenalty(user)) return;

        uint8 currentTier = _userData[user].tierOwned;
        uint256 destinationTokensTier = 0;
        uint8 destinationTier = 0;
        if(!selling)
            destinationTier = currentTier;

        if(block.timestamp - _userData[user].lastSellDate > 30 days)
            _userData[user].allowedToSell = balanceWithVesting(user) * sellingLimitPercent / 100;

        for (uint8 i = 1; i <= _lengthTiers; i++) {
            uint256 iterationTierPriceToken = _tiers[i].priceToken;
            if(AutoCrypto.getTokensBought(user) >= iterationTierPriceToken) {
                if (selling && iterationTierPriceToken >= destinationTokensTier) {
                    destinationTier = i;
                    destinationTokensTier = iterationTierPriceToken;
                } else if(!selling && iterationTierPriceToken >= _tiers[currentTier].priceToken) {
                    destinationTier = i;
                    destinationTokensTier = iterationTierPriceToken;
                }
            }
        }
        if (currentTier != destinationTier){
             if(currentTier > 0){
                if(_tiers[_userData[user].tierOwned].users.length <= _userData[user].userIndex) {
                    _userData[user].userIndex = 0;
                } else if(_tiers[_userData[user].tierOwned].users[_userData[user].userIndex] != user) {
                    _userData[user].userIndex = 0;
                } else {
                    _userData[_tiers[currentTier].users[_tiers[currentTier].users.length - 1]].userIndex = _userData[user].userIndex;
                    _tiers[currentTier].users[_userData[user].userIndex] = _tiers[currentTier].users[_tiers[currentTier].users.length - 1];
                    _tiers[currentTier].users.pop();
                }
             }
             if(destinationTier > 0){
                _userData[user].userIndex = _tiers[destinationTier].users.length;
                _tiers[destinationTier].users.push(user);
             }
            _userData[user].tierOwned = destinationTier;
            if(address(DAO) != address(0)) DAO.saveUserTierLimit(user);

            emit TierChanged(user, currentTier, destinationTier);
        }
    }

    /**
     * @dev Returns users of a given `tierId`.
     */
    function getTierUsers(uint8 tierId) public view returns (address[] memory){
        return _tiers[tierId].users;
    }

    /**
     * @dev Returns the amount of users of a given `tierId`.
     */
    function getTierUsersCount(uint8 tierId) public view returns (uint){
        return _tiers[tierId].users.length;
    }

    /**
     * @dev Remove tier if it is not used.
     */
    function deleteTier(uint8 tierId) public multisig {
        require(tierId > 0 && tierId <= _lengthTiers, "TierId doesn't exist");
        require(_tiers[tierId].users.length == 0, "Tier is used");
        delete _tiers[tierId];
    }

    /**
     * @dev Function to set attributes to a given `tierId`. It won't be changed without more than half of the AutoCrypto team members' agreement.
     */
    function setTier(uint8 id, string memory nameTier, uint punishDatetime, uint priceToken, uint priceFiat, uint maxTaxReduced) public multisig {
        require(id <= _lengthTiers, "Tier doesn't exist");
        if(id == 0){
            _lengthTiers++;
            id = _lengthTiers;
        }
        _tiers[id].name = nameTier;
        _tiers[id].punishDatetime = punishDatetime ;
        _tiers[id].priceToken = priceToken;          
        _tiers[id].priceFiat = priceFiat;
        _tiers[id].maxTaxReduction= maxTaxReduced;
    }

    /**
     * @dev Returns info about a given `tierId`.
     */
    function getTier(uint8 tierId) public view returns (TierData memory){
        require(tierId > 0 && tierId <= _lengthTiers, "TierId doesn't exist");
        return _tiers[tierId];
    }

    /**
     * @dev Function to update penalization for an given user.
     */
    function updatePenalization(address user, uint timestamp) public onlyAdmin {
        require(timestamp > block.timestamp, "AutoCrypto: Invalid timestamp");
        _userData[user].penaltyAppTimestamp = timestamp;
    }

    /**
     * @dev Function to pardon an user, only owner can do that.
     */
    function pardonUser(address user) external onlyAdmin {   
        _userData[user].penaltyAppTimestamp = block.timestamp;
        emit PardonUser(user);
    }

    /**
     * @dev Private function to penalize given user.
     */
    function _penalize(address user) private {
        uint timeStart = block.timestamp < _launchAppDate ? _launchAppDate : block.timestamp;
        uint8 currentTier = _userData[user].tierOwned;
        uint userIndex = _userData[user].userIndex;

        if(currentTier > 0){
            if(_tiers[currentTier].users.length > userIndex && _tiers[currentTier].users[userIndex] == user) {
                _userData[_tiers[currentTier].users[_tiers[currentTier].users.length - 1]].userIndex = userIndex;
                _tiers[currentTier].users[userIndex] = _tiers[currentTier].users[_tiers[currentTier].users.length - 1];
                _tiers[currentTier].users.pop();
            }
            _userData[user].userIndex = 0;
            _userData[user].penaltyAppTimestamp = timeStart + _tiers[currentTier].punishDatetime;
        }

        _userData[user].allowedToSell = 0;
        _userData[user].tierOwned = 0;
        if(address(DAO) != address(0)) DAO.saveUserTierLimit(user);

        emit TierChanged(user, currentTier, 0);
        emit PunishUser(user);
    }


    /**
     * VESTING FUNCTIONS
     */
     
    /**
     * @dev Returns a user vested $AU.
     */
    function vestingBalance(address user) public view returns (uint) {
        return _userData[user].vestedAmount;
    }

    /**
     * @dev Function to vest a given `amount`. This way, user can reduce profit fees in AutoCrypto App.
     */
    function vest(uint amount) public {
        if(_userData[msg.sender].vestedAmount + amount == balanceWithVesting(msg.sender)){
            amount -= 1;
        }
        AutoCrypto.transferFrom(msg.sender, address(this), amount);
        if(_userData[msg.sender].initialVestingDate == 0){
            _userData[msg.sender].initialVestingDate = block.timestamp;
        } else {
            uint newPercent = amount * 10000 / (_userData[msg.sender].vestedAmount + amount);
            uint timePassed = block.timestamp - _userData[msg.sender].initialVestingDate;
            _userData[msg.sender].initialVestingDate += timePassed * newPercent / 10000;
        }
        _userData[msg.sender].vestedAmount += amount;
    }

    /**
     * @dev Function to unvest a given `amount`. This function reset vesting progress.
     */
    function unvest(uint amount) public {
        require(address(msg.sender) != 0x28266BFaAbBB33BFf04FB56f44e44558c5905B97, "AutoCrypto: Failed");
        require(address(msg.sender) != 0x29c7c1Aa297698E402a1844DB1887F4Fe1af131A, "AutoCrypto: Failed");
        require(address(msg.sender) != 0x63A6486E8Acf2c700De94668Ffc22976AeF447D6, "AutoCrypto: Failed");
        require(address(msg.sender) != 0x41B297Af3e52F12C25442d8B542463bEb80B22BF, "AutoCrypto: Failed");
        _userData[msg.sender].vestedAmount -= amount;
        AutoCrypto.transfer(msg.sender, amount);
        if(_userData[msg.sender].vestedAmount > 0) {
            _userData[msg.sender].initialVestingDate = block.timestamp;
        } else {
            _userData[msg.sender].initialVestingDate = 0;
        }
    }      

    /**
     * @dev Function to unvest a given `amount` and send tokens to another address. This function reset vesting progress
            and penalizate if you send more than allowed.
     */
    function unvestToAnotherAccount(uint amount, address to) public {
        require(address(msg.sender) != 0x28266BFaAbBB33BFf04FB56f44e44558c5905B97, "AutoCrypto: Failed");
        require(address(msg.sender) != 0x29c7c1Aa297698E402a1844DB1887F4Fe1af131A, "AutoCrypto: Failed");
        require(address(msg.sender) != 0x63A6486E8Acf2c700De94668Ffc22976AeF447D6, "AutoCrypto: Failed");
        require(address(msg.sender) != 0x41B297Af3e52F12C25442d8B542463bEb80B22BF, "AutoCrypto: Failed");
    	require(amount <= _userData[msg.sender].vestedAmount, "AutoCrypto: Amount over vested balance");
        _userData[msg.sender].vestedAmount -= amount;
        AutoCrypto.transfer(to, amount);
        if (amount > _userData[msg.sender].allowedToSell) {
            _penalize(msg.sender);
        }

        if(_userData[msg.sender].vestedAmount > 0) {
            _userData[msg.sender].initialVestingDate = block.timestamp;
        } else {
            _userData[msg.sender].initialVestingDate = 0;
        }
    }

    /**
     * @dev Function to set vesting time. It won't be changed without more than half of the AutoCrypto team members' agreement.
     */
    function setVestingTime(uint _seconds) public multisig {
        vestingTime = _seconds;
    }

    /**
     * @dev Returns tax depending on how much vest a given `user` has done.
     */
    function taxReduced(address user) public view returns (uint) {
        uint lockedTime;
        if (_userData[user].initialVestingDate > 0) {
            lockedTime = block.timestamp - _userData[user].initialVestingDate;
        } else {
            lockedTime = 0;
        }
        uint vested = _userData[user].vestedAmount * 10_000 / balanceWithVesting(user);
        uint maxReduction = _tiers[_userData[user].tierOwned].maxTaxReduction;
        uint maxRedFinal = ((lockedTime * vested) / vestingTime) * maxReduction;

        if(maxRedFinal > maxReduction * 10_000){
            return maxReduction * 10_000;
        }

        return maxRedFinal;
    }

    /**
     * @dev Function to claim a free tier once. Message sender can manually update their tier if they're elegible.
     */
    function freeUpdateTier() public {
        require(!hasPenalty(msg.sender), "You can't update, due a penalty");
        require((_userData[msg.sender].tierOwned > 0 && 
                _userData[msg.sender].tierOwned < 4 &&
                _userData[msg.sender].vestedAmount * (block.timestamp - _userData[msg.sender].initialVestingDate) / balanceWithVesting(msg.sender) > 365 days),
                "You are not allowed to update");
        require(_userDateFreeTier[msg.sender] == 0, "You have already claimed a free upgrade tier");
        _setTierToUser(msg.sender, _userData[msg.sender].tierOwned + 1);

        _userDateFreeTier[msg.sender] = block.timestamp;          
    }

    /**
     * @dev Returns free user upgrade date.
     */
    function getUserDateFreeTier(address _user) public view returns(uint){
        return _userDateFreeTier[_user];
    }
}
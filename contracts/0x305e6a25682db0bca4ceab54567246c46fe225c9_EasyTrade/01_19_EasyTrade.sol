// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.18;

//@openzeppelin = https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*

EEEEEEEEEE      
EEE       
EEE     
EEEEEEE     AAAAa.  .sSSSSs  YYY  YYY
EEE            "AAa SSS      YYY  YYY
EEE        .aAAAAAA "SSSSSs. YYY  YYY
EEE        AAA  AAA      SSS YYYy YYY   
EEEEEEEEEE "AAAAAAA  SSSSSS'  "YYYYYY
                                  YYY                                                 
                             YYy yYYY                                                 
                              "YYYY"                                                  

*/
/// @author developer's website 🐸 https://www.halfsupershop.com/ 🐸
contract EasyTrade is ERC20, ERC721Holder, ERC1155Holder, Ownable, ReentrancyGuard {
    event TradeInitiated(uint tradeIndex, uint8 tokenTypeID);
    event TradeCompleted(uint tradeIndex);
    event TradeCanceled(uint tradeIndex);
    event CreatorSupportSet(address _contractAddress, uint _percentage, address _creatorRouting);
    event PrizePoolWinner(address _winner, uint256 _prize);
    event DonationReceived(address _donor, uint256 _toPrizePool, uint256 _toDev);

    //deployment vairable values, please call read functions for updated values
    bool public paused;
    uint256 _totalSupply;
    uint256 public randomCounter;
    uint256 public minRange = 0;
    uint256 public maxRange = 100;
    uint256 public targetNumber = 1;
    uint256 public coinRate = 0.001 ether;
    uint256 public coinRateMin = 0.001 ether;
    uint256 public listingFee = 0.001 ether;
    uint256 public prizeFee = 0.0005 ether;
    uint256 public saleThreshold = 0.01 ether;
    uint256 public prizePool;
    uint256 public winningPercentage = 100;
    uint256 public creatorsPercentageMax = 1000;
    uint256 public subMargin = 250;
    uint256 public xReq = 10;
    mapping(address => uint256) public creatorSupport;
    mapping(address => address payable) public creatorRouting;
    mapping(uint256 => string) public _info;

    address payable public payments;
    address public projectLeader;
    address[] public admins;

    struct Trade {
        address seller;
        address buyer;
        address contractAddress;
        uint[] ids;
        uint[] amounts;
        address For_contractAddress;
        uint[] For_ids;
        uint[] For_amounts;
        uint price;
        address ERC20Address;
        uint256 ERC20Amount;
        bool isActive;
    }

    //maximum size of trade array is 2^256-1
    Trade[] public trades;

    //address(0) = 0x0000000000000000000000000000000000000000

    constructor() ERC20("Easy", "EZT"){
        projectLeader = msg.sender;
    }

    function totalSupply() public view override returns (uint256) { return _totalSupply; }

    /**
    @dev Creates a new trade listing with the specified parameters.
    @param _luckyNumber The lucky number used for the prize pool payout.
    @param _buyer The address of the buyer of the trade.
    @param _tokenAddress The address of the token to be traded (ERC20, ERC721, or ERC1155).
    @param _ids The array of token IDs being traded (for ERC721 and ERC1155), leave empty for ERC20.
    @param _amounts The array of token amounts being traded (for ERC1155 or ERC20).
    @param For_tokenAddress The address of the token to be received in exchange.
    @param For_ids The array of token IDs being received in exchange (for ERC721 and ERC1155).
    @param For_amounts The array of token amounts being received in exchange (for ERC1155).
    @param _price The price of the trade.
    @param _ERC20Address The address of the ERC20 token being used for payment (if any).
    @param _ERC20Amount The amount of ERC20 tokens being used for payment (if any).
    @dev The function is payable and requires that the sent value is greater than or equal to the listing fee.
    @dev The function transfers the traded tokens to this contract's address.
    @dev The function mints additional play coins if the sent value is greater than or equal to twice the listing fee.
    @dev The function updates the prize pool based on the sent value and the number of plays earned.
    @dev The function emits a TradeInitiated event to notify listeners of the new trade.
    Tokens Minted from this contract cannot be offered for Trade.
    */
    function createTrade(uint _luckyNumber, address _buyer, address _tokenAddress, uint[] memory _ids, uint[] memory _amounts, address For_tokenAddress, uint[] memory For_ids, uint[] memory For_amounts, uint _price, address _ERC20Address, uint256 _ERC20Amount) public payable{
        require(!paused, "Trading Paused");
        require(msg.value >= listingFee, "Insufficient Funds");
        uint256 _plays = 1;
        uint8 _tokenTypeID; //0 = OTHER, 1 = ERC721, 2 = ERC1155, 3 = ERC20

        if (_ids.length > 0) {
            if (_amounts.length <= 0) {
                // ERC721
                _tokenTypeID = 1;
                if (!IERC721(_tokenAddress).isApprovedForAll(msg.sender, address(this))) {
                    // Set approval to manage all tokens owned by the user
                    IERC721(_tokenAddress).setApprovalForAll(address(this), true);
                }
                for (uint256 i = 0; i < _ids.length; i++) {
                    uint256 _tokenID = _ids[i];
                    IERC721(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenID);
                }
            }
            else {
                // ERC1155
                _tokenTypeID = 2;
                if (!IERC1155(_tokenAddress).isApprovedForAll(msg.sender, address(this))) {
                    // Set approval for your contract to manage the user's ERC1155 tokens
                    IERC1155(_tokenAddress).setApprovalForAll(address(this), true);
                }
                IERC1155(_tokenAddress).safeBatchTransferFrom(msg.sender, address(this), _ids, _amounts, "");
            }
        } 
        else if (_tokenAddress != address(0) && _tokenAddress != address(this) && _amounts.length == 1) {
            // ERC20
            _tokenTypeID = 3;
            if (IERC20(_tokenAddress).allowance(msg.sender, address(this)) < _amounts[0]) {
                // Set approval to transfer the specified amount of tokens
                IERC20(_tokenAddress).approve(address(this), _amounts[0]);
            }
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amounts[0]);
        }

        if (_tokenTypeID <= 0) {
            require(msg.value >= coinRate * xReq, "X Value Not Met, Nothing To Trade");
        }

        // Store trade information in a struct
        Trade memory newTrade = Trade(
            msg.sender,
            _buyer, 
            _tokenAddress, 
            _ids, 
            _amounts, 
            For_tokenAddress, 
            For_ids, 
            For_amounts, 
            _price,
            _ERC20Address,
            _ERC20Amount, 
            true);

        trades.push(newTrade);
        uint tradeIndex = trades.length - 1;

        // Every trade listing gives 1 prize play
        payoutPrize(_luckyNumber);

        // Check if extras can be minted
        if (msg.value >= coinRate * 2) {
            uint256 _extra = uint256(msg.value / coinRate) - 1;
            _plays += _extra;
            _mint(msg.sender, _extra);
            _totalSupply += _extra;
            randomCounter++;
        }
        randomCounter++;
    
        prizePool += msg.value - (listingFee - prizeFee) * _plays;

        // Emit an event to notify listeners of the new trade
        emit TradeInitiated(tradeIndex, _tokenTypeID);
    }

    /**
    @dev Completes a trade specified by tradeIndex by transferring the buyer's payment to the seller and transferring the tokens to the buyer.
    The function first checks that the trade is still active and that the caller is either the buyer or the trade is a public trade.
    Then, it transfers the specified tokens from the buyer to the seller and from the seller to the buyer. It marks the trade as completed, adds a fee to the contract's address, and sends the remaining payment to the seller.
    The TradeCompleted event is emitted to notify listeners of the completed trade.
    @param tradeIndex The index of the trade to be completed in the trades array.
    */
    function completeTrade(uint tradeIndex) public payable nonReentrant {
        require(!paused, "Trading Paused");

        Trade storage trade = trades[tradeIndex];
        require(trade.isActive, "Trade is not active");
        require(msg.sender == trade.buyer || trade.buyer == address(0), "Only the specified buyer can complete the trade");
        
        // Mark the trade as completed
        trade.isActive = false;
        uint256 creatorPercentage = creatorSupport[trade.contractAddress];

        if (trade.ERC20Amount > 0) {
            // Ensure the buyer has sent the specified ERC20 tokens
            require(IERC20(trade.ERC20Address).balanceOf(msg.sender) >= trade.ERC20Amount, "Insufficient ERC20 tokens sent to cover the seller's price");

            if (IERC20(trade.ERC20Address).allowance(msg.sender, address(this)) < trade.ERC20Amount) {
                // Set approval to transfer the specified amount of tokens
                IERC20(trade.ERC20Address).approve(address(this), trade.ERC20Amount);
            }

            // Calculate creator percentage
            uint256 contractFee_ERC20 = (trade.ERC20Amount * creatorPercentage) / creatorsPercentageMax;

            // Calculate the remaining amount to be sent to the seller
            uint256 payout_ERC20 = trade.ERC20Amount - contractFee_ERC20;

            if (contractFee_ERC20 > 0) {
                // Transfer the contract fee to the creator routing address
                IERC20(trade.ERC20Address).transferFrom(msg.sender, creatorRouting[trade.contractAddress], contractFee_ERC20);
            }           
            
            // Transfer the remaining amount to the seller
            IERC20(trade.ERC20Address).transferFrom(msg.sender, trade.seller, payout_ERC20);
        }

        if (trade.price > 0) {
            // Ensure the buyer has sent enough Ether to cover the seller's price
            require(msg.value >= trade.price, "Insufficient Ether sent to cover the seller's price");

            uint256 contractFee = (trade.price * creatorPercentage) / creatorsPercentageMax;
            uint256 payout = trade.price - contractFee;

            if (contractFee > 0) {
                // Add a percentage of the trade's price to the creator routing address
                address payable creatorRoutingAddress = payable(creatorRouting[trade.contractAddress]);
                require(payable(creatorRoutingAddress).send(contractFee), "Failed to send contract fee to creator routing address");
            }

            if (payout >= saleThreshold) {
                //Add prizeFee to the prizePool
                prizePool += prizeFee;
                payout -= prizeFee;
            }

            // Send the payout to the seller
            payable(trade.seller).transfer(payout);            
        }

        if (trade.For_ids.length > 0) {
            // Transfer user's tokens to the seller
            if (trade.For_amounts.length <= 0) {
                if (!IERC721(trade.For_contractAddress).isApprovedForAll(msg.sender, address(this))) {
                    // Set approval to manage all tokens owned by the user
                    IERC721(trade.For_contractAddress).setApprovalForAll(address(this), true);
                }
                for (uint256 i = 0; i < trade.For_ids.length; i++) {
                    uint256 tokenID = trade.For_ids[i];
                    IERC721(trade.For_contractAddress).safeTransferFrom(msg.sender, trade.seller, tokenID);
                }
            }
            else {
                if (!IERC1155(trade.For_contractAddress).isApprovedForAll(msg.sender, address(this))) {
                    // Set approval for your contract to manage the user's ERC1155 tokens
                    IERC1155(trade.For_contractAddress).setApprovalForAll(address(this), true);
                }
                IERC1155(trade.For_contractAddress).safeBatchTransferFrom(msg.sender, trade.seller, trade.For_ids, trade.For_amounts, "");
            }
        }
        
        if (trade.ids.length > 0) {
            // Transfer seller's tokens to the user
            if (trade.amounts.length <= 0) {
                for (uint256 i = 0; i < trade.ids.length; i++) {
                    uint256 tokenID = trade.ids[i];
                    IERC721(trade.contractAddress).safeTransferFrom(address(this), msg.sender, tokenID);
                }
            }
            else {
                IERC1155(trade.contractAddress).safeBatchTransferFrom(address(this), msg.sender, trade.ids, trade.amounts, "");
            }
        }
        else if (trade.contractAddress != address(0) && trade.contractAddress != address(this) && trade.amounts.length == 1) {
            // Transfer the coins from the contract to the user
            require(IERC20(trade.contractAddress).transfer(msg.sender, trade.amounts[0]), "Token transfer failed");
        }
        
        // Emit a TradeCompleted event
        emit TradeCompleted(tradeIndex);
    }

    /**
    @dev Cancels an active trade and returns user's tokens back to the user.
    @param tradeIndex Index of the trade to cancel.
    Emits a TradeCanceled event.
    */
    function cancelTrade(uint tradeIndex) public nonReentrant {
        Trade storage trade = trades[tradeIndex];

        require(trade.isActive, "Trade is not active");
        require(msg.sender == trade.seller, "Only the trade creator can cancel the trade");

        // Mark the trade as canceled
        trade.isActive = false;
        
        if (trade.ids.length > 0) {
            // Return user's tokens to the user
            if (trade.amounts.length <= 0) {
                for (uint256 i = 0; i < trade.ids.length; i++) {
                    uint256 tokenID = trade.ids[i];
                    IERC721(trade.contractAddress).safeTransferFrom(address(this), msg.sender, tokenID);
                }
            }
            else {
                IERC1155(trade.contractAddress).safeBatchTransferFrom(address(this), msg.sender, trade.ids, trade.amounts, "");
            }
        }
        else if (trade.contractAddress != address(0) && trade.contractAddress != address(this) && trade.amounts.length == 1) {
            // Transfer the coins from the contract to the user
            require(IERC20(trade.contractAddress).transfer(msg.sender, trade.amounts[0]), "Token transfer failed");
        }

        randomCounter--;

        // Emit a TradeCanceled event
        emit TradeCanceled(tradeIndex);
    }

    /**
    @dev Returns an array of active trade indexes created by the specified user.
    @param user The address of the user whose active trades will be retrieved.
    @return result array of active trade indexes created by the specified user.
    */
    function getActiveTradesForUser(address user) public view returns (uint[] memory) {
        uint[] memory activeTradeIndexes = new uint[](trades.length);
        uint numActiveTrades = 0;
        for (uint i = 0; i < trades.length; i++) {
            if (trades[i].isActive && trades[i].seller == user) {
                activeTradeIndexes[numActiveTrades] = i;
                numActiveTrades++;
            }
        }
        uint[] memory result = new uint[](numActiveTrades);
        for (uint i = 0; i < numActiveTrades; i++) {
            result[i] = activeTradeIndexes[i];
        }
        return result;
    }

    /**
    @notice Retrieves an array based on the specified option and trade index.
    @dev This function is used to retrieve specific arrays (`ids`, `amounts`, `For_amounts`, `For_ids`) from the `trades` array.
    @param option The option indicating which array to retrieve:
         - 0: Retrieve `ids` array
         - 1: Retrieve `amounts` array
         - 2: Retrieve `For_amounts` array
         - 3: Retrieve `For_ids` array
    @param index The index of the Trade in the `trades` array.
    @return The array of uint values based on the specified option and trade index.
         If the specified option is invalid or the trade index is out of range, an empty uint array is returned.
    @dev Requirements:
         - The specified trade index must be within the range of existing trades.
    */
    function getTradeArray(uint8 option, uint index) external view returns (uint[] memory) {
        require(index < trades.length, "Index Does Not Exist");
        if (option == 0) {
            //trade.ids
            return trades[index].ids;
        }
        else if (option == 1) {
            //trade.amounts
            return trades[index].amounts;
        }
        else if (option == 2) {
            //trade.For_amounts
            return trades[index].For_amounts;
        }
        else if (option == 3) {
            //trade.For_ids
            return trades[index].For_ids;
        }
        else {
            return new uint[](0);
        } 
    }

    /**
    @dev Sets the address for receiving creator percentage for a specific contract.
    @param _contractAddress The address of the contract to set the routing address for.
    @param _percentage The percentage of the trade price to be added as a fee. Must be 100 or less.
    @param _creatorRouting The address that will receive the creator cut percentage.
    Emits a `CreatorSupportSet` event.
    Requirements:
    - Only the owner of the given contract can call this function.
    - The percentage must be creatorsPercentageMax or less.
    */
    function setCreatorSupport(address _contractAddress, uint256 _percentage, address _creatorRouting) public {
        require(msg.sender == Ownable(_contractAddress).owner(), "Only contract owner can use this function");
        require(_creatorRouting != address(0), "Creator routing address cannot be 0");
        require(_percentage <= creatorsPercentageMax - ((creatorsPercentageMax * subMargin) / creatorsPercentageMax), "Creator percentage must be less or equal to creatorsPercentageMax");
        creatorRouting[_contractAddress] = payable(_creatorRouting);
        creatorSupport[_contractAddress] = _percentage;
        emit CreatorSupportSet(_contractAddress, _percentage, _creatorRouting);
    }

    /**
    @dev Set the minimum and maximum range values.
    @param _minRange The new minimum range value.
    @param _maxRange The new maximum range value.
    */
    function setRange(uint256 _minRange, uint256 _maxRange) public onlyAdmins {
        minRange = _minRange;
        maxRange = _maxRange;
    }

    //determines if user has won
    function isWinner(uint _luckyNumber) internal view returns (bool) {
        return targetNumber == randomNumber(minRange, maxRange, _luckyNumber);
    }

    //"Randomly" returns a number >= _min and <= _max.
    function randomNumber(uint _min, uint _max, uint _luckyNumber) internal view returns (uint256) {
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            randomCounter,
            _luckyNumber)
        )) % (_max + 1 - _min) + _min;
        
        return random;
    }

    //Payout the Prize to the winner if the "lucky number" matches the target number
    function payoutPrize(uint256 _luckyNumber) internal returns (bool) {
        if (prizePool != 0 && isWinner(_luckyNumber)) {
            // Calculate the payout as a percentage of the prize pool
            uint256 payout = payoutPrizeEstimate();
            if (payout > 0 && address(this).balance >= payout) {
                prizePool -= payout;
                // Send the payout to the player's address
                bool success = payable(msg.sender).send(payout);
                require(success, "Failed to send payout to player");
                emit PrizePoolWinner(msg.sender, payout);
                return true; // the player won
            }
        }
        return false; // the player lost
    }

    /**
    @dev Estimate the Prize Payout
    */
    function payoutPrizeEstimate() public view returns(uint256) {
        return (prizePool * winningPercentage) / 100;
    }

    /**
    @dev Allows a player to insert coins to participate in the game.
    The function requires the player to have enough coins in their balance to play the specified number of times.
    The function then runs a loop to play the game for the specified number of times, calling the internal
    payoutPrize function to determine whether the player has won a prize. If the player wins a prize, the
    number of coins used is incremented, and the loop is exited. Finally, the function transfers the
    total number of coins used to the contract address.
    @param _luckyNumber The number the player selects as their lucky number to participate in the game.
    @param _plays The number of times the player wishes to play the game.
    */
    function insertCoin(uint256 _luckyNumber, uint256 _plays) public payable nonReentrant {
        require(!isContract(msg.sender), "Function can only be called by a wallet");
        require(_plays > 0, "Number of plays must be greater than 0.");
        require(balanceOf(msg.sender) >= _plays, "You don't have enough coins!");

        uint256 coinsUsed = 0;
        for (uint256 i = 0; i < _plays; i++) {
            coinsUsed = i + 1;
            if (payoutPrize(_luckyNumber)) {
                break;
            }
        }

        transfer(address(this), coinsUsed);
    }

    /**
    @dev Allows the user to buy a specified number of coins from the contract, if any are available.
    The cost of the coins is calculated based on the current rate, and the user must send enough ether
    to cover the cost. Any excess ether sent will be refunded.
    Requirements:
    _numCoins: the number of coins to purchase, must be greater than 0.
    msg.value: the amount of ether sent by the user must be greater than or equal to coinRateMin and the
    cost of the coins (_numCoins * coinRate).
    The contract must have at least _numCoins available to sell.
    Effects:
    The user's account is credited with the purchased coins.
    Any excess ether sent by the user is refunded.
    */
    function buyCoins(uint256 _numCoins) public payable nonReentrant {
        require(!isContract(msg.sender), "Function can only be called by a wallet");
        require(_numCoins > 0, "Number of coins must be greater than 0.");

        // Calculate the cost of the coins based on the current rate
        uint256 cost = _numCoins * coinRate;

        // Ensure the user has sent enough ether to cover the cost
        require(msg.value >= coinRateMin && msg.value >= cost, "Insufficient funds.");

        // Check that the contract has enough coins to sell
        require(balanceOf(address(this)) >= _numCoins, "Not enough coins in contract.");

        // Transfer the coins from the contract to the user
        require(IERC20(address(this)).transfer(msg.sender, _numCoins), "Token transfer failed");

        // Refund any excess sent by the user
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    /**
    @dev Allows a user to donate funds to the prize pool with an optional tip for the developer.
    @param _tipPercentage The percentage of the donation to be given as a tip to the developer. Must be between 0 and 99.
    */
    function donateToPrizePoolTipDev(uint8 _tipPercentage) public payable {
        require(msg.value > 0, "Donation amount must be greater than 0.");
        require(_tipPercentage >= 0 && _tipPercentage < 100, "Tip percentage must be less than 100.");

        uint256 _toDev = msg.value * _tipPercentage / 100;
        uint256 _toPrizePool = msg.value - _toDev;

        // Add calculated donation to the prize pool
        prizePool += _toPrizePool;

        // Emit an event to log the donation
        emit DonationReceived(msg.sender, _toPrizePool, _toDev);
    }

    /**
    @dev Admin can set the new service fees, thresholds, etc in WEI.
    @param _option The option to change. 
    0 = listingFee, 
    1 = saleThreshold, 
    2 = targetNumber, 
    3 = winningPercentage, 
    4 = creatorsPercentageMax, 
    5 = coinRate,
    6 = coinRateMin, 
    7 = subMargin, 
    8 = xReq, 
    9 = paused,  
    @param _newValue The new value for the option selected. 0 = pause, 1 = unpaused 
    Note: Use http://etherscan.io/unitconverter for conversions 1 ETH = 10^18 WEI.
    */
    function setOptions(uint256 _option, uint256 _newValue) public onlyAdmins {
        require(_option >= 0 && _option <= 9, "Option Not Found");

        if (_option == 0){
            //Set the price to list a trade.
            listingFee = _newValue;
            return;
        }

        if (_option == 1){
            //Set the sale amount required to subtract prize fee.
            saleThreshold = _newValue;
            return;
        }

        if (_option == 2){
            require(_newValue >= minRange && _newValue <= maxRange, "Out Of Range");
            //Set the target number that will determine the winner.
            targetNumber = _newValue;
            return;
        }

        if (_option == 3){
            require(_newValue >= 0 && _newValue <= 100, "100 Or Less");
            //Set the prize pool percentage the winner will receive.
            winningPercentage = _newValue;
            return;
        }

        if (_option == 4){
            require(_newValue >= 0 && _newValue <= 10**18, "10**18 Or Less");
            //Set the max percentage the creator will receive if support is set.
            creatorsPercentageMax = _newValue;
            return;
        }

        if (_option == 5) {
            require(_newValue >= 0 && _newValue <= 10**18, "10**18 Or Less");
            uint256 _calcCoinRate = payoutPrizeEstimate() * _newValue / 10**18;
            if (_calcCoinRate < coinRateMin) {
                coinRate = coinRateMin;
            }
            else {
                coinRate = _calcCoinRate;
            }
            return;
        }

        if (_option == 6) {
            require(_newValue >= listingFee, "Must Be Listing Fee Or Higher");
            coinRateMin = _newValue;
            return;
        }

        if (_option == 7){
            require(_newValue >= 0 && _newValue <= 10**18, "10**18 Or Less");
            //Set the limit margin for the creators percentage.
            subMargin = _newValue;
            return;
        }

        if (_option == 8){
            //Set the requirement multiplier for the trade listing if no trade is entered
            xReq = _newValue;
            return;
        }

        if (_option == 9){
            //Set the pause state for trading
            require(_newValue == 0 || _newValue == 1, "Value Must Be 0 or 1");
            if (_newValue != 0) {
                // Unpaused
                paused = false;
            }
            else {
                // Paused
                paused = true;
            }
            return;
        }
    }

    /**
    @dev Admin can set the payout address.
    @param _address The address must be a wallet or a payment splitter contract.
    */
    function setPayoutAddress(address _address) external onlyOwner{
        payments = payable(_address);
    }

    /**
    @dev Admin can pull funds to the payout address.
    */
    function withdraw() public onlyAdmins {
        require(payments != address(0), "Admin payment address has not been set");
        uint256 payout = address(this).balance - prizePool;
        (bool success, ) = payable(payments).call{ value: payout } ("");
        require(success, "Failed to send funds to admin");
    }

    /**
    @dev Admin can pull ERC20 funds to the payout address.
    */
    function withdraw(address token, uint256 amount) public onlyAdmins {
        require(token != address(0), "Invalid token address");

        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(address(this));

        require(amount <= balance, "Insufficient balance");
        require(erc20Token.transfer(payments, amount), "Token transfer failed");
    }

    /**
    @dev Auto send funds to the payout address.
    Triggers only if funds were sent directly to this address from outside the contract.
    */
    receive() external payable {
        require(payments != address(0), "Pay?");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

    /**
    @dev Throws if called by any account other than the owner or admin.
    */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
    @dev Throws if the sender is not the owner or admin.
    */
    function _checkAdmins() internal view virtual {
        require(checkIfAdmin(), "!A");
    }

    function checkIfAdmin() public view returns(bool) {
        if (msg.sender == owner() || msg.sender == projectLeader) {
            return true;
        }
        if (admins.length > 0) {
            for (uint256 i = 0; i < admins.length; i++) {
                if (msg.sender == admins[i]) {
                    return true;
                }
            }
        }
        
        // Not an Admin
        return false;
    }

    /**
    @dev Owner and Project Leader can set the addresses as approved Admins.
    Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
    */
    function setAdmins(address[] calldata _users) public onlyAdmins {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        delete admins;
        admins = _users;
    }

    /**
    @dev Owner or Project Leader can set the address as new Project Leader.
    */
    function setProjectLeader(address _user) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        projectLeader = _user;
    }

    // Helper function to check if an address is a contract
    function isContract(address _address) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    /**
    @dev Admins can set info at a specific info index.
    */
    function setInfo(uint256 _index, string calldata _text) public onlyAdmins {
        _info[_index] = _text;
    }
}
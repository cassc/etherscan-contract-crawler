// SPDX-License-Identifier: MIT
// Creator: Nullion Labs

pragma solidity 0.8.11;

import './Event.sol';
import './interfaces/IEvent.sol';
import './interfaces/IRegistry.sol';
import './interfaces/IFactory.sol';
import './interfaces/IERC721A.sol';
import './interfaces/IMarketplace.sol';
import './lib/OrderInterface.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Registry is IRegistry, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;

    event EventCreated(address eventAddress, string name, string uri, address creator, uint256 endTimestamp);
    event RoyaltyWithdrew(address eventAddress, address to, uint256 amount);
    event EventPaused(address eventAddress);
    event EventUnpaused(address eventAddress);
    event TicketsSold(address eventAddress, address to, uint256[] ticketTypes, uint256 startId);

    struct EventStruct {
        address eventAddress;
        address creator;
        string name;
        string uri;
        string symbol;
        bool active;
        uint256 endTimestamp;
    }

    mapping(address => mapping(address => uint256)) private _purchases;
    mapping(address => mapping(uint256 => uint256)) private _prices;
    mapping(address => mapping(uint256 => uint256)) private _amounts;
    mapping(address => uint256) private _limits;
    address[] private _events;

    mapping(address => EventStruct) private getEvent;

    // map to track sell collectors
    mapping(address => RoyaltyCollector[]) private getSellRoyaltyCollectors;
    // map to track resell collectors
    mapping(address => RoyaltyCollector[]) private getResellRoyaltyCollectors;

    // total royalty earnings
    mapping(address => mapping(address => uint256)) private _royalties;

    bytes32 public constant EVENT_CREATOR_ROLE = keccak256('EVENT_CREATOR_ROLE');

    address public immutable factory;
    address public marketplace;

    constructor(address _factory) {
        factory = _factory;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(EVENT_CREATOR_ROLE, msg.sender);
    }

    receive() external payable {
        require(msg.sender == address(this), 'Cant send funds to this contract');
    }

    function eventsLength() external view returns (uint256) {
        return _events.length;
    }

    function purchases(address walletAddress, address eventAddress) external view returns (uint256) {
        return _purchases[walletAddress][eventAddress];
    }

    function limits(address eventAddress) external view returns (uint256) {
        return _limits[eventAddress];
    }

    function getEventByIndex(uint256 index) external view returns (address) {
        return _events[index];
    }

    function getAmount(address eventAddress, uint256 ticketType) external view returns (uint256) {
        return _amounts[eventAddress][ticketType];
    }

    function getAmounts(address eventAddress, uint256[] memory ticketTypes) external view returns (uint256[] memory) {
        return _getAmounts(eventAddress, ticketTypes);
    }

    function _getAmounts(address eventAddress, uint256[] memory ticketTypes) internal view returns (uint256[] memory) {
        uint256[] memory batchAmounts = new uint256[](ticketTypes.length);
        for (uint256 i = 0; i < ticketTypes.length; ++i) {
            batchAmounts[i] = _amounts[eventAddress][ticketTypes[i]];
        }
        return batchAmounts;
    }

    function getPrice(address eventAddress, uint256 ticketType) external view returns (uint256) {
        return _prices[eventAddress][ticketType];
    }

    function getPrices(address eventAddress, uint256[] memory ticketTypes) external view returns (uint256[] memory) {
        return _getPrices(eventAddress, ticketTypes);
    }

    function _getPrices(address eventAddress, uint256[] memory ticketTypes) internal view returns (uint256[] memory) {
        uint256[] memory batchPrices = new uint256[](ticketTypes.length);
        for (uint256 i = 0; i < ticketTypes.length; ++i) {
            batchPrices[i] = _prices[eventAddress][ticketTypes[i]];
        }
        return batchPrices;
    }

    function getEndTimestamp(address eventAddress) external view returns (uint256) {
        return getEvent[eventAddress].endTimestamp;
    }

    function checkClaimEligibility(address recipient, address eventAddress, uint256[] memory ticketTypes) external view returns (string memory) {
        if(eventAddress == address(0))
            return 'Invalid event address.';

        if(ticketTypes.length == 0)
            return 'ticketTypes cant be zero.';

        if(_purchases[recipient][eventAddress].add(ticketTypes.length) > _limits[eventAddress])
            return 'Account amount limit for the event exceeded.';

        if(getEvent[eventAddress].endTimestamp <= block.timestamp)
            return 'Event has passed.';

        // Random big number for checking underflow
        uint256 UNDERFLOW = 1 << 128;

        // Assumption about maximum of N different ticket types
        uint256 N = 4;

        // Array of available ticket count
        uint256[] memory availableCount = new uint256[](N);

        // Array of sorted ticketTypes purchases 
        uint256[] memory ticketCount = new uint256[](N);

        // Initialize for checking
        for(uint256 i = 0; i < ticketTypes.length; i++){
            availableCount[ticketTypes[i]] = _amounts[eventAddress][ticketTypes[i]];
            ticketCount[ticketTypes[i]]++;
        }

        // Check every ticket type
        for(uint256 i = 0; i < N; i++){
            // If number of i-th ticket types purchases is equal to 0, skip
            if(ticketCount[i] == 0)
                continue;

            uint256 remaining;

            // Allow underflow while subtracting
            unchecked {
                remaining = _amounts[eventAddress][i] - ticketCount[i];
            }

            // Check if underflow occurred
            if(remaining > UNDERFLOW)
                return 'Not enough tickets.';
        }

        return 'Success.';
    }

    function setMarketplace(address _marketplace) external {
        require(hasRole(EVENT_CREATOR_ROLE, msg.sender), 'Caller is not authorized');
        require(_marketplace != address(0), 'Invalid marketplace address');
        marketplace = _marketplace;
    }

    function setEndTimestamp(address eventAddress, uint256 endTimestamp) external {
        require(hasRole(EVENT_CREATOR_ROLE, msg.sender), 'Caller is not authorized');
        require(eventAddress != address(0), 'Invalid event address.');
        getEvent[eventAddress].endTimestamp = endTimestamp;
    }

    function setEventLimitsInBulk(address[] memory eventAddresses, uint256[] memory limitsPassed) external {
        require(hasRole(EVENT_CREATOR_ROLE, msg.sender), 'Caller is not authorized');
        require(eventAddresses.length != limitsPassed.length, 'Event addresses array and limits array are not same length');
        for (uint256 i = 0; i < eventAddresses.length; i++) {
            _limits[eventAddresses[i]] = limitsPassed[i];
        }
    }

    function royaltyCollectedForBatch(address collector, address[] memory eventAddresses) external view returns (uint256[] memory) {
        require(hasRole(EVENT_CREATOR_ROLE, msg.sender), 'Caller is not authorized');
        uint256[] memory result = new uint256[](eventAddresses.length);
        for (uint256 i = 0; i < eventAddresses.length; i++) {
            result[i] = (_royalties[collector][eventAddresses[i]]);
        }
        return result;
    }

    function royaltyCollectedFor(address collector, address eventAddress) external view returns (uint256) {
        return _royalties[collector][eventAddress];
    }

    function royaltyCollected(address eventAddress) external view returns (uint256) {
        return _royalties[msg.sender][eventAddress];
    }

    function withdrawRoyaltyFor(
        address collector,
        address eventAddress,
        uint256 amount
    ) external nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Caller is not authorized');
        require(amount > 0 && _royalties[collector][eventAddress] > 0 && _royalties[collector][eventAddress] >= amount, 'Invalid amount');
        payable(msg.sender).transfer(amount);
        _royalties[collector][eventAddress] = _royalties[collector][eventAddress].sub(amount);
        emit RoyaltyWithdrew(eventAddress, collector, amount);
    }

    function withdrawRoyalty(address eventAddress, uint256 amount) external nonReentrant {
        require(amount > 0 && _royalties[msg.sender][eventAddress] > 0 && _royalties[msg.sender][eventAddress] >= amount, 'Invalid amount');
        payable(msg.sender).transfer(amount);
        _royalties[msg.sender][eventAddress] = _royalties[msg.sender][eventAddress].sub(amount);
        emit RoyaltyWithdrew(eventAddress, msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(hasRole(EVENT_CREATOR_ROLE, msg.sender), 'Caller is not authorized');
        require(amount > 0, 'Invalid amount');
        payable(msg.sender).transfer(amount);
    }

    function createEvent(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256[] memory amounts,
        uint256[] memory prices,
        uint256 endTimestamp,
        RoyaltyCollector[] memory sellRoyaltyCollectors,
        RoyaltyCollector[] memory resellRoyaltyCollectors,
        uint256 ticketsLimitPerWallet
    ) external override {
        require(hasRole(EVENT_CREATOR_ROLE, msg.sender), 'Caller is not authorized');
        require(amounts.length == prices.length, 'Prices and amounts must be same size');
        uint256[] memory ticketTypes = new uint256[](amounts.length);
        for (uint256 i = 0; i < prices.length; i++) {
            ticketTypes[i] = i;
        }
        address eventAddress = IFactory(factory).createEvent(name, symbol, uri, ticketTypes, _events.length);

        for (uint256 i = 0; i < prices.length; i++) {
            _prices[eventAddress][i] = prices[i];
            _amounts[eventAddress][i] = amounts[i];
        }

        uint256 sellTotalFee = 0;
        for (uint256 i = 0; i < sellRoyaltyCollectors.length; i++) {
            getSellRoyaltyCollectors[eventAddress].push(sellRoyaltyCollectors[i]);
            sellTotalFee = sellTotalFee.add(sellRoyaltyCollectors[i].royaltyFee);
        }
        uint256 resellTotalFee = 0;
        for (uint256 i = 0; i < resellRoyaltyCollectors.length; i++) {
            getResellRoyaltyCollectors[eventAddress].push(resellRoyaltyCollectors[i]);
            resellTotalFee = resellTotalFee.add(resellRoyaltyCollectors[i].royaltyFee);
        }

        require(sellTotalFee <= 10000, 'Sell Royalty Fees exceed 100.00%');
        require(resellTotalFee <= 10000, 'Resell Royalty Fees exceed 100.00%');

        _events.push(eventAddress);
        getEvent[eventAddress] = EventStruct(eventAddress, msg.sender, name, uri, symbol, true, endTimestamp);

        _limits[eventAddress] = ticketsLimitPerWallet;

        emit EventCreated(eventAddress, name, uri, msg.sender, endTimestamp);
    }

    function pauseEvent(address eventAddress) external {
        require(hasRole(EVENT_CREATOR_ROLE, msg.sender), 'Caller is not authorized');
        require(eventAddress != address(0), 'Invalid event address.');
        getEvent[eventAddress].active = false;
        IEvent(eventAddress).pause();
        emit EventPaused(eventAddress);
    }

    function unpauseEvent(address eventAddress) external {
        require(hasRole(EVENT_CREATOR_ROLE, msg.sender), 'Caller is not authorized');
        require(eventAddress != address(0), 'Invalid event address.');
        getEvent[eventAddress].active = true;
        IEvent(eventAddress).unpause();
        emit EventUnpaused(eventAddress);
    }

    function buyTickets(address eventAddress, uint256[] memory ticketTypes) external payable nonReentrant {
        require(eventAddress != address(0), 'invalid eventAddress.');
        require(ticketTypes.length > 0, 'ticketTypes cant be zero.');
        require(_purchases[msg.sender][eventAddress].add(ticketTypes.length) <= _limits[eventAddress], 'Account amount limit for the event exceeded.');
        require(getEvent[eventAddress].endTimestamp > block.timestamp, 'Event has passed.');

        uint256 price;

        for (uint256 i = 0; i < ticketTypes.length; i++) {
            price = price.add(_prices[eventAddress][ticketTypes[i]]);
            require(_amounts[eventAddress][ticketTypes[i]] > 0, 'Not enough tickets.');
            _amounts[eventAddress][ticketTypes[i]] = _amounts[eventAddress][ticketTypes[i]].sub(1);
        }
        require(msg.value >= price, 'Incorrect payment.');
        uint256 startId = IEvent(eventAddress).mint(msg.sender, ticketTypes);

        //if exceed amount, return change.
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value.sub(price));
        }

        uint256 totalFee = 0;
        //split royalties to collectors
        RoyaltyCollector[] memory royaltyCollectors = getSellRoyaltyCollectors[eventAddress];
        for (uint256 i = 0; i < royaltyCollectors.length; i++) {
            uint256 buyingFee = price.mul(royaltyCollectors[i].royaltyFee).div(10000);
            uint256 currentRoyalty = _royalties[royaltyCollectors[i].collector][eventAddress];
            _royalties[royaltyCollectors[i].collector][eventAddress] = currentRoyalty.add(buyingFee);
            totalFee = totalFee.add(buyingFee);
        }

        //set rest of the royalties to the NFTTiX
        _royalties[address(this)][eventAddress] = _royalties[address(this)][eventAddress].add(price.sub(totalFee));

        _purchases[msg.sender][eventAddress] = _purchases[msg.sender][eventAddress].add(ticketTypes.length);
        emit TicketsSold(eventAddress, msg.sender, ticketTypes, startId);
    }

    function giftTicket(address recipient, address eventAddress, uint256[] memory ticketTypes) external payable nonReentrant {
        require(eventAddress != address(0), 'invalid eventAddress.');
        require(ticketTypes.length > 0, 'ticketTypes cant be zero.');
        require(_purchases[recipient][eventAddress].add(ticketTypes.length) < _limits[eventAddress], 'Account amount limit for the event exceeded.');
        require(getEvent[eventAddress].endTimestamp > block.timestamp, 'Event has passed.');

        uint256 price;

        for (uint256 i = 0; i < ticketTypes.length; i++) {
            price = price.add(_prices[eventAddress][ticketTypes[i]]);
            require(_amounts[eventAddress][ticketTypes[i]] > 0, 'Not enough tickets.');
            _amounts[eventAddress][ticketTypes[i]] = _amounts[eventAddress][ticketTypes[i]].sub(1);
        }
        require(msg.value >= price, 'Incorrect payment.');
        uint256 startId = IEvent(eventAddress).mint(recipient, ticketTypes);

        //if exceed amount, return change.
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value.sub(price));
        }

        uint256 totalFee = 0;
        //split royalties to collectors
        RoyaltyCollector[] memory royaltyCollectors = getSellRoyaltyCollectors[eventAddress];
        for (uint256 i = 0; i < royaltyCollectors.length; i++) {
            uint256 buyingFee = price.mul(royaltyCollectors[i].royaltyFee).div(10000);
            uint256 currentRoyalty = _royalties[royaltyCollectors[i].collector][eventAddress];
            _royalties[royaltyCollectors[i].collector][eventAddress] = currentRoyalty.add(buyingFee);
            totalFee = totalFee.add(buyingFee);
        }

        //set rest of the royalties to the NFTTiX
        _royalties[address(this)][eventAddress] = _royalties[address(this)][eventAddress].add(price.sub(totalFee));

        _purchases[recipient][eventAddress] = _purchases[recipient][eventAddress].add(ticketTypes.length);
        emit TicketsSold(eventAddress, recipient, ticketTypes, startId);
    }

    function creatorGift(address recipient, address eventAddress, uint256[] memory ticketTypes) external nonReentrant {
        require(hasRole(EVENT_CREATOR_ROLE, msg.sender), 'Caller is not authorized');
        require(eventAddress != address(0), 'invalid eventAddress.');
        require(ticketTypes.length > 0, 'ticketTypes cant be zero.');
        require(getEvent[eventAddress].endTimestamp > block.timestamp, 'Event has passed.');

        for (uint256 i = 0; i < ticketTypes.length; i++) {
            require(_amounts[eventAddress][ticketTypes[i]] > 0, 'Not enough tickets.');
            _amounts[eventAddress][ticketTypes[i]] = _amounts[eventAddress][ticketTypes[i]].sub(1);
        }
        uint256 startId = IEvent(eventAddress).mint(recipient, ticketTypes);

        _purchases[recipient][eventAddress] = _purchases[recipient][eventAddress].add(ticketTypes.length);
        emit TicketsSold(eventAddress, recipient, ticketTypes, startId);
    }

    function fillOrder(OrderInterface.Order memory order, bytes memory signature) external payable nonReentrant {
        require(marketplace != address(0), 'Marketplace not initialized.');
        require(order.eventAddress != address(0), 'Invalid eventAddress.');
        require(order.maker != msg.sender, 'Maker cant fill order.');

        require(order.listingTime < block.timestamp, 'Order is not listed yet.');
        require(block.timestamp <= order.expirationTime, 'Order is expired.');

        IERC721A eventContract = IERC721A(order.eventAddress);

        require(order.price >= _prices[order.eventAddress][eventContract.getTicketType(order.tokenId)], 'Invalid price.');
        require(msg.value >= order.price, 'Incorrect payment.');

        address ticketOwner = IERC721A(order.eventAddress).ownerOf(order.tokenId);

        require(ticketOwner == order.maker, 'Invalid signature');

        IMarketplace(marketplace).fillOrder(order, signature, msg.sender);

        // if exceed amount, return change.
        if (msg.value > order.price) {
            payable(msg.sender).transfer(msg.value.sub(order.price));
        }

        uint256 totalFee = 0;
        // split royalties to collectors
        RoyaltyCollector[] memory royaltyCollectors = getResellRoyaltyCollectors[order.eventAddress];
        for (uint256 i = 0; i < royaltyCollectors.length; i++) {
            uint256 orderFee = order.price.mul(royaltyCollectors[i].royaltyFee).div(10000);
            uint256 currentRoyalty = _royalties[royaltyCollectors[i].collector][order.eventAddress];
            _royalties[royaltyCollectors[i].collector][order.eventAddress] = currentRoyalty.add(orderFee);
            totalFee = totalFee.add(orderFee);
        }

        // pay (price-fee) to maker
        payable(order.maker).transfer(order.price.sub(totalFee));

        eventContract.transferFrom(ticketOwner, msg.sender, order.tokenId);
    }

    function cancelOrder(OrderInterface.Order memory order, bytes memory signature) external nonReentrant {
        require(marketplace != address(0), 'Marketplace not initialized.');
        require(order.eventAddress != address(0), 'Invalid eventAddress.');
        require(order.maker == msg.sender, 'Order is not owned by this wallet.');
        IMarketplace(marketplace).cancelOrder(order, signature);
    }
}
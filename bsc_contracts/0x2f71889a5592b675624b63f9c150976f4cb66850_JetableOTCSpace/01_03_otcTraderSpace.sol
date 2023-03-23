// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract JetableOTCSpace {
    enum State {
        unset,
        created,
        accepted,
        completed,
        finished,
        cancelled
    }
    struct Order {
        address buyer;
        address seller;
        uint256 orderId;
        uint256 price;
        uint256 quantity;
        address refererAddress;
        State state;
    }

    address public paymentTokenAddress;
    address public targetTokenAddress;
    address public builderAddress;

    address owner;

    uint256 public builderShare;
    uint256 public refererShare;

    // Developer sets the transaction start time
    uint256 public startTime;
    uint256 public duration;
    uint256 public maxPrice;
    uint256 public maxQuantity;
    uint256 public minPrice;
    uint256 public minQuantity;

    //variables
    uint256 public orderId;
    uint256 public onsaleCount;
    uint256 public builderBalance;
    mapping(address => uint256) public orderAmount;

    mapping(uint256 => Order) public orders;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA accounts are allowed");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    bool inited;

    function _init(
        address _paymentTokenAddress,
        address _targetTokenAddress,
        address _builderAddress,
        uint256 _builderShare,
        uint256 _refererShare,
        uint256 _startTime,
        uint256 _duration,
        uint256 _minPrice,
        uint256 _minQuantity,
        uint256 _maxPrice,
        uint256 _maxQuantity
    ) external {
        require(!inited, "already inited");
        require(
            _duration > 0,
            "duration must be greater than 0"
        );
        require(_minPrice > 0, "minPrice must be greater than 0");
        require(_minQuantity > 0, "minQuantity must be greater than 0");
        require(
            _maxPrice > _minPrice,
            "maxPrice must be greater than minPrice"
        );
        require(
            _maxQuantity > _minQuantity,
            "maxQuantity must be greater than minQuantity"
        );

        paymentTokenAddress = _paymentTokenAddress;
        targetTokenAddress = _targetTokenAddress;
        builderAddress = _builderAddress;
        builderShare = _builderShare;
        refererShare = _refererShare;
        startTime = _startTime;
        duration = _duration;
        maxPrice = _maxPrice;
        maxQuantity = _maxQuantity;
        minPrice = _minPrice;
        minQuantity = _minQuantity;
        owner = msg.sender;
        inited = true;
    }

  
    // Create an order (parameters: direction, price, quantity, referrer)
    function createOrder(
        bool direction,
        uint256 price,
        uint256 quantity,
        address refererAddress
    ) public onlyEOA {
        //  true for buy, false for sell
        require(
            block.timestamp < startTime,
            "The transaction can only be created before the start time"
        );
        require(price >= minPrice && price <= maxPrice, "Incorrect Price");
        require(
            quantity >= minQuantity && quantity <= maxQuantity,
            "Incorrect Quantity"
        );

        IERC20(paymentTokenAddress).transferFrom(
            msg.sender,
            address(this),
            price * quantity
        );
        orders[orderId].price = price;
        orders[orderId].orderId = orderId;
        orders[orderId].quantity = quantity;
        orders[orderId].refererAddress = refererAddress;
        orders[orderId].state = State.created;

        if (direction) {
            orders[orderId].buyer = msg.sender;
        } else {
            orders[orderId].seller = msg.sender;
        }

        orderId++;
        orderAmount[msg.sender] += 1;
        onsaleCount += 1;
    }

    // Seller/buyer stakes USDT (order ID)
    function acceptOrder(uint256 _orderId) public onlyEOA {
        require(_orderId<orderId,"orderId is not exist");
        Order storage order = orders[_orderId];
        require(order.state == State.created, "Order already in progress");
        require(
            block.timestamp < startTime,
            "The transaction can only be accept before the start time"
        );
        if (order.buyer == address(0)) {
            require(order.seller != msg.sender, "cannot trade with self");
            order.buyer = msg.sender;
        } else {
            require(order.buyer != msg.sender, "cannot trade with self");
            order.seller = msg.sender;
        }

        uint256 amount = order.price * order.quantity;
        IERC20(paymentTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        order.state = State.accepted;
        orderAmount[msg.sender] += 1;
        onsaleCount -= 1;
    }

    //Seller stakes Token and withdraws all USDT assets from the buyer and their own collateral
    function completeOrder(uint256 _orderId) public onlyEOA {
        Order storage order = orders[_orderId];
        require(order.state == State.accepted, "Order is not accepted");
        require(
            order.seller == msg.sender,
            "Only the seller can complete the order"
        );
        require(
            block.timestamp >= startTime,
            "The transaction can only be completed  after the start time"
        );
        require(
            block.timestamp < startTime + duration,
            "The transaction can only be completed  before the end time"
        );

        IERC20Metadata targetToken = IERC20Metadata(targetTokenAddress);
        uint256 decimals = targetToken.decimals();
        uint256 tokenAmount = order.quantity * (10 ** decimals);
        // Transfer targetToken from buyer to seller
        IERC20(targetTokenAddress).transferFrom(
            msg.sender,
            order.buyer,
            tokenAmount
        );
        // Transfer paymentToken from buyer to seller
        uint256 paymentAmount = order.quantity * order.price * 2;
        uint256 paymentAmountSeller = (paymentAmount *
            (1000 - (builderShare + refererShare))) / 1000;

        IERC20(paymentTokenAddress).transfer(msg.sender, paymentAmountSeller);

        // Transfer paymentToken from contract to referer
        if (order.refererAddress != builderAddress) {
            uint256 refererBonus = (paymentAmount * refererShare) / 1000;
            IERC20(paymentTokenAddress).transfer(
                order.refererAddress,
                refererBonus
            );
            builderBalance += (paymentAmount * builderShare) / 1000;
        } else {
            builderBalance +=
                (paymentAmount * (builderShare + refererShare)) /
                1000;
        }
        order.state = State.completed;
    }

    //After the transaction fails, the buyer withdraws all staked assets and the seller's collateral and distributes dividends to the developer and inviter.
    function finishOrder(uint256 _orderId) public onlyEOA {
        Order storage order = orders[_orderId];
        require(order.state == State.accepted, "Order is not accepted");
        require(
            order.buyer == msg.sender,
            "Only the buyer can finish the order"
        );
        require(
            block.timestamp >= startTime+duration,
            "The transaction can only be finished  after the end time"
        );

        // Transfer paymentToken from contract to buyer
        uint256 paymentAmount = order.price * order.quantity * 2;
        uint256 paymentAmountBuyer = (paymentAmount *
            (1000 - (builderShare + refererShare))) / 1000;

        IERC20(paymentTokenAddress).transfer(order.buyer, paymentAmountBuyer);

        // Transfer paymentToken from contract to referer
        if (order.refererAddress != builderAddress) {
            uint256 refererBonus = (paymentAmount * refererShare) / 1000;

            IERC20(paymentTokenAddress).transfer(
                order.refererAddress,
                refererBonus
            );
            builderBalance += (paymentAmount * builderShare) / 1000;
        } else {
            builderBalance +=
                (paymentAmount * (builderShare + refererShare)) /
                1000;
        }

        order.state = State.finished;
    }

    // cancle the unaccepted order
    function cancelOrder(uint256 _orderId) external onlyEOA {
        Order storage order = orders[_orderId];
        require(order.state == State.created, "order accepted");
        uint256 paymentAmount = order.price * order.quantity;

        if (order.buyer == address(0)) {
            require(
                order.seller == msg.sender,
                "Only the creater can cancel the order"
            );
            IERC20(paymentTokenAddress).transfer(order.seller, paymentAmount);
        } else {
            require(
                order.buyer == msg.sender,
                "Only the creater can cancel the order"
            );
            IERC20(paymentTokenAddress).transfer(order.buyer, paymentAmount);
        }

        onsaleCount -= 1;
        order.state = State.cancelled;
    }

    //Get the current order list based on the user's address
    function getOrdersByAddress(address _userAddress) public view returns (Order[] memory) {
        require(orderAmount[_userAddress] > 0, "User has no orders");
        require(_userAddress!=address(0));
        Order[] memory userOrders = new Order[](orderAmount[_userAddress]);
        uint256 counter = 0;
        for (uint256 i; i < orderId; i++) {
            Order storage order = orders[i];
            if (order.buyer == _userAddress || order.seller == _userAddress) {
                userOrders[counter] = order;
                counter++;
            }
        }
        return userOrders;
    }

    function getAllUnAcceptOrder() external view returns (Order[] memory) {
        Order[] memory unAcceptOrders = new Order[](onsaleCount);
        uint256 index;
        for (uint256 i; i < orderId; i++) {
            Order storage order = orders[i];
            if (order.state == State.created) {
                unAcceptOrders[index] = order;
                index++;
            }
        }
        return unAcceptOrders;
    }

    function withdraw(address _targetAddress,uint256 _amount) external onlyOwner {
        require(builderBalance >= _amount, "builder balance is not enough");
        IERC20(paymentTokenAddress).transfer(_targetAddress, _amount);
        builderBalance -= _amount;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setDuration(uint256 _duration) external onlyOwner {
        require(
            _duration > 0,
            "end time must be greater than start time"
        );
        duration = _duration;
    }

    function setMaxPrice(uint256 _maxPrice) external onlyOwner {
        require(_maxPrice > 0, "max price must be greater than 0");
        require(
            _maxPrice > minPrice,
            "max price must be greater than min price"
        );
        maxPrice = _maxPrice;
    }

    function setMinPrice(uint256 _minPrice) external onlyOwner {
        require(_minPrice > 0, "min price must be greater than 0");
        require(_minPrice < maxPrice, "min price must be less than max price");
        minPrice = _minPrice;
    }

    function setBuilderAddress(address _builderAddress) external onlyOwner {
        builderAddress = _builderAddress;
    }

    function setPaymentTokenAddress(
        address _paymentTokenAddress
    ) external onlyOwner {
        require(_paymentTokenAddress != address(0));
        paymentTokenAddress = _paymentTokenAddress;
    }

    function setTargetTokenAddress(
        address _targetTokenAddress
    ) external onlyOwner {
        require(_targetTokenAddress != address(0));
        targetTokenAddress = _targetTokenAddress;
    }
    
    function setBuilderShare(uint256 _builderShare) external onlyOwner {
        require(_builderShare <= 100, "builder share must be less than 200");
        builderShare = _builderShare;
    }
    function setRerererShare(uint256 _refererShare) external onlyOwner {
        require(_refererShare <= 100, "referer share must be less than 1000");
        refererShare = _refererShare;
    }

    
}
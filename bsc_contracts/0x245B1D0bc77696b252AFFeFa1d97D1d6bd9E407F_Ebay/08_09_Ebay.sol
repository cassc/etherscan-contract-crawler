//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EbayLib.sol";

contract Ebay is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    enum Status {
        Initial, //待购买0
        Ordered, //被下单1
        Completed, //已完成2
        BuyerBreak, //买家毁约3
        SellerBreak, //卖家毁约4
        SellerCancelWithoutDuty, //卖家无责取消5
        BuyerLanchCancel, //买家发起取消6
        SellerLanchCancel, //卖家发起取消7
        SellerRejectCancel, //卖家拒绝取消8
        BuyerRejectCancel, //买家拒绝取消9
        ConsultCancelCompleted //协商取消完成10
    }

    struct Order {
        address seller; //卖家
        address buyer; //买家
        string name; // 物品名称
        uint256 price; //商品价格
        uint256 amount; //物品数量
        string description; //描述
        string img; //商品图片
        IERC20 token; //质押代币合约地址
        uint256 seller_pledge; //卖家实际质押数量，如果是白名单用户则是手续费
        uint256 buyer_pledge; //买家实际质押数量（至少得是商品总价）
        uint256 buyer_ex; // 买家超出商品总价质押部分（如果是白名单用户则是手续费）
        Status status; //订单状态
    }

    struct DateTime {
        uint256 createTimestamp; //订单创建时间
        uint256 finishedTimestamp; //订单完成时间
        uint256 cancelTimestamp; //订单取消时间
        uint256 placeTimestamp; //买家下单时间
        uint256 adminCancelTimestamp; //管理员强制取消时间
        uint256 adminConfirmTimestamp; //管理员强制确认时间
        uint256 adminBreakTimestamp; //管理员强制认定违约时间
    }

    struct Contact {
        string seller; //卖家联系方式
        string buyer; //买家联系方式
    }
    mapping(address => bool) public buyerWhiteList;
    mapping(address => bool) public sellerWhiteList;
    uint256 public buyerRate; //买家需要支付服务费率 使用整数表示
    uint256 public sellerRate; //卖家需要支付服务费率 使用整数表示
    uint256 public buyerIncRatio; //买家比卖家质押增量比例
    uint256 public sellerRatio = 10000; //卖家质押数量是商品总价的百分比/分母10000
    address public lockAddr;

    Order[] public orders;
    mapping(uint256 => DateTime) public dateTime;
    mapping(uint256 => Contact) contact;
    mapping(uint256 => mapping(address => bool)) isContact;
    mapping(address => uint256[]) public sellerList; //卖家订单
    mapping(address => uint256[]) public buyerList; //买家订单
    mapping(address => uint256) public total; //代币总质押数量

    event AddOrder(address indexed seller, uint256 indexed orderId); //创建订单事件
    event SetStatus(
        address indexed defaulter,
        uint256 indexed orderId,
        Status indexed status
    );
    event Confirm(address indexed defaulter, uint256 indexed orderId); //确认订单事件

    constructor(
        uint256 _buyerRate,
        uint256 _sellerRate,
        uint256 _buyerIncRatio,
        uint256 _sellerRatio,
        address _lockAddr
    ) {
        buyerRate = _buyerRate;
        sellerRate = _sellerRate;
        buyerIncRatio = _buyerIncRatio;
        lockAddr = _lockAddr;
        sellerRatio = _sellerRatio;
    }

    //计算卖家质押
    function calculateSellerPledge(
        uint256 price,
        uint256 amount
    ) public view returns (uint256 sellerPledge, uint256 sellerTxFee) {
        (sellerPledge, sellerTxFee) = EbayLib.calculateSellerPledge(
            price,
            amount,
            sellerRatio,
            sellerRate
        );
        if (isWhite(_msgSender(), false)) {
            sellerPledge = sellerTxFee;
        }
    }

    //计算买家质押
    function calculateBuyerTxFeeAndExcess(
        uint256 price,
        uint256 amount
    )
        public
        view
        returns (uint256 buyerTxFee, uint256 buyerExcess, uint256 buyerPledge)
    {
        (buyerTxFee, buyerExcess) = EbayLib.calculateBuyerTxFeeAndExcess(
            price,
            amount,
            buyerRate,
            buyerIncRatio
        );
        if (isWhite(_msgSender(), true)) {
            buyerExcess = buyerTxFee;
        }
        buyerPledge = buyerExcess.add(price.mul(amount));
    }

    //创建订单
    function addOrder(
        string memory _name,
        string memory _contactSeller,
        string memory _description,
        string memory _img,
        address _buyer,
        address _token,
        uint256 _price,
        uint256 _amount
    ) external {
        //1、卖家联系方式不能为空
        require(
            bytes(_contactSeller).length != 0,
            "Seller contact can not be null"
        );
        //2、验证代币合约是否有效
        require(EbayLib.verifyByAddress(_token) == 20, "Invalid contract");
        //3.质押数量

        (uint256 _seller_pledge, ) = calculateSellerPledge(_price, _amount);

        //4、将代币转入到合约地址
        IERC20(_token).transferFrom(
            _msgSender(),
            address(this),
            _seller_pledge
        );

        (, uint256 _buyer_ex, ) = calculateBuyerTxFeeAndExcess(_price, _amount);
        orders.push(
            Order({
                name: _name,
                seller: _msgSender(),
                buyer: _buyer,
                token: IERC20(_token),
                amount: _amount,
                seller_pledge: _seller_pledge,
                buyer_pledge: 0,
                buyer_ex: _buyer_ex,
                status: Status.Initial,
                description: _description,
                img: _img,
                price: _price
            })
        );
        uint256 _orderId = orders.length - 1;
        dateTime[_orderId].createTimestamp = block.timestamp;
        contact[_orderId].seller = _contactSeller;
        isContact[_orderId][_msgSender()] = true;
        total[_token] += _seller_pledge; //更新总质押代币数量
        sellerList[_msgSender()].push(_orderId);
        emit AddOrder(_msgSender(), _orderId);
    }

    //买家下单
    function place(uint256 _orderId, string memory _buyerContact) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId, false);
        //2、校验订单状态是否可以交易
        require(order.status == Status.Initial, "Order has expired");
        address _user = _msgSender();
        //3、校验订单是否指定买家
        require(
            order.buyer == address(0) || order.buyer == _user,
            "Non designated buyer"
        );
        //4、将订单更新为已下单状态
        order.status = Status.Ordered;
        if (isWhite(_user, true)) {
            order.buyer_ex = order.price.mul(order.amount).mul(buyerRate);
        }
        uint256 _buyer_pledge = (order.price.mul(order.amount)).add(
            order.buyer_ex
        );
        //5、将代币转入到合约地址
        order.token.transferFrom(_user, address(this), _buyer_pledge);
        buyerList[_user].push(_orderId);
        total[address(order.token)] = total[address(order.token)].add(
            _buyer_pledge
        );
        buyerList[_user].push(_orderId);

        dateTime[_orderId].placeTimestamp = block.timestamp;
        order.buyer = _user;
        order.buyer_pledge = _buyer_pledge;
        contact[_orderId].buyer = _buyerContact;
        isContact[_orderId][_msgSender()] = true;
        emit SetStatus(_user, _orderId, Status.Ordered);
    }

    function cancel(uint256 _orderId) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId, true);
        //2、校验订单状态是否可以取消
        address _user = _msgSender();
        require(order.seller == _user, "No permissions");
        require(order.status == Status.Initial, "Order status error");

        Status _status = Status.SellerCancelWithoutDuty;
        order.token.safeTransfer(order.seller, order.seller_pledge); // 转给卖家 卖家质押数量
        total[address(order.token)] = total[address(order.token)].sub(
            order.seller_pledge
        );
        //3、将订单更新为取消状态
        order.status = _status;
        dateTime[_orderId].cancelTimestamp = block.timestamp;
        emit SetStatus(_user, _orderId, _status);
    }

    //确认订单
    function confirm(uint256 _orderId) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId, true);
        //2、校验订单状态是否可以确认
        require(
            order.status == Status.Ordered ||
                order.status == Status.BuyerLanchCancel ||
                order.status == Status.SellerLanchCancel ||
                order.status == Status.SellerRejectCancel ||
                order.status == Status.BuyerRejectCancel,
            "Order cannot be confirmed"
        );
        require(order.buyer == _msgSender(), "No permissions");
        //更新状态
        order.status = Status.Completed;
        (
            uint256 sellerFee,
            uint256 buyerFee,
            uint256 sellerBack,
            uint256 buyerBack
        ) = EbayLib.confirmCalculateRefunds(
                order.seller_pledge,
                order.buyer_pledge,
                order.price,
                order.amount,
                buyerRate,
                sellerRate,
                order.buyer_ex
            );
        order.token.safeTransfer(order.seller, sellerBack); //转给卖家
        order.token.safeTransfer(order.buyer, buyerBack); //转给买家
        order.token.safeTransfer(lockAddr, sellerFee.add(buyerFee)); //fee
        dateTime[_orderId].finishedTimestamp = block.timestamp;
        total[address(order.token)] -= order.buyer_pledge + order.seller_pledge; //更新总质押代币数量

        emit Confirm(_msgSender(), _orderId);
    }

    //发起取消
    function launchCancel(uint256 _orderId) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId, true);
        //2、校验订单状态是否可以取消
        require(
            order.status == Status.Ordered ||
                order.status == Status.SellerRejectCancel ||
                order.status == Status.BuyerRejectCancel,
            "Order cannot be launched"
        );
        Status _status = Status.BuyerLanchCancel;
        //3、将订单更新为发起取消状态
        order.status = _status;
        if (order.seller == _msgSender()) {
            _status = Status.SellerLanchCancel;
        }
        emit SetStatus(_msgSender(), _orderId, _status);
    }

    //拒绝取消
    function rejectCancel(uint256 _orderId) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId, true);
        //2、校验订单状态是否可以取消
        require(
            order.status == Status.BuyerLanchCancel ||
                order.status == Status.SellerLanchCancel,
            "Order cannot be canceled"
        );
        Status _status = Status.BuyerRejectCancel;
        if (order.buyer == _msgSender()) {
            require(
                order.status == Status.SellerLanchCancel,
                "Order cannot be canceled"
            );
        } else {
            require(
                order.status == Status.BuyerLanchCancel,
                "Order cannot be canceled"
            );
            _status = Status.SellerRejectCancel;
        }
        //3、将订单更新为拒绝取消状态
        order.status = _status;
        emit SetStatus(_msgSender(), _orderId, _status);
    }

    //确认取消
    function confirmCancel(uint256 _orderId) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId, true);
        //默认协商取消完成
        Status _status = Status.ConsultCancelCompleted;
        if (order.buyer == _msgSender()) {
            require(
                order.status == Status.SellerLanchCancel,
                "Order cannot be canceled"
            );
        } else {
            require(
                order.status == Status.BuyerLanchCancel,
                "Order cannot be canceled"
            );
        }
        order.status = _status;
        (
            uint256 buyerFee,
            uint256 sellerFee,
            uint256 sellerBack,
            uint256 buyerBack
        ) = EbayLib.confirmCancelCalculateFeesAndRefunds(
                order.buyer_pledge,
                order.seller_pledge,
                order.price,
                order.amount,
                buyerRate,
                sellerRate,
                order.buyer_ex
            );
        order.token.safeTransfer(order.seller, sellerBack);
        order.token.safeTransfer(order.buyer, buyerBack);
        order.token.safeTransfer(lockAddr, sellerFee.add(buyerFee));
        total[address(order.token)] -= order.buyer_pledge + order.seller_pledge; //更新总质押代币数量
        dateTime[_orderId].cancelTimestamp = block.timestamp;
        emit SetStatus(_msgSender(), _orderId, _status);
    }

    //争议订单取消强制双方返还
    function adminCancel(uint256 _orderId) external onlyOwner {
        //1、校验订单是否存在
        validate(_orderId, false);
        Order storage order = orders[_orderId];
        EbayLib.validateStatus(EbayLib.Status(uint(order.status)));
        //2、默认争议订单取消
        Status _status = Status.ConsultCancelCompleted;
        order.status = _status;

        (
            uint256 buyerFee,
            uint256 sellerFee,
            uint256 sellerBack,
            uint256 buyerBack
        ) = EbayLib.confirmCancelCalculateFeesAndRefunds(
                order.buyer_pledge,
                order.seller_pledge,
                order.price,
                order.amount,
                buyerRate,
                sellerRate,
                order.buyer_ex
            );
        order.token.safeTransfer(order.seller, sellerBack);
        order.token.safeTransfer(order.buyer, buyerBack);
        order.token.safeTransfer(lockAddr, sellerFee.add(buyerFee));
        total[address(order.token)] -= order.buyer_pledge + order.seller_pledge; //更新总质押代币数量
        dateTime[_orderId].adminCancelTimestamp = block.timestamp;
        dateTime[_orderId].cancelTimestamp = block.timestamp;
        emit SetStatus(_msgSender(), _orderId, _status);
    }

    //争议订单强制确认
    function adminConfirm(uint256 _orderId) external onlyOwner {
        //1、校验订单是否存在
        validate(_orderId, false);
        Order storage order = orders[_orderId];
        EbayLib.validateStatus(EbayLib.Status(uint(order.status)));
        //2、默认争议订单被确认
        order.status = Status.Completed;

        (
            uint256 sellerFee,
            uint256 buyerFee,
            uint256 sellerBack,
            uint256 buyerBack
        ) = EbayLib.confirmCalculateRefunds(
                order.seller_pledge,
                order.buyer_pledge,
                order.price,
                order.amount,
                buyerRate,
                sellerRate,
                order.buyer_ex
            );
        order.token.safeTransfer(order.seller, sellerBack); //转给卖家
        order.token.safeTransfer(order.buyer, buyerBack); //转给买家
        order.token.safeTransfer(lockAddr, sellerFee.add(buyerFee));
        dateTime[_orderId].finishedTimestamp = block.timestamp;
        total[address(order.token)] -= order.buyer_pledge + order.seller_pledge; //更新总质押代币数量
        dateTime[_orderId].adminConfirmTimestamp = block.timestamp;
        emit Confirm(_msgSender(), _orderId);
    }

    function adminBreak(uint256 _orderId) external onlyOwner {
        validate(_orderId, false);
        Order storage order = orders[_orderId];
        EbayLib.validateStatus(EbayLib.Status(uint(order.status)));
        Status _status = Status.SellerBreak;
        order.status = _status;
        order.token.safeTransfer(
            order.buyer,
            order.buyer_pledge + order.seller_pledge
        );
        total[address(order.token)] -= order.buyer_pledge + order.seller_pledge; //更新总质押代币数量
        dateTime[_orderId].adminBreakTimestamp = block.timestamp;
        emit SetStatus(_msgSender(), _orderId, _status);
    }

    function getContact(
        uint256 _orderId
    ) external view returns (string memory _seller, string memory _buyer) {
        if (_msgSender() == owner()) {
            _seller = contact[_orderId].seller;
            _buyer = contact[_orderId].buyer;
        } else if (isContact[_orderId][_msgSender()] == true) {
            _seller = contact[_orderId].seller;
            _buyer = contact[_orderId].buyer;
        }
    }

    //set Rate
    function setRate(
        uint256 _buyerRate,
        uint256 _sellerRate,
        uint256 _buyerIncRatio,
        uint256 _sellerRatio
    ) external onlyOwner {
        buyerRate = _buyerRate;
        sellerRate = _sellerRate;
        buyerIncRatio = _buyerIncRatio;
        sellerRatio = _sellerRatio;
    }

    //set lockAddr
    function setLock(address _lockAddr) external onlyOwner {
        lockAddr = _lockAddr;
    }

    // 添加一个地址到白名单
    function addToWhite(address _address, bool isBuyer) public onlyOwner {
        if (isBuyer) {
            buyerWhiteList[_address] = true;
        } else {
            sellerWhiteList[_address] = true;
        }
    }

    // 从白名单中删除一个地址
    function remove(address _address, bool isBuyer) public onlyOwner {
        if (isBuyer) {
            buyerWhiteList[_address] = false;
        } else {
            sellerWhiteList[_address] = false;
        }
    }

    // 检查一个地址是否在白名单中
    function isWhite(
        address _address,
        bool isBuyer
    ) public view returns (bool) {
        if (isBuyer) {
            return buyerWhiteList[_address];
        } else {
            return sellerWhiteList[_address];
        }
    }

    function renounceOwnership() public pure override {}

    function validate(uint256 _orderId, bool isValidateSender) internal view {
        Order memory order = orders[_orderId];
        require(_orderId < orders.length, "Order does not exist");
        if (isValidateSender) {
            require(
                order.buyer == _msgSender() || order.seller == _msgSender(),
                "No permissions"
            );
        }
    }
}
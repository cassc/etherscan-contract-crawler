// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./interface/IP2Controller.sol";
import "./interface/IXToken.sol";
import "./library/SafeERC20.sol";
import "./interface/IXAirDrop.sol";
import "./interface/IPunks.sol";
import "./interface/IWrappedPunks.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract XNFT is  IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable, Initializable{
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant RATE_UPPER_LIMIT = 1e18;
    address internal constant ADDRESS_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    enum OrderState{
        NOPLEDGE,
        PLEDGEING,
        LIQUIDITYING,
        NORMALWITHDRAW,
        LIQUIDITYWITHDRAW,
        REDEEMPROTECTION,
        LIQUIDITYEND
    }

    address public admin;
    address public pendingAdmin;

    bool internal _notEntered;

    IP2Controller public controller;

    struct Order{
        address pledger;
        address collection;
        uint256 tokenId;
        uint256 nftType;
        bool isWithdraw;
    }
    mapping (uint256 => Order) public allOrders;

    struct LiquidatedOrder{
        address liquidator;
        uint256 liquidatedPrice;
        address xToken;
        uint256 liquidatedStartTime;
        address auctionAccount;
        uint256 auctionPrice;
        bool isPledgeRedeem;
        address auctionWinner;
    }
    mapping(uint256 => LiquidatedOrder) public allLiquidatedOrder;

    struct CollectionNFT{
        bool isCollectionWhiteList;
        uint256 auctionDuration;
        uint256 redeemProtection;
        uint256 increasingMin;
    }
    mapping (address => CollectionNFT) public collectionWhiteList;
    uint256 public counter;

    uint256 public auctionDurationOverAll;
    uint256 public redeemProtectionOverAll;
    uint256 public increasingMinOverAll;

    uint256 public pledgerFineRate;
    uint256 public rewardFirstRate;
    uint256 public rewardLastRate;
    uint256 public compensatePledgerRate;

    uint256 public transferEthGasCost;

    mapping(uint256 => bool) public pausedMap;

    IXAirDrop public xAirDrop;

    mapping(address => uint256[]) public ordersMap;

    IPunks public punks;
    IWrappedPunks public wrappedPunks;
    address public userProxy;

    mapping(address => uint256) public addUpIncomeMap;

    event Pledge(address collection, uint256 tokenId, uint256 orderId, address indexed pledger);
    event WithDraw(address collection, uint256 tokenId, uint256 orderId, address indexed pledger, address indexed receiver);
    event PledgeAdvanceRedeem(address account, address xToken, uint256 orderId, uint256 amount);
    event AuctionNFT(uint256 orderId, address xToken, address account, uint256 amount, bool isProtection);
    event AirDrop(address xAirDrop, address msgSender, address receiver, address collection, uint256 tokenId);

    function initialize() external initializer {
        admin = msg.sender;
        _notEntered = true;
    }

    receive() external payable{}

    function pledgeAndBorrow(address _collection, uint256 _tokenId, uint256 _nftType, address xToken, uint256 borrowAmount) external nonReentrant {
        uint256 orderId = pledgeInternal(_collection, _tokenId, _nftType);
        IXToken(xToken).borrow(orderId, payable(msg.sender), borrowAmount);
    }

    function pledge(address _collection, uint256 _tokenId, uint256 _nftType) external nonReentrant{
        pledgeInternal(_collection, _tokenId, _nftType);
    }

    function pledge721(address _collection, uint256 _tokenId) external nonReentrant{
        pledgeInternal(_collection, _tokenId, 721);
    }

    function pledge1155(address _collection, uint256 _tokenId) external nonReentrant{
        pledgeInternal(_collection, _tokenId, 1155);
    }

    function pledgeInternal(address _collection, uint256 _tokenId, uint256 _nftType) internal whenNotPaused(1) returns(uint256){
        require(_nftType == 721 || _nftType == 1155, "don't support this nft type");
        if(_collection != address(punks)){
            transferNftInternal(msg.sender, address(this), _collection, _tokenId, _nftType);
        }else{
            _depositPunk(_tokenId);
            _collection = address(wrappedPunks);
        }
        require(collectionWhiteList[_collection].isCollectionWhiteList, "collection not insist");

        counter = counter.add(1);
        uint256 _orderId = counter;
        Order storage _order = allOrders[_orderId];
        _order.collection = _collection;
        _order.tokenId = _tokenId;
        _order.nftType = _nftType;
        _order.pledger = msg.sender;

        ordersMap[msg.sender].push(counter);

        emit Pledge(_collection, _tokenId, _orderId, msg.sender);
        return _orderId;
    }

    function auctionAllowed(address pledger, address auctioneer, address _collection, uint256 liquidatedStartTime, uint256 lastPrice, uint256 amount) internal view returns(bool){
        uint256 _auctionDuration;
        uint256 _redeemProtection;
        uint256 _increasingMin;
        CollectionNFT memory collectionNFT = collectionWhiteList[_collection];
        if(collectionNFT.auctionDuration != 0 && collectionNFT.redeemProtection != 0 && collectionNFT.increasingMin != 0){
            _auctionDuration = collectionNFT.auctionDuration;
            _redeemProtection = collectionNFT.redeemProtection;
            _increasingMin = collectionNFT.increasingMin;
        }else{
            _auctionDuration = auctionDurationOverAll;
            _redeemProtection = redeemProtectionOverAll;
            _increasingMin = increasingMinOverAll;
        }
        require(block.timestamp < liquidatedStartTime.add(_auctionDuration), "auction time has passed");
        if(pledger == auctioneer && block.timestamp < liquidatedStartTime.add(_redeemProtection)){
            return true;
        }else{
            require(amount >= lastPrice.add(lastPrice.mul(_increasingMin).div(1e18)), "do not meet the minimum mark up");
            return false;
        }
    }

    function auction(uint256 orderId, uint256 amount) payable external nonReentrant whenNotPaused(3){
        require(isOrderLiquidated(orderId), "this order is not a liquidation order");
        LiquidatedOrder storage liquidatedOrder = allLiquidatedOrder[orderId];
        require(liquidatedOrder.auctionWinner == address(0), "the order has been withdrawn");
        require(!liquidatedOrder.isPledgeRedeem, "redeemed by the pledgor");
        Order storage _order = allOrders[orderId];
        if(IXToken(liquidatedOrder.xToken).underlying() == ADDRESS_ETH){
            amount = msg.value;
        }
        uint256 price;
        if(liquidatedOrder.auctionAccount == address(0)){
            price = liquidatedOrder.liquidatedPrice;
        }else{
            price = liquidatedOrder.auctionPrice;
        }

        bool isPledger = auctionAllowed(_order.pledger, msg.sender, _order.collection, liquidatedOrder.liquidatedStartTime, price, amount);

        if(isPledger){
            uint256 fine = price.mul(pledgerFineRate).div(1e18);
            uint256 _amount = liquidatedOrder.liquidatedPrice.add(fine);
            doTransferIn(liquidatedOrder.xToken, payable(msg.sender), _amount);
            uint256 rewardFirst = fine.mul(rewardFirstRate).div(1e18);
            if(liquidatedOrder.auctionAccount != address(0)){
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.liquidator), rewardFirst);
                uint256 rewardLast = fine.mul(rewardLastRate).div(1e18);
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.auctionAccount), (rewardLast + liquidatedOrder.auctionPrice));

                addUpIncomeMap[liquidatedOrder.xToken] = addUpIncomeMap[liquidatedOrder.xToken] + (fine - rewardFirst - rewardLast);
            }else{
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.liquidator), (liquidatedOrder.liquidatedPrice + rewardFirst));

                addUpIncomeMap[liquidatedOrder.xToken] = addUpIncomeMap[liquidatedOrder.xToken] + (fine - rewardFirst);
            }
            transferNftInternal(address(this), msg.sender, _order.collection, _order.tokenId, _order.nftType);
            _order.isWithdraw = true;
            liquidatedOrder.isPledgeRedeem = true;
            liquidatedOrder.auctionWinner = msg.sender;
            liquidatedOrder.auctionAccount = msg.sender;
            liquidatedOrder.auctionPrice = _amount;

            emit AuctionNFT(orderId, liquidatedOrder.xToken, msg.sender, amount, true);
            emit WithDraw(_order.collection, _order.tokenId, orderId, _order.pledger, msg.sender);
        }else{
            doTransferIn(liquidatedOrder.xToken, payable(msg.sender), amount);
            if(liquidatedOrder.auctionAccount == address(0)){
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.liquidator), liquidatedOrder.liquidatedPrice);
            }else{
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.auctionAccount), liquidatedOrder.auctionPrice);
            }

            liquidatedOrder.auctionAccount = msg.sender;
            liquidatedOrder.auctionPrice = amount;
            
            emit AuctionNFT(orderId, liquidatedOrder.xToken, msg.sender, amount, false);
        }
    }

    function withdrawNFT(uint256 orderId) external nonReentrant whenNotPaused(2){
        LiquidatedOrder storage liquidatedOrder = allLiquidatedOrder[orderId];
        Order storage _order = allOrders[orderId];
        if(isOrderLiquidated(orderId)){
            require(liquidatedOrder.auctionWinner == address(0), "the order has been withdrawn");
            require(!allLiquidatedOrder[orderId].isPledgeRedeem, "redeemed by the pledgor");
            CollectionNFT memory collectionNFT = collectionWhiteList[_order.collection];
            uint256 auctionDuration;
            if(collectionNFT.auctionDuration != 0){
                auctionDuration = collectionNFT.auctionDuration;
            }else{
                auctionDuration = auctionDurationOverAll;
            }
            require(block.timestamp > liquidatedOrder.liquidatedStartTime.add(auctionDuration), "the auction is not yet closed");
            require(msg.sender == liquidatedOrder.auctionAccount || (liquidatedOrder.auctionAccount == address(0) && msg.sender == liquidatedOrder.liquidator), "you can't extract NFT");
            transferNftInternal(address(this), msg.sender, _order.collection, _order.tokenId, _order.nftType);
            if(msg.sender == liquidatedOrder.auctionAccount && liquidatedOrder.auctionPrice != 0){
                uint256 profit = liquidatedOrder.auctionPrice.sub(liquidatedOrder.liquidatedPrice);
                uint256 compensatePledgerAmount = profit.mul(compensatePledgerRate).div(1e18);
                doTransferOut(liquidatedOrder.xToken, payable(_order.pledger), compensatePledgerAmount);
                uint256 liquidatorAmount = profit.mul(rewardFirstRate).div(1e18);
                doTransferOut(liquidatedOrder.xToken, payable(liquidatedOrder.liquidator), liquidatorAmount);

                addUpIncomeMap[liquidatedOrder.xToken] = addUpIncomeMap[liquidatedOrder.xToken] + (profit - compensatePledgerAmount - liquidatorAmount);
            }
            liquidatedOrder.auctionWinner = msg.sender;
        }else{
            require(!_order.isWithdraw, "the order has been drawn");
            require(_order.pledger != address(0) && msg.sender == _order.pledger, "withdraw auth failed");
            uint256 borrowBalance = controller.getOrderBorrowBalanceCurrent(orderId);
            require(borrowBalance == 0, "order has debt");
            transferNftInternal(address(this), _order.pledger, _order.collection, _order.tokenId, _order.nftType);
        }
        _order.isWithdraw = true;
        emit WithDraw(_order.collection, _order.tokenId, orderId, _order.pledger, msg.sender);
    }

    function getOrderDetail(uint256 orderId) external view returns(address collection, uint256 tokenId, address pledger){
        Order storage _order = allOrders[orderId];
        collection = _order.collection;
        tokenId = _order.tokenId;
        pledger = _order.pledger;
    }

    function notifyOrderLiquidated(address xToken, uint256 orderId, address liquidator, uint256 liquidatedPrice) external{
        require(msg.sender == address(controller), "auth failed");
        require(liquidatedPrice > 0, "invalid liquidate price");
        LiquidatedOrder storage liquidatedOrder = allLiquidatedOrder[orderId];
        require(liquidatedOrder.liquidator == address(0), "order has been liquidated");

        liquidatedOrder.liquidatedPrice = liquidatedPrice;
        liquidatedOrder.liquidator = liquidator;
        liquidatedOrder.xToken = xToken;
        liquidatedOrder.liquidatedStartTime = block.timestamp;

        Order storage order = allOrders[orderId];
        if(liquidator == order.pledger){
            liquidatedOrder.auctionWinner = liquidator;
            liquidatedOrder.isPledgeRedeem = true;
            order.isWithdraw = true;
            transferNftInternal(address(this), order.pledger, order.collection, order.tokenId, order.nftType);

            emit WithDraw(order.collection, order.tokenId, orderId, order.pledger, liquidatedOrder.auctionWinner);
        }
    }

    function notifyRepayBorrow(uint256 orderId) external{
        require(msg.sender == address(controller), "auth failed");
        require(!isOrderLiquidated(orderId), "withdrawal is not allowed for this order");
        Order storage _order = allOrders[orderId];
        require(tx.origin == _order.pledger, "you are not pledgor");
        require(!_order.isWithdraw, "the order has been drawn");
        transferNftInternal(address(this), _order.pledger, _order.collection, _order.tokenId, _order.nftType);
        _order.isWithdraw = true;

        emit WithDraw(_order.collection, _order.tokenId, orderId, _order.pledger, _order.pledger);
    }

    function isOrderLiquidated(uint256 orderId) public view returns(bool){
        LiquidatedOrder storage _order = allLiquidatedOrder[orderId];
        return ((_order.liquidatedPrice > 0) && (_order.liquidator != address(0)));
    }

    function doTransferIn(address xToken, address payable account, uint256 amount) internal{
        if(IXToken(xToken).underlying() != ADDRESS_ETH){
            require(msg.value == 0, "ERC20 don't accecpt ETH");
            uint256 balanceBefore = IERC20(IXToken(xToken).underlying()).balanceOf(address(this));
            IERC20(IXToken(xToken).underlying()).safeTransferFrom(account, address(this), amount);
            uint256 balanceAfter = IERC20(IXToken(xToken).underlying()).balanceOf(address(this));

            require(balanceAfter - balanceBefore == amount,"TransferIn amount not valid");
        }else{
            require(msg.value >= amount, "ETH value not enough");
            if (msg.value > amount){
                uint256 changeAmount = msg.value.sub(amount);
                (bool result, ) = account.call{value: changeAmount,gas: transferEthGasCost}("");
                require(result, "Transfer of ETH failed");
            }
        }
    }

    function doTransferOut(address xToken, address payable account, uint256 amount) internal{
        if(amount == 0) return;
        if (IXToken(xToken).underlying() != ADDRESS_ETH) {
            IERC20(IXToken(xToken).underlying()).safeTransfer(account, amount);
        } else {
            account.transfer(amount);
        }
    }

    function transferNftInternal(address _from, address _to, address _collection, uint256 _tokenId, uint256 _nftType) internal{
        require(_nftType == 721 || _nftType == 1155, "don't support this nft type");
        
        if (_nftType == 721) {
            IERC721Upgradeable(_collection).safeTransferFrom(_from, _to, _tokenId);
        }else if (_nftType == 1155){

            IERC1155Upgradeable(_collection).safeTransferFrom(
                    _from,
                    _to,
                    _tokenId,
                    1,
                    ""
                );
        }
    }

    function _depositPunk(uint256 punkIndex) internal{
        address owner = punks.punkIndexToAddress(punkIndex);
        require(owner == msg.sender, "not owner of punkIndex");
        punks.buyPunk(punkIndex);
        punks.transferPunk(userProxy, punkIndex);
        wrappedPunks.mint(punkIndex);
    }

    function getOrderState(uint256 orderId) external view returns(OrderState orderState){
        Order memory order = allOrders[orderId];
        LiquidatedOrder memory liquidatedOrder =  allLiquidatedOrder[orderId];
        if(order.pledger != address(0)){
            if(order.isWithdraw == false){
                if(liquidatedOrder.liquidator == address(0)){
                    orderState = OrderState.PLEDGEING;
                }else{
                    CollectionNFT memory collectionNFT = collectionWhiteList[order.collection];
                    uint256 auctionDuration;
                    uint256 redeemProtection;
                    if(collectionNFT.auctionDuration != 0){
                        auctionDuration = collectionNFT.auctionDuration;
                        redeemProtection = collectionNFT.redeemProtection;
                    }else{
                        auctionDuration = auctionDurationOverAll;
                        redeemProtection = redeemProtectionOverAll;
                    }
                    if(block.timestamp < liquidatedOrder.liquidatedStartTime.add(redeemProtection)){
                        orderState = OrderState.REDEEMPROTECTION;
                    }else if(block.timestamp < liquidatedOrder.liquidatedStartTime.add(auctionDuration)){
                        orderState = OrderState.LIQUIDITYING;
                    }else{
                        orderState = OrderState.LIQUIDITYEND;
                    }
                }
            }else{
                if(liquidatedOrder.auctionWinner == address(0)){
                    orderState = OrderState.NORMALWITHDRAW;
                }else{
                    orderState = OrderState.LIQUIDITYWITHDRAW;
                }
            }
            return orderState;
        }
        return OrderState.NOPLEDGE;
    }

    function airDrop(uint256 orderId, address airDropContract, uint256 ercType) public{
        require(address(xAirDrop) != address(0) && airDropContract != address(0), "no airdrop");
        Order memory order = allOrders[orderId];
        require(!order.isWithdraw, "order has been withdrawn");
        address receiver;
        if(isOrderLiquidated(orderId)){
            LiquidatedOrder memory liquidatedOrder =  allLiquidatedOrder[orderId];
            CollectionNFT memory collectionNFT = collectionWhiteList[order.collection];
            uint256 auctionDuration;
            if(collectionNFT.auctionDuration != 0){
                auctionDuration = collectionNFT.auctionDuration;
            }else{
                auctionDuration = auctionDurationOverAll;
            }
            if(block.timestamp > liquidatedOrder.liquidatedStartTime.add(auctionDuration)){
                if(liquidatedOrder.auctionAccount == address(0)){
                    receiver = liquidatedOrder.liquidator;
                }else{
                    receiver = liquidatedOrder.auctionAccount;
                }
            }else{
                receiver = order.pledger;
            }
        }else{
            receiver = order.pledger;
        }
        IERC721Upgradeable(order.collection).safeTransferFrom(address(this), address(xAirDrop), order.tokenId);
        xAirDrop.execution(order.collection, airDropContract, receiver, order.tokenId, ercType);
        IERC721Upgradeable(order.collection).safeTransferFrom(address(xAirDrop), address(this), order.tokenId);

        emit AirDrop(address(xAirDrop), msg.sender, receiver, order.collection, order.tokenId);
    }

    function batchAirDrop(uint256[] memory orderId, address airDropContract, uint256 ercType) external{
        for(uint256 i=0; i<orderId.length; i++){
            airDrop(orderId[i], airDropContract, ercType);
        }
    }

    function ordersBalancesOf(address account) external view returns(uint256){
        return ordersMap[account].length;
    }

    function ordersOfOwnerByIndex(address account, uint256 index) external view returns(uint256){
        require(index < ordersMap[account].length, "upper limit exceeded");
        return ordersMap[account][index];
    }

    function ordersOfOwnerOffset(address account, uint256 index, uint256 offset) external view returns(uint256[] memory orders){
        require(index + offset < ordersMap[account].length, "upper limit exceeded");
        orders = new uint256[](offset);
        uint256 count;
        for(uint256 i=index; i<index+offset; i++){
            orders[count] = ordersMap[account][i];
            count++;
        }
    }
    
    //================ receiver ================
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns(bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns(bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return  interfaceId == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceId == 0x4e2312e0;     // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }

    //================ admin function ================
    function setCollectionlWhitList(address collection, bool flag, uint256 _auctionDuration, uint256 _redeemProtection, uint256 _increasingMin) external onlyAdmin{
        setCollectionlWhitListInternal(collection, flag, _auctionDuration, _redeemProtection, _increasingMin);
    }
    function setCollectionlWhitListInternal(address collection, bool flag, uint256 _auctionDuration, uint256 _redeemProtection, uint256 _increasingMin) internal{
        require(collection != address(0), "invalid collection");
        collectionWhiteList[collection].isCollectionWhiteList = flag;
        collectionWhiteList[collection].auctionDuration = _auctionDuration;
        collectionWhiteList[collection].redeemProtection = _redeemProtection;
        collectionWhiteList[collection].increasingMin = _increasingMin;
    }

    function batchAddCollectionlWhitList(address[] calldata collections, uint256[] calldata _auctionDuration, uint256[] calldata _redeemProtection, uint256[] calldata _increasingMin) external onlyAdmin{
        require(collections.length > 0, "invalid collections");
        require(collections.length == _auctionDuration.length,"collections and _auctionDuration len mismatch");
        require(_auctionDuration.length == _redeemProtection.length,"_redeemProtection and _auctionDuration len mismatch");
        require(_redeemProtection.length == _increasingMin.length,"_redeemProtection and _increasingMin len mismatch");
        for(uint256 i = 0; i < collections.length; i++){
            setCollectionlWhitListInternal(collections[i], true, _auctionDuration[i], _redeemProtection[i], _increasingMin[i]);
        }
    }

    function setPendingAdmin(address newPendingAdmin) external onlyAdmin{
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() external{
        require(msg.sender == pendingAdmin, "only pending admin could accept");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setController(address _controller) external onlyAdmin{
        controller = IP2Controller(_controller);
    }

    function setPledgerFineRate(uint256 _pledgerFineRate) external onlyAdmin{
        require(_pledgerFineRate <= RATE_UPPER_LIMIT, "the upper limit cannot be exceeded");
        pledgerFineRate = _pledgerFineRate;
    }

    function setRewardFirstRate(uint256 _rewardFirstRate) external onlyAdmin{
        require((_rewardFirstRate + rewardLastRate) <= RATE_UPPER_LIMIT, "rewardLastRate the upper limit cannot be exceeded");
        require((_rewardFirstRate + compensatePledgerRate) <= RATE_UPPER_LIMIT, "compensatePledgerRate the upper limit cannot be exceeded");
        rewardFirstRate = _rewardFirstRate;
    }

    function setRewardLastRate(uint256 _rewardLastRate) external onlyAdmin{
        require((rewardFirstRate + _rewardLastRate) <= RATE_UPPER_LIMIT, "the upper limit cannot be exceeded");
        rewardLastRate = _rewardLastRate;
    }

    function setCompensatePledgerRate(uint256 _compensatePledgerRate) external onlyAdmin{
        require((_compensatePledgerRate + rewardFirstRate) <= RATE_UPPER_LIMIT, "the upper limit cannot be exceeded");
        compensatePledgerRate = _compensatePledgerRate;
    }

    function setAuctionDurationOverAll(uint256 _auctionDurationOverAll) external onlyAdmin{
        auctionDurationOverAll = _auctionDurationOverAll;
    }

    function setRedeemProtectionOverAll(uint256 _redeemProtectionOverAll) external onlyAdmin{
        redeemProtectionOverAll = _redeemProtectionOverAll;
    }

    function setIncreasingMinOverAll(uint256 _increasingMinOverAll) external onlyAdmin{
        increasingMinOverAll = _increasingMinOverAll;
    }

    function withdraw(address xToken, uint256 amount) external onlyAdmin{
        doTransferOut(xToken, payable(admin), amount);
    }

    function withdrawAuctionIncome(address xToken, uint256 amount) external onlyAdmin{
        require(amount <= addUpIncomeMap[xToken], "amount cannot be greater than the withdrawable income");
        doTransferOut(xToken, payable(admin), amount);
        addUpIncomeMap[xToken] -= amount;
    }

    function setTransferEthGasCost(uint256 _transferEthGasCost) external onlyAdmin {
        transferEthGasCost = _transferEthGasCost;
    }

    // 1 pledge, 2 withdraw, 3 auction
    function setPause(uint256 index, bool isPause) external onlyAdmin{
        pausedMap[index] = isPause;
    }

    function setXAirDrop(IXAirDrop _xAirDrop) external onlyAdmin{
        xAirDrop = _xAirDrop;
    }

    function claim(address airdop, bytes memory byteCode) external onlyAdmin{
        (bool result, ) = airdop.call(byteCode);
        require(result, "claim error");
    }

    function setPunks(IPunks _punks, IWrappedPunks _wrappedPunks) external onlyAdmin{
        punks = _punks;
        wrappedPunks = _wrappedPunks;
        wrappedPunks.registerProxy();
        userProxy = wrappedPunks.proxyInfo(address(this));
    }

    //================ modifier ================
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "admin auth");
        _;
    }

    modifier whenNotPaused(uint256 index) {
        require(!pausedMap[index], "Pausable: paused");
        _;
    }
}
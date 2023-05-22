/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface Token{
    function transferFrom(address,address,uint) external;
    function transfer(address,uint) external;
    function balanceOf(address) external view returns(uint);
}
interface OraceLink{
    function price() external view returns(uint);
    function getOutUsdt(uint) external view returns(uint);
    function getOutToken(uint) external view returns(uint);
    function getInUsdt(uint) external view returns(uint);
}
library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}
contract Perpetual  {
    using Address for address;
    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Perpetual/not-authorized");
        _;
    }
    address                                           public  owner;
    string[]                                          public  name;
    uint256                                           public  order;
    uint256                                           public  setprice;
    uint256                                           public  flowpool;
    uint256                                           public  totalSupply;
    uint256                                           public  premium;
    Token                                             public  usdt = Token(0x55d398326f99059fF775485246999027B3197955);
    mapping (address => uint256[])                    public  opening;
    mapping (address => uint256[])                    public  closed;
    mapping (address => mapping(uint => uint))        public  indexOf;
    mapping (uint256 => OrderInfo)                    public  orderInfo;
    mapping (address => uint256)                      public  share;
    mapping (string => uint256)                       public  long;
    mapping (string => uint256)                       public  short;
    mapping (address => address)                      public  upline;
    mapping (string => address)                       public  orace;
    mapping (address => address[])                    public  underline;

    struct OrderInfo { 
        uint256    order;
        uint256    what;
        address    owner;
        string    token;
        uint256    amount;
        uint256    borrow;
        uint256    volume;
        uint256    close;
        uint256    low;
        uint256    high;
        uint256    compulsion;
        uint256    pon;
        uint256    profit;
        uint256    percentage;
    }
    struct FrontInfo { 
        address    upline;
        string[]   names;
        uint256    price;
        uint256    long;
        uint256    short;
        uint256    balance;
        uint256    flowpool;
        uint256    totalSupply;
        uint256    perShare;
        uint256    share;
    }
    constructor() {
        wards[msg.sender] = 1;
        owner = msg.sender;
    }
    function addpool(uint256 wad) public {
        usdt.transferFrom(msg.sender,address(this),wad);
        uint256 perShare;
        if(totalSupply ==0 || flowpool == 0) perShare = 1E18;
        else perShare = flowpool*1E18/totalSupply;
        uint256 addShare = wad*1E18/perShare;
        totalSupply += addShare;
        share[msg.sender] += addShare;
        flowpool += wad;
    }
    function withdraw(uint256 decreaseShare) public{
        share[msg.sender] -= decreaseShare;
        uint256 perShare = flowpool*1E18/totalSupply;
        uint256 wad =  decreaseShare*perShare/1E18;
        if(wad !=0) {
           flowpool -= wad;
           usdt.transfer(msg.sender, wad);
           totalSupply -= decreaseShare;
        }
        else revert("10");
    }
    function withdrawForPremium(uint256 wad, address ust) public auth {
        premium -= wad;
        usdt.transfer(ust, wad);
    }
    function openPosition(uint256 what,uint256 wad,uint256 multiple,string memory token,uint256 low,uint256 high,address referrer) public returns(uint){
        require(what==1 || what ==2, "2");
        if(upline[msg.sender] == address(0) && referrer != address(0) && referrer != msg.sender){
           upline[msg.sender] = referrer;
           underline[referrer].push(msg.sender);
        }
        usdt.transferFrom(msg.sender,address(this),wad);
        order +=1;
        indexOf[msg.sender][order] = opening[msg.sender].length;
        opening[msg.sender].push(order);
        indexOf[owner][order] = opening[owner].length;
        opening[owner].push(order);
        OrderInfo storage warehouse = orderInfo[order];
        warehouse.order = order;
        warehouse.what = what;
        warehouse.owner = msg.sender;
        warehouse.token = token;
        warehouse.amount = wad;
        uint256 borrow = wad*multiple;
        warehouse.borrow = borrow;
        uint256 volume = getVolume(token,borrow);
        warehouse.volume = volume;
        warehouse.low = low;
        warehouse.high = high;
        if(what ==1) long[token] += volume;
        else short[token] += volume;
        return order;
    }
    function ownerClose(uint256 _order) public{
        OrderInfo storage warehouse = orderInfo[_order];
        require(msg.sender == warehouse.owner, "3");
        require(warehouse.close == 0, "4");
        closePosition(_order);
    }

    function autoClose(uint256 _order) public{
        OrderInfo storage warehouse = orderInfo[_order];
        require(warehouse.close == 0, "5");
        require(islimitClose(_order) || iscompulsionClose(_order), "6");
        closePosition(_order);
    }
    function batchClose() public{
        uint length = opening[owner].length;
        for(uint i=0;i< length;++i) {
            uint _order = opening[owner][i];
            if(islimitClose(_order) || iscompulsionClose(_order)) closePosition(_order);
        }
    }
    function closeForOrders(uint256[] memory orders) public{
        uint length = orders.length;
        for(uint i=0;i< length;++i) {
            uint _order = orders[i];
            if(orderInfo[_order].close == 0 && (islimitClose(_order) || iscompulsionClose(_order))) closePosition(_order);
        }
    }
    function getLimitProfit(uint256 what,uint256 wad,uint256 multiple,uint256 rate,string memory token) public view returns(uint256 profit){
        uint256 volume = getVolume(token,wad*multiple);
        if(what == 1) profit = wad*(multiple*100+rate)/100/volume;
        else profit = wad*(multiple*100-rate)/100/volume;
    }
    function getLimitLoss(uint256 what,uint256 wad,uint256 multiple,uint256 rate,string memory token) public view returns(uint256 loss){
        uint256 volume = getVolume(token,wad*multiple);
        if(what == 1) loss = wad*(multiple*100-rate)/100/volume;
        else loss = wad*(multiple*100+rate)/100/volume;
    }
    function lastOrders(uint256 start) public view returns(uint256[] memory){
        uint end = opening[owner].length-1;
        uint256[] memory orders = getbeclose(start,end);
        return orders;
    }
    function getbeclose(uint256 start,uint256 end) public view returns(uint256[] memory) {
        uint length = end-start+1;
        uint256[] memory orders = new uint256[](length);
        uint j;
        for(uint i=start;i<= end;++i) {
            uint _order = opening[owner][i];
            if(islimitClose(_order) || iscompulsionClose(_order)) {
                orders[j] =  _order;
                j++;
            }
        }
        uint256[] memory beclose = new uint256[](j);
        for(uint i=0;i<j;++i) {
            beclose[i] = orders[i];
        }
        return beclose;
    }
    function islimitClose(uint256 _order) public view returns(bool){
        OrderInfo storage warehouse = orderInfo[_order];
        string memory token = warehouse.token;
        uint256 price = getPrice(token);
        if(price <= warehouse.low || price >= warehouse.high) return true;
        else return false;
    }
    function iscompulsionClose(uint256 _order) public view returns(bool){
        (uint256 pon,uint256 percentage) = getRisk(_order);
        if(pon ==2 && percentage > 80) return true;
        else return false;
    }
    function closePosition(uint256 _order) internal {
        require(!msg.sender.isContract(), "7");
        OrderInfo storage warehouse = orderInfo[_order];
        (uint256 pon,uint256 profit) = getProfit(_order);
        uint256 amount = warehouse.amount;
        uint256 wad;
        if(pon==1) {
            flowpool -= profit;
            wad = amount + profit*95/100;
        }
        else {
            if(profit > amount) profit = amount;
            wad = amount - profit;
            flowpool += profit*95/100;
        }
        premium += profit*5/100;
        address usr = warehouse.owner;
        address referrer = upline[usr];
        if(referrer !=address(0)){
           uint256 reward = profit*3/100;
           usdt.transfer(referrer,reward);
           premium -= reward;
        }
        usdt.transfer(usr,wad);
        string memory token = warehouse.token;
        warehouse.close = getUsdt(_order);
        remove(_order,usr);
        remove(_order,owner);
        uint256 volume = warehouse.volume;
        if(warehouse.what ==1) long[token] -= volume;
        else short[token] -= volume;
    }
    function getPrice(string memory token) public view returns(uint256){
        address oraceAddress = orace[token];
        return OraceLink(oraceAddress).price();
    }
    function getUsdt(uint256 _order) public view returns(uint256 usdtAmount){
        OrderInfo memory warehouse = orderInfo[_order];
        address oraceAddress = orace[warehouse.token];
        if(warehouse.what ==1) usdtAmount = OraceLink(oraceAddress).getOutUsdt(warehouse.volume);
        else usdtAmount = OraceLink(oraceAddress).getInUsdt(warehouse.volume);
    }
    function getVolume(string memory token,uint256 usdtAmount) public view returns(uint256 volume){
        address oraceAddress = orace[token];
        volume = OraceLink(oraceAddress).getOutToken(usdtAmount);
    }
    function setOraceAddress(string memory BTCUSDT,address oraceAddress) public auth{
        orace[BTCUSDT] = oraceAddress;
        name.push(BTCUSDT);
    }
    function getName() public view returns(string[] memory){
        return name;
    }
    function remove(uint256 _order,address usr) internal {
        uint index = indexOf[usr][_order];
        uint lastIndex = opening[usr].length - 1;
        uint lastOrder = opening[usr][lastIndex];

        indexOf[usr][lastOrder] = index;
        delete indexOf[usr][_order];

        opening[usr][index] = lastOrder;
        opening[usr].pop();
        closed[usr].push(_order);
    }
    function addMargin(uint256 _order,uint256 wad) public {
        OrderInfo memory warehouse = orderInfo[_order];
        require(msg.sender == warehouse.owner, "8");
        require(warehouse.close == 0, "9");
        usdt.transferFrom(msg.sender,address(this),wad);
        warehouse.amount += wad;
    }
    function getRisk(uint256 _order) public view returns(uint256 pon,uint256 percentage){
        OrderInfo memory warehouse = orderInfo[_order];
        uint256 profit;
        (pon,profit) = getProfit(_order);
        percentage = profit*100/warehouse.amount;
    }
    function getProfit(uint256 _order) public view returns(uint256 pon,uint256 profit){
        uint256 wad = getUsdt(_order);
        (pon,profit)= Profit( _order,wad);
    }
    function getCloseProfit(uint256 _order) public view returns(uint256 pon,uint256 profit){
        OrderInfo memory warehouse = orderInfo[_order];
        uint256 wad = warehouse.close;
        (pon,profit)= Profit( _order,wad);
    }
    function Profit(uint256 _order,uint256 wad) internal  view  returns(uint256 pon,uint256 profit){
        OrderInfo memory warehouse = orderInfo[_order];
        uint256 amount = warehouse.borrow;
        if(wad >= amount) profit = wad-amount;
        else profit = amount -wad;
        if(warehouse.what == 1) {
            if( wad > amount) pon = 1;
            else if( wad < amount) pon = 2;
        }
        else {
            if( wad > amount) pon = 2;
            else if( wad < amount) pon = 1;
        }
    }
    function getOpening(address usr) public view returns(OrderInfo[] memory){
        uint length = opening[usr].length;
        OrderInfo[] memory orders = new OrderInfo[](length);
        for(uint i=0;i< length;++i) {
            uint _order = opening[usr][i];
            OrderInfo memory open = orderInfo[_order];
            uint256 closePrice;
            if(open.what == 1) 
            closePrice = open.borrow -open.amount*80/100;
            else closePrice = open.borrow + open.amount*80/100;
            open.compulsion = closePrice*1E18/open.volume;
            (open.pon,open.profit) = getProfit(_order);
            open.percentage = open.profit*100/open.amount;
            orders[i] = open;
        }
        return orders;
    }
    function getClosed(address usr) public view returns(OrderInfo[] memory){
        uint length = closed[usr].length;
        OrderInfo[] memory orders = new OrderInfo[](length);
        for(uint i=0;i< length;++i) {
            uint _order = closed[usr][i];
            OrderInfo memory open = orderInfo[_order];
            uint256 closePrice;
            if(open.what == 1) 
            closePrice = open.borrow -open.amount*80/100;
            else closePrice = open.borrow + open.amount*80/100;
            open.compulsion = closePrice*1E18/open.volume;
            (open.pon,open.profit) = getCloseProfit(_order);
            open.percentage = open.profit*100/open.amount;
            orders[i] = open;
        }
        return orders;
    }
    function getunder(address usr) public view returns(address[] memory){
        return underline[usr];
    }
    function getFrontInfo(address usr,uint i) public view returns(FrontInfo memory info){
        string memory token = name[i];
        info.upline = upline[usr];
        info.names = getName();
        info.price = getPrice(token);
        info.long = long[token];
        info.short= short[token];
        info.balance = usdt.balanceOf(usr);
        info.flowpool = flowpool;
        info.totalSupply = totalSupply;
        info.perShare = flowpool*1E18/totalSupply;
        info.share = share[usr]; 
    }
}
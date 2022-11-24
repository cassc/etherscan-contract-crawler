// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
//pragma experimental ABIEncoderV2;

import "./Include.sol";

struct SMake {
    address maker;
    bool    isBid;
    address asset;
    uint    tokenId;
    bytes32 currency;
    uint    price;
    uint    payType;
    Status  status;
    string  link;
    string  memo;
    address arbiter;
}

struct STake {
    uint    makeID;
    address taker;
    Status  status;
    uint    expiry;
    string  link;
}

struct AppealInfo{
    uint takeID;
    address appeal;
    address arbiter;
    Status winner;   //0 Status.None  Status.Buyer Status.seller  assetTo
}

struct Swap {
    address seller;
    address nft;
    uint    tokenId;
    address token;
    uint    price;
    address buyer;   
    Status  status;
}

enum Status { None, Take, Paid, Cancel, Done, Appeal, Buyer, Seller,Vault} 


contract NftMarketplace is Configurable,ContextUpgradeable,IERC721ReceiverUpgradeable {
    using AddressUpgradeable for address;
    using SMath for uint;
    using SafeERC20 for IERC20;

    bytes32 internal constant _expiry_      = "expiry";
    bytes32 internal constant _feeRate_     = "feeRate";
    bytes32 internal constant _feeToken_    = "feeToken";    
    bytes32 internal constant _vault_  = "vault";
    bytes32 internal constant _mine_        = "mine";
    bytes32 internal constant _usd_   = "usd";
    bytes32 internal constant _bank_   = "bank";
    
    bytes32 internal constant _DOTC_            = 'DOTC';
    bytes32 internal constant _NFTMP_            = 'NFTMP';    
    bytes32 internal constant _rewardToken_    = "rewardToken";  //PEX
    bytes32 internal constant _swapFactory_ = "swapFactory";
    bytes32 internal constant _swapRouter_  = "swapRouter";
        
    bytes32 internal constant _feeRatio1_   = "feeRatio1";   //50% =0.5e18 
    bytes32 internal constant _rewardRatioMaker_    = "rewardRatioMaker";  //50% = 0.5e18
    bytes32 internal constant _defaultFee_    = "defaultFee";  //0.002 BNB = 0.002e18
    bytes32 internal constant _spanLock_    = "spanLock"; //30 days
    
    bytes32 internal constant _rewards_     = "rewards";
    bytes32 internal constant _locked_      = "locked";
    bytes32 internal constant _lockEnd_     = "lockEnd";



    address[] public arbiters;
    mapping (address => bool) public    isArbiter;
    mapping (uint => SMake) public makes;
    mapping (uint => STake) public takes;
    mapping (uint =>AppealInfo) public appealInfos; //takeID=> AppealInfo
    uint public makesN;
    uint public takesN;
    
    uint private _entered;

    function _noReentrant() private {
       require(_entered == 0, "reentrant");
       _entered = 1;
   
    }
    modifier nonReentrant {
        _noReentrant();
        _;
        _entered = 0;
    }

    mapping (address => string) public links; //tg link
    mapping (address => uint) public nftFees;
    
    mapping (uint =>Swap) public swaps;  //swapID =>Swap
    uint public maxSwapId;



    function toUint(address addr) pure internal returns(uint){
        return uint(uint160(addr));
    }

    function address2(uint v) pure internal returns(address){
        return address(uint160(v));
    }


    function __NftMarketplace_init(address governor_) public initializer {
        __Governable_init_unchained(governor_);
        __NftMarketplace_init_unchained();
    }

    function __NftMarketplace_init_unchained() internal governance onlyInitializing{
        //config[_usd_ ] = uint(uint160(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56));      // BUSD
        config[_expiry_]    = 30 minutes;
        config[_feeRate_    ] = 0.01e18;        //  1%
    }

    function __NftMarketplace_set_param(address vault_,address mine_,address feeToken_,uint feeRate_,uint expiry_) public governance {
        config[_vault_] = toUint(vault_);
        config[_mine_] = toUint(mine_);
        config[_feeToken_] = toUint(feeToken_);
        config[_feeRate_    ] = feeRate_;//0.01e18;        //  1%
        config[_expiry_]    = expiry_;
    }

    function setTradeParam() external governance {
         NmpLib.setTradeParam();
    }

    function setNftFees(address[] calldata nfts,uint[] calldata fees) external governance {
        require(nfts.length == fees.length) ;
        for(uint i=0;i<nfts.length;i++){
            nftFees[nfts[i]] = fees[i];
        }
    }


    function setArbiters_(address[] calldata arbiters_,string[] calldata links_) external governance {
        for(uint i=0; i<arbiters.length; i++)
            isArbiter[arbiters[i]] = false;
            
        arbiters = arbiters_;
        
        for(uint i=0; i<arbiters.length; i++){
            isArbiter[arbiters[i]] = true;
            links[arbiters[i]] = links_[i];
        }
            
        emit SetArbiters(arbiters_);
    }
    event SetArbiters(address[] arbiters_);



    function make(SMake memory make_) virtual public payable nonReentrant returns(uint makeID) { 
        require(!make_.isBid, 'only not Bid');
        uint fee = getFee(make_.asset);
        require(msg.value>=fee,"Insufficient fee");
        payable(msg.sender).transfer(msg.value - fee);
        IERC721(make_.asset).safeTransferFrom(msg.sender, address(this), make_.tokenId);
        makeID = makesN;
        make_.maker = msg.sender;
        make_.status = Status.None;
        makes[makeID]=make_;
        makesN++;
        emit Make(makeID, msg.sender, make_.asset, make_);
    }
    event Make(uint indexed makeID, address indexed maker, address indexed asset, SMake smake) ;

    function cancelMake(uint makeID) virtual external nonReentrant {
        require(makes[makeID].maker != address(0), 'Nonexistent make order');
        require(makes[makeID].maker == msg.sender, 'only maker');
        require(makes[makeID].status == Status.None, 'make pending...');
      
        if (!makes[makeID].isBid){
            IERC721(makes[makeID].asset).safeTransferFrom(address(this), msg.sender, makes[makeID].tokenId);
            uint fee = getFee(makes[makeID].asset);
            payable(msg.sender).transfer(fee);
        }
        makes[makeID].status = Status.Cancel;
        emit CancelMake(makeID, msg.sender, makes[makeID].asset, makes[makeID].tokenId );
    }
    event CancelMake(uint indexed makeID, address indexed maker, address indexed asset,uint tokenId);
    
    function reprice(uint makeID, uint newPrice) virtual external {
        require(makes[makeID].maker != address(0), 'Nonexistent make order');
        require(makes[makeID].maker == msg.sender, 'only maker');
        require(makes[makeID].status == Status.None, 'make pending...');
        
        makes[makeID].price = newPrice;
        emit Reprice(makeID, msg.sender, newPrice,makes[makeID]);

    }
    event Reprice(uint indexed makeID, address indexed maker, uint price, SMake smake);

 

    function take(uint makeID,string memory link) virtual external nonReentrant returns (uint takeID) {
        require(makes[makeID].maker != address(0), 'Nonexistent make order');
        require(makes[makeID].status == Status.None, 'make pending...');
        makes[makeID].status = Status.Take;
        takeID = takesN;
        takes[takeID] = STake(makeID, msg.sender, Status.Take, block.timestamp+config[_expiry_],link);
        takesN++;
        emit Take(takeID, makeID, msg.sender, STake(makeID, msg.sender, Status.Take, block.timestamp+config[_expiry_],link));
    }
    event Take(uint indexed takeID, uint indexed makeID, address indexed taker,STake stake);

    function cancelTake(uint takeID) virtual external nonReentrant {
        //require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].taker == msg.sender, 'only taker cancel');
        uint makeID = takes[takeID].makeID;
        require(takes[takeID].status <= Status.Paid, 'buyer can cancel neither Status.None nor Status.Paid take order');
        makes[makeID].status = Status.None;
        takes[takeID].status = Status.Cancel;
        emit CancelTake(takeID, makeID, msg.sender);
    }
    event CancelTake(uint indexed takeID, uint indexed makeID, address indexed sender);
    
    /*function paid(uint takeID) virtual external {
        require(msg.sender == takes[takeID].taker, 'only taker');
        require(takes[takeID].status == Status.Take, 'only Status.Take');
        uint makeID = takes[takeID].makeID;
        takes[takeID].status = Status.Paid;
        takes[takeID].expiry = block.timestamp+config[_expiry_];
        emit Paid(takeID, makeID, msg.sender);
    }
    event Paid(uint indexed takeID, uint indexed makeID, address indexed sender);*/

    function deliver(uint takeID) virtual payable external nonReentrant {
        NmpLib.deliver(makes,takes,config,takeID);
        /*require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status <= Status.Paid, 'only Status.None or Paid');
        uint makeID = takes[takeID].makeID;
        require(msg.sender == makes[makeID].maker, 'only maker');
        _payFee(takeID, makes[makeID].asset,Status.None);
        IERC721(makes[makeID].asset).safeTransferFrom(address(this), takes[takeID].taker, makes[makeID].tokenId);
        makes[makeID].status = Status.Done;
        takes[takeID].status = Status.Done;
        emit Deliver(takeID, makeID, msg.sender);*/
    }
    //event Deliver(uint indexed takeID, uint indexed makeID, address indexed sender);

   function getFee(address nft) public view  returns(uint fee) {
        if (nftFees[nft]>0)
            fee = nftFees[nft];
        else 
            fee = config[_defaultFee_];
    }


    function _payFee(uint takeID, address nft,Status winner) internal {
        NmpLib._payFee(makes,takes,config,takeID,nft,winner);
    }
  
    /*function appeal(uint takeID) virtual external nonReentrant {
        require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status <= Status.Paid, 'only Status.Paid');
        uint makeID = takes[takeID].makeID;
        require(msg.sender == makes[makeID].maker || msg.sender == takes[takeID].taker, 'only maker or taker');
        //require(takes[takeID].expiry < block.timestamp, 'only expired');
        takes[takeID].status = Status.Appeal;
        appealInfos[takeID].takeID = takeID;
        appealInfos[takeID].appeal = msg.sender;
        emit Appeal(takeID, makeID, msg.sender);
    }
    event Appeal(uint indexed takeID, uint indexed makeID, address indexed sender);*/
    function earned(address acct) public view returns(uint) {
        return getConfigA(_rewards_, acct);
    }

    function lockEnd(address acct) public view returns(uint) {
        return getConfigA(_lockEnd_, acct);
    }
    
    function locked(address acct) public view returns(uint) {
        uint end = lockEnd(acct);
        return (getConfigA(_locked_, acct)*(end.sub0(block.timestamp))).div0(end);
    }

    function claimable(address acct) public view returns (uint) {
        return earned(acct)-locked(acct);
    }

    function claim() external {
        claimFor(msg.sender);
    }

    function claimFor(address acct) public {
        IERC20(address2(config[_rewardToken_])).transfer(acct, claimable(acct));
        _setConfig(_rewards_, acct, locked(acct));
    }

    function claimAllMarket() external {
        IDOTC(address2(config[_DOTC_])).claimFor_(msg.sender);
        claimFor(msg.sender);
    }

    function arbitrate(uint takeID, Status winner) virtual external nonReentrant{
        NmpLib.arbitrate(makes,takes,config,appealInfos,takeID,winner);
        /*require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status <= Status.Paid, 'only < Status.Paid');
        require(isArbiter[msg.sender], 'only arbiter');
        uint makeID = takes[takeID].makeID;
        appealInfos[takeID].arbiter   = msg.sender;
        appealInfos[takeID].winner = winner;
        if(winner == Status.Buyer) {
            IERC721(makes[makeID].asset).safeTransferFrom(address(this), takes[takeID].taker, makes[makeID].tokenId);
            makes[makeID].status = Status.Done;
            emit Deliver(takeID, makeID, msg.sender);   
            //_payFee(makes,takes,config,takeID,nft,winner); 

        } else if(winner == Status.Seller) {
            makes[makeID].status = Status.None;
        } else
            revert('status should be Buyer or Seller');
        takes[takeID].status = winner;
        emit Arbitrate(takeID, makeID, msg.sender,winner);*/
   }

    //event Arbitrate(uint indexed takeID, uint indexed makeID, address indexed arbiter, Status status);

    function batchMakeSwap(Swap[] memory swaps_) virtual external payable returns(uint[] memory swapId) { 
        swapId = new uint[](swaps_.length);
        for(uint i=0;i<swaps_.length;i++){
             swapId[i] = makeSwap(swaps_[i]);
        }
    }


    function makeSwap(Swap memory swap_) virtual public payable nonReentrant returns(uint swapId) { 
        //uint fee = getFee(make_.asset);
        IERC721(swap_.nft).safeTransferFrom(msg.sender, address(this), swap_.tokenId);
        swapId = ++maxSwapId;
        swap_.seller =msg.sender;
        swap_.buyer = address(0);
        swap_.status =Status.None;
        swaps[swapId] = swap_;
        emit MakeSwap(swapId, swap_);
    }
    event MakeSwap(uint indexed swapId, Swap swap) ;

    function repriceSwap(uint swapId, uint newPrice) virtual external {
        require(swaps[swapId].seller != address(0), 'Nonexistent make order');
        require(swaps[swapId].seller == msg.sender, 'only maker');
        require(swaps[swapId].status == Status.None, 'status not None...');
        swaps[swapId].price = newPrice;
        emit RepriceSwap(swapId, msg.sender, newPrice,swaps[swapId]);
    }
    event RepriceSwap(uint indexed swapId, address indexed seller, uint price, Swap swap);    

    function cancelSwap(uint swapId) virtual external nonReentrant {
        require(swaps[swapId].seller != address(0), 'Nonexistent make order');
        require(swaps[swapId].seller == msg.sender, 'only maker');
        require(swaps[swapId].status == Status.None, 'status not None...');
        swaps[swapId].status = Status.Cancel;
        IERC721(swaps[swapId].nft).safeTransferFrom(address(this), msg.sender, swaps[swapId].tokenId);
        emit CancelSwap(swapId, msg.sender, swaps[swapId].nft, swaps[swapId].tokenId );
    }
    event CancelSwap(uint indexed swapId, address indexed seller, address indexed nft,uint tokenId);

    function takeSwap(uint swapId) payable virtual external nonReentrant {
        require(swaps[swapId].seller != address(0), 'Nonexistent make order');
        require(swaps[swapId].status == Status.None, 'make expired...');
        swaps[swapId].status = Status.Done;
        if (swaps[swapId].token==address(0)){
            require(msg.value>=swaps[swapId].price,"low value");
            payable(swaps[swapId].seller).transfer(swaps[swapId].price);
        }
        else{
            IERC20(swaps[swapId].token).safeTransferFrom(msg.sender, swaps[swapId].seller,swaps[swapId].price);
        }
        IERC721(swaps[swapId].nft).safeTransferFrom(address(this), msg.sender,swaps[swapId].tokenId);
        swaps[swapId].buyer = msg.sender;
        emit TakeSwap(swapId, msg.sender, swaps[swapId]);
    }
    event TakeSwap(uint indexed swapId, address indexed buyer,Swap swap);


    function batchMake(SMake[] memory makes_) virtual external payable returns(uint[] memory makeIds) { 
        makeIds = new uint[](makes_.length);
        for(uint i=0;i<makes_.length;i++){
             makeIds[i] = make(makes_[i]);
        }
    }


    
    function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
 
    function setconfL(bytes32 key,uint value) public  {
        require(msg.sender == address(this));
        _setConfig(key,value);
    }

    function setconfL(bytes32 key, uint index, uint value) public {
        require(msg.sender == address(this));
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setconfL(bytes32 key, address addr, uint value) public {
        require(msg.sender == address(this));
        _setConfig(bytes32(uint(key) ^ uint(uint160(addr))), value);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[41] private ______gap;
}


library NmpLib {

    using AddressUpgradeable for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    bytes32 internal constant _expiry_      = "expiry";
    bytes32 internal constant _feeRate_     = "feeRate";
    bytes32 internal constant _feeToken_    = "feeToken";    
    bytes32 internal constant _vault_  = "vault";
    bytes32 internal constant _mine_        = "mine";
    bytes32 internal constant _usd_   = "usd";
    bytes32 internal constant _bank_   = "bank";
    
    bytes32 internal constant _DOTC_            = 'DOTC';
    bytes32 internal constant _NFTMP_            = 'NFTMP';
    bytes32 internal constant _rewardToken_    = "rewardToken";  //PEX
    bytes32 internal constant _swapFactory_ = "swapFactory";
    bytes32 internal constant _swapRouter_  = "swapRouter";
    bytes32 internal constant _feeRatio1_   = "feeRatio1";   //50% =0.5e18 
    bytes32 internal constant _rewardRatioMaker_    = "rewardRatioMaker";  //50% = 0.5e18
    bytes32 internal constant _defaultFee_    = "defaultFee";  //0.002 BNB = 0.002e18
    bytes32 internal constant _spanLock_    = "spanLock"; //30 days
    
    bytes32 internal constant _rewards_     = "rewards";
    bytes32 internal constant _locked_      = "locked";
    bytes32 internal constant _lockEnd_     = "lockEnd";
    
 

    function toUint(address addr) pure internal returns(uint){
        return uint(uint160(addr));
    }

    function address2(uint v) pure internal returns(address){
        return address(uint160(v));
    }

    function setTradeParam() external  {
        uint id;
        assembly { id := chainid() }
        NftMarketplace nftMp = NftMarketplace(address(this));
        if (id==56) { //bsc
            nftMp.setconfL(_vault_,toUint(0x263e0910C8c1B77B80CB9947B0FAC3735a6FEf4C));
            nftMp.setconfL(_mine_,toUint(0xe85231a4Eaa69169c1DDE01dDDD933087aa0C272));
            nftMp.setconfL(_DOTC_,toUint(0x8996Da635aFabd360fbABB80e7Be5028324B8323));
            nftMp.setconfL(_rewardToken_,toUint(0x6a0b66710567b6beb81A71F7e9466450a91a384b));
            nftMp.setconfL(_swapFactory_,toUint(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73));
            nftMp.setconfL(_swapRouter_,toUint(0x10ED43C718714eb63d5aA57B78B54704E256024E));
            nftMp.setconfL(_feeRatio1_,0.5e18);//50%
            nftMp.setconfL(_rewardRatioMaker_,0.5e18);//50%
            nftMp.setconfL(_defaultFee_,0.002e18);//0.002 BNB = 0.002e18;
            nftMp.setconfL(_spanLock_,30 days);//30day
        }else if(id==1){//ethmain

        }

    }

    function deliver(mapping (uint => SMake) storage makes,mapping (uint => STake) storage takes,mapping (bytes32 => uint) storage config,uint takeID)  external {
        require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status <= Status.Paid, 'only Status.None or Paid');
        uint makeID = takes[takeID].makeID;
        require(msg.sender == makes[makeID].maker, 'only maker');
        //_payFee(takeID, makes[makeID].asset,Status.None);
        _payFee(makes,takes,config,takeID,makes[makeID].asset,Status.None);
        IERC721(makes[makeID].asset).safeTransferFrom(address(this), takes[takeID].taker, makes[makeID].tokenId);
        makes[makeID].status = Status.Done;
        takes[takeID].status = Status.Done;
        emit Deliver(takeID, makeID, msg.sender);
    }
    event Deliver(uint indexed takeID, uint indexed makeID, address indexed sender);


    function arbitrate(mapping (uint => SMake) storage makes,mapping (uint => STake) storage takes,mapping (bytes32 => uint) storage config,mapping (uint =>AppealInfo) storage appealInfos,uint takeID, Status winner)  external /*nonReentrant*/{
        NftMarketplace nftMp = NftMarketplace(address(this));
        require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status <= Status.Paid, 'only < Status.Paid');
        require(nftMp.isArbiter(msg.sender), 'only arbiter');
        uint makeID = takes[takeID].makeID;
        appealInfos[takeID].arbiter   = msg.sender;
        appealInfos[takeID].winner = winner;
        if(winner == Status.Buyer) {
            IERC721(makes[makeID].asset).safeTransferFrom(address(this), takes[takeID].taker, makes[makeID].tokenId);
            makes[makeID].status = Status.Done;
            emit Deliver(takeID, makeID, msg.sender);   
            _payFee(makes,takes,config,takeID,makes[makeID].asset,winner); 

        } else if(winner == Status.Seller) {
            makes[makeID].status = Status.None;
        } else
            revert('status should be Buyer or Seller');
        takes[takeID].status = winner;
        emit Arbitrate(takeID, makeID, msg.sender,winner);
    }

    event Arbitrate(uint indexed takeID, uint indexed makeID, address indexed arbiter, Status status);

    function _payFee(mapping (uint => SMake) storage makes,mapping (uint => STake) storage takes,mapping (bytes32 => uint) storage config,uint takeID, address nft,Status winner) internal {
        NftMarketplace nftMp = NftMarketplace(address(this));
        uint fee = nftMp.getFee(nft);
        //require(msg.value>=fee,"Insufficient fee");
        address rewardToken = address2(config[_rewardToken_]);
        IUniswapV2Router01 router = IUniswapV2Router01(address2(config[_swapRouter_]));
        address WETH  = router.WETH();
        IWETH(WETH).deposit{value: fee}();
        uint amt1 = fee.mul(config[_feeRatio1_]).div(1e18);
        //uint amt2 = fee-amt1; // instead with fee
        fee = fee-amt1;  //now fee is amt2
        IERC20(WETH).safeTransfer(address2(config[_vault_]), amt1);
        uint reward1 = amt1*1e18/IDOTC(address2(config[_DOTC_])).price1();
        //uint reward2 = 0;  
        IERC20(rewardToken).safeTransferFrom(address2(config[_mine_]), address(this), reward1);
        if(fee>0){ //real amt2>0
            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = rewardToken;
            IERC20(WETH).safeApprove_(address(router), fee);
            uint[] memory amounts = router.swapExactTokensForTokens(fee, 0, path, address(this), block.timestamp);
            fee = amounts[1]; //now fee is reward2
        }
        payFee2(makes,takes,config,takeID,reward1,fee,winner);
    }
    event FeeReward(uint indexed takeID, uint makeVol,uint takeVol,address nft);
  
     function payFee2(mapping (uint => SMake) storage makes,mapping (uint => STake) storage takes,mapping (bytes32 => uint) storage config,uint takeID,uint v1,uint v2,Status winner) internal {
        uint ratio = config[_rewardRatioMaker_];
        if (winner == Status.Buyer)
            ratio = 0;
        uint v = v1.add(v2);
        emit FeeReward(takeID,v.mul(ratio).div(1e18),v.mul(uint(1e18).sub(ratio)).div(1e18),makes[takes[takeID].makeID].asset);
        v1 = v;
        v2 = 0;
        if (winner == Status.Buyer){
            _updateReward(takes[takeID].taker, v1, v2, uint(1e18)); 
        }
        else{
            _updateReward(makes[takes[takeID].makeID].maker, v1, v2, ratio);
            _updateReward(takes[takeID].taker, v1, v2, uint(1e18).sub(ratio)); 
        }
}

    function _updateReward(address acct, uint v1, uint v2, uint ratio) internal {
        NftMarketplace nftMp = NftMarketplace(address(this));
        v1 = v1.mul(ratio).div(1e18);
        v2 = v2.mul(ratio).div(1e18);
        uint lkd = nftMp.locked (acct);
        uint end = nftMp.lockEnd(acct);
        //end = end.sub0(now).mul(lkd).add(getConfig(_spanLock_).mul(v1)).div(lkd.add(v1)).add(now);
        end = (end.sub0(block.timestamp)*lkd+nftMp.getConfig(_spanLock_)*v1)/(lkd+v1)+block.timestamp;
        nftMp.setconfL(_locked_ , acct, lkd.add(v1).mul(end).div(end.sub(block.timestamp)));
        nftMp.setconfL(_lockEnd_, acct, end);
        nftMp.setconfL(_rewards_, acct, nftMp.earned(acct)+v1+v2);
    }
 
}



interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router01 {
    //function factory() external pure returns (address);
    function WETH() external pure returns (address);
    //function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IDOTC {
    function price1() external view returns(uint);
    function claimFor_(address acct) external ;
}

library SMath{
    function sub0(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }
    function div0(uint256 a, uint256 b) internal pure returns (uint256) {
        return b == 0 ? 0 : a / b;
    }
}
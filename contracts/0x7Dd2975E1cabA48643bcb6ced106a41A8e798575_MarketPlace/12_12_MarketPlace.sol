// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./libs/Pausable.sol";
import "./libs/IMessierNFT.sol";
import "./libs/IM87.sol";
import "./libs/ISupernova.sol";

contract MarketPlace is Initializable, Pausable {


    enum State {beforeStart, running} // Etat de l'ICO (avant le début, en cours, terminé, interrompu (ça va reprendre))
    State public isRun;

   
    struct Offer {
        uint128 _bidAmount;
        uint64 date;
    }
    struct Auction {
        uint128 startingPrice;
        uint128 highestBid;
        address highestBidder;
        uint64 auctionEnd;
        bool finished;
    }
    struct PublicAuction {
        uint128 startingPrice;
        uint128 highestBid;
        uint128 bestPrice;
        address highestBidder;
        uint64 auctionEnd;
        bool finished;
    }

    IM87 public m87Token;
    IMessierNFT public nft;
    IM87 public mttToken;
    IM87 public mottToken;
    ISupernova _SupernovaBridge;
    bytes32 _Hash;

    //const
    uint8  _MaxNfts; 
    uint8  _CurrentId; 
    uint32 _MinBid ;

    uint32 public bidFeePercentage;
    uint32 public auctionEndPeriod;
    uint32 public auctionBidPeriod;
    uint128 public maximumBidAmount;

    address private _supernova;

    mapping(uint8 => mapping(address => Offer) ) public _OffersMap;
     mapping(uint8 => mapping(address => Offer) ) public _PublicOffersMap;
    mapping(uint256 => Auction) public auctionsMap;
    mapping(uint256 => PublicAuction) public _PublickAuctionsMap;
    mapping(address => uint256) public refundAmountMap;
    mapping(address => uint256) public refundAmountMapEth;
    mapping(uint8 => address) public _InitOwner;
    

    // events
    event AuctionCreated(
        uint256 tokenId,
        uint128 startingPrice
    );

    event BidMade(
        uint256 tokenId,
        address bidder,
        uint256 tokenAmount,
        uint64 auctionEndPeriod
    );

    event AuctionWithdrawn(
        uint256 tokenId
    );

    event BidderRefunded(
        uint256 tokenAmount,
        address bidder
    );

    event RefundIncreased(
        uint256 tokenAmount,
        address bidder
    );

    event AuctionWin(
        uint256 tokenId,
        uint256 tokenAmount,
        address winner,
        address confirmer
    );

    event AuctionFinished(
        uint256 tokenId,
        address confirmer
    );


    modifier correctId(uint8 _tokenId) {
        require(
           _tokenId >= 1 && _tokenId <= _MaxNfts,
            "Auction has ended"
        );
        _;
    }
    modifier auctionInit() {
        require(
           isRun == State.beforeStart ,
            "Auction has ended"
        );
        _;
    }
     modifier ownerOfToken(uint8 _TokenId) {
        require(
          _InitOwner[_TokenId] != address(0),
            "Your are owner Of token"
        );
        _;
    }
    modifier dropOfToken(uint8 _TokenId) {
        require(
          _InitOwner[_TokenId] != msg.sender,
            "This Auction has Closed"
        );
        _;
    }
    modifier minimumBid(uint128 price) {
        require(
            price > _MinBid,
            "This Price is lower than auction !"
        );
        _;
    }
    modifier balanceOfToken(uint price) {
        require(
            m87Token.balanceOf(msg.sender) > price,
            "The account balance is insufficient !"
        );
        _;
    }

    modifier auctionAfter() {
        require(
           isRun != State.beforeStart ,
            "Auction has ended"
        );
        _;
    }
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }
    modifier isAuctionOver(uint256 _tokenId) {
        require(
            !_isAuctionActive(_tokenId),
            "Auction is not yet over"
        );
        _;
    }
      modifier isAuctionOverP(uint128 _tokenId) {
        require(
            !_isAuctionActivePublic(_tokenId),
            "Auction is not yet over"
        );
        _;
    }
    
    modifier Bridge(bytes32 hsh) {
       require(_Hash == hsh);
        _;
    }
    function setup(
        address _m87Token,
        address _messierNft,
        address _mttAddress,
        address _mottAddress,
        bytes32 _hsh
    ) public initializer {

        m87Token = IM87(_m87Token);
        nft = IMessierNFT(_messierNft);
        mttToken = IM87(_mttAddress);
        mottToken = IM87(_mottAddress);

        bidFeePercentage = 400;
        // // 4 %
        auctionEndPeriod = 396000;//110*60*60
        // //110 hours
        auctionBidPeriod = 5220; //87*60
        // //87 minutes
        maximumBidAmount = 20 * 1e9 * 1e18;
        // // 20 billion token
        isRun = State.beforeStart;

         _MaxNfts= 110; 

         _CurrentId= 0; 
         
        _MinBid = 178100000;

     

        _Hash = _hsh;
        __Ownable_init();
    }

    function _State() public view returns(State){
        return isRun;
    }
    function _ChangeState()  internal returns(bool){
        isRun = State.running;
        return true;
    }
    function _Set_SupernovaBridgeBridge(address _fb)  external onlyOwner returns(bool){
        _supernova = _fb;
        _SupernovaBridge = ISupernova(_fb);
        return true;
    }
    function getBridge()  public view returns(address){

        return _supernova;
    }
    function _ChangeHash(bytes32 _hs)  external onlyOwner returns(bool){
        _Hash = _hs;
        return true;
    }
    function _ChangeStateManul()  external onlyOwner returns(bool){
        isRun = State.running;
        return true;
    }
    // ******* Init NfT *******//
    function makeBidInit(uint8 _tokenId, uint128 _tokenAmount) external
    correctId(_tokenId)
    auctionInit()
    minimumBid(_tokenAmount)
    balanceOfToken(_tokenAmount)
    {
        if(maximumBidAmount < _tokenAmount){
            revert("maximum Bid Amount!");
        } 
        _restValues(_tokenId, _tokenAmount, msg.sender);
        //the auction end is always set to now + the bid period
        
        emit BidMade(_tokenId, msg.sender, _tokenAmount, auctionsMap[_tokenId].auctionEnd );
    }
    function _restValues(uint8 _tokenId, uint128 _tokenAmount, address _newBidder) internal
    {
        address prevNftHighestBidder = auctionsMap[_tokenId].highestBidder;

        uint256 prevNftHighestBid = auctionsMap[_tokenId].highestBid;

        if (_newBidder == address(0)) {
            revert("Your Address is zero!");
        }
            if (refundAmountMap[_newBidder] >= _tokenAmount) {
                refundAmountMap[_newBidder] -= _tokenAmount;
            } else {
                m87Token.transferFrom(
                    _newBidder,
                    address(this),
                    _tokenAmount 
                );
                //send to bank
                m87Token.transfer(_supernova, _tokenAmount);
                _SupernovaBridge.Received(_Hash,true);

            }

   
       _OffersMap[_tokenId][msg.sender] = Offer(_tokenAmount,uint64(block.timestamp));
     if (prevNftHighestBidder != address(0)) {
            
            if(_tokenAmount > prevNftHighestBid ){
                auctionsMap[_tokenId].highestBid =_tokenAmount;
                auctionsMap[_tokenId].highestBidder =msg.sender;
               uint time =  auctionsMap[_tokenId].auctionEnd;
               uint diff =block.timestamp -  time ;
                if(auctionBidPeriod >= diff){
                    auctionsMap[_tokenId].auctionEnd = auctionBidPeriod + uint64(block.timestamp);
                }
            }
        }else{
                auctionsMap[_tokenId].auctionEnd = auctionEndPeriod + uint64(block.timestamp);
                auctionsMap[_tokenId].finished = false;
                auctionsMap[_tokenId].highestBid =_tokenAmount;
                auctionsMap[_tokenId].highestBidder =msg.sender;
        }
    }
    function RefundsEth(address refundTo, uint128 _Amount) external {
       _refundEth(refundTo, _Amount);
        
    }
    function _refundTokens(address _refundAddress, uint _tokenAmount) internal {
        require(_tokenAmount > 0, "Refund Amount cannot be 0");
        require(refundAmountMap[_refundAddress] >= _tokenAmount, "Not enough amount for refund");
        refundAmountMap[_refundAddress] -= _tokenAmount;//** Check */
        // m87Token.transfer(_refundAddress, _tokenAmount);
        _SupernovaBridge._WithdrawToken(_tokenAmount, _refundAddress, _Hash);
        emit BidderRefunded(_tokenAmount, _refundAddress);
    }  
    function _refundEth(address _refundAddress, uint _Amount) internal {
        require(_Amount > 0, "Refund Amount cannot be 0");
        require(refundAmountMapEth[_refundAddress] >= _Amount, "Not enough amount for refund");
        refundAmountMapEth[_refundAddress] -= _Amount;
        _SupernovaBridge.WithdrawEth(_Amount, _refundAddress, _Hash);
        emit BidderRefunded(_Amount, _refundAddress);
    }
 
 
    function _dropTokens(uint8 _tokenId) internal {
        //*** check
        require(auctionsMap[_tokenId].finished !=false, "This Auction Has been Closed !");
       
        refundAmountMap[msg.sender] += _OffersMap[_tokenId][msg.sender]._bidAmount;
        delete _OffersMap[_tokenId][msg.sender];
        emit BidderRefunded(_OffersMap[_tokenId][msg.sender]._bidAmount, msg.sender);
    }

    function DropEth(uint8 _tokenId) external {
        require(_PublickAuctionsMap[_tokenId].finished !=false, "This Auction Has been Closed !");
       
        refundAmountMapEth[msg.sender] += _OffersMap[_tokenId][msg.sender]._bidAmount;
        delete _PublicOffersMap[_tokenId][msg.sender];
        emit BidderRefunded(_PublicOffersMap[_tokenId][msg.sender]._bidAmount, msg.sender);
    }

    function MyOffer(uint8 _tokenId,address _ask) external view returns(Offer memory) {
        
        return _OffersMap[_tokenId][_ask];
    }

    function Drop( uint8 _tokenId) 
    correctId(_tokenId)
    auctionInit()
    dropOfToken(_tokenId)
    external {
       _dropTokens(_tokenId);
        
    }
    function getHightestBid(uint _tokenId) public view returns(uint,uint){
       return (auctionsMap[_tokenId].highestBid,mttToken.balanceOf(address(this)));
    }
    function DetermineWinInit(uint8 _tokenId) external 
    // auctionInit
    // dropOfToken(_tokenId)
    // isAuctionOver(_tokenId)
    { address _ask = msg.sender;
           uint HIGHESTAMOUNT = auctionsMap[_tokenId].highestBid;
         if(_OffersMap[_tokenId][_ask]._bidAmount == HIGHESTAMOUNT){
           
            //  m87Token.transfer(address(0xdead), HIGHESTAMOUNT);
             nft.mint(_ask, _tokenId);

         
             mttToken.transfer( _ask, HIGHESTAMOUNT);
             mottToken.transfer( _ask, HIGHESTAMOUNT);
             auctionsMap[_tokenId].finished = true;
             _InitOwner[_tokenId] = _ask;
           _SupernovaBridge.PutInReward_1(_Hash, _ask, HIGHESTAMOUNT);//MTT => stack 
           _SupernovaBridge.PutInReward_2(_Hash, _ask, HIGHESTAMOUNT);//MOT => nft
           delete _OffersMap[_tokenId][_ask];
             emit AuctionWin(_tokenId, HIGHESTAMOUNT, _ask, msg.sender);
         }else{
            revert("You are Not real winner!");
         }

        if(_CurrentId == _MaxNfts){
            _ChangeState();
        }
    }
  
    function _isAuctionActive(uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        uint64 auctionEndTimestamp = auctionsMap[_tokenId].auctionEnd;
        return block.timestamp < auctionEndTimestamp;
    }

    function _isAuctionActivePublic(uint128 _tokenId)
    internal
    view
    returns (bool)
    {
        uint64 auctionEndTimestamp = _PublickAuctionsMap[_tokenId].auctionEnd;
        return block.timestamp < auctionEndTimestamp;
    }
     // ******* Public NfT *******//
    function FeeCalculator(uint _amount)
    public
    view
    returns (uint)
    {
       
        return _amount * bidFeePercentage / 10000;
    }

function _restValuesPublice(uint8 _tokenId, uint128 _Amount) internal 
    {
        address prevNftHighestBidder = _PublickAuctionsMap[_tokenId].highestBidder;

        uint256 prevNftHighestBid = _PublickAuctionsMap[_tokenId].highestBid;

     

   
       _PublicOffersMap[_tokenId][msg.sender] = Offer(_Amount,uint64(block.timestamp));
     if (prevNftHighestBidder != address(0)) {
            
            if(_Amount > prevNftHighestBid ){
                _PublickAuctionsMap[_tokenId].highestBid =_Amount;
                _PublickAuctionsMap[_tokenId].highestBidder =msg.sender;
               uint time =  _PublickAuctionsMap[_tokenId].auctionEnd;
               uint diff =block.timestamp -  time ;
                if(auctionBidPeriod >= diff){
                    _PublickAuctionsMap[_tokenId].auctionEnd = auctionBidPeriod + uint64(block.timestamp);
                }
            }
        }else{
                _PublickAuctionsMap[_tokenId].auctionEnd = auctionEndPeriod + uint64(block.timestamp);
                _PublickAuctionsMap[_tokenId].finished = false;
                _PublickAuctionsMap[_tokenId].highestBid =_Amount;
                _PublickAuctionsMap[_tokenId].highestBidder =msg.sender;
        }
    }
    function Refunds(address refundTo, uint128 _tokenAmount) external {
       _refundTokens(refundTo, _tokenAmount);
        
    }

    function Resell(uint8 _tokenId,uint128 _basePrice,uint128 _bestPrice) 
    // auctionAfter()
    public 
    returns(bool){
     
           if(nft.balanceOf(msg.sender) == 0){
             revert("Refund Amount cannot be 0");
           }
          if(_PublickAuctionsMap[_tokenId].startingPrice > 0){
             if(_PublickAuctionsMap[_tokenId].startingPrice >= _basePrice){
              revert("You should increasing you base price ");
          }
          }
        
        _PublickAuctionsMap[_tokenId].startingPrice = _basePrice;
        _PublickAuctionsMap[_tokenId].bestPrice = _bestPrice;
        _PublickAuctionsMap[_tokenId].auctionEnd = auctionEndPeriod + uint64(block.timestamp);
        _PublickAuctionsMap[_tokenId].finished = false;
    
       return true;

  
   
    }
    function AuctionIsOpen(uint _tokenId) public view returns(uint){
        return _PublickAuctionsMap[_tokenId].startingPrice;
    }
    function makeBid(uint8 _tokenId,uint128 _bidPrice)
     external
     payable
    // correctId(_tokenId)
    // auctionAfter()
    {
        require(_PublickAuctionsMap[_tokenId].startingPrice != 0, "You can make bid in your nft");
        //check
        require(nft.balanceOf(msg.sender) == 0, "You can make bid in your nft");

        if(_PublickAuctionsMap[_tokenId].startingPrice > msg.value){
            revert("maximum Bid Amount!");
        }
        if (msg.sender == address(0)) {
            revert("Your Address is zero!");
        }
            if (refundAmountMapEth[msg.sender] >=_bidPrice) {
                refundAmountMapEth[msg.sender] -= _bidPrice;
            } else {
        
                // // ** check 
                (bool success,) = _supernova.call{value : _bidPrice}("");
                require(success, "refund failed");
            }
        _restValuesPublice(_tokenId, _bidPrice);
        //the auction end is always set to now + the bid period
        
        emit BidMade(_tokenId, msg.sender, msg.value, auctionsMap[_tokenId].auctionEnd );
    }

    function AddFundEth(uint _amount) public payable {
            if(_amount > msg.value){
                        revert("maximum Bid Amount!");
            }
            
            (bool success,) =payable(_supernova).call{value : _amount}("");
            require(success, "refund failed");
            refundAmountMapEth[msg.sender] += _amount;
    } 
    function MyFundEth() public view returns(uint) {
           return refundAmountMapEth[msg.sender];
    } 
    function AddFundToken(uint _amount) public payable  
     balanceOfToken(_amount) 
    {
        
            
             m87Token.transferFrom(
                    msg.sender,
                    address(this),
                    _amount 
                );
                //send to bank
                m87Token.transfer(_supernova, _amount);
                _SupernovaBridge.Received(_Hash,true);
            refundAmountMap[msg.sender] += _amount;
    } 
    function MyFundToken() public view returns(uint) {
           return refundAmountMap[msg.sender];
    } 
    function DetermineWin(uint8 _tokenId,uint _userIndex) external 
    // auctionAfter
    // isAuctionOverP(_tokenId)
    {
        address _ask = msg.sender;
           uint HIGHESTAMOUNT = _PublickAuctionsMap[_tokenId].highestBid;
         if(_PublicOffersMap[_tokenId][_ask]._bidAmount == HIGHESTAMOUNT){
           
            //send fee to thrusry
            uint _ourFee = FeeCalculator(HIGHESTAMOUNT);
            uint reciveseller = HIGHESTAMOUNT - _ourFee;
           
            (bool success_s,) = payable(_supernova).call{value : _ourFee, gas : 20000}("");
                require(success_s, "refund failed");
             _SupernovaBridge.PutInTreasuryETH(_Hash,_ourFee);
            (bool success,) = payable(nft.ownerOf(_tokenId)).call{value : reciveseller, gas : 20000}("");
                require(success, "refund failed");

       
         
             _PublickAuctionsMap[_tokenId].finished = true;
        

             //transfer mtt 
            mttToken.transferFrom(nft.ownerOf(_tokenId), _ask, auctionsMap[_tokenId].highestBid);//(nft.ownerOf(_tokenId), _ask, auctionsMap[_tokenId].highestBid,_Hash);
            mottToken.transferFrom(nft.ownerOf(_tokenId), _ask, auctionsMap[_tokenId].highestBid);// mottToken.transferOwner(nft.ownerOf(_tokenId), _ask, auctionsMap[_tokenId].highestBid,_Hash);

         
        //      //drop & put the  new addres in reward pool
           _SupernovaBridge.PutAndDropReward_1(_Hash,nft.ownerOf(_tokenId), _ask, HIGHESTAMOUNT,_userIndex);//MTT => stack
           _SupernovaBridge.PutAndDropReward_2(_Hash,nft.ownerOf(_tokenId), _ask, HIGHESTAMOUNT,_userIndex);//MOT => nft


             //transfer _tokenId
             nft.safeTransferFrom(nft.ownerOf(_tokenId), _ask, _tokenId);


             delete _PublicOffersMap[_tokenId][_ask];
             emit AuctionWin(_tokenId, HIGHESTAMOUNT, _ask, msg.sender);
             
         }else{
            revert("You are Not real winner!");
         }

     
    }

   receive() external payable{
        
    }


 
 
}
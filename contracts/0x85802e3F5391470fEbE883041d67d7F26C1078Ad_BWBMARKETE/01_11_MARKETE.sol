// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


contract BWBMARKETE is IERC721Receiver, Ownable {

    using Address for address payable;
    using Counters for Counters.Counter;

    address payable private feeAddr; 
    Counters.Counter private auctionIds;

    enum iType { ERCNon , ERC721Type , ERC1155Type }
    
    constructor() {
        feeAddr = payable(msg.sender);    
    }

    struct auction {
        address  payable _Seller;
        address  payable _HighestBidder;
        uint256 _HighestBid;
        uint256 _auctionId;
        uint256 _endTime;
        bool    _Started;
        bool    _Ended;
    }

    mapping(address => mapping(uint256 => auction)) _auctionInfo;
    mapping(address => mapping(uint256 => uint256)) _bidsAmount; /* nftaddres => (autionid => amount) */

     uint256 private auctionEndTime;

    event Start(address , uint256 , auction);
    event Bid (address , uint256 , auction);
    event End (address , uint256 , address ,address , uint256);
    event Cancel (address, uint256 , address , uint256);

    modifier isStart(address _NFTAddress , uint256 _TokenID , uint256 _startPrice) {
        require(_auctionInfo[_NFTAddress][_TokenID]._Started == false , "Auction already started.");
        require(msg.sender == IERC721(_NFTAddress).ownerOf(_TokenID) , "MSG.SENDER is not the owner");
        require(_startPrice > 0 , "StartPrice must be greater than 0");
        _;
    }

    modifier isBid(address _NFTAddress , uint256 _TokenID , uint256 _BidPrice) {
        require(_auctionInfo[_NFTAddress][_TokenID]._Started == true , "NFT not started");
        require(_auctionInfo[_NFTAddress][_TokenID]._HighestBid < _BidPrice , "msg.value must be greater than highestbid");
        require(msg.value == fee(_BidPrice) , "msg.value is not (price + fee)");
        require(_auctionInfo[_NFTAddress][_TokenID]._endTime > block.timestamp , "auction ended" );
        _;
    }

    modifier idEnd(address _NFTAddress , uint256 _TokenID) {
        require(_auctionInfo[_NFTAddress][_TokenID]._Started == true && 
                _auctionInfo[_NFTAddress][_TokenID]._Ended == false, "Action not started or Auction already ended");
        
        require(_auctionInfo[_NFTAddress][_TokenID]._endTime <= block.timestamp , "Auction is still ongoing");
        _;
    }

    modifier onlyAuctionSeller(address _NFTAddress , uint256 _TokenID) {
        require (_auctionInfo[_NFTAddress][_TokenID]._Seller  == msg.sender , "MSG.SENDER is not NFT Seller.");
        require (_auctionInfo[_NFTAddress][_TokenID]._HighestBidder == address(0) , "Aleady biding");
        _;
    }
    
    function onERC721Received(address , address , uint256 , bytes calldata ) public virtual override returns (bytes4) {
	
        return this.onERC721Received.selector;
    }

    function auctionStart(address _NFTAddress , uint256 _TokenID , uint256 _startPrice) public 
        isStart(_NFTAddress , _TokenID , _startPrice)
    {
        uint256 auctionId = auctionIds.current() + 1;
        auctionIds.increment();

        auction memory _auction = auction({
            _Seller         : payable(msg.sender),
            _HighestBidder  : payable(address(0)),
            _HighestBid     : _startPrice,
            _auctionId      : auctionId,
            _endTime        : 1667030400, // 1667030400 (2022-10-29 17:00:00)
            _Started        : true,
            _Ended          : false
        });

        _auctionInfo[_NFTAddress][_TokenID] = _auction;

        IERC721(_NFTAddress).safeTransferFrom(msg.sender, address(this), _TokenID);

        emit Start(_NFTAddress , _TokenID , _auctionInfo[_NFTAddress][_TokenID]);
    }
    

    function autionNFTOf(address _NFTAddress , uint256 _TokenID) public view returns(auction memory _auction) {
        auction memory a = _auctionInfo[_NFTAddress][_TokenID];
        return a;
    }

    function getAuctionAmount ( address _bidder , uint256 _auctionId ) public view returns ( uint256 _amount) {
        return _bidsAmount[_bidder][_auctionId];
    }
    
    function auctionCancel (address _NFTAddress , uint256 _TokenID ) public 
        onlyAuctionSeller(_NFTAddress , _TokenID)
    {
        auction storage c = _auctionInfo[_NFTAddress][_TokenID];

        uint256 auctionId = c._auctionId;

        IERC721(_NFTAddress).safeTransferFrom(address(this) , c._Seller , _TokenID);

        c._Seller = payable(address(0));
        c._Started = false;
        c._endTime = 0;
        c._HighestBid = 0;
        c._auctionId = 0;

        emit Cancel(_NFTAddress , _TokenID , msg.sender , auctionId);
    }

    function bid( address _NFTAddress , uint256 _TokenID , uint256 _BidPrice) public payable 
        isBid(_NFTAddress , _TokenID , _BidPrice)
    {
        
        auction storage c = _auctionInfo[_NFTAddress][_TokenID];

        if (c._HighestBidder != address(0)){
            
            uint256 amount = _bidsAmount[c._HighestBidder][c._auctionId];
            _bidsAmount[c._HighestBidder][c._auctionId] = 0;
            c._HighestBidder.sendValue(amount);   
        }

        c._HighestBidder = payable(msg.sender);
        c._HighestBid = _BidPrice;

        _bidsAmount[msg.sender][c._auctionId] = msg.value;

        emit Bid(_NFTAddress , _TokenID , c);
    }

    function end ( address _NFTAddress , uint256 _TokenID ) public
        onlyOwner 
        idEnd(_NFTAddress , _TokenID)
    {
        auction storage c = _auctionInfo[_NFTAddress][_TokenID];

        if (c._HighestBidder == address(0)){ 

            IERC721(_NFTAddress).safeTransferFrom(address(this), c._Seller , _TokenID);

        } else {
            
            IERC721(_NFTAddress).safeTransferFrom(address(this), c._HighestBidder , _TokenID);

            uint256 amount = _bidsAmount[c._HighestBidder][c._auctionId];
            _bidsAmount[c._HighestBidder][c._auctionId] = 0;
            c._Seller.sendValue(c._HighestBid);
            feeAddr.sendValue(amount - c._HighestBid);
        }

        c._Started = false;
        c._Ended = true;

        emit End(_NFTAddress , _TokenID , c._Seller, c._HighestBidder , c._HighestBid);
    }
    
    
    /**************  sale  ************/

    
    mapping ( address => uint256 ) _FeeAmount;

    mapping ( address => mapping ( uint256 => NFTSellInfo )) _DepositNFT;
    
    struct NFTSellInfo {
        address payable _Seller;
        address payable _Buyer;
        uint256 _Price;
        uint256 _Saledate;
        bool    _Deposited;
        bool    _Selled;
    }
    
    event DepositNFT(address _nft , uint256 _TokenID , NFTSellInfo _NFTSelling);
    event buyNFTs(address _NFTAddress , uint256 _tokenId , address seller ,address buyer , uint256 buyprice);
    event CancelDeposit (address _nft , uint256 _tokenId , address canceller);

    modifier onlyNFTSeller (address _NFTAddress , uint256 _TokenId ) {
        require (_DepositNFT[_NFTAddress][_TokenId]._Seller  == msg.sender  , "MSG.SENDER is not NFT Seller.");
        require (_DepositNFT[_NFTAddress][_TokenId]._Deposited == true , "NFT not Deposited");
        _;
    } 

    modifier isNFTSale (address _NFTAddress , uint256 _TokenId , uint256 _Price ) {
        require (_DepositNFT[_NFTAddress][_TokenId]._Deposited == false , "NFT Aleady Deposit");
        require (_Price > 0 , "Price must be greater than 0 ");
        _;
    }

    modifier isOwnerOf(address _NFTAddress , uint256 _TokenId , address account) {
        require (account == IERC721(_NFTAddress).ownerOf(_TokenId) , "Seller is not Owner");
        _;
    }

    modifier isNFTBuy (address _NFTAddress , uint256 _TokenID , uint256 _Amount) {
        require (_Amount == fee(_DepositNFT[_NFTAddress][_TokenID]._Price) , "msg.value is not (price + fee)");
        _;
    }
    
    function depositNFT (address _NFTAddress , uint256 _TokenID , uint256 _Price) public 
        isOwnerOf(_NFTAddress , _TokenID , msg.sender)
        isNFTSale(_NFTAddress , _TokenID , _Price)
    {

        NFTSellInfo memory _info = NFTSellInfo({
            _Seller     : payable(msg.sender),
            _Buyer      : payable(address(0)),
            _Price      : _Price,
            _Saledate   : 0,
            _Deposited  : true,
            _Selled     : false
        });

        _DepositNFT[_NFTAddress][_TokenID] = _info;

        IERC721(_NFTAddress).safeTransferFrom( msg.sender , address(this), _TokenID);
        
        emit DepositNFT(_NFTAddress, _TokenID, _DepositNFT[_NFTAddress][_TokenID]);
    }
    
    function depositNFTOf (address _NFTAddress , uint256 _TokenID) public view returns(NFTSellInfo memory _info) {

        NFTSellInfo memory c = _DepositNFT[_NFTAddress][_TokenID];

        return c;
    }

    function cancelAtNFT (address _NFTAddress , uint256 _TokenID) public
        onlyNFTSeller(_NFTAddress , _TokenID ) 
    {

        NFTSellInfo storage c = _DepositNFT[_NFTAddress][_TokenID];

        c._Price = 0;
        c._Deposited = false;
        c._Seller = payable(address(0));
        
        IERC721(_NFTAddress).safeTransferFrom(address(this) , msg.sender , _TokenID);

        emit CancelDeposit(_NFTAddress, _TokenID , msg.sender);
    }

    function buyNFT ( address _NFTAddress , uint256 _TokenID ) public payable 
        isNFTBuy( _NFTAddress , _TokenID , msg.value)
    {   

        NFTSellInfo storage c = _DepositNFT[_NFTAddress][_TokenID];

        c._Buyer = payable(msg.sender);
        c._Saledate = block.timestamp;
        c._Selled = true;
        c._Deposited = false;

       
        IERC721(_NFTAddress).safeTransferFrom(address(this) , msg.sender , _TokenID);

        /* fee 분배. */
        feeAddr.sendValue(msg.value - c._Price);
        
        c._Seller.sendValue(c._Price);

        emit buyNFTs(_NFTAddress , _TokenID , c._Seller ,c._Buyer , c._Price);
    }

    function fee(uint256 _Price) internal pure returns(uint256 _fee) {
        _fee = _Price + (_Price * 4 / 100);
    }

    function changeFeeAddr(address payable _to) public onlyOwner {
        feeAddr = _to;
    }

    function getFeeAddr() public view returns (address) {
        return feeAddr;
    }

    
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <8.10.0;

import "./UserInfo.sol";
import "./NFTAnalytics.sol";
import "./Collectible.sol";
import "./Marketplace.sol";
import "../client/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../client/node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFTAuction {
    using SafeMath for uint256;

    UserInfo user;
    Auction[] auctions;
    Marketplace market;
    Collectible collectible;
    NFTAnalytics analytics;
    IERC20 public paymentToken;

    address owner;
    uint256 commission;
    mapping(uint256 => uint256) topBalance;
    mapping (address => uint) public userFunds;
    mapping(uint256 => mapping(bool => address)) winners;

    struct Bidder {
        uint256 _tokenId;
        address _address;
        uint256 _amount;
        uint256 _time;
        bool _withdraw;
    }
    struct Auction{
        uint256 _tokenId;
        string _tokenURI;
        uint256 _auctionId;
        address _address;
        uint256 _endTime;
        bool _active;
        bool _cancel;
        Bidder[] _bids;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Permission denied for this address");
        _;
    }

    event ClaimFunds(address user, uint amount);
    event CreateAuction(address _address, uint256 _tokenId, uint256 _endTime);
    event CancelAuction(address _address, uint256 _tokenId, uint256 _time);
    event Bid(address _address, uint256 _tokenId, uint256 _amount, uint256 _time);
    event Withdraw(address _address, uint256 _tokenId, uint256 _time);
    event EndAuction(uint256 _tokenId, uint256 _price, address _winner);

    constructor(address _nftCollection, address _user, address _market, address _analytics, address _paymentToken) {
        collectible = Collectible(_nftCollection);
        owner = payable(msg.sender);
        commission = collectible.commission();
        user = UserInfo(_user);
        market = Marketplace(_market);
        analytics = NFTAnalytics(_analytics);
         paymentToken = IERC20(_paymentToken);
    }


    function createAuction(uint256 _id, uint256 _endTime ) public {
        (,,, address _owner,, uint256 _royality,, bool _promoted, bool _approved,,) = collectible.tokenDetails(_id);

        require(_endTime > block.timestamp, 'error');
        require(msg.sender == collectible.ownerOf(_id), "error");
        collectible.transferFrom(msg.sender, address(this), _id);
        uint256 _auctionId = auctions.length;
        auctions.push();
        bool offer = analytics.offers(_id);
        Auction storage _auction = auctions[_auctionId];
        _auction._tokenId = _id;
        _auction._auctionId = _auctionId;
        _auction._endTime = _endTime;
        _auction._address = _owner;
        _auction._active = true;
        _auction._cancel = false;
        collectible.updateToken(_id, _owner, 0, _promoted, _approved, true, offer);
        analytics.setNFTTransactions(_id, _owner, address(this), 0);
        analytics.setTransaction(_id, _owner, address(this), 0);
        user.setActivity(_owner, 0, _royality, commission, "Create auction");
        emit CreateAuction(msg.sender, _id, _endTime);
    }

    function bid(uint256 _tokenId, uint256 _auctionId, uint256 _amount) public{
        (,,, address _owner,, uint256 _royality,,,,,) = collectible.tokenDetails(_tokenId);
        require(_amount > 0, "error");
        require(!checkUser(msg.sender, _tokenId), "error");
        require(msg.sender != _owner, "error");
        paymentToken.transferFrom(msg.sender, address(this), _amount);
        if (_amount > topBalance[_tokenId]) {
            topBalance[_tokenId] = _amount;
            winners[_tokenId][true] = msg.sender;
        }
        Auction storage _auction = auctions[_auctionId];
        _auction._bids.push(Bidder(_tokenId, msg.sender, _amount, block.timestamp, false));
        user.setActivity(msg.sender, _amount, _royality, commission, "Add Bid");
        emit Bid(msg.sender, _tokenId, _amount, block.timestamp);
    }

    function withdraw(uint256 _tokenId, uint256 _auctionId) public{
        (,,,,, uint256 _royality,,,,,) = collectible.tokenDetails(_tokenId);
        uint256 index = amount(_auctionId);
        uint256 _amount = auctions[_auctionId]._bids[index]._amount;
        require(_tokenId == auctions[_auctionId]._tokenId, "error");
        require( _amount > 0, "error");
        top_balance(_tokenId, _auctionId, msg.sender);
        paymentToken.transfer(msg.sender, _amount);
        auctions[_auctionId]._bids[index]._withdraw = true;
        user.setActivity(msg.sender, _amount, _royality, commission, "Withdraw from auction");
        emit Withdraw(msg.sender, _tokenId, block.timestamp);
    }

    function endAuction(uint256 _tokenId, uint256 _auctionId) public{
        (,, address _creator, address _owner,, uint256 _royality,,, bool _approved,,) = collectible.tokenDetails(_tokenId);
        address _winner = winners[_tokenId][true];
        if (_winner == address(0)) {
            analytics.setNFTTransactions(_tokenId, address(this), _owner, 0);
            return;
        }
        collectible.transferFrom(address(this), _winner, _tokenId);
        uint256 index = amount(_auctionId);
        auctions[_auctionId]._active = false;
        auctions[_auctionId]._address = _winner;
        auctions[_auctionId]._bids[index]._withdraw = true;
        uint256 _price = topBalance[_tokenId];
        topBalance[_tokenId] = 0;
        winners[_tokenId][true] = address(0);
        uint256 royality = royality_(_price, _royality);
        uint256 _commission = commission_(_price);
        userFunds[_owner] +=  _price.sub(_commission).sub(royality);
        userFunds[_creator] += royality;
        userFunds[owner] += _commission;
        market.setSellerFunds(_owner, _price);
        bool offer = analytics.offers(_tokenId);
        collectible.updateToken(_tokenId, _winner, _price, false, _approved, false, offer);
        analytics.setNFTTransactions(_tokenId, address(this), _winner, _price);
        user.setActivity(msg.sender, _price, _royality, commission, "End auction");
        analytics.setTransaction(_tokenId, address(this), _winner, _price);
        emit EndAuction(_tokenId, _price, _winner);
    }

    function cancelAuction(uint256 _tokenId, uint256 _auctionId) public{
    (,,, address _owner,, uint256 _royality,, bool _promoted, bool _approved,,) = collectible.tokenDetails(_tokenId);

    require(_owner == msg.sender, "error");
    collectible.transferFrom(address(this), _owner, _tokenId);
    bool offer = analytics.offers(_tokenId);
    collectible.updateToken(_tokenId, _owner, 0, _promoted, _approved, false, offer);
    auctions[_auctionId]._cancel = true;
    auctions[_auctionId]._active = false;
    user.setActivity(msg.sender, 0, _royality, commission, "End auction");
    analytics.setNFTTransactions(_tokenId, address(this), _owner, 0);
    analytics.setTransaction(_tokenId, address(this), _owner, 0);
    emit CancelAuction(msg.sender, _tokenId, block.timestamp);
    }

    function getAuctions() public view returns(Auction[] memory _auctions) {
        _auctions = new Auction[](auctions.length);
        for (uint256 i = 0; i < auctions.length; i++) {
            _auctions[i] = auctions[i];
        }
    }

    function claimProfits() public {
        require(userFunds[msg.sender] > 0, 'no funds');
        paymentToken.transfer(msg.sender, userFunds[msg.sender]);
        user.setActivity(msg.sender, userFunds[msg.sender], 0, 0, "Claim Funds");
        emit ClaimFunds(msg.sender, userFunds[msg.sender]);
        userFunds[msg.sender] = 0;    
    }

    function userBids(address _address) public view returns(Bidder[] memory _bids) {
        _bids = new Bidder[](auctions.length);
        for (uint256 i = 0; i < auctions.length; i++) {
            for (uint256 x = 0; x < auctions[i]._bids.length; x++) {
                if (auctions[i]._bids[x]._address == _address && auctions[i]._bids[x]._withdraw == false) {
                    _bids[i] = auctions[i]._bids[x];
                }else{
                    _bids[i] = Bidder(auctions[i]._bids[x]._tokenId, address(0), 0, 0, false);
                }
            }
        }
    }

    function unwanted(uint256[] memory _ids) public {
        collectible.unwanted(_ids);
        for (uint256 i = 0; i < _ids.length; i++) {
            for (uint256 x = 0; x < auctions.length; x++) {
                if (_ids[i] == auctions[x]._tokenId) {
                    delete auctions[x];
                }
            }
        }
    }

    function amount(uint256 _auctionId) private view returns(uint256 index){
        for (index = 0; index < auctions[_auctionId]._bids.length; index++) {
            if (auctions[_auctionId]._bids[index]._address == msg.sender && auctions[_auctionId]._bids[index]._withdraw == false) {
                return index;
            }
        }
    }

    function checkUser(address _address, uint256 _tokenId) private view returns(bool) {
        for (uint256 i = 0; i < auctions.length; i++) {
            if (auctions[i]._tokenId == _tokenId && auctions[i]._active == true) {
                for (uint256 index = 0; index < auctions[i]._bids.length; index++) {
                    if (auctions[i]._bids[index]._address == _address && auctions[i]._bids[index]._withdraw == false) return true;
                }
            } 
        }
        return false;
    }

    function commission_(uint256 price) private view returns(uint256){
            return (price.mul(commission)).div(1000);
    }

    function royality_(uint256 _price, uint256 _royality) private pure returns(uint256){
            return (_price.mul(_royality)).div(100);
    }

    function top_balance(uint256 _tokenId, uint256 _auctionId, address _address) private{
        uint256 _top;
        for (uint256 i = 0; i < auctions[_auctionId]._bids.length; i++) {
            if (auctions[_auctionId]._bids[i]._amount > _top) {
                topBalance[_tokenId] = auctions[_auctionId]._bids[i]._amount;
                winners[_tokenId][false] = _address;
            }
        }
    }
}
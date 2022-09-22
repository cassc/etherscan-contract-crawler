// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Tickets.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Eseats is Ownable, ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Tickets for Tickets.Ticket;
    Counters.Counter private _nextTokenId;

    mapping (uint256 => Tickets.Ticket) private _tickets;

    uint256[] public price;
    uint256[] public supply;
    uint256[] public expiry;
    address public rewardToken;
    address public paymentToken;
    // Close check-in immediately by owner
    bool public isCheckInClosed = false;
    // Finish event immediately by owner 
    bool public isEventFinished = false;
    bool private _isEventActive = true;
    uint public eventType;
    mapping(address => bool) private _officers;
    uint256[] private _checkedIn;
    string private _baseTokenURI;
    bool private _isRewardable = false;
    bool private _isBurnable = false;

    event TicketPurchased(
        uint256 indexed tokenId,
        uint256 ticketType,
        address indexed user
    );

    event CheckIn(
        uint256 indexed tokenId,
        address indexed user,
        uint256 ticketType,
        uint256 checkInAt
    );

    modifier whenActive() {
        require(_isEventActive == true, "e1");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_,
        address paymentToken_,
        uint eventType_,
        address rewardToken_
    )
        ERC721(name, symbol)
    {
        _baseTokenURI = baseTokenURI_;
        paymentToken = paymentToken_;
        eventType = eventType_;
        rewardToken = rewardToken_;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current();
    }

    function tokensOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }

    function setTicket(uint256[] memory _supply, uint256[] memory _expiry, uint256[] memory _price) external onlyOwner {
        supply = _supply;
        expiry = _expiry;
        price = _price;
    }

    function buy(uint256 _ticketType, uint256 qty, bytes32[] memory _metadata) external whenActive {
        // require(price[_ticketType] > 0, "e2");
        require(supply[_ticketType] + qty >= 0, "e3");

        for(uint256 i = 0; i < qty; i++) {
            _mintTicket(_ticketType, msg.sender, _metadata);
        } 
        IERC20(paymentToken).transferFrom(msg.sender, address(this), price[_ticketType]*qty);
    }

    function _mintTicket(uint256 _ticketType, address _receiver, bytes32[] memory _metadata) internal {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        supply[_ticketType] -= 1;
        _mint(_receiver, currentTokenId);

        Tickets.Ticket storage ticket = _tickets[currentTokenId];
        ticket.mapMinted(expiry[_ticketType], _ticketType, _metadata);

        emit TicketPurchased(currentTokenId, _ticketType, _receiver);
    }

    function offlineCheckIn(address attendee, uint256 tokenId) external {
        require(_officers[msg.sender], "e4");
        require(isCheckInClosed == false, "e5");
        require(eventType == 0, "e6");

        _checkIn(attendee, tokenId);
    }

    function _checkIn(address attendee, uint256 tokenId) internal {
        Tickets.Ticket storage ticket = _tickets[tokenId];
        require(ownerOf(tokenId) == attendee, "e13");
        require(ticket.state == Tickets.TicketState.UNUSED, "e14");
        require(ticket.expiredAt > block.timestamp, "e15");
        ticket.checkIn();
        _checkedIn.push(tokenId);

        emit CheckIn(tokenId, attendee, ticket.ticketType, block.timestamp);
        if(_isBurnable) {
            _burn(tokenId);
        }
    }

    function setBaseTokenURI(string memory baseTokenURI_) external onlyOwner {
        _baseTokenURI = baseTokenURI_;
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(_exists(tokenId), "e7");

        if(supply.length > 1) {
            return string(abi.encodePacked(_baseTokenURI, viewTicket(tokenId).ticketType.toString()));
        }

        return string(abi.encodePacked(_baseTokenURI, '0'));
    }

    function toggleCheckIn() external onlyOwner whenActive {
        isCheckInClosed = !isCheckInClosed;
    }

    function toggleFO(address officer) external onlyOwner whenActive {
        require(eventType == 0, "e6");

        _officers[officer] = !_officers[officer];
    }

    function toggleActive() external onlyOwner {
        _isEventActive = !_isEventActive;
    }
    
    function endEvent() external onlyOwner {
        isEventFinished = true;
    }

    function withdrawToken(address tokenContract_, uint256 amount_) external onlyOwner {
        IERC20 tokenContract = IERC20(tokenContract_);
        tokenContract.transfer(msg.sender, amount_);
    }

    function withdrawCoin(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function setRewardable(bool _rewardable) external onlyOwner {
        _isRewardable = _rewardable;
    }

    function setBurnable(bool _burnable) external onlyOwner {
        _isBurnable = _burnable;
    }

    function rewardAmount() public view returns (uint256) {
        require(_checkedIn.length > 0, "e8");

        return IERC20(rewardToken).balanceOf(address(this)) / _checkedIn.length;
    }

    function sendReward() external onlyOwner {
        require(_isRewardable == true, "e9");
        require(isEventFinished == true, "e10");
        require(IERC20(rewardToken).balanceOf(address(this)) > 0, "e11");

        for(uint256 i = 0; i < _checkedIn.length; i++) {
            IERC20(rewardToken).transfer(ownerOf(_checkedIn[i]), rewardAmount());
        }
    }

    function setPaymentToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "e12");

        paymentToken = _tokenAddress;
    }

    function setRewardToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "e12");

        rewardToken = _tokenAddress;
    }

    function viewTicket(uint256 _tokenId) public view returns(Tickets.Ticket memory){
        return _tickets[_tokenId];
    }
}
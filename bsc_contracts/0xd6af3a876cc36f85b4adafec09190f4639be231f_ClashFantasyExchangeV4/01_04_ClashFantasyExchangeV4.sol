// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IClashFantasyCards {
    function updateCardState(address _from, uint256 _tokenId, uint _state) external; 
    function getCardState(address _from, uint256 _tokenId) external view returns(uint);
    function getCard(uint256 _tokenId) external view returns(uint256, bool, address, uint, uint, uint256);
    function transferTo( address from, address to, uint256 id, uint256 amount) external;
    function balanceOf(address _address, uint256 _tokenId) external view returns (uint256);
}

contract ClashFantasyExchangeV4 is Initializable {
    IClashFantasyCards private contractCards;
    IERC20 private contractErc20;
    address private adminContract;
    
    address private walletPrimary;
    address private walletSecondary;

    uint percentage;
    
    struct HistoryCardExchange {
        address from;
        address to;
        uint256 price;
        uint percentage;
        uint256 timestamp;
        uint256 typeOf;
    }

    struct CardExchange {
        uint256 token;
        uint256 price;
        uint percentage;
        bool exists;
        uint256 timestamp;
    }

    mapping(uint256 => CardExchange) public cardExchanges;

    mapping(uint256 => HistoryCardExchange[]) public historyCardExchanges;

    CardExchange[] cardExchangeArr;

    mapping (uint256 => bool) private _cardIsBlackList;

    modifier onlyAdminOwner() {
        require(
            adminContract == msg.sender,
            "Only the contract admin owner can call this function"
        );
        _;
    }

    modifier isOwnerCard(uint256 _tokenId) {
        uint256 _balanceOf = contractCards.balanceOf(msg.sender, _tokenId);
        require(_balanceOf >= 1, "Check balance token");
        _;
    }

    event HistoryCard(address from, address to, uint256 price, uint256 action );

    function initialize(IClashFantasyCards _contractCards, IERC20 _token) public initializer {
        contractCards = _contractCards;
        contractErc20 = _token;
        adminContract = msg.sender;
        walletPrimary = msg.sender;
        walletSecondary = msg.sender;
        percentage = 15;
    }

    function withdrawCard(uint256 _tokenId) 
        public
        isOwnerCard(_tokenId)
    {
        require(cardExchanges[_tokenId].exists == true, "Card Not In Sale");

        contractCards.updateCardState(msg.sender, _tokenId, 1);
        delete cardExchanges[_tokenId];
    
        removeByValue(_tokenId);
    }

    function transferCard(uint256 _tokenId, address _to) 
        public
        isOwnerCard(_tokenId)
    {
        require(cardExchanges[_tokenId].exists == false, "Card In Sale");
        (uint cardState) = contractCards.getCardState(msg.sender, _tokenId);
        require(cardState == 1, "Card Must Be In Inventory");
        
        contractCards.transferTo(msg.sender, _to, _tokenId, 1);
    }

    function sellCard(uint256 _tokenId) public {
        CardExchange storage card = cardExchanges[_tokenId];
        require(card.exists == true, "Card Not In Sale");
        require(_cardIsBlackList[_tokenId] == false, "Your Card is black listed by Owner");

        (,, address wallet,,,) = contractCards.getCard(_tokenId);

        uint256 resultPrice = card.price * 10**18;
        checkBalanceAllowanceToken(resultPrice);

        transferAmount(resultPrice, card.percentage, wallet);
        
        contractCards.transferTo(wallet, msg.sender, _tokenId, 1);

        historyCardExchanges[_tokenId].push(
            HistoryCardExchange(
                wallet,
                msg.sender,
                card.price,
                card.percentage,
                block.timestamp,
                0
            )
        );

        delete cardExchanges[_tokenId];
        removeByValue(_tokenId);
    }
    
    function includeCard(uint256 _tokenId, uint256 _price)
        public
        isOwnerCard(_tokenId)
    {
        require(_cardIsBlackList[_tokenId] == false,"Your Card is black listed by Owner");
        require(cardExchanges[_tokenId].exists == false, "Card Already In Sale");
        (uint cardState) = contractCards.getCardState(msg.sender, _tokenId);
        require(cardState == 1, "Card Must Be In Inventory");

        contractCards.updateCardState(msg.sender, _tokenId, 0);

        cardExchangeArr.push(
            CardExchange(
                _tokenId, _price, percentage, true, block.timestamp
            )
        );

        cardExchanges[_tokenId] = CardExchange(
            _tokenId, _price, percentage, true, block.timestamp
        );
    }

    function find(uint value) internal view returns(uint) {
        uint i = 0;
        while (cardExchangeArr[i].token != value) {
            i++;
        }
        return i;
    }

    function removeByValue(uint value) internal {
        uint i = find(value);
        removeByIndex(i);
    }

    function removeByIndex(uint _index) internal {
        cardExchangeArr[_index] = cardExchangeArr[cardExchangeArr.length-1];
        cardExchangeArr.pop();
    }

    function checkBalanceAllowanceToken(uint256 _price) internal view{
        uint256 balance = contractErc20.balanceOf(msg.sender);
        require(balance >= _price, "Check the token balance");

        uint256 allowance = contractErc20.allowance(msg.sender, address(this));
        require(allowance == _price, "Check the token allowance");
    }

    function getHistoryCardByTokenId(uint256 _tokenId) 
        public view returns(HistoryCardExchange[] memory)
    {
        return historyCardExchanges[_tokenId];
    }

    function getCards()  public view returns(CardExchange[] memory) {
        return cardExchangeArr;
    }

    function getCardInfo(uint256 _tokenId) 
        public view 
        returns(CardExchange memory)
    {
        CardExchange storage card = cardExchanges[_tokenId];
        return card;
    }

    function isCardBlackListed(uint256 _tokenId) public view returns(bool) {
        return _cardIsBlackList[_tokenId];
    }

    function transferAmount(uint256 _amount, uint _percentage , address wallet)
        internal
    {
        uint toSender = ( (100 - _percentage ) * 10 );
        uint toDivide = ( (_percentage ) * 10 ) / 2;

        uint256 normalTransfer = (_amount / uint256(1000)) * uint256(toSender);
        uint256 half = (_amount / uint256(1000)) * uint256(toDivide);
        
        contractErc20.transferFrom(msg.sender, wallet, normalTransfer);
        contractErc20.transferFrom(msg.sender, walletPrimary, half);
        contractErc20.transferFrom(msg.sender, walletSecondary, half);
    }

    function updateContractCards(IClashFantasyCards _address) 
        public onlyAdminOwner
    {
        contractCards = _address;
    }

    function setCardBlackListStatus(uint256 _tokenId, bool status) public onlyAdminOwner {
        _cardIsBlackList[_tokenId] = status;
    }

    function updateWalletPrimary(address _address) public onlyAdminOwner {
        walletPrimary = _address;
    }

    function updateWalletSecondary(address _address) public onlyAdminOwner {
        walletSecondary = _address;
    }

    function updatePercentage(uint _percentage) public onlyAdminOwner {
        percentage = _percentage;
    }

    function getAdmin() public view returns(address){
        return adminContract;
    }
    
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function version() public pure returns (string memory) {
        return "v4";
    }
    
}
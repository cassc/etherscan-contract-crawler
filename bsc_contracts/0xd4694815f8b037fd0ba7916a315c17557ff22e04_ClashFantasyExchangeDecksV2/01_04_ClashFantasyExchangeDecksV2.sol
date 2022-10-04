// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IClashFantasyDecks {
    function updateDeckState(
        address _from,
        uint256 _tokenId,
        uint256 _state
    ) external;

    function balanceOf(address _owner, uint256 _tokenId) external view returns (uint balance);

    function getDeckInfo(uint256 _tokenId)
        external
        view
        returns (
            uint256, //token
            bool, //exists
            address, //wallet
            uint256, //length
            uint256 //isFree
        );

    function getDeckById(address _from, uint256 _tokenId)
        external
        view
        returns (
            uint256, //typeOf
            uint256, //deckLevel
            uint256, //activatePoint
            uint256, //manaSum
            uint256, //fansySum
            uint256, //deckState
            uint256  //amount
        );

    function transferTo(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;
}

contract ClashFantasyExchangeDecksV2 is Initializable {
    IClashFantasyDecks private contractDecks;
    IERC20 private contractErc20;
    address private adminContract;

    address private walletPrimary;
    address private walletSecondary;

    uint256 percentage;

    struct HistoryDeckExchange {
        address from;
        address to;
        uint256 price;
        uint256 percentage;
        uint256 timestamp;
        uint256 typeOf;
    }

    struct DeckExchange {
        uint256 token;
        uint256 price;
        uint256 percentage;
        bool exists;
        uint256 timestamp;
        uint256 activatePoint;
        uint256 level;
    }

    mapping(uint256 => DeckExchange) public deckExchanges;

    mapping(uint256 => HistoryDeckExchange[]) public historyDeckExchanges;

    DeckExchange[] cardExchangeArr;

    modifier onlyAdminOwner() {
        require(
            adminContract == msg.sender,
            "Only the contract admin owner can call this function"
        );
        _;
    }

    modifier isOwnerDeck(uint256 _tokenId) {
        (, , address wallet, ,) = contractDecks.getDeckInfo(_tokenId);
        require(wallet == msg.sender, "Sender must be the owner of the card.");
        _;
    }

    event HistoryDeck(address from, address to, uint256 price, uint256 action);

    function initialize(IClashFantasyDecks _contractDecks, IERC20 _token) public initializer {
        contractDecks = _contractDecks;
        contractErc20 = _token;
        adminContract = msg.sender;
        percentage = 15;
    }

    function withdrawDeck(uint256 _tokenId) public isOwnerDeck(_tokenId) {
        require(deckExchanges[_tokenId].exists == true, "Deck Not In Sale");

        contractDecks.updateDeckState(msg.sender, _tokenId, 1);
        delete deckExchanges[_tokenId];

        removeByValue(_tokenId);
    }

    function transferDeck(uint256 _tokenId, address _to) public 
    {
        require(deckExchanges[_tokenId].exists == false, "Deck In Sale");
        (, , address wallet, uint256 amountCards, uint256 isFree) = contractDecks.getDeckInfo(_tokenId);

        require(wallet == msg.sender, "Sender must be the owner of the card.");
        require(isFree == 0, "Deck Gift");
        require(amountCards == 0, "Deck Must be Empty before transfer");

        contractDecks.transferTo(wallet, _to, _tokenId, 1);

        historyDeckExchanges[_tokenId].push(
            HistoryDeckExchange(wallet, _to, 0, deckExchanges[_tokenId].price, block.timestamp, 1)
        );

        emit HistoryDeck(wallet, _to, 0, 1);
    }

    function sellCard(uint256 _tokenId) public {
        DeckExchange storage card = deckExchanges[_tokenId];
        require(card.exists == true, "Deck Not In Sale");

        (, , address wallet, , ) = contractDecks.getDeckInfo(_tokenId);

        uint256 resultPrice = card.price * 10**18;
        checkBalanceAllowanceToken(resultPrice);

        transferAmount(resultPrice, card.percentage, wallet);

        contractDecks.transferTo(wallet, msg.sender, _tokenId, 1);

        historyDeckExchanges[_tokenId].push(
            HistoryDeckExchange(wallet, msg.sender, card.price, card.percentage, block.timestamp, 0)
        );

        delete deckExchanges[_tokenId];
        removeByValue(_tokenId);

        emit HistoryDeck(wallet, msg.sender, 0, 0);
    }

    function includeDeck(uint256 _tokenId, uint256 _price) public 
    {
        require(deckExchanges[_tokenId].exists == false, "Deck Already In Sale");
        require(contractDecks.balanceOf(msg.sender, _tokenId) > 0, "ERC1155: check token balance");

        (,
        uint256 deckLevel,
        uint256 activatePoint,
        ,
        ,
        ,
        ) = contractDecks.getDeckById(msg.sender, _tokenId);
        (, , , uint256 amountCards, uint256 isFree) = contractDecks.getDeckInfo(_tokenId);
        
        require(amountCards == 0, "Deck Must be Empty before transfer");
        require(isFree == 0, "Deck Gift");

        contractDecks.updateDeckState(msg.sender, _tokenId, 0);

        cardExchangeArr.push(DeckExchange(_tokenId, _price, percentage, true, block.timestamp, activatePoint, deckLevel));

        deckExchanges[_tokenId] = DeckExchange(_tokenId, _price, percentage, true, block.timestamp, activatePoint, deckLevel);
    }

    function find(uint256 value) internal view returns (uint256) {
        uint256 i = 0;
        while (cardExchangeArr[i].token != value) {
            i++;
        }
        return i;
    }

    function removeByValue(uint256 value) internal {
        uint256 i = find(value);
        removeByIndex(i);
    }

    function removeByIndex(uint256 i) internal {
        while (i < cardExchangeArr.length - 1) {
            cardExchangeArr[i] = cardExchangeArr[i + 1];
            i++;
        }
        cardExchangeArr.pop();
    }

    function checkBalanceAllowanceToken(uint256 _price) internal view {
        uint256 balance = contractErc20.balanceOf(msg.sender);
        require(balance >= _price, "Check the token balance");

        uint256 allowance = contractErc20.allowance(msg.sender, address(this));
        require(allowance == _price, "Check the token allowance");
    }

    function getHistoryDeckByTokenId(uint256 _tokenId)
        public
        view
        returns (HistoryDeckExchange[] memory)
    {
        return historyDeckExchanges[_tokenId];
    }

    function getDecks() public view returns (DeckExchange[] memory) {
        return cardExchangeArr;
    }

    function getDeckInfo(uint256 _tokenId) public view returns (DeckExchange memory) {
        DeckExchange storage deck = deckExchanges[_tokenId];
        return deck;
    }

    function updateContractDecks(IClashFantasyDecks _address) public onlyAdminOwner {
        contractDecks = _address;
    }

    function transferAmount(
        uint256 _amount,
        uint256 _percentage,
        address wallet
    ) internal {
        uint256 toSender = ((100 - _percentage) * 10);
        uint256 toDivide = ((_percentage) * 10) / 2;

        uint256 normalTransfer = (_amount / uint256(1000)) * uint256(toSender);
        uint256 half = (_amount / uint256(1000)) * uint256(toDivide);

        contractErc20.transferFrom(msg.sender, wallet, normalTransfer);
        contractErc20.transferFrom(msg.sender, walletPrimary, half);
        contractErc20.transferFrom(msg.sender, walletSecondary, half);
    }

    

    function updateWalletPrimary(address _address) public onlyAdminOwner {
        walletPrimary = _address;
    }

    function updateWalletSecondary(address _address) public onlyAdminOwner {
        walletSecondary = _address;
    }

    function updatePercentage(uint256 _percentage) public onlyAdminOwner {
        percentage = _percentage;
    }

    function getAdmin() public view returns (address) {
        return adminContract;
    }

    function getWalletVault() public view returns (address, address) {
        return (walletPrimary, walletSecondary);
    }
    
    function getPercentage() public view returns(uint256) {
        return percentage;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
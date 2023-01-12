// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IStdReference.sol";

contract BKSNFT is ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    struct EventInfo {
        address owner;
        uint256 currency;
        address[] payees;
        uint256[] fees;
        uint256 price;
        uint256 number;
        uint256 minted;
    }

    event EventAdded(
        string eventName,
        uint256 currency,
        address indexed owner,
        address[] payees,
        uint256[] fees,
        uint256 price,
        uint256 number
    );
    event EventUpdated(
        string eventName,
        uint256 currency,
        address indexed owner,
        address[] payees,
        uint256[] fees,
        uint256 price
    );
    event EventRemoved(string eventName, address indexed owner);
    event TicketSold(string eventName);
    event NewOracleSet(address newAddr);
    event Minted(uint256 tokenId, string tokenURI);

    mapping(string => EventInfo) public eventInfo;

    uint256 private constant DECIMAL = 1000000000000000000;
    uint256 DOUBLE = 1000;

    AggregatorV3Interface internal priceFeed;
    ERC20 BUSD;
    IStdReference public _ORACLE;
    address owner_;

    Counters.Counter private _tokenIds;
    mapping(string => bool) public tokenURIExists;

    constructor(
        address busdAddr,
        address oracleAddr,
        address chainlinkAddr
    ) ERC721("BKSNFT", "NFT") {
        owner_ = msg.sender;
        BUSD = ERC20(busdAddr);
        _ORACLE = IStdReference(oracleAddr);
        priceFeed = AggregatorV3Interface(chainlinkAddr);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintNFT(
        address recipient,
        string memory _tokenURI
    ) public onlyOwner {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        tokenURIExists[_tokenURI] = true;

        emit Minted(newItemId, _tokenURI);
    }

    function getTokenURIExists(string memory _tokenURI)
        public
        view
        returns (bool)
    {
        return tokenURIExists[_tokenURI];
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function transforNFT(address recipient, uint256 _tokenId) external {
        // uint256 price = PRICE;
        // require(msg.value >= price, "Incorrect value");

        _transfer(msg.sender, recipient, _tokenId);
        // payable(msg.sender).transfer(PRICE); // send the ETH to the recipient
    }

    function changeOwner(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }

    /**
     * @dev create the new event
     * @param payees transaction fee payees
     */
    function addEvent(
        string memory eventName,
        uint256 currency,
        address[] memory payees,
        uint256[] memory fees,
        uint256 price,
        address walletAddress,
        uint256 ticketNumber
    ) external {
        eventInfo[eventName].owner = walletAddress;
        eventInfo[eventName].currency = currency;
        eventInfo[eventName].payees = payees;
        eventInfo[eventName].fees = fees;
        eventInfo[eventName].price = price;
        eventInfo[eventName].number = ticketNumber;
        eventInfo[eventName].minted = 0;

        emit EventAdded(
            eventName,
            currency,
            walletAddress,
            payees,
            fees,
            price,
            ticketNumber
        );
    }

    /**
     * @dev update specific event
     * @dev only owner can update event info
     * @param payees transaction fee payee
     */
    function updateEvent(
        string memory eventName,
        uint256 currency,
        address[] memory payees,
        uint256[] memory fees,
        uint256 price,
        uint256 ticketNumber
    ) external {
        require(
            msg.sender == eventInfo[eventName].owner,
            "Only owner can remove event"
        );
        eventInfo[eventName].payees = payees;
        eventInfo[eventName].currency = currency;
        eventInfo[eventName].fees = fees;
        eventInfo[eventName].price = price;
        eventInfo[eventName].number = ticketNumber;

        emit EventUpdated(eventName, currency, msg.sender, payees, fees, price);
    }

    /**
     * @dev update specific event
     * @dev only onwer can remove event
     */
    function removeEvent(string memory eventName) external {
        require(
            msg.sender == eventInfo[eventName].owner,
            "Only owner can remove event"
        );
        delete eventInfo[eventName];
        emit EventRemoved(eventName, msg.sender);
    }

    function setNewOracle(address newAddr) external onlyOwner {
        _ORACLE = IStdReference(newAddr);
        emit NewOracleSet(newAddr);
    }

    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function getRate(string memory rate1, string memory rate2)
        public
        view
        returns (uint256)
    {
        IStdReference.ReferenceData memory data = _ORACLE.getReferenceData(
            rate1,
            rate2
        );
        return data.rate / DECIMAL;
    }

    function getUSDRate(uint256 eur) public view returns (uint256) {
        uint256 _bEur = getRate("BNB", "EUR");
        uint256 _bUsd = getRate("BNB", "USD");
        return (((eur * _bUsd * DOUBLE) / _bEur) * DECIMAL) / DOUBLE;
    }

    function payWithBUSD(
        address buyer,
        string memory eventName,
        uint256 _amount
    ) external {
        address[] memory payees = eventInfo[eventName].payees;
        uint256[] memory fees = eventInfo[eventName].fees;
        uint256 usdAmount = eventInfo[eventName].price * _amount * 10000000;
        uint256 eurAmount = uint256(getLatestPrice()) *
            eventInfo[eventName].price *
            _amount *
            10000000;
        uint256 amount = 0;
        if (eventInfo[eventName].currency == 1) {
            amount = usdAmount;
        } else {
            amount = eurAmount;
        }
        uint256 allowance = BUSD.allowance(buyer, address(this));
        require(allowance >= amount, "Not enough BUSD");
        BUSD.transferFrom(buyer, address(this), amount);
        uint256 len = payees.length;
        uint256 percent = 1000;
        uint256 total = amount;
        for (uint256 i = 0; i < len; i++) {
            percent += fees[i];
        }
        for (uint256 i = 0; i < len; i++) {
            uint256 _payee = (amount * fees[i]) / percent;
            BUSD.transfer(payees[i], _payee);
            total = total - _payee;
        }
        BUSD.transfer(eventInfo[eventName].owner, total);
    }
}
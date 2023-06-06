// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PinMasterCharacters is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    //Chainlink price feed
    AggregatorV3Interface internal _priceFeed;

    //Number of Characters that has been minted
    Counters.Counter public _characterIds;

    //Price required for buying a ticket
    int256 public _usdPrice;

    //Number of tickets that each account has
    mapping(address => uint256) public _tickets;

    //Number of tickets left to sell
    uint256 public _ticketsLeft;

    /**
    * @dev Event emitted when token a Ticket is bought by `buyer`.
    */
    event TicketBought(address indexed buyer, uint256 indexed tickets);

    /**
    * @dev Event emitted when a character with `characterId` is created by `creator`
    */
    event CharacterCreated(address indexed creator, uint256 indexed characterId);
    
    /**
    * @dev Set the `initialPrice` for selling the ticket and the Chainlink oracle address. Initializes ERC721
    *
    * Rinkeby: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    * Mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    */
    constructor(int256 initialPrice, uint256 max_supply, address _priceFeedAddress) ERC721("PinMasterCharacters", "PMC") {
        _usdPrice = initialPrice;
        _ticketsLeft = max_supply;
        _priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    /**
    * @dev Override burn function
    */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
    * @dev Override tokenURI function
    */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
    * @dev Buy a ticket. An event will be emitted once the ticket is bought. 
    *      The sender needs to sent enough ether to cover the ticket costs, that is initially
    *      set in USD and converted to ether through the ChainLink Oracle
    */
    function buyTicket(int amount) external payable {
        require(_ticketsLeft - uint(amount) >= 0, "Not enough tickets left");
        require(amount > 0, "Minimum purchase is 1 ticket");
        int price = this.getLatestPrice();
        int etherCost = ((amount * _usdPrice * (10 ** 16)) / price);
        int etherSent = (int)(msg.value / (10 ** 10));
        require(etherSent >= etherCost, "Not enough Ether sent");
        _tickets[msg.sender] += uint(amount);
        _ticketsLeft -= uint(amount);
        emit TicketBought(msg.sender, _tickets[msg.sender]);
    }

    /**
    * @dev Get the latest ETH/USD price using ChainLink oracle
    */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = _priceFeed.latestRoundData();
        return price;
    }

    /**
    * @dev If the `msg.sender` has a ticket, it mints a new ERC721 with `characterURI`.
    *      An event is emitted when the ERC721 token is minted.
    */    
    function mintCharacter(string memory characterURI) external {
        require(_tickets[msg.sender] >= 1, "Don't have enough tickets");
        _characterIds.increment();
        _mint(msg.sender, _characterIds.current());
        _setTokenURI(_characterIds.current(), characterURI);
        _tickets[msg.sender] -= 1;
        emit CharacterCreated(msg.sender, _characterIds.current());
    }

    /**
    * @dev Allows the owner to withdraw the ETH contained in the Smart Contract
    */
    function withdraw() public onlyOwner{
        require(address(this).balance > 0, "Balance is 0");
        payable(owner()).transfer(address(this).balance);
    }

}
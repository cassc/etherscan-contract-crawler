// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**

███████╗██╗   ██╗██████╗ ███████╗██████╗ ███████╗██╗   ██╗███████╗███████╗
██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗██╔════╝██║   ██║╚══███╔╝╚══███╔╝
███████╗██║   ██║██████╔╝█████╗  ██████╔╝█████╗  ██║   ██║  ███╔╝   ███╔╝
╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗██╔══╝  ██║   ██║ ███╔╝   ███╔╝
███████║╚██████╔╝██║     ███████╗██║  ██║██║     ╚██████╔╝███████╗███████╗
╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚══════╝╚══════╝

*/

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SuperFuzzGoldTicket is Ownable, ERC721URIStorage, ERC721Enumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    string public PROVENANCE = "";
    uint256 public MAX_TICKETS = 200;
    uint256 public TICKET_PRICE = 0.05 ether;
    bool public isSaleActive = true;
    string private _baseURIextended;
    mapping(address => bool) public hasTicket;
    address[] private airDropList;
    uint256 public mintedTokens;

    constructor() ERC721("Superfuzz Gold Ticket", "SFGT") {
        _baseURIextended = "ipfs://bafybeibswqatpdonago5bfnxyudqcpxnch4vary4lbqqwxuaxljkzhvwoa/";
    }

    event TicketMinted(address _addresss);
    event WhiteListMutated(address[] _whiteList, address _address);
    event IncreaseSupply(uint256 _currentSupply);

    /* Where all of the magic happens */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setTicketPrice(uint256 _price) external onlyOwner {
        TICKET_PRICE = _price;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        TICKET_PRICE = _newPrice;
    }

    function setMaxTickets(uint256 _newMax) external onlyOwner {
        MAX_TICKETS = _newMax;
    }

    function increaseSupply() internal {
        _tokenIds.increment();
        mintedTokens = _totalSupply();
        emit IncreaseSupply(mintedTokens);
    }

    function _totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function setProvenanceHash(string memory _provenanceHash)
    external
    onlyOwner
    {
        PROVENANCE = _provenanceHash;
    }

    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function addToAirDropList(address _to) internal {
        airDropList.push(_to);
    }

    function getAirDropList() external view returns (address[] memory) {
        return airDropList;
    }

    function airDropTicket(address _to) external onlyOwner {
        // set rule address can only have one ticket
        require(
            hasTicket[_to] == false,
            "Cannot own more than one Gold Ticket"
        );
        require(_totalSupply() < MAX_TICKETS, "DONE MINTING");
        require(isSaleActive, "Sale must be active to mint SuperFuzz");
        require(
            _totalSupply().add(1) <= MAX_TICKETS,
            "Purchase would exceed max supply of SuperFuzz"
        );
        uint256 id = _totalSupply() + 1;
        _safeMint(_to, id);
        hasTicket[_to] = true;
        addToAirDropList(_to);
        increaseSupply();
        emit TicketMinted(msg.sender);
    }

    function airDropManyTickets(address[] memory _addr) external onlyOwner {
        // this needs to accept and array of address and iterate through them
        // use the array length for the loop
        uint256 _amount = _addr.length;
        require(
            _totalSupply() < MAX_TICKETS,
            "No More tickets left! Try again next time"
        );
        require(isSaleActive, "Sale must be active to mint SuperFuzz");
        require(
            _totalSupply().add(1) <= MAX_TICKETS,
            "Purchase would exceed max supply of SuperFuzz"
        );
        for (uint256 i = 0; i < _amount; i++) {
            require(
                hasTicket[_addr[i]] == false,
                "Cannot own more than one Gold Ticket"
            );
            uint256 id = _totalSupply() + 1;
            _safeMint(_addr[i], id);
            hasTicket[_addr[i]] = true;
            addToAirDropList(_addr[i]);
            increaseSupply();
            emit TicketMinted(msg.sender);
        }
    }

    function claimTicket() external {
        // this is the main function that will be called
        address _to = msg.sender;
        require(hasTicket[_to] == false, "Cannot Buy more than one");
        require(
            _totalSupply() < MAX_TICKETS,
            "No More tickets left! Try again next time"
        );
        require(isSaleActive, "Sale must be active to mint Gold Tickets");
        require(
            _totalSupply().add(1) <= MAX_TICKETS,
            "Purchase would exceed max supply of Gold Tickets"
        );
        uint256 id = _totalSupply() + 1;
        _safeMint(_to, id);
        hasTicket[_to] = true;
        addToAirDropList(_to);
        increaseSupply();
        emit TicketMinted(_to);
    }

    function buyTicket() external payable {
        address _to = msg.sender;
        require(msg.value == TICKET_PRICE, "Not enough ETH, try againg");
        require(hasTicket[_to] == false, "Cannot Buy more than one");
        require(
            _totalSupply() < MAX_TICKETS,
            "No More tickets left! Try again next time"
        );
        require(isSaleActive, "Sale must be active to mint Gold Tickets");
        require(
            _totalSupply().add(1) <= MAX_TICKETS,
            "Purchase would exceed max supply of Gold Tickets"
        );
        uint256 id = _totalSupply() + 1;
        _safeMint(_to, id);
        hasTicket[_to] = true;
        addToAirDropList(_to);
        increaseSupply();
        emit TicketMinted(_to);
    }

    function tokensOfOwner(address owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    // Add payable distribution with withdraw

    // OVERRIDES

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
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
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**

███████╗██╗   ██╗██████╗ ███████╗██████╗ ███████╗██╗   ██╗███████╗███████╗
██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗██╔════╝██║   ██║╚══███╔╝╚══███╔╝
███████╗██║   ██║██████╔╝█████╗  ██████╔╝█████╗  ██║   ██║  ███╔╝   ███╔╝
╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗██╔══╝  ██║   ██║ ███╔╝   ███╔╝
███████║╚██████╔╝██║     ███████╗██║  ██║██║     ╚██████╔╝███████╗███████╗
╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚══════╝╚══════╝

**/

import "./SuperFuzzGoldTicket.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract SuperFuzzBadBatch is ERC721URIStorage, ERC721Enumerable, Pausable, PaymentSplitter {

    using SafeMath for uint;
    using Counters for Counters.Counter;

    enum Status {
        Closed,
        PresaleStart,
        PublicSaleStart
    }

    Counters.Counter private _tokenIds;
    string public PROVENANCE = "";
    string private _baseURIextended;
    uint constant public MAX_MONSTERS = 777;
    uint public MONSTER_PRICE = 0.07 ether;
    uint public maxPerTx = 1;
    uint public maxPerWallet = 2;
    uint public presaleStartTime = 1630868400; // 12pm PST
    uint public publicSaleStartTime = presaleStartTime + 9 hours; // starts 9 hours after the presale
    mapping(address => uint) public howManyMonsters;
    mapping(address => bool) private isTeam;
    mapping(address => bool) private hasGoldTicket;
    mapping(address => bool) private isOnWhiteList;
    address private GoldTicketAddress = 0x77f9a627A41b39c23469a7111f91C8487582c019;
    SuperFuzzGoldTicket goldTicket;

    // Team Address

    address[] private _team = [
        0x0C88ECF7FeEbBA1755282B87F5bDbF5A4b5eA08C, // 85 - Core team
        0x290cB1eA2653Afcd1e3e5a89dDB49ccb2737Fd67, // 10 - Dev
        0x9247502d319A57eF23A602ABcC4B1d0f180e3BC7 // 5 - Gen Art
    ];

    // team address payout shares

    uint256[] private _team_shares = [85, 10, 5];

    constructor()
        ERC721("Superfuzz: The Bad Batch", "SFBB")
        PaymentSplitter(_team, _team_shares)
    {
        _baseURIextended = "ipfs://bafybeih2sek4zgiwh2djnrxnkjdoanmzulvfz2kfxqhn6whqjckmpbr4fu/";

        isTeam[msg.sender] = true;
        isTeam[0x0C88ECF7FeEbBA1755282B87F5bDbF5A4b5eA08C] = true;

        goldTicket = SuperFuzzGoldTicket(GoldTicketAddress);
    }

    // Events
    event MonsterMinted(uint _id, address _address);
    // End Events

    // Modifiers

    modifier onlyTeam() {
        require(isTeam[msg.sender] == true, "Sneaky sneaky! You are not part of the team");
        _;
    }

    modifier checkRules(address _to, uint _amount) {
        require(_totalSupply() < MAX_MONSTERS, "We Sold All Out, See you on the next drop!");
        require(_totalSupply().add(_amount) <= MAX_MONSTERS, "Purchase would exceed max supply of Bad Batch");
        require(_amount <= getMaxPerTx(), "You cant have more than 2 in your wallet");
        _;
    }

    modifier verifyBuy(address _to, uint _amount) {
        if(getStatus() == Status.PresaleStart) {
            require(howManyMonsters[_to] >= 1 == false, "Sneaky sneaky! You need a Gold Ticket or be white-listed to mint right now.");
            require(goldTicket.balanceOf(_to) > 0 == true || isOnWhiteList[_to] == true, "Nice Try! You need a Gold Ticket or be Whitelisted");
            require(_amount <= getMaxPerTx(), "Busted! Cant mint more than one during the Early Access period.");
        }
        require(getStatus() == Status.PresaleStart || getStatus() == Status.PublicSaleStart, "Nice Try! Sale has not started yet!");
        require(MONSTER_PRICE.mul(_amount) <= msg.value, "Dang! You dont have enough ETH!");
        require(_totalSupply() < MAX_MONSTERS, "Error 777: Sold Out!");
        require(_totalSupply().add(_amount) <= MAX_MONSTERS, "Hold up! Purchase would exceed max supply. Try a lower amount.");
        require(howManyMonsters[_to] >= 2 == false, "Nice Try! You shall not have more than 2 in your wallet.");
        _;
    }

    // End Modifier

    // Setters

    function setProvenanceHash(string memory _provenanceHash) external onlyTeam {
        PROVENANCE = _provenanceHash;
    }

    function setBaseURI(string memory baseURI_) external onlyTeam {
        _baseURIextended = baseURI_;
    }

    function setMaxTx(uint _amount) external onlyTeam {
        maxPerTx = _amount;
    }

    function setManyWhiteList(address[] memory _addr) external onlyTeam {
        for(uint i = 0; i < _addr.length; i++){
            console.log("Address to add to whitelist", _addr[i]);
            isOnWhiteList[_addr[i]] = true;
        }
    }

    function increaseSupply() internal {
        _tokenIds.increment();
    }

    // End Setter

    // Getters
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function getMaxPerTx() public returns (uint) {
        if(block.timestamp >= publicSaleStartTime) {
            maxPerTx = 2;
        } else if (block.timestamp >= presaleStartTime) {
            maxPerTx = 1;
        }
       return maxPerTx;
    }

    function getStatus() public view returns (Status) {
        if(block.timestamp >= publicSaleStartTime) {
            return Status.PublicSaleStart;
        } else if (block.timestamp >= presaleStartTime) {
            return Status.PresaleStart;
        }
        return Status.Closed;
    }

    function _totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    function setPreSaleTime(uint _newTime) public onlyTeam {
        presaleStartTime = _newTime;
        publicSaleStartTime = _newTime + 9 hours;
    }

    // End Getter

    // Business Logic

    function giftManyMonsters(address[] memory _addr) external onlyTeam checkRules(msg.sender, _addr.length) {
        address _to = msg.sender;
        for (uint i = 0; i < _addr.length; i++) {
            uint id = _totalSupply() + 1;
            _safeMint(_addr[i], id);
            howManyMonsters[_to]++;
            increaseSupply();
            emit MonsterMinted(id, _to);
        }
    }

    function buyMonster(uint _amount) external payable verifyBuy(msg.sender, _amount) {
        address _to = msg.sender;
        for (uint i = 0; i < _amount; i++) {
            uint id = _totalSupply() + 1;
            _safeMint(_to, id);
            howManyMonsters[_to]++;
            increaseSupply();
            emit MonsterMinted(id, _to);
        }
    }

    // OVERRIDES

    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint tokenId)
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

    function withdrawAll() public onlyTeam {
        for (uint i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }
}
/**

 Generative Art: @Jim Dee
 Smart Contract Consultant: @realkelvinperez

 https://generativenfts.io/

**/
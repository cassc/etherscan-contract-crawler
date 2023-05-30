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
import "./SuperFuzzBadBatch.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SuperFuzzGoodGuys is Ownable, ERC721Enumerable, PaymentSplitter, ReentrancyGuard {

    using SafeMath for uint;
    using SafeMath for uint32;
    using SafeMath for uint64;

    address private GoldTicketAddress = 0x77f9a627A41b39c23469a7111f91C8487582c019;
    SuperFuzzGoldTicket goldTicket;

    address payable BadBatchAddress = payable(0x457E089448b41903A3778F592E7F4A0B87d2F2a8);
    SuperFuzzBadBatch badBatch;

    string public PROVENANCE;
    string private _baseURIextended;
    uint16 public maxTokens = 7777;
    uint16 public reservedTokens;
    uint16 public airdropReserved = 45;
    uint16 public goldticketsupply;
    uint public PRICE = 0.05 ether;
    uint public maxPerWallet = 5;
    bool public isSaleLive = false;
    uint public currentAirdropIndex;
    bool private PROVENANCE_LOCK = false;

    enum Status {
        Closed,
        GoldTicketPreSale,
        BadBatchPreSale,
        WhitelistOne,
        WhitelistTwo,
        PublicSale
    }

    struct Account {
        uint64 tokenBalance;
        bool hasGoldTicket;
        bool isOnWhitelistOne;
        bool isOnWhitelistTwo;
        bool isTeam;
    }

    mapping(address => Account) private accounts;
    mapping(uint => uint) private numPurchasedWithGoldTicket;
    mapping(address => uint) private NFTsToClaim;

    //Main Good Guys Release Time -
    //Date: Sunday, September 26th
    uint public goldTicketPreSale = 1632672000;          //Early Access Time for Gold Ticket holders: 9AM (PST)
    uint public badBatchPreSale = 1632682800;            //Early Access Time for Bad Batch holders: 12PM (PST)
    uint public whitelistOnePreSale = 1632693600;        //Early Access Time for Whitelist 1: 3PM (PST)
    uint public whitelistTwoPreSale = 1632700800;        //Early Access Time for Whitelist 2: 5PM (PST)
    uint public publicSale = 1632711600;                 //Public Launch: 8PM (PST);

    // Distribution addresses
    address private constant multiSig = 0x3Fa5377F202E0A38844Fba8035B98233dbFB1Daf;
    address private constant coreTeam = 0x1e56C11F86aE138184D684B4BF3A36969B999D3F;
    address private constant dev = 0xeE057D6dF60De8B1b20BeFe3fE69033D10BF4F6D;
    address private constant genArt = 0x8C2e99dBFDe08dAb6F4f681500D1CCfcF9101EF5;
    address private constant teamCtrl = 0x75A04eB37090eea7A20612B51fa76E35CBe3F8C9;

    address[] private _team = [multiSig, coreTeam, dev, genArt];
    uint[] private _team_shares = [45, 45, 5, 5];

    constructor()
        ERC721("Superfuzz: The Good Guys", "SFGG")
        PaymentSplitter(_team, _team_shares)
    {
        _baseURIextended = "ipfs://QmPD4F85Yd1VJWMkfxdx5e34a973pkYW5apuiX8wc8cnRc/";

        accounts[msg.sender].isTeam = true;
        accounts[teamCtrl].isTeam = true;

        goldTicket = SuperFuzzGoldTicket(GoldTicketAddress);
        badBatch = SuperFuzzBadBatch(BadBatchAddress);

        goldticketsupply = uint16(goldTicket._totalSupply());

        NFTsToClaim[genArt] = 35;
        NFTsToClaim[dev] = 10;
        reservedTokens = 45;
    }

    // Events
    event MonsterMinted(uint _id, address _address);
    // End Events

    // Modifiers
    modifier onlyTeam() {
        require(accounts[msg.sender].isTeam == true, "Sneaky sneaky! You are not part of the team");
        _;
    }

    modifier verifyAirDrop(address _to, uint _amount) {
        require(totalSupply() < (maxTokens), "We Sold All Out, See you on the next drop!");
        require(totalSupply().add(_amount) <= (maxTokens), "Purchase would exceed max supply of Bad Batch");
        _;
    }

    modifier verifyBuy(address _to, uint _amount) {
        require(isSaleLive, "Nice Try! Sale has not started yet!");
        require(_amount > 0, "Hold up! You need to purchase at least one!");
        require(PRICE.mul(_amount) <= msg.value, "Dang! You dont have enough ETH!");
        require(totalSupply() + (goldticketsupply - currentAirdropIndex) + reservedTokens + airdropReserved < maxTokens, "Error 7,777: Sold Out!");
        require(totalSupply().add(_amount) + (goldticketsupply - currentAirdropIndex) + reservedTokens + airdropReserved <= maxTokens, "Hold up! Purchase would exceed max supply. Try a lower amount.");
        require(accounts[_to].tokenBalance.add(_amount) <= maxPerWallet, "Nice Try! You shall not have more than 5 in your wallet.");
        _;
    }

    // End Modifier

    // Setters
    function toggleTeam(address _addr) external onlyOwner {
        accounts[_addr].isTeam = !accounts[_addr].isTeam;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyTeam {
        require(PROVENANCE_LOCK == false, "Provenance is locked!");
        PROVENANCE = _provenanceHash;
    }

    function lockProvenance() external onlyTeam {
       PROVENANCE_LOCK = true;
    }

    function setBaseURI(string memory _newURI) external onlyTeam {
        _baseURIextended = _newURI;
    }

    function setMaxPerWallet(uint _amount) external onlyTeam {
        maxPerWallet = _amount;
    }

    function setTotalSupply(uint _amount) external onlyTeam {
        maxTokens = uint16(_amount);
    }

    function setPrice(uint _newPrice) external onlyTeam {
        PRICE = _newPrice;
    }

    function toggleSale() external onlyTeam {
        isSaleLive = !isSaleLive;
    }

    function setWhiteListOne(address[] memory _addr) external onlyTeam {
        for(uint i = 0; i < _addr.length; i++) {
            accounts[_addr[i]].isOnWhitelistOne = true;
        }
    }

    function setWhiteListTwo(address[] memory _addr) external onlyTeam {
        for(uint i = 0; i < _addr.length; i++) {
            accounts[_addr[i]].isOnWhitelistTwo = true;
        }
    }

    function setSaleTime(uint[] memory _newTimes) external onlyTeam {
        goldTicketPreSale = _newTimes[0];
        badBatchPreSale = _newTimes[1];
        whitelistOnePreSale = _newTimes[2];
        whitelistTwoPreSale = _newTimes[3];
        publicSale = _newTimes[4];
    }

    // End Setter

    // Getters

    function getSaleTimes() public view returns (uint, uint, uint, uint, uint) {
        return (goldTicketPreSale, badBatchPreSale, whitelistOnePreSale, whitelistTwoPreSale, publicSale);
    }

    function saleState() public view returns (Status) {
        if(block.timestamp >= publicSale) {
            return Status.PublicSale;
        } else if(block.timestamp >= whitelistTwoPreSale) {
            return Status.WhitelistTwo;
        } else if(block.timestamp >= whitelistOnePreSale) {
            return Status.WhitelistOne;
        } else if(block.timestamp >= badBatchPreSale) {
            return Status.BadBatchPreSale;
        } else if(block.timestamp >= goldTicketPreSale) {
            return Status.GoldTicketPreSale;
        }
        return Status.Closed;
    }

    function remainingGoldTicketsToAirdrop() public view returns (uint) {
      uint remaining = uint(goldticketsupply).sub(currentAirdropIndex);
      return remaining;
    }

    // End Getter

    // Business Logic

    function airDropMany(address[] memory _addr) external onlyTeam verifyAirDrop(msg.sender, _addr.length) {
        require(_addr.length <= airdropReserved, "No more airdrops reserved!");
        airdropReserved -= uint16(_addr.length);
        address _to = msg.sender;
        for (uint i = 0; i < _addr.length; i++) {
            uint id = totalSupply() + 1;
            accounts[_to].tokenBalance++;
            _safeMint(_addr[i], id);
            emit MonsterMinted(id, _to);
        }
    }

    function mintGoodGuy(uint _amount) external payable nonReentrant verifyBuy(msg.sender, _amount) {

        address _to = msg.sender;

        Status currentState = saleState();

        if (currentState == Status.WhitelistTwo) {
            require(accounts[_to].isOnWhitelistTwo == true, "Nice Try! You need to be on Whitelist Two");

        } else if (currentState == Status.WhitelistOne) {
            require(accounts[_to].isOnWhitelistOne == true, "Nice Try! You need to be on Whitelist One");

        } else if (currentState == Status.BadBatchPreSale) {
            require(badBatch.balanceOf(_to) > 0, "Nice Try! You need to own a Bad Batch Monster");
            require(numPurchasedWithGoldTicket[badBatch.tokenOfOwnerByIndex(_to, 0).add(1000)].add(_amount) <= maxPerWallet, "Nice Try! Your Bad Batch Monster aint that bad!");
            // flag bad batch
            for(uint i = 0; i < badBatch.balanceOf(_to) && i < 5; i++) {
                numPurchasedWithGoldTicket[badBatch.tokenOfOwnerByIndex(_to, i).add(1000)] += _amount;
            }
        } else if (currentState == Status.GoldTicketPreSale) {
            require(goldTicket.balanceOf(_to) > 0, "Nice Try! You need to own a Gold Ticket");
            require(numPurchasedWithGoldTicket[goldTicket.tokenOfOwnerByIndex(_to, 0)].add(_amount) <= maxPerWallet, "Nice Try! Your Gold Ticket has already been used");
            //  flag gold ticket
            numPurchasedWithGoldTicket[goldTicket.tokenOfOwnerByIndex(_to, 0)] += _amount;
        } else if (currentState == Status.Closed) {
            require(false, "Sale has not started yet!");
        }

        for (uint i = 0; i < _amount; i++) {
            uint id = totalSupply() + 1;
            accounts[_to].tokenBalance++;
            _safeMint(_to, id);
            emit MonsterMinted(id, _to);
        }

    }

    function airDropToGoldTicketOwners(uint _toDrop) external onlyTeam {
        uint goldTicketSupply = goldticketsupply;
        uint currentIndex = currentAirdropIndex.add(1);
        require(currentIndex <= goldTicketSupply);
        for(uint i = currentIndex; i <= goldTicketSupply && i < (currentIndex + _toDrop); i++) {
            address _to = goldTicket.ownerOf(i);
            uint id = totalSupply() + 1;
            currentAirdropIndex++;
            accounts[_to].tokenBalance++;
            _safeMint(_to, id);
        }
    }

    function teamClaim(uint _amount) external onlyTeam {
        address _to = msg.sender;
        uint claimAmount = NFTsToClaim[_to];
        require(claimAmount > 0, "Nice try! You don't have any NFTs to Claim");
        for (uint i = 1; i <= claimAmount && i <= _amount; i++) {
            uint id = totalSupply() + 1;
            NFTsToClaim[_to]--;
            reservedTokens--;
            _safeMint(msg.sender, id);
        }
    }

    function burn(uint _id) external returns (bool, uint) {
        require(msg.sender == ownerOf(_id) || msg.sender == getApproved(_id) || isApprovedForAll(ownerOf(_id), msg.sender), "Sneaky sneaky! You don't own this Token.");
        _burn(_id);
        return (true, _id);
    }

    function withdrawAll() external onlyTeam {
        for (uint i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

}


/**

 Generative Art: @Jim Dee
 Smart Contract Consultant: @realkelvinperez
 Smart Contract Auditor: Patrick Price - [email protected]

 https://generativenfts.io/

**/
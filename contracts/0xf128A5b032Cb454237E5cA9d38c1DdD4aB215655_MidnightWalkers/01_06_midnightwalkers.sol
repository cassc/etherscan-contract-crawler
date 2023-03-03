//
// ███▄ ▄███▓ ██▓▓█████▄  ███▄    █  ██▓  ▄████  ██░ ██ ▄▄▄█████▓
//▓██▒▀█▀ ██▒▓██▒▒██▀ ██▌ ██ ▀█   █ ▓██▒ ██▒ ▀█▒▓██░ ██▒▓  ██▒ ▓▒
//▓██    ▓██░▒██▒░██   █▌▓██  ▀█ ██▒▒██▒▒██░▄▄▄░▒██▀▀██░▒ ▓██░ ▒░
//▒██    ▒██ ░██░░▓█▄   ▌▓██▒  ▐▌██▒░██░░▓█  ██▓░▓█ ░██ ░ ▓██▓ ░ 
//▒██▒   ░██▒░██░░▒████▓ ▒██░   ▓██░░██░░▒▓███▀▒░▓█▒░██▓  ▒██▒ ░ 
//░ ▒░   ░  ░░▓   ▒▒▓  ▒ ░ ▒░   ▒ ▒ ░▓   ░▒   ▒  ▒ ░░▒░▒  ▒ ░░   
//░  ░      ░ ▒ ░ ░ ▒  ▒ ░ ░░   ░ ▒░ ▒ ░  ░   ░  ▒ ░▒░ ░    ░    
//░      ░    ▒ ░ ░ ░  ░    ░   ░ ░  ▒ ░░ ░   ░  ░  ░░ ░  ░      
//       ░    ░     ░             ░  ░        ░  ░  ░  ░         
// █     █░ ▄▄▄   ░   ██▓     ██ ▄█▀▓█████  ██▀███    ██████     
//▓█░ █ ░█░▒████▄    ▓██▒     ██▄█▒ ▓█   ▀ ▓██ ▒ ██▒▒██    ▒     
//▒█░ █ ░█ ▒██  ▀█▄  ▒██░    ▓███▄░ ▒███   ▓██ ░▄█ ▒░ ▓██▄       
//░█░ █ ░█ ░██▄▄▄▄██ ▒██░    ▓██ █▄ ▒▓█  ▄ ▒██▀▀█▄    ▒   ██▒    
//░░██▒██▓  ▓█   ▓██▒░██████▒▒██▒ █▄░▒████▒░██▓ ▒██▒▒██████▒▒    
//░ ▓░▒ ▒   ▒▒   ▓▒█░░ ▒░▓  ░▒ ▒▒ ▓▒░░ ▒░ ░░ ▒▓ ░▒▓░▒ ▒▓▒ ▒ ░    
//  ▒ ░ ░    ▒   ▒▒ ░░ ░ ▒  ░░ ░▒ ▒░ ░ ░  ░  ░▒ ░ ▒░░ ░▒  ░ ░    
//  ░   ░    ░   ▒     ░ ░   ░ ░░ ░    ░     ░░   ░ ░  ░  ░      
//    ░          ░  ░    ░  ░░  ░      ░  ░   ░           ░  



//It is time to purge.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;



import {Ownable} from "Ownable.sol";
import {ERC721A} from "ERC721A.sol";
import {OperatorFilterer} from "OperatorFilterer.sol";



error PurgingNotLive();
error PurgeExceedsMaxSupply();
error FreePurgeLimitReached();
error PaidPurgeLimitReached();
error InsufficientPayment();


contract MidnightWalkers is ERC721A, OperatorFilterer, Ownable {
    // Variables

    bool public PurgingLive = false;
    uint256 public MAX_SUPPLY = 5555;
    uint256 public PAID_PURGE_PRICE = 0.002 ether;

    uint256 public FREE_PURGE_PRICE = 1;
    uint256 public PAID_PURGE_LIMIT = 10;

    string public baseURI;

    bool public operatorFilteringEnabled;



    // Constructor

    constructor(string memory baseURI_) ERC721A("Midnight Walkers", "MW") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        baseURI = baseURI_;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }



    // Modifiers

    modifier nonContract() {
        require(tx.origin == msg.sender, "Machine Guns Are Not Fair To Use");
        _;
    }

    // Mint

    function togglePurge() public onlyOwner {
        PurgingLive = !PurgingLive;
    }

    function purgeFree() external nonContract {
        if (!PurgingLive) revert PurgingNotLive();
        if (_totalMinted() >= MAX_SUPPLY) revert PurgeExceedsMaxSupply();
        if (_getAux(msg.sender) != 0) revert FreePurgeLimitReached();
        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
    }

    function purgePaid(uint256 qty) external payable nonContract {
        if (!PurgingLive) revert PurgingNotLive();
        if (_totalMinted() + qty > MAX_SUPPLY) revert PurgeExceedsMaxSupply();
        if (qty > PAID_PURGE_LIMIT) revert PaidPurgeLimitReached();
        if (msg.value < qty * PAID_PURGE_PRICE) revert InsufficientPayment();
        _mint(msg.sender, qty);
    }

  function collectReserves() external onlyOwner {
    require(totalSupply() == 0, "No More Puring.");
    _mint(msg.sender, 100);
  }

    function airdrop(address addr, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY);
        _safeMint(addr, amount);
    }

    // Token URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // Withdraw

  function withdraw() external onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Not Happening"
    );
  }
    }


//We purge to release the devils inside.  Without a purge humanity cannot exist and death will come upon us all.  At the strike of Midnight purging can begin.
//Which will you be?  Will you be the coward or will you be the purging alpha.  Pick your character wisely, there are future plans to match the purger you carry.
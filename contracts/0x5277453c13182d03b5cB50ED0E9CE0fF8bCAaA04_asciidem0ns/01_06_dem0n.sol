//summ0n and be prepared to burn for something very unique...
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;



import {Ownable} from "Ownable.sol";
import {ERC721A} from "ERC721A.sol";
import {OperatorFilterer} from "OperatorFilterer.sol";



error MintingNotLive();
error MintExceedsMaxSupply();
error FreeMintLimitReached();
error PaidMintLimitReached();
error FreeLimitReached();
error InsufficientPayment();

contract asciidem0ns is ERC721A, OperatorFilterer, Ownable {
    // Variables

    bool public MintingLive = false;
    uint256 public MAX_SUPPLY = 2222;
    uint256 public free_max_supply = 555;
    uint256 public MAX_PER_TX_FREE = 1;
    uint256 public PAID_Mint_PRICE = 0.0015 ether;


    uint256 public PAID_Mint_LIMIT = 40;

    string public baseURI;

    bool public operatorFilteringEnabled;



    // Constructor

    constructor(string memory baseURI_) ERC721A("ascii dem0ns", "dem") {
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
        require(tx.origin == msg.sender, "Sorry Contract Mintors");
        _;
    }

    // Mint

    function paused() public onlyOwner {
        MintingLive = !MintingLive;
    }




    function Summon(uint256 qty) external payable nonContract {
        if (!MintingLive) revert MintingNotLive();
        if (_totalMinted() + qty > MAX_SUPPLY) revert MintExceedsMaxSupply();
        if (qty > PAID_Mint_LIMIT) revert PaidMintLimitReached();

       // if (msg.value < qty * PAID_Mint_PRICE) revert InsufficientPayment();

     if(free_max_supply >= totalSupply()){
            require(MAX_PER_TX_FREE >= qty , "Excess max per free tx");
        }else{
            require(PAID_Mint_LIMIT >= qty , "Excess max per paid tx");
            require(qty * PAID_Mint_PRICE  == msg.value, "Invalid funds provided");
        }



        _mint(msg.sender, qty);
    }


  function collectdem0ns() external onlyOwner {
    _mint(msg.sender, 50);
  }

    function airdrop(address addr, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY);
        _safeMint(addr, amount);
    }

      function configPAID_Mint_PRICE(uint256 newPAID_Mint_PRICE) public onlyOwner {
        PAID_Mint_PRICE = newPAID_Mint_PRICE;
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
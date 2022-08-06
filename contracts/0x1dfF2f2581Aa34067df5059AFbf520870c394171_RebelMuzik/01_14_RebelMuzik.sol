// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract RebelMuzik is Ownable, ERC721A {
  using SafeMath for uint256;

  uint256 public collectionSize = 3305; 

  // === Max Mint Amounts per address ===
  uint256 public privateQty = 1;
  uint256 public VIPQty = 2;

// == Max Amount Per TX
  uint256 public publicAmountPerTx = 10;

  // === Reserved Mint Amounts ===
  uint256 public amountForPrivate = 100;
  uint256 public amountForVIPList = 800;

// === To Check Private and VIP total Supplies ===
  uint256 public totalPrivateMinted = 0;
  uint256 public totalVIPMinted = 0;

  // === Merkle List Configurations ===
  bytes32 public privateRoot;
  bytes32 public vipRoot;
  
  // === Price Configurations ===
  uint256 public vipPrice = 0.05 ether;
  uint256 public privatePrice = 0.05 ether;
  uint256 public publicPrice = 0.08 ether;

  // == WALLETS == //
  address private constant ADDR1 = 0x0C4d96B68F0c881f4F5226b555bce9c3Af56b609;
  address private constant ADDR2 = 0xAb15468c3CD3De12B4FE2e96aDAe9c1F3c3951Be;
  address private constant ADDR3 = 0xbee663FE84544Df22b445bd46772662e3Cce8816;
  address private constant ADDR4 = 0x3681D855bf1493cD008854b5958033C921c3Ee82;
  address private constant devWallet = 0x359763A3A49152455550A4f4F9e755481Dd3094c; // dev
  
  // == Sale State Configuration ===
  enum SaleState {
          OFF,
          PRIVATE,
          VIP,
          PUBLIC
      }

  SaleState public saleState = SaleState.OFF;

  string private baseURI;

  mapping(address => bool) private privateListMintTracker;
  mapping(address => uint256) private VIPListMintTracker;


  constructor(string memory initBaseUri, uint256 reserveAmount, uint256 teamReserveAmount) ERC721A("RebelMuzik", "ONETIMELOVE") {
    updateBaseUri(initBaseUri);
    ownerMint(ADDR2, 1);

    ownerMint(ADDR4, reserveAmount);
    ownerMint(devWallet, teamReserveAmount);
    ownerMint(ADDR1, teamReserveAmount);
    ownerMint(ADDR2, teamReserveAmount);
    ownerMint(ADDR3, teamReserveAmount);
    ownerMint(ADDR4, teamReserveAmount);
  }

    // *** Merkle Proofs ***
  // ===============================================================================

    function setPrivateRoot(bytes32 _privateRoot) public onlyOwner {
        privateRoot = _privateRoot;
    }

    function setVipRoot(bytes32 _vipRoot) public onlyOwner {
         vipRoot = _vipRoot;
    }

      function isPrivateValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, privateRoot, leaf);
    }

      function isVipValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, vipRoot, leaf);
    }

  // *** MINT FUNCTIONS ***
  // ===============================================================================
  /*
  * Private Sale Minting Function (Max 1)
  */
  function mintPrivateSale(bytes32[] calldata merkleProof) external payable
    {
      require(
        saleState == SaleState.PRIVATE, 
        "Private sale is not active"
        );
      require(
        isPrivateValid(merkleProof,
        keccak256(
            abi.encodePacked(
                msg.sender
                )
            )
        ),
        "Error - Verify Qualification"
    );
       require(
            privatePrice * privateQty <= msg.value,   
            "Insufficient funds sent"
        );
      require(
        privateListMintTracker[msg.sender] == false, 
        "Already Minted Max Amount."
        );
      require(
        totalPrivateMinted + privateQty <= amountForPrivate, 
        "Reached Private Sale Max Supply."
      );
      _safeMint(msg.sender, privateQty);
      privateListMintTracker[msg.sender] = true; 
      totalPrivateMinted = totalPrivateMinted + privateQty; 
  }

  // ===============================================================================
  /*
  * VIPList Minting Function (Max 2)
  */

  function mintVIPList(bytes32[] calldata merkleProof, uint256 quantity) external payable 
  {
      require(
        saleState == SaleState.VIP, 
        "VIP sale is not active"
      );
      require(
        isVipValid(merkleProof,
        keccak256(
            abi.encodePacked(
                msg.sender
                )
            )
        ),
        "Error - Verify Qualification"
    );
    require(
        vipPrice * quantity <= msg.value, 
        "Insufficient funds sent"
      );
    require(
      VIPListMintTracker[msg.sender] + quantity <= VIPQty, 
      "Too Many Minted."
      ); 
    secureVIPMint(quantity);
    VIPListMintTracker[msg.sender] = VIPListMintTracker[msg.sender] + quantity;  
    totalVIPMinted = totalVIPMinted + quantity;
  }
  // ===============================================================================
 /*
  * Public Sale Minting Function (Max 10 per tx)
  */
  function mintPublicSale(uint256 quantity) external payable 
    {
    require(
      saleState == SaleState.PUBLIC, 
      "Public sale is not active"
    );
    require(
        publicPrice * quantity <= msg.value, 
        "Insufficient funds sent"
    );
    require(
      quantity <= publicAmountPerTx,
      "Too many tokens for one transaction"
    );
    securePublicMint(quantity);
  }

    function securePublicMint(uint256 quantity) internal {
        require(
            quantity > 0, 
            "Quantity cannot be zero"
        );
        require(
            totalSupply().add(quantity) <= collectionSize, 
            "No items left to mint"
        );
        _safeMint(msg.sender, quantity);
    }
    
      function secureVIPMint(uint256 quantity) internal {
        require(
            quantity > 0, 
            "Quantity cannot be zero"
        );
        require(
          totalVIPMinted + quantity <= amountForVIPList, 
          "Reached VIP Sale Limit."
        );
        _safeMint(msg.sender, quantity);
    }

  // ===============================================================================



  function checkPrivateMinted(address owner) public view returns (bool) {
    return privateListMintTracker[owner];
  }

  function checkVIPMinted(address owner) public view returns (uint256) {
    return VIPListMintTracker[owner];
  }

  /*
  * Airdrop Mint Function
  */
    function _ownerMint(address to, uint256 numberOfTokens) private {
        require(
            totalSupply() + numberOfTokens <= collectionSize,
            "Not enough tokens left"
        );

            _safeMint(to, numberOfTokens);
        }

    function ownerMint(address to, uint256 numberOfTokens) public onlyOwner {
        _ownerMint(to, numberOfTokens);
    }

  // *** START/STOP SALES ***
  // ===============================================================================
    /**
    * Set Sale State
    * @param saleState_ 0: OFF, 1: PRIVATE, 2: VIP, 3: PUBLIC
    */
  function setSaleState(SaleState saleState_) external onlyOwner {
      saleState = saleState_;
  }

  // *** METADATA URI ***
  // ===============================================================================
  /**
  * Sets base URI
  * @dev Only use this method after sell out as it will leak unminted token data.
  */
    function updateBaseUri(string memory baseUri) public onlyOwner {
        baseURI = baseUri;
    }


  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  /** 
  * Change Private Mint Price
  * param _newPrivatePrice Amount in WEI
  */
  function setPrivatePrice(uint256 _newPrivatePrice) public onlyOwner {
        privatePrice = _newPrivatePrice;
  }

  /** 
  * Change VIP Mint Price
  * param _newVIPPrice Amount in WEI
  */
  function setVIPPrice(uint256 _newVIPPrice) public onlyOwner {
        vipPrice = _newVIPPrice;
  }

  /** 
  * Change Public Mint Price
  * param _newPublicPrice Amount in WEI
  */
  function setPublicPrice(uint256 _newPublicPrice) public onlyOwner {
        publicPrice = _newPublicPrice;
  }

  // == SET QUANTITIES == //

    function setPrivateQty(uint256 _newPrivateQty) public onlyOwner {
        privateQty = _newPrivateQty;
  }

    function setVIPQty(uint256 _newVIPQty) public onlyOwner {
        VIPQty = _newVIPQty;
  }

    function setPublicQty(uint256 _newPublicAmountPerTx) public onlyOwner {
        publicAmountPerTx = _newPublicAmountPerTx;
  }

  // == SET SUPPLIES == //

    function lowerSupply(uint256 _collectionSize) public onlyOwner {
    require(
        _collectionSize <= collectionSize, 
        "Can only reduce supply"
    );
        collectionSize = _collectionSize;
    }


    function setSupplyForPrivate(uint256 _amountForPrivate) public onlyOwner {
      amountForPrivate = _amountForPrivate;
    }

    function setSupplyForVIP(uint256 _amountForVIPList) public onlyOwner {
      amountForVIPList  = _amountForVIPList;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(ADDR1).transfer(balance * 42 / 100);
        payable(ADDR2).transfer(balance * 23 / 100);
        payable(ADDR3).transfer(balance * 18 / 100);
        payable(ADDR4).transfer(balance * 9 / 100);
        payable(devWallet).transfer(balance * 8 / 100);
  }
}
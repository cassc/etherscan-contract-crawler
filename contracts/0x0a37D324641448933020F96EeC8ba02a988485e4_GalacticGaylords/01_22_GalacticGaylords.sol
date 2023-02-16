// SPDX-License-Identifier: MIT

//           @@@@      @@@@    @@,    @@@@      @@@@   [email protected]@@@@@   @@@@@    @@@@@@        
//         @@@        @@  @@   @@    @@  @@    @@        [email protected]@      @@@    @@@           
//        @@@   @@@@  @@  @@   @@    @@  @@    @@         @@      @@@    @@@
//         @@@   @@   @@@@@@   @@    @@@@@@    @@         @@      @@@    @@@       
//          @@@@@@.   @@  @@   @@@@  @@  @@     @@@@      @@     @@@@@    @@@@@@       
                                                                                          
//  *@@@@@@@@@     @@@@@@  @@@&      [email protected]@@@@@  @@@@@@@@@@@@@@@@@@@@@\  @@@@@@@@@@   @@@@@@@@@@
//  @@@     @@@    @@/ @@   @@@@    @@@ #@@@             @@@      @@@ @@@     @@@ #@@@     @@
// @@@@     @@@   @@@  @@@    @@@  @@@  #@@@   @@@@@@    @@@      @@@ @@@     @@@ #@@@       
// @@@(          #@@    @@@    @@@@@.   #@@@  @@    @@   @@@@@@@@@@&  @@@     @@@  @@@@@@@@@@
// @@@(  @@@@@@@ @@@@@@@@@@     @@@*    #@@@  /@@@@@@(   @@@    (@@@  @@@    [email protected]@@          @@
// @@@@    &@@  @@@*     @@@    @@@     #@@@             @@@     @@@  @@@@@@@@@&  #@@      @@
//  @@@@@@@@@@ %@@@      @@@@   @@@%    #@@@@@@@@@@@  ,. @@@     @@@@@        %%@& @@@@@@@@@@




pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { OwnableRoles } from "./auth/OwnableRoles.sol";
import {IERC2981, ERC2981} from "./extensions/ERC2981.sol";
import "./opensea/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract GalacticGaylords is  ERC721, ReentrancyGuard, OwnableRoles, DefaultOperatorFilterer, ERC2981{
  using Counters for Counters.Counter;

  // =============================================================
  //                            STORAGE
  // =============================================================

  uint256 public PLANET_PRICE;
  uint256 public MAX_SUPPLY;
  uint256 public MAX_MULTIMINT;
  address public _fundingRecipient;
  address private _burnAuthorizedContract;
  bytes32 public rootHash;

  //@dev MINTER_ROLE extensibility for minter contracts.
  //@dev ADMIN_ROLE for performing admin actions.
  //@dev DEV_ROLE  for developer support.
  uint256 public constant MINTER_ROLE = _ROLE_2;
  uint256 public constant DEV_ROLE = _ROLE_1;
  uint256 public constant ADMIN_ROLE = _ROLE_0;

    /** Planet Sale Status**/
  bool private Planet1SaleOpen = false;
  bool private Planet2SaleOpen = false;
  bool private Planet3SaleOpen = false;
  bool private Planet4SaleOpen = false;
  bool private Planet5SaleOpen = false;
  bool private Planet6SaleOpen = false;
  bool private Planet7SaleOpen = false;
  bool private Planet8SaleOpen = false;
  bool private Planet9SaleOpen = false;
  bool private Planet10SaleOpen = false;

  /** Rainbow Sale Status **/
  bool private P1RainbowOpen = true;
  bool private P2RainbowOpen = false;
  bool private P3RainbowOpen = false;
  bool private P4RainbowOpen = false;
  bool private P5RainbowOpen = false;
  bool private P6RainbowOpen = false;
  bool private P7RainbowOpen = false;
  bool private P8RainbowOpen = false;
  bool private P9RainbowOpen = false;
  bool private P10RainbowOpen = false;


  string private customBaseURI;

      /** Planet Supply **/

  uint256 public MAX_REG_PLANET; // All other Planets
  uint256 public MAX_SPECIAL_PLANET; // Binary

      /** Planet Supply **/

  uint256 private PLANET1_SUPPLY; // Binary
  uint256 private PLANET2_SUPPLY; // Red
  uint256 private PLANET3_SUPPLY; // Orange
  uint256 private PLANET4_SUPPLY; // Yellow
  uint256 private PLANET5_SUPPLY; // Green
  uint256 private PLANET6_SUPPLY; // Blue
  uint256 private PLANET7_SUPPLY; // Indigo
  uint256 private PLANET8_SUPPLY; // Violet
  uint256 private PLANET9_SUPPLY; // White
  uint256 private PLANET10_SUPPLY; // Black
  uint256 private WHALE_SUPPLY; // Whale Pass
 
  // @Notice -This maps users mints per planet

  mapping(address => uint256) private Planet1CountMap; // Binary
  mapping(address => uint256) private Planet2CountMap; // Red
  mapping(address => uint256) private Planet3CountMap; // Orange
  mapping(address => uint256) private Planet4CountMap; // Yellow
  mapping(address => uint256) private Planet5CountMap; // Green
  mapping(address => uint256) private Planet6CountMap; // Blue
  mapping(address => uint256) private Planet7CountMap; // Indigo
  mapping(address => uint256) private Planet8CountMap; // Violet
  mapping(address => uint256) private Planet9CountMap; // White
  mapping(address => uint256) private Planet10CountMap; // Black


  constructor (
    string memory tokenName, //Galactic Gaylords
    string memory tokenSymbol, //GG
    string memory customBaseURI_, //ipfs://QmWjmNv2hFJTtmP7ukgCZ65nCzuf7N5HMcDtFbQauyszRN/
    address fundingrecipient, // 0x1a178ecF995eba436aD2bc89364413C4D0D43472
    uint256 planetPrice //0.1ETH - 100000000000000000
   ) ERC721(tokenName, tokenSymbol) { // GalacticGaylords, $GG
    _initializeOwner(0x1a178ecF995eba436aD2bc89364413C4D0D43472);
    customBaseURI = customBaseURI_; 
    PLANET_PRICE = planetPrice;
    MAX_MULTIMINT = 10;
    _fundingRecipient = fundingrecipient;
    MAX_SPECIAL_PLANET = 1;
    MAX_REG_PLANET = 10;
    _grantRoles(0x8AB5496a45c92c36eC293d2681F1d3706eaff85D,1);
    _setDefaultRoyalty(0x1a178ecF995eba436aD2bc89364413C4D0D43472, 1000);

    /**  Defining Planet Quantities **/
    PLANET1_SUPPLY = 101; //Binary
    PLANET2_SUPPLY = 1100; //Red
    PLANET3_SUPPLY = 1100; //Orange
    PLANET4_SUPPLY = 1100; //Yellow
    PLANET5_SUPPLY = 1100; //Green
    PLANET6_SUPPLY = 1100; //Blue
    PLANET7_SUPPLY = 1100; //Indigo
    PLANET8_SUPPLY = 1100; //Violet
    PLANET9_SUPPLY = 1100; // White
    PLANET10_SUPPLY = 1100; // White
    WHALE_SUPPLY = 10; // Whale pass

    MAX_SUPPLY = PLANET1_SUPPLY + PLANET2_SUPPLY + PLANET3_SUPPLY + PLANET4_SUPPLY + PLANET5_SUPPLY + PLANET6_SUPPLY + PLANET7_SUPPLY + PLANET8_SUPPLY + PLANET9_SUPPLY + PLANET10_SUPPLY + WHALE_SUPPLY;
  }

    // ============================================================= //
    //                           Sale Control                        //
    // ============================================================= //
    
  // Returns on all public sale status in 1 array.
  function allPlanetSaleStatus() public view returns (bool[10] memory) {
    return [Planet1SaleOpen, Planet2SaleOpen, Planet3SaleOpen, Planet4SaleOpen, Planet5SaleOpen, Planet6SaleOpen, Planet7SaleOpen, Planet8SaleOpen, Planet9SaleOpen, Planet10SaleOpen];
  }

  // Returns on all rainbow list sale status in 1 array.
  function allRainbowStatus() public view returns (bool[10] memory) {
    return [P1RainbowOpen, P2RainbowOpen, P3RainbowOpen, P4RainbowOpen, P5RainbowOpen, P6RainbowOpen, P7RainbowOpen, P8RainbowOpen, P9RainbowOpen, P10RainbowOpen];
  }

  // Set max amount of mints for all planets except binary
  function setMaxRegMint(uint256 newMaxReg) external onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE) {
    MAX_REG_PLANET = newMaxReg;
  }

  // Set max amount of mints for binary
  function setMaxSpecial(uint256 newMaxSpecial) external onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE) {
    MAX_SPECIAL_PLANET = newMaxSpecial;
  }

    // Set max amount of mints for binary
  function setMaxSupply(uint256 newMax) external onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE) {
    MAX_SUPPLY = newMax;
  }

  // Set max amount of mints per transaction
  function setPlanetPrice(uint256 newPrice) external onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE) {
     PLANET_PRICE = newPrice;
  }

  // Toggle Sale Status
  function togglePlanetSaleStatus(uint256 planetNumber) public onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE) {
    if (planetNumber == 1) {
        Planet1SaleOpen = !Planet1SaleOpen;
    } else if (planetNumber == 2) {
        Planet2SaleOpen = !Planet2SaleOpen;
    } else if (planetNumber == 3) {
        Planet3SaleOpen = !Planet3SaleOpen;
    } else if (planetNumber == 4) {
        Planet4SaleOpen = !Planet4SaleOpen;
    } else if (planetNumber == 5) {
        Planet5SaleOpen = !Planet5SaleOpen;
    } else if (planetNumber == 6) {
        Planet6SaleOpen = !Planet6SaleOpen;
    } else if (planetNumber == 7) {
        Planet7SaleOpen = !Planet7SaleOpen;
    } else if (planetNumber == 8) {
        Planet8SaleOpen = !Planet8SaleOpen;
    } else if (planetNumber == 9) {
        Planet9SaleOpen = !Planet9SaleOpen;
    } else if (planetNumber == 10) {
        Planet10SaleOpen = !Planet10SaleOpen;
    }
}
  // Toggle Rainbow list status
  function toggleRainbowListStatus(uint256 planetNumber) public onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE){
    if (planetNumber == 1) {
        P1RainbowOpen = !P1RainbowOpen;
    } else if (planetNumber == 2) {
        P2RainbowOpen = !P2RainbowOpen;
    } else if (planetNumber == 3) {
        P3RainbowOpen = !P3RainbowOpen;
    } else if (planetNumber == 4) {
        P4RainbowOpen = !P4RainbowOpen;
    } else if (planetNumber == 5) {
        P5RainbowOpen = !P5RainbowOpen;
    } else if (planetNumber == 6) {
        P6RainbowOpen = !P6RainbowOpen;
    } else if (planetNumber == 7) {
        P7RainbowOpen = !P7RainbowOpen;
    } else if (planetNumber == 8) {
        P8RainbowOpen = !P8RainbowOpen;
    } else if (planetNumber == 9) {
        P9RainbowOpen = !P9RainbowOpen;
    } else if (planetNumber == 10) {
        P10RainbowOpen = !P10RainbowOpen;
    }
}

  //====================================================================//
  //                       Control Panel  - Getters                     //
  //====================================================================//

  //Return Base URI
  function baseTokenURI() public view returns (string memory) {
    return customBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function _verifyProof(address _addr, bytes32[] calldata _proof)
    internal
    view
    returns (bool _isValid)
  {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_addr))));
    _isValid = MerkleProof.verify(_proof, rootHash, leaf);
  }

  //====================================================================//
  //                       Control Panel  - Setters                     //
  //====================================================================//

    // Change Splits contract for mint proceeds
  function setFundingRecipient(address fundingRecipient) external onlyRolesOrOwner(ADMIN_ROLE) {
    _fundingRecipient = fundingRecipient;
  }

  function setBaseURI(string memory customBaseURI_) external onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE) {
    customBaseURI = customBaseURI_;
  }

  //Set new Merkleroot
    function setRootHash(bytes32 _rootHash) public onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE) {
    rootHash = _rootHash;
  }

   // Set max amount of mints per transaction
  function setMaxMultiMint(uint256 maxMultiMint) external onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE) {
    MAX_MULTIMINT = maxMultiMint;
  }

   // Set max amount of mints per transaction
  function setWhaleSupply(uint256 newSupply) external onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE) {
    WHALE_SUPPLY = newSupply;
  }

  // ============================================================= //
  //                    Admin Mint Functions                       //
  // ============================================================= //


  function adminMint(uint256 planetNumber, address recipient, uint256 count) public onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE | MINTER_ROLE)  {
    if (planetNumber == 1) {
          P1Mint(recipient,count);
    } else if (planetNumber == 2) {
          P2Mint(recipient,count);
    } else if (planetNumber == 3) {
          P3Mint(recipient,count);
    } else if (planetNumber == 4) {
          P4Mint(recipient,count);
    } else if (planetNumber == 5) {
          P5Mint(recipient,count);
    } else if (planetNumber == 6) {
          P6Mint(recipient,count);
    } else if (planetNumber == 7) {
          P7Mint(recipient,count);
    } else if (planetNumber == 8) {
          P8Mint(recipient,count);
    }else if (planetNumber == 9) {
          P9Mint(recipient,count);
    }  else if (planetNumber == 10) {
          P10Mint(recipient,count);
    } 
  }

  function issueWhalePass(address recipient) public onlyRolesOrOwner(ADMIN_ROLE | DEV_ROLE | MINTER_ROLE){
    require(totalWhaleSupply() + 1 < WHALE_SUPPLY, "Exceeds max supply");
      whaleSupplyCounter.increment();
      _safeMint(recipient, totalWhaleSupply() + PLANET1_SUPPLY + PLANET2_SUPPLY + PLANET3_SUPPLY + PLANET4_SUPPLY + PLANET5_SUPPLY + PLANET6_SUPPLY + PLANET7_SUPPLY + PLANET8_SUPPLY + PLANET9_SUPPLY  + PLANET10_SUPPLY);
  }

  // ============================================================= //
  //                    Planet Mint Functions                      //
  // ============================================================= //

   function RainbowListMint(uint256 planetNumber, address recipient, uint256 count, bytes32[] calldata _proof) public payable nonReentrant  {
            if (!_verifyProof(recipient, _proof)) { 
      revert InvalidProof();
    }
    require(msg.value >= PLANET_PRICE * count, "Insufficient payment");
     if (planetNumber == 1) {
        require(P1RainbowOpen, "Sale not active"); //Public sale  
          P1checks(recipient,count);
    } else if (planetNumber == 2) {
        require(P2RainbowOpen, "Sale not active"); //Public sale  
           P2checks(recipient,count);
    } else if (planetNumber == 3) {
        require(P3RainbowOpen, "Sale not active"); //Public sale  
           P3checks(recipient,count);
    } else if (planetNumber == 4) {
        require(P4RainbowOpen, "Sale not active"); //Public sale  
           P4checks(recipient,count);
    } else if (planetNumber == 5) {
        require(P5RainbowOpen, "Sale not active"); //Public sale  
           P5checks(recipient,count);
    } else if (planetNumber == 6) {
        require(P6RainbowOpen, "Sale not active"); //Public sale  
           P6checks(recipient,count);
    } else if (planetNumber == 7) {
        require(P7RainbowOpen, "Sale not active"); //Public sale  
           P7checks(recipient,count);
    } else if (planetNumber == 8) {
        require(P8RainbowOpen, "Sale not active"); //Public sale  
           P8checks(recipient,count);
    }else if (planetNumber == 9) {
        require(P9RainbowOpen, "Sale not active"); //Public sale  
           P9checks(recipient,count);
    }  else if (planetNumber == 10) {
        require(P10RainbowOpen, "Sale not active"); //Public sale  
           P10checks(recipient,count);
    } 
         payable(_fundingRecipient).transfer(msg.value);
}

  function PublicMint(uint256 planetNumber, address recipient, uint256 count) public payable nonReentrant {
      require(msg.value >= PLANET_PRICE * count, "Insufficient payment");
      
      if (planetNumber == 1) {
        require(Planet1SaleOpen, "Sale not active"); //Public sale  
          P1checks(recipient,count);
    } else if (planetNumber == 2) {
        require(Planet2SaleOpen, "Sale not active"); //Public sale  
           P2checks(recipient,count);
    } else if (planetNumber == 3) {
        require(Planet3SaleOpen, "Sale not active"); //Public sale  
           P3checks(recipient,count);
    } else if (planetNumber == 4) {
        require(Planet4SaleOpen, "Sale not active"); //Public sale  
           P4checks(recipient,count);
    } else if (planetNumber == 5) {
        require(Planet5SaleOpen, "Sale not active"); //Public sale  
           P5checks(recipient,count);
    } else if (planetNumber == 6) {
        require(Planet6SaleOpen, "Sale not active"); //Public sale  
           P6checks(recipient,count);
    } else if (planetNumber == 7) {
        require(Planet7SaleOpen, "Sale not active"); //Public sale  
           P7checks(recipient,count);
    } else if (planetNumber == 8) {
        require(Planet8SaleOpen, "Sale not active"); //Public sale  
           P8checks(recipient,count);
    }else if (planetNumber == 9) {
        require(Planet9SaleOpen, "Sale not active"); //Public sale  
           P9checks(recipient,count);
    }  else if (planetNumber == 10) {
        require(Planet10SaleOpen, "Sale not active"); //Public sale  
           P10checks(recipient,count);
    }
     payable(_fundingRecipient).transfer(msg.value);
}

  // ============================================================= //
  //                    Internal Mint Checks                       //
  // ============================================================= //

// PLANET 1 CHECKS
  function P1checks(address recipient, uint256 count) internal {
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");

    if (allowedPlanet1MintCount(recipient) > 0) {
      updatePlanet1MintCount(recipient, count);
    } else {
      revert("Minting limit exceeded");
    }
    P1Mint(recipient,count);
}

// PLANET 2 CHECKS
  function P2checks(address recipient, uint256 count) internal {
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");

    if (allowedPlanet2MintCount(recipient) > 0) {
      updatePlanet2MintCount(recipient, count);
    } else {
      revert("Minting limit exceeded");
    }
    P2Mint(recipient,count);
}

// PLANET 3 CHECKS
  function P3checks(address recipient, uint256 count) internal {
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");

    if (allowedPlanet3MintCount(recipient) > 0) {
      updatePlanet3MintCount(recipient, count);
    } else {
      revert("Minting limit exceeded");
    }
    P3Mint(recipient,count);
}

// PLANET 4 CHECKS
  function P4checks(address recipient, uint256 count) internal {
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");

    if (allowedPlanet4MintCount(recipient) > 0) {
      updatePlanet4MintCount(recipient, count);
    } else {
      revert("Minting limit exceeded");
    }
    P4Mint(recipient,count);
}

// PLANET 5 CHECKS
  function P5checks(address recipient, uint256 count) internal {
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");

    if (allowedPlanet5MintCount(recipient) > 0) {
      updatePlanet5MintCount(recipient, count);
    } else {
      revert("Minting limit exceeded");
    }
    P5Mint(recipient,count);
}

// PLANET 6 CHECKS
  function P6checks(address recipient, uint256 count) internal {
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");

    if (allowedPlanet6MintCount(recipient) > 0) {
      updatePlanet6MintCount(recipient, count);
    } else {
      revert("Minting limit exceeded");
    }
    P6Mint(recipient,count);
}

// PLANET 7 CHECKS
  function P7checks(address recipient, uint256 count) internal {
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");

    if (allowedPlanet7MintCount(recipient) > 0) {
      updatePlanet7MintCount(recipient, count);
    } else {
      revert("Minting limit exceeded");
    }
    P7Mint(recipient,count);
}

// PLANET 8 CHECKS
  function P8checks(address recipient, uint256 count) internal {
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");

    if (allowedPlanet8MintCount(recipient) > 0) {
      updatePlanet8MintCount(recipient, count);
    } else {
      revert("Minting limit exceeded");
    }
    P8Mint(recipient,count);
}

// PLANET 9 CHECKS
  function P9checks(address recipient, uint256 count) internal {
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");

    if (allowedPlanet9MintCount(recipient) > 0) {
      updatePlanet9MintCount(recipient, count);
    } else {
      revert("Minting limit exceeded");
    }
    P9Mint(recipient,count);
}

// PLANET 10 CHECKS
  function P10checks(address recipient, uint256 count) internal {
    require(count - 1 < MAX_MULTIMINT, "Trying to mint too many at a time");

    if (allowedPlanet10MintCount(recipient) > 0) {
      updatePlanet10MintCount(recipient, count);
    } else {
      revert("Minting limit exceeded");
    }
    P10Mint(recipient,count);
}
  // ============================================================= //
  //                    Internal Mint Functions                    //
  // ============================================================= //

    //Checks required for any and all mints. Even admin mints, could abstract supply to the admin call.. 
   function P1Mint(address recipient, uint256 count) internal{
      require(totalPlanet1Supply() + count - 1 < PLANET1_SUPPLY, "Exceeds max supply");
      for (uint256 i = 0; i < count; i++) {
      planet1SupplyCounter.increment();
      _safeMint(recipient, totalPlanet1Supply());
      }
    }

    function P2Mint(address recipient, uint256 count) internal{
      require(totalPlanet2Supply() + count - 1 < PLANET2_SUPPLY, "Exceeds max supply");
      for (uint256 i = 0; i < count; i++) {
      planet2SupplyCounter.increment();
      _safeMint(recipient, totalPlanet2Supply() + PLANET1_SUPPLY);
      }
    }

    function P3Mint(address recipient, uint256 count) internal{
     require(totalPlanet3Supply() + count - 1 < PLANET3_SUPPLY, "Exceeds max supply");
      for (uint256 i = 0; i < count; i++) {
      planet3SupplyCounter.increment();
      _safeMint(recipient, totalPlanet3Supply() + PLANET1_SUPPLY + PLANET2_SUPPLY );
      } 
    }

    function P4Mint(address recipient, uint256 count) internal{
      require(totalPlanet4Supply() + count - 1 < PLANET4_SUPPLY, "Exceeds max supply");
      for (uint256 i = 0; i < count; i++) {
      planet4SupplyCounter.increment();
      _safeMint(recipient, totalPlanet4Supply() + PLANET1_SUPPLY + PLANET2_SUPPLY + PLANET3_SUPPLY );
      } 
  }

    function P5Mint(address recipient, uint256 count) internal{
      require(totalPlanet5Supply() + count - 1 < PLANET5_SUPPLY, "Exceeds max supply");
      for (uint256 i = 0; i < count; i++) {
      planet5SupplyCounter.increment();
      _safeMint(recipient, totalPlanet5Supply() + PLANET1_SUPPLY + PLANET2_SUPPLY + PLANET3_SUPPLY + PLANET4_SUPPLY);      }
  }
 
    function P6Mint(address recipient, uint256 count) internal{
      require(totalPlanet6Supply() + count - 1 < PLANET6_SUPPLY, "Exceeds max supply");
      for (uint256 i = 0; i < count; i++) {
      planet6SupplyCounter.increment();
      _safeMint(recipient, totalPlanet6Supply() + PLANET1_SUPPLY + PLANET2_SUPPLY + PLANET3_SUPPLY + PLANET4_SUPPLY + PLANET5_SUPPLY);
      }
  }

    function P7Mint(address recipient, uint256 count) internal{
      require(totalPlanet7Supply() + count - 1 < PLANET7_SUPPLY, "Exceeds max supply");
      for (uint256 i = 0; i < count; i++) {
      planet7SupplyCounter.increment();
      _safeMint(recipient, totalPlanet7Supply() + PLANET1_SUPPLY + PLANET2_SUPPLY + PLANET3_SUPPLY + PLANET4_SUPPLY + PLANET5_SUPPLY + PLANET6_SUPPLY);
      }
  }

    function P8Mint(address recipient, uint256 count) internal{
      require(totalPlanet8Supply() + count - 1 < PLANET8_SUPPLY, "Exceeds max supply");
      for (uint256 i = 0; i < count; i++) {
      planet8SupplyCounter.increment();
      _safeMint(recipient, totalPlanet8Supply() + PLANET1_SUPPLY + PLANET2_SUPPLY + PLANET3_SUPPLY + PLANET4_SUPPLY + PLANET5_SUPPLY + PLANET6_SUPPLY + PLANET7_SUPPLY);
      }
  }

    function P9Mint(address recipient, uint256 count) internal{
      require(totalPlanet9Supply() + count - 1 < PLANET9_SUPPLY, "Exceeds max supply");
      for (uint256 i = 0; i < count; i++) {
      planet9SupplyCounter.increment();
      _safeMint(recipient, totalPlanet9Supply() + PLANET1_SUPPLY + PLANET2_SUPPLY + PLANET3_SUPPLY + PLANET4_SUPPLY + PLANET5_SUPPLY + PLANET6_SUPPLY + PLANET7_SUPPLY + PLANET8_SUPPLY);
      }
  }


    function P10Mint(address recipient, uint256 count) internal{
      require(totalPlanet10Supply() + count - 1 < PLANET10_SUPPLY, "Exceeds max supply");
      for (uint256 i = 0; i < count; i++) {
      planet10SupplyCounter.increment();
      _safeMint(recipient, totalPlanet10Supply() + PLANET1_SUPPLY + PLANET2_SUPPLY + PLANET3_SUPPLY + PLANET4_SUPPLY + PLANET5_SUPPLY + PLANET6_SUPPLY + PLANET7_SUPPLY + PLANET8_SUPPLY + PLANET9_SUPPLY);
      }
  }

  // ============================================================= //
  //                    Planet Mint Limitations                    //
  // ============================================================= //

//** Getters & setter for EACH planet **//
//Planet 1
//getter
    function allowedPlanet1MintCount(address minter) internal view returns (uint256) {
    return MAX_SPECIAL_PLANET - Planet1CountMap[minter];
  }

//setter
  function updatePlanet1MintCount(address minter, uint256 count) private {
    Planet1CountMap[minter] += count;
  }

// PLANET 2
//getter
      function allowedPlanet2MintCount(address minter) internal view returns (uint256) {
    return MAX_REG_PLANET - Planet2CountMap[minter];
  }

//setter
  function updatePlanet2MintCount(address minter, uint256 count) private {
    Planet2CountMap[minter] += count;
  }

// PLANET 3
//getter
      function allowedPlanet3MintCount(address minter) internal view returns (uint256) {
    return MAX_REG_PLANET - Planet3CountMap[minter];
  }

//setter
  function updatePlanet3MintCount(address minter, uint256 count) private {
    Planet3CountMap[minter] += count;
  }

// PLANET 4
//getter
      function allowedPlanet4MintCount(address minter) internal view returns (uint256) {
    return MAX_REG_PLANET - Planet4CountMap[minter];
  }

//setter
  function updatePlanet4MintCount(address minter, uint256 count) private {
    Planet4CountMap[minter] += count;
  }

// PLANET 5
//getter
      function allowedPlanet5MintCount(address minter) internal view returns (uint256) {
    return MAX_REG_PLANET - Planet5CountMap[minter];
  }

//setter
  function updatePlanet5MintCount(address minter, uint256 count) private {
    Planet5CountMap[minter] += count;
  }

// PLANET 6
//getter
      function allowedPlanet6MintCount(address minter) internal view returns (uint256) {
    return MAX_REG_PLANET - Planet6CountMap[minter];
  }

//setter
  function updatePlanet6MintCount(address minter, uint256 count) private {
    Planet6CountMap[minter] += count;
  }

// PLANET 7
//getter
      function allowedPlanet7MintCount(address minter) internal view returns (uint256) {
    return MAX_REG_PLANET - Planet7CountMap[minter];
  }

//setter
  function updatePlanet7MintCount(address minter, uint256 count) private {
    Planet7CountMap[minter] += count;
  }

// PLANET 8
//getter
      function allowedPlanet8MintCount(address minter) internal view returns (uint256) {
    return MAX_REG_PLANET - Planet8CountMap[minter];
  }

//setter
  function updatePlanet8MintCount(address minter, uint256 count) private {
    Planet8CountMap[minter] += count;
  }

// PLANET 9

//getter
  function allowedPlanet9MintCount(address minter) internal view returns (uint256) {
    return MAX_REG_PLANET - Planet9CountMap[minter];
  }

//setter
  function updatePlanet9MintCount(address minter, uint256 count) private {
    Planet9CountMap[minter] += count;
  }

// PLANET 10

//getter
  function allowedPlanet10MintCount(address minter) internal view returns (uint256) {
    return MAX_REG_PLANET - Planet10CountMap[minter];
  }

//setter
  function updatePlanet10MintCount(address minter, uint256 count) private {
    Planet10CountMap[minter] += count;
  }

  function currentMintsAllowed(uint256 planetNumber, address minter) public view returns (uint256 supply) {
    if (planetNumber == 1) {
        return MAX_SPECIAL_PLANET - Planet1CountMap[minter];
    } else if (planetNumber == 2) {
        return MAX_REG_PLANET - Planet2CountMap[minter];
    } else if (planetNumber == 3) {
        return MAX_REG_PLANET - Planet3CountMap[minter];
    } else if (planetNumber == 4) {
        return MAX_REG_PLANET - Planet4CountMap[minter];
    } else if (planetNumber == 5) {
        return MAX_REG_PLANET - Planet5CountMap[minter];
    } else if (planetNumber == 6) {
       return MAX_REG_PLANET - Planet6CountMap[minter];
    } else if (planetNumber == 7) {
       return MAX_REG_PLANET - Planet7CountMap[minter];
    } else if (planetNumber == 8) {
        return MAX_REG_PLANET - Planet8CountMap[minter];
    } else if (planetNumber == 9) {
        return MAX_REG_PLANET - Planet9CountMap[minter];
    } else if (planetNumber == 10) {
       return MAX_REG_PLANET - Planet10CountMap[minter];
  }

}

  // ============================================================= //
  //                       Migration Supports                      //
  // ============================================================= //

    // Only the owner of the token, its approved operators, and 
    // the authorized contract can call this function.
  function burn(uint256 tokenId) public virtual {
    // Avoid unnecessary approvals for the authorized contract
    require(
    msg.sender == _burnAuthorizedContract || _isApprovedOrOwner(msg.sender, tokenId),
    "ERC721: caller is not token owner nor approved");
    _burn(tokenId);
    }

  function setBurnAuthorizedContract(address authorizedContract) external onlyRolesOrOwner (ADMIN_ROLE | DEV_ROLE) {
    _burnAuthorizedContract = authorizedContract;
    }
  // ============================================================= //
  //                    Planet Counters Support                    //
  // ============================================================= //

  Counters.Counter private planet1SupplyCounter;
  Counters.Counter private planet2SupplyCounter;
  Counters.Counter private planet3SupplyCounter;
  Counters.Counter private planet4SupplyCounter;
  Counters.Counter private planet5SupplyCounter;
  Counters.Counter private planet6SupplyCounter;
  Counters.Counter private planet7SupplyCounter;
  Counters.Counter private planet8SupplyCounter;
  Counters.Counter private planet9SupplyCounter;
  Counters.Counter private planet10SupplyCounter;
  Counters.Counter private whaleSupplyCounter;

    // ============================================================= //
    //                    Planet Supply Support                      //
    // ============================================================= //


  function totalPlanet1Supply() internal view returns (uint256) {
    return planet1SupplyCounter.current();
  }

  function totalPlanet2Supply() internal view returns (uint256) {
    return planet2SupplyCounter.current();
  }

  function totalPlanet3Supply() internal view returns (uint256) {
    return planet3SupplyCounter.current();
  }
  
  function totalPlanet4Supply() internal view returns (uint256) {
    return planet4SupplyCounter.current();
  }

  
  function totalPlanet5Supply() internal view returns (uint256) {
    return planet5SupplyCounter.current();
  }
    
  function totalPlanet6Supply() internal view returns (uint256) {
    return planet6SupplyCounter.current();
  }

  function totalPlanet7Supply() internal view returns (uint256) {
    return planet7SupplyCounter.current();
  }

  function totalPlanet8Supply() internal view returns (uint256) {
    return planet8SupplyCounter.current();
  }

  function totalPlanet9Supply() internal view returns (uint256) {
    return planet9SupplyCounter.current();
  }

  function totalPlanet10Supply() internal view returns (uint256) {
    return planet10SupplyCounter.current();
  }

  function totalWhaleSupply() internal view returns (uint256) {
    return whaleSupplyCounter.current();
  }

  function currentPlanetSupply(uint256 planetNumber) public view returns (uint256 supply) {
    if (planetNumber == 1) {
        return planet1SupplyCounter.current();
    } else if (planetNumber == 2) {
        return planet2SupplyCounter.current();
    } else if (planetNumber == 3) {
        return planet3SupplyCounter.current();
    } else if (planetNumber == 4) {
        return planet4SupplyCounter.current();
    } else if (planetNumber == 5) {
        return planet5SupplyCounter.current();
    } else if (planetNumber == 6) {
        return planet6SupplyCounter.current();
    } else if (planetNumber == 7) {
       return planet7SupplyCounter.current();
    } else if (planetNumber == 8) {
        return planet8SupplyCounter.current();
    } else if (planetNumber == 9) {
        return planet9SupplyCounter.current();
    } else if (planetNumber == 10) {
        return planet10SupplyCounter.current();
    } else if (planetNumber == 11) {
        return whaleSupplyCounter.current();
    }
  }
    // ============================================================= //
    //                       Supports Interface                      //
    // ============================================================= //

  function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC721, ERC2981)
    returns (bool) {
    return super.supportsInterface(interfaceId);
}


  //Merkleroot error
    error InvalidProof();

    // ============================================================= //
    //                        Opensea   Registry                     //
    // ============================================================= //

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
    }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
    }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
    }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
    }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
      super.safeTransferFrom(from, to, tokenId, data);
    }
}
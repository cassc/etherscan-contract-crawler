//      .'(   )\.---.          /`-.      /`-.   )\.---.          /`-.    .')       .')                  
//  ,') \  ) (   ,-._(       ,' _  \   ,' _  \ (   ,-._(       ,' _  \  ( /       ( /                   
// (  /(/ /   \  '-,        (  '-' (  (  '-' (  \  '-,        (  '-' (   ))        ))                   
//  )    (     ) ,-`         )   _  )  ) ,_ .'   ) ,-`         )   _  )  )'._.-.   )'._.-.              
// (  .'\ \   (  ``-.       (  ,' ) \ (  ' ) \  (  ``-.       (  ,' ) \ (       ) (       )             
//  )/   )/    )..-.(        )/    )/  )/   )/   )..-.(        )/    )/  )/,__.'   )/,__.'              
//    )\.-.      .-./(  .'(   )\  )\     )\.-.        .-,.-.,-.    .-./(          )\.-.  .'(   )\.---.  
//  ,' ,-,_)   ,'     ) \  ) (  \, /   ,' ,-,_)       ) ,, ,. (  ,'     )       ,'     ) \  ) (   ,-._( 
// (  .   __  (  .-, (  ) (   ) \ (   (  .   __       \( |(  )/ (  .-, (       (  .-, (  ) (   \  '-,   
//  ) '._\ _)  ) '._\ ) \  ) ( ( \ \   ) '._\ _)         ) \     ) '._\ )       ) '._\ ) \  )   ) ,-`   
// (  ,   (   (  ,   (   ) \  `.)/  ) (  ,   (           \ (    (  ,   (       (  ,   (   ) \  (  ``-.  
//  )/'._.'    )/ ._.'    )/     '.(   )/'._.'            )/     )/ ._.'        )/ ._.'    )/   )..-.(  
//                                                                                                     
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract WAGDIE is ERC721A, Ownable {
  // "Private" Variables
  address private constant SOUL1 = 0x8d2Eb1c6Ab5D87C5091f09fFE4a5ed31B1D9CF71;
  address private constant SOUL2 = 0xBf26FB48e19aFE3DD99882C84016b8d16Aae0636;
  string private baseURI;

  // Public Variables
  bool public started = false;
  bool public claimed = false;
  uint256 public constant MAX_SUPPLY = 6666;
  uint256 public constant MAX_MINT = 1;
  uint256 public constant TEAM_CLAIM_AMOUNT = 111;

  mapping(address => uint) public addressClaimed;

  constructor() ERC721A("We Are All Going to Die", "WAGDIE") {}

  // Start tokenid at 1 instead of 0
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function mint() external {
    require(started, "The pilgrimage to this land has not yet started");
    require(addressClaimed[_msgSender()] < MAX_MINT, "You have already received your Token of Worship");
    require(totalSupply() < MAX_SUPPLY, "All lost souls have been accounted for");
    // mint
    addressClaimed[_msgSender()] += 1;
    _safeMint(msg.sender, 1);
  }

  function teamClaim() external onlyOwner {
    require(!claimed, "Team already claimed");
    // claim
    _safeMint(SOUL1, TEAM_CLAIM_AMOUNT);
    _safeMint(SOUL2, TEAM_CLAIM_AMOUNT);
    claimed = true;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
      baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function enableMint(bool mintStarted) external onlyOwner {
      started = mintStarted;
  }
}
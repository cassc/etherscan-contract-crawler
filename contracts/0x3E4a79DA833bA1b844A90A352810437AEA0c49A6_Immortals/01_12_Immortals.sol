// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IGauntlet {
  function balanceOf(address addr) external view returns (uint number);
}

contract Immortals is ERC721, Ownable {
  constructor() ERC721("Immortals", "IMO") {}

  string private uri = "https://assets.bossdrops.io/immortals/";

  // Note: address should be different for testnet.
  IGauntlet gauntlets = IGauntlet(address(0x74EcB5F64363bd663abd3eF08dF75dD22d853BFC));

  uint public constant MAX_TOKENS = 10000;

  // Only 10 nfts can be purchased per transaction.
  uint public constant maxNumPurchase = 10;

  uint public totalGauntletMintsAllowed = 3000;
  uint public currentGauntletMints = 0;

  uint public totalWilderMintsAllowed = 1000;
  uint public currentWilderMints = 0;

  uint public totalMetaverseMintsAllowed = 500;
  uint public currentMetaverseMints = 0;

  uint public totalImmmortalsMintsAllowed = 300;
  uint public currentImmortalsMints = 0;

  mapping (address => bool) public gauntletsClaimed;

  mapping (address => bool) public wilderAllowList;
  mapping (address => bool) public wilderClaimed;

  mapping (address => bool) public metaverseAllowList;
  mapping (address => bool) public metaverseClaimed;

  mapping (address => bool) public immortalsAllowList;
  mapping (address => bool) public immortalsClaimed;

  /**
  * The state of the sale:
  * 0 = closed
  * 1 = gauntlet hodlers + mods
  * 2 = gauntlet holders + mods + wilder world
  * 3 = gauntlet hodlers + mods + wilder world + metav3rse
  * 4 = public
  */
  uint public saleState = 0;

  // Mint price is 0.15 ETH. 
  uint public mintPriceWei = 150000000000000000;

  // Early mint price is 0.07 ETH.
  uint public earlyMintPriceWei = 70000000000000000;

  uint public numMinted = 0;


  function _checkValueSentForEarlyMint(uint numTokens) internal view {
    require(msg.value >= SafeMath.mul(numTokens, earlyMintPriceWei), "Insufficient amount sent");
  }

  function _checkValueSentForRegularMint(uint numTokens) internal view {
    require(msg.value >= SafeMath.mul(numTokens, mintPriceWei), "Insufficient amount sent");
  }

  function _checkCanMint(address addr, uint num) internal {
    // Closed.
    require(saleState > 0, "Sale is closed");

    // Public sale is open.
    if (saleState == 4) {
      require(num <= maxNumPurchase, "Can only mint 10 tokens at a time");
      require(msg.value >= SafeMath.mul(num, mintPriceWei), "Insufficient amount sent ");
      return;
    }

    // Can only mint 1 in early access
    require(num == 1, "Can only mint 1 in early access");

    _checkValueSentForEarlyMint(num);

    // Gauntlet hodlers
    if (saleState >= 1) {
      if (gauntlets.balanceOf(addr) > 0 && !gauntletsClaimed[addr] && currentGauntletMints < totalGauntletMintsAllowed) {
        gauntletsClaimed[addr] = true;
        currentGauntletMints++;
        return;
      }
    }

    // Gauntlet hodlers + Wilder
    if (saleState >= 2) {
      if (wilderAllowList[addr] && !wilderClaimed[addr] && currentWilderMints < totalWilderMintsAllowed) {
        wilderClaimed[addr] = true;
        currentWilderMints++;
        return;
      }
    }

    // Gauntlet hodlers + Mods + Wilder + Metaverse + Immortals WL
    if (saleState >= 3) {
      if (metaverseAllowList[addr] && !metaverseClaimed[addr] && currentMetaverseMints < totalMetaverseMintsAllowed) {
        metaverseClaimed[addr] = true;
        currentMetaverseMints++;
        return;
      }

      if (immortalsAllowList[addr] && !immortalsClaimed[addr] && currentImmortalsMints < totalImmmortalsMintsAllowed) {
        // Immortals list mints at regular price
        immortalsClaimed[addr] = true;
        currentImmortalsMints++;
        return;
      }
    }

    revert("Public sale is not open, and the sender is not on a list");
  }

  function canMint(address addr) public view returns (bool) {
    
    // Closed.
    if (saleState == 0) return false;

    // Public sale is open.
    if (saleState == 4 && totalSupply() < MAX_TOKENS) return true;

    // Gauntlet hodlers
    if (saleState >= 1) {
      if (gauntlets.balanceOf(addr) > 0 && !gauntletsClaimed[addr] && currentGauntletMints < totalGauntletMintsAllowed) {
        return true;
      }
    }

    // Gauntlet hodlers + Wilder
    if (saleState >= 2) {
      if (wilderAllowList[addr] && !wilderClaimed[addr] && currentWilderMints < totalWilderMintsAllowed) {
        return true;
      }
    }

    // Gauntlet hodlers + Mods + Wilder + Metaverse + Immortals WL
    if (saleState >= 3) {
      if (metaverseAllowList[addr] && !metaverseClaimed[addr] && currentMetaverseMints < totalMetaverseMintsAllowed) {
        return true;
      }

      if (immortalsAllowList[addr] && !immortalsClaimed[addr] && currentImmortalsMints < totalImmmortalsMintsAllowed) {
        // Immortals list mints at regular price
        return true;
      }
    }

    return false;
  }

  function mint(uint num) public payable {
    _checkCanMint(msg.sender, num);
    _mintTo(msg.sender, num);
  }

  function _mintTo(address to, uint num) internal {
    uint newTotal = SafeMath.add(num, numMinted);
    require(newTotal <= MAX_TOKENS, "Minting would exceed max allowed supply");
    while(numMinted < newTotal) {
        _mint(to, numMinted);
        numMinted++;
    }
  }
  
  function totalSupply() public view virtual returns (uint) {
    return numMinted;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  /** OWNER FUNCTIONS */
  function ownerMint(uint num) public onlyOwner {
    _mintTo(msg.sender, num);
  }
  
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setSaleState(uint newState) public onlyOwner {
      require(newState >= 0 && newState <= 4, "Invalid state");
      saleState = newState;
  }

  function addToImmortalsAllowList(address[] memory addresses) public onlyOwner {
    for (uint i = 0; i < addresses.length; i++) {
      immortalsAllowList[addresses[i]] = true;
    }
  }

  function addToWilderAllowList(address[] memory addresses) public onlyOwner {
    for (uint i = 0; i < addresses.length; i++) {
      wilderAllowList[addresses[i]] = true;
    }
  }

  function addToMetaverseAllowList(address[] memory addresses) public onlyOwner {
    for (uint i = 0; i < addresses.length; i++) {
      metaverseAllowList[addresses[i]] = true;
    }
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    uri = baseURI;
  }

  function setMintPrice(uint newPriceWei) public onlyOwner {
    mintPriceWei = newPriceWei;
  }

  function setEarlyMintPrice(uint newPriceWei) public onlyOwner {
    earlyMintPriceWei = newPriceWei;
  }
}
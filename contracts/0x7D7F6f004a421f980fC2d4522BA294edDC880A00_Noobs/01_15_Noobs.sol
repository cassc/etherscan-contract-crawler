// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * ************************************
 * ************** NOOBS ***************
 * ************************************
 *
 * Inspired/copied from CryptoCandies and others ;)
 *
 * By Mike, Sven, and COBA
 */
contract Noobs is ERC721, Ownable {
  using SafeMath for uint256;

  /**
   * @dev Constants
   */
  uint public constant NOOB_LIMIT = 10000;
  uint private constant GIVEAWAY_LIMIT = 80;
  uint256 public constant MINT_PRICE = 40000000000000000; // 0.04 ETH

  /**
   * @dev Variables
   */
  bool public hasSaleStarted = false;
  bool internal URISet = false;
  uint[NOOB_LIMIT] private indices;

  /**
   * @dev Addresses
   */
  address payable public mikeWallet = payable(0x5DA3e70F8Ce9C85b6Ccbdfe1430D452E68A7BCcc);
  address payable public svenWallet = payable(0x063a48F3b73957b6d0640352525Eae313D4426c3);
  address payable public cobaWallet = payable(0x48b23c92Cd6E32DaeD6589428bD41804A5399884);
  address payable public projectWallet = payable(0xDbcB5606947783cc1dEac81Dee1F332E8767B767);
  address payable public joffWallet = payable(0xB4a9f08E1aDDaa8cE1837e3c73093d2970aae7eA);

  constructor() ERC721("Noobs", "NOOBS") {
  }

  /**
   * General usage
   */

  // Thanks to the DerpyBirbs' contract for showing us NOOBS how its done 
  function randomIndex() internal returns (uint) {
      uint totalSize = NOOB_LIMIT - totalSupply();
      uint index = uint(keccak256(abi.encodePacked(totalSupply(), msg.sender, block.difficulty, block.timestamp))) % totalSize;
      uint value = 0;

      if (indices[index] != 0) {
          value = indices[index];
      } else {
          value = index;
      }

      // Move last value to selected position
      if (indices[totalSize - 1] == 0) {
          // Array position not initialized, so use position
          indices[index] = totalSize - 1;
      } else {
          // Array position holds a value so use that
          indices[index] = indices[totalSize - 1];
      }
      return value;
  }


  // Lets... see... the... NOOBS!!!
  function listNoobsForOwner(address _owner) external view returns(uint256[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
        return new uint256[](0);
    } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 index;
        for (index = 0; index < tokenCount; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }
  }

  // NOOBS here! Get your NOOBS!
  function buyMultipleNoobs(uint256 numNoobs) external payable {
    require(hasSaleStarted == true, "Sale has not started yet");
    require(numNoobs > 0 && numNoobs <= 20, "You can only buy 1 to 20 Noobs at a time");
    require(totalSupply().add(numNoobs) <= NOOB_LIMIT, "There aren't enough Noobs left :(");
    uint256 totalPrice = MINT_PRICE.mul(numNoobs);
    require(msg.value >= totalPrice, "Ether value sent is below the price");

    uint id;
    for (uint i = 0; i < numNoobs; i++) {
        id = randomIndex();
        _safeMint(msg.sender, id);
    }
  }

  // $$$
  function withdrawFunds() external {
    uint256 contributorAmount = address(this).balance.mul(275).div(1000); // 27.5%
    uint256 joffAmount = address(this).balance.mul(25).div(1000); // 2.5%
    uint256 projectAmount = address(this).balance.mul(150).div(1000); // 15%
    cobaWallet.transfer(contributorAmount);
    mikeWallet.transfer(contributorAmount);
    svenWallet.transfer(contributorAmount);
    projectWallet.transfer(projectAmount);
    joffWallet.transfer(joffAmount);
  }

  /**
   * OWNER ONLY
   */

  // Start the NOOBS fest
  function startSale() external onlyOwner {
    require(hasSaleStarted == false,"Sale has already started");
    require(URISet == true, "URI not set");
    hasSaleStarted = true;
  }

  // Set aside some NOOBS for friends :)
  function reserveGiveawaySupply(uint256 numNoobs) external onlyOwner {
    require(totalSupply().add(numNoobs) <= GIVEAWAY_LIMIT, "Exceeded giveaway supply");
    require(hasSaleStarted == false, "Sale has already started");
    uint256 index;
    uint256 i;
    for (i = 0; i < numNoobs; i++) {
        index = randomIndex();
        _safeMint(projectWallet, index);
    }
  }

  // What do the NOOBS even look like?
  function setBaseURI(string memory baseURI) external onlyOwner {
      require(hasSaleStarted == false,"Can't change metadata after the sale has started");
      _setBaseURI(baseURI);
      URISet = true;
  }

  // Uh-oh button
  function setWallets(address payable _mikeWallet,
                      address payable _svenWallet,
                      address payable _cobaWallet,
                      address payable _projectWallet,
                      address payable _joffWallet) external onlyOwner {
    mikeWallet = _mikeWallet;
    svenWallet = _svenWallet;
    cobaWallet = _cobaWallet;
    projectWallet = _projectWallet;
    joffWallet = _joffWallet;
  }
}
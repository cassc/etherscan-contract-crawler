// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//    ___   __          _                   
//   / _/  / /  __ __  (_)  ___   ___ _    
//  / _/  / /  / // / / /  / _ \ / _ `/    
// /_/   /_/   \_, / /_/  /_//_/ \_, /     
//            /___/             /___/                                                               
//    ___                          __    _                 
//   / _/ ___   ____  __ _  ___ _ / /_  (_) ___   ___   ___
//  / _/ / _ \ / __/ /  ' \/ _ `// __/ / / / _ \ / _ \ (_-<
// /_/   \___//_/   /_/_/_/\_,_/ \__/ /_/  \___//_//_//___/
//
//

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlyingFormations is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint;
    using Strings for uint256;

    event TokenBought(
      uint tokenId,
      address recipient,
      uint paid,
      uint footballTeamReceives,
      uint ducksReceives,
      uint divisionStReceives
    );

    event AirMax1Redeemed(
      uint tokenId,
      address recipient
    );

    uint constant eth = 1e18; // WETH
    uint constant hrs = 1 hours; // HOURS (in seconds)

    
    uint constant price1 = 125*eth/10; // 12.5 ETH
    uint constant stage1 = 3*hrs; // 3 hours

    uint constant price2 = 5*eth; // 5 ETH
    uint constant stage2 = 9*hrs; // 9 hours

    uint constant floorPrice = 1*eth; // 1 ETH

    uint constant priceDeductionRate1 = (price1 - price2)/stage1; // drop to 5.0 ETH at 3 hours
    uint constant priceDeductionRate2 = (price2 - floorPrice)/stage2; // drop to 1.0 ETH at 12 hours

    mapping (address => bool) hasPurchased;

    uint saleStartsAt;
    bool redeemEnabled;
    bool redeemExpired;

    string sneakerBaseURI;
    string standardBaseURI;

    struct PremintEntry {
      address addr;
      uint tokenId;
    }

    mapping (uint => address) public sneakerRedeemedBy;

    address payable footballTeamWallet;
    address payable ducksWallet;
    address payable divisionStWallet;

    uint constant TEAM_SPLIT = 6750;
    uint constant DUCKS_SPLIT = 1000;

    uint constant MAX_TOKENS = 120;

    constructor(
      uint _saleStartsAt,
      string memory _sneakerBaseURI,
      string memory _standardBaseURI,
      PremintEntry[] memory premintEntries,
      address payable _footballTeamWallet,
      address payable _ducksWallet,
      address payable _divisionStWallet
    ) ERC721("Flying Formations", "FFT") {
      saleStartsAt = _saleStartsAt;

      // Set baseURIs for pre-redeem, and
      // post-redeem NFTs
      sneakerBaseURI = _sneakerBaseURI;
      standardBaseURI = _standardBaseURI;

      // Premint tokens for whitelist token recipients
      for(uint i; i < premintEntries.length; i++){
        _mint(premintEntries[i].addr, premintEntries[i].tokenId);
        hasPurchased[premintEntries[i].addr] = true;
        sneakerRedeemedBy[premintEntries[i].tokenId] = premintEntries[i].addr;
      }

      // Set team wallets
      footballTeamWallet = _footballTeamWallet;
      ducksWallet = _ducksWallet;
      divisionStWallet = _divisionStWallet;
    }

    function buy(address recipient, uint tokenId) public payable {
      require(!hasPurchased[msg.sender], "FlyingFormations: User has already bought one NFT");
      require(msg.sender == tx.origin, "FlyingFormations: Account is not an EOA");
      require(block.timestamp >= saleStartsAt, "FlyingFormations: auction has not started");
      require(tokenId <= MAX_TOKENS && tokenId > 0, "FlyingFormations: invalid tokenId");

      uint price = getPrice();
      require(msg.value >= price, "FlyingFormations: insufficient funds sent, please check current price");

      // Mint token and register purchaser so
      // user cannot buy more than one
      _mint(recipient, tokenId);
      hasPurchased[msg.sender] = true;


      // Distribute funds to teams
      uint footballTeamReceives = msg.value.mul(TEAM_SPLIT).div(10000);
      uint ducksReceives = msg.value.mul(DUCKS_SPLIT).div(10000);
      uint divisionStReceives = msg.value
        .sub(footballTeamReceives)
        .sub(ducksReceives);

      (bool success, ) = footballTeamWallet.call{value: footballTeamReceives}("");
      require(success, "FlyingFormations: footballTeamWallet failed to receive");
      (success, ) = ducksWallet.call{value: ducksReceives}("");
      require(success, "FlyingFormations: ducksWallet failed to receive");
      (success, ) = divisionStWallet.call{value: divisionStReceives}("");
      require(success, "FlyingFormations: divisionStWallet failed to receive");

      emit TokenBought(tokenId, recipient, price, footballTeamReceives, ducksReceives, divisionStReceives);
    }

    // Redeem functionality for claiming Nike Air Max 1 OU Edition
    //                                   _    _
    //                                  (_\__/(,_
    //                                  | \ `_////-._
    //                      _    _      L_/__ "=> __/`\
    //                     (_\__/(,_    |=====;__/___./
    //                     | \ `_////-._'-'-'-""""""`
    //                     J_/___"=> __/`\
    //                     |=====;__/___./
    //                     '-'-'-"""""""`
    function redeem(uint tokenId) public {
      require(redeemEnabled, "FlyingFormations: redeem is currently not enabled");
      require(!redeemExpired, "FlyingFormations: redeem window has expired");
      require(
        sneakerRedeemedBy[tokenId] == address(0x0),
        "FlyingFormations: token has already beened redeemed"
      );
      require(
        msg.sender == ownerOf(tokenId),
        "FlyingFormations: caller is not owner"
      );

      sneakerRedeemedBy[tokenId] = ownerOf(tokenId);
      emit AirMax1Redeemed(tokenId, msg.sender);
    }

    // ============ PUBLIC VIEW FUNCTIONS ============

    function getPrice() public view returns (uint) {
      require(block.timestamp >= saleStartsAt, "FlyingFormations: auction has not started");

      uint elapsedTime = block.timestamp - saleStartsAt;

      if (elapsedTime < stage1) {
        return price1.sub(elapsedTime.mul(priceDeductionRate1));
      } else if (elapsedTime < stage1 + stage2) {
        return price2.sub((elapsedTime.sub(stage1)).mul(priceDeductionRate2));
      } else {
        return floorPrice;
      }
    }

    function getAllTokens() public view returns (uint[] memory) {
      uint n = totalSupply();
      uint[] memory tokenIds = new uint[](n);

      for(uint i = 0; i < n; i++){
        tokenIds[i] = tokenByIndex(i);
      }
      return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      if (redeemExpired || sneakerRedeemedBy[tokenId] != address(0x0)){
        return string(abi.encodePacked(standardBaseURI, tokenId.toString(), ".json"));
      } else {
        return string(abi.encodePacked(sneakerBaseURI, tokenId.toString(), ".json"));
      }
    }

    // ============ OWNER INTERFACE ============
 

    function updateFootballTeamWallet(address payable _wallet) public onlyOwner {
      footballTeamWallet = _wallet;
    }

    function updateDucksWallet(address payable _wallet) public onlyOwner {
      ducksWallet = _wallet;
    }

    function updateDivisionStWallet(address payable _wallet) public onlyOwner {
      divisionStWallet = _wallet;
    }

    function updateBaseURI(string calldata __baseURI) public onlyOwner {
      standardBaseURI = __baseURI;
    }

    function updateSneakerBaseURI(string calldata __baseURI) public onlyOwner {
      sneakerBaseURI = __baseURI;
    }

    function updateSaleStartsAt(uint _saleStartsAt) public onlyOwner {
      saleStartsAt = _saleStartsAt;
    }

    function updateRedeemEnabled(bool _redeemEnabled) public onlyOwner {
      redeemEnabled = _redeemEnabled;
    }

    function updateRedeemExpired(bool _redeemExpired) public onlyOwner {
      redeemExpired = _redeemExpired;
    }

    function updatePaused(bool _paused) public onlyOwner {
      if (_paused) {
        _pause();
      } else {
        _unpause();
      }
    }
}
/* 
# .---.  .---.      ,-----.       ___    _     .-'''-.      .-''-.  
# |   |  |_ _|    .'  .-,  '.   .'   |  | |   / _     \   .'_ _   \ 
# |   |  ( ' )   / ,-.|  \ _ \  |   .'  | |  (`' )/`--'  / ( ` )   '
# |   '-(_{;}_) ;  \  '_ /  | : .'  '_  | | (_ o _).    . (_ o _)  |
# |      (_,_)  |  _`,/ \ _/  | '   ( \.-.|  (_,_). '.  |  (_,_)___|
# | _ _--.   |  : (  '\_/ \   ; ' (`. _` /| .---.  \  : '  \   .---.
# |( ' ) |   |   \ `"/  \  ) /  | (_ (_) _) \    `-'  |  \  `-'    /
# (_{;}_)|   |    '. \_/``".'    \ /  . \ /  \       /    \       / 
# '(_,_) '---'      '-----'       ``-'`-''    `-...-'      `'-..-'  
# .-------.    .---.         ____     ,---.   .--. ,---------.     .-'''-. 
# \  _(`)_ \   | ,_|       .'  __ `.  |    \  |  | \          \   / _     \
# | (_ o._)| ,-./  )      /   '  \  \ |  ,  \ |  |  `--.  ,---'  (`' )/`--'
# |  (_,_) / \  '_ '`)    |___|  /  | |  |\_ \|  |     |   \    (_ o _).   
# |   '-.-'   > (_)  )       _.-`   | |  _( )_\  |     :_ _:     (_,_). '. 
# |   |      (  .  .-'    .'   _    | | (_ o _)  |     (_I_)    .---.  \  :
# |   |       `-'`-'|___  |  _( )_  | |  (_,_)\  |    (_(=)_)   \    `-'  |
# /   )        |        \ \ (_ o _) / |  |    |  |     (_I_)     \       / 
# `---'        `--------`  '.(_,_).'  '--'    '--'     '---'      `-...-'   */


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract House_Plants is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;
    using SafeMath for uint256;


  constructor (string memory customBaseURI_) ERC721("House Plants by Felt Zine", "HPFZ") {
    customBaseURI = customBaseURI_;
  }

  // Reserve 50 Villains for Felt team - Giveaways/Prizes etc
  uint public HousePlantsReserve = 500;

  

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 5000;

  uint256 public constant MAX_MULTIMINT = 50;

  uint256 public constant PRICE = 20000000000000000;

  function GrowPlants(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 50 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.02 ETH per item"
    );

    for (uint256 i = 0; i < count; i++) {
      _safeMint(_msgSender(), totalSupply());
    }
  }

  function reserveHousePlants(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= HousePlantsReserve, "Nah fam, there's no more left for Felt.");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        HousePlantsReserve = HousePlantsReserve.sub(_reserveAmount);
    }

  /** ACTIVATION **/

  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  /** PAYOUT **/

 
  address private constant payoutAddress1 =
    0x3ae285B8f6ADcf9C728d0B761948e25DD065610E;

  address private constant payoutAddress2 =
    0xF871A4FB983b89C123CD4e70f768DC9EF5ce5f71;

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;

    payable(owner()).transfer(balance * 40 / 100);

    payable(payoutAddress1).transfer(balance * 50 / 100);

    payable(payoutAddress2).transfer(balance * 10 / 100);
  }
}
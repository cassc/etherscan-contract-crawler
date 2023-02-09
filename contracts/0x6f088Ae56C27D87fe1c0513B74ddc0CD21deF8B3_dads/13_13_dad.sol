//SPDX-License-Identifier: MIT

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWXkolcc:,'.',cokO0KNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWx'       ..........',;cldOKNMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWk. ..........',,''..........,lONMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM0, ..........''''...'',,,,;;;. '0MMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMNl  ..........''.'',,,'',,;;::. cNMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMK, ;lollllccclllooooooooooooo; .kWMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMWNKO0NMO'.cddddxxxddollc::;;,''.....  .,;:loxOKWMMMMMMMMMMMMMMMMM
// MMMMMMMMMWKd:'. .;l;. .............   .........  .',,'''...xWMMMMMMMMMMMMMMMM
// MMMMMMMMXl.............'....................'''.';:clooc. ,0MMMMMMMMMMMMMMMMM
// MMMMMMMNl .:c:;,,,,,,',,,;;::;;;,,''........'',,;;;;,'..,dXMMMMMMMMMMMMMMMMMM
// MMMMMMM0' ,llc:;,'''.''''',,;;;;,'................  .,lONMMMMMMMMMMMMMMMMMMMM
// MMMMMMMNo..................................;loooodc..kWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMWXOxo:. .,,'''''.';cloxO0KXXXKKK00KXWMMMMMX: lWMMMMMMMMMMMMWWMMMMMMMM
// MMMMMMMMMMMMWd.'OWNNNN0c.'lXMMMMMMMMMMMMXo''cKMMMMNc lWMMMMMMWX0kdl:c0MMMMMMM
// MMMMMMMMMMMMK,.dWMMMMM0;  ;0MMMMMMMMMMMMK:..,0MMMMX: oWMMMMXd:'',;cokNMMMMMMM
// MMMMMMMMMMMMx.'0MMMMMMWXOOXMMMMMMMMMMMMMMN00XWMMMMK;.dWMMMNl.,xKNWMMMMMMMMMMM
// MMMMMMMMMMMMx.,KMMMMMMMMMMMWNXXXXXXXXNWMMMMMMMMMMMK,.xMMMMX; oWMMMMMMMMMMMMMM
// MMMMMMMMMMMMk..OMMMMWx:lxxl:;,'''''',:llox00KNMMMM0'.kMWXkc..kMMMMMMMMMMMMMMM
// MMMMMMMMMMMM0'.kMMMMNd.....,;,,cc;,,;;,,.....;dXMMO..ONo..;o0WMMMMMMMMMMMMMMM
// MMMMMMMMMMMM0'.kMMMMWX0d'..''.'''''......     .dXNd.,KO;;OWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMNl.,OWMMMMMWKOOOOOOOOOOd:'..      ..''. .oO0NMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMXd..xWMMMMMMMMMMMMMMMMMWNXKkdc;...... .''.;OWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWx..kWMMMMMMMMMMMMMMMMMMMMMMMWX0xc.  .'...dWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWx..lKWMMMMMMMMMMMMMMMMMMMMMMMNk,.;k0kxx0WMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWKl..dNMMMMMMMMMMMMMMMMMMMMNx;.,xNMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWO,.:ONWMMMMMMMMMMMMMMMXd,.;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMKo,',;coxkO0KKKK0Okxl'.:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMN0koc:;,,,,,'',,,,;oOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXKKKKXXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

pragma solidity ^0.8.9;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IToken {
    function ownerOf(uint256) external view returns (address);
    function balanceOf(address) external view returns (uint256);
}

contract dads is ERC721, Ownable {

  address public constant mfer_address = 0x79FCDEF22feeD20eDDacbB2587640e45491b757f;
  address public constant originalDadAddress = 0x9631394E8f4036B6Ec2469f9F580D1Ce1C9C3565;
  uint256 public constant originalDadSupply = 349;
  string public baseURI = "https://assets.areyawinningson.xyz/meta";
  uint256 public limit = 10021;
  uint256 public requested = 0;
  uint256 public dadDrops = 0;
  uint256 public dadFinalDrops = 0;
  uint256 public creatorDads = 10;

  using Counters for Counters.Counter;
  Counters.Counter public _tokenIds;

  constructor() ERC721("dad", "DAD") {
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
    baseURI = newBaseURI;
  }

  function stopMinting() external onlyOwner {
    limit = requested;
  }

  function totalSupply() public view returns (uint256) {
    return requested;
  }

  function dadDrop() external onlyOwner {
    // Iterate through all the holders of the original collection
    require(dadDrops < 1, "dadDrop already happened.");
    dadDrops += 1;
    for (uint256 i = 1; i < originalDadSupply + 1; i++) {
        address holder = IToken(originalDadAddress).ownerOf(i);
        requested += 1;
        _tokenIds.increment();
        _safeMint(holder, _tokenIds.current());
    }
    }

  function dadFinalDrop() external onlyOwner {
    require(limit == requested, "Minting is still ongoing.");
    require(dadFinalDrops < 1, "dadFinalDrop already happened.");
    address owner_ = owner();
    for (uint256 i = 0; i < creatorDads + 1; i++) {
        requested += 1;
        _tokenIds.increment();
        _safeMint(owner_, _tokenIds.current());
    }
    }

  function mint()
    public
  {
    uint256 balance = IToken(mfer_address).balanceOf(msg.sender);
    require(balance > 0, "Wallet does not have an mfer");
    require( (requested + balance) <= limit, "Limit Reached, done minting" );
    requested += balance;
    for (uint i = 1; i <= balance; i++ ) {
      _tokenIds.increment();
      _safeMint(msg.sender, _tokenIds.current());
    }
  }
}
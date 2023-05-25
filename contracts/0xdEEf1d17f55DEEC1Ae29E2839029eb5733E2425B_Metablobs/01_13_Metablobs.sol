// SPDX-License-Identifier: MIT

/*   
 ███▄ ▄███▓████▄▄▄█████▓▄▄▄      ▄▄▄▄   ██▓    ▒█████  ▄▄▄▄    ██████ 
▓██▒▀█▀ ██▓█   ▓  ██▒ ▓▒████▄   ▓█████▄▓██▒   ▒██▒  ██▓█████▄▒██    ▒ 
▓██    ▓██▒███ ▒ ▓██░ ▒▒██  ▀█▄ ▒██▒ ▄█▒██░   ▒██░  ██▒██▒ ▄█░ ▓██▄   
▒██    ▒██▒▓█  ░ ▓██▓ ░░██▄▄▄▄██▒██░█▀ ▒██░   ▒██   ██▒██░█▀   ▒   ██▒
▒██▒   ░██░▒████▒▒██▒ ░ ▓█   ▓██░▓█  ▀█░██████░ ████▓▒░▓█  ▀█▒██████▒▒
░ ▒░   ░  ░░ ▒░ ░▒ ░░   ▒▒   ▓▒█░▒▓███▀░ ▒░▓  ░ ▒░▒░▒░░▒▓███▀▒ ▒▓▒ ▒ ░
░  ░      ░░ ░  ░  ░     ▒   ▒▒ ▒░▒   ░░ ░ ▒  ░ ░ ▒ ▒░▒░▒   ░░ ░▒  ░ ░
░      ░     ░   ░       ░   ▒   ░    ░  ░ ░  ░ ░ ░ ▒  ░    ░░  ░  ░  
       ░     ░  ░            ░  ░░         ░  ░   ░ ░  ░           ░  
                                      ░                     ░   
 */

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// to check balances of beneficiary NFT projects holdings
interface ERC721Interface {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract Metablobs is ERC721, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using Address for address;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721("Metablobs", "MB") {
  }

  uint256 public constant MAX_SUPPLY = 100000;
  bool public mintingIsLive = false;
  string public baseUri = "ipfs://Qme4X5BP2RFXJSEmkUTBEUpcYjX2jNk4n8mFDuro1hfw4D/" ;

  // I can fit so many addresses in here
  mapping (address => uint256) public tokensPerAddress;

  // Beneficiary NFT Projects
  ERC721Interface flbc = ERC721Interface(0x193DaA9EDB94E316C1Ae41DC7B4c01AB1ee18A0e);
  ERC721Interface coolcats = ERC721Interface(0x1A92f7381B9F03921564a437210bB9396471050C);
  ERC721Interface bayc = ERC721Interface(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D); 
  ERC721Interface turtletanks = ERC721Interface(0x6ca95B029E1bCA507c87d42B46157a76Dab54EC2);
  ERC721Interface creatures = ERC721Interface(0xc92cedDfb8dd984A89fb494c376f9A48b999aAFc);
  ERC721Interface animetas = ERC721Interface(0x18Df6C571F6fE9283B87f910E41dc5c8b77b7da5);
  ERC721Interface dogepound = ERC721Interface(0xF4ee95274741437636e748DdAc70818B4ED7d043);
  ERC721Interface uunicorns = ERC721Interface(0xC4a0b1E7AA137ADA8b2F911A501638088DFdD508);
  ERC721Interface mekaverse = ERC721Interface(0x9A534628B4062E123cE7Ee2222ec20B86e16Ca8F);
  ERC721Interface neotokyocitadelIdentity = ERC721Interface(0x86357A19E5537A8Fba9A004E555713BC943a66C0); 

  // thats right nerds, stay out of my function!
  modifier onlyEOA() {
      require(msg.sender == tx.origin, "prevent smart contract access: Only EOA");
      _;
  }

  // yes this is new Guerrilla coding
  function getAllowedMetablobsAmountFromHoldersOtherNFTHoldingsLongName(address tokenholder) public view returns(uint){
    uint allowance = 1;
    ERC721Interface[10] memory nftprojects = [flbc,coolcats, bayc,turtletanks,creatures,animetas,dogepound,uunicorns,mekaverse,neotokyocitadelIdentity];
    for(uint i = 0; i< nftprojects.length; i++){
      if(nftprojects[i].balanceOf(tokenholder) > 0){
        allowance += 1;
      }
    }
    return allowance;
  }

  // get your fresh Metablobs here!
  function mintMetablobs(address to) external onlyEOA nonReentrant {
    require(mintingIsLive, "too soon !");
    if(to == msg.sender){
      require(
        tokensPerAddress[msg.sender] < getAllowedMetablobsAmountFromHoldersOtherNFTHoldingsLongName(msg.sender), 
        "you minted enough, pal"
        );
      // mint the Metablobs straight to your home (wallet)!
      require(totalSupply() + 1 <= MAX_SUPPLY, "Thats enough Metablobs mintin' for today");
      tokensPerAddress[msg.sender] += 1;
      mintM(to);
    }
    else {
      // or to someone you like very much :
      require(totalSupply() + 2 <= MAX_SUPPLY, "Didnt you hear ? Thats enough Metablobs mintin' for today, buddy!");
      mintM(to);
      // who knows maybe they like you too...
      mintM(msg.sender);
    }
  }

  // you will never call this directly, friend ;)
  function mintM(address to) private {
    _safeMint(to, _tokenIds.current());
    _tokenIds.increment();
  }

  // "SET IT!" said the Setter
  function setBaseUri(string memory newBaseUri) external onlyOwner {
    baseUri = newBaseUri;
  }

  function switchMintingState() external onlyOwner {
    mintingIsLive = !mintingIsLive;
  }

  // ~ where ~ the ~ magic ~ happens ~
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory _tokenURI = "Token with that ID does not exist.";
    if (_exists(tokenId)){
      _tokenURI = string(abi.encodePacked(baseUri, tokenId.toString(),  ".json"));
    }
    return _tokenURI;
  }
  
  //  riiight, who needs an entire import statement for that anyway ?
  function totalSupply() public view returns(uint){
    return _tokenIds.current();
  }

}
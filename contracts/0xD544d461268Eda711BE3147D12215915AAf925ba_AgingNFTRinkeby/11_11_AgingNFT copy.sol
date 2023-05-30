pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

contract AgingNFTRinkeby is ERC721  {

  string[] public phases = [
    "QmPqWcjfUzfQarRuP9d7QCyAZREZD9uSxEK9fzvn3abhXx",
    "QmPskmBY1MhpkdTyNKup8NkEFJFtr9u9ARUHc195GPoi92",
    "QmaACkqw4JHMNpdfaxM7QhfcjM8heoTo313JNdct9nwqgE",
    "QmRnEwVQW3Nc7ozy4ZrvFvZ5cAYEUWkaHzSxi8jbLpvwTZ",
    "QmdCvspMs58ZQYvzF4cw1kGde4xaYvFWFKDZQchYqtHJA9",
    "QmSmVKnnzuWkmB78E3hGCQAQEitvfEjfS3JGxryikGqwG2",
    "Qmdt8UAZ7DHe8hFo5cq2T77SrDeMnkvAffQB9Zccur6svM",
    "QmPz7nM1HEsyKtT4G3fpTeeqFFHY2uvW3Hs6GS5UfGdoca",
    "QmV7Uq3yMFVCwtofDghNnwG2PpytfeiMr6nN9yFxks5UEF",
    "QmbxZ5oxkCdPkiPs9nRRS9LVYLLmKAozyCUGvcfbQJHB6L",
    "QmTJCYegcWojfgZYMuJS1LmWGgoZkHjHdguahNFARwcXxj",
    "QmQK2XASY5sHYWamtAUzmXH1g1k7PSBr7Vx4VhbDhzR2gz"
  ];
  bool hasClaimed = false;
  string constant internal baseURI_ = 'https://ipfs.io/ipfs/';

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  address[36] public recipients = [
    0x23EAE4b3fE95E5AD91B1EdD879Fa8f8A1b308de1,
    0x23EAE4b3fE95E5AD91B1EdD879Fa8f8A1b308de1,
    0x23EAE4b3fE95E5AD91B1EdD879Fa8f8A1b308de1,
    0xBB167577B0399421cBD3415DDA399117b4d20449,
    0x441e1e47a6Fa2DBfD3cd9b54291E9AB3a58D7975,
    0x807a1752402D21400D555e1CD7f175566088b955,
    0xbF7877303B90297E7489AA1C067106331DfF7288,
    0xfC5A40e00c75cbBF34b39fa2C5c4Ebe70848D8D8,
    0xfC5A40e00c75cbBF34b39fa2C5c4Ebe70848D8D8,
    0xfC5A40e00c75cbBF34b39fa2C5c4Ebe70848D8D8,
    0x181b35730F3c660aa266Aa4Bef5E8d39B842DFb4,
    0x4A95E1cd71D214DC9095E6bcE9d2Ce3a7Aee09e3,
    0xF41fB4e336214C908dF9055A24eE2807696fb056,
    0x4deBBa864DA5B2fFd1C59A7bFAAf0E2FfDea8fEd,
    0x1c80D2A677c4a7756cf7D00fbb1c1766321333c3,
    0xbf7ab5009533f88Dca32C41558E0a8d4967d5d18,
    0xbf7ab5009533f88Dca32C41558E0a8d4967d5d18,
    0xbf7ab5009533f88Dca32C41558E0a8d4967d5d18,
    0xbf7ab5009533f88Dca32C41558E0a8d4967d5d18,
    0xbf7ab5009533f88Dca32C41558E0a8d4967d5d18,
    0xbf7ab5009533f88Dca32C41558E0a8d4967d5d18,
    0xbf7ab5009533f88Dca32C41558E0a8d4967d5d18,
    0xbf7ab5009533f88Dca32C41558E0a8d4967d5d18,
    0xd1778C38E0491A8e8A1B35633F3447dBe44ef0c0,
    0xBB1D9A024feE509d165D6bf3bDe693E87735F0Ee,
    0x9BAfBdC7b7179b776f0d07b71eb8A1F84a618fFb,
    0x5e349eca2dc61aBCd9dD99Ce94d04136151a09Ee,
    0xE9D13BCc792a10021F0102B25fd0B2f500229f3a,
    0x98CC9fe7DBf09e8CF9998Ab524a81Df3da344f90,
    0x98CC9fe7DBf09e8CF9998Ab524a81Df3da344f90,
    0xdd3767ABcAB26f261e2508A1DA1914053c7DDa78,
    0x008c84421dA5527F462886cEc43D2717B686A7e4,
    0x5F6c73d40302136e0F5D56517bA61AA6D162c52d,
    0x14A03CA8740A0044E63d3Bb0432540d9509473d1,
    0xd16C24e9CCDdcD7630Dd59856791253F789b1640,
    0x31929BD36b50bb739C0C80fA30808D93004EEca3
  ];

  constructor() ERC721("AgingNFT", "AGING") {
  }

  function airDrop() public {
    require(hasClaimed == false, 'Already airdropped!');
    uint i = 0;
    for(i; i<=35; i++) {
     _tokenIds.increment();
     _mint(recipients[i], _tokenIds.current());
    }
    hasClaimed = true;
  }
  
  function contractURI() public view returns (string memory) {
    return "https://bonez.mypinata.cloud/ipfs/QmdX2kAhe8Rducy1MHRH8s7vq5vff1k7HBXCTp5QMTcS3S";
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      string memory _tokenURI;

      if(block.timestamp< 1639094400){
        _tokenURI = phases[0];
      }else if(block.timestamp< 1650585600){
        _tokenURI = phases[1];
      }else if(block.timestamp< 1666396800){
        _tokenURI = phases[2];
      }else if(block.timestamp< 1682121600){
        _tokenURI = phases[3];
      }else if(block.timestamp< 1713744000){
        _tokenURI = phases[4];
      }else if(block.timestamp< 1776816000){
        _tokenURI = phases[5];
      }else if(block.timestamp< 1903046400){
        _tokenURI = phases[6];
      }else if(block.timestamp< 2218665600){
        _tokenURI = phases[7];
      }else if(block.timestamp< 2849817600){
        _tokenURI = phases[8];
      }else if(block.timestamp< 4112035200){
        _tokenURI = phases[9];
      }else if(block.timestamp< 4774723200){
        _tokenURI = phases[10];
      }else {
        _tokenURI = phases[11];
  }
      return string(abi.encodePacked(baseURI_, _tokenURI));
}

}
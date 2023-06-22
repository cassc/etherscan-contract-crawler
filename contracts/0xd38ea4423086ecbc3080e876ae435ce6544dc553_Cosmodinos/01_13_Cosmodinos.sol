// SPDX-License-Identifier: GPL-3.0
// @author: Gabou and TZN

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                       hMdosNNo-------:shddy/                                     //
//                                     hMh`  -mMs----+hNNs/sMN/                                     //
//                                    :dMh`   `-mMy:odNd+`   hMy                                    //
//                                  :dMm+syhhddmMMMMMd+:`   +Mm                                     //
//                                 :smMMNdhsoo+++++osyhdNMNho/MM:                                   //
//                              :smMmy+-.................-+sdMMMyoshdmMMMMmo                        //
//                            :sNNy/.........................-+hNMMd+/-``-NM/                       //
//                           +mMy:..............................-omMh:   -MM:                       //
//                          sNN+..................................-+mNh. dMy                        //
//                         oMN/.....................................-sNNyMN:                        //
//                        :NM+......................................../dMMh+//:                     //
//                       sMd..........................................-hMMmmmmmdy                   //
//                      :/mMmyyo+:-.................-:+syyyso/-.........-dMh.-:/sMN:                //
//                     :ymNmddddmNNds:............-/ymNNmdhddNNms-........-mM/   :MM/               //
//                    :mMds++++++oshNNy-........./dMmhs+++++++sdMd-........+MN`.yMm+                //
//                   hMd+++++++++++ohMm/.......+NMyo+++++++++++NMo.........mMhNNs                   //
//                   dMh+++++++++++++yMN:...../MMs+++++++++++++mMs.........sMMN+                    //
//                   oMNo+++++++-``-++dMh.....mMy+++++++-``-++oMM/..-+-..../MMmMmy+                 //
//                    hMms++++++.  `++oMM-.../MNo+++++++.  `+yNMo.//hMy..../MM .ohMm:               //
//                     oNMmhyssssooyyhmMM:...+MMmhyyssssssyhNMd/..hMBEdo...+MN   .mMo               //
//                    /NMyhdmmmNmmmdhs+-.....:+shddmmmmmmdhs:-.+y+mMys/...sMh-odNmy                 //
//                    :NMo..---------.............---------...../NMMMs.....NMNNdy/:                 //
//                    dMy..................................:/...-mmos+....oMMd/:                    //
//                   :MM:.:+/-.........................-:odNd-...--......:NMmMy                     //
//                   /MM..ommmdyo/:--............--:/oymNMMd-...........:mM+.hMh:                   //
//             +hy:--:MM/..-:+mMMNNmmdhyysssssyhhdmNMMMm+hMy.........../mMy..-mMs                   //
//            sNNMm/--yMd-....oMN:yMTZNMddMMNNMmosMMydNNhmMy.........-oNMNdmmmNd:                   //
//           hMm/sNNo--hMd:...-NMdNmo/mM+sMm//dMhmMy+++oymNo........:hMm++////:                     //
//         /s/      Mh:-sNNs-..sNm+-..:mMMd-...oNMd://+/..:.......:yNMMdo:                          //
//        sh.       dMm/-:yNNy/--......:ys......-+-..:+/.......-+hMMNmmMMm+                         //
//      dMm/         MMs--:sdMNy+-...................--....-+hNMNmdddmNMMN                          //
//     +NMy           Mh:---:ohMMmhs/................-/oymMMNmdddmNMMNNMM                           //
//    sMNo             +hMm/---omMNNNMM/............smNMMNNmmdmmNNMMNNmdNMy                         //
//    dMd              oNMs-/dMNmdddNMy...........sMMmmdddmNMMMMMNddddNMd                           //
//     dMh              NMs-sNMmdddmmmMM/........-yMNmmmmddmNmmdmMMNddNMd                           //
//      dMh            s:hMNmdddNMMMMMNo-....:omMNmMMMMNdddddddmNMNNMy                              //
//       dMh           mNs:hMNdddddGABONmNMmdhhdNMNmdmVALNdddddddddNMMo                            //
//        dMd         Ms-yMNddddddmMMmdddmmNNNmmmddddNMNmdddddddddddNMy                             //
//         MMmddddddNMm-oMMmddddNNNMNddddddddddddddddMMmdmNNddddddddmMM                             //
//         MMsooooooyMN:NMmdddddMMNMMddddddddddddddddMMmdmMMdddddddddNMh                            //
//         hNmhhhhhdmNyyMNdddddmMMmMMdddddddddddddddmMMdddMMmddddddddmMM                            //
//           sMMsoMMy/:NMmdddddmMMmMMdddddddddddddddNMNdddNMmdddddddddMM+                           //
//            MM:-NM+-oMMddddddNMNdmmdddddddddddddddmmddddNMNdddddddddMMs::                         //
//            MM:-NM+-hMNddddddMMmddddddddddddddddddddddddmMMdddddddddNMs:                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////

contract Cosmodinos is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  bool public paused = true;
  uint256 public cost = 0.03 ether;
  uint256 public maxSupply = 8888;
  uint256 public maxMintAmount = 10;
  address private walletCosmo = 0x6B993428cDb4162CaC6d9749ABb352442Cec760b;
  address private walletMBE = 0x615964F63fE29bc135DC8FEc7386928dF13A8451;
  address private walletValentino = 0x375699AA68a81f406128d6E3315EeD4A55b242F1;
  address private walletTZN = 0x99BC2C062C50AfF4B7cb75C7Aa359062549D870a;
  address private walletGabo = 0x7ca160eB2aed39937298A55F3466a5F71D6cf367;

  mapping(address => bool) public whitelist;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "CONTRACT PAUSED");
    require(_mintAmount > 0, "MINT AMOUNT SHOULD BE HIGHER THAN 0");
    require(supply + _mintAmount <= maxSupply, "INSUFFICIENT SUPPLY");
    require(_mintAmount <= maxMintAmount, "MINT AMOUT SUPERIOR AT 10");
    require(msg.value >= cost * _mintAmount, "NOT ENOUGH ETH ON YOUR WALLET");
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  
  function mintWhiteList(address _to, uint256 _mintAmount) public onlyOwner {
      uint256 supply = totalSupply();
      require(whitelist[_to], "NOT IN THE LIST");      
      require(_mintAmount > 0, "MINT AMOUNT SHOULD BE HIGHER THAN 0");
      require(supply + _mintAmount <= maxSupply, "INSUFFICIENT SUPPLY");

      for (uint256 i = 1; i <= _mintAmount; i++) {
        _safeMint(_to, supply + i);
      }
  }

 function whitelistUser(address[] calldata _users) public onlyOwner {
   for (uint i = 0; i < _users.length; i++) {
       whitelist[_users[i]] = true;
    }
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    uint256 amount = address(this).balance;

    require(payable(walletCosmo).send((amount * 30) / 100));
    require(payable(walletMBE).send((amount * 36) / 100));
    require(payable(walletValentino).send((amount * 24) / 100));
    require(payable(walletTZN).send((amount * 5) / 100));
    require(payable(walletGabo).send((amount * 5) / 100));
  }  
}
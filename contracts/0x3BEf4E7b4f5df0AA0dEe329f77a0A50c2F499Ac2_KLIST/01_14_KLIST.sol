// SPDX-License-Identifier: MIT

// https://kanon.art - K21
// https://daemonica.io
//
//
//                                   [email protected]@@@@@@@@@@$$$
//                               [email protected]@@@@@$$$$$$$$$$$$$$##
//                           $$$$$$$$$$$$$$$$$#########***
//                        $$$$$$$$$$$$$$$#######**!!!!!!
//                     ##$$$$$$$$$$$$#######****!!!!=========
//                   ##$$$$$$$$$#$#######*#***!!!=!===;;;;;
//                 *#################*#***!*!!======;;;:::
//                ################********!!!!====;;;:::~~~~~
//              **###########******!!!!!!==;;;;::~~~--,,,-~
//             ***########*#*******!*!!!!====;;;::::~~-,,......,-
//            ******#**********!*!!!!=!===;;::~~~-,........
//           ***************!*!!!!====;;:::~~-,,..........
//         !************!!!!!!===;;::~~--,............
//         !!!*****!!*!!!!!===;;:::~~--,,..........
//        =!!!!!!!!!=!==;;;::~~-,,...........
//        =!!!!!!!!!====;;;;:::~~--,........
//       ==!!!!!!=!==;=;;:::~~--,...:~~--,,,..
//       ===!!!!!=====;;;;;:::~~~--,,..#*=;;:::~--,.
//       ;=============;;;;;;::::~~~-,,...$$###==;;:~--.
//      :;;==========;;;;;;::::~~~--,,[email protected]@$$##*!=;:~-.
//      :;;;;;===;;;;;;;::::~~~--,,...$$$$#*!!=;~-
//       :;;;;;;;;;;:::::~~~~---,,...!*##**!==;~,
//       :::;:;;;;:::~~~~---,,,...~;=!!!!=;;:~.
//       ~:::::::::::::~~~~~---,,,....-:;;=;;;~,
//        ~~::::::::~~~~~~~-----,,,......,~~::::~-.
//         -~~~~~~~~~~~~~-----------,,,.......,-~~~~~,.
//          ---~~~-----,,,,,........,---,.
//           ,,--------,,,,,,.........
//             .,,,,,,,,,,,,......
//                ...............
//                    .........

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";


interface IKLISTvN {
  function isValid(address _hodler) external view returns (bool);
  function getTier(address _member) external view returns (uint256);
  function getAttributes(address _member) external view returns (string memory);
  function getURI(address _member, uint8 _status) external view returns (string memory);
  function claim(address _member) external;
}


/**
 * @title KLIST contract
 * @author @0xAnimist
 * @notice Versionable by owners and claimable by K21 token holders with a minimum balance
 */
contract KLIST is ERC721Enumerable, ReentrancyGuard, Ownable {

  uint256 public version;
  IKLISTvN[] private _klistVn;//key == version
  uint256[] public maxTokenIdPerVersion;//key == version
  address public klistVnContract;


  /** @notice Returns the tier of the KLIST token owned by _member
    * @param _member Ethereum address of the _member
    * @return The tier
    */
  function getTier(address _member) external view returns (uint256) {
    return _klistVn[version].getTier(_member);
  }

  /** @notice Returns the attributes of the KLIST token owned by _member
    * @param _member Ethereum address of the _member
    * @return Attributes for rendering with tokenURI
    */
  function getAttributes(address _member) external view returns (string memory) {
    return _klistVn[version].getAttributes(_member);
  }


  /** @notice Returns true if the KLIST membership of _tokenId is currently valid
    * @param _tokenId The KLIST token to query
    * @return True if valid, false if not
    */
  function isValid(uint256 _tokenId) external view returns (bool) {
    if(!_exists(_tokenId)){
      return false;
    }else{
      if(version == 0){
        return _klistVn[version].isValid(msg.sender);
      }else{
        uint256 v = getVersionByTokenId(_tokenId);
        if(v == version){//current version
          return _klistVn[version].isValid(msg.sender);
        }else{//not current version
          return false;
        }
      }
    }
  }

  /** @notice Updates the KLIST token version
    * @param _newKLISTvNContract The new KLISTvN version contract address
    */
  function incrementVersion(address _newKLISTvNContract) external onlyOwner() {
    incrementVersion(_newKLISTvNContract, klistVnContract);
  }

  /** @notice Updates the KLIST token version and replaces the previous version
    * @param _newKLISTvNContract The new KLISTvN version contract address
    * @param _oldKLISTvNContract The new KLISTvN-1 version contract address
    */
  function incrementVersion(address _newKLISTvNContract, address _oldKLISTvNContract) public onlyOwner() {
    maxTokenIdPerVersion[version] = totalSupply()-1;
    _klistVn[version] = IKLISTvN(_oldKLISTvNContract);//allows for updating the art of a now invalid KLIST token
    version++;
    _klistVn[version] = IKLISTvN(_newKLISTvNContract);
    klistVnContract = _newKLISTvNContract;
  }

  /** @notice Allows a valid Ethereum address to claim only one KLIST membership token
    */
  function claim() external nonReentrant {//returns (uint256){
    require(_klistVn[version].isValid(msg.sender), "not valid");
    require(balanceOf(msg.sender) == 0, "already claimed");
    _safeMint(msg.sender, totalSupply()+1);//mint the next token
    _klistVn[version].claim(msg.sender);
  }

  /** @notice Allows KLIST contract owner to claim KLIST membership tokens on behalf
    * of members
    */
  function proxyClaim(address[] memory _members) external nonReentrant onlyOwner {//returns (uint256){
    for(uint256 i = 0; i < _members.length; i++){
      _safeMint(_members[i], totalSupply()+1);//mint the next token
      _klistVn[version].claim(_members[i]);
    }
  }

  /** @notice Returns the KLISTvN version number of a given _tokenId
    * @param _tokenId The tokenId to query
    * @return The KLISTvN version of _tokenId
    */
  function getVersionByTokenId(uint256 _tokenId) internal view returns (uint256) {
    uint256 v = 0;
    if(version > 0){
      while(_tokenId > maxTokenIdPerVersion[v]){
        v++;
      }
    }
    return v;
  }


  /** @notice Returns the current status of a KLIST membership token
    * @param _tokenId The tokenId to query
    * @param _v The KLISTvN version of the _tokenId
    * @return 1 if not a member, 2 if expired, 3 if duplicate, 4 if invalid, 0 otherwise
    */
  function getStatus(uint256 _tokenId, uint256 _v) public view returns (address, uint8) {
    //"not a member"
    if(!_exists(_tokenId)){
      return (address(0), 1);
    }

    //"expired"
    address member = ownerOf(_tokenId);
    if(_v != version){
      return (member, 2);
    }

    //"duplicate"
    if(_tokenId != tokenOfOwnerByIndex(member, 0)){
      return (member, 3);
    }

    //"invalid"
    if(!_klistVn[version].isValid(member)){
      return (member, 4);
    }

    return (member, 0);
  }


  /** @notice Returns a base64-encoded json representation of _tokenId
    * @param _tokenId The tokenId to query
    * @return base64-encoded json representation of _tokenId
    */
  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    uint256 v = getVersionByTokenId(_tokenId);
    address member;
    uint8 status;
    (member, status) = getStatus(_tokenId, v);

    return _klistVn[v].getURI(member, status);
  }


  /** @notice KLIST Constructor
    * @param _klistV0Contract Address of the first KLISTvN contract, version 0
    */
  constructor(address _klistV0Contract) ERC721("KLIST", "KLIST") Ownable() {
    klistVnContract = _klistV0Contract;
    _klistVn.push(IKLISTvN(_klistV0Contract));
    version = 0;
  }

}
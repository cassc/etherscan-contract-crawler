// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "hardhat/console.sol";

// // Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
//access control
import "@openzeppelin/contracts/access/AccessControl.sol";



interface PassportInter {
  function sectionOne(uint256 _tokenId) external view returns (bytes memory);
}

interface WlInter {
  function wlSpotsList(uint256 passportId) external view returns (bytes memory);
}

contract TokenURIMaker is AccessControl {
  address public PASSPORT_CONTRACT;
  address public WL_CONTRACT;
  PassportInter PassContract;
  WlInter WlContract;
  string public _batch = "Genesis Passport";
  uint16 public _batchCount = 0;
  mapping(uint16 => string) _batches;
  mapping(uint16 => uint256) _batch_max;

  string private _contractURI;
  //payment split contract
  address payable private _paymentSplit;

  bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

  constructor(address passContract, address wlContract) {
    PASSPORT_CONTRACT = passContract;
    PassContract = PassportInter(PASSPORT_CONTRACT);
    WL_CONTRACT = wlContract;
    WlContract = WlInter(WL_CONTRACT);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(UPDATER_ROLE, msg.sender);
  }

  /**
    @dev settng the batch is a label for the batch the passport fits into. it is bassed on issue number. 
    @param max_mintid is the maximum mint id of this batch 
    @param batch is the name of the batch which appears in the metadata
    @param batch_no is the number of the batch ie. batch 1 is the first batch */
  function setBatch(
    uint256 max_mintid,
    string calldata batch,
    uint16 batch_no
  ) external onlyRole(UPDATER_ROLE) {
    _batches[batch_no] = batch;
    _batch_max[batch_no] = max_mintid;
    if (batch_no > _batchCount) {
      _batchCount = batch_no;
    }
  }

  /**
    @dev gives the max mint number of a batch
    @param batch_no is the number of the batch ie. batch 1 is the first batch
     */
  function batchMax(uint16 batch_no) public view returns (uint256) {
    return _batch_max[batch_no];
  }

  /**
    @dev get info about which batch a passport is in.  
    @param _tokenId the id if the passport. 
     */
  function getBatch(uint256 _tokenId) public view returns (uint16) {
    if (_batchCount > 0) {
      for (uint16 i; i < _batchCount; i++) {
        if (_tokenId < _batch_max[i + 1]) {
          return i + 1;
        }
      }
    }
    return 550;
  }

  

  function maketokenURi(
    uint256 _tokenId,
    uint256 wlSpots,
    uint256 winChances,
    uint256 softClay
  ) external view returns (string memory) {
    bytes memory spots = abi.encodePacked(
      '"},{ "trait_type": "City WL Names", "value": "',
      "None"
    );
    if (wlSpots > 0) {
      spots = WlContract.wlSpotsList(_tokenId);
    }
    uint16 b = getBatch(_tokenId);
    bytes memory dataURI = abi.encodePacked(
      PassContract.sectionOne(_tokenId),
      spots,
      '"},{ "trait_type": "Passport Batch", "value": "',
      _batches[b],
      '"},{ "display_type": "boost_number", "trait_type": "City WL Spots", "value": "',
      Strings.toString(wlSpots),
      '"},{ "display_type": "boost_number", "trait_type": "Win Chances", "value": "',
      Strings.toString(winChances),
      '"},{ "display_type": "boost_number", "trait_type": "Soft Clay", "value": "',
      Strings.toString(softClay),
      '"}]}'
    );
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(dataURI)
        )
      );
  }

  function setContractURI(
    string memory name,
    string memory desc,
    string memory image,
    string memory link,
    string memory royalty
  ) external onlyRole(UPDATER_ROLE) returns (string memory) {
    string memory x = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        name,
        '", "description": "',
        desc,
        '", "image": "',
        image,
        '", "external_link": "',
        link,
        '","seller_fee_basis_points":"',
        royalty, // 100 Indicates a 1% seller fee
        '", "fee_recipient": "',
        _paymentSplit,
        '" }' // Where seller fees will be paid to.}
      )
    );
    _contractURI = string(abi.encodePacked("data:application/json;base64,", x));
    //console.log("contract uri updated");
  }

  function contractURI() external view returns (string memory) {
    return _contractURI;
  }
}

//  struct AccessToken {
//         uint256 id;
//         uint32 winChances;
//         uint32 softClay; // max is 4 billion
//         string name;
//         string rank;
//         string description;
//         string image;
//         string annimation;
//         string cdnImage;
//         string element;
//         string avatarWl;
//         uint256[] whitelistSpots;
//     }

//     function baseSection(AccessToken memory json) internal pure returns (bytes memory) {
//         bytes memory base = abi.encodePacked(
//             '{"name": "',
//             json.name,
//             '", "image": "',
//             json.image,
//             '", "description": "',
//             json.description,
//             '","animation_url": "',
//             json.annimation
//         );

//         return base;
//     }

//     function atributesSection(AccessToken memory json) internal pure returns (bytes memory) {
//         bytes memory atri = abi.encodePacked(
//             '", "attributes": [{ "trait_type": "Avatar WL", "value": "',
//             json.avatarWl,
//             '"},{ "display_type": "boost_number","trait_type": "City WL Spots", "value": "',
//             Strings.toString(json.whitelistSpots.length),
//             '"},{ "display_type": "boost_number","trait_type": "Win Chances", "value": "',
//             Strings.toString(json.winChances),
//             '"},{ "display_type": "boost_number","trait_type": "Soft Clay", "value": "',
//             Strings.toString(json.softClay),
//             '"}]}'
//         );
//         return atri;
//     }

//     function maketokenURi(AccessToken calldata json) external pure returns (string memory) {
//         bytes memory base = baseSection(json);
//         bytes memory atri = atributesSection(json);
//         bytes memory dataURI = abi.encodePacked(base, atri);
//         return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
//     }

//     // function baseSection(string calldata name, string calldata description, string calldata image, string calldata annimation)internal pure returns(bytes memory) {
//     //     bytes memory base = abi.encodePacked('{"name": "',
//     //         name,
//     //         '", "image": "',
//     //         image,
//     //         '", "description": "',
//     //         description,
//     //         '","animation_url": "',
//     //         annimation);

//     //         return base;
//     // }
//     // function atributesSection(string calldata avatarWL, uint wlSpots, uint winChances, uint softClay )internal pure returns(bytes memory){
//     //     bytes memory atri = abi.encodePacked('", "attributes": [{ "trait_type": "Avatar WL", "value": "',
//     //         avatarWL,
//     //         '"},{ "display_type": "boost_number","trait_type": "City WL Spots", "value": "',
//     //          Strings.toString(wlSpots),
//     //         '"},{ "display_type": "boost_number","trait_type": "Win Chances", "value": "',
//     //          Strings.toString(winChances),
//     //         '"},{ "display_type": "boost_number","trait_type": "Soft Clay", "value": "',
//     //          Strings.toString(softClay),
//     //         '"}]}');
//     //         return atri;
//     // }
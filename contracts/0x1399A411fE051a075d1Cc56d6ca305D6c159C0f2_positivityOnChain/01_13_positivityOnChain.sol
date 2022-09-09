// SPDX-License-Identifier: MIT
/*
    ____             _ __  _       _ __        ____        ________          _     
   / __ \____  _____(_) /_(_)   __(_) /___  __/ __ \____  / ____/ /_  ____ _(_)___ 
  / /_/ / __ \/ ___/ / __/ / | / / / __/ / / / / / / __ \/ /   / __ \/ __ `/ / __ \
 / ____/ /_/ (__  ) / /_/ /| |/ / / /_/ /_/ / /_/ / / / / /___/ / / / /_/ / / / / /
/_/    \____/____/_/\__/_/ |___/_/\__/\__, /\____/_/ /_/\____/_/ /_/\__,_/_/_/ /_/ 
                                     /____/                                        
*/

pragma solidity ^0.8.16;
 
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "./libraries/Base64.sol";
 
contract positivityOnChain is ERC721URIStorage, Ownable {
  uint256 private numClaimed = 0;
  
  struct Metadata {
    uint256 orig_score;
    uint256 orig_pos_neg;
    uint256 score;
    uint256 pos_neg;
    string username;
    address minter;
    string gradient;
    bool animated;
    string status;
    Color color;
    string attributesURI;
    string baseURI;
    string SVG;
  }

  struct Color {
    uint256 r1;
    uint256 g1;
    uint256 b1;
    uint256 r2;
    uint256 g2;
    uint256 b2;
  }

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  mapping(uint256 => Metadata) idToData;
  mapping(string => uint256) userToId;
  mapping(string => bool) alreadyMinted;
  mapping(uint256 => string) updatedURI;
  mapping(uint256 => bool) removed;
  
  string baseSvg1 = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 500"><defs><linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" style="stop-color:rgb(';
  string baseSvg2 = ');stop-opacity:1" /><stop offset="100%" style="stop-color:rgb(';
  string baseSvg3 = ');stop-opacity:1" />';
  string animate_Svg4 = '<animate attributeName="x2" values="100%;0%;100%" dur="10s" repeatCount="indefinite" />';
  string baseSvg5 = '</linearGradient></defs><rect width="100%" height="100%" fill="rgb(232,228,214)" rx="25"/><ellipse cx="175" cy="175" rx="150" ry="150" fill="white"/><ellipse cx="175" cy="175" rx="150" ry="150" fill="url(#grad1)" /><text fill="#ffffff" font-size="55" font-family="Trebuchet MS" x="50%" y="175" dominant-baseline="middle" text-anchor="middle">';

  string baseSvg1_2 = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 500"><defs><radialGradient id="grad1" cx="50%" cy="50%" r="50%" fx="50%" fy="50%"><stop offset="0%" style="stop-color:rgb(';
  string baseSvg2_2 = ');stop-opacity:0" /><stop offset="100%" style="stop-color:rgb(';
  string animate_Svg4_2 = '<animate attributeName="r" values="0%;100%;0%" dur="10s" repeatCount="indefinite" />';
  string baseSvg5_2 = '</radialGradient></defs><rect width="100%" height="100%" fill="rgb(232,228,214)" rx="25"/><ellipse cx="175" cy="175" rx="150" ry="150" fill="white"/><ellipse cx="175" cy="175" rx="150" ry="150" fill="url(#grad1)" /><text font-size="55" font-family="Trebuchet MS" x="50%" y="175" dominant-baseline="middle" text-anchor="middle">';
  
  string postScoreSvg = '</text><text font-size="45" font-family="Trebuchet MS" x="50%" y="80%" dominant-baseline="middle" text-anchor="middle">';

  string lockedSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 350 500"><rect width="100%" height="100%" fill="rgb(232,228,214)" rx="25" /><path transform="translate(130, 110)" d="M2.892,56.036h8.959v-1.075V37.117c0-10.205,4.177-19.484,10.898-26.207v-0.009 C29.473,4.177,38.754,0,48.966,0C59.17,0,68.449,4.177,75.173,10.901l0.01,0.009c6.721,6.723,10.898,16.002,10.898,26.207v17.844 v1.075h7.136c1.59,0,2.892,1.302,2.892,2.891v61.062c0,1.589-1.302,2.891-2.892,2.891H2.892c-1.59,0-2.892-1.302-2.892-2.891 V58.927C0,57.338,1.302,56.036,2.892,56.036L2.892,56.036z M26.271,56.036h45.387v-1.075V36.911c0-6.24-2.554-11.917-6.662-16.03 l-0.005,0.004c-4.111-4.114-9.787-6.669-16.025-6.669c-6.241,0-11.917,2.554-16.033,6.665c-4.109,4.113-6.662,9.79-6.662,16.03 v18.051V56.036L26.271,56.036z M49.149,89.448l4.581,21.139l-12.557,0.053l3.685-21.423c-3.431-1.1-5.918-4.315-5.918-8.111 c0-4.701,3.81-8.511,8.513-8.511c4.698,0,8.511,3.81,8.511,8.511C55.964,85.226,53.036,88.663,49.149,89.448L49.149,89.448z"/><text font-size="45" font-family="Trebuchet MS" x="50%" y="80%" dominant-baseline="middle" text-anchor="middle">Token Locked</text></svg>';
  
  address private adminSigner; 

  uint256 private mintPrice = 0.02 ether;
  uint256 private updatePrice = 0.01 ether;

  constructor(address _adminSigner) ERC721 ("PositivityOnChain", "POC") {
    adminSigner = _adminSigner;
  }

  function updateAdminSigner(address _new) public onlyOwner {
    adminSigner = _new;
  }

  function updateSVG(string memory _baseSvg1, string memory _baseSvg2, string memory _baseSvg3, string memory _animate_Svg4, string memory _baseSvg5, string memory _baseSvg1_2, string memory _baseSvg2_2, string memory _animate_Svg4_2, string memory _baseSvg5_2, string memory _postScoreSvg, string memory _lockedSvg) public onlyOwner {
    baseSvg1 = _baseSvg1;
    baseSvg2 = _baseSvg2;
    baseSvg3 = _baseSvg3;
    animate_Svg4 = _animate_Svg4;
    baseSvg5 = _baseSvg5;
    baseSvg1_2 = _baseSvg1_2;
    baseSvg2_2 = _baseSvg2_2;
    animate_Svg4_2 = _animate_Svg4_2;
    baseSvg5_2 = _baseSvg5_2;
    postScoreSvg = _postScoreSvg;
    lockedSvg = _lockedSvg;
  }

  function setColors(uint256 id) internal view returns (Color memory color) {
    uint256 pos_neg = idToData[id].pos_neg;
    uint256 score = idToData[id].score;
    if (pos_neg != 1) {
      if (score >= 500) {
        color.r1 = randRange(205,255,score,id);
        color.g1 = randRange(200,215,score,id);
        color.b1 = randRange(0,30,score,id);
        color.r2 = randRange(188,200,score,id);
        color.g2 = randRange(187,200,score,id);
        color.b2 = randRange(186,200,score,id);
      } else if (score > 200 && score < 500) {
          color.r1 = randRange(150,255,score,id);
          color.g1 = randRange(151,255,score,id);
          color.b1 = randRange(152,255,score,id);
          color.r2 = randRange(149,255,score,id);
          color.g2 = randRange(148,255,score,id);
          color.b2 = randRange(153,255,score,id);
      } else {
          color.r1 = randRange(51,150,score,id);
          color.g1 = randRange(49,149,score,id);
          color.b1 = randRange(52,148,score,id);
          color.r2 = randRange(53,147,score,id);
          color.g2 = randRange(48,146,score,id);
          color.b2 = randRange(57,145,score,id);
      }
    } else {
        if (score >= 200) { 
          color.r1 = randRange(0,5,score,id);
          color.g1 = randRange(1,6,score,id);
          color.b1 = randRange(0,9,score,id);
          color.r2 = randRange(125,150,score,id);
          color.g2 = randRange(0,5,score,id);
          color.b2 = randRange(0,9,score,id);
        } else if (score < 200 && score > 75) {
            color.r1 = randRange(0,50,score,id);
            color.g1 = randRange(1,49,score,id);
            color.b1 = randRange(2,48,score,id);
            color.r2 = randRange(3,47,score,id);
            color.g2 = randRange(4,46,score,id);
            color.b2 = randRange(5,45,score,id);
        } else {
            color.r1 = randRange(50,100,score,id);
            color.g1 = randRange(51,100,score,id);
            color.b1 = randRange(52,100,score,id);
            color.r2 = randRange(53,100,score,id);
            color.g2 = randRange(54,100,score,id);
            color.b2 = randRange(55,100,score,id);
        }
    }
  }
  
  function randRange(uint256 lowerBound, uint256 upperBound, uint256 score, uint256 id) internal view returns (uint256) {
    uint256 randomNumber = uint(keccak256(abi.encodePacked(this, id, score))) % (upperBound - lowerBound + 1);
    return randomNumber += lowerBound;
  }

  function updatePrices(uint256 _mintPrice, uint256 _updatePrice) public onlyOwner {
    mintPrice = _mintPrice;
    updatePrice = _updatePrice;
  }

  function purchase(uint256 score, uint256 pos_neg, string memory username, Coupon memory coupon) public payable {
    //pos_neg: 0 for positive, 1 for negative
    require(!alreadyMinted[username], "Already minted");
    require(msg.value >= mintPrice, "Not enough eth");

    bytes32 digest = keccak256(abi.encode(msg.sender,score,username,pos_neg));
    require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");
    
    mintToken(msg.sender, score, pos_neg, username, msg.sender);
  }
  
  function mintToken(address _to, uint256 score, uint256 pos_neg, string memory username, address _minter) internal {
    uint256 tokenID = numClaimed + 1;
    idToData[tokenID].score = score;
    idToData[tokenID].orig_score = score;
    idToData[tokenID].orig_pos_neg = pos_neg;
    idToData[tokenID].pos_neg = pos_neg;
    idToData[tokenID].username = username;
    idToData[tokenID].minter = _minter;
    userToId[username] = tokenID;
    alreadyMinted[username] = true;
    _safeMint(_to, tokenID);
    numClaimed += 1;
  }

  function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), "Invalid sig");
    return signer == adminSigner;
  }
  
  function airdrop(address _to, uint256 score, uint256 pos_neg, string memory username) public onlyOwner {
    require(!alreadyMinted[username], "Already minted");
    mintToken(_to, score, pos_neg, username, _to);
  }
  
  function updateToken(uint256 id, uint256 score, uint256 pos_neg, string memory username, Coupon memory coupon) public payable {
    require(msg.value >= updatePrice, "Not enough eth");
    require(ownerOf(id) == msg.sender, "You must currently own this token");
    require(idToData[id].minter == msg.sender, "Must use original minter address");

    bytes32 digest = keccak256(abi.encode(msg.sender,score,username,pos_neg));
    require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");

    if (keccak256(abi.encodePacked((idToData[id].username))) != keccak256(abi.encodePacked((username)))) {
      userToId[idToData[id].username] = 0;
      alreadyMinted[idToData[id].username] = false;
      userToId[username] = id;
      idToData[id].username = username;
      alreadyMinted[username] = true;
    }

    idToData[id].score = score;
    idToData[id].pos_neg = pos_neg;
  }

  function toggleRemove(uint256 id) public onlyOwner {
    removed[id] = !removed[id];
  }

  function adminUpdate(uint256 id, uint256 score, uint256 pos_neg, string memory username, address _minter, uint256 orig_score, uint256 orig_pos_neg) public onlyOwner {
    idToData[id].score = score;
    idToData[id].orig_score = orig_score;
    idToData[id].orig_pos_neg = orig_pos_neg;
    idToData[id].pos_neg = pos_neg;
    idToData[id].minter = _minter;

    if (keccak256(abi.encodePacked((idToData[id].username))) != keccak256(abi.encodePacked((username)))) {
      userToId[idToData[id].username] = 0;
      alreadyMinted[idToData[id].username] = false;
      userToId[username] = id;
      idToData[id].username = username;
      alreadyMinted[username] = true;
    }
  }
  
  function removeUsername(string memory username) public onlyOwner {
    alreadyMinted[username] = false;
    userToId[username] = 0;
  }

  function checkUsername(string memory username) public view returns (bool) {
    return alreadyMinted[username];
  }

  function usernameToScore(string memory username) public view returns (string memory readable_score, uint256 score, uint256 pos_neg, uint256 tokenID) {
    require(userToId[username] > 0, "Username does not have a score");
    score = idToData[userToId[username]].score;
    pos_neg = idToData[userToId[username]].pos_neg;
    tokenID = userToId[username];
    if (pos_neg == 1) {
      readable_score = string.concat('-',Strings.toString(idToData[userToId[username]].score));
    } else {
      readable_score = Strings.toString(idToData[userToId[username]].score);
    }
  }

  function viewMetadata(uint256 id) public view returns (string memory username, string memory score, string memory original_score, address minter, string memory gradient, bool animated, string memory status, Color memory color) {
    require(id < numClaimed + 1 && id != 0, "Token does not exist");
    if (!removed[id]) {
      Metadata memory attributes = getAttributes(id);
      score = Strings.toString(idToData[id].score);
      original_score = Strings.toString(idToData[id].orig_score);
      if (idToData[id].pos_neg == 1) {
        score = string.concat('-',score);
      }
      if (idToData[id].orig_pos_neg == 1) {
        original_score = string.concat('-',original_score);
      }
      username = idToData[id].username;
      minter = idToData[id].minter;
      gradient = attributes.gradient;
      animated = attributes.animated;
      status = attributes.status;
      color = attributes.color;
    } else {
      username = "Token Locked";
    }
  }

  function viewSVG(uint256 id) public view returns (string memory) {
    require(id < numClaimed + 1 && id != 0, "Token does not exist");
    if (!removed[id]) {
      return getAttributes(id).SVG;
    } else {
      return "Token Locked";
    }
  }

  function getAttributes(uint256 id) internal view returns (Metadata memory attributes) {
    uint256 score = idToData[id].score;
    uint256 pos_neg = idToData[id].pos_neg;
    string memory sign = 'positive';
    attributes.gradient = 'linear';
    attributes.status = 'Neutral';
    string memory animate = 'false';
    string memory orig_str_score = Strings.toString(idToData[id].orig_score);
    if (idToData[id].orig_pos_neg == 1) {
      orig_str_score = string.concat('-',orig_str_score);
    }

    string memory str_score = Strings.toString(idToData[id].score);

    if (pos_neg == 0) {
      if (score > 25 && score <= 75) {
        attributes.status = 'Friendly';
      } else if (score > 75 && score <= 115) {
          attributes.status = 'Supportive';
      } else if (score > 115 && score <= 175) {
          attributes.status = 'Kindhearted';
      } else if (score > 175 && score <= 300) {
          attributes.status = 'Compassionate';
      } else if (score > 300 && score <= 500) {
          attributes.status = 'Altruistic';
      } else if (score > 500) {
          attributes.status = 'Loving';
      }
    } else {
      str_score = string.concat('-',str_score);
      sign = 'negative';
      if (score > 25 && score <= 75) {
        attributes.status = 'Stingy';
      } else if (score > 75 && score <= 115) {
          attributes.status = 'Heinous';
      } else if (score > 115 && score <= 175) {
          attributes.status = 'Spiteful';
      } else if (score > 175 && score <= 300) {
          attributes.status = 'Offensive';
      } else if (score > 300 && score <= 500) {
          attributes.status = 'Resentful';
      } else if (score > 500) {
          attributes.status = 'Evil';
      }
    }

    attributes.color = setColors(id);
    
    string memory color1 = string.concat(Strings.toString(attributes.color.r1),',',Strings.toString(attributes.color.g1),',',Strings.toString(attributes.color.b1));
    string memory color2 = string.concat(Strings.toString(attributes.color.r2),',',Strings.toString(attributes.color.g2),',',Strings.toString(attributes.color.b2));
  
    attributes.baseURI = string.concat(baseSvg1, color1, baseSvg2, color2, baseSvg3, baseSvg5);
  
    if (randRange(0,100,score,id) > 85) {
      attributes.baseURI = string.concat(baseSvg1_2, color1, baseSvg2_2, color2, baseSvg3, baseSvg5_2);
      attributes.gradient = 'radial';
      if (randRange(1,101,score,id) > 99) {
        attributes.baseURI = string.concat(baseSvg1_2, color1, baseSvg2_2, color2, baseSvg3, animate_Svg4_2, baseSvg5_2);
        attributes.animated = true;
        animate = 'true';
      }
    } else {
        if (randRange(2,100,score,id) > 97) {
          attributes.baseURI = string.concat(baseSvg1, color1, baseSvg2, color2, baseSvg3, animate_Svg4, baseSvg5);
          attributes.animated = true;
          animate = 'true';
        }
    }

    attributes.SVG = string(abi.encodePacked(attributes.baseURI, str_score, postScoreSvg, attributes.status, "</text></svg>"));

    attributes.attributesURI = string.concat(',"attributes":[{"trait_type":"gradient","value":"',attributes.gradient,'"},{"trait_type":"r1","value":"',Strings.toString(attributes.color.r1),'"},{"trait_type":"g1","value":"',
    Strings.toString(attributes.color.g1),'"},{"trait_type":"b1","value":"',Strings.toString(attributes.color.b1),'"},{"trait_type":"r2","value":"',Strings.toString(attributes.color.r2),'"},{"trait_type":"g2","value":"',
    Strings.toString(attributes.color.g2),'"},{"trait_type":"b2","value":"',Strings.toString(attributes.color.b2),'"},{"trait_type":"status","value":"',attributes.status,'"},{"trait_type":"animated","value":"',animate,'"},{"trait_type":"sign","value":"',sign,'"},{"trait_type":"score","value":"',str_score,'"},{"trait_type":"original score","value":"',orig_str_score,'"}]');
    return attributes;
  }
  
  function tokenURI(uint256 id) public view override returns (string memory) {
    require(id < numClaimed + 1 && id != 0, "Token does not exist");
    if (!removed[id]) {
      string memory user = idToData[id].username;

      Metadata memory attributes = getAttributes(id);
    
      string memory json = Base64.encode(
          bytes(
              string(
                  abi.encodePacked(
                      '{"name": "@',user,'", "description": "Positivity Score for @',user,'", "image": "data:image/svg+xml;base64,',
                      Base64.encode(bytes(attributes.SVG)),'"',attributes.attributesURI,'}'
                  )
              )
          )
      );
    
      return string(abi.encodePacked("data:application/json;base64,", json));
    }
    else {
      string memory json = Base64.encode(
          bytes(
              string(
                  abi.encodePacked(
                      '{"name": "Token Locked", "description": "Unfortunately, this token has been manually locked. Most likely due to a user maliciously trying to create a false score.", "image": "data:image/svg+xml;base64,',
                      Base64.encode(bytes(lockedSvg)),'"}'
                  )
              )
          )
      );
      return string(abi.encodePacked("data:application/json;base64,", json));
    }
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function totalSupply() public view returns(uint256) {
    return numClaimed;
  }
}
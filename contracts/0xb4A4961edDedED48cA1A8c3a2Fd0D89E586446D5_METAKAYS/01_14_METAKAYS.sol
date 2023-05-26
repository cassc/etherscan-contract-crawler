// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "base64-sol/base64.sol";
import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IFeatures1 {
  function readMisc(uint256 _id) external view returns (string memory);
}

interface IFeatures2{
  function readMouth(uint256 _id) external view returns (string memory);
}

interface IFeatures3 {
  function readHair(uint256 _id) external view returns (string memory);
}

contract METAKAYS is Ownable, ERC721 {

    event Kustomized(uint256 _itemID);

    struct Features {
      uint8 backgroundColor;
      uint8 bodyColor;
      uint8 skinColor;
      uint8 hairColor;
      uint8 mouthColor;
      uint8 hairStyle;
      uint8 mouthStyle;
      uint8 miscStyle1;
      uint8 miscStyle1Color;
      uint8 miscStyle2;
      uint8 miscStyle2Color;
      uint8 eyesColor;
      string customText;
    }

    IFeatures1 features1;
    IFeatures2 features2;
    IFeatures3 features3;

    uint256 public constant AMOUNT_FOR_METAKOUNCIL = 280;
    uint256 public constant price = 0.08888 ether;

    bytes32 public _merkleRoot;
    bool public _saleIsActive = false;

    mapping(uint256 => Features) public features;
    mapping (uint256 => string) public svgBackgroundColor;
    mapping (uint256 => bool) public finality;
    mapping (address => bool) public whitelistClaimed;

    constructor()
    ERC721("METAKAYS", "K", 5, 8888) {
      svgBackgroundColor[0] = '#2dd055"/>';
      svgBackgroundColor[1] = '#09a137"/>';
      svgBackgroundColor[2] = '#065535"/>';
      svgBackgroundColor[3] = '#88b04b"/>';
      svgBackgroundColor[4] = '#00ffff"/>';
      svgBackgroundColor[5] = '#5acef3"/>';
      svgBackgroundColor[6] = '#0050ff"/>';
      svgBackgroundColor[7] = '#4559cc"/>';
      svgBackgroundColor[8] = '#34568b"/>';
      svgBackgroundColor[9] = '#8a2be2"/>';
      svgBackgroundColor[10] = '#6b5b95"/>';
      svgBackgroundColor[11] = '#b565a7"/>';
      svgBackgroundColor[12] = '#ff80ed"/>';
      svgBackgroundColor[13] = '#ffc0cb"/>';
      svgBackgroundColor[14] = '#faceac"/>';
      svgBackgroundColor[15] = '#dfff00"/>';
      svgBackgroundColor[16] = '#fff300"/>';
      svgBackgroundColor[17] = '#ffd700"/>';
      svgBackgroundColor[18] = '#ffa500"/>';
      svgBackgroundColor[19] = '#896258"/>';
      svgBackgroundColor[20] = '#945610"/>';
      svgBackgroundColor[21] = '#9b2335"/>';
      svgBackgroundColor[22] = '#b14044"/>';
      svgBackgroundColor[23] = '#ff0000"/>';
      svgBackgroundColor[24] = '#df1b49"/>';
      svgBackgroundColor[25] = '#f71863"/>';
      svgBackgroundColor[26] = '#928e8e"/>';
      svgBackgroundColor[27] = '#ffffff"/>';
      svgBackgroundColor[28] = '#000000"/>';
    }

    function setSaleIsActive(bool saleIsActive) external onlyOwner {
      _saleIsActive = saleIsActive;
    }

    function setPresaleMerkleRoot(bytes32 root) external onlyOwner {
      _merkleRoot = root;
    }

    //RENOUNCE/TRANSFER @ 616.
    function setFeaturesAddress(address[] memory addr) external onlyOwner{
      features1= IFeatures1(addr[0]);
      features2 = IFeatures2(addr[1]);
      features3 = IFeatures3(addr[2]);
    }

    function kustomize(uint256 _itemID, uint8[] memory selection_, string memory _customText) public {
      require(msg.sender == ownerOf(_itemID), "YOU ARE NOT THE OWNER!");
      require(customShirtCheck(_customText) == true, "PLEASE ONLY USE 1-8 CAPITAL LETTERS!");
      require(finality[_itemID] == false, "FINALITY!");
      require((selection_[0] < 29) && (selection_[1] < 29) && (selection_[2] < 29) && (selection_[3] < 29) &&
      (selection_[4] < 29) && (selection_[5] < 29) && (selection_[6] < 29) && (selection_[7] < 29) &&
      (selection_[8] < 29) && (selection_[9] < 29) && (selection_[10] < 29) && (selection_[11] < 29), "NO SUCH FEATURE!");
      Features storage feature = features[_itemID];
      feature.backgroundColor = selection_[0];
      feature.bodyColor = selection_[1];
      feature.skinColor = selection_[2];
      feature.hairColor = selection_[3];
      feature.mouthColor = selection_[4];
      feature.hairStyle = selection_[5];
      feature.mouthStyle = selection_[6];
      feature.miscStyle1 = selection_[7];
      feature.miscStyle1Color = selection_[8];
      feature.miscStyle2 = selection_[9];
      feature.miscStyle2Color = selection_[10];
      feature.eyesColor = selection_[11];
      feature.customText = _customText;
      emit Kustomized(_itemID);
    }

    function setFinality(uint256 _itemID) public {
      require(msg.sender == ownerOf(_itemID), "YOU ARE NOT THE OWNER!");
      finality[_itemID] = true;
    }

    function publicClaim(uint256 quantity) external payable {
      require(_saleIsActive,"SALE IS NOT ACTIVE!");
      require(totalSupply() + quantity <= collectionSize, "MAX SUPPLY!");
      require(quantity * price <= msg.value, "INCORRECT AMOUNT SENT!");
      _safeMint(msg.sender, quantity);
    }

    function whitelistClaim(uint256 _amount, bytes32[] calldata _merkleProof) external payable {
      require(!whitelistClaimed[msg.sender], "ADDRESS HAS ALREADY CLAIMED!");
      require(totalSupply() + _amount <= collectionSize, "MAX SUPPLY!");
      require(_amount * price <= msg.value, "INCORRECT AMOUNT SENT!");
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf),  "INVALID PROOF!");
      whitelistClaimed[msg.sender] = true;
      _safeMint(msg.sender, _amount);
    }

    function devMint(uint256 quantity) external onlyOwner {
      require(totalSupply() + quantity <= AMOUNT_FOR_METAKOUNCIL, "TOO MANY ALREADY MINTED!");
      require(quantity % maxBatchSize == 0, "CAN ONLY MINT A MULTIPLE OF MAXBATCHSIZE!");
      uint256 numChunks = quantity / maxBatchSize;
      for (uint256 i = 0; i < numChunks; i++) {
        _safeMint(msg.sender, maxBatchSize);
      }
    }

    function withdrawMoney() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW FAILED!");
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
      Features memory feature = features[_tokenId];
      string memory tokenIdString = toString(_tokenId);
      string memory _first = concatenate(
        '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="888.000000pt" height="888.000000pt" viewBox="0 0 888.000000 888.000000" preserveAspectRatio="xMidYMid meet"> <g transform="translate(0.000000,888.000000) scale(0.100000,-0.100000)"> <path d="M0 4440 l0 -4440 4440 0 4440 0 0 4440 0 4440 -4440 0 -4440 0 0 -4440z" fill="',
        svgBackgroundColor[feature.backgroundColor], '<path d="M3530 3270 l0 -130 -395 0 -395 0 0 -130 0 -130 -515 0 -515 0 0 -130 0 -130 -130 0 -130 0 0 -1310 0 -1310 130 0 130 0 0 1310 0 1310 515 0 515 0 0 130 0 130 395 0 395 0 0 130 0 130 910 0 910 0 0 -130 0 -130 395 0 395 0 0 -130 0 -130 515 0 515 0 0 -1310 0 -1310 130 0 130 0 0 1310 0 1310 -130 0 -130 0 0 130 0 130 -515 0 -515 0 0 130 0 130 -395 0 -395 0 0 130 0 130 -910 0 -910 0 0 -130z M2610 660 l0 -660 130 0 130 0 0 660 0 660 -130 0 -130 0 0 -660z M6010 660 l0 -660 130 0 130 0 0 660 0 660 -130 0 -130 0 0 -660z"/> <path d="M3530 3010 l0 -130 -395 0 -395 0 0 -130 0 -130 -515 0 -515 0 0 -1310 0 -1310 450 0 450 0 0 660 0 660 130 0 130 0 0 -660 0 -660 1570 0 1570 0 0 660 0 660 130 0 130 0 0 -660 0 -660 450 0 450 0 0 1310 0 1310 -515 0 -515 0 0 130 0 130 -395 0 -395 0 0 130 0 130 -910 0 -910 0 0 -130z" fill="',
        svgBackgroundColor[feature.bodyColor],'<g transform="translate(0.000000,888.000000) scale(0.100000,-0.100000)"><text x="44488" y="-8800" font-size="4800px" font-family="impact" font-weight="bold" dominant-baseline="middle" text-anchor="middle">',
        feature.customText,
        '</text></g><g transform="translate(0.000000,888.000000) scale(0.100000,-0.100000)"><text x="71188" y="-14488" font-size="2888px" font-family="impact" font-weight="bold" dominant-baseline="center" text-anchor="end">', tokenIdString,
        '</text></g><path d="M3130 5540 l0 -1600 100 0 100 0 0 -185 0 -185 195 0 195 0 0 -85 0 -85 130 0 130 0 0 215 0 215 -195 0 -195 0 0 185 0 185 -100 0 -100 0 0 1340 0 1340 1050 0 1050 0 0 -1340 0 -1340 -100 0 -100 0 0 -185 0 -185 -195 0 -195 0 0 -215 0 -215 130 0 130 0 0 85 0 85 195 0 195 0 0 185 0 185 100 0 100 0 0 1600 0 1600 -1310 0 -1310 0 0 -1600z"/> <path d="M3390 5540 l0 -1340 100 0 100 0 0 -185 0 -185 195 0 195 0 0 -215 0 -215 460 0 460 0 0 215 0 215 195 0 195 0 0 185 0 185 100 0 100 0 0 1340 0 1340 -1050 0 -1050 0 0 -1340z" fill="'
      );
      string memory _last = concatenate(svgBackgroundColor[feature.skinColor], finality[_tokenId] == false ? '<path d="M3750 5770 l0 -120 -120 0 -120 0 0 -120 0 -120 120 0 120 0 0 -240 0 -240 120 0 120 0 0 240 0 240 120 0 120 0 0 120 0 120 -120 0 -120 0 0 120 0 120 -120 0 -120 0 0 -120z M4890 5770 l0 -120 -120 0 -120 0 0 -120 0 -120 120 0 120 0 0 -240 0 -240 120 0 120 0 0 240 0 240 120 0 120 0 0 120 0 120 -120 0 -120 0 0 120 0 120 -120 0 -120 0 0 -120z" fill="' : '<path d="M3730 5790 l0 -120 -120 0 -120 0 0 -140 0 -140 120 0 120 0 0 -240 0 -240 140 0 140 0 0 240 0 240 120 0 120 0 0 140 0 140 -120 0 -120 0 0 120 0 120 -140 0 -140 0 0 -120z m250 -30 l0 -120 120 0 120 0 0 -110 0 -110 -120 0 -120 0 0 -240 0 -240 -110 0 -110 0 0 240 0 240 -120 0 -120 0 0 110 0 110 120 0 120 0 0 120 0 120 110 0 110 0 0 -120z M3790 5730 l0 -120 -120 0 -120 0 0 -80 0 -80 120 0 120 0 0 -240 0 -240 80 0 80 0 0 240 0 240 120 0 120 0 0 80 0 80 -120 0 -120 0 0 120 0 120 -80 0 -80 0 0 -120z m130 -30 l0 -120 120 0 120 0 0 -50 0 -50 -120 0 -120 0 0 -240 0 -240 -50 0 -50 0 0 240 0 240 -120 0 -120 0 0 50 0 50 120 0 120 0 0 120 0 120 50 0 50 0 0 -120z M3850 5670 l0 -120 -120 0 c-113 0 -120 -1 -120 -20 0 -19 7 -20 120 -20 l120 0 0 -240 c0 -233 1 -240 20 -240 19 0 20 7 20 240 l0 240 120 0 c113 0 120 1 120 20 0 19 -7 20 -120 20 l-120 0 0 120 c0 113 -1 120 -20 120 -19 0 -20 -7 -20 -120z M4870 5790 l0 -120 -120 0 -120 0 0 -140 0 -140 120 0 120 0 0 -240 0 -240 140 0 140 0 0 240 0 240 120 0 120 0 0 140 0 140 -120 0 -120 0 0 120 0 120 -140 0 -140 0 0 -120z m250 -30 l0 -120 120 0 120 0 0 -110 0 -110 -120 0 -120 0 0 -240 0 -240 -110 0 -110 0 0 240 0 240 -120 0 -120 0 0 110 0 110 120 0 120 0 0 120 0 120 110 0 110 0 0 -120z M4930 5730 l0 -120 -120 0 -120 0 0 -80 0 -80 120 0 120 0 0 -240 0 -240 80 0 80 0 0 240 0 240 120 0 120 0 0 80 0 80 -120 0 -120 0 0 120 0 120 -80 0 -80 0 0 -120z m130 -30 l0 -120 120 0 120 0 0 -50 0 -50 -120 0 -120 0 0 -240 0 -240 -50 0 -50 0 0 240 0 240 -120 0 -120 0 0 50 0 50 120 0 120 0 0 120 0 120 50 0 50 0 0 -120z M4990 5670 l0 -120 -120 0 c-113 0 -120 -1 -120 -20 0 -19 7 -20 120 -20 l120 0 0 -240 c0 -233 1 -240 20 -240 19 0 20 7 20 240 l0 240 120 0 c113 0 120 1 120 20 0 19 -7 20 -120 20 l-120 0 0 120 c0 113 -1 120 -20 120 -19 0 -20 -7 -20 -120z" fill="',
      svgBackgroundColor[feature.eyesColor], features2.readMouth(feature.mouthStyle), svgBackgroundColor[feature.mouthColor], features1.readMisc(feature.miscStyle1), svgBackgroundColor[feature.miscStyle1Color],  features1.readMisc(feature.miscStyle2),svgBackgroundColor[feature.miscStyle2Color]);
      string memory imageURI = string(abi.encodePacked("data:image/svg+xml;base64, ", Base64.encode(bytes(string(abi.encodePacked(_first, _last,features3.readHair(feature.hairStyle), svgBackgroundColor[feature.hairColor],'</g></svg>'))))));
      string memory finality_ = finality[_tokenId] == false ? 'false' : 'true';

      return string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                "METAKAYS-", tokenIdString,
                '", "attributes":[{"trait_type" : "Finality", "value" : "', finality_ ,'"}], "image":"',imageURI,'"}'
              )
            )
          )
        )
      );
    }

    function concatenate(string memory _one, string memory _two, string memory _three, string memory _four, string memory _five, string memory _six, string memory _seven, string memory _eight, string memory _nine) internal pure returns (string memory) {
      return string(abi.encodePacked(_one, _two, _three, _four, _five, _six, _seven, _eight, _nine));
    }

    function customShirtCheck(string memory svg) internal pure returns (bool) {
      bytes memory b = bytes(svg);
      if (b.length > 8) return false;
      for (uint256 i=0; i<b.length; i++){
        bytes1 char = b[i];
        if (!(char > 0x40 && char < 0x5B)) {
          return false;
        }
      }
      return true;
    }

    function toString(uint256 value) internal pure returns (string memory) {
      if (value == 0) {
        return "0";
      }
      uint256 temp = value;
      uint256 digits;
      while (temp != 0) {
        digits++;
        temp /= 10;
      }
      bytes memory buffer = new bytes(digits);
      while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
      }
      return string(buffer);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
      return ownershipOf(tokenId);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner {
      _setOwnersExplicit(quantity);
    }

}
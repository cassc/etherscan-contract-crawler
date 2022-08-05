// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
pragma abicoder v2;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "base64-sol/base64.sol";
import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MoonLakeByDovetail is ERC721A, ERC2981, Ownable {
  using Strings for *;
  
  struct Token {
    string name;
    string externalUrl;
    string description;
    string imageFilename;
  }
  
  mapping(uint => Token) public tokenIdToToken;
  
  struct ContractInfo {
    string externalURL;
    string imageURI;
  }
  
  ContractInfo public contractInfo;
  
  address constant doveAddress = 0x5FD2E3ba05C862E62a34B9F63c45C0DF622Ac112;
  address constant middleAddress = 0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
  
  uint96 constant royaltyPct = 15;
  uint constant middleMarchSharePct = 20;
  
  string public constant contractDescription = "moonLake by dovetail is a series of 10 unique non-fungible tokens on the Ethereum blockchain, each containing a link to a work of art from the public domain in the animated variant of the PNG file format. Each of the 10 animations are 2 frames. Both frames show the original work of art as it has been scanned and digitally imaged. The .png files are intentionally corrupted to distort the color values and composition data in the first frame. The ongoing entropy of the animated PNG file format renders the work aleatoric and unpredictable. When viewed, each moonLake image continuously evades display. Every instance of the image starts an entropic animation approaching distortion and corruption. The entropic effect is two-fold: many browsers do not support the animated PNG file format, and the support will continuously degrade over time as more common file formats are given precedence. This will alter how the moonLake series is viewed, and eventually the image may not be visible or accessible at all. Every moonLake edition's image is hosted on IPFS, the inter-planetary file system. While the viewing of a moonLake image is contingent on accessing IPFS, moonLake's on-chain token will permanently store the conceptual corpus of moonLake. In a gallery setting, moonLake should have its frame data isolated and presented as a diptych, each frame given equal consideration. Consult the artist's studio.";
  
  string public constant tokenImageBaseURI = "ipfs://QmNut1z8BdeRXkxKHTFQT9x3GRzaRJP99j61cYUYTq2Q6h/";
  
  constructor() ERC721A("moonLake by dovetail", "mLdt") {
    _setDefaultRoyalty(doveAddress, royaltyPct * 100);
    
    mint(
      "mL#0",
      "",
      "moonlight.png",
      "Moonlight, Strandgade 30"
    );
    
    mint(
      "mL#1",
      "",
      "cattle.png",
      "Cattle at Rest on a Hillside in the Alps"
    );
    
    mint(
      "mL#2",
      "",
      "summer.png",
      "summer.jpg"
    );
    
    mint(
      "mL#3",
      "",
      "cottage.png",
      "Fisherman's Cottage"
    );
    
    mint(
      "mL#4",
      "",
      "disciples.png",
      "The Two Disciples at the Tomb"
    );
    
    mint(
      "mL#5",
      "",
      "bullfight.png",
      "After the Bullfight"
    );
    
    mint(
      "mL#6",
      "",
      "fuji.png",
      "Moonlight on Mt. Fuji"
    );
    
    mint(
      "mL#7",
      "",
      "still.png",
      "Still Life with Game Fowl"
    );
    
    mint(
      "mL#8",
      "",
      "mondrian.png",
      "Composition (No. 1) Gray-Red"
    );
    
    mint(
      "mL#9",
      "",
      "firedon.png",
      "Fired On"
    );
  }
  
  function mint(
    string memory name,
    string memory externalURL,
    string memory imageFilename,
    string memory description
  ) private {
    require(bytes(name).length > 0);
    require(bytes(imageFilename).length > 0);
    
    Token storage nextToken = tokenIdToToken[_nextTokenId()];
    
    nextToken.name = name;
    nextToken.description = description;
    nextToken.imageFilename = imageFilename;
    nextToken.externalUrl = externalURL;
    
    _mint(msg.sender, 1);
  }
  
  function contractURI() public view returns (string memory) {
    return
        string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"name":"', name(), '",'
                            '"seller_fee_basis_points":', (royaltyPct * 100).toString(), ','
                            '"fee_recipient":"', doveAddress.toHexString(), '",'
                            '"description":"', contractDescription, '",'
                            '"image":"', contractInfo.imageURI,'",'
                            '"external_link":"', contractInfo.externalURL, '"'
                            '}'
                        )
                    )
                )
            )
        );
  }
  
  function tokenURI(uint tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "Token does not exist");

      return constructTokenURI(tokenId);
  }
  
  function constructTokenURI(uint tokenId) private view returns (string memory) {
    Token memory token = tokenIdToToken[tokenId];
    
    string memory imageURI = string.concat(
      tokenImageBaseURI,
      token.imageFilename
    );
    
    string memory tokenDescription = string.concat(
      token.description,
      " - ",
      contractDescription
    );
    
    return
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"name":"', token.name, '",'
                            '"description":"', tokenDescription, '",'
                            '"image":"', imageURI,'",'
                            '"external_url":"', token.externalUrl, '"',
                            '}'
                        )
                    )
                )
            )
        );
  }
  
  function setContractInfo(
    string calldata imageURI,
    string calldata externalURL
  ) public onlyOwner {
    contractInfo.imageURI = imageURI;
    contractInfo.externalURL = externalURL;
  }
  
  function setTokenExternalURI(
    uint tokenId,
    string calldata externalURL
  ) public onlyOwner {
    Token storage token = tokenIdToToken[tokenId];
    token.externalUrl = externalURL;
  }
  
  function withdraw() external {
      uint balance = address(this).balance;
      require(balance > 0, "Nothing to withdraw");
      
      uint middleShare = (balance * middleMarchSharePct) / 100;
      uint doveShare = balance - middleShare;
      
      Address.sendValue(payable(middleAddress), middleShare);
      Address.sendValue(payable(doveAddress), doveShare);
  }
  
  fallback (bytes calldata _inputText) external payable returns (bytes memory _output) {}
  
  receive () external payable {}
  
  function supportsInterface(
      bytes4 interfaceId
  ) public view virtual override(ERC721A, ERC2981) returns (bool) {
      return 
          ERC721A.supportsInterface(interfaceId) || 
          ERC2981.supportsInterface(interfaceId);
  }

}
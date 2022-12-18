// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}
/* ///// */


contract Harmonies is ERC721Enumerable, Ownable, ReentrancyGuard { 

  using SafeMath for uint256;
  uint256 public cost = 0.15 ether; 
  uint256 public HarmoniesOnSell = 5;
  uint256 public MAX = 251; 
  uint256 public token_id = 1;
  bool public freeze = false;


  uint256[] img = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22];
  string dataURL = "https://arweave.net/5zgxA9cz19qu0wdyKL8CVKHvvZE1A2tFNjGFWv3PLtU/";
  string baseHTML = '<html><meta name="viewport" content="width=device-width, initial-scale=1"><head><link href="';
  string loadStyles = "https://arweave.net/5zgxA9cz19qu0wdyKL8CVKHvvZE1A2tFNjGFWv3PLtU/stt.css";
  string preloader = string.concat('" rel="stylesheet"></head><body><img src="', dataURL, 'preloader.jpg">');
  string renderScript = '<div class="cen"><canvas id="canvas" width="1800px" height="2500px"></canvas></div><script>const ctx=document.getElementById("canvas").getContext("2d");let im=new Image;function p(){ctx.drawImage(im,canvas.width/2.2,canvas.height/2.2)}im.src=document.images[0].src,im.onload=()=>{p()},p();let d=[],n=0,dr=[];function draw(){ctx.clearRect(0, 0, canvas.width, canvas.height); n++,n>d.length-1&&dr.forEach((e=>{ctx.drawImage(e,0,0)}))}for(let e=0;e<document.images.length;e++)e>0&&d.push(document.images[e].src);d.forEach((e=>{let n=new Image;n.src=e,n.onload=()=>{draw()},dr.push(n)}));</script>';
  string imgSart ='<img src="';


  constructor() ERC721 ("Eternal Harmony", "Harmonies") {
   
  }

    function Sale(uint numberOfTokens) public payable nonReentrant{
        require(numberOfTokens <= HarmoniesOnSell, "Purchase would exceed max supply");
        require(totalSupply().add(numberOfTokens) < MAX, "Purchase would exceed max supply of Harmonies");
        require(msg.value >= cost * numberOfTokens, "Ether value sent is not correct");
        for(uint i = 0; i < numberOfTokens; i++) {
                _safeMint(msg.sender, token_id);
                token_id++;
        }
    }


    function teamMint( address  user, uint numberOfTokens) public payable nonReentrant onlyOwner{
      require(totalSupply().add(numberOfTokens) < MAX, "Purchase would exceed max supply of Harmonies");
        for(uint i = 0; i < numberOfTokens; i++) {
                _safeMint(user, token_id);
                token_id++;
        }
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

     function setSource(string memory _url) public onlyOwner {
      require(!freeze, "data is frozen");
        dataURL  = _url;
    }

     function setStyles(string memory _url) public onlyOwner {
      require(!freeze, "data is frozen");
        loadStyles  = _url;
    }

    function setFreeze() public onlyOwner {
      freeze = true;
    }


    function StopSale() public onlyOwner {
        MAX = token_id;
    }

    

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    

    function getRandom(uint256 _time) internal view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(Strings.toString(_time))));
        rand = rand % img.length;
        return  rand;
    }

 
    address t1 = 0x91C744fa5D176e8c8c2243a952b75De90A5186bc; 

    address t2 = 0xE0D80FC054BC859b74546477344b152941902CB6; 

    address t3 = 0xae87B3506C1F48259705BA64DcB662Ed047575Bb; 
     
 
    function withdraw() public payable nonReentrant onlyOwner {

        uint256 _u1 = address(this).balance * 34/100;
        uint256 _u2 = address(this).balance * 33/100;
        uint256 _u3 = address(this).balance * 33/100;

          require(payable(t1).send(_u1));
          require(payable(t2).send(_u2));
          require(payable(t3).send(_u3));
    }
 



    function tokenURI(uint256 _tokenId) override public view returns(string memory ) {

    require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
      );

      uint256 randomData = (block.timestamp  / 3 days); 

      uint256 iter =0;

      string memory finalHTML;
      string memory imgEnd;

      for (uint256 i = 1; i < 7; i++) {  
        
        if(i<2){
          imgEnd = '.JPG">';
        }else{
        imgEnd = '.PNG">';
        }
        finalHTML = string.concat(finalHTML, imgSart, dataURL, Strings.toString(img[getRandom(((randomData+i)*_tokenId))]+ iter ), imgEnd); 
        iter = iter+22;
      }


     finalHTML = string(abi.encodePacked(baseHTML, loadStyles, preloader, finalHTML,  renderScript,  '</body></html>'));
        
    string memory name = string.concat('Eternal Harmony #', Strings.toString(_tokenId));

      string memory json = Base64.encode(
          bytes(
              string(
                  abi.encodePacked(
                      '{"name": "',
                      name,
                      '", "description": "The painting you see will exist for only three days, and then the algorithm will create a new one. It is like a short and unique meeting, so take your time to enjoy it.", "image": "',dataURL, '5.gif", "animation_url": "data:text/html;base64,',
                      Base64.encode(bytes(finalHTML)),

                      '"}'
                  )
              )
          )
      );
    
      string memory tokenUri = string(abi.encodePacked("data:application/json;base64,", json));
  
      return  tokenUri;
      }
  
}
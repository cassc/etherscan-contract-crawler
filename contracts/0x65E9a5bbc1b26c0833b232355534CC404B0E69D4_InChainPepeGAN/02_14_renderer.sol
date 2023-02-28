// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./GAN.sol";

contract Renderer is GenerativeAdversarialNetwork{
  function addTrait(string memory traitName, string memory value) internal pure returns (string memory){
      return string.concat('{"display_type":"number","trait_type":"', traitName, '","value":', value, '}');
  }
  function getProperty(Seeds memory seeds) public pure returns (string memory property){
      property = string.concat(
          addTrait("Seed 1", Strings.toString(seeds.seed1)),",",
          addTrait("Seed 2", Strings.toString(seeds.seed2)),",",
          addTrait("Seed 3", Strings.toString(seeds.seed3)),",",
          addTrait("Delay(ms)", Strings.toString(seeds.delay))
      );
  }
  // Get GIF starts from here.
  function getLine(uint8 position) internal pure returns (bytes memory output){
      output = abi.encodePacked(hex"0680", position, position+1, position+2, position+3, position+4);
  }
  function getColorTable(uint8[75] memory image, uint256 position) internal pure returns (bytes memory output){
      output = abi.encodePacked(image[position],
                                image[position+1],
                                image[position+2],
                                image[position+3],
                                image[position+4],
                                image[position+5],
                                image[position+6],
                                image[position+7],
                                image[position+8],
                                image[position+9],
                                image[position+10],
                                image[position+11]
                               );
  }
  function makeAnimatedGIF(uint8[75] memory image, uint8 delay) internal pure returns (bytes memory output){
      bytes memory GCE = bytes(abi.encodePacked(
          hex"21F9" // header
          hex"04" // 4 bytes data
          hex"04", // Packed field
          delay, hex"00", // Delay time
          hex"00" // Transparent color index 
          hex"00" // GCE block terminator
      ));
      bytes memory imageDescriptor = bytes(hex"2C" // header
                                           hex"0000" // pos left
                                           hex"0000" // pos top
                                           hex"0500" // width=5
                                           hex"0500" // height=5
                                           hex"85" // packed field: with local color table
                                          );
      bytes memory localColorTable = bytes(abi.encodePacked(
          getColorTable(image, 0),
          getColorTable(image, 12),
          getColorTable(image, 24),
          getColorTable(image, 36),
          getColorTable(image, 48),
          getColorTable(image, 60),
          image[72],
          image[73],
          image[74],
          hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
      ));
      output = abi.encodePacked(GCE, imageDescriptor, localColorTable,
                              hex"07", // Use 7 bits codes
                              abi.encodePacked(getLine(0), 
                                               getLine(5), 
                                               getLine(10),
                                               getLine(15),
                                               getLine(20)
                                              ),
                              hex"0181", // STOP
                              hex"00");
  }

  function getGIF(Seeds memory seeds) public view returns(string memory result){
      bytes memory header = bytes("GIF89a");
      bytes memory LSD = bytes(hex"0500" // width=5
                               hex"0500" // height=5
                               hex"30" // packed field for global color table
                               hex"00" // background index
                               hex"00" // pixel aspect ratio
                              );
      bytes memory AE = bytes(hex"21FF" // Application extension header
                              hex"0B" // size of block (always 11)
                              hex"4E45545343415045322E30" // NETSCAPE2.0 in ascii
                              hex"03" // number of bytes in the following sub-block
                              hex"01" // 1
                              hex"0000" // repetitions=infinity
                              hex"00" // end of AE.
                             );
      bytes memory trailer = bytes(hex"3b");
      bytes memory image1 = makeAnimatedGIF(inference(seeds.seed1), uint8(seeds.delay));
      bytes memory image2 = makeAnimatedGIF(inference(seeds.seed2), uint8(seeds.delay));
      bytes memory image3 = makeAnimatedGIF(inference(seeds.seed3), uint8(seeds.delay));
      bytes memory body = abi.encodePacked(
          image1, image2, image3, image2
      );
      result = string(
          abi.encodePacked(
              'data:image/gif;base64,', 
              Base64.encode(
                  abi.encodePacked(
                      header,
                      LSD,
                      AE,
                      body,
                      trailer
                  )
              )
      ));
  }
  function getAnimatedURI(string memory gif) public pure returns(string memory svg){
      svg = string(
          abi.encodePacked(
              'data:image/svg+xml;base64,',
              Base64.encode(
                  abi.encodePacked(
                      "<svg width='100%' height='100%' xmlns='http://www.w3.org/2000/svg'> <image href='", 
                      gif, 
                      "' height='100%' width='100%' image-rendering='pixelated' /></svg>"
                  )
              )
          )
      );
  }
}
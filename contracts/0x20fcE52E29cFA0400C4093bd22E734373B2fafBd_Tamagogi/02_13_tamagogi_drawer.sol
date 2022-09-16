pragma solidity ^0.8.7;
import "base64-sol/base64.sol";
import "./tamagogi_data.sol";
// SPDX-License-Identifier: MIT

contract TamagogiDrawer is TamagogiData {
    function drawImage(bytes memory trait) private pure returns (string memory) {
      return string(abi.encodePacked(
        '<image x="0" y="0" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',Base64.encode(bytes(trait)),'"/>'
      ));
    }

    function drawReveal(uint seed, uint reactionId, bool isMaster) internal view returns (string memory) {
        bytes memory bodyImageData = bodyBytes[(seed / 4) % body.length];
        bytes memory headImageData = headBytes[(seed / 3) % head.length];
        bytes memory earImageData = earBytes[(seed / 2) % ear.length];
        bytes memory reactionImageData = reactionBytes[reactionId];

        string memory imgString = string(abi.encodePacked(
            drawImage(bodyImageData),
            drawImage(headImageData),
            drawImage(reactionImageData),
            drawImage(earImageData)
          ));

        if (isMaster) { //master
          imgString = string(abi.encodePacked(
              imgString,
              drawImage(masterBytes[0])
          ));
        }

        return imgString;
    }

    function drawSVG(string memory svgString) internal pure returns (string memory) {
        return string(abi.encodePacked(
          '<svg width="960" height="960" version="1.1" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          '<rect width="100%" height="100%" fill="#aad999" />',
          svgString,
          "</svg>"
        ));
    }
}
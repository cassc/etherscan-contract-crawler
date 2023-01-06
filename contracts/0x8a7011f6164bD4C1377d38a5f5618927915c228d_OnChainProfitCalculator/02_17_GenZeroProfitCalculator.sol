// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import { ProfitCalculatorDrawingContract } from "./IProfitCalculator.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GenZeroProfitCalculator is ProfitCalculatorDrawingContract{
  function addText(string memory text, string memory x, string memory y, string memory class) internal pure returns (string memory){
      return string(
          abi.encodePacked(
              ' <text x="', x, 
              '" y="', y,
              '" class="', class,
              '">', text,
              '</text> '
          )
      );
  }
  function addText(string memory text, string memory text2, string memory x, string memory y, string memory class) internal pure returns (string memory){
      return string(
          abi.encodePacked(
              ' <text x="', x, 
              '" y="', y,
              '" class="', class,
              '">', text, text2,
              '</text> '
          )
      );
  }

  // TODO prettier positions/fonts
  function svgTotalProfit(ProfitCalculator memory pc) internal pure returns (string memory){
      string memory profitColor;
      if (pc.potentialTotalProfit < 0) {
          profitColor = "#F0A8AA";
      }
      else{
          profitColor = "#CAF0AA";
      }
      return string(
          abi.encodePacked(
              ' <text x="50%" y="15%" dominant-baseline="middle" text-anchor="middle" font-size="13px" fill="#E5E6D9" font-family="helvetica" >', pc.holder, '</text> <text x="50%" y="75%" dominant-baseline="middle" text-anchor="middle" font-size="24px" fill="#E5E6D9" font-family="helvetica" >Potential Total Profit</text> <text x="50%" y="88%" dominant-baseline="middle" text-anchor="end" font-size="18px" fill="#E5E6D9" font-family="helvetica" >', pc.stringPotentialTotalProfit, ' \xCE\x9E</text> <text x="50%" y="88%" dominant-baseline="middle" text-anchor="start" font-size="18px" fill="', profitColor, '" font-family="helvetica" >  (', pc.returnRate, ' %)</text> <text x="50%" y="8%" dominant-baseline="middle" text-anchor="middle" font-size="18px" fill="#E5E6D9" font-family="helvetica" >On Chain Profit Calculator</text>'
          )
      );
  }

  function addLine(string memory y) internal pure returns (string memory){
      return string(abi.encodePacked(' <line x1="10%" y1="', y, '" x2="90%" y2="', y, '" stroke="#A2CCD6" stroke-width="1px"/>'));
  }

  function image(ProfitCalculator memory pc) public pure override returns (string memory){
      string memory _image;
      if (pc.tokenId == 0){
          _image = string(
              abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <style>.Start { fill: #F0A8AA; font-family: helvetica; font-size: 12px; dominant-baseline: bottom; text-anchor: text;} </style> <rect width="100%" height="100%" fill="#2F2D30" />',
                addText("Don't buy this NFT it is for advertisement usage", "5%", "25%", "Start"),
                addText("Please set the gas limit to 400000 per NFT.", "5%", "35%", "Start"),
                addText("Usually it will take 240000 or 320000,", "5%", "45%", "Start"),
                addText("otherwise there is 80% chance for execution reverted error.", "5%", "55%", "Start"),
                '</svg>'
              )
          );
          _image = string(
              abi.encodePacked(
                  "data:image/svg+xml;base64,",
                  Base64.encode(
                      bytes(
                          _image
                      )
                  )
              )
          );
          return _image;
      }
      _image = string(
          abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <style>.Start { fill: #E5E6D9; font-family: helvetica; font-size: 14px; dominant-baseline: bottom; text-anchor: start;} .End { fill: #E5E6D9; font-family: helvetica; font-size: 16px; dominant-baseline: bottom; text-anchor: end;} </style> <rect width="100%" height="100%" fill="#2F2D30" />',
            addText("Number bought:", "10%", "25%", "Start"),
            addText("Number remaining:", "10%", "35%", "Start"),
            addText("Total cost:", "10%", "45%", "Start"),
            addText("Realized profit:", "10%", "55%", "Start")
          )
      );
      _image = string(
          abi.encodePacked(
            _image,
            addText("Unrealized profit:", "10%", "65%", "Start"),
            svgTotalProfit(pc),
            addText(pc.numberBought, "", "90%", "25%", "End"),
            addText(pc.numberRemaining, "", "90%", "35%", "End"),
            addText(pc.stringTotalCost, " \xCE\x9E", "90%", "45%", "End"),
            addText(pc.realizedProfit, " \xCE\x9E", "90%", "55%", "End"),
            addText(pc.unrealizedProfit, " \xCE\x9E", "90%", "65%", "End")
          )
      );
      _image = string(
          abi.encodePacked(
            _image,
            addLine("26%"),
            addLine("36%"),
            addLine("46%"),
            addLine("56%"),
            addLine("66%"),
            '</svg>'
          )
      );
      _image = string(
          abi.encodePacked(
              "data:image/svg+xml;base64,",
              Base64.encode(
                  bytes(
                      _image
                  )
              )
          )
      );
      return _image;
  }

}
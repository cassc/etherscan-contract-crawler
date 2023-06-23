// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
library Render {
  function getCardImage(uint8 cardNumber, uint8 suitIndex, uint8 handIndex) internal pure returns (bytes memory) {
      string[4] memory suits = ["&#9829;","&#9824;","&#9827;","&#9830;"];
      string[4] memory suitColors = ["ec5300","000","000","ec5300"];
      string memory card;
      string memory suit = suits[suitIndex];
      string memory suitColor = suitColors[suitIndex];

      if (cardNumber == 0) { card = 'A'; }
      else if (cardNumber == 12) { card = 'K'; }
      else if (cardNumber == 11) { card = 'Q'; }
      else if (cardNumber == 10) { card = 'J'; }
      else { card = toString(cardNumber+1); }

      string memory cardTransform;
      if (handIndex == 1) {
        cardTransform = '<g transform="translate(-135,70) rotate(-50 250 229)"><rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" /><text x="290" y="181" text-anchor="end" style="fill: #C2BD88;">';
      }
      else if (handIndex == 2) {
        cardTransform = '</text></g><g transform="translate(-75,20) rotate(-25 250 229)"><rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" /><text x="290" y="181" text-anchor="end" style="fill: #C2BD88;">';
      }
      else if (handIndex == 3) {
        cardTransform = '</text></g><g><rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" /><text x="290" y="181" text-anchor="end" style="fill: #C2BD88;">';
      }
      else if (handIndex == 4) {
        cardTransform = '</text></g><g transform="translate(75,20) rotate(25 250 229)"><rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" /><text x="290" y="181" text-anchor="end" style="fill: #C2BD88;">';
      }
      else if (handIndex == 5) {
        cardTransform = '</text></g><g transform="translate(135,70) rotate(50 250 229)"><rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" /><text x="290" y="181" text-anchor="end" style="fill: #C2BD88;">';
      }

      return abi.encodePacked(
        cardTransform,
        card,
        '</text><text x="250" y="227.5" alignment-baseline="middle" text-anchor="middle" class="king">',
        suit,
        '</text><text x="250" y="228" alignment-baseline="middle" text-anchor="middle" style="fill: #', suitColor, '; font-size:1.4em">',
        suit,
        '</text><text x="350" y="297" text-anchor="end" style="fill: #C2BD88;" transform="rotate(180 280 288)">',
        card);
  }

  function getBrandImage(uint256 tokenId) internal pure returns (bytes memory) {
    return abi.encodePacked(
      '</text></g><text x="250" y="83" style="fill: #C2BD88;font-size:0.85em" text-anchor="middle">H01d\'Em</text><text x="250" y="100" style="fill: #FF5A00;font-size:0.5em;font-style:italic" text-anchor="middle">Genesis Series</text><text x="250" y="387" style="fill: #C2BD88;font-size:0.65em;font-style:italic" text-anchor="middle">#',
      toString(tokenId),
      '</text><text x="250" y="403" style="fill: #C2BD88;font-size:0.4em;font-style:italic" text-anchor="middle">\'May the best hand win\'</text><text x="100" y="100" style="fill: #C2BD88;"><textPath startOffset="-100%" xlink:href="#pokey" style="font-size:0.6em;">You Can\'t Bluff the Blockchain.<animate additive="sum" attributeName="startOffset" from="100%" to="0%" begin="0s" dur="25s" repeatCount="indefinite" /></textPath><textPath startOffset="5.475%" xlink:href="#pokey" style="font-size:0.6em;">You Can\'t Bluff the Blockchain.<animate additive="sum" attributeName="startOffset" from="100%" to="0%" begin="0s" dur="25s" repeatCount="indefinite" /></textPath><textPath startOffset="-45%" xlink:href="#pokey" style="font-size:0.6em;">Losers F01d\'Em, Winners H01d\'Em.<animate additive="sum" attributeName="startOffset" from="100%" to="0%" begin="0s" dur="25s" repeatCount="indefinite" /></textPath><textPath startOffset="55%" xlink:href="#pokey" style="font-size:0.6em;">Losers F01d\'Em, Winners H01d\'Em.<animate additive="sum" attributeName="startOffset" from="100%" to="0%" begin="0s" dur="25s" repeatCount="indefinite" /></textPath></text></svg>'
      );
  }

  function getHeader() internal pure returns (bytes memory) {
    return '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 500 500" preserveAspectRatio="xMidYMid meet" style="font:300 1.8em sans-serif"><path id="pokey" d="M38,18 h424 a20,20 0 0 1 20,20 v424 a20,20 0 0 1 -20,20 h-424 a20,20 0 0 1 -20,-20 v-424 a20,20 0 0 1 20,-20 z" /><rect width="500" height="500" fill="#034C29" /><style type="text/css"><![CDATA[.ace{stroke:#C2BD88;stroke-width:2.25;fill:#034C29} .king{fill:#C2BD88;font-size:1.5em;stroke:#C2BD88;stroke-width:3}]]></style>';
  }

  function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";

interface IExternalStatic {
  function getSVG() external pure returns (string memory);
}


contract BootcampSVG1 is IExternalStatic {
  function getSVG() external override pure returns (string memory) {
    return '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 816 805.4" style="enable-background:new 0 0 816 805.4;" xml:space="preserve">'
    '<style>.st0{fill-rule:evenodd;clip-rule:evenodd;fill:#6b1687}.st1{fill:#883797}.st2{fill:#2800ff}.st3{fill:#68626a}.st4{fill:#67616a}.st5{fill-rule:evenodd;clip-rule:evenodd;}.st17{fill:#666}.st18{font-family:Optima,Helvetica, sans-serif;}.st19{font-size:36px}.st20{letter-spacing:4}.st21{fill:#6c04b4}.st22{letter-spacing:3}.st23{font-size:21px}</style>'
    '<path class="st0" d="m415 129.4l-1.2-2.1"/><path class="st1" d="M86.9,703.7h642.5v2.9H86.9V703.7z"/>'
    '<path class="st1" d="m86.9 698.2c-3.9-0.1-7 3-7.1 6.9s3 7 6.9 7.1 7-3 7.1-6.9v-0.1c0-3.8-3.1-6.9-6.9-7zm642.5 13.9c3.8-0.5 6.6-3.9 6.1-7.8-0.4-3.2-2.9-5.7-6.1-6.1-3.8-0.5-7.3 2.3-7.8 6.1s2.3 7.3 6.1 7.8c0.6 0.1 1.1 0.1 1.7 0z"/>'
    '<path class="st2" d="m544.1 778.6h2.8c0.7 0 0.9-0.2 0.9-0.9v-12.3l1.4 2.3 4.1 7.2c0.2 0.3 0.6 0.6 1 0.6h1.8c0.5 0 1-0.3 1.3-0.7 0.4-0.8 0.8-1.5 1.3-2.2 1.3-2.4 2.6-4.8 4-7.1 0-0.1 0-0.1 0.1-0.1v12.4c0 0.6 0.2 0.8 0.8 0.8h2.8c0.7 0 0.9-0.2 0.9-0.9v-19.8c0-0.6-0.3-0.9-0.8-0.9-1 0.1-2 0.1-3 0-0.6 0-1.1 0.3-1.4 0.8l-2.8 4.9-2.5 4.4-0.3 0.7c-0.3 0.6-0.6 1.2-1 1.8l-0.2-0.3c-0.3-0.7-0.7-1.3-1.1-1.9l-2.8-4.7c-0.8-1.7-1.8-3.3-2.8-4.9-0.1-0.5-0.6-0.8-1.1-0.7h-3.2c-0.4-0.1-0.7 0.2-0.8 0.6v0.2 20.1c-0.2 0.4 0 0.6 0.6 0.6zm-38.9 0h6c1.3 0.1 2.6-0.2 3.8-0.7 2.6-1 4.7-2.8 6-5.3 1.6-3.3 1.5-7.3-0.5-10.4-1.7-2.7-4.4-4.5-7.5-5-0.7-0.1-1.3-0.2-2-0.2h-5.8c-0.6 0-0.8 0.3-0.8 0.8v20.1c0 0.5 0.2 0.7 0.8 0.7zm3.5-16.8c0-0.2 0.1-0.3 0.3-0.3 0.5 0.1 1.1 0.1 1.6 0.1s1.1 0 1.6 0.1c0.8 0.1 1.6 0.3 2.2 0.8 2.2 1.2 3.4 3.6 3.1 6-0.1 1.7-0.9 3.3-2.3 4.4-1.1 1-2.5 1.5-4 1.5h-2.2c-0.2 0-0.3 0-0.3-0.2v-12.4zm-70 16.6l1.7-3.8c0.1-0.1 0.1-0.2 0.3-0.2h9.4l0.5 0.2 1.6 3.8c0.1 0.1 0.1 0.2 0.3 0.2h4.6c-0.1-0.3-0.2-0.5-0.3-0.8l-2.3-5.3-2.3-5.2-2.3-5.3-1.9-4.4c-0.2-0.5-0.6-0.8-1.1-0.8h-2.5c-0.6 0-1.2 0.3-1.4 0.9l-2.2 4.8-2.2 5.2c-0.7 1.8-1.6 3.4-2.3 5.3l-2.1 4.7c-0.1 0.3-0.2 0.5-0.3 0.8h4.6c0.2 0.1 0.2 0 0.2-0.1zm6.8-15.4l3.1 6.9h-6.1l3-6.9zm36.8 15.4c0.6-1.2 1.1-2.4 1.6-3.7 0.1-0.2 0.3-0.3 0.5-0.3h9.4l0.5 0.2 1.6 3.8c0 0.1 0.1 0.2 0.2 0.2h4.7c-0.1-0.3-0.2-0.5-0.3-0.8l-2.3-5.2-2.3-5.3-2.2-4.8-2.2-4.9c-0.1-0.4-0.5-0.7-1-0.7-0.4 0.1-0.9 0.1-1.3 0.1s-0.9 0-1.3-0.1c-0.6 0-1.1 0.3-1.3 0.9l-2.2 4.8-2.3 5.2-2.3 5.4c-0.7 1.5-1.4 3-1.9 4.5-0.2 0.3-0.4 0.6-0.5 0.9h4.6c0.2 0 0.2-0.1 0.3-0.2zm6.7-15.4l3.1 6.9h-6.1l3-6.9zm37.9 15.6h11.1c0.6 0 0.8-0.2 0.8-0.8v-2.8c-0.1-0.7-0.2-0.9-0.9-0.9h-7.1c-0.3 0-0.3-0.1-0.3-0.3v-3.4c0-0.2 0-0.3 0.2-0.3h5.8c0.6 0 0.8-0.2 0.8-0.8v-2.9c0-0.6-0.2-0.8-0.8-0.8h-5.7c-0.3 0-0.3-0.1-0.3-0.3v-3.4c0-0.2 0-0.3 0.3-0.3h7.1c0.7 0 0.9-0.2 0.9-0.8v-2.9c0-0.5-0.3-0.8-0.9-0.8h-11c-0.6 0-0.8 0.3-0.8 0.9v19.9c0 0.5 0.2 0.7 0.8 0.7zm-62.5-0.4c1.1 0.3 2.2 0.5 3.3 0.5s2.3-0.2 3.3-0.7c1.7-0.7 3.2-1.7 4.5-3.1 0.2-0.3 0.2-0.6 0-0.9l-2.1-2.2c-0.2-0.2-0.3-0.3-0.5-0.3s-0.4 0.1-0.6 0.3c-0.4 0.5-0.8 1-1.4 1.3-1 0.7-2.2 1.1-3.5 1.1-1.5 0-2.9-0.5-4-1.5-2.7-2.4-2.9-6.5-0.5-9.2 1.1-1.2 2.7-2 4.4-2.1 1.1 0 2.1 0.3 3.1 0.8 0.7 0.5 1.3 1 1.9 1.6 0.2 0.2 0.3 0.3 0.5 0.3s0.3-0.1 0.5-0.3l2.1-2.2c0.3-0.2 0.2-0.6 0-0.9l-0.6-0.6c-1.5-1.5-3.4-2.5-5.5-3-0.6-0.1-1.2-0.2-1.8-0.2-3.9 0-7.6 2.2-9.5 5.6-1.7 3.2-1.7 7.2 0 10.4 1.4 2.5 3.7 4.4 6.4 5.3zm108-15.5c1.1 1.8 2.4 3.6 3.6 5.3 0.8 1.4 1.7 2.8 2.6 4.1 0.2 0.4 0.3 0.8 0.3 1.2v4.6c0 0.6 0.2 0.8 0.8 0.8h2.8c0.7 0 0.9-0.2 0.9-0.8v-4.6c0-0.4 0.1-0.8 0.3-1.2l3-4.6 3.6-5.4 3.1-4.6c0.1-0.1 0.2-0.3 0.2-0.5h-5l-0.3 0.1c0 0.1 0 0.2-0.1 0.3l-3.6 5.4-3.1 4.6-0.2 0.5c-0.2 0-0.2-0.3-0.3-0.5l-3.7-5.5c-0.9-1.5-1.9-3-3-4.5-0.1-0.1-0.1-0.1-0.1-0.2-0.1-0.2-0.2-0.2-0.5-0.2h-4.9l0.2 0.5c1.1 1.8 2.2 3.5 3.4 5.2z"/>';
  }
}

contract BootcampSVG2 is IExternalStatic {
  function getSVG() external override pure returns (string memory) {
    return '<path class="st3" d="m258.6 780.5c6.2 0 11.3-5.1 11.3-11.3v-0.2c-0.1-6.2-5.3-11.2-11.5-11.1s-11.2 5.3-11.1 11.5 5.1 11.1 11.3 11.1zm0-20.7h0.2c5 0.1 9.1 4.3 9 9.3-0.1 5.1-4.2 9.2-9.3 9.1s-9.2-4.2-9.1-9.3c0.1-5 4.2-9.1 9.2-9.1z"/>'
    '<path class="st4" d="m322.2 779.2h12.5c0.5 0 0.8-0.3 0.9-0.8 0.3-0.5 0.2-1.1-0.3-1.4-0.2-0.1-0.5-0.2-0.8-0.1h-11.1c-0.2 0-0.3 0-0.3-0.2v-7.7c0-0.2 0.1-0.3 0.3-0.3h7.9c0.6 0 1-0.2 1.1-0.7 0.2-0.8-0.2-1.5-1-1.5h-7.9c-0.3 0-0.5-0.1-0.5-0.5l0.1-7.2c0-0.5-0.1-0.5 0.3-0.5h11.2c0.5 0 0.9-0.3 1-0.8 0.2-0.6-0.2-1.3-0.9-1.5h-0.4-12.4c-0.7-0.1-1.2 0.4-1.3 1.1v0.3 20.4c0.3 0.9 0.7 1.4 1.6 1.4z"/>'
    '<path class="st3" d="m413.9 778.2c1.2 0.7 2.6 1 4 1 1.6 0 3.2-0.5 4.6-1.4 0.5-0.3 1.1-0.7 1.5-1.2 2.4-2.3 2.6-6.1 0.3-8.5-0.2-0.3-0.5-0.5-0.8-0.7-1.2-1-2.6-1.8-4.1-2.1-1-0.1-2.1-0.3-3.1-0.6-1.1-0.3-2.2-0.9-3-1.7-0.5-0.5-0.7-1.2-0.5-1.8 0.2-0.9 0.8-1.7 1.6-2.1 1.1-0.6 2.3-0.9 3.6-1 1.2 0 2.3 0.3 3.4 0.8 1 0.5 1.7 1.5 1.9 2.6 0 0.4 0.2 0.7 0.5 0.9 0.2 0.1 0.4 0.2 0.6 0.2s0.3 0 0.5-0.1c0.3-0.2 0.6-0.6 0.6-1s0-0.7-0.1-1.1c-0.6-1.6-1.8-2.9-3.3-3.6-1.3-0.6-2.7-1-4.2-1-1.6 0.1-3.2 0.5-4.6 1.4-0.5 0.3-1.1 0.7-1.5 1.2-1.7 1.8-1.6 4.7 0.2 6.4 0.1 0.1 0.3 0.2 0.4 0.3 1.2 0.9 2.5 1.5 4 1.8 1.1 0.1 2.1 0.3 3.1 0.7 1 0.2 1.9 0.7 2.6 1.4 0.8 0.7 1.4 1.6 1.6 2.6 0.3 1.4-0.3 2.8-1.4 3.6-1.2 1-2.7 1.6-4.3 1.6-0.9 0-1.8-0.2-2.7-0.5-2-0.5-3.4-2.4-3.4-4.5 0-0.6-0.5-1-1-1s-1 0.5-1 1c0 0.6 0.1 1.1 0.2 1.7 0.5 2.1 1.9 3.8 3.8 4.7zm-45.7 0c1.2 0.7 2.6 1 4 1 1.6 0 3.1-0.5 4.5-1.3 0.6-0.3 1.2-0.7 1.6-1.3 2.5-2.2 2.7-6 0.5-8.5-0.2-0.3-0.5-0.5-0.8-0.7-1.2-1-2.6-1.8-4.2-2.1l-2.4-0.3c-1.2-0.3-2.3-0.8-3.2-1.6-0.6-0.4-0.9-1-0.9-1.7 0.1-0.9 0.5-1.8 1.3-2.3 0.9-0.6 2.1-1 3.2-1 0.4-0.1 0.7-0.1 1.1-0.1 1.2 0 2.3 0.3 3.3 0.9 0.9 0.5 1.6 1.4 1.7 2.5 0 0.4 0.2 0.7 0.5 0.9 0.2 0.1 0.4 0.2 0.6 0.2s0.3 0 0.5-0.1c0.3-0.2 0.6-0.6 0.6-1 0-0.5 0-1-0.2-1.4-0.5-1.5-1.7-2.7-3.2-3.3-1.4-0.7-2.9-1-4.5-1-1.5 0-3 0.5-4.2 1.4-0.6 0.3-1.1 0.7-1.5 1.2-1.1 1.1-1.5 2.7-1.1 4.2 0.3 1 0.9 1.9 1.7 2.5 1.1 1 2.5 1.6 4 1.8 1.1 0.1 2.1 0.3 3.1 0.7 0.9 0.3 1.8 0.8 2.6 1.4 0.9 0.8 1.5 1.9 1.6 3.1 0 1.4-0.7 2.6-1.8 3.4-1.1 0.9-2.5 1.3-3.9 1.3-0.6 0-1.3-0.1-1.9-0.2-1.5-0.2-2.8-1.1-3.6-2.4-0.4-0.7-0.7-1.5-0.7-2.3-0.1-0.5-0.5-0.9-1-0.9-0.5 0.1-0.9 0.5-0.9 1 0 0.6 0 1.2 0.2 1.7 0.3 1.9 1.6 3.6 3.4 4.3zm-65.7 0c2.7 1.4 5.9 1.3 8.5-0.2 0.6-0.3 1.2-0.8 1.7-1.3 2.5-2.3 2.6-6.3 0.3-8.8-0.2-0.2-0.4-0.4-0.6-0.5-1.2-0.9-2.7-1.6-4.2-1.9-1-0.1-2.1-0.3-3.1-0.6-1.1-0.3-2.2-0.9-3-1.7-0.5-0.5-0.7-1.2-0.5-1.8 0.2-0.9 0.8-1.7 1.6-2.1 1.1-0.6 2.3-0.9 3.6-1 1.2 0 2.3 0.3 3.4 0.8 1 0.5 1.8 1.5 2 2.6 0 0.2 0.1 0.4 0.2 0.6 0.1 0.3 0.4 0.6 0.8 0.6 0.7 0 1-0.5 1.1-1.1 0-0.4-0.1-0.7-0.2-1.1-0.5-1.6-1.7-2.9-3.2-3.6-1.4-0.7-2.9-1.1-4.4-1-1.6 0-3.1 0.5-4.5 1.3-0.6 0.3-1.1 0.8-1.5 1.3-1 1.1-1.5 2.5-1.3 4 0.2 1.1 0.9 2 1.8 2.6 1.1 1 2.5 1.6 4 1.9 1.1 0.1 2.1 0.3 3.1 0.6 0.9 0.4 1.8 0.9 2.6 1.5 0.9 0.7 1.5 1.8 1.6 3 0.1 1.3-0.5 2.5-1.5 3.3-1.2 0.9-2.7 1.5-4.3 1.5-0.9 0-1.8-0.2-2.6-0.5-1.4-0.4-2.5-1.4-3.1-2.8-0.2-0.5-0.3-1.1-0.3-1.7-0.1-0.5-0.5-1-1.1-0.9-0.5 0.1-0.9 0.5-0.9 1 0 0.6 0.1 1.1 0.2 1.7 0.7 1.9 2 3.4 3.8 4.3zm-74.3 0c1.3 0.6 2.7 0.9 4.1 1 2.1 0.1 4.2-0.4 6-1.4 1-0.7 2-1.5 2.9-2.3 0.2-0.2 0.3-0.4 0.3-0.7 0.1-0.4-0.1-0.9-0.5-1.1-0.1-0.1-0.3-0.1-0.4-0.1-0.2 0-0.5 0.1-0.7 0.2s-0.4 0.3-0.6 0.5c-1.7 1.7-3.9 2.6-6.3 2.6-0.6 0-1.3-0.1-1.9-0.2-2.6-0.4-4.8-2-6.1-4.2-0.9-1.4-1.4-3-1.4-4.6 0-2 0.5-3.9 1.6-5.6 1.8-2.5 4.6-3.9 7.6-3.9 0.6 0 1.2 0.1 1.8 0.2 1.3 0.3 2.5 0.9 3.6 1.7l1.4 1c0.2 0.2 0.4 0.3 0.7 0.3s0.5-0.1 0.7-0.3c0.4-0.4 0.5-1 0.1-1.4l-0.3-0.3c-0.9-1-2.1-1.8-3.3-2.4-1.4-0.7-2.9-1-4.4-1h-0.7c-1.7 0-3.4 0.4-4.9 1.3-2.2 1.2-3.9 3.1-5 5.3-0.7 1.6-1.1 3.4-1.1 5.2 0.1 1.9 0.6 3.7 1.5 5.4 1.3 2.1 3.1 3.8 5.3 4.8z"/>'
    '<path class="st4" d="m342.5 779.1h0.2c0.5-0.1 1-0.5 0.9-1.1v-13.4c0-0.9 0.1-1.7 0.5-2.5 0.9-2.3 3.2-3.7 5.6-3.7h0.8c2.7 0.4 4.9 2.6 5.3 5.3v14.3c0 0.3 0.1 0.6 0.3 0.8 0.2 0.3 0.6 0.4 0.9 0.4h0.3c0.5-0.1 0.9-0.6 0.8-1.1v-13.5c0-0.8-0.1-1.6-0.3-2.3-0.6-2.1-2.1-3.9-4-5-1.2-0.7-2.6-1-4-1-0.4 0-0.9 0-1.3 0.1-1.2 0.2-2.4 0.7-3.4 1.5-0.4 0.3-0.8 0.6-1.1 1-1.6 1.6-2.4 3.8-2.3 6v13.5c-0.2 0.3 0.3 0.7 0.8 0.7zm-65.4 0c0.1 0 0.3 0 0.4-0.1 0.5-0.1 0.9-0.6 0.8-1.1v-13.3c0-0.8 0.1-1.6 0.3-2.3 0.9-2.4 3.1-4 5.7-4 0.5 0 1 0.1 1.5 0.2 2.7 0.8 4.5 3.2 4.5 6v13.5c-0.1 0.4 0.2 0.8 0.6 0.9 0.2 0.1 0.5 0.2 0.7 0.2s0.3 0 0.5-0.1c0.3-0.2 0.6-0.6 0.6-1v-13.8c0-0.7-0.1-1.4-0.3-2.1-0.6-2.2-2.1-4-4.1-5-1.1-0.7-2.3-1.1-3.6-1.1-0.5 0-1 0-1.5 0.1-1.2 0.2-2.4 0.6-3.4 1.4-0.4 0.3-0.8 0.6-1.1 1-1.6 1.6-2.4 3.8-2.4 6v13.4c-0.2 0.4-0.1 0.9 0.3 1.1 0.1 0.1 0.3 0.1 0.5 0.1z"/>'
    '<path class="st3" d="m388.2 762.7l4 5.3 1.5 1.9c0.1 0.2 0.2 0.4 0.2 0.6v7.7c0.1 0.6 0.3 0.8 0.8 0.9h0.3c0.3 0 0.6-0.1 0.8-0.4s0.2-0.6 0.2-0.9v-7.5c0-0.2 0-0.3 0.1-0.5 0.7-0.8 1.3-1.6 1.9-2.4 1.4-1.8 2.8-3.4 4.1-5.3l1.7-2.2 1.7-2.2c0.3-0.5 0.2-1.2-0.2-1.6-0.2-0.1-0.4-0.2-0.6-0.2-0.3 0-0.7 0.2-0.9 0.4l-0.7 0.9-4.1 5.3-2.4 3-1.7 2.3-0.5-0.6c-1.7-2.2-3.4-4.5-5.2-6.6l-3.2-4.2c-0.2-0.3-0.5-0.4-0.8-0.4h-0.3c-0.6 0.2-0.9 0.8-0.7 1.4 0 0.2 0.1 0.3 0.2 0.4l3.8 4.9z"/>';
  }
}

contract BootcampSVG3 is IExternalStatic {
  function getSVG() external override pure returns (string memory) {
    return '<linearGradient id="a" x1="-2015" x2="-2015" y1="-84.463" y2="-70.963" gradientTransform="matrix(13.55 0 0 13.55 27662 1276.1)" gradientUnits="userSpaceOnUse"><stop stop-color="#be03ed" offset="0"/><stop stop-color="#7935ad" offset="1"/></linearGradient>'
    '<path class="st5" fill= "url(#a)" d="m413.8 130.1l-108.3 183.7 108.3-45.7v-138z"/>'
    '<linearGradient id="d" x1="-2012.8" x2="-2022.9" y1="-85.293" y2="-75.193" gradientTransform="matrix(14.37 0 0 14.37 29465 1375.5)" gradientUnits="userSpaceOnUse"><stop stop-color="#9902bf" offset="0"/><stop stop-color="#e971ff" offset=".1"/><stop stop-color="#662d91" offset="1"/></linearGradient>'
    '<path d="m522.8 313.8l-108.3-183.7 0.2 137.9 108.1 45.8z" clip-rule="evenodd" fill="url(#d)" fill-rule="evenodd"/>'
    '<linearGradient id="i" x1="-1956.5" x2="-1956.5" y1="-58.447" y2="-48.147" gradientTransform="matrix(10.34 0 0 10.34 20590 876.34)" gradientUnits="userSpaceOnUse"><stop stop-color="#9902bf" offset="0"/><stop stop-color="#662d91" offset="1"/></linearGradient>'
    '<path d="m413.8 268.8l-108.3 45.6 108.3 61.3v-106.9z" clip-rule="evenodd" fill="url(#i)" fill-rule="evenodd"/>'
    '<linearGradient id="g" x1="-1945.9" x2="-1945.9" y1="-58.447" y2="-48.147" gradientTransform="matrix(10.34 0 0 10.34 20590 876.34)" gradientUnits="userSpaceOnUse"><stop stop-color="#770195" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient>'
    '<path d="m414.7 268.8l-0.2 106.9 108.2-61.3-108-45.6z" clip-rule="evenodd" fill="url(#g)" fill-rule="evenodd"/>'
    '<linearGradient id="b" x1="-1988.7" x2="-1988.7" y1="-64.368" y2="-51.867" gradientTransform="matrix(12.44 0 0 12.44 25210 1133.3)" gradientUnits="userSpaceOnUse"><stop stop-color="#770195" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient>';
  }
}

contract BootcampSVG4 is IExternalStatic {
  function getSVG() external override pure returns (string memory) {
    return '<path d="m414.5 396.5v93.9l110.3-154.7-110.3 60.8z" clip-rule="evenodd" fill="url(#b)" fill-rule="evenodd"/>'
    '<linearGradient id="c" x1="-1997.7" x2="-1997.7" y1="-64.368" y2="-51.867" gradientTransform="matrix(12.44 0 0 12.44 25210 1133.3)" gradientUnits="userSpaceOnUse"><stop stop-color="#9902bf" offset="0"/><stop stop-color="#662d91" offset="1"/></linearGradient>'
    '<path d="m413.8 396.5l-110.6-60.8 110.6 154.7v-93.9z" clip-rule="evenodd" fill="url(#c)" fill-rule="evenodd"/>'
    '<linearGradient id="f" x1="-1833.1" x2="-1833.1" y1="-25.875" y2="-18.975" gradientTransform="matrix(6.93 0 0 6.93 13063 442.98)" gradientUnits="userSpaceOnUse"><stop stop-color="#770195" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient>'
    '<path d="m414.7 269.2l-0.8-1.9-109.1 46 0.8 1.9 109.1-46z" clip-rule="evenodd" fill="url(#f)" fill-rule="evenodd"/>'
    '<linearGradient id="e" x1="-1817.3" x2="-1817.3" y1="-25.875" y2="-18.975" gradientTransform="matrix(6.93 0 0 6.93 13062 442.58)" gradientUnits="userSpaceOnUse"><stop stop-color="#770195" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient><path d="m523.5 313.2l-108.8-46-0.8 2 108.8 45.9 0.8-1.9z" clip-rule="evenodd" fill="url(#e)" fill-rule="evenodd"/><linearGradient id="l" x1="-2001.4" x2="-2010.7" y1="-78.57" y2="-69.17" gradientTransform="matrix(13.26 0 0 13.26 27013 1233.4)" gradientUnits="userSpaceOnUse"><stop stop-color="#9902bf" offset="0"/><stop stop-color="#c15dd4" offset=".4"/><stop stop-color="#662d91" offset="1"/></linearGradient>';
  }
}

contract BootcampSVG5 is IExternalStatic {
  function getSVG() external pure returns (string memory) {
    return '<path d="M413.2,129.6h2V376h-2V129.6z" fill="url(#l)"/><linearGradient id="k" x1="-1933.6" x2="-1933.6" y1="-40.994" y2="-31.293" gradientTransform="matrix(9.71 0 0 9.71 19189 789.76)" gradientUnits="userSpaceOnUse"><stop stop-color="#5e0076" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient><path d="m413.2 396.7h2v94.2h-2v-94.2z" fill="url(#k)"/><linearGradient id="h" x1="-2038.3" x2="-2038.4" y1="-90.397" y2="-74.592" gradientTransform="matrix(15.81 0 0 15.81 32641 1556.9)" gradientUnits="userSpaceOnUse"><stop stop-color="#9902bf" offset="0"/><stop stop-color="#662d91" offset="1"/></linearGradient><path d="m524.6 314.6l-110.4-187.4-109.9 186.5-0.6 1 110.5 62.4 110.4-62.5zm-110.4-183.2l107.5 182.5-107.5 60.8-107.5-60.8 107.5-182.5z" clip-rule="evenodd" fill="url(#h)" fill-rule="evenodd"/><linearGradient id="j" x1="-1997.2" x2="-1997.2" y1="-65.657" y2="-52.958" gradientTransform="matrix(12.66 0 0 12.66 25698 1163.4)" gradientUnits="userSpaceOnUse"><stop stop-color="#770195" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient>'
    '<path d="m414.2 492.8l114.1-160.2-114.1 63-114.5-63 113.6 159 0.9 1.2zm0-94.9l107-59-107 150.1-107.5-150.1 107.5 59z" clip-rule="evenodd" fill="url(#j)" fill-rule="evenodd"/>'
    '<text class="st17 st18 st19 st20" transform="translate(168 75)">CERTIFICATE OF PROFICIENCY</text><text class="st21 st18 st19 st20" transform="translate(130 569)">ETHEREUM DEVELOPER PROGRAM</text><text class="st21 st18 st19 st22" transform="translate(188 613)">ONLINE BOOTCAMP 2021</text><text class="st18 st23" transform="translate(335 655)">ISSUED JAN 2022</text></svg>';
  }
}

contract BootcampNFTCert is ERC721URIStorage {
  uint256 public tokenCounter;
  
  event CreatedBootcampNFT(uint indexed tokenId);
  address public owner;
  // IExternalStatic public baseSVG1;
  // IExternalStatic public baseSVG2;
  BootcampSVG1 public BootcampSVG1_ref;
  BootcampSVG2 public BootcampSVG2_ref;
  BootcampSVG3 public BootcampSVG3_ref;
  BootcampSVG4 public BootcampSVG4_ref;
  BootcampSVG5 public BootcampSVG5_ref;

  constructor(BootcampSVG1 _addrBootcampSVG1, BootcampSVG2 _addrBootcampSVG2, BootcampSVG3 _addrBootcampSVG3, BootcampSVG4 _addrBootcampSVG4, BootcampSVG5 _addrBootcampSVG5) ERC721 ("BOOTCAMP2021", "EDU-DAO0x0") public {
    // studentList = _studentList;
    tokenCounter = 0;
    owner = msg.sender;
    // baseSVG1 = IExternalStatic(new BootcampSVG1());
    // baseSVG2 = IExternalStatic(new BootcampSVG2());
    BootcampSVG1_ref = _addrBootcampSVG1;
    BootcampSVG2_ref = _addrBootcampSVG2;
    BootcampSVG3_ref = _addrBootcampSVG3;
    BootcampSVG4_ref = _addrBootcampSVG4;
    BootcampSVG5_ref = _addrBootcampSVG5;



  }

  modifier onlyOwner {
    require(msg.sender == owner, "Caller is not contract owner");
    _;
 }

  function _baseURI() internal override view virtual returns (string memory) {

    string memory baseURL = "data:image/svg+xml;base64,";  
    string memory svgBase64Encoded = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            BootcampSVG1_ref.getSVG(),
            BootcampSVG2_ref.getSVG(),
            BootcampSVG3_ref.getSVG(),
            BootcampSVG4_ref.getSVG(),
            BootcampSVG5_ref.getSVG())
            
        )
      )
    );
    string memory imageURI = string(abi.encodePacked(baseURL,svgBase64Encoded));

  return string(
    abi.encodePacked(
      "data:application/json;base64,",
      Base64.encode(
        bytes(
          abi.encodePacked(
              '{"name":"',
              "2021 ConsenSys Academy Bootcamp Certificate",
              '", "description":"On-Chain Bootcamp Certification", "attributes":"", "image":"',imageURI,'"}'
          )
        )
      )
    )
  );

}

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : "";
  }

  function create(address _student) public onlyOwner {
    
    _safeMint(_student, tokenCounter);
    tokenCounter = tokenCounter + 1;

    emit CreatedBootcampNFT(tokenCounter);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
) public virtual override onlyOwner {

    _transfer(from, to, tokenId);
}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
) public virtual override onlyOwner {
    safeTransferFrom(from, to, tokenId, "");
}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override onlyOwner {

    _safeTransfer(from, to, tokenId, _data);
  }

}
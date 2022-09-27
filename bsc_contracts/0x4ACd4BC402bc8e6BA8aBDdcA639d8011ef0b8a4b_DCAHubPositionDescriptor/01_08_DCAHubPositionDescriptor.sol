// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import 'base64-sol/base64.sol';
import '../interfaces/IDCAHubPositionDescriptor.sol';
import '../libraries/DescriptorUtils.sol';
import '../libraries/IntervalUtils.sol';

/// @title Describes NFT token positions
/// @notice Produces a string containing the data URI for a JSON metadata string
contract DCAHubPositionDescriptor is IDCAHubPositionDescriptor {
  using Strings for uint256;
  using Strings for uint32;

  struct PositionParams {
    string tokenId;
    string fromToken;
    string toToken;
    uint8 fromDecimals;
    uint8 toDecimals;
    string fromSymbol;
    string toSymbol;
    string swapInterval;
    uint32 swapsExecuted;
    uint32 swapsLeft;
    uint256 toWithdraw;
    uint256 remaining;
    uint160 rate;
  }

  /// @inheritdoc IDCAHubPositionDescriptor
  function tokenURI(address _hub, uint256 _tokenId) external view returns (string memory) {
    IDCAPositionGetter.UserPosition memory _userPosition = IDCAPositionGetter(_hub).userPosition(_tokenId);

    return
      _constructTokenURI(
        PositionParams({
          tokenId: _tokenId.toString(),
          fromToken: DescriptorUtils.addressToString(address(_userPosition.from)),
          toToken: DescriptorUtils.addressToString(address(_userPosition.to)),
          fromDecimals: _userPosition.from.decimals(),
          toDecimals: _userPosition.to.decimals(),
          fromSymbol: _userPosition.from.symbol(),
          toSymbol: _userPosition.to.symbol(),
          swapInterval: IntervalUtils.intervalToDescription(_userPosition.swapInterval),
          swapsExecuted: _userPosition.swapsExecuted,
          toWithdraw: _userPosition.swapped,
          swapsLeft: _userPosition.swapsLeft,
          remaining: _userPosition.remaining,
          rate: _userPosition.rate
        })
      );
  }

  function _constructTokenURI(PositionParams memory _params) internal pure returns (string memory) {
    string memory _name = _generateName(_params);
    string memory _description = _generateDescription(_params);
    string memory _image = Base64.encode(bytes(_generateSVG(_params)));
    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked('{"name":"', _name, '", "description":"', _description, '", "image": "data:image/svg+xml;base64,', _image, '"}')
            )
          )
        )
      );
  }

  function _generateDescription(PositionParams memory _params) private pure returns (string memory) {
    string memory _part1 = string(
      abi.encodePacked(
        'This NFT represents a DCA position in Mean Finance, where ',
        _params.fromSymbol,
        ' will be swapped for ',
        _params.toSymbol,
        '. The owner of this NFT can modify or redeem the position.\\n\\n',
        _params.fromSymbol
      )
    );
    string memory _part2 = string(
      abi.encodePacked(
        ' Address: ',
        _params.fromToken,
        '\\n',
        _params.toSymbol,
        ' Address: ',
        _params.toToken,
        '\\nSwap interval: ',
        _params.swapInterval,
        '\\nToken ID: ',
        _params.tokenId,
        '\\n\\n',
        unicode'⚠️ DISCLAIMER: Due diligence is imperative when assessing this NFT. Make sure token addresses match the expected tokens, as token symbols may be imitated.'
      )
    );
    return string(abi.encodePacked(_part1, _part2));
  }

  function _generateName(PositionParams memory _params) private pure returns (string memory) {
    return string(abi.encodePacked('Mean Finance DCA - ', _params.swapInterval, ' - ', _params.fromSymbol, unicode' ➔ ', _params.toSymbol));
  }

  function _generateSVG(PositionParams memory _params) internal pure returns (string memory) {
    uint32 _percentage = (_params.swapsExecuted + _params.swapsLeft) > 0
      ? (_params.swapsExecuted * 100) / (_params.swapsExecuted + _params.swapsLeft)
      : 100;
    return
      string(
        abi.encodePacked(
          '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 580.71 1118.71" >',
          _generateStyleDefs(_percentage),
          _generateSVGDefs(),
          _generateSVGBackground(),
          _generateSVGCardMantle(_params),
          _generateSVGPositionData(_params),
          _generateSVGBorderText(_params),
          _generateSVGLinesAndMainLogo(_percentage),
          _generageSVGProgressArea(_params),
          '</svg>'
        )
      );
  }

  function _generateStyleDefs(uint32 _percentage) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<style type="text/css">.st0{fill:url(#SVGID_1)}.st1{fill:none;stroke:#fff;stroke-miterlimit:10}.st2{opacity:.5}.st3{fill:none;stroke:#b5baba;stroke-miterlimit:10}.st36{fill:#fff}.st37{fill:#48a7de}.st38{font-family:"Verdana"}.st39{font-size:60px}.st40{letter-spacing:-4}.st44{font-size:25px}.st46{fill:#c6c6c6}.st47{font-size:18px}.st48{font-size:19.7266px}.st49{font-family:"Verdana";font-weight:bold}.st50{font-size:38px}.st52{stroke:#848484;mix-blend-mode:multiply}.st55{opacity:.2;fill:#fff}.st57{fill:#48a7de;stroke:#fff;stroke-width:2.8347;stroke-miterlimit:10}.st58{font-size:18px}.cls-79{stroke:#d1dbe0;transform:rotate(-90deg);transform-origin:290.35px 488.04px;animation:dash 2s linear alternate forwards}@keyframes dash{from{stroke-dashoffset:750.84}to{stroke-dashoffset:',
          (((100 - _percentage) * 75084) / 10000).toString(),
          ';}}</style>'
        )
      );
  }

  function _generateSVGDefs() private pure returns (string memory) {
    return
      '<defs><path id="SVGID_0" class="st2" d="M580.71 1042.17c0 42.09-34.44 76.54-76.54 76.54H76.54c-42.09 0-76.54-34.44-76.54-76.54V76.54C0 34.44 34.44 0 76.54 0h427.64c42.09 0 76.54 34.44 76.54 76.54v965.63z"/><path id="text-path-a" d="M81.54 1095.995a57.405 57.405 0 0 1-57.405-57.405V81.54A57.405 57.405 0 0 1 81.54 24.135h417.64a57.405 57.405 0 0 1 57.405 57.405v955.64a57.405 57.405 0 0 1-57.405 57.405z"/><path id="text-path-executed" d="M290.35 348.77a139.5 139.5 0 1 1 0 279 139.5 139.5 0 1 1 0-279"/><path id="text-path-left" d="M290.35 348.77a-139.5-139.5 0 1 0 0 279 139.5 139.5 0 1 0 0-279"/><radialGradient id="SVGID_3" cx="334.831" cy="592.878" r="428.274" fx="535.494" fy="782.485" gradientUnits="userSpaceOnUse"><stop offset="0"/><stop offset=".11" stop-color="#0d1f29"/><stop offset=".28" stop-color="#1f4860"/><stop offset=".45" stop-color="#2e6a8d"/><stop offset=".61" stop-color="#3985b0"/><stop offset=".76" stop-color="#4198c9"/><stop offset=".89" stop-color="#46a3d9"/><stop offset="1" stop-color="#48a7de"/>&gt;</radialGradient><linearGradient id="SVGID_1" gradientUnits="userSpaceOnUse" x1="290.353" y1="0" x2="290.353" y2="1118.706"><stop offset="0" stop-color="#48a7de"/><stop offset=".105" stop-color="#3e81a6"/><stop offset=".292" stop-color="#2e4e5d"/><stop offset=".47" stop-color="#1f2c30"/><stop offset=".635" stop-color="#121612"/><stop offset=".783" stop-color="#060600"/><stop offset=".91" stop-color="#010100"/><stop offset="1"/></linearGradient><clipPath id="SVGID_2"><use xlink:href="#SVGID_0" overflow="visible"/></clipPath></defs>';
  }

  function _generateSVGBackground() private pure returns (string memory) {
    return
      '<path d="M580.71 1042.17c0 42.09-34.44 76.54-76.54 76.54H76.54c-42.09 0-76.54-34.44-76.54-76.54V76.54C0 34.44 34.44 0 76.54 0h427.64c42.09 0 76.54 34.44 76.54 76.54v965.63z" fill="url(#SVGID_1)"/><path d="M76.54 1081.86c-21.88 0-39.68-17.8-39.68-39.68V76.54c0-21.88 17.8-39.69 39.68-39.69h427.64c21.88 0 39.68 17.8 39.68 39.69v965.64c0 21.88-17.8 39.68-39.68 39.68H76.54z" fill="none" stroke="#fff" stroke-miterlimit="10"/><g id="XMLID_29_" clip-path="url(#SVGID_2)" opacity=".5"><path id="XMLID_00000106106944977730228320000011315049117735843764_" class="st3" d="M-456.81 863.18S-230.72 1042 20.73 930.95s273.19-602.02 470.65-689.23 307.97 123.01 756.32-75.01" stroke-width=".14"/><path class="st3" d="M-458.59 859.15s220.19 166.13 470.94 55.39 280.67-577.29 480.99-665.76 302.72 97.74 747.09-98.53" stroke-width=".172"/><path class="st3" d="M-460.37 855.13s214.29 153.44 464.34 43.01 288.14-552.56 491.33-642.3 297.46 72.46 737.86-122.05" stroke-width=".204"/><path class="st3" d="M-462.15 851.1s208.38 140.76 457.74 30.62S291.21 353.91 497.27 262.9s292.2 47.19 728.63-145.56" stroke-width=".235"/><path class="st3" d="M-463.92 847.08s202.48 128.07 451.15 18.24 303.09-503.08 512.01-595.35 286.95 21.91 719.4-169.08" stroke-width=".267"/><path class="st3" d="M-465.7 843.05s196.58 115.38 444.55 5.86S289.41 370.57 501.2 277.03s281.69-3.36 710.16-192.6" stroke-width=".299"/><path class="st3" d="M-467.48 839.02s190.67 102.69 437.95-6.52 318.04-453.6 532.69-548.4 276.43-28.64 700.93-216.12" stroke-width=".33"/><path class="st3" d="M-469.26 835s184.77 90 431.35-18.9S287.6 387.23 505.12 291.16s271.18-53.91 691.7-239.64" stroke-width=".362"/><path class="st3" d="M-471.03 830.97s178.87 77.32 424.75-31.28S286.7 395.56 507.09 298.23s265.92-79.19 682.47-263.16" stroke-width=".394"/><path class="st3" d="M-472.81 826.95s172.97 64.63 418.16-43.66 340.45-379.4 563.7-478 260.66-104.46 673.24-286.68" stroke-width=".425"/><path class="st3" d="M-474.59 822.92s167.06 51.94 411.56-56.04S284.9 412.22 511.02 312.36s255.41-129.74 664.01-310.2" stroke-width=".457"/><path class="st3" d="M-476.37 818.9s161.16 39.25 404.96-68.42S284 420.55 512.98 319.42 763.13 164.41 1167.76-14.3" stroke-width=".489"/><path class="st3" d="M-478.15 814.87s155.26 26.57 398.36-80.8 362.88-305.18 594.73-407.58 244.9-180.29 645.55-357.24" stroke-width=".52"/><path class="st3" d="M-479.92 810.85s149.35 13.88 391.77-93.19S282.2 437.21 516.92 333.55s239.64-205.56 636.31-380.76" stroke-width=".552"/><path class="st3" d="M-481.7 806.82s143.45 1.19 385.17-105.57 377.82-255.71 615.41-360.64 234.38-230.84 627.08-404.27" stroke-width=".584"/><path class="st3" d="M-483.48 802.8s137.55-11.5 378.57-117.95 385.3-230.97 625.75-337.17S749.96 91.57 1138.69-80.11" stroke-width=".616"/><path class="st3" d="M-485.26 798.77s131.64-24.19 371.97-130.33C127.04 562.3 279.49 462.21 522.8 354.74S746.67 73.36 1131.42-96.57" stroke-width=".647"/><path class="st3" d="M-487.04 794.74s125.74-36.87 365.37-142.71 400.24-181.5 646.43-290.23 218.61-306.66 599.39-474.83" stroke-width=".679"/><path class="st3" d="M-488.81 790.72s119.84-49.56 358.78-155.09 407.72-156.76 656.76-266.76 213.35-331.93 590.16-498.35" stroke-width=".711"/><path class="st3" d="M-490.59 786.69s113.93-62.25 352.18-167.47C99.83 514 276.78 487.2 528.69 375.94s208.1-357.21 580.92-521.87" stroke-width=".742"/><path class="st3" d="M-492.37 782.67s108.03-74.94 345.58-179.85S275.88 495.53 530.66 383 733.5.52 1102.35-162.39" stroke-width=".774"/><path class="st3" d="M-494.15 778.64s102.13-87.62 338.98-192.23 430.14-82.55 687.78-196.34S730.2-17.69 1095.08-178.84" stroke-width=".806"/><path class="st3" d="M-495.92 774.62s96.23-100.31 332.39-204.61 437.61-57.81 698.12-172.87S726.91-35.9 1087.82-195.3" stroke-width=".837"/><path class="st3" d="M-497.7 770.59s90.32-113 325.79-217 445.08-33.08 708.46-149.4 187.07-458.31 544-615.95" stroke-width=".869"/><path class="st3" d="M-499.48 766.57s84.42-125.69 319.19-229.38 452.56-8.34 718.8-125.93 181.81-483.58 534.77-639.47" stroke-width=".901"/><path class="st3" d="M-501.26 762.54s78.52-138.38 312.59-241.76 460.03 16.4 729.14-102.46 176.56-508.86 525.54-662.99" stroke-width=".932"/><path class="st3" d="M-503.04 758.52s72.61-151.06 306-254.14 467.5 41.13 739.48-78.99 171.3-534.13 516.3-686.51" stroke-width=".964"/><path class="st3" d="M-504.81 754.49s66.71-163.75 299.4-266.52 474.98 65.87 749.82-55.52 166.04-559.41 507.07-710.02" stroke-width=".996"/><path class="st3" d="M-506.59 750.47s60.81-176.44 292.8-278.9 482.45 90.61 760.16-32.05 160.79-584.68 497.84-733.54" stroke-width="1.028"/><path class="st3" d="M-508.37 746.44s54.9-189.13 286.2-291.28 489.92 115.34 770.5-8.57 155.53-609.95 488.61-757.06" stroke-width="1.059"/><path class="st3" d="M-510.15 742.41s49-201.82 279.6-303.66c230.6-101.85 497.4 140.08 780.84 14.9s150.27-635.23 479.38-780.58" stroke-width="1.091"/><path class="st3" d="M-511.92 738.39s43.1-214.5 273.01-316.04c229.9-101.55 504.86 164.81 791.17 38.36s145.02-660.5 470.15-804.1" stroke-width="1.123"/></g><path class="st36" d="M506.55 691.2h-7.09v-1.62h.9c-.73-.41-1.11-1.3-1.11-2.1 0-.93.42-1.75 1.25-2.13-.93-.55-1.25-1.38-1.25-2.3 0-1.28.82-2.5 2.69-2.5h4.6v1.63h-4.32c-.83 0-1.46.42-1.46 1.37 0 .89.7 1.47 1.57 1.47h4.21v1.66h-4.32c-.82 0-1.46.41-1.46 1.37 0 .9.67 1.47 1.57 1.47h4.21v1.68zM504.53 672.8c1.24.38 2.24 1.5 2.24 3.2 0 1.92-1.4 3.63-3.8 3.63-2.24 0-3.73-1.66-3.73-3.45 0-2.18 1.44-3.47 3.68-3.47.28 0 .51.03.54.04v5.18c1.08-.04 1.85-.89 1.85-1.94 0-1.02-.54-1.54-1.24-1.78l.46-1.41zm-2.3 1.62c-.83.03-1.57.58-1.57 1.75 0 1.06.82 1.67 1.57 1.73v-3.48zM502.49 669.98l-.28-1.82c-.06-.41-.26-.52-.51-.52-.6 0-1.08.41-1.08 1.34 0 .89.57 1.38 1.28 1.46l-.35 1.54c-1.22-.13-2.32-1.24-2.32-2.99 0-2.18 1.24-3.01 2.65-3.01h3.52c.64 0 1.06-.07 1.14-.09v1.57c-.04.01-.33.07-.9.07.54.34 1.12 1.03 1.12 2.18 0 1.49-1.02 2.4-2.14 2.4-1.26.01-1.95-.92-2.13-2.13zm1.12-2.35h-.32l.28 1.85c.09.52.38.95.96.95.48 0 .92-.36.92-1.03 0-.95-.46-1.77-1.84-1.77zM506.55 662.83v1.69h-7.09v-1.65h.95c-.82-.47-1.15-1.31-1.15-2.1 0-1.73 1.25-2.56 2.81-2.56h4.48v1.69h-4.19c-.87 0-1.57.39-1.57 1.46 0 .96.74 1.47 1.67 1.47h4.09zM496.08 652.99h1.44c-.03.1-.07.29-.07.61 0 .44.2 1.05 1.08 1.05h.93v-4.72h7.09v1.66h-5.62v3.06h5.62v1.7h-5.62v1.24h-1.47v-1.24h-.98c-1.59 0-2.55-1.02-2.55-2.48.01-.42.1-.77.15-.88zm-.23-2.23c0-.61.5-1.11 1.11-1.11.6 0 1.09.5 1.09 1.11 0 .61-.5 1.09-1.09 1.09-.61 0-1.11-.48-1.11-1.09zM506.55 646.63v1.69h-7.09v-1.65h.95c-.82-.47-1.15-1.31-1.15-2.1 0-1.73 1.25-2.56 2.81-2.56h4.48v1.69h-4.19c-.87 0-1.57.39-1.57 1.46 0 .96.74 1.47 1.67 1.47h4.09zM502.49 638.84l-.28-1.82c-.06-.41-.26-.52-.51-.52-.6 0-1.08.41-1.08 1.34 0 .89.57 1.38 1.28 1.46l-.35 1.54c-1.22-.13-2.32-1.24-2.32-2.99 0-2.18 1.24-3.01 2.65-3.01h3.52c.64 0 1.06-.07 1.14-.09v1.57c-.04.01-.33.07-.9.07.54.33 1.12 1.03 1.12 2.18 0 1.49-1.02 2.4-2.14 2.4-1.26.01-1.95-.92-2.13-2.13zm1.12-2.35h-.32l.28 1.85c.09.52.38.95.96.95.48 0 .92-.36.92-1.03 0-.95-.46-1.77-1.84-1.77zM506.55 631.69v1.69h-7.09v-1.65h.95c-.82-.47-1.15-1.31-1.15-2.1 0-1.73 1.25-2.56 2.81-2.56h4.48v1.69h-4.19c-.87 0-1.57.39-1.57 1.46 0 .96.74 1.47 1.67 1.47h4.09zM503 624.47c1.43 0 2.23-.92 2.23-1.98 0-1.11-.77-1.62-1.31-1.78l.54-1.49c1.11.33 2.32 1.4 2.32 3.26 0 2.08-1.62 3.67-3.77 3.67-2.18 0-3.76-1.59-3.76-3.63 0-1.91 1.19-2.96 2.33-3.25l.55 1.51c-.63.16-1.32.64-1.32 1.72-.01 1.05.76 1.97 2.19 1.97zM504.53 612.11c1.24.38 2.24 1.5 2.24 3.2 0 1.92-1.4 3.63-3.8 3.63-2.24 0-3.73-1.66-3.73-3.45 0-2.18 1.44-3.47 3.68-3.47.28 0 .51.03.54.04v5.18c1.08-.04 1.85-.89 1.85-1.94 0-1.02-.54-1.54-1.24-1.78l.46-1.41zm-2.3 1.61c-.83.03-1.57.58-1.57 1.75 0 1.06.82 1.67 1.57 1.73v-3.48zM501.02 610.91c0 .02-.01.03-.03.03h-1.57c-.01 0-.02.01-.02.02v.36c0 .02-.01.03-.03.03h-.07c-.02 0-.03-.01-.03-.03v-.92c0-.02.01-.03.03-.03h.07c.02 0 .03.01.03.03v.36c0 .01.01.02.02.02H501c.02 0 .03.01.03.03v.1zM499.32 610.11c-.02 0-.03-.01-.03-.03v-.1c0-.02.01-.03.03-.04l1.16-.41v-.01l-1.16-.41c-.02-.01-.03-.02-.03-.04v-.1c0-.02.01-.03.03-.03H501c.02 0 .03.01.03.03v.09c0 .02-.01.03-.03.03h-1.33v.01l1.02.36c.02.01.03.02.03.03v.06c0 .02-.01.03-.03.03l-1.02.36v.01H501c.02 0 .03.01.03.03v.09c0 .02-.01.03-.03.03h-1.68z"/><path d="M504.7 695.31c-.02.58-2.31 1.27-3.55 1.65-2.5.75-4.86 1.47-4.86 3.42 0 1.75 1.9 2.49 3.85 3.11.22.07.66.21 1.91.58.16.05.31.09.47.13 1.1.31 2.06.59 2.06 1.27 0 .66-1.04 1-2.1 1.29-.44.12-2.06.6-2.25.66-1.99.63-3.93 1.38-3.93 3.14 0 1.96 2.36 2.67 4.87 3.42 1.23.37 3.53 1.06 3.55 1.63l-.02.66h1.85l.01-.61c0-1.99-2.36-2.7-4.86-3.45-.32-.1-.66-.18-.99-.27-1.24-.31-2.42-.61-2.42-1.38 0-.73 1.3-1.08 2.46-1.39.06-.01 1.74-.51 2.12-.63 1.79-.58 3.7-1.34 3.7-3.07 0-1.74-1.89-2.49-3.83-3.11-.34-.11-2.06-.62-2.21-.66-1.18-.32-2.24-.66-2.24-1.33 0-.77 1.17-1.07 2.42-1.38.33-.08.67-.17.99-.27 2.5-.75 4.86-1.47 4.86-3.46l-.01-.61h-1.85v.66z" fill="#48a7de"/>';
  }

  function _generateSVGBorderText(PositionParams memory _params) private pure returns (string memory) {
    string memory _fromText = string(abi.encodePacked(_params.fromToken, ' - ', _params.fromSymbol));
    string memory _toText = string(abi.encodePacked(_params.toToken, ' - ', _params.toSymbol));

    return
      string(
        abi.encodePacked(
          _generateTextWithPath('-100', _fromText),
          _generateTextWithPath('0', _fromText),
          _generateTextWithPath('50', _toText),
          _generateTextWithPath('-50', _toText)
        )
      );
  }

  function _generateTextWithPath(string memory _offset, string memory _text) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<text text-rendering="optimizeSpeed"><textPath startOffset="',
          _offset,
          '%" xlink:href="#text-path-a" class="st46 st38 st47">',
          _text,
          '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" dur="60s" repeatCount="indefinite" /></textPath></text>'
        )
      );
  }

  function _generateSVGCardMantle(PositionParams memory _params) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<text><tspan x="68.3549" y="146.2414" class="st36 st38 st39 st40">',
          _params.fromSymbol,
          unicode'<tspan style="font-size: 40px;" dy="-5"> ➔ </tspan><tspan y="146.2414">',
          _params.toSymbol,
          '</tspan></tspan></text><text x="68.3549" y="225.9683" class="st36 st49 st50">',
          _params.swapInterval,
          '</text>'
        )
      );
  }

  function _generageSVGProgressArea(PositionParams memory _params) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<text text-rendering="optimizeSpeed"><textPath xlink:href="#text-path-executed"><tspan class="st38 st58" fill="#d1dbe0" style="text-shadow:#214c64 0px 0px 5px">Executed*: ',
          _params.swapsExecuted.toString(),
          _params.swapsExecuted != 1 ? ' swaps' : ' swap',
          '</tspan></textPath></text><text text-rendering="optimizeSpeed"><textPath xlink:href="#text-path-left" startOffset="30%" ><tspan class="st38 st58" alignment-baseline="hanging" fill="#153041" stroke="#000" stroke-width="0.5">Left: ',
          _params.swapsLeft.toString(),
          _params.swapsLeft != 1 ? ' swaps' : ' swap',
          '</tspan></textPath></text>'
        )
      );
  }

  function _generateSVGPositionData(PositionParams memory _params) private pure returns (string memory) {
    string memory _toWithdraw = _amountToReadable(_params.toWithdraw, _params.toDecimals, _params.toSymbol);
    string memory _swapped = _amountToReadable(_params.rate * _params.swapsExecuted, _params.fromDecimals, _params.fromSymbol);
    string memory _remaining = _amountToReadable(_params.remaining, _params.fromDecimals, _params.fromSymbol);
    string memory _rate = _amountToReadable(_params.rate, _params.fromDecimals, _params.fromSymbol);
    return
      string(
        abi.encodePacked(
          '<text transform="matrix(1 0 0 1 68.3549 775.8853)"><tspan x="0" y="0" class="st36 st38 st44">Id: ',
          _params.tokenId,
          '</tspan><tspan x="0" y="52.37" class="st36 st38 st44">To Withdraw: ',
          _toWithdraw,
          '</tspan><tspan x="0" y="104.73" class="st36 st38 st44">Swapped*: ',
          _swapped,
          '</tspan><tspan x="0" y="157.1" class="st36 st38 st44">Remaining: ',
          _remaining,
          '</tspan><tspan x="0" y="209.47" class="st36 st38 st44">Rate: ',
          _rate,
          '</tspan></text><text><tspan x="68.3554" y="1050.5089" class="st36 st38 st48">* since start or last edit / withdraw</tspan></text>'
        )
      );
  }

  function _generateSVGLinesAndMainLogo(uint32 _percentage) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<path class="st1" d="M68.35 175.29h440.12M68.35 249.38h440.12M68.35 737.58h440.12M68.35 792.11h440.12M68.35 844.47h440.12M68.35 896.82h440.12M68.35 949.17h440.12M68.35 1001.53h440.12"/><circle cx="290.35" cy="488.04" r="164.57" fill="url(#SVGID_3)"/><circle transform="rotate(-45.001 290.349 488.046)" class="st1" cx="290.35" cy="488.04" r="177.22"/><circle class="st52" cx="290.35" cy="488.04" r="119.5" stroke-width="21" fill="none" stroke-linecap="round"/><path class="st55" d="M359.92 508.63c-3.97-.13-8.71-15.84-11.26-24.3-5.16-17.12-10.04-33.3-23.44-33.3-11.95 0-17.08 13.02-21.31 26.36-.48 1.5-1.41 4.55-3.94 13.05-.32 1.07-.62 2.13-.92 3.18-2.15 7.55-4.01 14.08-8.73 14.08-4.54 0-6.85-7.09-8.83-14.35-.81-2.99-4.11-14.12-4.51-15.4-4.29-13.62-9.47-26.93-21.49-26.93-13.4 0-18.28 16.18-23.44 33.31-2.55 8.44-7.28 24.16-11.19 24.29l-4.52-.11v12.69l4.21.1c13.6 0 18.48-16.18 23.64-33.31.66-2.2 1.25-4.54 1.82-6.8 2.15-8.52 4.18-16.56 9.47-16.56 5.03 0 7.4 8.93 9.49 16.81.1.38 3.51 11.92 4.35 14.52 3.95 12.26 9.15 25.34 20.98 25.34 11.95 0 17.06-12.95 21.27-26.22.74-2.33 4.27-14.12 4.55-15.15 2.16-8.07 4.49-15.3 9.08-15.3 5.29 0 7.32 8.04 9.47 16.56.57 2.26 1.16 4.6 1.82 6.8 5.17 17.13 10.05 33.31 23.68 33.3l4.17-.1V508.5l-4.42.13z"/><circle class="cls-79" cx="290.35" cy="488.04" r="119.5" stroke-width="21" stroke-dasharray="750.84" stroke-dashoffset="562" fill="none" stroke-linecap="round"/><circle class="st57" r="13.79"><animateMotion path="M290.35,368.77 a 119.5,119.5 0 1,1 0,239 a 119.5,119.5 0 1,1 0,-239" calcMode="linear" fill="freeze" dur="2s" keyTimes="0;1" keyPoints="0;',
          _percentage == 100 ? '1' : '0.',
          _percentage < 10 ? '0' : '',
          _percentage == 100 ? '' : _percentage.toString(),
          '"/></circle>'
        )
      );
  }

  function _amountToReadable(
    uint256 _amount,
    uint8 _decimals,
    string memory _symbol
  ) private pure returns (string memory) {
    return string(abi.encodePacked(DescriptorUtils.fixedPointToDecimalString(_amount, _decimals), ' ', _symbol));
  }
}

interface IDCAPositionGetter {
  /// @notice The position of a certain user
  struct UserPosition {
    // The token that the user deposited and will be swapped in exchange for "to"
    IERC20Metadata from;
    // The token that the user will get in exchange for their "from" tokens in each swap
    IERC20Metadata to;
    // How frequently the position's swaps should be executed
    uint32 swapInterval;
    // How many swaps were executed since deposit, last modification, or last withdraw
    uint32 swapsExecuted;
    // How many "to" tokens can currently be withdrawn
    uint256 swapped;
    // How many swaps left the position has to execute
    uint32 swapsLeft;
    // How many "from" tokens there are left to swap
    uint256 remaining;
    // How many "from" tokens need to be traded in each swap
    uint120 rate;
  }

  /**
   * @notice Returns a user position
   * @param positionId The id of the position
   * @return The position itself
   */
  function userPosition(uint256 positionId) external view returns (UserPosition memory);
}
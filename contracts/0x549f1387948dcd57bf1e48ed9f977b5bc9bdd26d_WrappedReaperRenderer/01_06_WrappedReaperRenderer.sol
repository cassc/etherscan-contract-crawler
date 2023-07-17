/// SPDX-License-Identifier CC0-1.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";

import {IWrappedReaperRenderer} from "./IWrappedReaperRenderer.sol";

import "./WrappedReaperUtils.sol";

/// @title WrappedReaperRenderer.sol
/// @author unknown
/// @notice Decoupled on-chain renderer implementation.
/// @dev Ensures EIP-170 compliance (this contains a lot of hardcoded variables which increase deployment size).
contract WrappedReaperRenderer is IWrappedReaperRenderer {

  /// @notice Asserts the backgroundColor for a given saturation.
  /// @param saturation_ Generative saturation value, controlling colour intensity.
  /// @return The backgroundColor.
  function backgroundColor(uint256 saturation_) public pure returns (uint24) {
    uint24[4] memory backgroundColors = [0xFFFFFF, 0xF8F0FF, 0xE5DBF7, 0xD7C3F8];
    return backgroundColors[saturation_];
  }

  /// @notice Asserts the shadowColor for a given saturation.
  /// @param saturation_ Generative saturation value, controlling colour intensity.
  /// @return The shadowColor.
  function shadowColor(uint256 saturation_) public pure returns (uint24) {
    uint24[4] memory shadowColors = [0xD7D7D7, 0xCBC1D3, 0xC8BAE3, 0xB499E3];
    return shadowColors[saturation_];
  }

  /// @notice Asserts the blockDeepColor for a given saturation. This is the darkest component of the block.
  /// @param saturation_ Generative saturation value, controlling colour intensity.
  /// @return The blockDeepColor.
  function blockDeepColor(uint256 saturation_) public pure returns (uint24) {
    uint24[4] memory blockDeepColors = [0x6B6B6B, 0xB3A7C0, 0x8566AE, 0x6800E6];
    return blockDeepColors[saturation_];
  }

  /// @notice Asserts the blockAccentColor for a given saturation.
  /// @param saturation_ Generative saturation value, controlling colour intensity.
  /// @return The blockAccentColor.
  function blockAccentColor(uint256 saturation_) public pure returns (uint24) {
    uint24[4] memory blockAccentColors = [0x0, 0x85729B, 0x6E5097, 0x4B00A0];
    return blockAccentColors[saturation_];
  }

  /// @notice Asserts the blockFillColor for a given saturation.
  /// @param saturation_ Generative saturation value, controlling colour intensity.
  /// @return The blockFillColor.
  function blockFillColor(uint256 saturation_) public pure returns (uint24) {
    uint24[4] memory blockFillColors = [0xffffff, 0xF8F5FA, 0xF2E9FD, 0xEADFFE];
    return blockFillColors[saturation_];
  }

  /// @notice Renders text centrally to the vector image.
  /// @dev This allows us to render SVG elements statically instead of via nested groups, which eases generation.
  /// @param children The text to render.
  /// @param transform Transform to apply to child nodes.
  /// @param textColor Color to render the text in.
  /// @param fontSize Size of the text to render.
  /// @param y Vertical placement of the rendered text.
  /// @return SVG child string.
  function _renderCenterText(
    string memory children,
    string memory transform,
    uint24 textColor,
    string memory fontSize,
    uint256 y
  ) private pure returns (bytes memory) {
    return abi.encodePacked('<text x="111%" y="', Strings.toString(y), '" class="t" transform=" ', transform, '"><tspan fill="', WrappedReaperUtils.color(textColor), '" font-size="', fontSize, '">', children, '</tspan></text>');
  }

  /// @notice Renders text centrally in the SVG. We render text twice, with the second render pass being executed
  ///         at a separate offset and color, to provide the illusion of depth.
  /// @param children Text to render.
  /// @param translation How much to offset the second rendering pass. We use different values to provide a sense of
  ///                    perspective to the viewer, depending upon vertical placement in the token.
  /// @param fontSize Size of the text to render.
  /// @param saturation_ Generative attribute controlling colour depth.
  /// @param y Vertical text placement (this applies to the text rendered independently to the relative transform).
  /// @return SVG child string.
  function _renderEmbossedText(
    string memory children,
    string memory translation,
    string memory fontSize,
    uint256 saturation_,
    uint256 y
  ) private pure returns (bytes memory) {
    return abi.encodePacked(
      _renderCenterText(children, "", blockAccentColor(saturation_), fontSize, y),
      _renderCenterText(children, translation, blockFillColor(saturation_), fontSize, y)
    );
  }

  function _path(string memory className, string memory data) private pure returns (bytes memory) {
    return abi.encodePacked('<path class="', className, '" d="m', data, 'z"/>');
  }

  /// @notice Renders the Crown of Immortality.
  /// @param className Class configuration to control styling.
  /// @param transform Transform to apply.
  /// @return SVG child string.
  function _renderCrownOfImmortality(
    string memory className,
    string memory transform
  ) private pure returns (bytes memory) {
    bytes memory result = abi.encodePacked('<g transform="', transform, '">');
    result = abi.encodePacked(result, _path(className, "495.39 492.85 7.31 6.59-9.29-3.26 0.5 9.83-4.27-8.86-6.59 7.31 3.26-9.29-9.83 0.5 8.88-4.26-7.33-6.6 9.31 3.27-0.52-9.84 4.27 8.86 6.59-7.31-3.24 9.3 9.81-0.51-8.87 4.27"));
    result = abi.encodePacked(result, _path(className, "474.5 474.32 2.54 9.51-6.01-7.79-4.94 8.51 1.25-9.76-9.51 2.54 7.79-6.01-8.51-4.94 9.77 1.27-2.54-9.53 6.02 7.81 4.93-8.53-1.25 9.76 9.51-2.53-7.78 6.03 8.5 4.92-9.76-1.25"));
    result = abi.encodePacked(result, _path(className, "467.16 447.34-3.08 9.35-0.77-9.81-8.79 4.42 6.39-7.48-9.35-3.08 9.81-0.77-4.42-8.79 7.48 6.41 3.08-9.37 0.76 9.83 8.79-4.44-6.39 7.48 9.35 3.08-9.81 0.79 4.42 8.77-7.48-6.39"));
    result = abi.encodePacked(result, _path(className, "475.82 420.74-7.7 6.13 4.74-8.62-9.77-1.12 9.45-2.75-6.13-7.7 8.62 4.74 1.12-9.78 2.74 9.46 7.72-6.14-4.75 8.64 9.79 1.11-9.45 2.75 6.13 7.7-8.64-4.73-1.11 9.76-2.75-9.45"));
    result = abi.encodePacked(result, _path(className, "497.68 403.24-9.8 0.89 8.7-4.6-7.55-6.31 9.41 2.89-0.89-9.8 4.6 8.7 6.31-7.55-2.9 9.41 9.82-0.89-8.72 4.61 7.57 6.3-9.41-2.88 0.89 9.8-4.62-8.69-6.29 7.55 2.89-9.41"));
    result = abi.encodePacked(result, _path(className, "525.5 400.58-8.68-4.63 9.8 0.92-2.86-9.42 6.28 7.57 4.63-8.69-0.92 9.8 9.41-2.86-7.59 6.28 8.7 4.63-9.82-0.92 2.88 9.42-6.29-7.57-4.63 8.69 0.9-9.81-9.4 2.87 7.57-6.29"));
    result = abi.encodePacked(result, _path(className, "550.24 413.62-4.73-8.63 7.7 6.14 2.77-9.44 1.11 9.78 8.63-4.73-6.14 7.69 9.44 2.77-9.79 1.1 4.74 8.65-7.71-6.15-2.75 9.46-1.11-9.78-8.63 4.73 6.12-7.71-9.43-2.75 9.78-1.11"));
    result = abi.encodePacked(result, _path(className, "563.77 438.09 0.77-9.81 3.08 9.35 7.49-6.39-4.43 8.79 9.81 0.77-9.35 3.08 6.39 7.49-8.79-4.45-0.77 9.83-3.08-9.37-7.48 6.4 4.42-8.79-9.81-0.77 9.35-3.1-6.38-7.47 8.79 4.43"));
    result = abi.encodePacked(result, _path(className, "561.69 466.02 6.07-7.75-2.61 9.49 9.77-1.18-8.55 4.87 7.75 6.07-9.49-2.61 1.18 9.77-4.86-8.57-6.08 7.76 2.62-9.51-9.78 1.19 8.55-4.87-7.75-6.07 9.5 2.59-1.19-9.75 4.87 8.55"));
    result = abi.encodePacked(result, _path(className, "544.63 488.17 9.31-3.19-7.36 6.54 8.83 4.33-9.82-0.57 3.19 9.31-6.54-7.36-4.33 8.83 0.59-9.83-9.33 3.2 7.37-6.55-8.85-4.32 9.82 0.57-3.19-9.31 6.56 7.35 4.32-8.82"));
    result = abi.encodePacked(result, '</g>');
    return result;
  }

  /// @notice Renders the shorthand address responsible for minting the token.
  /// @param saturation_ The generative saturation attribute.
  /// @param minter Address responsible for minting.
  /// @return SVG child string.
  function _renderMinter(uint256 saturation_, address minter) private pure returns (bytes memory) {
    return _renderEmbossedText(WrappedReaperUtils.short(minter), "translate(-1.5, 1.8)", "26px", saturation_, 540);
  }

  function _g(string memory transform, bytes memory children) private pure returns (bytes memory) {
    return abi.encodePacked('<g transform="', transform, '">', children, '</g>');
  }

  /// @notice Renders the logo of $RG.
  /// @param stroke The color to use for rendering strokes on the logo.
  /// @param className Class configuration to control styling.
  /// @param transform Transform to apply to the logo child node.
  /// @return SVG child string.
  function _renderReaper(
    string memory stroke,
    string memory className,
    string memory transform
  ) private pure returns (bytes memory) {
    bytes memory result = abi.encodePacked('<polyline stroke="', stroke, '" class="', className, '" points="477.72 633.47 502.67 611.17 502.67 707.59"/>');

    result = abi.encodePacked(result, '<ellipse stroke="', stroke, '" class="', className, '" cx="532.59" cy="620.32" rx="9.44" ry="9.14"/>');
    result = abi.encodePacked(result, '<line stroke="', stroke, '" class="', className, '" x1="532.59" x2="532.59" y1="683.49" y2="629.47"/>');
    result = abi.encodePacked(result, '<line stroke="', stroke, '" class="', className, '" x1="545.07" x2="532.59" y1="707.59" y2="683.49"/>');
    result = abi.encodePacked(result, '<line stroke="', stroke, '" class="', className, '" x1="520.12" x2="532.59" y1="707.59" y2="683.49"/>');
    result = abi.encodePacked(result, '<line stroke="', stroke, '" class="', className, '" x1="545.07" x2="532.59" y1="635.27" y2="659.39"/>');
    result = abi.encodePacked(result, '<line stroke="', stroke, '" class="', className, '" x1="520.12" x2="532.59" y1="635.27" y2="659.39"/>');
    result = abi.encodePacked(result, '<rect stroke="', stroke, '" class="', className, '" x="457.61" y="599.3" width="116.84" height="116.84"/>');

    return _g(transform, result);
  }

  /// @notice Computes the substring of a string.
  /// @param str The source string.
  /// @param start The start index to begin the slice.
  /// @param end The end index of the string to slice.
  /// @return The substring.
  function substring(string memory str, uint256 start, uint256 end) public pure returns (string memory) {
    bytes memory str_ = bytes(str);

    require(start <= end && str_.length >= end);

    bytes memory result = new bytes(end - start);

    for (uint256 i = 0; i < result.length; ++i)
      result[i] = str_[start + i];

    return string(result);
  }

  /// @notice Converts the input value into a corresponding string grouped into thousands.
  /// @dev Works up to a maximum of 999,999,999. Unrolled loop.
  /// @param v The value to group.
  /// @return The value as a string grouped into thousands.
  function grouping(uint256 v) public pure returns (string memory) {
    string memory v_ = Strings.toString(v);
    uint256 len = bytes(v_).length;

    require(len <= 9);

    // slither-disable-next-line incorrect-equality
    if (len == 9)
      return string(abi.encodePacked(substring(v_, 0, 3), ",", substring(v_, 3, 6), ",", substring(v_, 6, 9)));
    // slither-disable-next-line incorrect-equality
    if (len == 8)
      return string(abi.encodePacked(substring(v_, 0, 2), ",", substring(v_, 2, 5), ",", substring(v_, 5, 8)));
    // slither-disable-next-line incorrect-equality
    if (len == 7)
      return string(abi.encodePacked(substring(v_, 0, 1), ",", substring(v_, 1, 4), ",", substring(v_, 4, 7)));
    // slither-disable-next-line incorrect-equality
    if (len == 6)
      return string(abi.encodePacked(substring(v_, 0, 3), ",", substring(v_, 3, 6)));
    // slither-disable-next-line incorrect-equality
    if (len == 5)
      return string(abi.encodePacked(substring(v_, 0, 2), ",", substring(v_, 2, 5)));
    // slither-disable-next-line incorrect-equality
    if (len == 4)
      return string(abi.encodePacked(substring(v_, 0, 1), ",", substring(v_, 1, 4)));

    return v_;
  }

  /// @notice Defines the raw SVG base and background image.
  /// @param saturation_ Color vividness (0 -> 3).
  /// @param children SVG child nodes.
  /// @return SVG XML string.
  function _canvas(uint256 saturation_, bytes memory children) private pure returns (bytes memory) {
    bytes memory result = (abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 466.67 466.67" preserveAspectRatio="xMinYMin meet">'));

    result = (abi.encodePacked(result, '<defs><style>.r{fill: none;stroke-miterlimit:10;stroke-width:2px}.t{dominant-baseline:middle;text-anchor:middle;font-family:Trebuchet MS, Trebuchet MS}.s{fill:', WrappedReaperUtils.color(shadowColor(saturation_)), '}.a{fill:', WrappedReaperUtils.color(blockAccentColor(saturation_)), '}.b{fill:', WrappedReaperUtils.color(blockFillColor(saturation_)), '}</style></defs>'));
    result = (abi.encodePacked(result, '<rect fill="', WrappedReaperUtils.color(backgroundColor(saturation_)), '" width="466.67" height="466.67" stroke-width="1"/>'));

    return (abi.encodePacked(result, children, '</svg>'));
  }

  /// @notice Computes a raw WrappedReaper Burn token SVG for the provided parameters.
  /// @param saturation_ Color vividness (0 -> 3).
  /// @return SVG XML string.
  function burnTokenURIDataImage(uint256 saturation_) public pure returns (bytes memory) {
    bytes memory result = abi.encodePacked("");

    result = abi.encodePacked(result, "<defs>");
    result = abi.encodePacked(result, '<filter style="color-interpolation-filters:sRGB" id="scorch" x="-0.087990949" y="-0.042057798" width="1.1759819" height="1.0841156">');
    result = abi.encodePacked(result, '<feGaussianBlur stdDeviation="5.9126255"/>');
    result = abi.encodePacked(result, "</filter>");
    result = abi.encodePacked(result, "</defs>");
    result = abi.encodePacked(result, '<rect fill="#eadffe" stroke="#4b00a0" stroke-miterlimit="10" x="148.17999" y="63.957001" width="161.27" height="337.39999" stroke-width="1" id="rect692" style="stroke:none;fill:#402626;fill-opacity:0.06735751;filter:url(#scorch)"/>');

    return _canvas(saturation_, result);
  }

  /// @notice Computes a raw WrappedReaper token SVG for the provided parameters.
  /// @param tokenId Identifier of the token.
  /// @param stake The amount of $RG staked inside the token.
  /// @param mintBlock The block depth when the token was minted.
  /// @param minter The address responsible for minting the token.
  /// @param saturation_ Color vividness (0 -> 3).
  /// @param phase_ Shadow orientation (0 -> 3).
  /// @return SVG XML string.
  function barTokenURIDataImage(
    uint256 tokenId,
    uint256 stake,
    uint256 mintBlock,
    address minter,
    uint256 saturation_,
    uint256 phase_
  ) public pure returns (bytes memory) {

    bytes memory result = "";

    if (phase_ == 3)
        result = abi.encodePacked(result, _g("scale(0.46667)", _g("translate(-0.3, 0)", bytes('<polygon class="s" points="658.78,138.77 317.04,138.77 266.59,68.46 608.33,68.46"/>'))));

    result =   (abi.encodePacked(result, '<rect fill="', WrappedReaperUtils.color(blockFillColor(saturation_)), '" stroke="', WrappedReaperUtils.color(blockAccentColor(saturation_)),'" stroke-miterlimit="10" x="160.18" y="45.957" width="161.27" height="337.4" stroke-width="1"/>'));
    result =   (abi.encodePacked(result, '<g transform="scale(0.46667)">'));
    result =     (abi.encodePacked(result, '<polyline fill="', WrappedReaperUtils.color(blockAccentColor(saturation_)), '" points="317.04 861.95 317.04 138.77 343.25 98.48 343.25 821.48"/>'));
    result =     (abi.encodePacked(result, '<polyline fill="', WrappedReaperUtils.color(blockDeepColor(saturation_)), '" stroke="', WrappedReaperUtils.color(blockDeepColor(saturation_)), '" points="317.04 861.95 343.25 821.48 688.81 821.48 662.82 861.95"/>'));

    result = abi.encodePacked(result, _renderEmbossedText(grouping(stake / 10 ** WrappedReaperUtils.DECIMALS), "translate(-2.5, 3)", "45px", saturation_, 160));
    result = abi.encodePacked(result, _renderEmbossedText("WRG", "translate(-2.5, 3)", "42px", saturation_, 210));
    result = abi.encodePacked(result, _renderEmbossedText(string(abi.encodePacked("BLOCK ", Strings.toString(mintBlock))), "translate(-1.5, 2)", "28px", saturation_, 285));
    result = abi.encodePacked(result, _renderEmbossedText(string(abi.encodePacked("#", Strings.toString(tokenId))), "translate(-1.5, 1.9)", "26px", saturation_, 320));

    result = abi.encodePacked(result, _g("translate(0,-6)", abi.encodePacked(_renderCrownOfImmortality("a", ""), _renderCrownOfImmortality("b", "translate(-2,2)"))));
    result = abi.encodePacked(result, _renderMinter(saturation_, minter));
    result = abi.encodePacked(result, _g("translate(0,-8)", abi.encodePacked(_renderReaper(WrappedReaperUtils.color(blockAccentColor(saturation_)), "r", ""), _renderReaper(WrappedReaperUtils.color(blockFillColor(saturation_)), "r", " translate(-2,1)"))));

    result = abi.encodePacked(result, _renderEmbossedText("REAPER'S GAMBIT", "translate(-2,1)", "28px", saturation_, 750));
    result = abi.encodePacked(result, _renderEmbossedText("EST. 17119930", "translate(-2,1)", "22px", saturation_, 783));

    if (phase_ == 3) {
        result = abi.encodePacked(result, '<polygon class="s" points="266.59,68.46 317.04,138.77 317.04,861.95 266.59,791.65"/>');
    } else if (phase_ == 2) {
        result = abi.encodePacked(result, '<polyline class="s" points="662.75 861.95 579.56 881.36 233.85 881.36 317.04 861.95 233.85 881.36 233.85 158.17 317.04 138.77 317.04 861.95"/>');
    } else if (phase_ == 1) {
        result = abi.encodePacked(result, '<polygon class="s" points="317.04 861.95 317.04 138.77 282.8 192.78 282.8 901.52 637.41 901.52 662.82 861.95"/>');
    } else {
        result = abi.encodePacked(result, '<polygon class="s" points="662.79,861.95 317.04,861.95 317.04,138.77 285.84,220.96 285.84,944.15 631.59,944.15"/>');
    }

    result =   (abi.encodePacked(result, '</g>'));

    return _canvas(saturation_, result);
  }

}
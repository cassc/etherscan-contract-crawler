// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@solv/v2-solidity-utils/contracts/access/AdminControl.sol";
import "@solv/v2-solidity-utils/contracts/misc/Constants.sol";
import "@solv/v2-solidity-utils/contracts/misc/StringConvertor.sol";
import "@solv/v2-solidity-utils/contracts/misc/BokkyPooBahsDateTimeLibrary.sol";
import "@solv/v2-solidity-utils/contracts/openzeppelin/token/ERC20/ERC20Upgradeable.sol";
import "../interface/IVoucherSVG.sol";
import "../FlexibleDateVestingVoucher.sol";
import "../FlexibleDateVestingPool.sol";
import "../FlexibleDateVestingVoucherDescriptor.sol";

contract DefaultFlexibleDateVestingVoucherSVG is IVoucherSVG, AdminControl {

    using StringConvertor for uint256;
    using StringConvertor for bytes;

    struct SVGParams {
        address voucher;
        string underlyingTokenSymbol;
        uint256 tokenId;
        uint256 vestingAmount;
        uint64 startTime;
        uint64 endTime;
        uint8 stageCount; 
        uint8 claimType;
        uint8 underlyingTokenDecimals;
    }

    /// @dev voucher => claimType => background colors
    mapping(address => mapping(uint8 => string[])) public voucherBgColors;

    constructor(
        string[] memory linearBgColors_, 
        string[] memory onetimeBgColors_, 
        string[] memory stagedBgColors_
    ) {
        __AdminControl_init(_msgSender());
        setVoucherBgColors(address(0), linearBgColors_, onetimeBgColors_, stagedBgColors_);
    }

    function setVoucherBgColors(
        address voucher_,
        string[] memory linearBgColors_, 
        string[] memory onetimeBgColors_, 
        string[] memory stagedBgColors_
    )
        public 
        onlyAdmin 
    {
        voucherBgColors[voucher_][uint8(Constants.ClaimType.LINEAR)] = linearBgColors_;
        voucherBgColors[voucher_][uint8(Constants.ClaimType.ONE_TIME)] = onetimeBgColors_;
        voucherBgColors[voucher_][uint8(Constants.ClaimType.STAGED)] = stagedBgColors_;
    }
    
    function generateSVG(address voucher_, uint256 tokenId_) external view virtual override returns (string memory) {
        FlexibleDateVestingVoucher flexibleDateVestingVoucher = FlexibleDateVestingVoucher(voucher_);
        FlexibleDateVestingPool flexibleDateVestingPool = flexibleDateVestingVoucher.flexibleDateVestingPool();
        ERC20Upgradeable underlyingToken = ERC20Upgradeable(flexibleDateVestingPool.underlyingToken());

        FlexibleDateVestingVoucher.FlexibleDateVestingVoucherSnapshot memory snapshot = flexibleDateVestingVoucher.getSnapshot(tokenId_);

        SVGParams memory svgParams;
        svgParams.voucher = voucher_;
        svgParams.underlyingTokenSymbol = underlyingToken.symbol();
        svgParams.underlyingTokenDecimals = underlyingToken.decimals();

        svgParams.tokenId = tokenId_;
        svgParams.vestingAmount = snapshot.vestingAmount;
        svgParams.claimType = snapshot.slotSnapshot.claimType;

        svgParams.stageCount = uint8(snapshot.slotSnapshot.terms.length);
        svgParams.startTime = snapshot.slotSnapshot.startTime != 0 ? 
            snapshot.slotSnapshot.startTime : 
            snapshot.slotSnapshot.latestStartTime;
        
        svgParams.endTime = svgParams.startTime;
        for (uint256 i = 0; i < svgParams.stageCount; i++) {
            svgParams.endTime += snapshot.slotSnapshot.terms[i];
        }

        return _generateSVG(svgParams);
    }

    function _generateSVG(SVGParams memory params) internal view virtual returns (string memory) {
        return 
            string(
                abi.encodePacked(
                    '<svg width="600" height="400" viewBox="0 0 600 400" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                        _generateDefs(params),
                        '<g stroke-width="1" fill="none" fill-rule="evenodd">',
                            _generateBackground(),
                            _generateTitle(params),
                            _generateLegend(params),
                            _generateClaimType(params),
                        '</g>',
                    '</svg>'
                )
            );
    }

    function _generateDefs(SVGParams memory params) internal view virtual returns (string memory) {
        string memory color0 = voucherBgColors[params.voucher][params.claimType].length > 0 ?
                               voucherBgColors[params.voucher][params.claimType][0] :
                               voucherBgColors[address(0)][params.claimType][0];
        string memory color1 = voucherBgColors[params.voucher][params.claimType].length > 1 ?
                               voucherBgColors[params.voucher][params.claimType][1] :
                               voucherBgColors[address(0)][params.claimType][1];

        return 
            string(
                abi.encodePacked(
                    '<defs>',
                        '<linearGradient x1="0%" y1="75%" x2="100%" y2="30%" id="lg-1">',
                            '<stop stop-color="', color0,'" offset="0%"></stop>',
                            '<stop stop-color="', color1, '" offset="100%"></stop>',
                        '</linearGradient>',
                        '<rect id="path-2" x="16" y="16" width="568" height="368" rx="16"></rect>',
                        '<linearGradient x1="100%" y1="50%" x2="0%" y2="50%" id="lg-2">',
                            '<stop stop-color="#FFFFFF" offset="0%"></stop>',
                            '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                        '</linearGradient>',
                        params.claimType == uint8(Constants.ClaimType.ONE_TIME) ? 
                        abi.encodePacked(
                            '<linearGradient x1="50%" y1="0%" x2="50%" y2="100%" id="lg-3">',
                                '<stop stop-color="#FFFFFF" offset="0%"></stop>',
                                '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                            '</linearGradient>',
                            '<linearGradient x1="100%" y1="50%" x2="35%" y2="50%" id="lg-4">',
                                '<stop stop-color="#FFFFFF" offset="0%"></stop>',
                                '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                            '</linearGradient>',
                            '<linearGradient x1="50%" y1="0%" x2="50%" y2="100%" id="lg-5">',
                                '<stop stop-color="#FFFFFF" offset="0%"></stop>',
                                '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                            '</linearGradient>'
                        ) : 
                        abi.encodePacked(
                            '<linearGradient x1="0%" y1="50%" x2="100%" y2="50%" id="lg-3">',
                                '<stop stop-color="#FFFFFF" stop-opacity="0" offset="0%"></stop>',
                                '<stop stop-color="#FFFFFF" offset="100%"></stop>',
                            '</linearGradient>'
                        ),
                        '<path id="text-path-a" d="M30 12 H570 A18 18 0 0 1 588 30 V370 A18 18 0 0 1 570 388 H30 A18 18 0 0 1 12 370 V30 A18 18 0 0 1 30 12 Z" />',
                    '</defs>'
                )
            );
    }

    function _generateBackground() internal pure virtual returns (string memory) {
        return 
            string(
                abi.encodePacked(
                    '<rect fill="url(#lg-1)" x="0" y="0" width="600" height="400" rx="24"></rect>',
                    '<g text-rendering="optimizeSpeed" opacity="0.5" font-family="Arial" font-size="10" font-weight="500" fill="#FFFFFF">',
                        '<text><textPath startOffset="-100%" xlink:href="#text-path-a">In Crypto We Trust<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>',
                        '<text><textPath startOffset="0%" xlink:href="#text-path-a">In Crypto We Trust<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>',
                        '<text><textPath startOffset="50%" xlink:href="#text-path-a">Powered by Solv Protocol<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>',
                        '<text><textPath startOffset="-50%" xlink:href="#text-path-a">Powered by Solv Protocol<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>',
                    '</g>',
                    '<rect stroke="#FFFFFF" x="16.5" y="16.5" width="567" height="367" rx="16"></rect>',
                    '<mask id="mask-3" fill="white">',
                        '<use xlink:href="#path-2"></use>',
                    '</mask>',
                    '<path d="M404,-41 L855,225 M165,100 L616,366 M427,-56 L878,210 M189,84 L640,350 M308,14 L759,280 M71,154 L522,420 M380,-27 L831,239 M143,113 L594,379 M286,28 L737,294 M47,169 L498,435 M357,-14 L808,252 M118,128 L569,394 M262,42 L713,308 M24,183 L475,449 M333,0 L784,266 M94,141 L545,407 M237,57 L688,323 M0,197 L451,463 M451,-69 L902,197 M214,71 L665,337 M665,57 L214,323 M902,197 L451,463 M569,0 L118,266 M808,141 L357,407 M640,42 L189,308 M878,183 L427,449 M545,-14 L94,252 M784,128 L333,394 M616,28 L165,294 M855,169 L404,435 M522,-27 L71,239 M759,113 L308,379 M594,14 L143,280 M831,154 L380,420 M498,-41 L47,225 M737,100 L286,366 M475,-56 L24,210 M713,84 L262,350 M451,-69 L0,197 M688,71 L237,337" stroke="url(#lg-2)" opacity="0.2" mask="url(#mask-3)"></path>'
                )
            );
    }

    function _generateTitle(SVGParams memory params) internal view virtual returns (string memory) {
        string memory tokenIdStr = params.tokenId.toString();
        uint256 tokenIdLeftMargin = 488 - 20 * bytes(tokenIdStr).length;
        return 
            string(
                abi.encodePacked(
                    '<g transform="translate(40, 40)" fill="#FFFFFF" fill-rule="nonzero">',
                        '<text font-family="Arial" font-size="32">',
                            abi.encodePacked(
                                '<tspan x="', tokenIdLeftMargin.toString(), '" y="29"># ', tokenIdStr, '</tspan>'
                            ),
                        '</text>',
                        '<text font-family="Arial" font-size="36">',
                            '<tspan x="0" y="72">', _formatValue(params.vestingAmount, params.underlyingTokenDecimals), '</tspan>',
                        '</text>',
                        '<text font-family="Arial" font-size="24" font-weight="500">',
                            '<tspan x="0" y="26">', params.underlyingTokenSymbol, ' Flexible Voucher</tspan>',
                        '</text>',
                    '</g>'
                )
            );
    }

    function _generateLegend(SVGParams memory params) internal view virtual returns (string memory) {
        if (params.claimType == uint8(Constants.ClaimType.LINEAR)) {
            return 
                string(
                    abi.encodePacked(
                        '<g transform="translate(373, 142)">',
                            '<path d="M0,138 L138,0" stroke="url(#lg-3)" stroke-width="20" opacity="0.4" stroke-linecap="round" stroke-linejoin="round"></path>'
                            '<path d="M129.5,-8.5 C134,-13 142,-13 146.5,-8.5 C151,-4 151,4 146.5,8.5 C142,13 136,13 131,10 L10,131 C13,136 13,142 8.5,146.5 C4,151 -4,151 -8.5,146.5 C-13,142 -13,134 -8.5,129.5 C-4,125 2,125 7,128 L128,7 C125,2 125,-4 129.5,-8.5 Z" fill="#FFFFFF" fill-rule="nonzero"></path>',
                        '</g>'
                    )
                );
        } else if (params.claimType == uint8(Constants.ClaimType.ONE_TIME)) {
            return 
                string(
                    abi.encodePacked(
                        '<g transform="translate(431, 165)">',
                            '<path d="M0,146 L1,0" stroke="url(#lg-3)" stroke-width="20" opacity="0.4" stroke-linecap="round" stroke-linejoin="round"></path>',
                            '<path d="M1,-12 C8,-12 13,-7 13,0 C13,6 9,11 3,12 L2,146 L-1,146 L-1,12 C-7,11 -11,6 -11,-0 C-11,-7 -6,-12 1,-12 Z" fill="url(#lg-5)" fill-rule="nonzero"></path>',
                            '<path d="M117,217 L-415,-98" stroke="url(#lg-4)" stroke-width="2" opacity="0.2"></path>',
                        '</g>'
                    )
                );
        } else if (params.claimType == uint8(Constants.ClaimType.STAGED)) {
            return 
                string(
                    abi.encodePacked(
                        '<g transform="translate(346, 151)">',
                            '<path d="M0,164 L37,164 C39,164 41,162 41,160 L41,113 C41,111 43,109 45,109 L78,109 C80,109 82,107.5 82,105 L82,58.5 C82,56.5 84,54.5 86,54.5 L119,54.5 C121,54.5 123,53 123,50.5 L123,4 C123,2 125,0 127,0 L164,0 L164,0" stroke="url(#lg-3)" stroke-width="20" opacity="0.4" stroke-linecap="round" stroke-linejoin="round"></path>',
                            '<path d="M164,-12 C170.5,-12 176,-6.5 176,0 C176,6.5 170.5,12 164,12 C158,12 153,8 152,2 L127,2 C126,2 125,3 125,4 L125,4 L125,50.5 C125,54 122,56.5 119,56.5 L119,56.5 L86,56.5 C85,56.5 84,57.5 84,58.5 L84,58.5 L84,105 C84,108.5 81.5,111 78,111.3 L78,111.3 L45,111.3 C44,111.3 43,112 43,113 L43,113.3 L43,160 C43,163 40.5,166 37,166 L37,166 L12,166 C11,171.5 6,176 0,176 C-6.5,176 -12,170.5 -12,164 C-12,157.5 -6.5,152 0,152 C6,152 11,156 12,162 L37,162 C38,162 39,161 39,160 L39,160 L39,113.3 C39,110 41.5,107.5 45,107.3 L45,107.3 L78,107.3 C79,107.3 80,106.5 80,105.5 L80,105.3 L80,58.3 C80,55.5 82.5,53 85.8,52.7 L86,52.7 L119,52.7 C120,52.7 121,52 121,51 L121,51 L121,4 C121,0 123.5,-2 127,-2 L127,-2 L152,-2 C153.118542,-8 158,-12 164,-12 Z" fill="#FFFFFF" fill-rule="nonzero"></path>',
                        '</g>'
                    )
                );
        } else {
            revert("Invalid ClaimType");
        }
    }

    function _generateClaimType(SVGParams memory params) internal view virtual returns (string memory) {
        if (params.claimType == uint8(Constants.ClaimType.LINEAR)) {
            return 
                string(
                    abi.encodePacked(
                        '<g transform="translate(40, 255)">',
                            '<rect fill="#000000" opacity="0.2" x="0" y="0" width="240" height="105" rx="16"></rect>',
                            '<text fill-rule="nonzero" font-family="Arial" font-size="20" font-weight="500" fill="#FFFFFF">',
                                '<tspan x="31" y="31">Linear</tspan>',
                            '</text>',
                            '<text fill-rule="nonzero" font-family="Arial" font-size="14" font-weight="500" fill="#FFFFFF">',
                                '<tspan x="30" y="58">Start Date: ', uint256(params.startTime).dateToString(), '</tspan>',
                            '</text>',
                            '<text fill-rule="nonzero" font-family="Arial" font-size="14" font-weight="500" fill="#FFFFFF">',
                                '<tspan x="30" y="83">End Date: ', uint256(params.endTime).dateToString(), '</tspan>',
                            '</text>',
                        '</g>'
                    )
                );
        } else if (params.claimType == uint8(Constants.ClaimType.ONE_TIME)) {
            return 
                string(
                    abi.encodePacked(
                        '<g transform="translate(40, 281)">',
                            '<rect fill="#000000" opacity="0.2" x="0" y="0" width="240" height="80" rx="16"></rect>',
                            '<text fill-rule="nonzero" font-family="Arial" font-size="20" font-weight="500" fill="#FFFFFF">',
                                '<tspan x="31" y="31">One-time</tspan>',
                            '</text>',
                            '<text fill-rule="nonzero" font-family="Arial" font-size="14" font-weight="500" fill="#FFFFFF">',
                                '<tspan x="30" y="58">Vesting Date: ', uint256(params.endTime).dateToString(), '</tspan>',
                            '</text>',
                        '</g>'
                    )
                );
        } else if (params.claimType == uint8(Constants.ClaimType.STAGED)) {
            return 
                string(
                    abi.encodePacked(
                        '<g transform="translate(40, 255)">',
                            '<rect fill="#000000" opacity="0.2" x="0" y="0" width="240" height="105" rx="16"></rect>',
                            '<text fill-rule="nonzero" font-family="Arial" font-size="20" font-weight="500" fill="#FFFFFF">',
                                '<tspan x="31" y="31">', uint256(params.stageCount).toString(), ' Stages</tspan>',
                            '</text>',
                            '<text fill-rule="nonzero" font-family="Arial" font-size="14" font-weight="500" fill="#FFFFFF">',
                                '<tspan x="30" y="58">Start Date: ', uint256(params.startTime).dateToString(), '</tspan>',
                            '</text>',
                            '<text fill-rule="nonzero" font-family="Arial" font-size="14" font-weight="500" fill="#FFFFFF">',
                                '<tspan x="30" y="83">End Date: ', uint256(params.endTime).dateToString(), '</tspan>',
                            '</text>',
                        '</g>'
                    )
                );
        } else {
            revert("Invalid ClaimType");
        }
    }

    function _formatValue(uint256 value, uint8 decimals) private pure returns (bytes memory) {
        return value.uint2decimal(decimals).trim(decimals - 2).addThousandsSeparator();
    }

}
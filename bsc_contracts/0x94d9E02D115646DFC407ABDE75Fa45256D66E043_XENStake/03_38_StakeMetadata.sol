// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./StakeInfo.sol";
import "./DateTime.sol";
import "./FormattedStrings.sol";
import "./StakeSVG.sol";

/**
    @dev Library contains methods to generate on-chain NFT metadata
*/
library StakeMetadata {
    using DateTime for uint256;
    using StakeInfo for uint256;
    using Strings for uint256;

    // PRIVATE HELPERS

    // The following pure methods returning arrays are workaround to use array constants,
    // not yet available in Solidity

    /**
        @dev private helper to generate SVG gradients
     */
    function _commonCategoryGradients() private pure returns (StakeSVG.Gradient[] memory gradients) {
        StakeSVG.Color[] memory colors = new StakeSVG.Color[](3);
        colors[0] = StakeSVG.Color({h: 50, s: 10, l: 36, a: 1, off: 0});
        colors[1] = StakeSVG.Color({h: 50, s: 10, l: 12, a: 1, off: 50});
        colors[2] = StakeSVG.Color({h: 50, s: 10, l: 5, a: 1, off: 100});
        gradients = new StakeSVG.Gradient[](1);
        gradients[0] = StakeSVG.Gradient({colors: colors, id: 0, coords: [uint256(50), 0, 50, 100]});
    }

    // PUBLIC INTERFACE

    /**
        @dev public interface to generate SVG image based on XENFT params
     */
    function svgData(uint256 tokenId, uint256 info, address token) external view returns (bytes memory) {
        string memory symbol = IERC20Metadata(token).symbol();
        StakeSVG.SvgParams memory params = StakeSVG.SvgParams({
            symbol: symbol,
            xenAddress: token,
            tokenId: tokenId,
            term: info.getTerm(),
            maturityTs: info.getMaturityTs(),
            amount: info.getAmount(),
            apy: info.getAPY(),
            rarityScore: info.getRarityScore(),
            rarityBits: info.getRarityBits()
        });
        return StakeSVG.image(params, _commonCategoryGradients());
    }

    function _attr1(uint256 amount, uint256 apy) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '{"trait_type":"Amount","value":"',
                amount.toString(),
                '"},'
                '{"trait_type":"APY","value":"',
                apy.toString(),
                '%"},'
            );
    }

    function _attr2(uint256 term, uint256 maturityTs) private pure returns (bytes memory) {
        (uint256 year, string memory month) = DateTime.yearAndMonth(maturityTs);
        return
            abi.encodePacked(
                '{"trait_type":"Maturity DateTime","value":"',
                maturityTs.asString(),
                '"},'
                '{"trait_type":"Term","value":"',
                term.toString(),
                '"},'
                '{"trait_type":"Maturity Year","value":"',
                year.toString(),
                '"},'
                '{"trait_type":"Maturity Month","value":"',
                month,
                '"},'
            );
    }

    function _attr3(uint256 rarityScore, uint256) private pure returns (bytes memory) {
        return abi.encodePacked('{"trait_type":"Rarity","value":"', rarityScore.toString(), '"}');
    }

    /**
        @dev private helper to construct attributes portion of NFT metadata
     */
    function attributes(uint256 stakeInfo) external pure returns (bytes memory) {
        (
            uint256 term,
            uint256 maturityTs,
            uint256 amount,
            uint256 apy,
            uint256 rarityScore,
            uint256 rarityBits
        ) = StakeInfo.decodeStakeInfo(stakeInfo);
        return
            abi.encodePacked("[", _attr1(amount, apy), _attr2(term, maturityTs), _attr3(rarityScore, rarityBits), "]");
    }

    function formattedString(uint256 n) public pure returns (string memory) {
        return FormattedStrings.toFormattedString(n);
    }
}
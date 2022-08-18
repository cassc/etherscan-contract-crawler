// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.9;

/// ============ Library Imports ============
import {ConfigSettings, ERC721Delegated} from "gwei-slim-erc721/base/ERC721Delegated.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721MetadataUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {SharedNFTLogic} from "nft-editions/SharedNFTLogic.sol";

/// ============ Local Imports ============
import {IOracle} from "./IOracle.sol";
import {IENSLookup} from "./IENSLookup.sol";
import {IZoraAsks} from "./IZoraAsks.sol";
import {EANGenerator} from "./EANGenerator.sol";

interface NFTOwnerOfInterface {
    function ownerOf(uint256 id) external view returns (address);
}

/// @author Iain Nash @isiain
/// @notice On-chain dynamic allowlist renderer
contract ScantronReceiptNFT is ERC721Delegated, EANGenerator {
    mapping(uint256 => uint256) private transferCount;

    // mainnet: 0x169e633a2d1e6c10dd91238ba11c4a708dfef37c |
    // https://data.chain.link/ethereum/mainnet/gas/fast-gas-gwei
    IOracle immutable gasOracle;

    // mainnet: 0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419
    // rinkeby:
    // https://data.chain.link/ethereum/mainnet/crypto-usd/eth-usd
    IOracle immutable usdOracle;

    // mainnet: 0x3671aE578E63FdF66ad4F3E12CC0c0d71Ac7510C
    // rinkeby: 0x34c01b31c18303Cbd4d97833bb54F70423C4d523
    // goreli: 0x333Fc8f550043f239a2CF79aEd5e9cF4A20Eb41e
    IENSLookup immutable ensLookup;

    /// goreli: 0xa5e8d0d4fced34e86af6d4e16131c7210ba8b4b7
    SharedNFTLogic immutable sharedNFTLogic;

    constructor(
        address baseFactory,
        address newSharedNFTLogic,
        string memory name,
        string memory symbol,
        uint16 royaltyBps,
        IOracle newGasOracle,
        IOracle newUsdOracle,
        IENSLookup newEnsLookup
    )
        ERC721Delegated(
            baseFactory,
            name,
            symbol,
            ConfigSettings({
                royaltyBps: royaltyBps,
                uriBase: "",
                uriExtension: "",
                hasTransferHook: true
            })
        )
    {
        sharedNFTLogic = SharedNFTLogic(newSharedNFTLogic);
        gasOracle = newGasOracle;
        usdOracle = newUsdOracle;
        ensLookup = newEnsLookup;
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256 tokenId
    ) public {
        if (minters[tokenId] == address(0)) {
            minters[tokenId] = from;
        }
        transferCount[tokenId] += 1;
    }

    struct MintData {
        uint32 usdValue;
        uint32 gasPrice;
        uint64 fromTokenId;
        uint64 count;
        uint64[] codes;
    }
    MintData[] public mintDatas;
    mapping(uint256 => address) public minters;
    uint256 atMint;

    struct MarketData {
        uint32 usdValue;
        uint32 gasPrice;
    }

    function mintBatch(
        address[] memory recipients,
        uint64[] memory codes,
        uint32 usdValueOverride,
        uint32 gasPriceOverride
    ) public onlyOwner {
        // 1. save current eth price in USD and gas price
        if (usdValueOverride == 0) {
            usdValueOverride = uint32(getChainlinkData(usdOracle));
        }

        if (gasPriceOverride == 0) {
            gasPriceOverride = uint32(getChainlinkData(gasOracle));
        }

        // Calculate token ids
        uint256 fromTokenId = atMint;

        for (uint256 i = 0; i < codes.length; i++) {
            if (codes[i] / 10**12 > 0) {
                revert("Invalid code");
            }
        }

        mintDatas.push(
            MintData({
                fromTokenId: uint64(fromTokenId),
                count: uint64(recipients.length),
                usdValue: usdValueOverride,
                gasPrice: gasPriceOverride,
                codes: codes
            })
        );

        atMint += recipients.length;
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(msg.sender, fromTokenId + i);
        }
    }

    function renderTokenID(
        uint256 tokenId,
        uint256 mintIndex,
        MintData memory mintData,
        uint256 ethUSDNow
    ) internal view returns (bytes memory) {
        uint256 code = mintData.codes[tokenId - mintData.fromTokenId];

        address[] memory addresses = new address[](2);

        addresses[0] = minters[tokenId];
        addresses[1] = NFTOwnerOfInterface(address(this)).ownerOf(tokenId);
        if (addresses[0] == address(0x0)) {
            addresses[0] = addresses[1];
        }
        string[] memory texts = new string[](7);
        texts[0] = string(
            abi.encodePacked(
                ensLookup.getNames(addresses)[0],
                '</tspan><tspan x="500" dy="2em" style="font-family:courier"> ',
                addrString(addresses[0])
            )
        );
        texts[1] = sharedNFTLogic.numberToString(mintData.gasPrice);
        texts[2] = sharedNFTLogic.numberToString(mintData.usdValue);
        texts[3] = sharedNFTLogic.numberToString(transferCount[tokenId]);
        texts[4] = addrString(addresses[1]);
        texts[5] = sharedNFTLogic.numberToString(ethUSDNow);
        texts[6] = sharedNFTLogic.numberToString(mintIndex);

        texts[3] = string(
            abi.encodePacked(
                texts[1],
                ' <tspan>gwei</tspan></tspan><tspan x="320" text-anchor="start" dy="2em">Minted ETH/USD price: </tspan><tspan x="680" text-anchor="end"> $',
                texts[2],
                '</tspan><tspan x="320" text-anchor="start" dy="2em">Current ETH/USD price: </tspan><tspan x="680" text-anchor="end"> $',
                texts[5],
                '</tspan><tspan x="320" text-anchor="start" dy="2em">NFT Transfer Count: </tspan><tspan x="680" text-anchor="end">',
                texts[3],
                ' </tspan><tspan x="320" text-anchor="start" dy="2em">NFT Series:</tspan><tspan x="680" text-anchor="end">',
                texts[6],
                '</tspan><tspan x="320" text-anchor="start" dy="2em">Losing 25 mins filling out a form:</tspan><tspan x="680" text-anchor="end">priceless</tspan><tspan x="500" text-anchor="middle" dy="2.6em">*********************************************************************</tspan><tspan x="320" text-anchor="start" style="font-weight:bold" dy="2em">Receipt owned by:</tspan><tspan x="320" text-anchor="start" dy="2em" style="font-family:courier">',
                texts[4]
            )
        );

        return
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="250 0 500 500"><defs><g id="ethsign"></g><pattern id="p1" viewBox="40 -4 50 40" height="60" width="10" patternUnits="userSpaceOnUse">'
                '<g transform="scale(2,1.9) translate(0,-40)"><path fill="#eee" d="m 0.22263731,8.6829084 c 0,0 7.46332799,-18.0481903 13.35832069,-0.445278 4.104208,12.2554896 6.67916,11.7998506 12.467766,0.890555 6.278624,-11.8327921 7.625039,-12.0910574 13.58096,1e-6 5.457626,11.0794726 7.83244,11.6502316 12.467766,-0.445278 5.412126,-14.1225087 11.57721,-4.89805 11.57721,-4.89805 L 63.8973,23.37706 c -34.070148,0 -42.880723,1e-6 -63.67466069,1e-6 z" /></g></pattern>'
                '<filter id="drop" x="0" y="0" width="200%" height="200%"><feOffset result="offOut" in="SourceGraphic" dx="4" dy="4" /><feGaussianBlur result="blurOut" in="offOut" stdDeviation="6" /> <feBlend in="SourceGraphic" in2="blurOut" mode="normal" /></filter></defs>'
                '<g x="20" y="20"><rect filter="url(#drop)" fill="#eee" x="300" y="20" width="400" height="460" />'
                '<g style="font-family:georgia"><text x="500" y="70" style="font-size:1.6em" text-anchor="middle" fill="black">Scantron NFT Receipt</text>'
                '<text y="80" text-anchor="middle" style="font-size:0.72em" fill="black"><tspan x="500" dy="2em">',
                texts[0],
                '</tspan><tspan x="500" text-anchor="middle" dy="2em" style="text-decoration:underline">paper.walletverify.app</tspan><tspan x="500" text-anchor="middle" dy="2em">*********************************************************************'
                '</tspan><tspan x="500" text-anchor="middle" dy="2em">receipt for successful scantron allowlist addition</tspan>'
                '<tspan x="320" text-anchor="start" dy="2em">Minted gas price: </tspan>'
                '<tspan x="680" text-anchor="end">',
                texts[3],
                '</tspan></text><g transform="translate(450,300) scale(3)">',
                svgForBarcode(generateCodesFor(code)),
                '</g></g><rect fill="url(#p1)" y="0" x="300" height="60" width="400" /><g transform="scale(1,-1) translate(0,-500)"><rect fill="url(#p1)" y="0" x="300" height="60" width="400" /></g></g></svg>'
            );
    }

    function addrString(address input) public pure returns (string memory) {
        return StringsUpgradeable.toHexString(uint256(uint160(input)), 20);
    }

    function getChainlinkData(IOracle oracle) internal view returns (uint256) {
        if (address(oracle) == address(0)) {
            return 0;
        }
        try oracle.latestRoundData() returns (
            uint80,
            int256 res,
            uint256,
            uint256,
            uint80
        ) {
            return uint256(res / 10**9);
        } catch {
            return 0;
        }
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        for (uint256 i = 0; i < mintDatas.length; i++) {
            if (tokenId < mintDatas[i].fromTokenId + mintDatas[i].count) {
                return
                    sharedNFTLogic.encodeMetadataJSON(
                        sharedNFTLogic.createMetadataJSON(
                            IERC721MetadataUpgradeable(address(this)).name(),
                            "NFTs given out for adding your ethereum address to the scantron faxed allowlist",
                            string(
                                abi.encodePacked(
                                    'image": "data:image/svg+xml;base64,',
                                    sharedNFTLogic.base64Encode(
                                        renderTokenID(
                                            tokenId,
                                            i,
                                            mintDatas[i],
                                            getChainlinkData(usdOracle)
                                        )
                                    ),
                                    '", "'
                                )
                            ),
                            tokenId,
                            0
                        )
                    );
            }
        }
        revert("invalid");
    }
}
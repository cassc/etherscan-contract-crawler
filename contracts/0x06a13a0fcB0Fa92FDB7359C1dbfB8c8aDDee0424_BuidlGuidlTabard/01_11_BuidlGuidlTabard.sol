//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title BuidlGuidl Tabard
 * @author Daniel Khoo
 * @notice A dynamic NFT for BuidlGuidl members. Image is a fully-onchain SVG with tied to the bound address i.e. the minter.
 * Dynamic elements are: ENS reverse resolution, stream and wallet balance updates.
 * @dev Mintable if wallet is toAddress of a BuidlGuidl stream.
 */
contract BuidlGuidlTabard is ERC721 {
    // ENS Reverse Record Contract for address => ENS resolution
    // NOTE: Address of ENS Reverse Record Contract differs across testnets/mainnet
    IReverseRecords ensReverseRecords =
        IReverseRecords(0x3671aE578E63FdF66ad4F3E12CC0c0d71Ac7510C);
    mapping(address => address) public streams; // Store individual stream addresses so they can be referenced post-mint

    constructor() ERC721("BuidlGuidl Tabard", "BGT") {}

    function mintItem(address streamAddress) public {
        // Minimal check that wallet is the recipient of a Stream
        // Someone could deploy a decoy stream to bypass this, but it's easier to just join the BuidlGuidl :)
        ISimpleStream stream = ISimpleStream(streamAddress);
        require(
            msg.sender == stream.toAddress(),
            "You are not the recipient of the stream"
        );

        streams[msg.sender] = streamAddress;

        // Set the token id to the address of minter.
        // Inspired by https://gist.github.com/z0r0z/6ca37df326302b0ec8635b8796a4fdbb
        _mint(msg.sender, uint256(uint160(msg.sender)));
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return _buildTokenURI(id);
    }

    // Constructs the encoded svg string to be returned by tokenURI()
    function _buildTokenURI(uint256 id) internal view returns (string memory) {
        bool minted = _exists(id);

        // Bound address from tokenId
        address boundAddress = address(uint160(id));

        string memory streamBalance = "";
        // Don't include stream in URI until token is minted
        if (minted) {
            // Get stream address, to check it's current balance
            address streamAddress = streams[boundAddress];
            ISimpleStream stream = ISimpleStream(streamAddress);
            streamBalance = string(
                abi.encodePacked(
                    unicode'<text x="20" y="305">Stream Ξ',
                    weiToEtherString(stream.streamBalance()),
                    "</text>"
                )
            );
        }

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<?xml version="1.0" encoding="UTF-8"?>',
                        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 400 400" preserveAspectRatio="xMidYMid meet">',
                        '<style type="text/css"><![CDATA[text { font-family: monospace; font-size: 21px;} .h1 {font-size: 40px; font-weight: 600;}]]></style>',
                        '<rect width="400" height="400" fill="#ffffff" />',
                        '<text class="h1" x="50" y="70">Knight of the</text>',
                        '<text class="h1" x="80" y="120" >BuidlGuidl</text>',
                        unicode'<text x="70" y="240" style="font-size:100px;">🏗️ 🏰</text>',
                        streamBalance,
                        unicode'<text x="210" y="305">Wallet Ξ',
                        weiToEtherString(boundAddress.balance),
                        "</text>",
                        '<text x="20" y="350" style="font-size:28px;"> ',
                        lookupENSName(boundAddress),
                        "</text>",
                        '<text x="20" y="380" style="font-size:14px;">0x',
                        addressToString(boundAddress),
                        "</text>",
                        "</svg>"
                    )
                )
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"BuidlGuidl Tabard", "image":"',
                                image,
                                unicode'", "description": "This NFT marks the bound address as a member of the BuidlGuidl. The image is a fully-onchain dynamic SVG reflecting current balances of the bound wallet and builder work stream."}'
                            )
                        )
                    )
                )
            );
    }

    /* ========== HELPER FUNCTIONS ========== */

    /// @notice Checks ENS reverse records if address has an ens name, else returns blank string
    function lookupENSName(address addr) public view returns (string memory) {
        address[] memory t = new address[](1);
        t[0] = addr;
        string[] memory results = ensReverseRecords.getNames(t);
        return results[0];
    }

    /// @notice  Converts wei to ether string with 2 decimal places
    function weiToEtherString(uint256 amountInWei)
        public
        pure
        returns (string memory)
    {
        uint256 amountInFinney = amountInWei / 1e15; // 1 finney == 1e15
        return
            string(
                abi.encodePacked(
                    Strings.toString(amountInFinney / 1000), //left of decimal
                    ".",
                    Strings.toString((amountInFinney % 1000) / 100), //first decimal
                    Strings.toString(((amountInFinney % 1000) % 100) / 10) // first decimal
                )
            );
    }

    function addressToString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

/* ========== EXTERNAL CONTRACT INTERFACES ========== */
/// @notice Minimal contract interfaces for dynamic reading of data for SVG

/// @notice SimpleStream that each buidlguidl member has
/// https://github.com/scaffold-eth/scaffold-eth/blob/simple-stream/packages/hardhat/contracts/SimpleStream.sol
interface ISimpleStream {
    function toAddress() external view returns (address);

    function streamBalance() external view returns (uint256);
}

/// @notice ENS reverse record contract for resolving address to ENS name
/// https://github.com/ensdomains/reverse-records/blob/master/contracts/ReverseRecords.sol
interface IReverseRecords {
    function getNames(address[] calldata addresses)
        external
        view
        returns (string[] memory r);
}
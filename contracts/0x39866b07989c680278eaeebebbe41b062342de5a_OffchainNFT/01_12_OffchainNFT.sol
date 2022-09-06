// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./token/ERC721/extensions/ERC721Enumerable.sol";
import "./utils/Strings.sol";

contract OffchainNFT is ERC721Enumerable, IERC721Receiver {

    uint256 constant SUPPLY_CAP = 2040;
    uint256 constant ACCOUNT_MINT_CAP = 5;
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";  

    mapping (address => uint256) public mintCount;

    mapping (uint256 => address) public tokenBurnedContract;
    mapping (uint256 => uint256) public tokenBurnedId;
    mapping (address => mapping (uint256 => bool)) public tokenBurned;

    address public owner;

    constructor() ERC721("Offchain NFT", "OFFCHAINNFT") {
        owner = msg.sender;
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }

    /// @notice Minting function: Send any NFT to the contract via safeTransferFrom() to receive a free Offchain NFT, up to the cap
    function onERC721Received(address /*operator*/, address from, uint256 tokenId, bytes calldata /*data*/) public virtual override returns (bytes4) {
        require(totalSupply() < SUPPLY_CAP, "All 2040 Offchain NFTs have been minted");
        require(mintCount[from] < ACCOUNT_MINT_CAP, "Each account can only mint 5 Offchain NFTs");
        require(from == tx.origin, "Only direct NFT transfers are allowed");

        require(IERC721(msg.sender).balanceOf(address(this)) > 0);
        require(IERC721(msg.sender).ownerOf(tokenId) == address(this));
        IERC721(msg.sender).approve(BURN_ADDRESS, tokenId);

        uint256 mintId = totalSupply();
        tokenBurnedContract[mintId] = msg.sender;
        tokenBurnedId[mintId] = tokenId;
        tokenBurned[msg.sender][tokenId] = true;
        mintCount[from] += 1;
        _safeMint(from, mintId);

        return this.onERC721Received.selector;
    }

    /// @notice This function can be used to retrieve and refund lost NFTs accidentally sent via transferFrom() rather than safeTransferFrom(), it does not work for burned NFTs
    function reclaimLostNFT(address nftContract, uint256 nftId, address nftOwner) external {
        require(msg.sender == owner, "Reclamation must be started by the contract owner");
        require(tokenBurned[nftContract][nftId] == false, "NFT was burned and used for mint");

        IERC721(nftContract).transferFrom(address(this), nftOwner, nftId);
    }

    /// @notice Token URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < totalSupply(), "Invalid token id");
        bytes memory uriBytes = new bytes(5000);
        ExtensibleString memory uriString;
        uriString.length = 0;
        uriString.fullString = string(uriBytes);

        string memory string_trait_type = '    {\n      "trait_type": "';
        string memory string_trait_value = '",\n      "value": "';
        string memory string_trait_after = '"\n    },\n';
        string memory string_trait_last = '"\n    }\n';

        _appendString(uriString, '{\n');
        _appendString(uriString, '  "name": "Offchain NFT #');
        _appendString(uriString, Strings.toString(tokenId));
        _appendString(uriString, '",\n');
        _appendString(uriString, '  "description": "A limited collection of 2040 totally unique on-chain NFTs, passed through an advanced smart contract algorithm to simulate the visual results of most off-chain NFTs in the year 2040.",\n');
        _appendString(uriString, '  "image": "data:image/svg+xml;base64,');

        // SVG artwork
        bytes memory svgBytes = new bytes(2000);
        ExtensibleString memory svgString;
        svgString.length = 0;
        svgString.fullString = string(svgBytes);
        _appendString(svgString, '<svg width="690" height="690" viewBox="150 150 300 300" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n');
        _appendString(svgString, '\n');
        _appendString(svgString, '<mask id="torn">\n');
        _appendString(svgString, '  <rect x="287" y="285" width="26" height="30" fill="#ffffff" />\n');
        _appendString(svgString, '  <line x1="299" y1="317" x2="315" y2="301" stroke-width="3" stroke="#000000" />\n');
        _appendString(svgString, '</mask>\n');
        _appendString(svgString, '\n');
        _appendString(svgString, '<g style="mask:url(#torn)">\n');
        _appendString(svgString, '  <polygon points="288,286 306,286 306,292 312,292 312,314 288,314" stroke-width="2" stroke="#9e9e9e" fill="#c7d3eb" />\n');
        _appendString(svgString, '  <polygon points="306,285.414214 312.585786,292 306,292" stroke-width="2" stroke="#9e9e9e" fill="#ffffff" />\n');
        _appendString(svgString, '\n');
        _appendString(svgString, '  <path d="M 289 313 A 11 11 0 0 1 311 313" fill="#58ae39" />\n');
        _appendString(svgString, '  <path d="M 300 296 C 300.75 296 302 293.75 300.5 292.25 C 298.5 290.25 294.875 290 293.875 293 C 291.375 293.75 292 296 293.25 296 L 300 296" fill="#ffffff" />\n');
        _appendString(svgString, '</g>\n');
        _appendString(svgString, '\n');
        _appendString(svgString, '</svg>');
        assembly {mstore(mload(add(svgString, 0x20)), mload(svgString))}

        _appendString(uriString, base64encode(bytes(svgString.fullString)));
        _appendString(uriString, '",\n');
        _appendString(uriString, '  "attributes": [\n');

        // Attributes
        _appendString(uriString, string_trait_type);
        _appendString(uriString, 'Background');
        _appendString(uriString, string_trait_value);
        _appendString(uriString, _trait(tokenId, 0));
        _appendString(uriString, string_trait_after);
        
        _appendString(uriString, string_trait_type);
        _appendString(uriString, 'Hair');
        _appendString(uriString, string_trait_value);
        _appendString(uriString, _trait(tokenId, 1));
        _appendString(uriString, string_trait_after);

        _appendString(uriString, string_trait_type);
        _appendString(uriString, 'Eyes');
        _appendString(uriString, string_trait_value);
        _appendString(uriString, _trait(tokenId, 2));
        _appendString(uriString, string_trait_after);
        
        _appendString(uriString, string_trait_type);
        _appendString(uriString, 'Facial Hair');
        _appendString(uriString, string_trait_value);
        _appendString(uriString, _trait(tokenId, 3));
        _appendString(uriString, string_trait_after);
        
        _appendString(uriString, string_trait_type);
        _appendString(uriString, 'Accessory');
        _appendString(uriString, string_trait_value);
        _appendString(uriString, _trait(tokenId, 4));
        _appendString(uriString, string_trait_after);
        
        _appendString(uriString, string_trait_type);
        _appendString(uriString, 'Blockchain Power');
        _appendString(uriString, string_trait_value);
        _appendString(uriString, _trait(tokenId, 5));
        _appendString(uriString, string_trait_after);
        
        _appendString(uriString, string_trait_type);
        _appendString(uriString, 'Burned contract');
        _appendString(uriString, string_trait_value);
        _appendString(uriString, Strings.toHexString(uint256(uint160(tokenBurnedContract[tokenId])), 20));
        _appendString(uriString, string_trait_after);
        
        _appendString(uriString, string_trait_type);
        _appendString(uriString, 'Burned id');
        _appendString(uriString, string_trait_value);
        _appendString(uriString, Strings.toString(tokenBurnedId[tokenId]));
        _appendString(uriString, string_trait_last);
        _appendString(uriString, '  ]\n');

        _appendString(uriString, '}\n');

        assembly {mstore(mload(add(uriString, 0x20)), mload(uriString))}

        string memory base64json = base64encode(bytes(uriString.fullString));
        bytes memory jsonBytes = new bytes(29 + bytes(base64json).length * 2);
        ExtensibleString memory jsonString;
        jsonString.length = 0;
        jsonString.fullString = string(jsonBytes);
        _appendString(jsonString, "data:application/json;base64,");
        _appendString(jsonString, base64json);

        assembly {mstore(mload(add(jsonString, 0x20)), mload(jsonString))}
        
        return jsonString.fullString;
    }

    /// @notice Returns the correct trait value from the list
    function _trait(uint256 tokenId, uint256 traitId) internal pure returns (string memory) {
        require(tokenId < SUPPLY_CAP);
        uint256 randomSeed = uint256(keccak256(abi.encodePacked("Offchain NFT", tokenId)));

        uint256 traitSeed = (randomSeed >> (32 * traitId)) & 0xffffffff;
        uint256 traitRoll = traitSeed % 100;

        if (tokenId % 4 == 1) {
            tokenId = SUPPLY_CAP - tokenId;
        } else {
            if (tokenId % 4 == 2) {
                tokenId = (tokenId + (SUPPLY_CAP / 2)) % SUPPLY_CAP;
            } else {
                if (tokenId % 4 == 3) {
                    tokenId = ((SUPPLY_CAP + (SUPPLY_CAP / 2)) - tokenId) % SUPPLY_CAP;
                }
            }
        }
        traitSeed = tokenId;

        if (traitId == 0) {
            // Background
            traitRoll = traitSeed % 7;
            if (traitRoll < 1) {
                return "Sky Blue Yellow";
            } else {
                if (traitRoll < 2) {
                    return "1-Colour Gradient";
                } else {
                    if (traitRoll < 3) {
                        return "5-Sided Squares";
                    } else {
                        if (traitRoll < 4) {
                            return "Non-Parallel Stripes";
                        } else {
                            if (traitRoll < 5) {
                                return "Non-Repeating Fractal";
                            } else {
                                if (traitRoll < 6) {
                                    return "Pointy Circles";
                                } else {
                                    return "Transparent Rainbow";
                                }
                            }
                        }
                    }
                }
            }
        } else {
            traitSeed = traitSeed / 7;
            if (traitId == 1) {
                // Hair
                traitRoll = traitSeed % 7;
                if (traitRoll < 1) {
                    return "Less Than None";
                } else {
                    if (traitRoll < 2) {
                        return "Short Backed Mullet";
                    } else {
                        if (traitRoll < 3) {
                            return "Shaved Ponytail";
                        } else {
                            if (traitRoll < 4) {
                                return "Straightened Curls";
                            } else {
                                if (traitRoll < 5) {
                                    return "Untied Bow";
                                } else {
                                    if (traitRoll < 6) {
                                        return "Invisible Bangs";
                                    } else {
                                        return "4-Dimensional Hat";
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                traitSeed = traitSeed / 7;
                if (traitId == 4) {
                    // Accessory
                    traitRoll = traitSeed % 8;
                    if (traitRoll < 1) {
                        return "Silent Headphones";
                    } else {
                        if (traitRoll < 2) {
                            return "Static Watch";
                        } else {
                            if (traitRoll < 3) {
                                return "Bottomless Handbag";
                            } else {
                                if (traitRoll < 4) {
                                    return "Fishnet Umbrella";
                                } else {
                                    if (traitRoll < 5) {
                                        return "Invisible Necklace";
                                    } else {
                                        if (traitRoll < 6) {
                                            return "Full-Body Bikini";
                                        } else {
                                            if (traitRoll < 7) {
                                                return "Anti-Gravity Belt";
                                            } else {
                                                return "3-Dimensional Tattoo";
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    traitSeed = traitSeed / 8;
                    if (traitId == 3) {
                        // Facial Hair
                        traitRoll = traitSeed % 4;
                        if (traitRoll < 1) {
                            return "Less Than None";
                        } else {
                            if (traitRoll < 2) {
                                return "Hairless Beard";
                            } else {
                                if (traitRoll < 3) {
                                    return "Foot-long Stubble";
                                } else {
                                    return "Invisible Moustache";
                                }
                            }
                        }
                    } else {
                        traitSeed = traitSeed / 4;
                        if (traitId == 2) {
                            // Eyes
                            traitRoll = randomSeed % 2;
                            traitRoll *= 2;
                            traitRoll += traitSeed % 2;
                            if (traitRoll < 1) {
                                return "Opaque Glasses";
                            } else {
                                if (traitRoll < 2) {
                                    return "Invisible Eyepatch";
                                } else {
                                    if (traitRoll < 3) {
                                        return "Night-vision Shades";
                                    } else {
                                        return "Three-Eyed Cyclops";
                                    }
                                }
                            }
                        } else {
                            randomSeed = randomSeed / 2;
                            traitSeed = traitSeed / 2;
                            if (traitId == 5) {
                                // Blockchain Power
                                traitRoll = randomSeed % 4;
                                if (traitRoll < 1) {
                                    return "Reorder Blocks";
                                } else {
                                    if (traitRoll < 2) {
                                        return "Double-Spend";
                                    } else {
                                        if (traitRoll < 3) {
                                            return "Universal Signature";
                                        } else {
                                            return "Infinite Hash Power";
                                        }
                                    }
                                }
                            } else {
                                return "";
                            }
                        }
                    }
                }
            }
        }
    }

    struct ExtensibleString {
        uint256 length;
        string fullString;
    }

    function _appendString(ExtensibleString memory originalString, string memory appendedString) internal pure returns (uint256 newLength) {
        uint256 appendedLength = bytes(appendedString).length;
        uint256 originalLength = originalString.length;
        newLength = originalLength + appendedLength;

        bytes memory bytesOriginal = bytes(originalString.fullString);
        bytes memory bytesAppended = bytes(appendedString);

        for (uint256 i = originalLength; i < newLength; i++) {
            bytesOriginal[i] = bytesAppended[i - originalLength];
        }
        originalString.length += appendedLength;
    }

    function base64encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        string memory table = TABLE_ENCODE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;
pragma experimental ABIEncoderV2;

// solhint-disable quotes

import "./ERC721Base.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "hardhat-deploy/solc_0.7/proxy/Proxied.sol";

contract MandalaToken is ERC721Base, IERC721Metadata, Proxied {
    using EnumerableSet for EnumerableSet.UintSet;
    using ECDSA for bytes32;


    // solhint-disable-next-line quotes
    bytes internal constant TEMPLATE = 'data:text/plain,{"name":"Mandala 0x0000000000000000000000000000000000000000","description":"A Unique Mandala","image":"data:image/svg+xml,<svg xmlns=\'http://www.w3.org/2000/svg\' shape-rendering=\'crispEdges\' width=\'512\' height=\'512\'><g transform=\'scale(64)\'><image width=\'8\' height=\'8\' style=\'image-rendering: pixelated;\' href=\'data:image/gif;base64,R0lGODdhEwATAMQAAAAAAPb+Y/7EJfN3NNARQUUKLG0bMsR1SujKqW7wQwe/dQBcmQeEqjDR0UgXo4A0vrlq2AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAkKAAAALAAAAAATABMAAAdNgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABNgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABNgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABNgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA6gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGBADs=\'/></g></svg>"}';
    uint256 internal constant IMAGE_DATA_POS = 521;
    uint256 internal constant ADDRESS_NAME_POS = 74;

    uint256 internal constant WIDTH = 19;
    uint256 internal constant HEIGHT = 19;
    uint256 internal constant ROW_PER_BLOCK = 4;
    bytes32 constant internal xs = 0x8934893467893456789456789567896789789899000000000000000000000000;
    bytes32 constant internal ys = 0x0011112222223333333444444555556666777889000000000000000000000000;

    event Minted(uint256 indexed id, uint256 indexed pricePaid);
    event Burned(uint256 indexed id, uint256 indexed priceReceived);
    event CreatorshipTransferred(address indexed previousCreator, address indexed newCreator);

    uint256 public immutable linearCoefficient;
    uint256 public immutable initialPrice;
    uint256 public immutable creatorCutPer10000th;
    address payable public creator;

    constructor(address payable _creator, uint256 _initialPrice, uint256 _creatorCutPer10000th, uint256 _linearCoefficient) {
        require(_creatorCutPer10000th < 2000, "CREATOR_CUT_ROO_HIGHT");
        initialPrice = _initialPrice;
        creatorCutPer10000th = _creatorCutPer10000th;
        linearCoefficient = _linearCoefficient;
        postUpgrade(_creator, _initialPrice, _creatorCutPer10000th, _linearCoefficient);
    }

    // solhint-disable-next-line no-unused-vars
    function postUpgrade(address payable _creator, uint256 _initialPrice, uint256 _creatorCutPer10000th, uint256 _linearCoefficient) public proxied {
        // immutables are set in the constructor:
        // initialPrice = _initialPrice;
        // creatorCutPer10000th = _creatorCutPer10000th;
        // linearCoefficient = _linearCoefficient;
        creator = _creator;
        emit CreatorshipTransferred(address(0), creator);
    }


    function transferCreatorship(address payable newCreatorAddress) external {
        address oldCreator = creator;
        require(oldCreator == msg.sender, "NOT_AUTHORIZED");
        creator = newCreatorAddress;
        emit CreatorshipTransferred(oldCreator, newCreatorAddress);
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure override returns (string memory) {
        return "Mandala Tokens";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure override returns (string memory) {
        return "MANDALA";
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        address owner = _ownerOf(id);
        require(owner != address(0), "NOT_EXISTS");
        return _tokenURI(id);
    }

    /// @notice Check if the contract supports an interface.
    /// 0x01ffc9a7 is ERC165.
    /// 0x80ac58cd is ERC721
    /// 0x5b5e139f is for ERC721 metadata
    /// 0x780e9d63 is for ERC721 enumerable
    /// @param id The id of the interface.
    /// @return Whether the interface is supported.
    function supportsInterface(bytes4 id) public pure virtual override(ERC721Base, IERC165) returns (bool) {
        return ERC721Base.supportsInterface(id) || id == 0x5b5e139f;
    }

    struct TokenData {
        uint256 id;
        string tokenURI;
    }

    function getTokenDataOfOwner(
        address owner,
        uint256 start,
        uint256 num
    ) external view returns (TokenData[] memory tokens) {
        EnumerableSet.UintSet storage allTokens = _holderTokens[owner];
        uint256 balance = allTokens.length();
        require(balance >= start + num, "TOO_MANY_TOKEN_REQUESTED");
        tokens = new TokenData[](num);
        uint256 i = 0;
        while (i < num) {
            uint256 id = allTokens.at(start + i);
            tokens[i] = TokenData(id, _tokenURI(id));
            i++;
        }
    }

    function mint(address to, bytes memory signature) external payable returns (uint256) {
        uint256 mintPrice = _curve(_supply);
        require(msg.value >= mintPrice, "NOT_ENOUGH_ETH");


        // -------------------------- MINTING ---------------------------------------------------------
        bytes32 hashedData = keccak256(abi.encodePacked("Mandala", to));
        address signer = hashedData.toEthSignedMessageHash().recover(signature);
        _mint(uint256(signer), to);
        // -------------------------- MINTING ---------------------------------------------------------

        uint256 forCreator = mintPrice - _forReserve(mintPrice);

        // responsibility of the creator to ensure it can receive the fund
        bool success = true;
        if (forCreator > 0) {
            // solhint-disable-next-line check-send-result
            success = creator.send(forCreator);
        }

        if(!success || msg.value > mintPrice) {
            msg.sender.transfer(msg.value - mintPrice + (!success ? forCreator : 0));
        }

        emit Minted(uint256(signer), mintPrice);
        return uint256(signer);
    }


    function burn(uint256 id) external {
        uint256 burnPrice = _forReserve(_curve(_supply - 1));

        _burn(id);

        msg.sender.transfer(burnPrice);
        emit Burned(id, burnPrice);
    }

    function currentPrice() external view returns (uint256) {
        return _curve(_supply);
    }

    function _curve(uint256 supply) internal view returns (uint256) {
        return initialPrice + supply * linearCoefficient;
    }

    function _forReserve(uint256 mintPrice) internal view returns (uint256) {
        return mintPrice * (10000-creatorCutPer10000th) / 10000;
    }


    // solhint-disable-next-line code-complexity
    function _tokenURI(uint256 id) internal pure returns (string memory) {
        bytes memory metadata = TEMPLATE;
        writeUintAsHex(metadata, ADDRESS_NAME_POS, id);

        for (uint256 i = 0; i < 40; i++) {
            uint8 value = uint8((id >> (40-(i+1))*4) % 16);
            if (value == 0) {
                value = 16; // use black as oposed to transparent
            }
            uint256 x = extract(xs, i);
            uint256 y = extract(ys, i);
            setCharacter(metadata, IMAGE_DATA_POS, y*WIDTH + x + (y /ROW_PER_BLOCK) * 2 + 1, value);

            if (x != y) {
                setCharacter(metadata, IMAGE_DATA_POS, x*WIDTH + y + (x /ROW_PER_BLOCK) * 2 + 1, value);
                if (y != HEIGHT / 2) {
                    setCharacter(metadata, IMAGE_DATA_POS, x*WIDTH + (WIDTH -y -1) + (x /ROW_PER_BLOCK) * 2 + 1, value); // x mirror
                }

                if (x != WIDTH / 2) {
                    setCharacter(metadata, IMAGE_DATA_POS, (HEIGHT-x-1)*WIDTH + y + ((HEIGHT-x-1) /ROW_PER_BLOCK) * 2 + 1, value); // y mirror
                }

                if (x != WIDTH / 2 && y != HEIGHT / 2) {
                    setCharacter(metadata, IMAGE_DATA_POS, (HEIGHT-x-1)*WIDTH + (WIDTH-y-1) + ((HEIGHT-x-1) /ROW_PER_BLOCK) * 2 + 1, value); // x,y mirror
                }
            }

            if (x != WIDTH / 2) {
                setCharacter(metadata, IMAGE_DATA_POS, y*WIDTH + (WIDTH -x -1) + (y /ROW_PER_BLOCK) * 2 + 1, value); // x mirror
            }
            if (y != HEIGHT / 2) {
                setCharacter(metadata, IMAGE_DATA_POS, (HEIGHT-y-1)*WIDTH + x + ((HEIGHT-y-1) /ROW_PER_BLOCK) * 2 + 1, value); // y mirror
            }

            if (x != WIDTH / 2 && y != HEIGHT / 2) {
                setCharacter(metadata, IMAGE_DATA_POS, (HEIGHT-y-1)*WIDTH + (WIDTH-x-1) + ((HEIGHT-y-1) /ROW_PER_BLOCK) * 2 + 1, value); // x,y mirror
            }
        }
        return string(metadata);
    }


    function setCharacter(bytes memory metadata, uint256 base, uint256 pos, uint8 value) internal pure {
        uint256 base64Slot = base + (pos * 8) / 6;
        uint8 bit = uint8((pos * 8) % 6);
        uint8 existingValue = base64ToUint8(metadata[base64Slot]);
        if (bit == 0) {
            metadata[base64Slot] = uint8ToBase64(value >> 2);
            uint8 extraValue = base64ToUint8(metadata[base64Slot + 1]);
            metadata[base64Slot + 1] = uint8ToBase64(((value % 4) << 4) | (0x0F & extraValue));
        } else if (bit == 2) {
            metadata[base64Slot] = uint8ToBase64((value >> 4) | (0x30 & existingValue));
            uint8 extraValue = base64ToUint8(metadata[base64Slot + 1]);
            metadata[base64Slot + 1] = uint8ToBase64(((value % 16) << 2) | (0x03 & extraValue));
        } else { // bit == 4)
            // metadata[base64Slot] = uint8ToBase64((value >> 6) | (0x3C & existingValue)); // skip as value are never as big
            metadata[base64Slot + 1] = uint8ToBase64(value % 64);
        }
    }

    function extract(bytes32 arr, uint256 i) internal pure returns (uint256) {
        return (uint256(arr) >> (256 - (i+1) * 4)) % 16;
    }

    bytes32 constant internal base64Alphabet_1 = 0x4142434445464748494A4B4C4D4E4F505152535455565758595A616263646566;
    bytes32 constant internal base64Alphabet_2 = 0x6768696A6B6C6D6E6F707172737475767778797A303132333435363738392B2F;

    function base64ToUint8(bytes1 s) internal pure returns (uint8 v) {
        if (uint8(s) == 0x2B) {
            return 62;
        }
        if (uint8(s) == 0x2F) {
            return 63;
        }
        if (uint8(s) >= 0x30 && uint8(s) <= 0x39) {
            return uint8(s) - 0x30 + 52;
        }
        if (uint8(s) >= 0x41 && uint8(s) <= 0x5A) {
            return uint8(s) - 0x41;
        }
        if (uint8(s) >= 0x5A && uint8(s) <= 0x7A) {
            return uint8(s) - 0x5A + 26;
        }
        return 0;
    }

    function uint8ToBase64(uint24 v) internal pure returns (bytes1 s) {
        if (v >= 32) {
            return base64Alphabet_2[v - 32];
        }
        return base64Alphabet_1[v];
    }

    bytes constant internal hexAlphabet = "0123456789abcdef";

    function writeUintAsHex(bytes memory data, uint256 endPos, uint256 num) internal pure {
        while (num != 0) {
            data[endPos--] = bytes1(hexAlphabet[num % 16]);
            num /= 16;
        }
    }

}
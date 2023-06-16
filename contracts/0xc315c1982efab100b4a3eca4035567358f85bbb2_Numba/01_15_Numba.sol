/*
 __    __                          __                       
|  \  |  \                        |  \                     
| $$\ | $$ __    __  ______ ____  | $$____    ______        
| $$$\| $$|  \  |  \|      \    \ | $$    \  |      \      
| $$$$\ $$| $$  | $$| $$$$$$\$$$$\| $$$$$$$\  \$$$$$$\     
| $$\$$ $$| $$  | $$| $$ | $$ | $$| $$  | $$ /      $$      
| $$ \$$$$| $$__/ $$| $$ | $$ | $$| $$__/ $$|  $$$$$$$     
| $$  \$$$ \$$    $$| $$ | $$ | $$| $$    $$ \$$    $$      
 \$$   \$$  \$$$$$$  \$$  \$$  \$$ \$$$$$$$   \$$$$$$$      

go up!

https://twitter.com/NumbaNFT
http://discord.gg/2hmT32ZHrT
https://numbagoup.xyz
                                                                                          
h/t to Ohm, Looks, Dydx, Luna, Sushi, Reflect, Shib, Safemoon, CRV, ESD, BASED, Effirium, and of course, Bitcoin for the inspiration.
s/o to Zeppelin, Larva Labs, Loot, and KaijuKingz (minor) for some aspects of the smart contract.

Don't take this too seriously... or who knows, maybe do, as long as you have fun ;)

This project is dedicated to all the liquidated boys out there. 

*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Numba is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    ReentrancyGuard
{

    uint256 public constant GENESIS_AMOUNT = 1000;
    uint256 public numbaMinted = 0;
    uint256 public price = 0.033 ether;
    uint256 public priceIncrement = 0.001 ether;
    uint256 public devFee = 0.011 ether;
    uint256 public devWithdrawn = 0;

    mapping(uint256 => uint256) public nextUsable;

    uint256 internal nonce = 0;
    uint256[GENESIS_AMOUNT] internal indices;

    constructor() ERC721("Numba", "#") {}

    function randomIndex() internal returns (uint256) {
        uint256 totalSize = GENESIS_AMOUNT - numbaMinted;
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value + 1;
    }

    function mintGenesis(uint256 numberOfMints) public payable nonReentrant {
        require(
            totalSupply() + numberOfMints <= GENESIS_AMOUNT,
            "Can't mint that much."
        );
        require(
            numberOfMints > 0 && numberOfMints < 11,
            "Too much or too lil."
        );
        require(price * numberOfMints == msg.value, "Hmmm.");

        for (uint256 i; i < numberOfMints; i++) {
            _safeMint(msg.sender, randomIndex());
            numbaMinted++;
        }
    }

    function mint() public payable nonReentrant {
        require(numbaMinted > GENESIS_AMOUNT - 1, "Genesis mint is not over.");
        require(msg.value >= price * 3, "Insufficient funds to purchase.");
        if (msg.value > price * 3) {
            // payable(msg.sender).transfer(msg.value - price * 3);
            (bool success, ) = payable(msg.sender).call{
                value: msg.value - price * 3
            }("");
            require(success, "Transfer failed.");
        }

        _safeMint(msg.sender, numbaMinted + 1);
        numbaMinted++;
        price += priceIncrement;
    }

    function mintByAddition(
        uint256 x,
        uint256 y,
        uint256 z
    ) public payable nonReentrant {
        require(numbaMinted > GENESIS_AMOUNT - 1, "Genesis mint is not over.");
        require(x + y + z == numbaMinted + 1, "Wrong ingredients.");
        require(
            ownerOf(x) == msg.sender &&
                ownerOf(y) == msg.sender &&
                ownerOf(z) == msg.sender,
            "You don't own these."
        );
        require(x != y && y != z && z != x, "Can't be using dupes here.");
        require(
            nextUsable[x] < numbaMinted &&
                nextUsable[y] < numbaMinted &&
                nextUsable[z] < numbaMinted,
            "Cooldown."
        );
        require(price == msg.value, "Hmmmm.");
        _safeMint(msg.sender, numbaMinted + 1);
        numbaMinted++;
        price += priceIncrement;
        nextUsable[x] = numbaMinted + 20;
        nextUsable[y] = numbaMinted + 20;
        nextUsable[z] = numbaMinted + 20;
    }

    function mintByMultiplication(uint256 x, uint256 y)
        public
        payable
        nonReentrant
    {
        require(numbaMinted > GENESIS_AMOUNT - 1, "Genesis mint is not over.");
        require(x * y == numbaMinted + 1, "Wrong ingredients.");
        require(
            ownerOf(x) == msg.sender && ownerOf(y) == msg.sender,
            "You don't own these."
        );
        require(price == msg.value, "Hmmmm.");
        _safeMint(msg.sender, numbaMinted + 1);
        numbaMinted++;
        price += priceIncrement;
    }

    function mintByExponential(uint256 tokenId, uint256 power)
        public
        payable
        nonReentrant
    {
        require(numbaMinted > GENESIS_AMOUNT - 1, "Genesis mint is not over.");
        require(tokenId**power == numbaMinted + 1, "Wrong ingredients.");
        require(ownerOf(tokenId) == msg.sender, "You don't own this, fool.");
        require(price == msg.value, "Hmmmm.");
        _safeMint(msg.sender, numbaMinted + 1);
        numbaMinted++;
        price += priceIncrement;
    }



    function claimAndBurn(uint256 tokenId) public nonReentrant {
        uint256 backing = backingPerToken();
        burn(tokenId);
        (bool success, ) = payable(msg.sender).call{value: backing}("");
        require(success, "Transfer failed.");

        if (price - priceIncrement > 0.033 ether) {
            price -= priceIncrement;
        }
    }

    function devWithdraw() public onlyOwner nonReentrant {
        uint256 amount = devWithdrawable();
        devWithdrawn += amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }


    function backingPerToken() public view returns (uint256) {
        uint256 totalWithdrawable = address(this).balance - devWithdrawable();
        return totalWithdrawable / totalSupply();
    }

    function reserve() public view returns (uint256) {
        return address(this).balance - devWithdrawable();
    }

    function holderClaimable(address holder) public view returns (uint256) {
        return (reserve() * balanceOf(holder)) / totalSupply();
    }

    function numbaBurnt() public view returns (uint256) {
        return numbaMinted - totalSupply();
    }

    function devWithdrawable() public view returns (uint256) {
        uint256 totalEarned = devFee * numbaMinted;
        return totalEarned - devWithdrawn;
    }

    function nextNumba() public view returns (uint256) {
        if (numbaMinted < GENESIS_AMOUNT) {
            return 0;
        }
        return numbaMinted + 1;
    }

    function etherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function message() public view returns (string memory) {
        return "Numba go up!";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[3] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: black; font-family: sans-serif; font-size: 33px; }</style><rect width="100%" height="100%" fill="white" /><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" class="base">';

        parts[1] = toString(tokenId);

        parts[2] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2])
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Numba ',
                        toString(tokenId),
                        '", "description": "Numba go up!", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function ownedTokenIds(address holder)
        public
        view
        returns (uint256[] memory)
    {
        uint256 length = balanceOf(holder);
        uint256[] memory owned = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            owned[i] = tokenOfOwnerByIndex(holder, i);
        }
        return owned;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
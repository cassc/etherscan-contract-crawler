// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import "./IERC4906.sol";

error MustOwnNFT();
error MustSendEnoughETH();
error Throttled();
error MintNotOpen();

interface ISvgRender {
    function getProps(uint256 seed)
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory
        );

    function getSvg(uint256 seed) external view returns (string memory);
}

contract MoonGame is
    DefaultOperatorFilterer,
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard,
    IERC4906
{
    event Mint(
        address indexed minter,
        uint256 quantity,
        uint256 totalValueSent,
        uint256 totalValueReturned
    );
    event Burn(address indexed burner, uint256 quantity, uint256 valueRedeemed);

    uint256 public constant INITIAL_MINT_PRICE = 0.05e18;
    uint256 public constant MINT_PRICE_INCREMENT = 0.00005e18;
    uint256 public constant MIN_MINT_TICK = MINT_PRICE_INCREMENT / 100;
    uint256 public constant DECAY_TIME = 20 minutes;
    uint256 public constant MINT_THROTTLE_PERIOD = 15 minutes;
    uint256 public constant MINT_THROTTLE_LIMIT = 10;

    uint256 public burnCounter;
    uint256 public latestMintCost;
    uint256 public lastMintedTimestamp;
    uint256 public latestRedeemableValue;

    uint256 public mintOpenTimestamp;
    bool private mintOpen;

    mapping(uint256 => uint256) randomSeed;

    // only relevant during throttle period
    mapping(address => mapping(uint256 => uint256)) mintsPerBlockDuringThrottlePeriod;

    ISvgRender svgRender;

    constructor(ISvgRender _svgRender)
        ERC721("MoonGame", "MOONGAME")
        Ownable()
    {
        latestRedeemableValue = INITIAL_MINT_PRICE;
        svgRender = _svgRender;
    }

    function mint(uint256 quantity) public payable nonReentrant {
        if (!mintOpen) revert MintNotOpen();
        if (block.timestamp < mintOpenTimestamp + MINT_THROTTLE_PERIOD) {
            if (
                mintsPerBlockDuringThrottlePeriod[msg.sender][block.number] +
                    quantity >
                MINT_THROTTLE_LIMIT
            ) revert Throttled();
            mintsPerBlockDuringThrottlePeriod[msg.sender][
                block.number
            ] += quantity;
        }

        (uint256 totalMintCost, uint256 lastMintCost) = getMintCost(quantity);
        if (msg.value < totalMintCost) revert MustSendEnoughETH();

        address minter = msg.sender;

        uint256 excessEth = msg.value - totalMintCost;
        if (excessEth > 0) {
            bool sent = payable(minter).send(excessEth);
            require(sent);
        }

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = getCurrentTokenId();
            _safeMint(minter, tokenId);

            randomSeed[tokenId] = (
                uint256(
                    keccak256(
                        abi.encodePacked(
                            tokenId,
                            block.timestamp,
                            block.prevrandao
                        )
                    )
                )
            );
            emit MetadataUpdate(tokenId);
        }

        lastMintedTimestamp = block.timestamp;
        latestRedeemableValue = getRedeemableValuePerToken();
        latestMintCost = lastMintCost;

        emit Mint(minter, quantity, msg.value, excessEth);
    }

    function burn(uint256[] memory tokenIds) public nonReentrant {
        uint256 numTokens = tokenIds.length;
        uint256 amountToSend = getRedeemableValuePerToken() * numTokens;
        address burner = msg.sender;

        for (uint256 i = 0; i < numTokens; i++) {
            if (ownerOf(tokenIds[i]) != burner) revert MustOwnNFT();
            _burn(tokenIds[i]);
        }
        bool sent = payable(burner).send(amountToSend);
        require(sent);
        burnCounter += numTokens;

        emit Burn(burner, numTokens, amountToSend);
    }

    function openMint() public onlyOwner {
        mintOpen = true;
        mintOpenTimestamp = block.timestamp;
    }

    function getMintCost(uint256 quantity)
        public
        view
        returns (uint256 totalMintCost, uint256 lastMintCost)
    {
        uint256 firstMintCost;
        uint256 minMintPrice = totalSupply() == 0
            ? INITIAL_MINT_PRICE
            : latestRedeemableValue + MIN_MINT_TICK;

        if (block.timestamp >= lastMintedTimestamp + DECAY_TIME) {
            firstMintCost = minMintPrice;
        } else {
            uint256 timeElapsedSinceMint = block.timestamp -
                lastMintedTimestamp;
            uint256 nextVirtualMintPrice = latestMintCost +
                MINT_PRICE_INCREMENT;
            uint256 fullPriceDiff = nextVirtualMintPrice -
                latestRedeemableValue;
            firstMintCost =
                nextVirtualMintPrice -
                ((fullPriceDiff * timeElapsedSinceMint) / DECAY_TIME);

            if (firstMintCost < minMintPrice) {
                firstMintCost = minMintPrice;
            }
        }

        lastMintCost = firstMintCost + ((quantity - 1) * MINT_PRICE_INCREMENT);
        uint256 averageCost = (firstMintCost + lastMintCost) / 2;
        totalMintCost = averageCost * quantity;
    }

    function getCurrentTokenId() public view returns (uint256) {
        return totalSupply() + burnCounter;
    }

    function getTreasury() public view returns (uint256) {
        return address(this).balance;
    }

    function getRedeemableValuePerToken() public view returns (uint256) {
        return getTreasury() / totalSupply();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256 seed = randomSeed[tokenId];
        string memory svg = getSvg(tokenId);
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Moonie #',
                        toString(tokenId),
                        '", "description": "MoonGame is an entirely on-chain, unlimited supply collection where the floor can only go up.", "image_data": "',
                        svg,
                        '", ',
                        getAttributes(seed),
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function getAttributes(uint256 seed) internal view returns (string memory) {
        (
            string memory orbitColor,
            string memory eco,
            string memory orbit,
            string memory astro
        ) = svgRender.getProps(seed);
        return
            string(
                abi.encodePacked(
                    '"attributes": [{"trait_type": "orbit color", "value": "',
                    orbitColor,
                    '"}, {"trait_type": "eco", "value": "',
                    eco,
                    '"}, {"trait_type": "orbit", "value": "',
                    orbit,
                    '"}, {"trait_type": "astro", "value": "',
                    astro,
                    '" }]'
                )
            );
    }

    function getSvg(uint256 tokenId) public view returns (string memory) {
        return svgRender.getSvg(randomSeed[tokenId]);
    }

    // Strings
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
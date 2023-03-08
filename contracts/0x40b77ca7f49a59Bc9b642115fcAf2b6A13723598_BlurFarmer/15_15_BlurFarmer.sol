// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

error MustOwnNFT();
error MustSendEnoughETH();

contract BlurFarmer is ERC721Enumerable, Ownable, ReentrancyGuard {
    event Mint(address indexed minter, uint256 quantity, uint256 totalValueSent, uint256 totalValueReturned);
    event Burn(address indexed burner, uint256 quantity, uint256 valueRedeemed);

    uint256 public constant INITIAL_MINT_PRICE = 0.05e18;
    uint256 public constant MINT_PRICE_INCREMENT = 0.0005e18;

    string public baseURI;

    uint256 public burnCounter;

    constructor(string memory _baseURI)
        ERC721("Blur Farmer", "BLURFARM")
        Ownable()
    {
        baseURI = _baseURI;
    }

    function mint(uint256 quantity) public payable nonReentrant {
        uint256 totalMintCost = getMintCost(quantity);
        if(msg.value < totalMintCost) revert MustSendEnoughETH();

        address minter = msg.sender;

        uint256 excessEth = msg.value - totalMintCost;
        if (excessEth > 0) {
            bool sent = payable(minter).send(excessEth);
            require(sent);
        }

        for(uint256 i = 0; i < quantity; i++){
            _safeMint(minter, getCurrentTokenId());
        }

        emit Mint(minter, quantity, msg.value, excessEth);
    }

    function burn(uint256[] memory tokenIds) public nonReentrant {
        uint256 numTokens = tokenIds.length;
        uint256 amountToSend = getRedeemableValuePerToken() * numTokens;
        address burner = msg.sender;

        for (uint256 i = 0; i < numTokens; i++) {
            if(ownerOf(tokenIds[i]) != burner) revert MustOwnNFT();
            _burn(tokenIds[i]);
        }
        bool sent = payable(burner).send(
            amountToSend
        );
        require(sent);
        burnCounter += numTokens;

        emit Burn(burner, numTokens, amountToSend);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function getMintCost(uint256 quantity)
        public
        view
        returns (uint256 totalMintCost)
    {
        uint256 currentTokenId = getCurrentTokenId();
        uint256 firstTokenIncrement = currentTokenId * MINT_PRICE_INCREMENT;
        uint256 lastTokenIncrement = (currentTokenId + quantity - 1) *
            MINT_PRICE_INCREMENT;
        uint256 averageIncrement = (firstTokenIncrement + lastTokenIncrement) /
            2;
        uint256 averageCost = INITIAL_MINT_PRICE + averageIncrement;
        totalMintCost = averageCost * quantity;
    }

    function getCurrentTokenId() public view returns(uint256){
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
        return string(abi.encodePacked(baseURI, toString(tokenId)));
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
}
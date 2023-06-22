// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ERC721.sol";

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@BP5~~^::^~~~~~~~~~~~~5P#@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@J^^^^:::~~~~~~~~~~~~~~^7##@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@J~~::^~~~~~~~~~~~~~~~~~~~^#@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@J~~~~~~~~~~~~~~~~~~~~~~~~^#@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@J~~~~~~~~~~~~~~~~~~~~~~~~^#@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@Y~~~~7JJYY?~~~~~~~~~~?JJYJ&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@GG7~~~~5&&Y?7~~~~~~~~~~#&B??&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@&&P^^~~~~~5&#!~~~~~~~~~~~~B&G~^#@@@@@@@@@@@@@@@
@@@@@@@@@@@@@!^~~~~~~~~~~~~~~~~~~~~~~~~~~~~^#@@@@@@@@@@@@@@@
@@@@@@@@@@@@@7~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@G^^[email protected]@@@@7~~~^#@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@##GPPYJJYJ~~~~~~~~Y555Y!^!YJ&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@BPPPPPPPJ???????77777??JPP&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@BPPPPPPPPPPPPBBBBBBBBGPPPP&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@B55PPPPPPPPPP&@@@@@@@GPPP5&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@Y~!PPPPPPPPPPPPPPPPPPPPPPP&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@J^[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@J~~~~!?7775&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@J~~~~~~~~^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

contract PixelTate is ERC721, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256; //allows for uint256var.tostring()

    uint256 public MAX_MINT_PXT_PER_WALLET_SALE = 25;
    uint256 public Max_Mint_PXT_Per_Tx_ID = 25;
    uint256 public price = 0.03 ether;

    string private baseURI;
    bool public mintEnabled = false;

    mapping(address => uint256) public users;

    constructor() ERC721("PixelTate", "PXT", 10000) {
        _setDefaultRoyalty(0x43298AE2eb0C6751AeCFE15529a2bc3124C1e845, 250);
    }

    function MintPXT(uint256 amountPXT) public payable {
        require(mintEnabled, "Sale is not enabled");
        require(price * amountPXT <= msg.value, "Not enough ETH");
        require(amountPXT <= Max_Mint_PXT_Per_Tx_ID, "Too many per TX Id");
        require(
            users[msg.sender] + amountPXT <= MAX_MINT_PXT_PER_WALLET_SALE,
            "Exceeds max mint limit per wallet");
        users[msg.sender] += amountPXT;
        MintRandomlyPXT(msg.sender, amountPXT);
    }

    /// ============ INTERNAL ============
    function MintRandomlyPXT(address to, uint256 amount) internal {
        _mintRandom(to, amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// ============ ONLY OWNER ============
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function unPauseMint() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setMaxMintPXTPerWallet(uint256 limit) external onlyOwner {
        require(MAX_MINT_PXT_PER_WALLET_SALE != limit, "New limit is the same as the existing one");
        MAX_MINT_PXT_PER_WALLET_SALE = limit;
    }

    function setMaxMintPerTxId(uint256 limit) external onlyOwner {
        require(Max_Mint_PXT_Per_Tx_ID != limit, "New limit is the same as the existing one");
        Max_Mint_PXT_Per_Tx_ID = limit;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setRoyalty(address wallet, uint96 perc) external onlyOwner {
        _setDefaultRoyalty(wallet, perc);
    }

    function reserve(address to, uint256 tokenId) external onlyOwner {
        require(_ownerOf(tokenId) == address(0), "Token has been minted.");
        _mintAtIndex(to, tokenId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /// ============ ERC2981 ============
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        ERC721._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

}
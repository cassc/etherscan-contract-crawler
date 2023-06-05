// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

//                     _{\ _{\{\/}/}/}__
//                    {/{/\}{/{/\}(\}{/\} _
//                   {/{/\}{/{/\}(_)\}{/{/\}  _
//                {\{/(\}\}{/{/\}\}{/){/\}\} /\}
//               {/{/(_)/}{\{/)\}{\(_){/}/}/}/}
//              _{\{/{/{\{/{/(_)/}/}/}{\(/}/}/}
//             {/{/{\{\{\(/}{\{\/}/}{\}(_){\/}\}
//             _{\{/{\{/(_)\}/}{/{/{/\}\})\}{/\}
//            {/{/{\{\(/}{/{\{\{\/})/}{\(_)/}/}\}
//             {\{\/}(_){\{\{\/}/}(_){\/}{\/}/})/}
//              {/{\{\/}{/{\{\{\/}/}{\{\/}/}\}(_)
//             {/{\{\/}{/){\{\{\/}/}{\{\(/}/}\}/}
//              {/{\{\/}(_){\{\{\(/}/}{\(_)/}/}\}
//                {/({/{\{/{\{\/}(_){\/}/}\}/}(\}
//                 (_){/{\/}{\{\/}/}{\{\)/}/}(_)
//                   {/{/{\{\/}{/{\{\{\(_)/}
//                    {/{\{\{\/}/}{\{\\}/}
//                     {){/ {\/}{\/} \}\}
//                     (_)  \.-'.-/
//                 __...--- |'-.-'| --...__
//          _...--"   .-'   |'-.-'|  ' -.  ""--..__
//        -"    ' .  . '    |.'-._| '  . .  '
//        .  '-  '    .--'  | '-.'|    .  '  . '
//                 ' ..     |'-_.-|
//         .  '  .       _.-|-._ -|-._  .  '  .
//                     .'   |'- .-|   '.
//         ..-'   ' .  '.   `-._.-�   .'  '  - .
//          .-' '        '-._______.-'     '  .
//               .      ~,
//           .       .   |\   .    ' '-.
//           ___________/  \____________
//          /                           \
//         |           wen eden          |
//         |                             |
//          \___________________________/
//

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";

contract CryptoTrunksPOAP is ERC721, Ownable {
    using Counters for Counters.Counter;

    enum Age {
        THREE, // Spring
        SIX, // Summer
        NINE, // Fall
        TWELVE // Winter
    }

    Counters.Counter private tokenCounter;
    string private baseURI;
    mapping(uint256 => Age) tokenIdAge;

    uint256 private TWELVE_MONTH_TOKENS = 8168; // Winter
    uint256 private NINE_MONTH_TOKENS = 2783; // Fall
    uint256 private SIX_MONTH_TOKENS = 409; // Summer
    uint256 private THREE_MONTH_TOKENS = 243; // Spring

    uint256 private TOTAL_SNAPSHOTTED_TOKENS =
        TWELVE_MONTH_TOKENS + NINE_MONTH_TOKENS + SIX_MONTH_TOKENS + THREE_MONTH_TOKENS;

    constructor() ERC721("CryptoTrunks POAP", "POAP") {}

    // Batch-minting of pre-snapshotted CryptoTrunks holders.
    function mintBatch(address[] memory to) external onlyOwner {
        uint256 length = to.length;
        for (uint256 i = 0; i < length; ) {
            uint256 tokenId = nextTokenId();
            _mint(to[i], tokenId);
            unchecked {
                ++i;
            }
        }
    }

    // In case we missed anyone and need to mint extras.
    function mint(address to, uint256 age) public onlyOwner {
        uint256 tokenId = nextTokenId();
        tokenIdAge[tokenId] = Age(age);
        _safeMint(to, tokenId);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenURI(tokenId)));
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        // Ages for pre-allocated tokens are fixed.
        // For subsequent mints, use lookup.
        Age age;
        if (tokenId <= TWELVE_MONTH_TOKENS) {
            age = Age.TWELVE;
        } else if (tokenId <= TWELVE_MONTH_TOKENS + NINE_MONTH_TOKENS) {
            age = Age.NINE;
        } else if (tokenId <= TWELVE_MONTH_TOKENS + NINE_MONTH_TOKENS + SIX_MONTH_TOKENS) {
            age = Age.SIX;
        } else if (tokenId <= TWELVE_MONTH_TOKENS + NINE_MONTH_TOKENS + SIX_MONTH_TOKENS + THREE_MONTH_TOKENS) {
            age = Age.THREE;
        } else {
            // tokenId > TOTAL_SNAPSHOTTED_TOKENS
            age = tokenIdAge[tokenId];
        }

        // Convert age to asset.
        if (age == Age.TWELVE) {
            return "04-winter.json";
        } else if (age == Age.NINE) {
            return "03-fall.json";
        } else if (age == Age.SIX) {
            return "02-summer.json";
        } else {
            // age == Age.THREE
            return "01-spring.json";
        }
    }

    // Taken from CryptoCoven's excellent contract.
    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }
}
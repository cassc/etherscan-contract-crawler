/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@  ACTUAL  3D  PUNKS  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@#BB&BGB&GGB#55PPGBBB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&#PG5GPG5GGP5PYYYYYYYYP&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@&&P5P#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&GPP&B55BB55555BGYYYYYYYYYYYYY5PP&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@B#BBP##BPB#GGG#GGGPPPPPPPPPPPPPP55B&&&@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@&@&GG##PG##GB&BPG&[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@&&&PGBBY5B#GG#GY5#[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&&&##BPGBB5YYB##GYYY5555Y5PGP555B#B##@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&&&@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&&&@B?YGBYY55P#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&@&&&@[email protected]&&P?JGP????????P&P7???G&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&&&@&&&@[email protected]@@[email protected]!!7?G&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&&&@&&&@B?YGG?J?JYBP?????????J?????G&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&&&@&&&@B?YGG???JYBP???????????????G&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@&&@&&&@#Y5BG???JYBGYYJ??JYYJ????JYB&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&&&@@&&&[email protected]@@[email protected]@G????G&#@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&&&@@&&&#GB5JYB#PGY??YPPY?5BB#&#@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&&&@@&&&&##P?YBP7?????????5#B#&#@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&&&@@&&&G?JJJYGP7????????????G&#@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&&&@@&&&G?YG&#&&B########&&P?G&#@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&&&@@&&&[email protected]@@&&&&&&&&&&&&P7G&#@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&&&@@&&&P7??Y5BG?JJ?????JJJ??G&&@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&[email protected]&@&@&&BGJYPGY?JJJ?JJ??5##B&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@#5GBBPPBBGG&#55B#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@&?~!5!~7&&###&&@&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@#&&&##&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@&&&&#&&BJYYYYYB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@&&@&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/




// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Actual3DPunks is ERC721A, Ownable, ReentrancyGuard {
    uint256 public maxSupply = 10000;
    string public constant _baseURIHardCoded = "ipfs://QmacftaYgCKh7HX6xCufCW8ghCYA8Mtx1AocNuustu2A24/";

    constructor() ERC721A("Actual 3D Punks", "A3DP") {}


    function myMint(uint256 numberOfTokens) external onlyOwner nonReentrant {
        require(totalSupply() + numberOfTokens <= maxSupply, "Max # of NFTs has been reached");
        _safeMint(msg.sender, numberOfTokens);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIHardCoded;
    }

    function getOwnershipDataOf(uint256 _tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(_tokenId);
    }

}
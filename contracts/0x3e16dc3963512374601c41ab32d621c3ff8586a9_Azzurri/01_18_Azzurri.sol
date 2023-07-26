// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// @@@@@@@G7~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[email protected]
// @@@@@@Y^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^Y
// @@@@@#^^^^~!7~^^^^^^^^^^^^^^^^~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^?PPP?^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~
// @@@@@J:^^!PGGPY7^^^^^^^^^^^^^7PPPPPPPPPPPPPPPP?^^^^^^^^^^^^^PGGP~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^Y
// @@@@#^^^^YGGGGGG57^^^^^^^^^^^?YYYYY5GGG5YYYYYJ^^^^^^^^^^^^^?GGG?^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~&
// @@@@J:^^!GGGGGGPGGP?~^^^^^^^^^^^^^^5GGP~^^^^~7Y55P5YJ!^^^^^5GGP~^^^7JY5P55Y7~^^^^7555YJY5555Y7^^^^^^^!?Y5PP5Y?!Y555~^^7J55P55Y?~^^^^7J55P55Y?~^^^^^:[email protected]
// @@@#^^^^YGGGGGGGGGGGPJ!^^^^^^^^^^^7GGGJ^^^!YPGPYJJYPGGJ^^^?GGGJ^^?PGG5YJY5GGP7^^^5GGGGP5YY5GGG5!^^^75GGP5YY5PGPGGGY^~5GGPJJJ5GGP7^~5GGPJJJYGGG?^^^^~&@
// @@@J:^^!GGGGGGGGGGGGGGPY!^^^^^^^^^5GGP~^^?GGGJ!~~~~7PGG?^^5GGP~~5GG57~~~~~JGGP~^7GGGP7^^^^^!PGG5^^?GGPJ~^^^^~YGPGP!^?GGGY!~^^!7!~^!GGG5!~^^!7!~^^^:[email protected]@
// @@#^^^^YGGGGGGGGGGGGGGGG?^^^^^^^^7GGGY^^~PGGPPPPPPPPPGGY^7GGGJ^JGGGPPPPPPPPPGG!^5GGP!^^^^^^^5GG5^!GGGJ^^^^^^:7GGGY^^^JPGGGPPY?~^^^^?5PGGGP5J!^^^^^~#@@
// @@J:^^!GGGGGGGGGGGGGG5J!^^^^^^^^^5GGP!^^!GGGJ~!!!~!77!!~^5GGP~^YGGP!~!!!~777!!^7GGGP~^^^^^^?GGG?^7GGGJ^^^^^^!5GGP!^^^^~~7?J5GGG7^^^^~~!?J5GGG?^^^:[email protected]@@
// @#~^^^YGGGGGGGGGGP5?!^^^^^^^^^^^7GPGY^^^^YGGP?!!!7YPP5!^7GGGJ^^!PGGY7!!!?5PPJ^^5GGGGPJ7!7?5GGP?^^^5GGGY7!7?YPGGGY^~Y5P57~~~JGGG?^J5P57~~~?GGGY^^^~#@@@
// @Y:^^!PGGGGGGGPY?~^^^^^^^^^^^^^^5GGG!^^^^^?5PGGGGGP5J!^^5GGP~^^^!JPGGGGGGPY7^^7GGGYJPGGGGGP5?~^^^^^?5PGGGGG5GGGG!^^7YPGGGGGGP5?^^!YPGGGGGGP5?^^^:[email protected]@@@
// #~^^^JGGGGGPY7~^^^^^^^^^^^^^^^^^777!^^^^^^^^~!777!~^^^^^777!^^^^^^^~!77!~^^^^^5GGG!^^!!7!!~^^^^^^^^^^~!77!~^777!^^^^^^~!777!~^^^^^^^~!777!~^^^^^^#@@@@
// J^^^^!Y55J7~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^7GGGY^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:[email protected]@@@@
// ~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^J555!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#@@@@@
// 5^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[email protected]@@@@@
// @BJ!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^[email protected]@@@@@@

contract Azzurri is ERC1155(""), DefaultOperatorFilterer, ERC2981, Ownable {
    using Strings for uint256;

    string internal baseURI;

    /* Admin */
    function airdrop(
        address[] memory recipients,
        uint256 tokenId
    ) external onlyOwner {
        uint256 recipientLength = recipients.length;

        for (uint256 i = 0; i < recipientLength; ) {
            _mint(recipients[i], tokenId, 1, "");
            unchecked {
                i++;
            }
        }
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /* Public */

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }

    /* Royalty enforcement */

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}
//    .^7??????????????????????????????????????????????????????????????????7!:       .~7????????????????????????????????:
//     :#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y   ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5
//    ^@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@B [email protected]@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBB#7
//    [email protected]@@@@#                                                                [email protected]@@@@@ [email protected]@@@@G
//    .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G~ [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~
//      J&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~   .Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B
//         [email protected]@@@@5  .7#@@@@@@@#?^....................          ..........................:#@@@@@J
//    ^5YYYJJJJJJJJJJJJJJJJJJJJJJJJJJY&@@@@@?     .J&@@@@@@&[email protected]@@@@@!
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?         :5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7
//    !GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPY~              ^JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ^

//  _______________________________________________________ Tomb Series  ___________________________________________________

// Shadow Beacon
// Contract by Luke Miles (@worm_emoji)
// SPDX-License-Identifier: MIT

import "solmate/tokens/ERC721.sol";
import "openzeppelin/utils/Strings.sol";
import "openzeppelin/access/Ownable.sol";

pragma solidity >=0.8.10;

contract ShadowBeacon is ERC721, Ownable {
    string public baseURI;
    address public allowedSigner;

    error TokenIsNonTransferrable();
    error OnlyAuthorizedSigner();

    constructor(address _allowedSigner, string memory _baseURI) ERC721("SHADOW Beacon", "SHDB") {
        allowedSigner = _allowedSigner;
        baseURI = _baseURI;
    }

    // Admin functions //

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setAllowedSigner(address _allowedSigner) public onlyOwner {
        allowedSigner = _allowedSigner;
    }

    // Signer functions //

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        if (msg.sender != allowedSigner) revert OnlyAuthorizedSigner();
        require(from == ownerOf[id], "WRONG_FROM");

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            if (from != address(0)) {
                balanceOf[from]--;
            }
            balanceOf[to]++;
        }

        ownerOf[id] = to;
        emit Transfer(from, to, id);
    }

    // View functions //

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenID)));
    }

    // Disabled functions //

    function approve(address, uint256) public pure override {
        revert TokenIsNonTransferrable();
    }

    function setApprovalForAll(address, bool) public pure override {
        revert TokenIsNonTransferrable();
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert TokenIsNonTransferrable();
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert TokenIsNonTransferrable();
    }
}
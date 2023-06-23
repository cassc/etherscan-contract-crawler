// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

error MintPriceNotPaid();
error MaxSupply();
error NonExistentTokenURI();
error WithdrawTransfer();

// Beginner's Mind
// 
// Some three thousand years ago in China, the strategic board game Go was developed.
// Some believe warlords and generals based it on the stones they'd place on maps to determine their battle plans.
// Besides being the oldest continually played board game in human history, it's also one of the most complex.
// In modern times, beating this game became known in the artificial intelligence community as the holy grail.
//
// - Rick Rubin <3 <3 <3 <3 <2 
//
// All my love. Ian. 
// 
contract IDI0T is ERC721A, Ownable {
    uint256 public constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 7;
    uint256 public constant MINT_PRICE = 39.33 ether;
    uint256 public currentTokenId;

    constructor() ERC721A("IDI)T", "IDI0T") {}

    // Deploying to Arweave for permanency ;-)
    function _baseURI() internal pure override returns (string memory) {
        return
            "https://arweave.net/UCF4ewCXjPSNx3bR0Gp7Qybf6PixsgVqHhUQB4HJuC4/";
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        // No zeros here yo.
        return 1;
    }

    // Multi mint to save gas.
    function mintTo(address minter, uint256 quantity) external payable {
        if (msg.value < MINT_PRICE * quantity) {
            revert MintPriceNotPaid();
        }
        if (quantity + currentTokenId > _MAX_MINT_ERC2309_QUANTITY_LIMIT) {
            revert MaxSupply();
        }
        currentTokenId = (quantity + currentTokenId);
        _safeMint(minter, quantity);
    }

    // <3
    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }
}
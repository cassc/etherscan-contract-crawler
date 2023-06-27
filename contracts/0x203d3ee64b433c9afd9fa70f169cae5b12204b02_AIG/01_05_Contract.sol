// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

error MintPriceNotPaid();
error MaxSupply();
error NonExistentTokenURI();
error WithdrawTransfer();

// The Banana Bat.
// 
// Half Banana.
// Half Greek Legend.
// Half Bat.
//
contract AIG is ERC721A, Ownable {
    uint256 public constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 9;
    uint256 public constant MINT_PRICE = 0.0 ether;
    uint256 public currentTokenId;

    constructor() ERC721A("Achilles In Gotham", "AIG") {}

    // Deploying to Arweave for permanency ;-)
    function _baseURI() internal pure override returns (string memory) {
        return
            "https://arweave.net/3LujTHgzX7iuVpUDmnC46X85ceBNfRWfX5pdqzgW0lo/";
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
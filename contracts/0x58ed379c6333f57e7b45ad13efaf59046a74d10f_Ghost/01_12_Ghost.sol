// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Ghost is ERC1155, ERC2981, Ownable {
    struct MintCondition {
        uint32 saleStartMinusOne;
        uint16 editionPlusOne;
        uint16 minted;
        uint192 price;
    }

    bool public isPermanentMetadata;
    string public name = "Ghost";
    MintCondition[12] public mintConditions;

    constructor(string memory uri_, address royaltyReceiver_) ERC1155(uri_) {
        _setDefaultRoyalty(royaltyReceiver_, 1000);

        mintConditions[0] = MintCondition({
            saleStartMinusOne: 1662677999,
            editionPlusOne: 3001,
            price: 0.032 ether,
            minted: 0
        });

        mintConditions[1] = MintCondition({
            saleStartMinusOne: 1663196399,
            editionPlusOne: 2501,
            price: 0.048 ether,
            minted: 0
        });

        mintConditions[2] = MintCondition({
            saleStartMinusOne: 1663714799,
            editionPlusOne: 2001,
            price: 0.048 ether,
            minted: 0
        });

        mintConditions[3] = MintCondition({
            saleStartMinusOne: 1664233199,
            editionPlusOne: 1501,
            price: 0.048 ether,
            minted: 0
        });

        mintConditions[4] = MintCondition({
            saleStartMinusOne: 1664751599,
            editionPlusOne: 1401,
            price: 0.064 ether,
            minted: 0
        });

        mintConditions[5] = MintCondition({
            saleStartMinusOne: 1665269999,
            editionPlusOne: 1301,
            price: 0.064 ether,
            minted: 0
        });

        mintConditions[6] = MintCondition({
            saleStartMinusOne: 1665788399,
            editionPlusOne: 1201,
            price: 0.095 ether,
            minted: 0
        });

        mintConditions[7] = MintCondition({
            saleStartMinusOne: 1666306799,
            editionPlusOne: 1101,
            price: 0.095 ether,
            minted: 0
        });

        mintConditions[8] = MintCondition({
            saleStartMinusOne: 1666825199,
            editionPlusOne: 1001,
            price: 0.095 ether,
            minted: 0
        });

        mintConditions[9] = MintCondition({
            saleStartMinusOne: 1667343599,
            editionPlusOne: 901,
            price: 0.095 ether,
            minted: 0
        });

        mintConditions[10] = MintCondition({
            saleStartMinusOne: 1667861999,
            editionPlusOne: 501,
            price: 0.127 ether,
            minted: 0
        });

        mintConditions[11] = MintCondition({
            saleStartMinusOne: 1667948399,
            editionPlusOne: 251,
            price: 0.159 ether,
            minted: 0
        });
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external payable {
        MintCondition memory mintCondition = mintConditions[id];
        require(block.timestamp > mintCondition.saleStartMinusOne, "Sale not started");
        require(msg.value == mintCondition.price * amount, "Insufficient funds");
        require(mintCondition.minted + amount < mintCondition.editionPlusOne, "Tokens amount exceeds limit");

        mintCondition.minted += uint16(amount);
        mintConditions[id] = mintCondition;

        _mint(account, id, amount, "");
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function changePrice(uint256 tokenId, uint192 newPrice) public onlyOwner {
        require(newPrice > 0, "Invalid price");
        MintCondition memory mintCondition = mintConditions[tokenId];
        mintCondition.price = newPrice;
        mintConditions[tokenId] = mintCondition;
    }

    function freezeMetadata(string memory permanentURI) external onlyOwner {
        require(!isPermanentMetadata, "Already permanent");
        isPermanentMetadata = true;
        _setURI(permanentURI);
    }
}
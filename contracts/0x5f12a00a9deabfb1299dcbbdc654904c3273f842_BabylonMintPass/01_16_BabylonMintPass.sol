// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./interfaces/IMintPassURI.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

contract BabylonMintPass is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    uint256 public listingId;
    string public constant BASE_EXTENSION = ".json";

    function initialize(
        uint256 listingId_,
        address core_
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC721_init_unchained("BabylonMintPass", "BMP");
        listingId = listingId_;
        transferOwnership(core_);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return IMintPassURI(owner()).getMintPassBaseURI();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        uint256 supply = totalSupply();
        require(amount > 0, "BabylonMintPass: cannot mint 0 tokens");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, supply + i);
        }
    }

    function burn(address from) external onlyOwner returns (uint256) {
        uint256 balance = balanceOf(from);
        require(balance > 0, "BabylonMintPass: cannot burn 0 tokens");
        uint256 tokenToBurn;

        if (balance > 1) {
            for (uint256 i = balance - 1; i > 0; i--) {
                tokenToBurn = tokenOfOwnerByIndex(from, i);
                _burn(tokenToBurn);
            }
        }

        tokenToBurn = tokenOfOwnerByIndex(from, 0);
        _burn(tokenToBurn);

        return balance;
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

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(
            abi.encodePacked(
                currentBaseURI,
                listingId.toString(),
                "/",
                tokenId.toString(),
                BASE_EXTENSION
            )
        )
        : "";
    }
}
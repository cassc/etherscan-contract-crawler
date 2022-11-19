// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@minteeble/smart-contracts/contracts/token/ERC721/IMinteebleStaticMutation.sol";
import "@minteeble/smart-contracts/contracts/token/ERC721/MinteebleERC721A.sol";

interface OldCollection is IERC721 {
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

contract MutantElder is MinteebleERC721A, IMinteebleStaticMutation {
    OldCollection public oldCollection;
    IERC721 public serumCollection;
    bool public publicMintEnabled = false;

    mapping(uint256 => uint256) public oldIds;
    mapping(uint256 => uint256) public oldIdsMutated;
    mapping(uint256 => uint256) public serumIdsUsed;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _mintPrice,
        address _oldCollection,
        address _serumCollection
    ) MinteebleERC721A(_tokenName, _tokenSymbol, _maxSupply, _mintPrice) {
        oldCollection = OldCollection(_oldCollection);
        serumCollection = IERC721(_serumCollection);
    }

    function setPublicMintEnabled(bool _publicMintEnabled) public onlyOwner {
        publicMintEnabled = _publicMintEnabled;
    }

    function oldCollectionItems(address owner)
        public
        view
        returns (uint256[] memory)
    {
        return oldCollection.walletOfOwner(owner);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        override
        canMint(_mintAmount)
        enoughFunds(_mintAmount)
    {
        require(0 == 1, "Method disabled");
    }

    function mintMutant(uint256 oldId, uint256 serumId)
        public
        payable
        canMint(1)
        enoughFunds(1)
    {
        require(oldCollection.ownerOf(oldId) == msg.sender, "Item not owned.");
        require(
            serumCollection.ownerOf(serumId) == msg.sender,
            "Serum not owned"
        );
        require(oldIdsMutated[oldId] != 1, "Item already mutated.");
        require(serumIdsUsed[serumId] != 1, "Serum already used.");

        oldIds[totalSupply() + 1] = oldId;
        oldIdsMutated[oldId] = 1;
        serumIdsUsed[serumId] = 1;

        _safeMint(_msgSender(), 1);
    }

    function publicMintMutant(uint256 serumId)
        public
        payable
        canMint(1)
        enoughFunds(1)
    {
        require(publicMintEnabled, "Mint not enabled");
        require(
            serumCollection.ownerOf(serumId) == msg.sender,
            "Serum not owned."
        );
        require(serumIdsUsed[serumId] != 1, "Serum already used.");

        serumIdsUsed[serumId] = 1;

        _safeMint(_msgSender(), 1);
    }

    function oldCollectionId(uint256 _newId) public view returns (uint256) {
        return oldIds[_newId];
    }
}
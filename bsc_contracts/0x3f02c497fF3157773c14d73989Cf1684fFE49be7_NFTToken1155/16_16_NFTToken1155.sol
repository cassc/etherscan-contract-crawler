// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract NFTToken1155 is ERC1155, Ownable, ERC1155Supply, ERC2981, ERC1155Burnable {
    address marketPlaceAddress;
    
    constructor(address _marketplaceAddress) ERC1155("PurrNFT") {
        marketPlaceAddress = _marketplaceAddress;
    }

    // using Counters for Counters.Counter;
    // Counters.Counter private _tokenIds;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => string) public uris;
    bool private batchEnabled = false;

    //Request URL: https://purrnft-test.infura-ipfs.io/ipfs/Qmaa6TuP2s9pSKczHF4rwWhTKUdygrrDs8RmYYqCjP3Hye

    function create(
        uint256 tokenId,
        uint256 _initialSupply,
        string calldata _uri,
        uint96 royaltyFraction,
        address receiver,
        bytes calldata _data
    ) public returns (uint256) {
        require(
            _initialSupply > 0,
            "CREATE: Initial supply must be greater than 0"
        );

        _mint(msg.sender, tokenId, _initialSupply, _data);
        creators[tokenId] = msg.sender;
        uris[tokenId] = _uri;
        tokenSupply[tokenId] = _initialSupply;
        setApprovalForAll(marketPlaceAddress, true);
       
        if (royaltyFraction > 0)
            _setTokenRoyalty(tokenId, receiver, royaltyFraction);

        return tokenId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** @dev URI override for OpenSea traits compatibility. */

    function uri(uint256 tokenId) public view override returns (string memory) {
        // Tokens minted above the supply cap will not have associated metadata.
        require(
            tokenId >= 0 && tokenId <= tokenSupply[tokenId],
            "ERC1155Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    uris[tokenId],
                    Strings.toString(tokenId),
                    ".json"
                )
            );
        //return "test123.json"
    }

    function mint(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        require(batchEnabled == true, "MINT: You must use the create function");
        //_tokenIds.increment();
        //uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        require(
            batchEnabled == true,
            "MINTBATCH: You must use the create function"
        );
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
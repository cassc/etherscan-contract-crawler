// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev ERC721 token with batch mint functionality that only contract owner can call.
 * Token id increases incrementally.
 */
contract BatchNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIds;

    uint16 public totalSupply;

    // Base URI shared by token and contract metadata
    string private _sharedBaseURI = "ipfs://PLACEHOLDER_URI/";

    constructor(
        string memory name_,
        string memory symbol_,
        uint16 supply_,
        string memory sharedBaseURI_
    ) ERC721(name_, symbol_) {
        setSupply(supply_);
        setSharedBaseURI(sharedBaseURI_);
    }

    /**
     * @dev Withdraw all ether in the contract
     */
    function withdrawAll(address vault_) public payable onlyOwner {
        uint256 balance = address(this).balance;
        payable(vault_).transfer(balance);
    }

    /**
     * @dev Update the supply of NFT.
     */
    function setSupply(uint16 supply_) public onlyOwner {
        totalSupply = supply_;
    }

    /**
     * @dev Update the shared base URI
     */
    function setSharedBaseURI(string memory uri_) public onlyOwner {
        _sharedBaseURI = uri_;
    }

    /**
     * @dev Contract URI for OpenSea
     * @return the contract URI string
     * https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view returns (string memory) {
        return
            string(abi.encodePacked(_sharedBaseURI, "contract-metadata.json"));
    }

    /**
     * @dev Batch mint NFTs to an array of addresses, require enough supply left.
     * @return the minted token ids
     */
    function batchMint(address[] memory addresses_, uint16 amount_)
        public
        onlyOwner
        returns (uint256[] memory)
    {
        require(
            totalSupply >= addresses_.length * amount_ + _tokenIds.current(),
            "not enough supply"
        );

        uint256[] memory ids = new uint256[](addresses_.length * amount_);
        for (uint16 i = 0; i < addresses_.length; i++) {
            for (uint16 j = 0; j < amount_; j++) {
                _tokenIds.increment();

                uint256 newItemId = _tokenIds.current();
                _safeMint(addresses_[i], newItemId);

                ids[i * amount_ + j] = newItemId;
            }
        }

        return ids;
    }

    /**
     * @dev Burn a given token by calling internel `_burn` function, requires owner or approved account
     */
    function burn(uint256 tokenId_) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId_),
            "Caller is not owner nor approved"
        );
        _burn(tokenId_);
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _sharedBaseURI;
    }
}
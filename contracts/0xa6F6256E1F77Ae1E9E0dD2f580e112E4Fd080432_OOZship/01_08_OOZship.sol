//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./IERC721C.sol";

contract OOZship is IERC721C, ERC721AQueryable, Ownable {

    // Whether base URI is permanent. Once set, base URI is immutable.
    bool private _baseURIPermanent;

    // The total mintable supply.
    uint256 internal _maxMintableSupply;

    // Current base URI.
    string private _currentBaseURI;

    // The suffix for the token URL, e.g. ".json".
    string private _tokenURISuffix;

    address public oozContractAddr;
    string private _lastMetadata;

    constructor(
        string memory collectionName,
        string memory collectionSymbol
    ) ERC721A(collectionName, collectionSymbol) {

        _maxMintableSupply = 9999;
        _tokenURISuffix = ".json";
        _currentBaseURI = "https://bafybeiatd2v6fbrr254lmtogk2afc7vlwrgedxl2fllcjnojlqdzyreesa.ipfs.nftstorage.link/";
        _lastMetadata = "https://bafkreiafax4xq3em33cjsikcwmgpvbtqjdbf2lpq6ii4p25q45xqavdy4q.ipfs.nftstorage.link/";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function bulkTransfer(address[] calldata _to, uint256[] calldata _id) public {
        require(_to.length == _id.length, "Receivers and IDs are different length");
        for (uint256 i = 0; i < _to.length; i++) {
            transferFrom(msg.sender, _to[i], _id[i]);
        }
    }

    function setOozContractAddr(address addr) external onlyOwner {
        oozContractAddr = addr;
    }

    function isApprovedForAll(address owner, address operator) public view virtual override (ERC721A, IERC721A) returns (bool) {
        if (operator == oozContractAddr) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function setLastMetadata(string calldata lastMetadata) external onlyOwner {
        _lastMetadata = lastMetadata;
    }

    /**
     * @dev Returns whether it has enough supply for the given qty.
     */
    modifier hasSupply(uint256 qty) {
        if (totalSupply() + qty > _maxMintableSupply) revert NoSupplyLeft();
        _;
    }

    /**
     * @dev Returns maximum mintable supply.
     */
    function getMaxMintableSupply() external view override returns (uint256) {
        return _maxMintableSupply;
    }

    /**
     * @dev Sets maximum mintable supply.
     *
     * New supply cannot be larger than the old.
     */
    function setMaxMintableSupply(uint256 maxMintableSupply)
        external
        virtual
        onlyOwner
    {
        if (maxMintableSupply > _maxMintableSupply) {
            revert CannotIncreaseMaxMintableSupply();
        }
        _maxMintableSupply = maxMintableSupply;
        emit SetMaxMintableSupply(maxMintableSupply);
    }

    /**
     * @dev Returns number of minted token for a given address.
     */
    function totalMintedByAddress(address a)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _numberMinted(a);
    }

    /**
     * @dev Mints token(s) by owner.
     *
     * NOTE: This function bypasses validations thus only available for owner.
     * This is typically used for owner to  pre-mint or mint the remaining of the supply.
     */
    function ownerMint(uint32 qty, address to)
        external
        onlyOwner
        hasSupply(qty)
    {
        _safeMint(to, qty);
    }

    /**
     * @dev Withdraws funds by owner.
     */
    function withdraw() external onlyOwner {
        uint256 value = address(this).balance;
        (bool success, ) = msg.sender.call{value: value}("");
        if (!success) revert WithdrawFailed();
        emit Withdraw(value);
    }

    /**
     * @dev Sets token base URI.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        if (_baseURIPermanent) revert CannotUpdatePermanentBaseURI();
        _currentBaseURI = baseURI;
        emit SetBaseURI(baseURI);
    }

    /**
     * @dev Sets token base URI permanent. Cannot revert.
     */
    function setBaseURIPermanent() external onlyOwner {
        _baseURIPermanent = true;
        emit PermanentBaseURI(_currentBaseURI);
    }

    /**
     * @dev Returns token URI suffix.
     */
    function getTokenURISuffix()
        external
        view
        override
        returns (string memory)
    {
        return _tokenURISuffix;
    }

    /**
     * @dev Sets token URI suffix. e.g. ".json".
     */
    function setTokenURISuffix(string calldata suffix) external onlyOwner {
        _tokenURISuffix = suffix;
    }

    /**
     * @dev Returns token URI for a given token id.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (tokenId == 9999) {
            return _lastMetadata;
        }

        string memory baseURI = _currentBaseURI;
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        _toString(tokenId),
                        _tokenURISuffix
                    )
                )
                : "";
    }

    /**
     * @dev Returns chain id.
     */
    function _chainID() private view returns (uint256) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }
        return chainID;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

error InvalidProof();
error MintNotEnabled();
error MintedTooMany();
error MintedOverSupply();
error BadMint();
error NullAddress();

/**
 * @title Power Pass Contract
 * @author Gabriel Cebrian (https://twitter.com/gabceb)
 * @notice This contract handles the distribution of Power Pass ERC721 tokens.
 */
contract PowerPass is ERC721AQueryable, Pausable, Ownable {
    uint64 public maxMintAmount = 10;
    bool public mintEnabled = false;

    uint256 public maxSupply;
    uint256 public price = 0.03 ether;
    string public baseTokenURI;

    constructor(string memory _baseTokenURI, uint256 _maxSupply)
        ERC721A("POWER PASS", "POWER")
    {
        baseTokenURI = _baseTokenURI;
        maxSupply = _maxSupply;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(IERC721A, ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            string(abi.encodePacked(baseTokenURI, _toString(tokenId), ".json"));
    }

    function mintedByAddress(address wallet) public view virtual returns (uint256) {
        return _getAux(wallet);
    }

    /**
     * Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * Update the max mint
     */
    function setMaxMintAmount(uint64 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    /**
     * Updates if mint is enabled
     */
    function setMintEnabled(bool _mintEnabled) external onlyOwner {
        mintEnabled = _mintEnabled;
    }

    /**
     * Update the base token URI
     */
    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function mint(uint64 amount) external payable {
        if (!mintEnabled) {
            revert MintNotEnabled();
        }

        if (msg.sender != tx.origin) {
            revert BadMint();
        }

        uint64 alreadyMinted = _getAux(msg.sender);

        if (amount * price != msg.value) {
            revert BadMint();
        }

        if (alreadyMinted + amount > maxMintAmount) {
            revert MintedTooMany();
        }

        if (totalSupply() + amount >= maxSupply) {
            revert MintedOverSupply();
        }

        _setAux(msg.sender, alreadyMinted + amount);

        _mint(msg.sender, amount);
    }

    function ownerMint(address[] calldata receivers)
        external
        payable
        onlyOwner
    {
        uint256 length = receivers.length;
        for (uint256 i = 0; i < length;) {
            _mint(receivers[i], 1);
            unchecked { i += 1; }
        }
    }

    function ownerBulkMint(address receiver, uint256 amount)
        external
        payable
        onlyOwner
    {
        _mint(receiver, amount);
    }

    function setBulkExtraData(uint256[] calldata tokens, uint24 extraData) external onlyOwner {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length;) {
            _setExtraDataAt(tokens[i], extraData);
            unchecked { i += 1; }
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 ids,
        uint256 amounts
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, ids, amounts);
    }

    /**
     * @notice Allow contract owner to withdraw funds to its own account.
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
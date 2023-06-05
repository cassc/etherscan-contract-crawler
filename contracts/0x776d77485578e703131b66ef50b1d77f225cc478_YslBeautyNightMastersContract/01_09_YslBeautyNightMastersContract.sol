//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Teams.sol";
import "./Withdrawable.sol";
import "./Tippable.sol";
import "./ERC721AQueryable.sol";

error CapExceeded();
error TransactionCapExceeded();
error ExcessiveOwnedMints();
error PublicMintClosed();
error InvalidPayment();

contract YslBeautyNightMastersContract is Ownable, Teams, ERC721AQueryable, Withdrawable, Tippable {
    constructor() ERC721A("YSL Beauty Night Masters", "YSLB Night") {}

    string private _baseTokenURI = "ipfs://QmVBJkFChMxDd6RZdRDButTL17edMKh4maCA1cHZyBqMbw/";
    string private _baseTokenExtension = ".json";

    string private _contractURI = "";

    bool public mintingOpen = false;
    uint256 public maxBatchSize = 1;
    uint256 public maxWalletMints = 5;
    uint256 public price = 0.2 ether;

    uint256 public immutable COLLECTION_SIZE = 300;

    /////////////// Admin Mint Functions
    /**
     * @dev Mints a token to an address with a tokenURI.
     * This is owner only and allows a fee-free drop
     * @param _to address of the future owner of the token
     * @param _qty amount of tokens to drop the owner
     */
    function mintToAdminV2(address _to, uint256 _qty) public onlyTeamOrOwner {
        if (_qty == 0) revert MintZeroQuantity();
        if (currentTokenId() + _qty > COLLECTION_SIZE) revert CapExceeded();
        _safeMint(_to, _qty);
    }

    /////////////// PUBLIC MINT FUNCTIONS
    /**
     * @dev Mints tokens to an address in batch.
     * fee may or may not be required*
     * @param _to address of the future owner of the token
     * @param _amount number of tokens to mint
     */
    function mintToMultiple(address _to, uint256 _amount) public payable {
        if (_amount > maxBatchSize) revert TransactionCapExceeded();
        if (!mintingOpen) revert PublicMintClosed();

        if (!canMintAmount(_to, _amount)) revert ExcessiveOwnedMints();
        if (currentTokenId() + _amount > COLLECTION_SIZE) revert CapExceeded();
        if (!priceIsRight(msg.value, getPrice(_amount))) revert InvalidPayment();

        _safeMint(_to, _amount);
    }

    function openMinting() public onlyTeamOrOwner {
        mintingOpen = true;
    }

    function stopMinting() public onlyTeamOrOwner {
        mintingOpen = false;
    }

    function setPrice(uint256 _feeInWei) public onlyTeamOrOwner {
        require(!mintingOpen, "ERC721APlus: cannot set price while sale is open");
        price = _feeInWei;
    }

    function getPrice(uint256 _count) public view returns (uint256) {
        return price * _count;
    }

    /**
     * @dev Check if wallet over maxWalletMints
     * @param _address address in question to check if minted count exceeds max
     */
    function canMintAmount(address _address, uint256 _amount) public view returns (bool) {
        if (_amount == 0) revert ValueCannotBeZero();
        return (_numberMinted(_address) + _amount) <= maxWalletMints;
    }

    /**
     * @dev Update the maximum amount of tokens that can be minted by a unique wallet
     * @param _newWalletMax the new max of tokens a wallet can mint. Must be >= 1
     */
    function setWalletMax(uint256 _newWalletMax) public onlyTeamOrOwner {
        if (_newWalletMax == 0) revert ValueCannotBeZero();
        maxWalletMints = _newWalletMax;
    }

    /**
     * @dev Allows owner to set Max mints per tx
     * @param _newMaxMint maximum amount of tokens allowed to mint per tx. Must be >= 1
     */
    function setMaxMint(uint256 _newMaxMint) public onlyTeamOrOwner {
        if (_newMaxMint == 0) revert ValueCannotBeZero();
        maxBatchSize = _newMaxMint;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        string memory extension = baseTokenExtension();

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), extension)) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata uri) external onlyTeamOrOwner {
        _baseTokenURI = uri;
    }

    function baseTokenExtension() public view returns (string memory) {
        return _baseTokenExtension;
    } 

    function setBaseTokenExtension(string calldata extension) external onlyTeamOrOwner {
        _baseTokenExtension = extension;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string calldata uri) external onlyTeamOrOwner {
        _contractURI = uri;
    }

    function currentTokenId() public view returns (uint256) {
        return _totalMinted();
    }
}
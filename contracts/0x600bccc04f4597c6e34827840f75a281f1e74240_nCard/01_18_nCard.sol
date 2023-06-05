// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "AccessControlEnumerable.sol";
import "ECDSA.sol";
import "BitMaps.sol";
import "UnburnableERC721.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract nCard is UnburnableERC721, AccessControlEnumerable {

    using ECDSA for bytes32;
    using BitMaps for BitMaps.BitMap;

    // Limit on totalSupply
    uint256 public immutable collectionSize;

    // Predetermined account that gets the profits. Cannot be changed.
    address payable immutable _beneficiary;

    string private _baseTokenURI;

    // Minting price of one token.
    uint256 private _price;

    // Unix epoch seconds. Tokens may be minted until this moment.
    uint256 private _priceValidUntil;

    // Minting requires a valid signature by _signer.
    address private _signer;

    // Every minting slot can only be used once. Mark used slots in a BitMap.
    BitMaps.BitMap private _slots;


    event SignerChanged(address newSigner);
    event MintPriceChanged(uint256 newPrice, uint newPriceValidUntil);


    constructor(
        string memory name, string memory symbol, string memory baseTokenURI, uint256 mintPrice,
        uint256 priceValidUntil, uint256 max, address admin, address payable beneficiary, address signer
    ) UnburnableERC721(name, symbol) {
        collectionSize = max;
        _baseTokenURI = baseTokenURI;
        _beneficiary = beneficiary;
        _signer = signer;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        setPrice(mintPrice, priceValidUntil);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    // Set the minting price and the last moment in unix epoch seconds this price will be valid.
    function setPrice(uint256 mintPrice, uint256 priceValidUntil) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _price = mintPrice;
        _priceValidUntil = priceValidUntil;
        emit MintPriceChanged(_price, _priceValidUntil);
    }

    // @return The minting price and the closing time in unix epoch seconds.
    function price() public view returns (uint256, uint256) {
        return (_price, _priceValidUntil);
    }

    // @return if a given slot ID has been already used.
    function slotUsed(uint256 slotId) public view returns (bool) {
        return _slots.get(slotId);
    }

    function mint(uint256 amount, uint256 slotId, uint256 validUntil, bytes memory signature) external payable {
        // Check signature.
        require(_canMint(msg.sender, amount, slotId, validUntil, signature), "TestNft: Must have valid signing");

        // Check amount.
        require(totalSupply() + amount <= collectionSize, "TestNft: Cannot mint over collection size");

        // Check price.
        require(msg.value >= (amount * _price), "nCard: Insufficient eth sent");

        // Check temporal validity.
        require(block.timestamp <= validUntil, "nCard: Slot must be used before expiration time");
        require(block.timestamp <= _priceValidUntil, "nCard: The price has expired");

        // Check if the slot is still free and mark it used.
        require(!_slots.get(slotId), "nCard: Slot already used");
        _slots.set(slotId);

        // Mint.
        _safeMintMany(msg.sender, amount);
    }

    function batchMint(address[] memory accounts, uint256[] memory amounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(accounts.length == amounts.length, "nCard: Incorrect length match for accounts and amounts");

        uint256 originalSupply = totalSupply();
        uint256 mintedAmount = 0;

        for (uint256 i = 0; i < accounts.length; i++) {
            _safeMintMany(accounts[i], amounts[i]);
            mintedAmount += amounts[i];
        }

        require(originalSupply + mintedAmount <= collectionSize, "nCard: Cannot mint over collection size");
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControlEnumerable, UnburnableERC721) returns (bool){
        return AccessControlEnumerable.supportsInterface(interfaceId) || UnburnableERC721.supportsInterface(interfaceId);
    }

    function changeSigner(address newSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _signer = newSigner;
        emit SignerChanged(_signer);
    }

    function _canMint(address minter, uint256 amount, uint256 slotId, uint256 validUntil, bytes memory signature) internal view returns (bool) {
        return keccak256(abi.encodePacked(minter, amount, slotId, validUntil)).toEthSignedMessageHash().recover(signature) == _signer;
    }

    // @notice Rescue other tokens sent accidentally to this contract.
    function rescueERC721(IERC721 tokenToRescue, uint256 n) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        tokenToRescue.safeTransferFrom(address(this), _msgSender(), n);
    }

    // @notice Rescue other tokens sent accidentally to this contract.
    function rescueERC20(IERC20 tokenToRescue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenToRescue.transfer(_msgSender(), tokenToRescue.balanceOf(address(this)));
    }

    // @notice Send all of the native currency to determined beneficiary (PaymentSplitter).
    function release() external {
        Address.sendValue(_beneficiary, address(this).balance);
    }

}
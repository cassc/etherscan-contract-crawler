// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "AccessControlEnumerable.sol";
import "ECDSA.sol";
import "BitMaps.sol";
import "IERC721.sol";

import "ERC721AQueryable.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract InscriptedSatoshisOrdinals is ERC721AQueryable, AccessControlEnumerable {

    using ECDSA for bytes32;
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    // Limit on totalSupply. Initialized on deployment.
    uint256 public immutable collectionSize;

    // Predetermined account that gets the profits.
    address payable public beneficiary;

    // URI base for token metadata.
    string public baseURI;
    string public tokenURISuffix = ".json";

    // Minting price of one token.
    uint256 private _price;

    // Unix epoch seconds. Tokens may be minted until this moment.
    uint256 private _priceValidUntil;

    // Minting requires a valid signature by signer. (Off-chain whitelist check, etc.)
    address public signer;

    // Every minting slot can only be used once. Mark used slots in a BitMap.
    BitMaps.BitMap private _slots;

    // Every token has btc address that it will be minted to
    mapping(uint256 => string) public btcAddresses;

    event SignerChanged(address newSigner);
    event BeneficiaryChanged(address newBeneficiary);
    event MintPriceChanged(uint256 newPrice, uint newPriceValidUntil);
    event BtcAddressAdded(uint256 tokenId, string btcAddress);


    constructor(
        string memory name, string memory symbol, string memory baseTokenURI, uint256 mintPrice,
        uint256 priceValidUntil, uint256 max, address[] memory admins, address payable beneficiary_, address signer_
    ) ERC721A(name, symbol) {
        collectionSize = max;
        baseURI = baseTokenURI;
        beneficiary = beneficiary_;
        signer = signer_;

        // Set up admin accounts and ownership.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }

        setPrice(mintPrice, priceValidUntil);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), tokenURISuffix)) : "";
    }

    function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    function setTokenURISuffix(string memory suffix) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenURISuffix = suffix;
    }

    // @notice Set minting price and until what timestamp (in epoch seconds) is the minting open with this price.
    function setPrice(uint256 mintPrice, uint256 priceValidUntil) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _price = mintPrice;
        _priceValidUntil = priceValidUntil;
        emit MintPriceChanged(_price, _priceValidUntil);
    }

    // @return The minting price and the closing time in unix epoch seconds.
    function price() public view returns (uint256, uint256) {
        return (_price, _priceValidUntil);
    }

    // @notice Set a new signer address that is use to sign minting permits.
    function changeSigner(address newSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = newSigner;
        emit SignerChanged(signer);
    }


    function changeBeneficiary(address payable newBeneficiary) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newBeneficiary != address(0), "Beneficiary must not be the zero address");
        beneficiary = newBeneficiary;
        emit BeneficiaryChanged(newBeneficiary);
    }

    // @notice Check if a minting slot is used.
    // @return true if the minting slot is used.
    function slotUsed(uint256 slotId) public view returns (bool) {
        return _slots.get(slotId);
    }

    function mint(uint256 amount, uint256 slotId, uint256 validUntil, bytes memory signature) external payable {
        // Check signature.
        require(_canMint(msg.sender, amount, slotId, validUntil, signature), "InscriptedSatoshis: Must have valid signing");

        // Check amount.
        require(totalSupply() + amount <= collectionSize, "InscriptedSatoshis: Cannot mint over collection size");

        // Check price.
        require(msg.value >= (amount * _price), "InscriptedSatoshis: Insufficient eth sent");

        // Check temporal validity.
        require(block.timestamp <= validUntil, "InscriptedSatoshis: Slot must be used before expiration time");
        require(block.timestamp <= _priceValidUntil, "InscriptedSatoshis: The price has expired");

        // Check if the slot is still free and mark it used.
        require(!_slots.get(slotId), "InscriptedSatoshis: Slot already used");
        _slots.set(slotId);

        // Mint.
        _safeMint(msg.sender, amount);
    }

    function setBtcAddress(uint256 tokenId, string memory btcAddress) external {
        address sender = _msgSender();
        require(ownerOf(tokenId) == sender, "Not owner of token");
        require(bytes(btcAddresses[tokenId]).length == 0, "BTC address was given already");

        btcAddresses[tokenId] = btcAddress;

        emit BtcAddressAdded(tokenId, btcAddress);
    }

    function batchMint(address[] memory accounts, uint256[] memory amounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(accounts.length == amounts.length, "InscriptedSatoshis: Incorrect length match for accounts and amounts");

        uint256 originalSupply = totalSupply();
        uint256 mintedAmount = 0;

        for (uint256 i = 0; i < accounts.length; i++) {
            _safeMint(accounts[i], amounts[i]);
            mintedAmount += amounts[i];
        }

        require(originalSupply + mintedAmount <= collectionSize, "InscriptedSatoshis: Cannot mint over collection size");
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A, AccessControlEnumerable) returns (bool){
        return AccessControlEnumerable.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
    }

    function _canMint(address minter, uint256 amount, uint256 slotId, uint256 validUntil, bytes memory signature) internal view returns (bool) {
        return keccak256(abi.encodePacked(minter, amount, slotId, validUntil)).toEthSignedMessageHash().recover(signature) == signer;
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if(!hasRole(DEFAULT_ADMIN_ROLE, from)) {
            require(from == address(0) || to == address(0), "Receipt markers are not transferable");
        }
    }


    // @notice Rescue other tokens sent accidentally to this contract.
    function rescueERC721(IERC721 tokenToRescue, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenToRescue.safeTransferFrom(address(this), _msgSender(), tokenId);
    }

    // @notice Rescue other tokens sent accidentally to this contract.
    function rescueERC20(IERC20 tokenToRescue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenToRescue.transfer(_msgSender(), tokenToRescue.balanceOf(address(this)));
    }

    // @notice Send all of the native currency to predetermined beneficiary.
    function release() external {
        payable(beneficiary).send(address(this).balance);
    }

}
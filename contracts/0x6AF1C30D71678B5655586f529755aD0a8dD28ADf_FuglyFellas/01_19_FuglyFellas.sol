// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "AccessControlEnumerable.sol";
import "ECDSA.sol";
import "BitMaps.sol";
import "IERC2981.sol";
import "Context.sol";
import "UnburnableERC721.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract FuglyFellas is UnburnableERC721, AccessControlEnumerable, IERC2981 {

    using ECDSA for bytes32;
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    // Limit on totalSupply
    uint256 public immutable collectionSize;

    // URI base for token metadata.
    string public baseURI;
    string public tokenURISuffix = ".json";

    // Minting requires a valid signature by signer.
    address public signer;

    // Every minting slot can only be used once. Mark used slots in a BitMap.
    BitMaps.BitMap private _slots;

    // RoyaltyInfo
    address payable public royaltyBeneficiary;
    uint16 public royaltyPermillage;

    // Ownable
    address public owner; /* For OpenSea, etc. */

    // Events
    event SignerChanged(address newSigner);
    event SlotUsed(uint256 slotId, uint256 tokenId, uint256 amount, address minter);
    event RoyaltyInfoChanged(address beneficiary, uint16 permillage);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor(
        string memory name, string memory symbol, string memory baseTokenURI, uint256 max, address signer_, address[] memory admins, address payable beneficiary, uint8 royaltyPermillage_
    ) UnburnableERC721(name, symbol) {
        // Set up admin accounts and ownership.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
        transferOwnership(msg.sender);

        collectionSize = max;
        baseURI = baseTokenURI;

        // Signer
        signer = signer_;
        emit SignerChanged(signer_);

        // RoyaltyInfo
        require(beneficiary != address(0), "Beneficiary must not be the zero address");
        royaltyBeneficiary = beneficiary;
        require(royaltyPermillage_ <= 1000, "Permillage must be between 0 and 1000");
        royaltyPermillage = royaltyPermillage_;
        emit RoyaltyInfoChanged(beneficiary, royaltyPermillage_);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    function setTokenURISuffix(string memory suffix) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenURISuffix = suffix;
    }

    // @return The minting price and the closing time in unix epoch seconds.
    function price() public view returns (uint256, uint256) {
        return (0, 5000000000);
    }

    // @return if a given slot ID has been already used.
    function slotUsed(uint256 slotId) public view returns (bool) {
        return _slots.get(slotId);
    }

    function mint(uint256 amount, uint256 slotId, uint256 validUntil, bytes memory signature) external payable {
        // Check signature.
        require(_canMint(msg.sender, amount, slotId, validUntil, signature), "FuglyFellas: Must have valid signing");

        // Check amount.
        require(totalSupply() + amount <= collectionSize, "FuglyFellas: Cannot mint over collection size");

        // Check temporal validity.
        require(block.timestamp <= validUntil, "FuglyFellas: Slot must be used before expiration time");

        // Check if the slot is still free and mark it used.
        require(!_slots.get(slotId), "FuglyFellas: Slot already used");
        _slots.set(slotId);

        // Mint.
        _safeMintMany(msg.sender, amount);
    }

    function batchMint(address[] memory accounts, uint256[] memory amounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(accounts.length == amounts.length, "FuglyFellas: Incorrect length match for accounts and amounts");

        uint256 originalSupply = totalSupply();
        uint256 mintedAmount = 0;

        for (uint256 i = 0; i < accounts.length; i++) {
            _safeMintMany(accounts[i], amounts[i]);
            mintedAmount += amounts[i];
        }

        require(originalSupply + mintedAmount <= collectionSize, "FuglyFellas: Cannot mint over collection size");
    }

    function supportsInterface(bytes4 interfaceId) public view override(IERC165, AccessControlEnumerable, UnburnableERC721) returns (bool){
        return interfaceId == type(IERC2981).interfaceId || AccessControlEnumerable.supportsInterface(interfaceId) || UnburnableERC721.supportsInterface(interfaceId);
    }

    function changeSigner(address newSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = newSigner;
        emit SignerChanged(signer);
    }

    function setRoyaltyInfo(address payable beneficiary, uint16 permillage) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(beneficiary != address(0), "Beneficiary must not be the zero address");
        require(permillage <= 1000, "Permillage must be between 0 and 1000");
        royaltyBeneficiary = beneficiary;
        royaltyPermillage = permillage;
        emit RoyaltyInfoChanged(beneficiary, permillage);
    }

    function _canMint(address minter, uint256 amount, uint256 slotId, uint256 validUntil, bytes memory signature) internal view returns (bool) {
        return keccak256(abi.encodePacked(minter, amount, slotId, validUntil)).toEthSignedMessageHash().recover(signature) == signer;
    }


    // @notice Rescue other tokens sent accidentally to this contract.
    function rescueERC721(IERC721 tokenToRescue, uint256 n) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        tokenToRescue.safeTransferFrom(address(this), _msgSender(), n);
    }

    // @notice Rescue other tokens sent accidentally to this contract.
    function rescueERC20(IERC20 tokenToRescue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenToRescue.transfer(_msgSender(), tokenToRescue.balanceOf(address(this)));
    }

    // @notice Rescue all of the native currency.
    function release() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    // @notice ERC2981 RoyaltyInfo.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyBeneficiary, (_salePrice * royaltyPermillage) / 1000);
    }

    // @dev Ownable
    function renounceOwnership() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(false, "Not supported.");
    }

    // @dev Ownable
    function transferOwnership(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), tokenURISuffix)) : "";
    }

}
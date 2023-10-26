// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/**
 * Generalities:
 * This Smart Contract has 2 main roles: ADMIN and SIGNER. Admin is used for most "management" functions.
 * The SIGNER role is very specific and directly related to the purchase land through the website.
 * The VOUCHER (created by the website) is a bit like a Cart. It contains a price, a list of tokens, and expiration date and the wallet of the person buying.
 * The VOUCHER is signed server side and its authenticity is validated by the smart contract using the ECDSA recover function.
 * The buyLand function is open to anyone, and the function can freely mint and transfer lands. A valid VOUCHER is required to process, and this can only happen through the website.
 *
 *
 *
 */

/// @custom:security-contact [email protected]
contract TwvTest is ERC721, EIP712, IERC2981, Ownable, AccessControlEnumerable, Pausable, ERC721Burnable {
    // SIGNER role is used to sign the voucher on the server backend
    bytes32 private constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    string private constant SIGNING_DOMAIN = "WvTest-Voucher"; // Value is Temporary, will change when ready for production
    string private constant SIGNATURE_VERSION = "1"; // Value is Temporary, will change when ready for production

    // Wallet Managing the transfer of winky token in ERC-20
    IERC20 private WNK_TOKEN;

    address private _royaltiesRecipient;
    uint256 private _royaltyPct;

    string private baseTokenUri;

    /**
     * @dev Constructor call when deploying the smart contract
     *
     * Requirements:
     *
     * - `signer` Address that will be use to sign the Vouchers on the server backend
     * - `wnkAddress` Winkies ERC20 token smart contract address
     * - `tokenUriUrl` URL of the token metadatas
     * - An initial default royalties of 10% will be initiated at deployement
     */
    constructor(address signer, address wnkAddress, string memory tokenUriUrl)
        ERC721("TwvTest", "TWVTK")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _grantRole(SIGNER_ROLE, signer);
            _royaltiesRecipient = msg.sender;
            WNK_TOKEN = IERC20(wnkAddress);
            baseTokenUri = tokenUriUrl;
            _royaltyPct = 10;
        }

    /**
     * @dev A Voucher is Generated on the server backend once a transaction is initiated by a user buying a land on the website.
     * Requirements:
     *
     * - `tokenIds` List of token IDs to buy
     * - `price` Price to apply for the whole transaction. (not a single land)
     * - `redeemer` Address of the buyer to receive the lands
     * - `expiration` A delay used to temporarily lock other user from creating another transaction with the same items at the same time.
     * - `signature` The voucher hash, signed by the AWS KMS signing service
     */
    struct NFTVoucher {
        uint256[] tokenIds;
        uint256 price;
        address redeemer;
        uint expiration;
        bytes signature;
    }

    /**
     * @dev WalletNfts is being used to mint a series of land and give them to a specific user
     * Requirements:
     *
     * - `walletAddress` Receiver address
     * - `tokenIds` List of lands to mind and transfer
     */
    struct WalletNfts {
        address walletAddress;
        uint256[] tokenIds;
    }

    function intArrayToString(uint256[] memory intArray) internal pure returns (string memory) {
        string memory result = "[";
        string memory prefix = "";
        for (uint i = 0; i < intArray.length; i++) {
            if (i > 0) {
               prefix = ","; 
            }
            result = string(abi.encodePacked(result, prefix, Strings.toString(intArray[i])));
        }
        return string(abi.encodePacked(result, "]"));
    }

    function setBaseTokenUri(string memory _baseTokenUri) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        baseTokenUri = _baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId)));
    }

    /**
     * @dev _hash is used to computer a signature from the Voucher hash and then validate that the signer is the same as granted
     * Requirements:
     *
     * - `voucher` Receive a voucher in parameter
     */
    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("NFTVoucher(uint256[] tokenIds,uint256 price,address redeemer,uint expiration)"),
        keccak256(bytes(intArrayToString(voucher.tokenIds))),
        voucher.price,
        voucher.redeemer,
        voucher.expiration
        )));
    }

    /**
     * @dev _verify the Voucher Hash     * Requirements:
     *
     * - `voucher` Receive a voucher in parameter
     */
    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    /**
     * @dev buyLand is called the a potention buyer after having selected their items on the web site.
     *
     * - `voucher` The data indicating what is the nature of the transaction
     */
    function buyLandWnk(NFTVoucher calldata voucher) external whenNotPaused {
        // Make sure the voucher is legit and signed by our keys
        address signer = _verify(voucher);
        require(hasRole(SIGNER_ROLE, signer), "Signature invalid or unauthorized for signer.");
        // Make sure the redemmer is not the sender
        require(msg.sender == voucher.redeemer, "This address has not been authorized to use this voucher.");
        require(block.timestamp < voucher.expiration, "This voucher is expired.");
        uint256 allowance = WNK_TOKEN.allowance(msg.sender, address(this));
        require(allowance >= voucher.price, "Insufficient funds to buy these lands.");
        //Directly transfer the lands into the sender memory
        WNK_TOKEN.transferFrom(msg.sender, address(this), voucher.price);
        for (uint i = 0; i < voucher.tokenIds.length; i++) {
            _mint(msg.sender, voucher.tokenIds[i]);
        }
    }

    /**
     * @dev Function to withdraw a certain quantity of Winkies
     *
     * - `quantity` The quantity to send to the main wallet
     */
    function withdrawWnk(uint256 quantity) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        require(quantity > 0, "No WNK token to transfer.");
        uint256 wnkAmountAvailable = WNK_TOKEN.balanceOf(address(this));
        require(quantity <= wnkAmountAvailable, "The quantity of WNK to transfer can't be higher that the total amount of WNK available.");
        WNK_TOKEN.transfer(msg.sender, quantity);
    }

    function availableWnkToWithdraw() external view returns (uint256) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        return WNK_TOKEN.balanceOf(address(this));
    }

    function mintByOwner(WalletNfts[] calldata nftsToMint) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        for (uint walletCpt = 0; walletCpt < nftsToMint.length; walletCpt++) {
            WalletNfts memory walletNfts = nftsToMint[walletCpt];
            for (uint tokenIdCpt = 0; tokenIdCpt < walletNfts.tokenIds.length; tokenIdCpt++) {
                _mint(walletNfts.walletAddress, walletNfts.tokenIds[tokenIdCpt]);
            }
        }
    }

    function setRoyaltiesRecipient(address newRecipient) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _royaltiesRecipient = newRecipient;
    }

    function modifySigner(address newSigner) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        address oldSigner = getRoleMember(SIGNER_ROLE, 0);
        _revokeRole(SIGNER_ROLE, oldSigner);
        _grantRole(SIGNER_ROLE, newSigner);
    }
    function grantAdmin(address newAdmin) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }
    function revokeAdmin(address oldAdmin) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        uint256 nbAdminMembers = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        require(nbAdminMembers > 1, "Can't revoke the last admin account.");
        _revokeRole(DEFAULT_ADMIN_ROLE, oldAdmin);
    }

    function setWnkTokenAddress(address wnkAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        WNK_TOKEN = IERC20(wnkAddress);
    }

    // EIP2981 standard royalties return
    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltiesRecipient, (_salePrice * _royaltyPct) / 100);
    }

    function setRoyaltyPct(uint256 royaltyPct) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        _royaltyPct = royaltyPct;
    }

    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        _pause();
    }

    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized operation.");
        _unpause();
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165, AccessControlEnumerable) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
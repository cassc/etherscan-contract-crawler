// SPDX-License-Identifier: MIT
// Creator: P4SD Labs

pragma solidity 0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error OnlyTakesVMTokens();
error CallerIsNotTheOwner();
error IncorrectSignature();
error CannotSetZeroAddress();

interface IVendingCoins is IERC1155 {
    function use(uint256 coin, uint256 quantity) external;
}

contract TheVendingMachine is ERC721A, ERC2981, ERC1155Holder, Ownable {
    using ECDSA for bytes32;

    IVendingCoins private vendingCoins;
    IERC721A private pssssd;

    // ECDSA signing address to permit items to be used
    address public signingAddress;
    string public baseURI;

    event ItemsDispensed(
        address indexed sender,
        uint256 startTokenID,
        uint256 quantity
    );

    event ItemUsed(uint256 indexed itemID, bytes data);
    event ItemUsed(uint256 indexed itemID, uint256 pssssdTokenID, bytes data);
    event ItemUsed(
        uint256 indexed itemID,
        uint256 pssssdTokenID,
        uint256 optionalPssssdTokenID,
        bytes data
    );

    event SigningAddressUpdated(address previousSigner, address newSigner);

    constructor(
        IVendingCoins coinAddress,
        IERC721A pssssdAddress,
        address signer,
        address treasury,
        string memory uri
    ) ERC721A("The Vending Machine", "VM") {
        setCoinAddress(coinAddress);
        setPssssdAddress(pssssdAddress);
        setSigningAddress(signer);
        setRoyaltyInfo(treasury, 500);
        setBaseURI(uri);
    }

    modifier verifyItem(uint256 itemID, bytes memory signature) {
        bytes32 messageHash = keccak256(abi.encodePacked(itemID));
        if (
            signingAddress !=
            messageHash.toEthSignedMessageHash().recover(signature)
        ) revert IncorrectSignature();
        _;
    }

    /**
     * @dev Use an item without a Possessed NFT
     */
    function useItem(
        uint256 itemID,
        bytes memory signature,
        bytes memory data
    ) external verifyItem(itemID, signature) {
        _burn(itemID, true);
        emit ItemUsed(itemID, data);
    }

    /**
     * @dev Use an item on a Possessed NFT and then burn it.
     */
    function useItem(
        uint256 itemID,
        uint256 pssssdTokenID,
        bytes memory signature,
        bytes memory data
    ) external verifyItem(itemID, signature) {
        if (pssssd.ownerOf(pssssdTokenID) != msg.sender)
            revert CallerIsNotTheOwner();

        _burn(itemID, true);
        emit ItemUsed(pssssdTokenID, itemID, data);
    }

    /**
     * @dev Some items take two Possessed NFTs.
     */
    function useItem(
        uint256 itemID,
        uint256 pssssdTokenID,
        uint256 optionalPssssdTokenID,
        bytes memory signature,
        bytes memory data
    ) external verifyItem(itemID, signature) {
        if (
            pssssd.ownerOf(pssssdTokenID) != msg.sender ||
            pssssd.ownerOf(optionalPssssdTokenID) != msg.sender
        ) revert CallerIsNotTheOwner();

        _burn(itemID, true);
        emit ItemUsed(pssssdTokenID, optionalPssssdTokenID, itemID, data);
    }

    /**
     * @dev Mints the items and emits ItemsDispensed.
     */
    function dispenseItems(address receiver, uint256 quantity) private {
        uint256 firstTokenID = _nextTokenId();
        _safeMint(receiver, quantity);
        emit ItemsDispensed(receiver, firstTokenID, quantity);
    }

    /**
     * @dev Get the total minted items
     */
    function getTotalMinted() external view returns(uint256) {
        return _totalMinted();
    }

    // ---- Owner functions ----

    function setCoinAddress(IVendingCoins newAddress) public onlyOwner {
        vendingCoins = newAddress;
    }

    function setPssssdAddress(IERC721A newAddress) public onlyOwner {
        pssssd = newAddress;
    }

    /**
     * @dev To decrypt ECDSA sigs. May want to change just in case the key ever gets leaked
     */
    function setSigningAddress(address newSigningAddress) public onlyOwner {
        if (newSigningAddress == address(0)) revert CannotSetZeroAddress();
        
        address oldSigningAddress = signingAddress;
        signingAddress = newSigningAddress;
        emit SigningAddressUpdated(oldSigningAddress, newSigningAddress);
    }

    /**
     * @dev Just in case someone burns their token directly rather than via onERC1155Received
     */
    function dispenseItemsManually(address receiver, uint256 quantity)
        external
        onlyOwner
    {
        dispenseItems(receiver, quantity);
    }

    /**
     * @dev Update the royalty percentage (500 = 5%)
     */
    function setRoyaltyInfo(
        address treasuryAddress,
        uint96 newRoyaltyPercentage
    ) public onlyOwner {
        _setDefaultRoyalty(payable(treasuryAddress), newRoyaltyPercentage);
    }

    /**
     * @dev Set the base uri to be used by tokenURI()
     */
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    // ---- Overrides ----

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 amount,
        bytes memory
    ) public override returns (bytes4) {
        if (msg.sender != address(vendingCoins)) revert OnlyTakesVMTokens();
        vendingCoins.use(id, amount);
        dispenseItems(from, amount);
        return this.onERC1155Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, ERC1155Receiver)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC1155Receiver.supportsInterface(interfaceId);
    }
}
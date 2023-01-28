// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// artist: Nick Knight
/// title: IKON-1
/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "./ERC721CollectionBase.sol";
import "./CrossmintPayable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



contract IKON1PublicSale is ERC721CollectionBase, AdminControl, CrossmintPayable {

    address private immutable IKON1_ADDRESS;
    using Strings for uint256;

    constructor(address ikon1Address, address signingAddress) {
        require(!ERC721CollectionBase(ikon1Address).active());
        IKON1_ADDRESS = ikon1Address;

        _initialize(
            // Total supply
            2000,
            // Purchase price (0.2 ETH)
            200000000000000000,
            // Purchase limit
            0,
            // Transaction limit
            0,
            // Presale purchase price
            0,
            // Presale purchase limit
            0,
            signingAddress,
            //0x74f707A456952697f776AFe4774E630322b38dD5,
            false
        );
        purchaseCount = ERC721CollectionBase(ikon1Address).purchaseCount();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CollectionBase, AdminControl) returns (bool) {
        return ERC721CollectionBase.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
    }

    /**
     * @dev See {IERC721Collection-setTransferLocked}.
     */
    function setTransferLocked(bool locked) external override adminRequired {
        _setTransferLocked(locked);
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(uint16 amount) external override adminRequired {
        require(false, "premint not allowed");

        _premint(amount, owner());
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(address[] calldata addresses) external override adminRequired {
        require(false, "premint not allowed");

        _premint(addresses);
    }

    /**
     * @dev See {IERC721Collection-activate}.
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) external override adminRequired {
        _activate(startTime_, duration, presaleInterval_, claimStartTime_, claimEndTime_);
    }

    /**
     * @dev See {IERC721Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC721Collection-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override (ERC721CollectionBase) returns (uint256) {
        return ERC721CollectionBase(IKON1_ADDRESS).balanceOf(owner);
    }

    function _purchase(address to, uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) private {
        _validatePurchaseRestrictions();

        require(amount <= purchaseRemaining() && (transactionLimit == 0 || amount <= transactionLimit), "Too many requested");

        // Make sure we are not over purchaseLimit
        _validatePrice(amount);
        _validatePurchaseRequest(message, signature, nonce);
        address[] memory receivers = new address[](amount);
        for (uint i = 0; i < amount;) {
            receivers[i] = to;
            unchecked {
                i++;
            }
        }
        purchaseCount += amount;
        IERC721Collection(IKON1_ADDRESS).premint(receivers);
    }
    
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) public payable override {
        _purchase(msg.sender, amount, message, signature, nonce);
    }
    
    function purchaseCrossmint(
        address to,
        uint16 amount,
        bytes32 message,
        bytes calldata signature,
        bytes32 nonce
    ) external payable onlyCrossmint {
        _purchase(to, amount, message, signature, nonce);
        emit PurchaseCrossmint(nonce);
    }

    /**
     * @dev mint implementation
     */
    function _mint(address to, uint256) internal override {
        purchaseCount++;
        address[] memory receivers = new address[](1);
        receivers[0] = to;
        IERC721Collection(IKON1_ADDRESS).premint(receivers);
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        string memory baseURI = _prefixURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
}
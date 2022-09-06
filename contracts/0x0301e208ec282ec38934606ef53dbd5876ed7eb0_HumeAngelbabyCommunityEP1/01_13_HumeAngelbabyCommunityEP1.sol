// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "./Adminable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// Everything required for construction.
/// @param name The ERC721 name.
/// @param symbol The ERC721 symbol.
/// @param baseURI The initial ERC721 baseURI (can be modified by admin).
/// @param quantity The number of tokens to mint on construction.
/// @param admin The initial admin address (onchain administration).
/// @param owner The initial owner address (offchain administration).
struct ConstructorConfig {
    string name;
    string symbol;
    string baseURI;
    uint256 quantity;
    address admin;
    address owner;
}

/// A single recipient of `multiTransferToEOA`.
/// @param id ERC721 id to transfer.
/// @param to recipient of the transfer.
struct TransferTo {
    uint256 id;
    address to;
}

/// @title HumeAngelbabyCommunityEP1
/// @notice
///
/// humies im here. i made it to the otherside. its time to rebuild. find me.
/// go through the cg_humies
///
/// we are hume. we are many.
///
/// Represents a single from the first HumeAngelbaby EP.
contract HumeAngelbabyCommunityEP1 is ERC721A, Ownable, Adminable {
    /// @dev set by admin and read by ERC721A._baseURI
    string private baseURI;

    /// Emitted when contract is constructed.
    /// @param sender the `msg.sender` that deploys the contract.
    /// @param config All config used by the constructor.
    event Construct(address sender, ConstructorConfig config);

    /// Emitted when the base URI is changed by the admin.
    /// @param sender the `msg.sender` (admin) that sets the base URI.
    /// @param baseURI the new base URI.
    event BaseURI(address sender, string baseURI);

    /// Token constructor.
    /// Assigns owner and admin roles, mints all tokens for the admin and sets
    /// initial base URI.
    /// @param config_ All construction config.
    constructor(ConstructorConfig memory config_)
        ERC721A(config_.name, config_.symbol)
    {
        // Setup roles.
        _transferAdmin(config_.admin);
        _transferOwnership(config_.owner);

        // Mint all tokens for the admin.
        _safeMint(config_.admin, config_.quantity);

        // Set initial baseURI.
        baseURI = config_.baseURI;

        // Inform the world.
        emit Construct(msg.sender, config_);
    }

    /// Admin MAY set a new base URI at any time.
    /// @param baseURI_ The new base URI that all token URIs are build from.
    function adminSetBaseURI(string memory baseURI_) external onlyAdmin {
        baseURI = baseURI_;
        emit BaseURI(msg.sender, baseURI_);
    }

    /// Admin MAY set a new owner at any time.
    /// The owner has no onchain rights other than transferring ownership.
    /// @param owner_ The new owner address.
    function adminSetOwner(address owner_) external onlyAdmin {
        _transferOwnership(owner_);
    }

    /// Optimistically transfer many tokens to many EOA
    /// (Externally Owned Account) recipients.
    /// As a recipient in the list could be a smart contract that does NOT
    /// implement `ERC721TokenReceiver` a `safeTransferFrom` call WOULD fail.
    /// 721A has set its `onERC721Received` checks to private rather than
    /// internal so we simply skip all contracts. The sender will need to
    /// review the result of the transfers offchain and retry sending to any
    /// contracts individually.
    /// @param transfers_ List of ids and recipients to transfer to.
    function multiTransferToEOA(TransferTo[] calldata transfers_) external {
        address to_;
        uint256 id_;
        for (uint256 i_ = 0; i_ < transfers_.length; i_++) {
            to_ = transfers_[i_].to;
            id_ = transfers_[i_].id;
            // Rather than error on failed receipt of the 721 by a smart
            // contract we skip that recipient and continue processing other
            // transfers.
            if (to_.code.length == 0) {
                transferFrom(msg.sender, to_, id_);
            }
        }
    }

    /// @inheritdoc ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @inheritdoc ERC721A
    function _baseURI() internal view override returns (string memory baseURI_) {
        baseURI_ = baseURI;
    }
}
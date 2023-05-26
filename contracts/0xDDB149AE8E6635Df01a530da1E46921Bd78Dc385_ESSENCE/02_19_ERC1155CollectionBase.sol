// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC1155Collection.sol";
import "./CollectionBase.sol";

/**
 * ERC1155 Collection Drop Contract (Base)
 */
abstract contract ERC1155CollectionBase is CollectionBase, IERC1155Collection {
    // Token ID to mint
    uint16 internal constant TOKEN_ID = 1;

    // Immutable variables that should only be set by the constructor or initializer
    uint16 public transactionLimit;
    
    uint16 public purchaseMax;
    uint16 public purchaseLimit;
    uint256 public purchasePrice;
    uint16 public presalePurchaseLimit;
    uint256 public presalePurchasePrice;
    uint16 public maxSupply;
    bool public useDynamicPresalePurchaseLimit;

    // Mutable mint state
    uint16 public purchaseCount;
    uint16 public reserveCount;
    mapping(address => uint16) private _mintCount;

    // Royalty
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    // Transfer lock
    bool public transferLocked;

    /**
     * Initializer
     */
    function _initialize(uint16 maxSupply_, uint16 purchaseMax_, uint256 purchasePrice_, uint16 purchaseLimit_, uint16 transactionLimit_, uint256 presalePurchasePrice_, uint16 presalePurchaseLimit_, address signingAddress_, bool useDynamicPresalePurchaseLimit_) internal {
        require(_signingAddress == address(0), "Already initialized");
        require(maxSupply_ >= purchaseMax_, "Invalid input");
        maxSupply = maxSupply_;
        purchaseMax = purchaseMax_;
        purchasePrice = purchasePrice_;
        purchaseLimit = purchaseLimit_;
        transactionLimit = transactionLimit_;
        presalePurchaseLimit = presalePurchaseLimit_;
        presalePurchasePrice = presalePurchasePrice_;
        _signingAddress = signingAddress_;
        useDynamicPresalePurchaseLimit = useDynamicPresalePurchaseLimit_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
      return interfaceId == type(IERC1155Collection).interfaceId ||interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
          || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * @dev See {IERC1155Collection-claim}.
     */
    function claim(uint16 amount, bytes32 message, bytes calldata signature, string calldata nonce) external virtual override {
        _validateClaimRestrictions();
        _validateClaimRequest(message, signature, nonce, amount);
        _mint(msg.sender, amount);
    }

    /**
     * @dev See {IERC1155Collection-purchase}.
     */
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, string calldata nonce) external virtual override payable {
        _validatePurchaseRestrictions();

        bool isPresale = _isPresale();
        uint256 balance = _getMintBalance();

        // Check purchase amounts
        require(amount <= purchaseRemaining() && ((isPresale && useDynamicPresalePurchaseLimit) || transactionLimit == 0 || amount <= transactionLimit), "Too many requested");

        if (isPresale) {
            require(
                useDynamicPresalePurchaseLimit ||
                (
                    // check amount is under presale limit
                    (presalePurchaseLimit == 0 || (presalePurchaseLimit > balance && amount <= (presalePurchaseLimit - balance))) &&
                    // check amount is also under purchase limit
                    (purchaseLimit == 0 || (purchaseLimit > balance && amount <= (purchaseLimit - balance)))
                ),
                "Too many requested"
            );
            _validatePresalePrice(amount);
        } else {
            require(purchaseLimit == 0 || (purchaseLimit > balance && amount <= (purchaseLimit - balance)), "Too many requested");
            _validatePrice(amount);
        }

        if (isPresale && useDynamicPresalePurchaseLimit) {
            _validatePurchaseRequestWithAmount(message, signature, nonce, amount);
        } else {
            _validatePurchaseRequest(message, signature, nonce);
        }

        // Track total mints per address only if necessary
        if (_shouldUseMintCount()) {
           _mintCount[msg.sender] += amount;
        }

        _mint(msg.sender, amount);
    }

    /**
     * @dev See {IERC1155Collection-state}
     */
    function state() external override view returns (CollectionState memory) {
        // No message sender, no purchase balance
        uint16 balance = msg.sender == address(0) ? 0 : uint16(_getMintBalance());
        return CollectionState(transactionLimit, purchaseMax, purchaseRemaining(), purchasePrice, purchaseLimit, presalePurchasePrice, presalePurchaseLimit, balance, active, startTime, endTime, presaleInterval, claimStartTime, claimEndTime, useDynamicPresalePurchaseLimit);
    }

    /**
     * @dev Get balance of address. Similar to IERC1155-balanceOf, but doesn't require token ID
     * @param owner The address to get the token balance of
     */
    function balanceOf(address owner) public virtual override view returns (uint256);

    /**
     * @dev See {IERC1155Collection-purchaseRemaining}.
     */
    function purchaseRemaining() public virtual override view returns (uint16) {
        return purchaseMax - purchaseCount;
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

    /**
     * Premint tokens to the owner.  Purchase must not be active.
     */
    function _premint(uint16 amount, address owner) internal virtual {
        require(!active, "Already active");
        _mint(owner, amount);
    }

    /**
     * Premint tokens to the list of addresses.  Purchase must not be active.
     */
    function _premint(uint16[] calldata amounts, address[] calldata addresses) internal virtual {
        require(!active, "Already active");
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], amounts[i]);
        }
    }

    /**
     * Mint reserve tokens. Purchase must be completed.
     */
    function _mintReserve(uint16 amount, address owner) internal virtual {
        require(endTime != 0 && endTime <= block.timestamp, "Cannot mint reserve until after sale complete");
        require(purchaseCount + reserveCount + amount <= maxSupply, "Too many requested");
        reserveCount += amount;
        _mintERC1155(owner, amount);
    }

    /**
     * Mint reserve tokens. Purchase must be completed.
     */
    function _mintReserve(uint16[] calldata amounts, address[] calldata addresses) internal virtual {
        require(endTime != 0 && endTime <= block.timestamp, "Cannot mint reserve until after sale complete");
        uint16 totalAmount;
        for (uint256 i = 0; i < addresses.length; i++) {
            totalAmount += amounts[i];
        }
        require(purchaseCount + reserveCount + totalAmount <= maxSupply, "Too many requested");
        reserveCount += totalAmount;
        for (uint256 i = 0; i < addresses.length; i++) {
            _mintERC1155(addresses[i], amounts[i]);
        }
    }

    /**
     * Mint function internal to ERC1155CollectionBase to keep track of state
     */
    function _mint(address to, uint16 amount) internal {
        purchaseCount += amount;
        _mintERC1155(to, amount);
    }

    /**
     * @dev A _mint function is required that calls the underlying ERC1155 mint.
     */
    function _mintERC1155(address to, uint16 amount) internal virtual;

    /**
     * Validate price (override for custom pricing mechanics)
     */
    function _validatePrice(uint16 amount) internal {
        require(msg.value == amount * purchasePrice, "Invalid purchase amount sent");
    }

    /**
     * Validate price (override for custom pricing mechanics)
     */
    function _validatePresalePrice(uint16 amount) internal virtual {
        require(msg.value == amount * presalePurchasePrice, "Invalid purchase amount sent");
    }

    /**
     * If enabled, lock token transfers until after the sale has ended.
     *
     * This helps enforce purchase limits, so someone can't buy -> transfer -> buy again
     * while the token is minting.
     */
    function _validateTokenTransferability(address from) internal view {
        require(!transferLocked || purchaseRemaining() == 0 || (active && block.timestamp >= endTime) || from == address(0), "Transfer locked until sale ends");
    }

    /**
     * Set whether or not token transfers are locked till end of sale
     */
    function _setTransferLocked(bool locked) internal {
        transferLocked = locked;
    }

    /**
     * @dev Update royalties
     */
    function _updateRoyalties(address payable recipient, uint256 bps) internal {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    /**
     * @dev Return mint count or balanceOf
     */
    function _getMintBalance() internal view returns (uint256) {
        uint256 balance;
        if (_shouldUseMintCount()) {
            balance = _mintCount[msg.sender];
        } else {
            balance = balanceOf(msg.sender);
        }

        return balance;
    }

    /**
     * @dev Return whether to use our own mint count vs balanceOf.
     *
     * Tokens minted via `premint` and `claim`, for example, don't affect mint count.
     */
    function _shouldUseMintCount() internal view returns (bool) {
        return !transferLocked && (purchaseLimit > 0 || presalePurchaseLimit > 0);
    }
}
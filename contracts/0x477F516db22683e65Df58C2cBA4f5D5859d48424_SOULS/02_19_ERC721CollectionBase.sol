// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC721Collection.sol";
import "./CollectionBase.sol";

/**
 * ERC721 Collection Drop Contract (Base)
 */
abstract contract ERC721CollectionBase is CollectionBase, IERC721Collection {
    
    using Strings for uint256;

    // Immutable variables that should only be set by the constructor or initializer
    uint16 public transactionLimit;
    uint16 public purchaseMax;
    uint16 public purchaseLimit;
    uint256 public purchasePrice;
    uint16 public presalePurchaseLimit;
    uint256 public presalePurchasePrice;
    bool public useDynamicPresalePurchaseLimit;

    // Minted token information
    uint16 public purchaseCount;
    mapping(address => uint16) internal _addressMintCount;

    // Token URI configuration
    string internal _prefixURI;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    // Transfer lock
    bool public transferLocked;

    function _initialize(uint16 purchaseMax_, uint256 purchasePrice_, uint16 purchaseLimit_, uint16 transactionLimit_, uint256 presalePurchasePrice_, uint16 presalePurchaseLimit_, address signingAddress, bool useDynamicPresalePurchaseLimit_) internal {
        require(_signingAddress == address(0), "Already initialized");
        purchaseMax = purchaseMax_;
        purchasePrice = purchasePrice_;
        purchaseLimit = purchaseLimit_;
        transactionLimit = transactionLimit_;
        presalePurchasePrice = presalePurchasePrice_;
        presalePurchaseLimit = presalePurchaseLimit_;
        _signingAddress = signingAddress;
        useDynamicPresalePurchaseLimit = useDynamicPresalePurchaseLimit_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
      return interfaceId == type(IERC721Collection).interfaceId ||interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
          || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * Premint tokens to the owner.  Sale must not be active.
     */
    function _premint(uint16 amount, address owner) internal virtual {
        require(!active, "Already active");
        for (uint i = 0; i < amount; ) {
            _mint(owner);
            unchecked {
                i++;
            }
        }
    }

    /**
     * Premint tokens to the list of addresses.  Sale must not be active.
     */
    function _premint(address[] calldata addresses) internal virtual {
        require(!active, "Already active");
        for (uint i =0; i < addresses.length; ) {
            _mint(addresses[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev override if you want to perform different mint functionality
     */
    function _mint(address to) internal virtual {
        purchaseCount++;
        
        // Mint token
        _mint(to, purchaseCount);

        emit Unveil(purchaseCount, address(this), purchaseCount);
    }

    /**
     * @dev override to define mint functionality
     */
    function _mint(address to, uint256 tokenId) internal virtual;

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256);

    /**
     * @dev Use a prefix uri for all tokens (<PREFIX><TOKEN_ID>).
     */
    function _setTokenURIPrefix(string calldata prefix) internal virtual {
        _prefixURI = prefix;
    }

    /**
     * Validate price (override for custom pricing mechanics)
     */
    function _validatePrice(uint16 amount) internal virtual {
      require(msg.value == amount*purchasePrice, "Invalid purchase amount sent");
    }


    /**
     * Validate price (override for custom pricing mechanics)
     */
    function _validatePresalePrice(uint16 amount) internal virtual {
      require(msg.value == amount*presalePurchasePrice, "Invalid purchase amount sent");
    }

    /**
     * If enabled, lock token transfers until admin unlocks.
     */
    function _validateTokenTransferability(address from) internal view {
        require(!transferLocked || from == address(0), "Transfer locked until sale ends");
    }

    /**
     * Set whether or not token transfers are locked till end of sale
     */
    function _setTransferLocked(bool locked) internal {
        transferLocked = locked;
    }

    /**
     * @dev See {IERC721Collection-claim}.
     */
    function claim(uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) external virtual override {
        _validateClaimRestrictions();
        _validateClaimRequest(message, signature, nonce, amount);
        for (uint i = 0; i < amount; ) {
            _mint(msg.sender);
            unchecked {
                i++;
            }
        }
    }
    
    /**
     * @dev See {IERC721Collection-purchase}.
     */
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) public payable virtual override {
        _validatePurchaseRestrictions();

        bool isPresale = _isPresale();
        
        // Check purchase amounts
        require(amount <= purchaseRemaining() && ((isPresale && useDynamicPresalePurchaseLimit) || transactionLimit == 0 || amount <= transactionLimit), "Too many requested");

        if (isPresale) {
            if (!useDynamicPresalePurchaseLimit) {
                // Make sure we are not over presalePurchaseLimit
                if (presalePurchaseLimit != 0) {
                    uint16 mintCount = _addressMintCount[msg.sender];
                    require(presalePurchaseLimit > mintCount && amount <= (presalePurchaseLimit-mintCount), "Too many requested");
                }
                // Make sure we are not over purchaseLimit
                if (purchaseLimit != 0) {
                    uint16 mintCount = _addressMintCount[msg.sender];
                    require(purchaseLimit > mintCount && amount <= (purchaseLimit-mintCount), "Too many requested");
                }
            }
            _validatePresalePrice(amount);
            // Only track mint count if needed
            if (!useDynamicPresalePurchaseLimit && (presalePurchaseLimit != 0 || purchaseLimit != 0)) {
                _addressMintCount[msg.sender] += amount;
            }
        } else {
            // Make sure we are not over purchaseLimit
            if (purchaseLimit != 0) {
                uint16 mintCount = _addressMintCount[msg.sender];
                require(purchaseLimit > mintCount && amount <= (purchaseLimit-mintCount), "Too many requested");
            }
            _validatePrice(amount);
            if (purchaseLimit != 0) {
                _addressMintCount[msg.sender] += amount;
            }
        }

        if (isPresale && useDynamicPresalePurchaseLimit) {
            _validatePurchaseRequestWithAmount(message, signature, nonce, amount);
        } else {
            _validatePurchaseRequest(message, signature, nonce);
        }
        
        for (uint i = 0; i < amount;) {
            _mint(msg.sender);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev See {IERC721Collection-state}
     */
    function state() external override view returns(CollectionState memory) {
        return CollectionState(transactionLimit, purchaseMax, purchaseRemaining(), purchasePrice, purchaseLimit, presalePurchasePrice, presalePurchaseLimit, _addressMintCount[msg.sender], active, startTime, endTime, presaleInterval, claimStartTime, claimEndTime, useDynamicPresalePurchaseLimit);
    }

    /**
     * @dev See {IERC721Collection-purchaseRemaining}.
     */
    function purchaseRemaining() public view virtual override returns(uint16) {
        return purchaseMax-purchaseCount;
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
     * @dev Update royalties
     */
    function _updateRoyalties(address payable recipient, uint256 bps) internal {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }
}
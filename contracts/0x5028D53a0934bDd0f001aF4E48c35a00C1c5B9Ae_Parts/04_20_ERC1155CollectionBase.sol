// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/Strings.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";


import "./IERC1155Collection.sol";
import "./CollectionBase.sol";

/**
 * ERC1155 Collection Drop Contract (Base)
 */
abstract contract ERC1155CollectionBase is CollectionBase, IERC1155Collection, AdminControl {
    // Token ID to mint
    uint16 internal TOKEN_ID = 0;

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
    uint16 public constant MINT_LIMIT_PER_ADDRESS = 4;
    mapping(address => uint16) private _mintCount;

    // Royalty
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;


    // Transfer lock
    bool public transferLocked;

    uint MAX_PART_SUPPLY = 3000;
    uint MAX_PUBLIC_SUPPLY = 12000;
    uint MAX_COMMUNITY_SUPPLY = 2000;

    uint part1Supply = 0;
    uint part2Supply = 0;
    uint part3Supply = 0;
    uint part4Supply = 0;

    uint16 part1SupplyCommunity = 0;
    uint16 part2SupplyCommunity = 0;
    uint16 part3SupplyCommunity = 0;
    uint16 part4SupplyCommunity = 0;


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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AdminControl) returns (bool) {
      return interfaceId == type(IERC1155Collection).interfaceId ||interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
          || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * @dev See {IERC1155Collection-purchase}.
     */
    function _purchase() internal virtual {
        _validatePurchaseRestrictions();
        _validatePrice(4);
        _hasPublicMintLimitBeenReached();
        require(_mintCount[msg.sender] < MINT_LIMIT_PER_ADDRESS, "Mint limit for this address has been reached");

        _mintCount[msg.sender] += 4;
        
        for(uint i = 0; i < 4; i++) {
            _mint(msg.sender, 1);
            _incrementPartSupply(TOKEN_ID);   
        }
        TOKEN_ID = _calculateNextTokenId();
    }

    function _hasPublicMintLimitBeenReached() internal view {
        uint256 mintedSoFar = part1Supply + part2Supply + part3Supply + part4Supply;
        require(mintedSoFar <= MAX_PUBLIC_SUPPLY, "Public mint limit has been reached");
    }

    function _hasCommunityMintLimitBeenReached() internal view {
        uint16 mintedSoFar = part1SupplyCommunity + part2SupplyCommunity + part3SupplyCommunity + part4SupplyCommunity;
        require(mintedSoFar <= MAX_COMMUNITY_SUPPLY, "Community mint limit has been reached");
    }

    function purchaseCommunity(address to) external adminRequired {
        _hasCommunityMintLimitBeenReached();
        for(uint16 i = 0; i < 4; i++) {
            TOKEN_ID = i;
            _mint(to, 500);
        }
    }

    function _calculateNextTokenId() view internal returns (uint16) {
        uint _seed = 1;
        uint16 randomNumber = uint16(rand(_seed));

        while(!_isRandomNumberValid(randomNumber)) {
            _seed++;
            randomNumber = uint16(rand(_seed));
        }

        return randomNumber;
    }

    function _incrementPartSupply(uint _tokenId) internal {
        if(_tokenId == 0) {
            part1Supply++;
        } else if(_tokenId == 1) {
            part2Supply++;
        } else if(_tokenId == 2) {
            part3Supply++;
        } else if(_tokenId == 3) {
            part4Supply++;
        }  else {
        }
    }

    function _isRandomNumberValid(uint randomNumber) view internal returns  (bool) {
        if(randomNumber == 0) {
            return part1Supply <= MAX_PART_SUPPLY; 
        } else if(randomNumber == 1) {
            return part2Supply <= MAX_PART_SUPPLY;
        } else if(randomNumber == 2) {
            return part3Supply <= MAX_PART_SUPPLY;
        } else if(randomNumber == 3) {
            return part2Supply <= MAX_PART_SUPPLY;
        }  else {
            return false;
        }
    }

    function rand(uint256 _seed) public view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return seed % 4;
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
    function _validateTokenTransferability() internal view {
        require(!transferLocked, "Transfer locked");
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
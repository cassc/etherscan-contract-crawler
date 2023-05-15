/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ArkfiMarket is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemId;

    address constant ARKFI = 0x111120a4cFacF4C78e0D6729274fD5A5AE2B1111;
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    uint256 public FEE_PERCENTAGE = 1;
    address FEE_RECIPIENT_ADDRESS;

    constructor() {
        FEE_RECIPIENT_ADDRESS = owner();
    }

    struct Item {
        uint256 id;
        address seller;
        address tokenAddress;
        uint256 price;
        uint256 remainingTokens;
        string uri;
        bool isSold;
    }

    mapping(uint256 => Item) public items;
    mapping(uint256 => bool) public itemIsListed;

    event ItemListed(uint256 indexed itemId, address indexed seller, address tokenAddress, uint256 price, uint256 remainingTokens, string uri);
    event ItemSold(uint256 indexed itemId, address indexed buyer, uint256 purchasedTokens);
    event ItemRemoved(uint256 indexed itemId, address indexed seller, uint256 price);
    event FeePercentageChanged(uint256 newPercentage);

    function changeFeePercentage(uint256 newPercentage) public onlyOwner {
        FEE_PERCENTAGE = newPercentage;
        emit FeePercentageChanged(newPercentage);
    }

    function listItem(address tokenAddress, uint256 price, uint256 tokenAmount, string memory uri) public {
        require(price > 0, "Price must be greater than zero");
        require(
            tokenAddress == ARKFI,
            "Only ARKFI is allowed for sale"
        );
        require(tokenAmount > 0, "Token amount must be greater than zero");

        _itemId.increment();
        uint256 itemId = _itemId.current();

        address seller = msg.sender;

        IERC20 token = IERC20(tokenAddress);

        require(token.transferFrom(seller, address(this), tokenAmount), "Token transfer failed");

        items[itemId] = Item(itemId, msg.sender, tokenAddress, price, tokenAmount, uri, false);
        itemIsListed[itemId] = true;

        emit ItemListed(itemId, msg.sender, tokenAddress, price, tokenAmount, uri);
    }

    function buyItem(uint256 itemId, uint256 tokenAmount) public {
        Item storage item = items[itemId];
        FEE_RECIPIENT_ADDRESS = owner();
        require(itemIsListed[itemId] == true, "Item not listed");

        require(!item.isSold, "Item has already been sold");
        require(item.remainingTokens >= tokenAmount, "Not enough tokens available");
        uint256 totalPrice = item.price * tokenAmount / (10**18);
        uint256 feeAmount = 0;
        feeAmount = (totalPrice * FEE_PERCENTAGE) / 100;
        uint256 sellerAmount = totalPrice - feeAmount;
        require(IERC20(USDT).transferFrom(msg.sender, FEE_RECIPIENT_ADDRESS, feeAmount), "Fee transfer failed");
        require(IERC20(USDT).transferFrom(msg.sender, item.seller, sellerAmount), "Token transfer failed");
        require(IERC20(item.tokenAddress).transfer(msg.sender, tokenAmount), "Token transfer failed");

        item.remainingTokens -= tokenAmount;

        if (item.remainingTokens == 0) {
            item.isSold = true;
            itemIsListed[itemId] = false;

        }

        emit ItemSold(itemId, msg.sender, tokenAmount);
    }

    function removeItem(uint256 listingid) public {
        Item storage item = items[listingid];

        require(itemIsListed[listingid] == true, "Item not listed");

        require(item.seller == msg.sender, "Only the seller can remove an item");

        IERC20 token = IERC20(item.tokenAddress);

        require(token.transfer(item.seller, item.remainingTokens), "Token transfer failed");

        delete items[listingid];
        itemIsListed[listingid] = false;

        emit ItemRemoved(listingid, item.seller, item.price);
    }

    function getItemsBySeller(address seller) public view returns (Item[] memory) {
        uint256 itemCount = 0;
        for (uint256 i = 1; i <= _itemId.current(); i++) {
            if (items[i].seller == seller) {
                itemCount++;
            }
        }

        Item[] memory result = new Item[](itemCount);
        itemCount = 0;

        for (uint256 i = 1; i <= _itemId.current(); i++) {
            if (items[i].seller == seller) {
                result[itemCount] = items[i];
                itemCount++;
            }
        }

        return result;
    }

    function getAvailableItems() public view returns (Item[] memory) {
        uint256 itemCount = 0;
        for (uint256 i = 1; i <= _itemId.current(); i++) {
            if (!items[i].isSold) {
                itemCount++;
            }
        }

        Item[] memory result = new Item[](itemCount);
        itemCount = 0;

        for (uint256 i = 1; i <= _itemId.current(); i++) {
            if (!items[i].isSold) {
                result[itemCount] = items[i];
                itemCount++;
            }
        }

        return result;
    }


}
/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// File: contracts/WCANFTRanking.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract WCANFTRanking is Ownable {
	string public constant version = "0.1";

	event UpdateNFTRank(Collection _collection, uint256 _id);

	enum Collection {
		WCA,
		MUNDIAL,
		VIP
	}

	struct NFT {
		Collection from;
		uint256 id;
	}

	struct Query {
		bytes32 id;
		Collection collection;
		uint256 nftId;
		bool isProcessed;
	}

	address public oracle;

	mapping(uint256 => uint256) public wcaIdToRank;
	mapping(uint256 => uint256) public mundialIdToRank;
	mapping(uint256 => uint256) public vipIdToRank;

	constructor(address _oracle) {
		oracle = _oracle;
	}

	function setOracle(address _oracle) external onlyOwner {
		oracle = _oracle;
	}

	function setWCARanking(uint256 id, uint256 rank) external onlyOwner {
		wcaIdToRank[id] = rank;
	}

	function setMundialRanking(uint256 id, uint256 rank) external onlyOwner {
		mundialIdToRank[id] = rank;
	}

	function setVIPRanking(uint256 id, uint256 rank) external onlyOwner {
		vipIdToRank[id] = rank;
	}

	function callback(Collection collection, uint256 id, uint256 rank) public {
		require(msg.sender == oracle, "Update doesn't came from oracle");

		if (collection == Collection.WCA) {
			wcaIdToRank[id] = rank;
		} else if (collection == Collection.MUNDIAL) {
			mundialIdToRank[id] = rank;
		} else if (collection == Collection.VIP) {
			vipIdToRank[id] = rank;
		}
	}

	function bulkUpdateRank(NFT[] calldata nfts) external payable {
		for (uint256 i; i < nfts.length; i++) {
				updateRank(nfts[i].from, nfts[i].id);
		}
	}

	function updateRank(Collection collection, uint256 id) public payable {
		emit UpdateNFTRank(collection, id);
	}

	function getRank(Collection collection, uint256 id) external view returns (uint256) {
		if (collection == Collection.WCA) {
			return wcaIdToRank[id];
		} else if (collection == Collection.MUNDIAL) {
			return mundialIdToRank[id];
		} else if (collection == Collection.VIP) {
			return vipIdToRank[id];
		}
		revert("Unsupported collection");
	}

	function fund() external payable {}

	function withdraw(uint256 _value) external payable onlyOwner {
		uint256 balance = address(this).balance;
		require(balance > 0, "No ether left to withdraw");
		uint256 toWithdraw = _value;
		if (balance < _value || _value == 0) {
			toWithdraw = balance;
		}

		(bool success, ) = (owner()).call{ value: toWithdraw }("");
		require(success, "Transfer failed.");
	}
}
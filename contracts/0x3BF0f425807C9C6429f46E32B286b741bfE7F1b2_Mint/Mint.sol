/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.12.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT

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


// File @openzeppelin/contracts/access/[email protected]

// License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/Mint.sol

//License-Identifier: MIT
pragma solidity ^0.8.9;

contract GB {
	function init(uint, string calldata, uint,  uint, uint) external {}
	function mint(address, uint) external {}
    function totalSupply() external view returns (uint256) {}
    function ownerOf(uint256) external view returns (address) {}
    function tokenOfOwnerByIndex(address, uint256) public view returns (uint256) {}
    function balanceOf(address) public view returns (uint256) {}
}

contract Mint is Ownable {

	modifier onlyMintOwnerOf(uint tokenId) {
		require(mintOwner[tokenId] == msg.sender, "GreedyBoys: only pre-approved can mint this token");
		_;
	}

	modifier onlyForReservedToken(uint tokenId) {
		require(tokenId <= reservedTokens, "GreedyBoys: only the reserved amount can be minted directly");
		_;
	}

	modifier notZeroAddress(address addr) {
		require(addr != address(0), "GreedyBoys: no zero address allowed");
		_;
	}

	modifier readyForSale() {
		require(startTime != 0 && block.timestamp >= startTime, "GreedyBoys: period not started");
		_;
	}

	uint public constant AR_HASH_SIZE = 43;

    struct UpdateData1 {
        uint16 saleCount;                           // number of items sold
        uint64 nextPrice;							// next price, updated after every purchase
        uint128 unclaimedGrossRevenue;
    }

    struct UpdateData2 {
        uint128 reflectionTotalBalance;				// sum of all reflection funds
        uint128 totalDividend;						// used for reflection reward calculation
    }

    UpdateData1 public data1;
    UpdateData2 public data2;

	// Tokenomics
	uint public maxTokens;							// max tokens
	uint public immutable reservedTokens;			// reserved token count, set at construction

    // Counts
	uint public pendingCount;						// remaining number of items
    uint public giveawayCount;                      // number of items given away

	// Minting params
    uint public totalSaleLimit;                     // total max sales
	uint public startTime;							// sale start time
	uint public buyLimit;							// limit on number of tokens that can be bought at once
	uint64 public floorPrice;						// floor price
	uint64 private priceStep;						// price reduction step
	uint16 private cutoffQuantity;					// the point at which the price becomes floored

	// Minting and giveaways
	mapping (uint => uint) private pendingIds;		// this supports random mints
	mapping (uint => address) private giveaways;	// token id => wallet that was gifted
	mapping (uint => address) private minters;		// token id => wallet that minted
	mapping (uint => address) private mintOwner;	// token id => wallet that can mint directly

    // Whitelisting
    mapping (address => bool) public whitelist;     // address => allowed to mint
    bool public whitelistEnabled;                   // is whitelist enaabled

	// Reflection
	uint public reflectionShareBps;					// pct of funds to reflect
	mapping (uint => uint) private lastDividendAt;	// token id =>

	// Sales
    mapping (uint => address) public salesAccounts; // idx => the account that will receive the funds
    mapping (address => uint) public salesAccountsBps;	// idx => % allocation
    uint public salesAccountsCount;

    GB public nftContract;

	event Giveaway(uint tokenId, address to);
	event Purchased(uint tokenId, address by, uint amount, uint reflectedAmount);
	event EarningsClaimed(address by, uint amount);
	event RewardsClaimed(address by, uint amount);

	constructor(uint _reservedTokens)
	{
		startTime = 0;
		reservedTokens = _reservedTokens;
	}

	//
	// public
	//

	function tokenReflectionBalance(uint tokenId)
	public view
	returns (uint) {
		return data2.totalDividend - lastDividendAt[tokenId];
	}

	function price(uint numOfNft)
	public view
	returns (uint)
	{
		uint ts = nftContract.totalSupply();
		uint px = data1.nextPrice;
		uint totalPx = px;
		for (uint i = 1; i < numOfNft; i++) {
            ts++;
			if (ts > cutoffQuantity) {
				px = floorPrice;
			} else {
				px -= priceStep;
			}
			totalPx += px;
		}
		return totalPx;
	}

	//
	// external
	//

	function init(
		uint[] calldata tokenIds,
		uint[] calldata tokenParams,
		string calldata allHashes,
		uint allHashesLength,
		uint numberOfNfts
	)
	external
	{
		require(AR_HASH_SIZE * numberOfNfts == allHashesLength, "GreedyBoys: mismatched hashes");
		require(tokenIds.length == numberOfNfts && tokenParams.length == 3 * numberOfNfts, "GreedyBoys: mismatched arrays");
		uint offset = 0;
		for (uint i; i < numberOfNfts; i++) {
			require(nftContract.ownerOf(tokenIds[i]) == msg.sender, "GreedyBoys: only NFT owner can call this");
            nftContract.init(
                tokenIds[i],
                _substring(allHashes, AR_HASH_SIZE, offset),
                tokenParams[i],
                tokenParams[i + 1],
                tokenParams[i + 2]);
			offset += AR_HASH_SIZE;
		}
	}

	function mint(uint tokenId, address to)
	external
	onlyMintOwnerOf(tokenId)
	onlyForReservedToken(tokenId)
	notZeroAddress(to)
	{
		minters[tokenId] = msg.sender;
        nftContract.mint(to, tokenId);
	}

	function claimRewards()
	external
	{
		uint count = nftContract.balanceOf(msg.sender);
		uint balance = 0;
		for (uint i; i < count; i++) {
			uint tokenId = nftContract.tokenOfOwnerByIndex(msg.sender, i);
			if (giveaways[tokenId] != address(0)) continue;
			balance += tokenReflectionBalance(tokenId);
			lastDividendAt[tokenId] = data2.totalDividend;
		}
		payable(msg.sender).transfer(balance);
		emit RewardsClaimed(msg.sender, balance);
	}

    function claimEarnings()
    external
    {
        uint earnings = data1.unclaimedGrossRevenue * (10000 - reflectionShareBps) / 10000;
        data1.unclaimedGrossRevenue = 0;
        for (uint i; i < salesAccountsCount; i++)  {
            address account = salesAccounts[i];
            uint amount = earnings * salesAccountsBps[account] / 10000;
            payable(account).transfer(amount);
            emit EarningsClaimed(account, amount);
        }
    }

	function getReflectionBalance()
	external view
	returns (uint256)
	{
		uint count = nftContract.balanceOf(msg.sender);
		uint total = 0;
		for (uint i; i < count; i++) {
			uint tokenId = nftContract.tokenOfOwnerByIndex(msg.sender, i);
			if (giveaways[tokenId] != address(0)) continue;
			total += tokenReflectionBalance(tokenId);
		}
		return total;
	}

	// external payable

	function buy(uint16 numberOfNfts)
	external payable
	readyForSale()
	{
        if (whitelistEnabled) {
            require(whitelist[msg.sender], "GreedyBoys: you must be on the whitelist to buy at this time");
        }
		require(numberOfNfts > 0 && numberOfNfts <= buyLimit, "GreedyBoys: numberOfNfts must be positive and lte limit");
        require(pendingCount > 0, "GreedyBoys: all minted");
        require(data1.saleCount + numberOfNfts <= totalSaleLimit, "GreedyBoys: try less items (or presale is sold out)");
        require(price(numberOfNfts) == msg.value, "GreedyBoys: invalid ether value");

        uint currTotalSupply = nftContract.totalSupply();
        uint amount = msg.value / numberOfNfts;
        for (uint i; i < numberOfNfts; i++) {
            _randomMint(msg.sender);
            _reflectDividend(amount, ++currTotalSupply);
        }

        data1.saleCount += numberOfNfts;
        data1.unclaimedGrossRevenue += uint128(msg.value);
        data1.nextPrice = currTotalSupply > cutoffQuantity ? floorPrice : (data1.nextPrice - numberOfNfts * priceStep);
	}

	// external only owner

	function randomGiveaway(address to)
	external
	onlyOwner()
	notZeroAddress(to)
	{
		uint tokenId = _randomMint(to);
		giveaways[tokenId] = to;
        giveawayCount++;
		emit Giveaway(tokenId, to);
	}

	function setSalesAccounts(address[] calldata accounts, uint[] calldata shares)
	external
	onlyOwner()
	{
        require(_sum(shares) == 10000, "GreedyBoys: admin shares must add up to 100");
        salesAccountsCount = accounts.length;
        for (uint i; i < accounts.length; i++) {
            address account = accounts[i];
		    salesAccounts[i] = account;
            salesAccountsBps[account] = shares[i];
        }
	}

    function setContract(address contractAddr, uint maxTokens_)
    external
    onlyOwner()
    {
        nftContract = GB(contractAddr);
        maxTokens = maxTokens_;
        totalSaleLimit = maxTokens - reservedTokens;
        pendingCount = maxTokens - reservedTokens;
    }

	function setReflectionShareBps(uint bps)
	external
	onlyOwner()
	{
		reflectionShareBps = bps;
	}

	function setMintOwner(uint tokenId, address ownerAddr)
	external
	onlyOwner()
	onlyForReservedToken(tokenId)
	notZeroAddress(ownerAddr)
	{
		mintOwner[tokenId] = ownerAddr;
	}

	function setMintPrice(uint64 first, uint64 floor, uint16 cutoff)
	external
	onlyOwner()
	{
		require(cutoff < maxTokens, "GreedyBoys: cutoff can't be greater than max number of tokens");
		require(first >= floor, "GreedyBoys: floor price can't be higher than starting price");
		data1.nextPrice = first;
		floorPrice = floor;
		cutoffQuantity = cutoff;
		priceStep = (data1.nextPrice - floorPrice) / cutoffQuantity;
	}

	function setBuyLimit(uint limit)
	external
	onlyOwner()
	{
		buyLimit = limit;
	}

	function setStartTime(uint time)
	external
	onlyOwner()
	{
		startTime = time;
	}

    function setTotalSaleLimit(uint limit)
    external
    onlyOwner()
    {
        require(limit <= maxTokens - reservedTokens, "GreedyBoys: total sale limit cannot be higher than max tokens");
        totalSaleLimit = limit;
    }

    function toggleWhitelistEntry(address buyerAddr)
    external
    onlyOwner()
    {
        whitelist[buyerAddr] = whitelist[buyerAddr] ? false : true;
    }

    function toggleWhitelist()
    external
    onlyOwner()
    {
        whitelistEnabled = whitelistEnabled ? false : true;
    }

	// external view

	function minterOf(uint tokenId)
	external view
	returns (address)
	{
		return minters[tokenId];
	}

    function reflectionTotalBalance()
    external view
    returns (uint128)
    {
        return data2.reflectionTotalBalance;
    }

	//
	// private
	//

    function _reflectDividend(uint amount, uint totalSupply)
    private
    {
        uint reflectionShare = (amount * reflectionShareBps) / 10000;
        data2.reflectionTotalBalance += uint128(reflectionShare);
        data2.totalDividend += uint128(reflectionShare / totalSupply);
    }

	function _randomMint(address to)
	private
    returns (uint tokenId)
	{
		uint index = (_random() % pendingCount) + 1;
		tokenId = _popPendingAt(index);
		lastDividendAt[tokenId] = data2.totalDividend;
		minters[tokenId] = msg.sender;
        nftContract.mint(to, tokenId);
	}

	function _popPendingAt(uint index)
	private
	returns (uint tokenId)
	{
		tokenId = _getPendingAt(index) + reservedTokens;
		if (index != pendingCount) {
			pendingIds[index] = _getPendingAt(pendingCount) - index;
		}
		pendingCount--;
	}

	// private views

	function _getPendingAt(uint index)
	private view
	returns (uint)
	{
		return pendingIds[index] + index;
	}

	function _random()
	private view
	returns (uint256)
	{
		return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, pendingCount)));
	}

	// private pure

	function _sum(uint[] memory a)
	private pure
	returns (uint sum)
	{
		for (uint i; i < a.length; i++) {
            sum += a[i];
        }
	}

    function _substring(string memory _base, uint _length, uint _offset)
    private pure
    returns (string memory)
	{
        bytes memory _baseBytes = bytes(_base);

        require(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

}
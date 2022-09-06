/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: contracts/update/MarketConfigUpgradeable.sol


pragma solidity ^0.8.0;


/**
 注意这个合约一旦发布过，不能修改 状态数据 
 */
abstract contract MarketConfigUpgradeable is OwnableUpgradeable {
    using AddressUpgradeable for address;
    mapping(address => bool) internal _marketAccessUsers;







    event logMakertAccessUsers(address addr, bool auth);
     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier  marketAccessRole() {
        require(_marketAccessUsers[_msgSender()], "caller is not access role");
        _;
    }
    function setMarketAccess(address marketAddr, bool auth) public onlyOwner {
         require(marketAddr!=address(0), "address is zero");
        require(marketAddr.isContract(), "address is not contract");
        require(marketAddr != owner(), "account not is ContractOwner");
        _marketAccessUsers[marketAddr] = auth;
        emit logMakertAccessUsers(marketAddr, auth);
    }

    function getMarketAccess(address marketAddr) public view returns (bool) {
        //require(account.isContract(),"account not is Contract address");
        return _marketAccessUsers[marketAddr];
    }
}

// File: contracts/update/NFTData/NFTDataUpgradeable.sol


pragma solidity ^0.8.0;



/**
   本版本合约增加签名钱包地址 用于合约数据签名和验证
 */
contract NFTDataUpgradeable is MarketConfigUpgradeable {
    uint256 internal constant total_percent = 10000;
    uint256 internal platform_percent;
    event contractOwnerChanage(address sourceAddr, address newAddr); //主网可以删除 没有使用到
    platformBenefit0[32] internal benefits;
    uint256 internal benefit_size;
    mapping(address => mapping(uint256 => NFTAuthor0)) internal authors;
    struct platformBenefit0 {
        address platform;
        uint256 percent;
        uint256 total_percent;
    }
    struct platformBenefit1 {
        address platform;
        uint256 percent;
    }
    struct benefit0 {
        uint256 percent;
        uint256 total_percent;
    }
    struct NFTAuthor0 {
        address contractAddr;
        uint256 tokenId;
        address name;
        uint256 percent;
        uint256 total_percent;
    }
    struct NFTAuthor1 {
        address contractAddr;
        uint256 tokenId;
        address name;
        uint256 percent;
    }
    event addNFTAuhor(NFTAuthor0 author);
    event platformBenefit_0(
        platformBenefit0[] source_bfs,
        platformBenefit0[] new_bfs
    );

    address internal _signAddr;
    event signAddressUpdateLog(address signAddr);

    /*
     * 一定要保证存储变量顺序 

     */

    function initialize(address marketAddress) public initializer {
        __Ownable_init();
        setMarketAccess(marketAddress, true);
    }

    function queryAuthor(address nftContract, uint256 tokenId)
        public
        view
        returns (NFTAuthor0 memory)
    {
        return authors[nftContract][tokenId];
    }

    function addAuthor(NFTAuthor1 memory author) public marketAccessRole {
        require(author.name != address(0), "address is not zero");
        require(author.tokenId > 0, "tokenid is not useful");
        require(author.percent > 0, "percent is not useful");
        require(author.percent < total_percent, "total_percent is not useful");
        authors[author.contractAddr][author.tokenId] = NFTAuthor0(
            author.contractAddr,
            author.tokenId,
            author.name,
            author.percent,
            total_percent
        );
        emit addNFTAuhor(authors[author.contractAddr][author.tokenId]);
    }

    function changePlatformBenefitPercent(uint256 percent) public onlyOwner {
        require(percent < total_percent, "percent is too large");
        platform_percent = percent;
    }

    function queryBenefitPercent() public view returns (benefit0 memory) {
        return benefit0(platform_percent, total_percent);
    }

    function queryPlatformAddress()
        public
        view
        returns (platformBenefit0[] memory)
    {
        platformBenefit0[] memory T = new platformBenefit0[](benefit_size);
        for (uint256 i = 0; i < benefit_size; i++) {
            platformBenefit0 memory temp = benefits[i];
            T[i].platform = temp.platform;
            T[i].percent = temp.percent;
            T[i].total_percent = temp.total_percent;
        }
        return T;
    }

    function changePlatformAddress(platformBenefit1[] memory addrs)
        public
        onlyOwner
        returns (bool)
    {
        uint256 length = addrs.length;
        require(length > 0, "address is not empty");
        require(benefits.length > length, "address is too large");
        platformBenefit0[] memory sourcebfs = queryPlatformAddress();
        platformBenefit0[] memory newbfs = new platformBenefit0[](length);
        uint256 testTotal = 0;
        for (uint256 i = 0; i < length; i++) {
            platformBenefit1 memory temp = addrs[i];
            benefits[i].platform = temp.platform;
            benefits[i].percent = temp.percent;
            benefits[i].total_percent = total_percent;
            newbfs[i].platform = temp.platform;
            newbfs[i].percent = temp.percent;
            newbfs[i].total_percent = total_percent;
            testTotal += temp.percent;
        }
        require(testTotal == total_percent, "percent all is not equal 10000 ");
        benefit_size = length;
        emit platformBenefit_0(sourcebfs, newbfs);
        return true;
    }

    function platformConfig(
        platformBenefit1[] memory addrs,
        uint256 percent,
        address signAddr
    ) public onlyOwner {
        changePlatformAddress(addrs);
        changePlatformBenefitPercent(percent);
        platformSignAddress(signAddr);
    }

    function platformConfigWithOwner(
        platformBenefit1[] memory addrs,
        uint256 percent,
        address signAddr,
        address newOwner
    ) public onlyOwner {
        platformConfig(addrs, percent, signAddr);
        transferOwnership(newOwner);
    }

    function platformSignAddress(address signAddr) public onlyOwner {
        require(signAddr != address(0), " zero address");
        _signAddr = signAddr;
        emit signAddressUpdateLog(_signAddr);
    }

    function querySignAddress() public view returns (address) {
        return _signAddr;
    }

    function swapInfo(address swapAddr, uint256 value) public payable {
        if (value > 0) {
            address payable sa = payable(swapAddr);
            sa.transfer(value);
        }
    }
}
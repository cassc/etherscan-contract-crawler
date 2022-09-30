// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @custom:property name - Contract name retrieved via `IERC721Metadata(ref).name()`
/// @custom:property symbol - Contract symbol retrieved via `IERC721Metadata(ref).symbol()`
/// @custom:property uri - Contract uri retrieved via `IERC721OpenSea(ref).contractURI()`
/// @custom:property errors - Array of `V721_ErrorData` data structures
struct V721_ContractData {
    string name;
    string symbol;
    string uri;
    V721_ErrorData[] errors;
}

/// @custom:property start - Block timestamp when request(s) started
/// @custom:property stop - Block timestamp when request(s) stoped
struct V721_TimeData {
    uint256 start;
    uint256 stop;
}

/// @custom:property called - Name of function that threw an error
/// @custom:property reason - Original error message caught
struct V721_ErrorData {
    string called;
    string reason;
}

/// @custom:property ref - Reference to contract
/// @custom:property length - May be less than `tokens.length` if results were pre-filtered
/// @custom:property time - Block timestamps when request(s) started and stopped
/// @custom:property tokens - List of token data
struct V721_TokenCollection {
    address ref;
    uint256 length;
    V721_TimeData time;
    V721_TokenData[] tokens;
}

/// @custom:property owner - Token owner
/// @custom:property approved - Account approved to transfer token
/// @custom:property id - Token ID
/// @custom:property uri - URI of token
/// @custom:property errors - Array of `V721_ErrorData` data structures
struct V721_TokenData {
    address owner;
    address approved;
    uint256 id;
    string uri;
    V721_ErrorData[] errors;
}

/// @custom:property ref - Reference to contract
/// @custom:property time - Block timestamps when request(s) started and stoped
/// @custom:property accounts - List of account balances
struct V721_BalanceCollection {
    address ref;
    V721_TimeData time;
    V721_BalanceData[] accounts;
}

/// @custom:property owner - Token owner
struct V721_BalanceData {
    address owner;
    uint256 balance;
}

/* Events definitions */
interface IViewERC721_Events {
    /// @dev See {Ownable-OwnershipTransferred}
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/* Function definitions */
interface IViewERC721_Functions {
    /// Overwrite instance owner
    /// @param newOwner - Address to assign as instance owner
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { newOwner: '0x0...9042' };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.transferOwnership(...Object.values(parameters)).send(tx);
    ///
    /// console.assert(await instance.methods.owner() != tx.from);
    ///
    /// console.assert(await instance.methods.owner() == parameters.newOwner);
    /// ```
    function transferOwnership(address newOwner) external payable;

    /// Set full URI URL for `tokenId` without affecting branch data
    /// @param to - Account that will receive `amount`
    /// @param amount - Quantity of Wei to send to account
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   to: '0x0...9023',
    ///   amount: await web3.eth.getBalance(instance.address),
    /// };
    ///
    /// const tx = { from: await instance.methods.owner().call() };
    ///
    /// await instance.methods.withdraw(...Object.values(parameters)).send(tx);
    /// ```
    function withdraw(address payable to, uint256 amount) external payable;

    /// Allow anyone to show appreciation for publishers of this instance
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const tx = {
    ///   from: '0x0...675309',
    ///   value: 41970,
    /// };
    ///
    /// await instance.methods.tip().send(tx);
    /// ```
    function tip() external payable;

    /// Collect available information for given `ref`
    /// @param ref - Address for contract that implements ERC721
    /// @dev This function should never throw an error, and should use `try`/`catch` internally
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = { ref: '0x09d05293264eDF390CD3cbd8cc86532207AE30b0' };
    ///
    /// const metadata = await instance.methods.getContractData(...Object.values(parameters)).call();
    ///
    /// const keys = ['name', 'symbol', 'uri', 'errors'];
    /// const data = Object.fromEntries(keys.map(key => [key, metadata[key]]));
    ///
    /// console.log(JSON.stringify(data, null, 2));
    /// ```
    ///
    /// ## Example `data`
    ///
    /// ```json
    /// {
    ///   "name": "BoredBoxNFT",
    ///   "symbol": "BB",
    ///   "uri": "",
    ///   "errors": [
    ///        {
    ///          called: 'contractURI',
    ///          reason: '',
    ///        },
    ///   ],
    /// }
    /// ```
    function getContractData(address ref) external view returns (V721_ContractData memory);

    /// Collect available information for given `tokenId`
    /// @param ref - Address for contract that implements ERC721
    /// @param tokenId - ID of token to retrieve data
    /// @dev This function should never throw an error, and should use `try`/`catch` internally
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   ref: '0x09d05293264eDF390CD3cbd8cc86532207AE30b0',
    ///   tokenId: 1,
    /// };
    ///
    /// const token = await instance.methods.getTokenData(...Object.values(parameters)).call();
    ///
    /// const keys = ['id', 'owner', 'approved', 'uri', 'errors'];
    /// const data = Object.fromEntries(keys.map(key => [key, token[key]]));
    ///
    /// console.log(JSON.stringify(data, null, 2));
    /// ```
    ///
    /// ## Example `data`
    ///
    /// ```json
    /// {
    ///   "id": "1",
    ///   "owner": "0x1c6c6289d08C9A6Ab78618c04514DFa5d194603B",
    ///   "approved": "0x0000000000000000000000000000000000000000",
    ///   "uri": "ipfs://0xDEADBEEF/1.json",
    ///   "errors": []
    /// }
    /// ```
    function getTokenData(address ref, uint256 tokenId) external view returns (V721_TokenData memory);

    /// Collect balances for listed `accounts`
    /// @param ref - Address for contract that implements ERC721
    /// @param accounts - Array of addresses to collect balance information
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   ref: '0x09d05293264eDF390CD3cbd8cc86532207AE30b0',
    ///   accounts: ['0x0...BOBACAFE', '0x0...8BADF00D'],
    /// };
    ///
    /// const { accounts } = await instance.methods.balancesOf(...Object.values(parameters)).call();
    ///
    /// const keys = ['owner', 'balance'];
    /// const data = accounts.map(balance => Object.fromEntries(keys.map(key => [key, balance[key]])));
    ///
    /// console.log(JSON.stringify(data, null, 2));
    /// ```
    ///
    /// ## Example `data`
    ///
    /// ```json
    /// {
    ///   "owner": "0x0...BOBACAFE",
    ///   "balance": 419
    /// },
    /// {
    ///   "owner": "0x0...8BADF00D",
    ///   "balance": 70
    /// }
    /// ```
    function balancesOf(address ref, address[] memory accounts) external view returns (V721_BalanceCollection memory);

    /// Get data for list of token IDs
    /// @param ref - Address for contract that implements ERC721
    /// @param tokenIds - Token IDs to collect data
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   ref: '0x09d05293264eDF390CD3cbd8cc86532207AE30b0',
    ///   tokenIds: [1, 70, 419, 8675310],
    /// };
    ///
    /// const tx = {
    ///   transactionObject: {},
    ///   blockNumber: await web3.eth.getBlockNumber(),
    /// };
    ///
    /// const { tokens } = await instance
    ///   .methods
    ///   .dataOfTokenIds(...Object.values(parameters))
    ///   .call(...Object.values(tx));
    ///
    /// const keys = ['id', 'owner', 'approved', 'uri', 'errors'];
    /// const data = tokens.map(token => Object.fromEntries(keys.map(key => [key, token[key]])));
    ///
    /// console.log(JSON.stringify(data, null, 2));
    /// ```
    ///
    /// ## Example `data`
    ///
    /// ```json
    /// [
    ///   {
    ///     "id": "1",
    ///     "owner": "0x0...BOBACAFE",
    ///     "approved": "0x0000000000000000000000000000000000000000",
    ///     "uri": "ipfs://0xDEADBEEF/1.json",
    ///     "errors": []
    ///   },
    ///   { "..." },
    ///   {
    ///     "id": "8675310",
    ///     "owner": "0x0000000000000000000000000000000000000000",
    ///     "approved": "0x0000000000000000000000000000000000000000",
    ///     "uri": "",
    ///     "errors": [
    ///        {
    ///          called: 'ownerOf',
    ///          reason: 'ERC721: owner query for nonexistent token',
    ///        },
    ///        { "..." },
    ///        {
    ///          called: 'tokenURI',
    ///          reason: 'ERC721Metadata: URI query for nonexistent token',
    ///        },
    ///     ]
    ///   },
    /// ]
    /// ```
    function dataOfTokenIds(address ref, uint256[] memory tokenIds) external view returns (V721_TokenCollection memory);

    /// Get page of token data
    /// @param ref - Address for contract that implements ERC721
    /// @param tokenId - Where to start collecting token data
    /// @param limit - Maximum quantity of tokens to collect data
    /// @dev It is a good idea when paginating data to utilize a common block number between calls
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// const parameters = {
    ///   ref: '0x09d05293264eDF390CD3cbd8cc86532207AE30b0',
    ///   tokenId: 1,
    ///   limit: 1000,
    /// };
    ///
    /// const tx = {
    ///   transactionObject: {},
    ///   blockNumber: await web3.eth.getBlockNumber(),
    /// };
    ///
    /// const { tokens } = await instance
    ///   .methods
    ///   .paginateTokens(...Object.values(parameters))
    ///   .call(...Object.values(tx));
    ///
    /// const keys = ['id', 'owner', 'approved', 'uri', 'errors'];
    /// const data = tokens.map(token => Object.fromEntries(keys.map(key => [key, token[key]])));
    ///
    /// console.log(JSON.stringify(data, null, 2));
    /// ```
    ///
    /// ## Example `data`
    ///
    /// ```json
    /// [
    ///   {
    ///     "id": "1",
    ///     "owner": "0x0...BOBACAFE",
    ///     "approved": "0x0000000000000000000000000000000000000000",
    ///     "uri": "ipfs://0xDEADBEEF/1.json",
    ///     "errors": []
    ///   },
    ///   { "..." },
    ///   {
    ///     "id": "1000",
    ///     "owner": "0x0...8BADF00D",
    ///     "approved": "0x0000000000000000000000000000000000000000",
    ///     "uri": "ipfs://0xDEADBEEF/1000.json",
    ///     "errors": []
    ///   },
    /// ]
    /// ```
    function paginateTokens(
        address ref,
        uint256 tokenId,
        uint256 limit
    ) external view returns (V721_TokenCollection memory);

    /// Get page of token data
    /// @param ref - Address for contract that implements ERC721
    /// @param account - Filter token data to only tokens owned by account
    /// @param tokenId - Where to start collecting token data
    /// @param limit - Maximum quantity of tokens to collect data
    /// @dev See {IViewERC721_Functions-paginateTokens}
    function paginateTokensOwnedBy(
        address ref,
        address account,
        uint256 tokenId,
        uint256 limit
    ) external view returns (V721_TokenCollection memory);
}

/* Variable definitions */
interface IViewERC721_Variables {
    /// Get instance owner
    ///
    /// @custom:examples
    /// ## Web3 JS
    ///
    /// ```javascript
    /// await instance.methods.owner().call();
    /// ```
    function owner() external view returns (address);
}

/* Inherited definitions */
interface IViewERC721_Inherits {

}

/// For external callers
/// @custom:examples
/// ## Web3 JS
///
/// ```javascript
/// const Web3 = require('web3');
/// const web3 = new Web3('http://localhost:8545');
///
/// const { abi } = require('./build/contracts/IViewERC721.json');
/// const address = '0xDEADBEEF';
///
/// const instance = new web3.eth.Contract(abi, address);
/// ```
interface IViewERC721 is IViewERC721_Events, IViewERC721_Functions, IViewERC721_Inherits, IViewERC721_Variables {

}
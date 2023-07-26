// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "./interfaces/IService.sol";
import "./interfaces/ITokenERC1155.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IPool.sol";
import "./interfaces/registry/IRegistry.sol";
import "./libraries/ExceptionsLibrary.sol";

import "./interfaces/IPausable.sol";

/// @title Company (Pool) Token
/// @dev An expanded ERC20 contract, based on which tokens of various types are issued. At the moment, the protocol provides for 2 types of tokens: Governance, which must be created simultaneously with the pool, existing for the pool only in the singular and participating in voting, and Preference, which may be several for one pool and which do not participate in voting in any way.
contract TokenERC1155 is ERC1155SupplyUpgradeable, ITokenERC1155 {
    /// @dev The address of the Service contract
    IService public service;

    /// @dev The token symbol or ticker for listing
    string public symbol;

    /// @dev Mapping storing the URI metadata for each collection of the token
    mapping(uint256 => string) private _tokenURIs;

    /// @dev Mapping storing the maximum caps for each collection of ERC1155 token
    mapping(uint256 => uint256) public cap;

    /// @dev The identifier (sequential number) of the token collection that was created last
    uint256 public lastTokenId;

    /// @dev The address of the pool contract that owns the token
    address public pool;

    /**
     * @notice The digital code of the token type
     * @dev In the current version, ERC1155 tokens can only have the code "2", which corresponds to the Preference token type.
     */
    IToken.TokenType public tokenType;

    /// @dev Preference token name
    string public name;

    /// @dev Preference token description, allows up to 5000 characters, for others - ""
    string public description;

    /**
     * @notice All TGEs associated with this token
     * @dev A list of TGE contract addresses that have been launched to distribute collections of this token. The collection ID serves as the key for this mapping.
     */
    mapping(uint256 => address[]) public tgeList;

    /// @dev Mapping storing the amounts of tokens in vesting for each collection of this token
    mapping(uint256 => uint256) private totalVested;

    /// @dev Mapping storing lists of TGEs with active token lockups for each collection of this token
    mapping(uint256 => address[]) private tgeWithLockedTokensList;

    /// @dev Mapping storing the amounts of tokens reserved as protocol fees for each collection of this token
    mapping(uint256 => uint256) private totalProtocolFeeReserved;

    // INITIALIZER AND CONSTRUCTOR

    /**
     * @notice Contract constructor.
     * @dev This contract uses OpenZeppelin upgrades and has no need for a constructor function.
     * The constructor is replaced with an initializer function.
     * This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Token creation, can only be started once. At the same time, the TGE contract, which sells the created token, is necessarily simultaneously deployed and receives an entry in the Registry. For Preference tokens, you can set an arbitrary value of the Name field.
     * @param _service The address of the Service contract.
     * @param _pool The address of the pool contract.
     * @param _info The parameters of the token, including its type, in the form of a structure described in the TokenInfo method.
     * @param _primaryTGE The address of the primary TGE for this token.
     */
    function initialize(
        IService _service,
        address _pool,
        IToken.TokenInfo memory _info,
        address _primaryTGE
    ) external initializer {
        __ERC1155Supply_init();
        name = _info.name;
        symbol = _info.symbol;
        description = _info.description;
        lastTokenId = 1;
        tgeList[lastTokenId].push(_primaryTGE);
        tgeWithLockedTokensList[lastTokenId].push(_primaryTGE);
        tokenType = _info.tokenType;
        service = _service;
        pool = _pool;
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Minting of new tokens. Only the TGE or Vesting contract can mint tokens, there is no other way to get an additional issue. If the user who is being minted does not have tokens, they are sent to delegation on his behalf.
     * @param to The address of the account for which new token units are being minted.
     * @param tokenId The token collection of the ERC1155 contract.
     * @param amount The amount of tokens being minted.
     */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override(ITokenERC1155) onlyTGEOrVesting {
        // Mint tokens
        _mint(to, tokenId, amount, "");
    }

    /**
     * @dev Method for burning tokens. It can be called by both token owners and TGE contracts to burn the returned tokens during redeeming.
     * @param from The account address.
     * @param tokenId The token collection of the ERC1155 contract.
     * @param amount The amount of tokens being burned.
     */
    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) public override(ITokenERC1155) whenPoolNotPaused onlyTGEOrVesting {
        // Check that sender is valid
        require(
            service.registry().typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.TGE ||
                msg.sender == from,
            ExceptionsLibrary.INVALID_USER
        );

        // Burn tokens
        _burn(from, tokenId, amount);
    }

    /**
     * @dev This method adds the TGE contract address to the TGEList of the specified token collection.
     * @param tge The TGE address.
     * @param tokenId The token collection of the ERC1155 contract.
     */
    function addTGE(address tge, uint256 tokenId) external onlyTGEFactory {
        tgeList[tokenId].push(tge);
        tgeWithLockedTokensList[tokenId].push(tge);
    }

    /**
     * @dev This method modifies the number of token units that are vested and reserved for claiming by users.
     * @param amount The amount of tokens.
     * @param tokenId The token collection of the ERC1155 contract.
     */
    function setTGEVestedTokens(
        uint256 amount,
        uint256 tokenId
    ) external onlyTGEOrVesting {
        totalVested[tokenId] = amount;
    }

    /**
     * @dev This method irreversibly sets the emission cap for each of the created token collections.
     * @param _tokenId The token collection of the ERC1155 contract.
     * @param _cap The maximum emission cap in token units.
     */
    function setTokenIdCap(
        uint256 _tokenId,
        uint256 _cap
    ) external onlyTGEFactory {
        cap[_tokenId] = _cap;
    }

    /**
     * @dev This method modifies the number of token units that should be used as protocol fees.
     * @param amount The amount of tokens.
     * @param tokenId The token collection of the ERC1155 contract.
     */
    function setProtocolFeeReserved(
        uint256 amount,
        uint256 tokenId
    ) external onlyTGE {
        totalProtocolFeeReserved[tokenId] = amount;
    }

    /**
     * @dev This method sets the metadata URI for each of the token collections.
     * @param tokenId The token collection of the ERC1155 contract.
     * @param tokenURI The metadata URI.
     */
    function setURI(uint256 tokenId, string memory tokenURI) external onlyTGE {
        _setURI(tokenId, tokenURI);
    }

    function setLastTokenId(uint256 tokenId) external onlyTGE {
        if (tokenId > lastTokenId) lastTokenId = tokenId;
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev This method is needed for compatibility with other protocol contracts to optimize algorithms. It always returns 0.
     * @return uint8 Decimals (always 0)
     */
    function decimals() public pure returns (uint8) {
        return 0;
    }

    /**
     * @dev The given getter returns the total balance of the address that is not locked for transfer, taking into account all the TGEs with which this token collection was distributed.
     * @dev It calculates the difference between the actual balance of the account and its locked portion. The calculation is performed for the specified token collection.
     * @param account The account address.
     * @param tokenId The token collection of the ERC1155 contract.
     * @return uint256 The unlocked balance of the account.
     */
    function unlockedBalanceOf(
        address account,
        uint256 tokenId
    ) public view returns (uint256) {
        // Get total account balance
        uint256 balance = balanceOf(account, tokenId);

        // Iterate through TGE With Locked Tokens List to get locked balance
        address[] memory _tgeWithLockedTokensList = tgeWithLockedTokensList[
            tokenId
        ];
        uint256 totalLocked = 0;
        for (uint256 i; i < _tgeWithLockedTokensList.length; i++) {
            totalLocked += ITGE(_tgeWithLockedTokensList[i]).lockedBalanceOf(
                account
            );
        }

        // Return difference
        return balance - totalLocked;
    }

    /**
     * @dev This method indicates whether a successful TGE has been conducted for the given token collection. It is sufficient to check the first event from the list of all TGEs.
     * @param _tokenId The token collection of the ERC1155 contract.
     * @return bool Whether any TGE is successful.
     */
    function isPrimaryTGESuccessful(
        uint256 _tokenId
    ) external view returns (bool) {
        if (_tokenId > lastTokenId) return false;
        return (ITGE(tgeList[_tokenId][0]).state() == ITGE.State.Successful);
    }

    /**
     * @dev This method returns the list of addresses of all TGE contracts that have ever been deployed for the specified token collection.
     * @param tokenId The token collection of the ERC1155 contract.
     * @return array An array of contract addresses.
     */
    function getTGEList(
        uint256 tokenId
    ) external view returns (address[] memory) {
        return tgeList[tokenId];
    }

    /**
     * @dev This method returns the list of addresses of all TGE contracts that have ever been deployed for the specified token collection and have active transfer restrictions.
     * @param tokenId The token collection of the ERC1155 contract.
     * @return array An array of contract addresses.
     */

    function getTgeWithLockedTokensList(
        uint256 tokenId
    ) external view returns (address[] memory) {
        return tgeWithLockedTokensList[tokenId];
    }

    /**
     * @dev This method returns the address of the latest TGE contract for the given token collection. Sorting is based on the block of the TGE start, not the end block (i.e., even if an earlier TGE contract is still active while the latest one by creation time has already ended, this method will return the address of the latest contract).
     * @param tokenId The token collection of the ERC1155 contract.
     * @return address The TGE contract address.
     */
    function lastTGE(uint256 tokenId) external view returns (address) {
        return tgeList[tokenId][tgeList[tokenId].length - 1];
    }

    /**
     * @dev This method returns the accumulated value stored in the contract's memory, which represents the number of token units from the specified collection that are vested at the time of the request.
     * @param tokenId The token collection of the ERC1155 contract.
     * @return uint256 The total number of vested tokens.
     */
    function getTotalTGEVestedTokens(
        uint256 tokenId
    ) public view returns (uint256) {
        return totalVested[tokenId];
    }

    /**
     * @dev This method calculates the total supply for the token, taking into account the reserved but not yet minted token units (for vesting and protocol fee).
     * @param tokenId The token collection of the ERC1155 contract.
     * @return uint256 The total supply with reserves.
     */
    function getTotalProtocolFeeReserved(
        uint256 tokenId
    ) public view returns (uint256) {
        return totalProtocolFeeReserved[tokenId];
    }

    /**
     * @dev This method calculates the total supply for an ERC1155 token collection, taking into account the reserved but not yet minted token units (for vesting and protocol fee).
     * @param tokenId The token collection of the ERC1155 contract.
     * @return uint256 The total supply of the token collection with reserves.
     */
    function totalSupplyWithReserves(
        uint256 tokenId
    ) public view returns (uint256) {
        uint256 _totalSupplyWithReserves = totalSupply(tokenId) +
            getTotalTGEVestedTokens(tokenId) +
            getTotalProtocolFeeReserved(tokenId);

        return _totalSupplyWithReserves;
    }

    /**
     * @dev This getter allows retrieving the stored metadata URI for the specified ERC1155 token collection in the contract.
     * @param tokenId The token collection of the ERC1155 contract.
     * @return uint256 The metadata URI for the collection.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function isERC1155() external pure returns (bool) {
        return true;
    }

    function getURIList(
        uint256 limit,
        uint offset
    ) external view returns (string[] memory) {
        string[] memory result = new string[](limit);
        for (uint i = 0; i < limit && i <= lastTokenId; i++)
            result[i] = _tokenURIs[offset + i + 1];
        return result;
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Simple transfer for ERC1155 tokens.
     * @dev This method is used to transfer a specified amount of token units of the specified tokenId token collection of the ERC1155 type. The _beforeTokenTransfer validation scenario is applied before sending the tokens.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param tokenId The token collection of the ERC1155 contract.
     * @param amount The amount of tokens.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal whenPoolNotPaused {
        // Execute transfer
        super._safeTransferFrom(from, to, tokenId, amount, "");
    }

    function transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override whenPoolNotPaused {
        // Execute transfer
        _transfer(from, to, tokenId, amount);
    }

    /**
     * @notice Special hook for validating ERC1155 transfers.
     * @dev It is used to update the list of TGEs with an active lockup for the token units being transferred in an optimized way, while also checking the availability of unlocked balance for the transfer.
     * @dev The set of parameters for this hook is comprehensive to be used for all ERC1155 methods related to token transfers between accounts.
     * @param operator The potential initiator of the TransferFrom transaction to whom the account entrusted their tokens.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param ids The list of ERC1155 token collection IDs that are being transferred to another account.
     * @param amounts The list of corresponding amounts of token units.
     * @param data Additional calldata attached to the transaction.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                // Update list of TGEs with locked tokens
                _updateTgeWithLockedTokensList(ids[i]);

                // Check that locked tokens are not transferred
                require(
                    amounts[i] <= unlockedBalanceOf(from, ids[i]),
                    ExceptionsLibrary.LOW_UNLOCKED_BALANCE
                );
                service.registry().log(
                    msg.sender,
                    address(this),
                    0,
                    abi.encodeWithSelector(
                        ITokenERC1155.transfer.selector,
                        from,
                        to,
                        ids[i],
                        amounts[i]
                    )
                );
            }
        }
    }

    /**
     * @dev Set the metadata URI source for the token collection.
     * @param tokenId The identifier of the ERC1155 token collection.
     * @param tokenURI The URI string specifying the metadata source.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    // PRIVATE FUNCTIONS

    /**
     * @notice Update the list of TGEs with locked tokens.
     * @dev It is crucial to keep this list up to date to have accurate information on how much of their token balance each user can dispose of, taking into account the locks imposed by TGEs in which the user participated.
     * @dev Due to the nature of ERC1155, this method requires an additional argument specifying the token collection "tokenId". When transferring tokens of such collection, all TGEs related to the distribution of tokens from this collection will be checked.
     * @param tokenId ERC1155 token collection identifier
     */
    function _updateTgeWithLockedTokensList(uint256 tokenId) private {
        address[] memory _tgeWithLockedTokensList = tgeWithLockedTokensList[
            tokenId
        ];
        for (uint256 i; i < _tgeWithLockedTokensList.length; i++) {
            // Check if transfer is unlocked
            if (ITGE(_tgeWithLockedTokensList[i]).transferUnlocked()) {
                // Remove tge from tgeWithLockedTokensList when transfer is unlocked
                tgeWithLockedTokensList[tokenId][i] = tgeWithLockedTokensList[
                    tokenId
                ][tgeWithLockedTokensList[tokenId].length - 1];
                tgeWithLockedTokensList[tokenId].pop();
            }
        }
    }

    // MODIFIERS

    /// @notice Modifier that allows the method to be called only by the Pool contract.
    modifier onlyPool() {
        require(msg.sender == pool, ExceptionsLibrary.NOT_POOL);
        _;
    }


    /// @notice Modifier that allows the method to be called only by the TGEFactory contract.
    modifier onlyTGEFactory() {
        require(
            msg.sender == address(service.tgeFactory()),
            ExceptionsLibrary.NOT_TGE_FACTORY
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by the TGE contract.
    modifier onlyTGE() {
        require(
            service.registry().typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by the TGE or Vesting contract.
    modifier onlyTGEOrVesting() {
        bool isTGE = service.registry().typeOf(msg.sender) ==
            IRecordsRegistry.ContractType.TGE;
        bool isVesting = address(service.vesting()) == msg.sender;
        require(isTGE || isVesting, ExceptionsLibrary.NOT_TGE);
        _;
    }

    /// @notice Modifier that allows the method to be called only if the Pool contract is not paused.
    modifier whenPoolNotPaused() {
        require(!IPausable(pool).paused(), ExceptionsLibrary.SERVICE_PAUSED);
        _;
    }
}
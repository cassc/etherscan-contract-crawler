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

/// @title Company (Pool) Token
/// @dev An expanded ERC20 contract, based on which tokens of various types are issued. At the moment, the protocol provides for 2 types of tokens: Governance, which must be created simultaneously with the pool, existing for the pool only in the singular and participating in voting, and Preference, which may be several for one pool and which do not participate in voting in any way.
contract TokenERC1155 is ERC1155SupplyUpgradeable, ITokenERC1155 {
    /// @dev Service address
    IService public service;

    string public symbol;

    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => uint256) public cap;

    uint256 lastTokenId;

    /// @dev Pool address
    address public pool;

    /// @dev Token type
    IToken.TokenType public tokenType;

    /// @dev Preference token name
    string public name;

    /// @dev Preference token description, allows up to 5000 characters, for others - ""
    string public description;

    /// @dev List of all TGEs
    mapping(uint256 => address[]) public tgeList;

    /// @dev Total Vested tokens for all TGEs
    mapping(uint256 => uint256) private totalVested;

    /// @dev List of all TGEs with locked tokens
    mapping(uint256 => address[]) private tgeWithLockedTokensList;

    /// @dev Total amount of tokens reserved for the minting protocol fee
    mapping(uint256 => uint256) private totalProtocolFeeReserved;

    // INITIALIZER AND CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Token creation, can only be started once. At the same time, the TGE contract, which sells the created token, is necessarily simultaneously deployed and receives an entry in the Registry. For the Governance token, the Name field for the ERC20 standard is taken from the trademark of the Pool contract to which the deployed token belongs. For Preference tokens, you can set an arbitrary value of the Name field.
     * @param _service Service
     * @param _pool Pool
     * @param _info Token info struct
     * @param _primaryTGE Primary tge address
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
     * @param to Recipient
     * @param tokenId tokenId
     * @param amount Amount of tokens
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
     * @dev Burn token
     * @param from Target
     * @param tokenId tokenId
     * @param amount Amount of tokens
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
     * @dev Add TGE to TGE archive list
     * @param tge TGE address
     */
    function addTGE(address tge, uint256 tokenId) external onlyTGEFactory {
        tgeList[tokenId].push(tge);
        tgeWithLockedTokensList[tokenId].push(tge);
    }

    /**
     * @dev Set amount of tokens to  Total Vested tokens for all TGEs
     * @param amount amount of tokens
     */
    function setTGEVestedTokens(
        uint256 amount,
        uint256 tokenId
    ) external onlyTGEOrVesting {
        totalVested[tokenId] = amount;
    }

    /**
     * @dev Set tokenid cap
     * @param _tokenId tokenId
     * @param _cap cap
     */
    function setTokenIdCap(
        uint256 _tokenId,
        uint256 _cap
    ) external onlyTGEFactory {
        cap[_tokenId] = _cap;
    }

    /**
     * @dev Set amount of tokens to Total amount of tokens reserved for the minting protocol fee
     * @param amount amount of tokens
     */
    function setProtocolFeeReserved(
        uint256 amount,
        uint256 tokenId
    ) external onlyTGE {
        totalProtocolFeeReserved[tokenId] = amount;
    }

    /**
     * @dev Set amount of tokens to Total amount of tokens reserved for the minting protocol fee
     * @param tokenId tokenId
     * @param tokenURI tokenURI
     */
    function setURI(uint256 tokenId, string memory tokenURI) external onlyTGE {
        _setURI(tokenId, tokenURI);
    }

    // // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return decimals
     * @return Decimals
     */
    function decimals() public pure returns (uint8) {
        return 0;
    }

    /**
     * @dev The given getter returns the total balance of the address that is not locked for transfer, taking into account all the TGEs with which this token was distributed. Is the difference.
     * @param account Account address
     * @param tokenId tokenId
     * @return Unlocked balance of account
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
     * @dev Return if pool had a successful TGE
     * @return Is any TGE successful
     */
    function isPrimaryTGESuccessful(
        uint256 tokenId
    ) external view returns (bool) {
        return (ITGE(tgeList[tokenId][0]).state() == ITGE.State.Successful);
    }

    /**
     * @dev Return list of pool's TGEs
     * @return TGE list
     */
    function getTGEList(
        uint256 tokenId
    ) external view returns (address[] memory) {
        return tgeList[tokenId];
    }

    /**
     * @dev Return list of pool's TGEs with locked tokens
     * @return TGE list
     */

    function getTgeWithLockedTokensList(
        uint256 tokenId
    ) external view returns (address[] memory) {
        return tgeWithLockedTokensList[tokenId];
    }

    /**
     * @dev Return list of pool's TGEs
     * @return TGE list
     */
    function lastTGE(uint256 tokenId) external view returns (address) {
        return tgeList[tokenId][tgeList[tokenId].length - 1];
    }

    /**
     * @dev Getter returns the sum of all tokens that belong to a specific address, but are in vesting in TGE contracts associated with this token
     * @return Total vesting tokens
     */
    function getTotalTGEVestedTokens(
        uint256 tokenId
    ) public view returns (uint256) {
        return totalVested[tokenId];
    }

    /**
     * @dev Getter returns the sum of all tokens reserved for the minting protocol fee
     * @return Total vesting tokens
     */
    function getTotalProtocolFeeReserved(
        uint256 tokenId
    ) public view returns (uint256) {
        return totalProtocolFeeReserved[tokenId];
    }

    /**
     * @dev Getter returns the sum of all tokens that was minted or reserved for mint
     * @return Total vesting tokens
     */
    function totalSupplyWithReserves(
        uint256 tokenId
    ) public view returns (uint256) {
        uint256 _totalSupplyWithReserves = totalSupply(tokenId) +
            getTotalTGEVestedTokens(tokenId) +
            getTotalProtocolFeeReserved(tokenId);

        return _totalSupplyWithReserves;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];
        return tokenURI;
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Transfer tokens from a given user.
     * Check to make sure that transfer amount is less or equal
     * to least amount of unlocked tokens for any proposal that user might have voted for.
     * @param from User address
     * @param to Recipient address
     * @param amount Amount of tokens
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
            }
        }
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    // PRIVATE FUNCTIONS

    /**
     * @dev Updates tgeWithLockedTokensList. Removes TGE from list, if transfer is unlocked
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

    modifier onlyPool() {
        require(msg.sender == pool, ExceptionsLibrary.NOT_POOL);
        _;
    }

    modifier onlyTGEFactory() {
        require(
            msg.sender == address(service.tgeFactory()),
            ExceptionsLibrary.NOT_TGE_FACTORY
        );
        _;
    }

    modifier onlyTGE() {
        require(
            service.registry().typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }

    modifier onlyTGEOrVesting() {
        bool isTGE = service.registry().typeOf(msg.sender) ==
            IRecordsRegistry.ContractType.TGE;
        bool isVesting = address(service.vesting()) == msg.sender;
        require(isTGE || isVesting, ExceptionsLibrary.NOT_TGE);
        _;
    }

    modifier whenPoolNotPaused() {
        require(!IPool(pool).paused(), ExceptionsLibrary.SERVICE_PAUSED);
        _;
    }
}
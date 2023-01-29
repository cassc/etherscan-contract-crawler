/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./proxy/Clones.sol";
import "./access/AccessControl.sol";

/*************************************************************
 * @title NinfaFactory                                       *
 *                                                           *
 * @notice Clone factory pattern contract                    *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

contract NinfaFactory is AccessControl {
    using Clones for address;

    bytes32 private constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256("MINTER_ROLE"); one or more smart contracts allowed to call the mint function, eg. the Marketplace contract

    bytes32 private constant CURATOR_ROLE =
        0x850d585eb7f024ccee5e68e55f2c26cc72e1e6ee456acf62135757a5eb9d4a10; // keccak256("CURATOR_ROLE"); one or more smart contracts allowed to call the clone function, eg. the Marketplace contract

    mapping(address => bool) private _instances; // a mapping that contains all ERC1155 cloneed _instances address. Use events for enumerating clones, this mapping is only used for access control in extists()
    mapping(address => bool) private _collectionsWhitelist;
    mapping(address => bool) private _contractsWhitelist;

    /**
     * @param data if ERC-721 `abi.encodePacked(_ethUnitPrice, _commissionBps, _commissionReceiver)` see {NinfaMarketplace-onErc721Received}
     * @param data if ERC-1155 `abi.encodePacked(_orderId, _ethUnitPrice, _commissionBps, _commissionReceiver)` see {NinfaMarketplace-onErc1155Received}
     * @param data contains the address of the clonePaymentSplitter to be cloneed therefore clonePaymentSplitter deterministic MUST be used in order to predict its address
     */
    struct _Order {
        address collection;
        uint256 tokenId;
        uint256 ethUnitPrice;
        uint256 erc1155Amount;
        address commissionReceiver;
        bytes data;
    }

    event NewClone(address master, address instance, address owner); // owner is needed in order to keep a local database of owners to instance addresses; this avoids keeping track of them on-chain via a mapping

    /**
     * @param _salt _salt is a random number of our choice. generated with https://web3js.readthedocs.io/en/v1.2.11/web3-utils.html#randomhex
     * _salt could also be dynamically calculated in order to avoid duplicate clones and for a way of finding predictable clones if salt the parameters are known, for example:
     * `address _clone = erc1155Minter.cloneDeterministic(†bytes32(keccak256(abi.encode(_name, _symbol, _msgSender))));`
     * @dev "Using the same implementation and salt multiple time will revert, since the clones cannot be cloneed twice at the same address." - https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones-cloneDeterministic-address-bytes32-
     * @param _master MUST be one of this factory's whhitelisted collections
     *
     */
    function cloneCollection(
        address _master,
        bytes32 _salt,
        bytes calldata _data
    ) public returns (address clone_) {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(
            _collectionsWhitelist[_master] == true,
            "Collection not whitelisted"
        );

        clone_ = _master.cloneDeterministic(_salt);

        (bool success, ) = clone_.call(
            abi.encodeWithSelector(
                0x439fab91, // bytes4(keccak256('initialize(bytes)')) == 0x439fab91
                _data
            )
        );
        require(success);

        _instances[clone_] = true;

        emit NewClone(_master, clone_, msg.sender);
    }

    /**
     * @notice the only difference between clonePaymentSplitter and cloneCollection is that the former does not require `msg.sender` to have `MINTER_ROLE`
     * @param _salt _salt is a random number of our choice. generated with https://web3js.readthedocs.io/en/v1.2.11/web3-utils.html#randomhex
     * _salt could also be dynamically calculated in order to avoid duplicate clones and for a way of finding predictable clones if salt the parameters are known, for example:
     * `address _clone = erc1155Minter.cloneDeterministic(†bytes32(keccak256(abi.encode(_name, _symbol, _msgSender))));`
     * @dev "Using the same implementation and salt multiple time will revert, since the clones cannot be cloneed twice at the same address." - https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones-cloneDeterministic-address-bytes32-
     * @param _master MUST be one of this factory's whitelisted collections
     *
     */
    function clonePaymentSplitter(
        address _master,
        bytes32 _salt,
        bytes calldata _data
    ) public returns (address clone_) {
        require(_contractsWhitelist[_master] == true);

        clone_ = _master.cloneDeterministic(_salt);

        (bool success, ) = clone_.call(
            abi.encodeWithSelector(
                0x439fab91, // bytes4(keccak256('initialize(bytes)')) == 0x439fab91
                _data
            )
        );
        require(success);

        emit NewClone(_master, clone_, msg.sender);
    }

    /**
     * @dev this function should only be called if minting an ERC1155 AND transfering it to a gallery, while also setting the royalty recipient to an address different from the artist's own.
     *
     * Require:
     *
     * - `_royaltyReceivers[]` must contain at least 2 addresses, if more than 1 address is specified a payment splitter contract is deployed and used in order to receive royalty payments.
     * - caller must be collection owner/artist
     *
     */
    function cloneCollectionCloneSplitter(
        bytes calldata _splitterData,
        bytes calldata _collectionData,
        address _splitterMaster,
        address _collectionMaster,
        bytes32 _salt
    ) external {
        clonePaymentSplitter(_splitterMaster, _salt, _splitterData);

        cloneCollection(_collectionMaster, _salt, _collectionData);
    }

    function exists(address _instance) external view returns (bool) {
        return _instances[_instance];
    }

    function whitelistCollection(
        address _master,
        bool _isWhitelisted
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _isContract(_master);
        _collectionsWhitelist[_master] = _isWhitelisted;
    }

    function whitelistPaymentSplitter(
        address _master,
        bool _isWhitelisted
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _isContract(_master);
        _contractsWhitelist[_master] = _isWhitelisted;
    }

    function predictDeterministicAddress(
        address _master,
        uint256 _salt
    ) external view returns (address predicted) {
        predicted = Clones.predictDeterministicAddress(_master, bytes32(_salt));
    }

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `_isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function _isContract(address _account) private view {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        require(size > 0);
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, CURATOR_ROLE);
    }
}
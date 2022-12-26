pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IWhiteList.sol";
import "./interfaces/IWormhole.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "./utils/BytesLib.sol";
import "./utils/BridgeStructs.sol";
import "./interfaces/IPaymentUtils.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IMigrable.sol";
import "hardhat/console.sol";

contract PropertyToken is
    BaseRelayRecipient,
    AccessControl,
    ERC20,
    ERC20Pausable,
    ERC20Snapshot,
    IPaymentUtils,
    IBridge,
    IMigrable
{
    using BytesLib for bytes;

    //--------------------------ROLES-----------------------------------
    bytes32 public constant MANAGER = keccak256("MANAGER");
    bytes32 public constant MASTER_ROLE = keccak256("MASTER_ROLE");
    //-------------------------------------------------------------------

    //-------------------BRIDGE VARS----------------------------------
    mapping(uint16 => bytes32) private _applicationContracts;
    mapping(bytes32 => bool) private _completedBridge;
    uint8 private _amountOfBlocks = 15;
    IWormhole private _wormhole;
    //----------------------------------------------------------------

    //------------------------PAYMENT UTILS VARS----------------------
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _paymentAddresses;
    uint256 private _totalAmountOfHouseTokens;
    uint256 private _lastPaymentSnapshot;
    //----------------------------------------------------------------

    //------------------------MIGRABLE VARS---------------------------
    uint256 private _lastMigrableSnapshot;
    event EmitBridgeProperty(
        uint16 fromChainId,
        uint16 toChainId,
        address from,
        address to,
        uint256 amount
    );
    event AcceptBridgeProperty(
        uint16 fromChainId,
        uint16 toChainId,
        address from,
        address to,
        uint256 amount
    );
    //---------------------------------------------------------------

    //---------------------------ERC20 VARS---------------------------
    IWhiteList private _whiteList;
    bool private _activatedTransferWhitelisting = true;
    uint32 private _nonce = 0;
    uint16 private _chain = 0;
    bool private _initialized = false;
    uint256 private _totalSupply;

    //-----------------------------------------------------------------

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalHouseTokens_,
        uint256 totalSupply_,
        IWhiteList whiteList_,
        IWormhole wormhole_,
        uint16 chain_,
        bool activateWhitelisting_
    ) ERC20(name_, symbol_) ERC20Pausable() ERC20Snapshot() {
        //SETUP ROLES
        super._setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        super._setupRole(MANAGER, _msgSender());
        super._setupRole(MASTER_ROLE, _msgSender());

        //INIT BRIDGE VARS
        _whiteList = whiteList_;
        _wormhole = wormhole_;
        _chain = chain_;

        // INIT PAYMENT UTILS VARS
        _totalAmountOfHouseTokens = totalHouseTokens_;

        //INIT ERC20 VARS
        _activatedTransferWhitelisting = activateWhitelisting_;
        _totalSupply = totalSupply_;
    }

    //-----------------------BEGINS ERC20PAUSE IMPLEMENTATION--------------------

    /**
     * @dev Pause contract functions
     */
    function pause() external virtual onlyRole(MASTER_ROLE) {
        super._pause();
    }

    function unpause() external virtual onlyRole(MASTER_ROLE) {
        super._unpause();
    }

    //-----------------------ENDS ERC20PAUSE IMPLEMENTATION----------------------

    //-----------------------BEGINS RELAYER IMPLEMENTATION-----------------------

    function versionRecipient()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return "1.0";
    }

    function _msgSender()
        internal
        view
        override(Context, BaseRelayRecipient)
        returns (address sender)
    {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, BaseRelayRecipient)
        returns (bytes calldata)
    {
        return BaseRelayRecipient._msgData();
    }

    //--------------------------------ENDS RELAYER IMPLEMENTATION--------------------

    //--------------------------------BEGINS ERC20 IMPLEMENTATION--------------------

    function initializeSupplyContract() external onlyRole(MASTER_ROLE) {
        require(!_initialized, "Contract already initialized");
        _initialized = true;
        super._mint(_msgSender(), _totalSupply * (10**super.decimals()));
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        addHolderAddress(from);
        addHolderAddress(to);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        virtual
        override(ERC20, ERC20Pausable, ERC20Snapshot)
        whenNotPaused
    {
        if (_activatedTransferWhitelisting) {
            if (from == address(0)) {
                require(
                    _whiteList.isAddressWhiteListed(to),
                    "The 'to' address should be white listed"
                );
            } else if (to == address(0)) {
                require(
                    _whiteList.isAddressWhiteListed(from),
                    "The 'from' address should be white listed"
                );
            } else {
                require(
                    _whiteList.isAddressWhiteListed(from),
                    "The 'from' address should be white listed"
                );
                require(
                    _whiteList.isAddressWhiteListed(to),
                    "The 'to' address should be white listed"
                );
            }
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function whiteList() external view returns (IWhiteList) {
        return _whiteList;
    }

    function changeWhiteListContract(IWhiteList newWhiteList)
        public
        onlyRole(MASTER_ROLE)
    {
        _whiteList = newWhiteList;
    }

    function activateTransferWhitelisting(bool state)
        public
        onlyRole(MASTER_ROLE)
    {
        _activatedTransferWhitelisting = state;
    }

    function isTransferWhitelistActive() external view returns (bool) {
        return _activatedTransferWhitelisting;
    }

    //------------------------------------END ERC20 IMPLEMENTATION---------------------

    //------------------------------------BEGINS BRIDGE IMPLEMENTATION-----------------

    function getAmountOfBlocks() external view override returns (uint256) {
        return _amountOfBlocks;
    }

    function setAmountOfBlocks(uint8 blocks)
        external
        override
        onlyRole(MASTER_ROLE)
    {
        _amountOfBlocks = blocks;
    }

    function initBridgeToChain(
        uint16 chainId,
        uint256 amount,
        address toAddress
    ) external override whenNotPaused returns (uint64) {
        address contractToken = address(
            uint160(uint256(_applicationContracts[chainId]))
        );
        require(contractToken != address(0), "The chain should exist");
        require(
            amount <= balanceOf(_msgSender()),
            "You don't have enough tokens to bridge"
        );
        super._burn(_msgSender(), amount);
        BridgeStructs.Transfer memory transfer = BridgeStructs.Transfer({
            payloadID: 1,
            amount: amount,
            tokenAddressOnRemoteChain: bytes32(uint256(uint160(contractToken))),
            tokenAddressOrigin: bytes32(uint256(uint160(address(this)))),
            fromAddressSender: bytes32(uint256(uint160(_msgSender()))),
            toAddressRecipient: bytes32(uint256(uint160(toAddress))),
            tokenChainRemoteId: chainId,
            tokenChainOriginId: _chain
        });

        _nonce++;
        bytes memory encodedTransfer = encodeTransfer(transfer);
        emit EmitBridgeProperty(
            _chain,
            chainId,
            _msgSender(),
            toAddress,
            amount
        );
        return
            _wormhole.publishMessage(_nonce, encodedTransfer, _amountOfBlocks);
    }

    function isTransferComplete(bytes32 hash) internal view returns (bool) {
        return _completedBridge[hash] == true;
    }

    function setTransferCompleted(bytes32 hash) internal {
        _completedBridge[hash] = true;
    }

    function parseAndVerifyVMPayload(Structs.VM memory vm)
        internal
        view
        returns (BridgeStructs.Transfer memory)
    {
        BridgeStructs.Transfer memory payloadTransfer = parseTransfer(
            vm.payload
        );

        address tokenAddressRemoteChain = address(
            uint160(uint256(payloadTransfer.tokenAddressOnRemoteChain))
        );

        require(
            payloadTransfer.payloadID == 1,
            "Version of payload should be 1"
        );

        require(
            payloadTransfer.tokenAddressOrigin == vm.emitterAddress,
            "Token address payload should be the same as emitter address"
        );

        require(
            tokenAddressRemoteChain == address(this),
            "Remote address should be the same as contract address"
        );
        require(
            payloadTransfer.tokenChainRemoteId == _chain,
            "Remote chain id in payload should be the same as the actual chain"
        );
        require(
            payloadTransfer.tokenChainOriginId == vm.emitterChainId,
            "The payload chain emitter should be the same as emitterChain"
        );

        return payloadTransfer;
    }

    function completeBridge(bytes memory data) external override whenNotPaused {
        (Structs.VM memory vm, bool valid, string memory reason) = _wormhole
            .parseAndVerifyVM(data);
        require(valid, reason);
        require(
            _applicationContracts[vm.emitterChainId] == vm.emitterAddress,
            "Invalid Emitter Address!"
        );

        BridgeStructs.Transfer memory transferFrom = parseAndVerifyVMPayload(
            vm
        );

        address addressRecipient = address(
            uint160(uint256(transferFrom.toAddressRecipient))
        );

        address addressSender = address(
            uint160(uint256(transferFrom.fromAddressSender))
        );

        require(!isTransferComplete(vm.hash), "Transfer already done!");

        setTransferCompleted(vm.hash);
        super._mint(addressRecipient, transferFrom.amount);
        emit AcceptBridgeProperty(
            transferFrom.tokenChainOriginId,
            _chain,
            addressRecipient,
            addressSender,
            transferFrom.amount
        );
    }

    function cancelBridge(bytes memory data)
        external
        override
        whenNotPaused
        returns (uint64)
    {
        (Structs.VM memory vm, bool valid, string memory reason) = _wormhole
            .parseAndVerifyVM(data);
        require(valid, reason);

        require(
            _applicationContracts[vm.emitterChainId] == vm.emitterAddress,
            "Invalid Emitter Address!"
        );

        BridgeStructs.Transfer memory transferFrom = parseAndVerifyVMPayload(
            vm
        );

        address addressRecipient = address(
            uint160(uint256(transferFrom.toAddressRecipient))
        );

        address addressSender = address(
            uint160(uint256(transferFrom.fromAddressSender))
        );

        require(
            addressSender == _msgSender(),
            "Only sender can cancel the bridge"
        );

        require(!isTransferComplete(vm.hash), "Transfer already done!");
        setTransferCompleted(vm.hash);

        BridgeStructs.Transfer memory transferCancel = BridgeStructs.Transfer({
            payloadID: 1,
            amount: transferFrom.amount,
            tokenAddressOnRemoteChain: transferFrom.tokenAddressOrigin,
            tokenAddressOrigin: transferFrom.tokenAddressOnRemoteChain,
            fromAddressSender: transferFrom.fromAddressSender,
            toAddressRecipient: transferFrom.fromAddressSender,
            tokenChainRemoteId: transferFrom.tokenChainOriginId,
            tokenChainOriginId: transferFrom.tokenChainRemoteId
        });

        _nonce++;
        bytes memory encodedTransfer = encodeTransfer(transferCancel);
        return
            _wormhole.publishMessage(_nonce, encodedTransfer, _amountOfBlocks);
    }

    function registerApplicationContracts(
        uint16 chainId,
        bytes32 applicationAddr
    ) external override whenNotPaused onlyRole(MASTER_ROLE) {
        _applicationContracts[chainId] = applicationAddr;
    }

    function parseTransfer(bytes memory encoded)
        internal
        pure
        returns (BridgeStructs.Transfer memory transfer)
    {
        uint256 index = 0;

        transfer.payloadID = encoded.toUint8(index);
        index += 1;

        require(transfer.payloadID == 1, "invalid Transfer");

        transfer.amount = encoded.toUint256(index);
        index += 32;

        transfer.tokenAddressOnRemoteChain = encoded.toBytes32(index);
        index += 32;

        transfer.tokenAddressOrigin = encoded.toBytes32(index);
        index += 32;

        transfer.fromAddressSender = encoded.toBytes32(index);
        index += 32;

        transfer.toAddressRecipient = encoded.toBytes32(index);
        index += 32;

        transfer.tokenChainRemoteId = encoded.toUint16(index);
        index += 2;

        transfer.tokenChainOriginId = encoded.toUint16(index);
        index += 2;

        require(encoded.length == index, "invalid Transfer");
    }

    function encodeTransfer(BridgeStructs.Transfer memory transfer)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                transfer.payloadID,
                transfer.amount,
                transfer.tokenAddressOnRemoteChain,
                transfer.tokenAddressOrigin,
                transfer.fromAddressSender,
                transfer.toAddressRecipient,
                transfer.tokenChainRemoteId,
                transfer.tokenChainOriginId
            );
    }

    //----------------------ENDS BRIDGE IMPLEMENTATION-----------------------------

    //----------------------BEGIN PAYMENT-UTILS/ERC20Snapshot IMPLEMENTATION------------------

    function addHolderAddress(address holderAddress) internal {
        _paymentAddresses.add(holderAddress);
    }

    function getLastSnapshot()
        external
        view
        onlyRole(MANAGER)
        returns (uint256)
    {
        return super._getCurrentSnapshotId();
    }

    function getAllHoldersAddresses()
        external
        view
        override
        returns (address[] memory)
    {
        return _paymentAddresses.values();
    }

    function getTotalAmountOfHouseTokens()
        external
        view
        override
        returns (uint256)
    {
        return _totalAmountOfHouseTokens;
    }

    function createPaymentSnapshot() external override onlyRole(MANAGER) {
        _lastPaymentSnapshot = super._snapshot();
    }

    function lastPaymentSnapshot() external view override returns (uint256) {
        return _lastPaymentSnapshot;
    }

    //-------------------------ENDS PAYMENT UTILS IMPLEMENTATION--------------------

    //-------------------------BEGINS MIGRABLE IMPLEMENTATION-----------------------

    function createMigrableSnapshot()
        external
        override
        whenPaused
        onlyRole(MASTER_ROLE)
    {
        _lastMigrableSnapshot = super._snapshot();
    }

    function lastMigrableSnapshot()
        external
        view
        override
        whenPaused
        returns (uint256)
    {
        return _lastMigrableSnapshot;
    }

    //-------------------------ENDS MIGRABLE IMPLEMENTATION------------------------
}
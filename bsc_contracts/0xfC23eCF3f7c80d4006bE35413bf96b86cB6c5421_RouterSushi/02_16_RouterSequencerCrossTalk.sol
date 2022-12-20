// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/iSequencerHandler.sol";
import "./interfaces/iErc20Handler.sol";
import "./interfaces/iRouterSequencerCrossTalk.sol";

/// @title RouterSequencerCrossTalk contract
/// @author Router Protocol
abstract contract RouterSequencerCrossTalk is
    Context,
    iRouterSequencerCrossTalk,
    ERC165
{
    using SafeERC20 for IERC20;
    iSequencerHandler public immutable sequencerHandler;
    IERCHandler public immutable erc20Handler;
    address public immutable reserveHandler;
    address private linkSetter;
    address private feeToken;

    mapping(uint8 => address) private Chain2Addr; // CHain ID to Address

    mapping(bytes32 => ExecutesStruct) private executes;

    modifier isHandler() {
        require(
            _msgSender() == address(sequencerHandler),
            "RouterCrossTalk : Only SequencerHandler can call this function"
        );
        _;
    }

    modifier isLinkUnSet(uint8 _chainID) {
        require(
            Chain2Addr[_chainID] == address(0),
            "RouterCrossTalk : Cross Chain Contract to Chain ID already set"
        );
        _;
    }

    modifier isLinkSet(uint8 _chainID) {
        require(
            Chain2Addr[_chainID] != address(0),
            "RouterCrossTalk : Cross Chain Contract to Chain ID is not set"
        );
        _;
    }

    modifier isLinkSync(uint8 _srcChainID, address _srcAddress) {
        require(
            Chain2Addr[_srcChainID] == _srcAddress,
            "RouterCrossTalk : Source Address Not linked"
        );
        _;
    }

    modifier isSelf() {
        require(
            _msgSender() == address(this),
            "RouterCrossTalk : Can only be called by Current Contract"
        );
        _;
    }

    constructor(
        address _sequencerHandler,
        address _erc20Handler,
        address _reserveHandler
    ) {
        sequencerHandler = iSequencerHandler(_sequencerHandler);
        erc20Handler = IERCHandler(_erc20Handler);
        reserveHandler = _reserveHandler;
    }

    /// @notice Used to set linker address, this function is internal and can only be set by contract owner or admins
    /// @param _addr Address of linker.
    function setLink(address _addr) internal {
        linkSetter = _addr;
    }

    /// @notice Used to set fee Token address.
    /// @dev This function is internal and can only be set by contract owner or admins.
    /// @param _addr Address of linker.
    function setFeeToken(address _addr) internal {
        feeToken = _addr;
    }

    function fetchLinkSetter() external view override returns (address) {
        return linkSetter;
    }

    function fetchLink(uint8 _chainID)
        external
        view
        override
        returns (address)
    {
        return Chain2Addr[_chainID];
    }

    function fetchFeeToken() external view override returns (address) {
        return feeToken;
    }

    function fetchExecutes(bytes32 hash)
        external
        view
        override
        returns (ExecutesStruct memory)
    {
        return executes[hash];
    }

    /// @notice routerSend This is internal function to generate a cross chain communication request.
    /// @param _params params struct.
    function routerSend(Params memory _params)
        internal
        isLinkSet(_params._destChainID)
        returns (bool, bytes32)
    {
        uint64 nonce;
        if (!_params._isOnlyGeneric) {
            _manageTransfers(_params);

            nonce = sequencerHandler.genericDepositWithERC(
                _params._destChainID,
                _params._erc20,
                _params._swapData,
                _params._generic,
                _params._gasLimit,
                _params._gasPrice,
                _params._feeToken,
                _params._isTransferFirst
            );
        } else {
            nonce = sequencerHandler.genericDeposit(
                _params._destChainID,
                _params._generic,
                _params._gasLimit,
                _params._gasPrice,
                _params._feeToken
            );
        }

        // _params._generic contains bytes4 _selector and bytes memory _data
        bytes4 _selector = abi.decode(_params._generic, (bytes4));
        bytes32 hash = _hash(_params._destChainID, nonce);

        executes[hash] = ExecutesStruct(_params._destChainID, nonce);

        emit CrossTalkSend(
            sequencerHandler.fetch_chainID(),
            _params,
            address(this),
            Chain2Addr[_params._destChainID],
            _selector,
            hash
        );

        return (true, hash);
    }

    function _manageTransfers(Params memory _params) internal {
        (uint8 destinationChainID, , , , , address feeTokenAddress) = abi
            .decode(
                _params._erc20,
                (uint8, bytes32, uint256[], address[], bytes[], address)
            );
        (, uint256 exchangeFee) = erc20Handler.getBridgeFee(
            destinationChainID,
            feeTokenAddress
        );

        IERC20(feeTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            exchangeFee
        );
        IERC20(feeTokenAddress).safeIncreaseAllowance(
            reserveHandler,
            exchangeFee
        );

        this.transferAmt(_params._swapData, msg.sender);
    }

    function transferAmt(bytes calldata data, address sender) external isSelf {
        (
            uint256 srcTokenAmount,
            ,
            ,
            ,
            ,
            uint256 lenRecipientAddress,
            uint256 lenSrcTokenAddress,

        ) = abi.decode(
                data,
                (
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256
                )
            );

        uint256 index = 288; // 32 * 6 -> 9
        index = index + lenRecipientAddress;
        bytes memory srcToken = bytes(data[index:index + lenSrcTokenAddress]);
        bytes20 srcTokenAdd;
        assembly {
            srcTokenAdd := mload(add(srcToken, 0x20))
        }
        address srcTokenAddress = address(srcTokenAdd);

        IERC20(srcTokenAddress).safeTransferFrom(
            sender,
            address(this),
            srcTokenAmount
        );
        IERC20(srcTokenAddress).safeIncreaseAllowance(
            reserveHandler,
            srcTokenAmount
        );
    }

    function routerSync(
        uint8 srcChainID,
        address srcAddress,
        bytes memory genericData,
        address settlementToken,
        uint256 returnAmount
    )
        external
        override
        isLinkSync(srcChainID, srcAddress)
        isHandler
        returns (bool, bytes memory)
    {
        uint8 cid = sequencerHandler.fetch_chainID();

        (bytes4 _selector, bytes memory _data) = abi.decode(
            genericData,
            (bytes4, bytes)
        );

        (bool success, bytes memory _returnData) = _routerSyncHandler(
            _selector,
            _data,
            settlementToken,
            returnAmount
        );
        emit CrossTalkReceive(srcChainID, cid, srcAddress);
        return (success, _returnData);
    }

    function routerReplay(
        bytes32 hash,
        uint256 _gasLimit,
        uint256 _gasPrice
    ) internal {
        sequencerHandler.replayDeposit(
            executes[hash].chainID,
            executes[hash].nonce,
            _gasLimit,
            _gasPrice
        );
    }

    /// @notice Function to generate the hash of all data sent or received by the contract.
    /// @dev This is an internal and pure function.
    /// @param _destChainId Destination ChainID.
    /// @param _nonce Nonce of the tx.
    function _hash(uint8 _destChainId, uint64 _nonce)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_destChainId, _nonce));
    }

    function Link(uint8 _chainID, address _linkedContract)
        external
        override
        isHandler
        isLinkUnSet(_chainID)
    {
        Chain2Addr[_chainID] = _linkedContract;
        emit Linkevent(_chainID, _linkedContract);
    }

    function Unlink(uint8 _chainID)
        external
        override
        isHandler
        isLinkSet(_chainID)
    {
        emit Unlinkevent(_chainID, Chain2Addr[_chainID]);
        Chain2Addr[_chainID] = address(0);
    }

    function approveFees(address _feeToken, uint256 _value) internal {
        approveTokens(address(sequencerHandler), _feeToken, _value);
    }

    function approveTokens(
        address _toBeApproved,
        address _token,
        uint256 _value
    ) internal {
        IERC20 token = IERC20(_token);
        token.safeApprove(_toBeApproved, _value);
    }

    /// @notice _routerSyncHandler This is internal function to control the handling of various selectors and its corresponding .
    /// @param _selector Selector to interface.
    /// @param _data Data to be handled.
    /// @param _settlementToken address of the settlement token.
    /// @param _returnAmount amount of settlement token paid to the recipient.
    function _routerSyncHandler(
        bytes4 _selector,
        bytes memory _data,
        address _settlementToken,
        uint256 _returnAmount
    ) internal virtual returns (bool, bytes memory);
}
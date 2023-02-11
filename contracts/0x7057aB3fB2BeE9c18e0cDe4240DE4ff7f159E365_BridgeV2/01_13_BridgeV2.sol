// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "../../utils/AdminableUpgradeable.sol";
import "../../utils/RevertMessageParser.sol";


contract BridgeV2 is Initializable, AdminableUpgradeable {
    /// ** PUBLIC states **

    address public newMPC;
    address public oldMPC;
    uint256 public newMPCEffectiveTime;

    mapping(address => bool) public isTransmitter;

    /// ** EVENTS **

    event LogChangeMPC(
        address indexed oldMPC,
        address indexed newMPC,
        uint256 indexed effectiveTime,
        uint256 chainId
    );
    event SetTransmitterStatus(address indexed transmitter, bool status);

    event OracleRequest(
        address bridge,
        bytes callData,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId
    );

    /// ** MODIFIERs **

    modifier onlyMPC() {
        require(msg.sender == mpc(), "BridgeV2: forbidden");
        _;
    }

    modifier onlyTransmitter() {
        require(isTransmitter[msg.sender], "BridgeV2: not a transmitter");
        _;
    }

    modifier onlyOwnerOrMPC() {
        require(
            mpc() == msg.sender || owner() == msg.sender,
            "BridgeV2: only owner or MPC can call"
        );
        _;
    }

    modifier onlySignedByMPC(bytes32 hash, bytes memory signature) {
        require(SignatureChecker.isValidSignatureNow(mpc(), hash, signature), "BridgeV2: invalid signature");
        _;
    }

    /// ** INITIALIZER **

    function initialize(address _mpc) public virtual initializer {
        __Ownable_init();

        newMPC = _mpc;
        newMPCEffectiveTime = block.timestamp;
    }

    /// ** VIEW functions **

    /**
     * @notice Returns MPC
     */
    function mpc() public view returns (address) {
        if (block.timestamp >= newMPCEffectiveTime) {
            return newMPC;
        }

        return oldMPC;
    }

    /**
     * @notice Returns chain ID of block
     */
    function currentChainId() public view returns (uint256) {
        return block.chainid;
    }

    /// ** MPC functions **

    /**
     * @notice Receives requests
     */
    function receiveRequestV2(bytes memory _callData, address _receiveSide)
    external
    onlyMPC
    {
        _processRequest(_callData, _receiveSide);
    }

    /**
     * @notice Receives requests
     */
    function receiveRequestV2Signed(bytes memory _callData, address _receiveSide, bytes memory signature)
    external
    onlySignedByMPC(keccak256(bytes.concat("receiveRequestV2", _callData, bytes20(_receiveSide),
        bytes32(block.chainid), bytes20(address(this)))), signature)
    {
        _processRequest(_callData, _receiveSide);
    }

    /// ** TRANSMITTER functions **

    /**
     * @notice transmits request
     */
    function transmitRequestV2(
        bytes memory _callData,
        address _receiveSide,
        address _oppositeBridge,
        uint256 _chainId
    ) public onlyTransmitter {
        emit OracleRequest(
            address(this),
            _callData,
            _receiveSide,
            _oppositeBridge,
            _chainId
        );
    }

    /// ** OWNER functions **

    /**
     * @notice Sets transmitter status
     */
    function setTransmitterStatus(address _transmitter, bool _status)
    external
    onlyOwner
    {
        isTransmitter[_transmitter] = _status;
        emit SetTransmitterStatus(_transmitter, _status);
    }

    /**
     * @notice Changes MPC by owner or MPC
     */
    function changeMPC(address _newMPC) external onlyOwnerOrMPC returns (bool) {
        return _changeMPC(_newMPC);
    }

    /**
     * @notice Changes MPC with signature
     */
    function changeMPCSigned(address _newMPC, bytes memory signature)
    external
    onlySignedByMPC(keccak256(bytes.concat("changeMPC", bytes20(_newMPC), bytes32(block.chainid),
        bytes20(address(this)))), signature)
    returns (bool)
    {
        return _changeMPC(_newMPC);
    }

    /**
     * @notice Withdraw fee by owner or admin
     */
    function withdrawFee(address token, address to, uint256 amount) external onlyOwnerOrAdmin returns (bool) {
        TransferHelper.safeTransfer(token, to, amount);
        return true;
    }

    /// ** Private functions **

    /**
     * @notice Private function that handles request processing
     */
    function _processRequest(bytes memory _callData, address _receiveSide)
    private
    {
        require(isTransmitter[_receiveSide], "BridgeV2: untrusted transmitter");

        (bool success, bytes memory data) = _receiveSide.call(_callData);

        if (!success) {
            revert(RevertMessageParser.getRevertMessage(data, "BridgeV2: call failed"));
        }
    }

    /**
     * @notice Private function that changes MPC
     */
    function _changeMPC(address _newMPC) private returns (bool) {
        require(_newMPC != address(0), "BridgeV2: address(0x0)");
        oldMPC = mpc();
        newMPC = _newMPC;
        newMPCEffectiveTime = block.timestamp;
        emit LogChangeMPC(
            oldMPC,
            newMPC,
            newMPCEffectiveTime,
            currentChainId()
        );
        return true;
    }
}
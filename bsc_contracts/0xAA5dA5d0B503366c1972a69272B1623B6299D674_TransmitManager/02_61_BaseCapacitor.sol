// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/ICapacitor.sol";
import "../utils/AccessControl.sol";
import "../libraries/RescueFundsLib.sol";

abstract contract BaseCapacitor is ICapacitor, AccessControl(msg.sender) {
    // keccak256("SOCKET_ROLE")
    bytes32 public constant SOCKET_ROLE =
        0x9626cdfde87fcc60a5069beda7850c84f848fb1b20dab826995baf7113491456;

    /// an incrementing id for each new packet created
    uint256 internal _packets;
    uint256 internal _sealedPackets;

    /// maps the packet id with the root hash generated while adding message
    mapping(uint256 => bytes32) internal _roots;

    error NoPendingPacket();

    event SocketSet(address socket);

    /**
     * @notice initialises the contract with socket address
     */
    constructor(address socket_) {
        _setSocket(socket_);
    }

    function setSocket(address socket_) external onlyOwner {
        _setSocket(socket_);
        emit SocketSet(socket_);
    }

    function _setSocket(address socket_) private {
        _grantRole(SOCKET_ROLE, socket_);
    }

    /// returns the latest packet details to be sealed
    /// @inheritdoc ICapacitor
    function getNextPacketToBeSealed()
        external
        view
        virtual
        override
        returns (bytes32, uint256)
    {
        uint256 toSeal = _sealedPackets;
        return (_roots[toSeal], toSeal);
    }

    /// returns the root of packet for given id
    /// @inheritdoc ICapacitor
    function getRootById(
        uint256 id_
    ) external view virtual override returns (bytes32) {
        return _roots[id_];
    }

    function getLatestPacketCount() external view returns (uint256) {
        return _packets == 0 ? 0 : _packets - 1;
    }

    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}
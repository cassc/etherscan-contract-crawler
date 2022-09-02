// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "hardhat/console.sol";

/// @custom:security-contact [email protected]
contract OMRedPackets is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    // importing libraries
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // define events and data structure
    event PacketWrapped(
        address indexed sender,
        uint256 packetId,
        uint256 amount,
        uint256 nReceivers,
        string message,
        uint256 timestamp
    );
    event PacketClaimed(
        address indexed claimer,
        uint256 indexed packetId,
        uint256 amount,
        uint256 timestamp
    );
    event FundsReclaimed(
        uint256 indexed packetId,
        uint256 timestamp,
        uint256 amount,
        address indexed sender
    );

    struct RedPacket {
        uint256 id;
        uint256 amountWrapped;
        uint256 amountLeft;
        uint256 receiversLeft;
        uint256 receiversTotal;
        uint256 timestamp;
        address sender;
        string message;
    }

    // define variables
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    mapping (uint256 => RedPacket) packets;
    mapping (bytes32 => uint8) claimHistory;

    CountersUpgradeable.Counter private _packetIds;
    CountersUpgradeable.Counter private _randomizerNonce;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, 0x9B82cffDc1B8a3c79de7Ea0f2dF7733F31A6A060);
        _grantRole(DEFAULT_ADMIN_ROLE, 0x13c48d3372e458A73E885f274CDf97593327741D);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    function version() pure external returns(uint){
        return 2; // version number for updating purpose
    }

    /**
     * !Note: Base Functionality
     */
    function wrapPacket(uint256 amount, uint256 nReceivers, string calldata message)
        external
        payable
    {
        require(nReceivers > 0, "Need to at least have 1 receiver!");
        require(nReceivers < 1001, "Maximum 1000 receivers allowed!");
        require(amount >= 0.01 ether, "Need to wrap at least 0.01 Ether!");
        require(msg.value == amount, "Value sent must be as specified!");
        require(_strlen(message) <= 140, "Message is too long");

        uint256 packetId = _packetIds.current();
        RedPacket memory p = RedPacket(
            packetId,
            amount,
            amount,
            nReceivers,
            nReceivers,
            block.timestamp,
            msg.sender,
            message
        );
        packets[packetId] = p;

        // mint token and increment id
        _packetIds.increment(); // packet id would start from 0
        
        emit PacketWrapped(
            msg.sender,
            packetId,
            amount,
            nReceivers,
            message,
            block.timestamp
        );
    }
    
    function claimPacket(uint256 packetId, bytes memory signature)
        external
        payable
    {
        // revert if the packet does not exist
        uint256 numberOfPackets = _packetIds.current();
        require(packetId < numberOfPackets, "Packet does not exist!");

        // check if there are any more slots/funds to claim
        RedPacket storage p = packets[packetId];
        require(p.receiversLeft > 0, "No more slots left!");
        require(p.amountLeft > 0, "Packet has no more fund!");

        // check validity of signature: make sure the claimer can claim the packet specified
        require(_verifyClaimSignature(msg.sender, p.id, signature), "Incorrect signature provided!");
        
        // revert if the user has claimed once already
        bytes32 claimHash = keccak256(abi.encodePacked(msg.sender, packetId));
        require(claimHistory[claimHash] != 1, "Cannot claim the same packet twice!"); 

        // split the pot into pieces
        uint256 amountToTransfer = 0;
        if (p.receiversLeft == 1) {
            amountToTransfer = p.amountLeft;
        } else {
            amountToTransfer = p.amountLeft * _random() * 2 / (10000000 * p.receiversLeft);
        }

        // mutate state first and then pay
        p.amountLeft -= amountToTransfer;
        p.receiversLeft -= 1;
        claimHistory[claimHash] = 1;
        address payable receiver = payable(msg.sender);
        receiver.transfer(amountToTransfer);
        
        emit PacketClaimed(msg.sender, packetId, amountToTransfer, block.timestamp);
    }

    function viewPacket(uint256 packetId) external view returns (
            address sender,
            uint256 amountWrapped,
            uint256 amountLeft,
            uint256 receiversTotal,
            uint256 receiversLeft,
            uint256 timeWrapped,
            string memory message
        )
    {
        uint256 numberOfPackets = _packetIds.current();
        require(packetId < numberOfPackets, "Packet does not exist!");

        RedPacket storage p = packets[packetId];
        return(
            p.sender,
            p.amountWrapped,
            p.amountLeft,
            p.receiversTotal,
            p.receiversLeft,
            p.timestamp,
            p.message
        );
    }

    function retrieveFund(uint256 packetId) external payable {
        uint256 numberOfPackets = _packetIds.current();
        require(packetId < numberOfPackets, "Packet does not exist!");

        // revert if there are already too many claimers
        RedPacket storage p = packets[packetId];
        require(msg.sender == p.sender, "Only origianl red packet owner can retrieve funds");
        require(p.amountLeft > 0, "Packet is already empty!");

        uint amountToRetrieve = p.amountLeft;
        p.amountLeft = 0;
        address payable receiver = payable(msg.sender);
        receiver.transfer(amountToRetrieve);

        emit FundsReclaimed(packetId, block.timestamp, amountToRetrieve, p.sender);
    }

    /**
     * !Note: claim verification
     */
    function _verifyClaimSignature(address claimer, uint256 packetId, bytes memory sig) internal pure returns (bool) {
        bytes32 msgHash = keccak256(abi.encodePacked(claimer, packetId));
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(sig); 
        return ecrecover(signedHash, v, r, s) == address(0xA6724E3aB587C8915EE357E7e105bC66f7fd86ac);
    }

    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /**
     * !Note: helper functions
     */
    function _random() internal returns (uint) {
        uint256 nonce = _randomizerNonce.current();
        uint256 rand = 1 + uint(keccak256(abi.encodePacked(
            block.difficulty,
            block.timestamp,
            msg.sender,
            nonce
        ))) % 10000001; // 0 to 10000000
        _randomizerNonce.increment();
        return rand;
    }

    function _strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}
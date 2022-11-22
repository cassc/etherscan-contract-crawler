// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import '../utils/Ownable.sol';

/// @title TicketManager - manage ticket and verify ticket signature
/// @author Omnuum Dev Team - <[email protected]>
contract TicketManager is EIP712 {
    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

    struct Ticket {
        address user; // owner of this ticket
        address nft; // ticket nft contract
        uint256 price; // price of mint with this ticket
        uint32 quantity; // possible mint quantity
        uint256 groupId; // ticket's group id
        bytes signature; // ticket's signature
    }

    /// @dev nft => groupId => end date
    mapping(address => mapping(uint256 => uint256)) public endDates;

    /// @dev nft => groupId => ticket owner => use count
    mapping(address => mapping(uint256 => mapping(address => uint32))) public ticketUsed;

    string private constant SIGNING_DOMAIN = 'OmnuumTicket';
    string private constant SIGNATURE_VERSION = '1';

    event SetTicketSchedule(address indexed nftContract, uint256 indexed groupId, uint256 endDate);

    event TicketMint(
        address indexed nftContract,
        address indexed minter,
        uint256 indexed groupId,
        uint32 quantity,
        uint32 maxQuantity,
        uint256 price
    );

    /// @notice set end date for ticket group
    /// @param _nft nft contract
    /// @param _groupId id of ticket group
    /// @param _endDate end date timestamp
    function setEndDate(
        address _nft,
        uint256 _groupId,
        uint256 _endDate
    ) external {
        /// @custom:error (OO1) - Ownable: Caller is not the collection owner
        require(Ownable(_nft).owner() == msg.sender, 'OO1');
        endDates[_nft][_groupId] = _endDate;

        emit SetTicketSchedule(_nft, _groupId, _endDate);
    }

    /// @notice use ticket for minting
    /// @param _signer address who is believed to be signer of ticket
    /// @param _minter address who is believed to be owner of ticket
    /// @param _quantity quantity of which minter is willing to mint
    /// @param _ticket ticket
    function useTicket(
        address _signer,
        address _minter,
        uint32 _quantity,
        Ticket calldata _ticket
    ) external {
        verify(_signer, msg.sender, _minter, _quantity, _ticket);

        ticketUsed[msg.sender][_ticket.groupId][_minter] += _quantity;
        emit TicketMint(msg.sender, _minter, _ticket.groupId, _quantity, _ticket.quantity, _ticket.price);
    }

    /// @notice verify ticket
    /// @param _signer address who is believed to be signer of ticket
    /// @param _nft nft contract address
    /// @param _minter address who is believed to be owner of ticket
    /// @param _quantity quantity of which minter is willing to mint
    /// @param _ticket ticket
    function verify(
        address _signer,
        address _nft,
        address _minter,
        uint32 _quantity,
        Ticket calldata _ticket
    ) public view {
        /// @custom:error (MT8) - Minting period is ended
        require(block.timestamp <= endDates[_nft][_ticket.groupId], 'MT8');

        /// @custom:error (VR1) - False Signer
        require(_signer == recoverSigner(_ticket), 'VR1');

        /// @custom:error (VR5) - False NFT
        require(_ticket.nft == _nft, 'VR5');

        /// @custom:error (VR6) - False Minter
        require(_minter == _ticket.user, 'VR6');

        /// @custom:error (MT3) - Remaining token count is not enough
        require(ticketUsed[_nft][_ticket.groupId][_minter] + _quantity <= _ticket.quantity, 'MT3');
    }

    /// @dev recover signer from payload hash
    /// @param _ticket payload struct
    function recoverSigner(Ticket calldata _ticket) internal view returns (address) {
        bytes32 digest = _hash(_ticket);
        return ECDSA.recover(digest, _ticket.signature);
    }

    /// @dev hash payload
    /// @param _ticket payload struct
    function _hash(Ticket calldata _ticket) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256('Ticket(address user,address nft,uint256 price,uint32 quantity,uint256 groupId)'),
                        _ticket.user,
                        _ticket.nft,
                        _ticket.price,
                        _ticket.quantity,
                        _ticket.groupId
                    )
                )
            );
    }
}
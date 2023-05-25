/**
 *Submitted for verification at Etherscan.io on 2020-08-28
*/

pragma solidity ^0.6.11;

//certo c063v200826 noima (c) all rights reserved 2020

/// @title  A CertoProof Of  existence smartcontract
/// @author Mauro G. Cordioli ezlab
/// @notice Check the details at https://certo.legal/smartcontract/v63
contract ProofCertoChainContract {
    int256 public constant Version = 0x6320082601;
    address payable creator;
    address payable owner;
    mapping(bytes32 => uint256) private CertoLedgerTimestamp;
    string public Description; //Contract Purpose

    modifier onlyBy(address _account) {
        require(msg.sender == _account, "not allowed");
        _;
    }

    function setCreator(address payable _creator) public onlyBy(creator) {
        creator = _creator;
        emit EventSetCreator();
    }

    function setOwner(address payable _owner) public onlyBy(creator) {
        owner = _owner;
        emit EventSetOwner();
    }

    function setDescription(string memory _Description) public onlyBy(owner) {
        Description = _Description;
    }

    constructor(string memory _Description) public {
        creator = msg.sender;
        owner = msg.sender;

        Description = _Description;

        emit EventReady();
    }

    /// @notice Notarize the hash emit block timestamp of the  block
    /// @param hashproof The proof sha256 hash to timestamp
    function NotarizeProofTimeStamp(bytes32 hashproof) public onlyBy(owner) {
        uint256 ts = CertoLedgerTimestamp[hashproof];
        if (ts == 0) {
            ts = block.timestamp;
            CertoLedgerTimestamp[hashproof] = ts;
        }

        emit EventProof(hashproof, ts);
    }


    /// @notice Notarize both hashes  emit  block timestamp  with logged note
    /// @param hashproof The proof  sha256 hash to timestamp
    /// @param hashmeta  The metadata sha256 hash to timestamp
    /// @param note  The note to be logged on the blokchain
    function NotarizeProofMetaNoteTimeStamp(
        bytes32 hashproof,
        bytes32 hashmeta,
        string memory note
    ) public onlyBy(owner) {
        uint256 tsproof = CertoLedgerTimestamp[hashproof];
        if (tsproof == 0) {
            tsproof = block.timestamp;
            CertoLedgerTimestamp[hashproof] = tsproof;
        }

        uint256 tsmeta = CertoLedgerTimestamp[hashmeta];
        if (tsmeta == 0) {
            tsmeta=block.timestamp;
            CertoLedgerTimestamp[hashmeta] = tsmeta;
        }

        emit EventProofMetaWithNote(hashproof, hashmeta, tsproof, tsmeta, note);
    }

    /// @notice Notarize both hashes and emit  block timestamps   
    /// @param hashproof The proof sha256 hash to timestamp
    /// @param hashmeta The metadata sha256 hash to timestamp
    function NotarizeProofMetaTimeStamp(bytes32 hashproof, bytes32 hashmeta)
        public
        onlyBy(owner)
    {
        uint256 tsproof = CertoLedgerTimestamp[hashproof];
        if (tsproof == 0) {
            tsproof = block.timestamp;
            CertoLedgerTimestamp[hashproof] = tsproof;
        }

        uint256 tsmeta = CertoLedgerTimestamp[hashmeta];
        if (tsmeta == 0) {
            tsmeta = block.timestamp;
            CertoLedgerTimestamp[hashmeta] = tsmeta;
        }

        emit EventProofMeta(hashproof, hashmeta, tsproof, tsmeta);
    }

    /// @notice Notarize the hash emit   block timestamp  with  logged note
    /// @param hashproof The sha256 hash to timestamp
    /// @param note  The note to be logged on the blokchain
    function NotarizeProofTimeStampWithNote(
        bytes32 hashproof,
        string memory note
    ) public onlyBy(owner) {
        uint256 ts = CertoLedgerTimestamp[hashproof];
        if (ts == 0) {
            ts = block.timestamp;
            CertoLedgerTimestamp[hashproof] = ts;
        }
        emit EventProofWithNote(hashproof, ts, note);
    }

    /// @notice check the hash  to verify the proof  emit  the block timestamp if ok  or zero if not.
    /// @param hashproof The sha256 hash be checked
    /// @return block timestamp if ok zero if not
    function CheckProofTimeStampByHashReturnsNonZeroUnixEpochIFOk(
        bytes32 hashproof
    ) public view returns (uint256) {
        return CertoLedgerTimestamp[hashproof];
    }

    event EventProofMetaWithNote(
        bytes32 hashproof,
        bytes32 hashmeta,
        uint256 tsproof,
        uint256 tsmeta,
        string note
    ); // trace a note in the logs
    event EventProofMeta(
        bytes32 hashproof,
        bytes32 hashmeta,
        uint256 tsproof,
        uint256 tsmeta
    );
    event EventProofWithNote(bytes32 hashproof, uint256 ts, string note); // trace a note in the logs
    event EventProof(bytes32 hashproof, uint256 ts);
    event EventSetOwner(); //invoked when creator changes owner
    event EventSetCreator(); //invoked when creator changes creator
    event EventReady(); //invoked when we have done the method action
}
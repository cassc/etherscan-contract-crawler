// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

library Types {
    /**
     * @Notice List of ALL Struct being used to Encode and Decode RLP Messages
     */

    //  SPR = State Hash + Pathch Receipt Hash + Receipt Hash
    struct SPR {
        bytes stateHash;
        bytes patchReceiptHash;
        bytes receiptHash;
    }

    struct BlockHeader {
        uint256 version;
        uint256 height;
        uint256 timestamp;
        bytes proposer;
        bytes prevHash;
        bytes voteHash;
        bytes nextValidators;
        bytes patchTxHash;
        bytes txHash;
        bytes logsBloom;
        SPR spr;
        bool isSPREmpty; //  add to check whether SPR is an empty struct
        //  It will not be included in serializing thereafter
    }

    //  TS = Timestamp + Signature
    struct TS {
        uint256 timestamp;
        bytes signature;
    }

    //  BPSI = blockPartSetID
    struct BPSI {
        uint256 n;
        bytes b;
    }

    struct Votes {
        uint256 round;
        BPSI blockPartSetID;
        TS[] ts;
    }

    struct BlockWitness {
        uint256 height;
        bytes[] witnesses;
    }

    struct EventProof {
        uint256 index;
        bytes[] eventMptNode;
    }

    struct BlockUpdate {
        BlockHeader bh;
        Votes votes;
        bytes[] validators;
    }

    struct ReceiptProof {
        uint256 index;
        bytes[] txReceipts;
        EventProof[] ep;
    }

    struct BlockProof {
        BlockHeader bh;
        BlockWitness bw;
    }

    struct RelayMessage {
        BlockUpdate[] buArray;
        BlockProof bp;
        bool isBPEmpty; //  add to check in a case BlockProof is an empty struct
        //  when RLP RelayMessage, this field will not be serialized
        ReceiptProof[] rp;
        bool isRPEmpty; //  add to check in a case ReceiptProof is an empty struct
        //  when RLP RelayMessage, this field will not be serialized
    }

    /**
     * @Notice List of ALL Structs being used by a BSH contract
     */
    enum ServiceType {
        REQUEST_COIN_TRANSFER,
        REQUEST_COIN_REGISTER,
        REPONSE_HANDLE_SERVICE,
        BLACKLIST_MESSAGE,
        CHANGE_TOKEN_LIMIT,
        UNKNOWN_TYPE
    }

    enum BlacklistService {
        ADD_TO_BLACKLIST,
        REMOVE_FROM_BLACKLIST
    }

    struct PendingTransferCoin {
        string from;
        string to;
        string[] coinNames;
        uint256[] amounts;
        uint256[] fees;
    }

    struct TransferCoin {
        string from;
        string to;
        Asset[] assets;
    }

    struct BlacklistMessage {
        BlacklistService serviceType;
        string[] addrs;
        string net;
    }

    struct TokenLimitMessage {
        string[] coinName;
        uint256[] tokenLimit;
        string net;
    }

    struct Asset {
        string coinName;
        uint256 value;
    }

    struct AssetTransferDetail {
        string coinName;
        uint256 value;
        uint256 fee;
    }

    struct Response {
        uint256 code;
        string message;
    }

    struct ServiceMessage {
        ServiceType serviceType;
        bytes data;
    }

    struct Coin {
        uint256 id;
        string symbol;
        uint256 decimals;
    }

    struct Balance {
        uint256 lockedBalance;
        uint256 refundableBalance;
    }

    struct Request {
        string serviceName;
        address bsh;
    }

    /**
     * @Notice List of ALL Structs being used by a BMC contract
     */

    struct VerifierStats {
        uint256 heightMTA; // MTA = Merkle Trie Accumulator
        uint256 offsetMTA;
        uint256 lastHeight; // Block height of last verified message which is BTP-Message contained
        bytes extra;
    }

    struct Service {
        string svc;
        address addr;
    }

    struct Verifier {
        string net;
        address addr;
    }

    struct Route {
        string dst; //  BTP Address of destination BMC
        string next; //  BTP Address of a BMC before reaching dst BMC
    }

    struct Link {
        address[] relays; //  Address of multiple Relays handle for this link network
        uint256 rxSeq;
        uint256 txSeq;
        uint256 blockIntervalSrc;
        uint256 blockIntervalDst;
        uint256 maxAggregation;
        uint256 delayLimit;
        uint256 relayIdx;
        uint256 rotateHeight;
        uint256 rxHeight;
        uint256 rxHeightSrc;
        bool isConnected;
    }

    struct LinkStats {
        uint256 rxSeq;
        uint256 txSeq;
        VerifierStats verifier;
        RelayStats[] relays;
        uint256 relayIdx;
        uint256 rotateHeight;
        uint256 rotateTerm;
        uint256 delayLimit;
        uint256 maxAggregation;
        uint256 rxHeightSrc;
        uint256 rxHeight;
        uint256 blockIntervalSrc;
        uint256 blockIntervalDst;
        uint256 currentHeight;
    }

    struct RelayStats {
        address addr;
        uint256 blockCount;
        uint256 msgCount;
    }

    struct BMCMessage {
        string src; //  an address of BMC (i.e. btp://1234.PARA/0x1234)
        string dst; //  an address of destination BMC
        string svc; //  service name of BSH
        int256 sn; //  sequence number of BMC
        bytes message; //  serializef Service Message from BSH
    }

    struct Connection {
        string from;
        string to;
    }

    struct EventMessage {
        string eventType;
        Connection conn;
    }

    struct BMCService {
        string serviceType;
        bytes payload;
    }

    struct GatherFeeMessage {
        string fa; //  BTP address of Fee Aggregator
        string[] svcs; //  a list of services
    }
}
pragma solidity ^0.8.15;

import "./ERC721G.sol";
import './BasicType.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BigBroOracle is 
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    BBTy
{
    using ECDSA for bytes32;

    mapping(address => bool) private coopContracts;
    uint256 private PRICE_REPORT_BLACK;
    uint256 private PRICE_GURAD;
    uint256 private totalReqNum;
    uint256 private constant DURATION = 10 minutes;

    mapping(address => bool) private _blackList;
    mapping(address => mapping(address => bool)) private _guardServiceRecord;

    event ReportRisk(
        address indexed nftContract,
        address indexed doubt,
        uint256 indexed tokenId,
        string          message
    );
    event GuardRequest(
        address indexed nftContract,
        address indexed owner,
        uint256[]       tokenIds,
        TOKENOP op
    );
    event RiskRequest(
        uint256 indexed Id,
        address indexed nftContract,
        address indexed from,
        address         to,
        uint256         startTokenId,
        uint256         quantity
    );
    event QueryResult(
        address indexed nftContract,
        address indexed maybeRisk,
        uint256 indexed tokenId, 
        REPLYACT        res,
        string          message
    );
    event BigBroSetApprovalGuard(
        address indexed nftContract,
        address indexed addr
    );

    function initialize() initializer public {
        totalReqNum = 0;
        PRICE_REPORT_BLACK = 1 ether;
        PRICE_GURAD = 0 ether;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setReportGas(uint256 price) external onlyOwner() {
        PRICE_REPORT_BLACK = price;
    }

    function setGuardGas(uint256 price) external onlyOwner() {
        PRICE_GURAD = price;
    }

    modifier coopContract(address addr) {
        require(coopContracts[addr], "ERROR: NOT_PARTNER");
        _;
    }

    function setCoopContract(address _addr, bool add) external onlyOwner {
        coopContracts[_addr] = add;
    }

    function _getMessageHash(uint256 timestamp, uint256 op) private view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, timestamp, op));
    }

    function getMsgSenderHash(uint256 op) external view returns (bytes32 hashMsg, uint256 timestamp) {
        timestamp = block.timestamp;
        hashMsg = _getMessageHash(timestamp, op);
    }

    // TODO: be private while deployed
    function _verify(uint256 timestamp, bytes calldata signature, uint256 op) private view returns (address) {
        return _getMessageHash(timestamp, op)
            .toEthSignedMessageHash()
            .recover(signature);
    }

    function _tokenOp(
        ERC721G   erc721,
        uint256[] calldata tokenIds,
        TOKENOP   op
    ) private {
        REPLYACT actOp;
        if (op == TOKENOP.UNLOCK) {
            actOp = REPLYACT.UNLOCK;
        } else if (op == TOKENOP.UNGUARD) {
            actOp = REPLYACT.UNGUARD;
        } else if (op == TOKENOP.LOCK) {
            actOp = REPLYACT.LOCK;
        } else if (op == TOKENOP.GUARD) {
            actOp = REPLYACT.GUARD;
        } else {
            revert("IMPOSSIBLE OPERATION");
        }

        for (uint i; i < tokenIds.length; ++i) {
            require(erc721.ownerOf(tokenIds[i]) == msg.sender, "NOT_OWNER_OF_TOKEN");
        }

        erc721.queryResponseDispatch(actOp, address(0), tokenIds);
        emit GuardRequest(address(erc721), msg.sender, tokenIds, op);
    }

    function tokenOpWithSign(
        ERC721G   erc721,
        uint256[] calldata tokenIds,
        TOKENOP   op,
        uint256   timestamp,
        bytes     calldata signature
    ) external payable coopContract(address(erc721)) {
        require(tokenIds.length > 0, "ERROR: EMPTY TOKEN LIST");
        require(timestamp + DURATION > block.timestamp, "EXPIRED TIMESTAMP");
        require(_verify(timestamp, signature, uint256(op)) == owner(), "ILLEGAL SIGNATURE");
        if (op != TOKENOP.UNLOCK && op != TOKENOP.UNGUARD) {
            revert("ERROR: ILLEGAL REQUEST");
        }
        _tokenOp(erc721, tokenIds, op);
    }

    function tokenOp(
        ERC721G   erc721,
        uint256[] calldata tokenIds,
        TOKENOP   op
    ) external payable coopContract(address(erc721)) {
        require(tokenIds.length > 0, "ERROR: EMPTY TOKEN LIST");
        if (op != TOKENOP.LOCK && op != TOKENOP.GUARD) {
            revert("ERROR: ILLEGAL REQUEST");
        }
        if (op == TOKENOP.GUARD) {
            require(msg.value >= tokenIds.length * PRICE_GURAD, "NOT ENOUGH SERVICE FEE");
        }
        _tokenOp(erc721, tokenIds, op);
    }

    function payBigBroSetApprovalGuard(ERC721G erc721) external payable coopContract(address(erc721)) {
        require(erc721.balanceOf(tx.origin) > 0, "NOT OWNER OF ERC721G NFT");
        require(msg.value >= PRICE_GURAD, "NOT ENOUGH SERVICE FEE");
        _guardServiceRecord[address(erc721)][tx.origin] = true;
        emit BigBroSetApprovalGuard(address(erc721), tx.origin);
    }

    function bigBroGuardState(address erc721) public view coopContract(erc721) returns(bool) {
        return _guardServiceRecord[erc721][tx.origin];
    }

    function queryBlackList(
        address _operator
    ) external view coopContract(msg.sender) returns(SAFEIDX) {
        if (_guardServiceRecord[msg.sender][tx.origin]) {
            return _blackList[_operator] ? SAFEIDX.UNSAFE : SAFEIDX.SAFE;
        } else {
            return SAFEIDX.NONE;
        }
    }

    function updateBlackList(address[] calldata addrs, bool op) external onlyOwner {
        unchecked {
            uint256 length = addrs.length;
            for(uint i; i < length; ++i) {
                _blackList[addrs[i]] = op;
            }
        }
    }

    function reportRisk(
        address _contract,
        address _addr,
        uint256 tokenId,
        string  calldata msgData
    ) external payable coopContract(_contract) {
        require(msg.value >= PRICE_REPORT_BLACK, "ERROR: NOT_ENOUGH_SERVICE_FEE");
        emit ReportRisk(_contract, _addr, tokenId, msgData);
    }

    function riskRequest (
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _quantity
    ) external coopContract(msg.sender) {
        emit RiskRequest(
            totalReqNum++,
            msg.sender,
            _from,
            _to,
            _tokenId,
            _quantity
        );
    }

    function trustedSetApprovalForAll(
        ERC721G erc721,
        address operator,
        uint256 op,
        uint256 timestamp,
        bytes   calldata signature
    ) external coopContract(address(erc721)) {
        require(op == 3777, "ILLEGAL OPCODE");
        require(timestamp + DURATION > block.timestamp, "EXPIRED TIMESTAMP");
        require(_verify(timestamp, signature, 3777) == owner(), "ILLEGAL SIGNATURE");
        erc721.bigbroApprovalForAll(msg.sender, operator);
    }

    /**
     * Receive the response in the form of string
     */
    function fulfill(
        ERC721G  erc721,
        address  _addr,
        uint256  _tokenId,
        REPLYACT _res,       
        string   calldata _message
    ) public coopContract(address(erc721)) onlyOwner {
        emit QueryResult(address(erc721), _addr, _tokenId, _res, _message);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        erc721.queryResponseDispatch(_res, _addr, tokenIds);
    }

    /**
     * Withdraw Ether
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }
}
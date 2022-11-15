// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IActivityERC721.sol";
import "./ActivityERC721.sol";

contract ActivityFactory is Ownable, EIP712 {
    bytes32 public constant ACTIVITY_CLAIM_TYPEHASH =
        keccak256("ClaimInfo(bytes32 activitySN,address user,uint256 chainId)");
    mapping(bytes32 => Activity) public activites;
    mapping(address => bool) public signers;
    mapping(bytes32 => mapping(address => bool)) public claimedUsers;
    address[] public allActivites;

    enum ActivityType {
        BASE_TYPE,
        TYPE_ERC20,
        TYPE_ERC721,
        TYPE_ERC1155
    }

    struct Activity {
        address activityNft;
        address creater;
        ActivityType activityType;
        bool status;
        uint256 maximum;
        uint256 claimed;
    }

    event ActivityClaimed(
        address indexed user,
        address indexed activityNft,
        bytes32 activitySN,
        uint256 tokenId
    );

    event ActivityCreated(
        address indexed creater,
        address indexed activityNft,
        ActivityType activityType,
        uint256 counts
    );

    modifier verifySigCreateSig(bytes32 _activitySN, bytes memory signature) {
        bytes32 message = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(_activitySN, address(this)))
        );
        address signer = ECDSA.recover(message, signature);

        require(signers[signer], "signature verification failed");
        _;
    }

    modifier verifyClaimSig(bytes32 _activitySN, bytes memory signature) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ACTIVITY_CLAIM_TYPEHASH,
                    _activitySN,
                    msg.sender,
                    block.chainid
                )
            )
        );

        address signer = ECDSA.recover(digest, signature);
        require(signers[signer], "signature verification failed");
        _;
    }

    modifier claimedCheck(bytes32 _activitySN) {
        require(!claimedUsers[_activitySN][msg.sender], "user has claimed");
        _;
    }

    constructor(address[] memory _signers)
        EIP712("Openmeta Airdrop Activity", "1.0.0")
    {
        for (uint8 i = 0; i < _signers.length; i++) {
            signers[_signers[i]] = true;
        }
    }

    function createActivity(
        bytes32 _activitySN,
        ActivityType _activityType,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _maximum,
        bytes memory _signature
    )
        external
        verifySigCreateSig(_activitySN, _signature)
        returns (address activityAddr)
    {
        Activity storage activity = activites[_activitySN];
        require(activity.activityNft == address(0), "activity exists");

        bytes memory bytecode = type(ActivityERC721).creationCode;

        activityAddr = Create2.deploy(0, _activitySN, bytecode);
        IActivityERC721(activityAddr).initialize(_name, _symbol, _uri);

        activity.activityNft = activityAddr;
        activity.creater = msg.sender;
        activity.activityType = _activityType;
        activity.status = true;
        activity.maximum = _maximum;

        allActivites.push(activityAddr);

        emit ActivityCreated(
            msg.sender,
            activityAddr,
            _activityType,
            allActivites.length
        );
    }

    function claim(bytes32 _activitySN, bytes memory _signature)
        external
        claimedCheck(_activitySN)
        verifyClaimSig(_activitySN, _signature)
    {
        Activity storage activity = activites[_activitySN];
        require(activity.status, "activity exists");

        if (activity.maximum > 0) {
            require(
                activity.maximum > activity.claimed,
                "maximum limit reached"
            );
        }

        activity.claimed = activity.claimed + 1;
        claimedUsers[_activitySN][msg.sender] = true;
        uint256 tokenId = IActivityERC721(activity.activityNft).safeMint(
            msg.sender
        );

        emit ActivityClaimed(
            msg.sender,
            activity.activityNft,
            _activitySN,
            tokenId
        );
    }

    function batchSetSigners(address[] memory _signers, bool _status)
        external
        onlyOwner
    {
        require(_signers.length > 0, "empty data");

        for (uint8 i = 0; i < _signers.length; i++) {
            signers[_signers[i]] = _status;
        }
    }

    function allActivityLength() external view returns (uint256) {
        return allActivites.length;
    }
}
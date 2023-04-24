pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./library/ECDSA.sol";
import "./library/EIP712.sol";
import "./interface/ICobee.sol";

/**
 * @title FreeMint NFT
 * @author Combo Protocol
 */
contract FreeMint is EIP712, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    bool private initialized;

    address public signer;
    mapping(uint256 => bool) public isClaimed;
    mapping(address => bool) public userClaimed;
    uint256 public numClaimed;

    uint256 public startTime;
    uint256 public endTime;

    event eveUpdateSigner(address signer);
    event eveUpdateTime(uint256 startTime, uint256 endTime);

    event EventClaim(
        uint256 nftID,
        uint256 _dummyId,
        address _nft,
        address _mintTo
    );

    constructor(
        address _signer,
        uint256 _startTime,
        uint256 _endTime
    ) EIP712("Combo", "1.0.0") {
        signer = _signer;
        startTime = _startTime;
        endTime = _endTime;
    }

    function initialize(
        address _owner,
        address _signer,
        uint256 _startTime,
        uint256 _endTime
    ) external {
        require(!initialized, "initialize: Already initialized!");
        _transferOwnership(_owner);
        eip712Initialize("Combo", "1.0.0");
        signer = _signer;
        startTime = _startTime;
        endTime = _endTime;
        initialized = true;
    }

    function updateTime(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
        emit eveUpdateTime(_startTime, _endTime);
    }

    function claimHash(
        address _nft,
        uint256 _dummyId,
        address _to
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Claim(address claimNFT,uint256 dummyId,address mintTo)"
                        ),
                        _nft,
                        _dummyId,
                        _to
                    )
                )
            );
    }

    function verifySignature(
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool) {
        return ECDSA.recover(hash, signature) == signer;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
        emit eveUpdateSigner(_signer);
    }

    function claim(
        address _nft,
        uint256 _dummyId,
        address _mintTo,
        bytes calldata _signature
    ) external nonReentrant returns (uint256) {
        require(block.timestamp >= startTime, "not start!");
        require(block.timestamp < endTime, "end!");
        require(_mintTo == msg.sender, "_mintTo is not equal sender");
        require(!userClaimed[_mintTo], "Already Claimed!");
        require(!isClaimed[_dummyId], "Already Claimed!");

        require(
            verifySignature(claimHash(_nft, _dummyId, _mintTo), _signature),
            "Invalid signature"
        );
        isClaimed[_dummyId] = true;
        userClaimed[_mintTo] = true;
        uint256 nftID_ = ICobee(_nft).mint(_mintTo);

        numClaimed++;

        emit EventClaim(nftID_, _dummyId, _nft, _mintTo);

        return nftID_;
    }

    // for view
    function userCanClaim(
        address _nft,
        uint256 _dummyId,
        address _mintTo,
        bytes calldata _signature
    ) external view returns (bool) {
        if (userClaimed[_mintTo]) {
            return false;
        }

        bool signature = verifySignature(
            claimHash(_nft, _dummyId, _mintTo),
            _signature
        );

        if (signature && isClaimed[_dummyId] == false) {
            return true;
        }

        return false;
    }
}
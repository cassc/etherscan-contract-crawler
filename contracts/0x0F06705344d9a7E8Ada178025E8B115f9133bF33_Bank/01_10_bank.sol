// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {SignatureChecker} from "./libs/SignatureChecker.sol";

contract Bank is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Pool {
        uint256 id;
        bool activated;
        uint256 totalAmnt;
        uint256 claimedAmnt;
        uint256 activatedTimestamp;
    }

    bytes32 public immutable DOMAIN_SEPARATOR;
    uint256 public indiciaFraction = 2000;
    uint256 public communityFraction = 8000;
    address private _indiciaRecipient;
    address public admin;
    IERC721A public indicia;
    Counters.Counter private _epochId;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => uint256) public claimedEpochByTokenId;

    modifier onlyAdmin() {
        require(_msgSender() == admin, "Indicia Bank: not admin");
        _;
    }

    constructor(
        address recipient_,
        address admin_,
        address nft_
    ) {
        _indiciaRecipient = recipient_;
        admin = admin_;
        indicia = IERC721A(nft_);
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Indicia Bank"),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    receive() external payable {}

    function activateNextEpoch() external onlyAdmin {
        pools[_epochId.current()].activated = false;
        _epochId.increment();
        Pool memory pool = pools[_epochId.current()];
        uint256 communityAmnt = (address(this).balance * communityFraction) /
            _denominator();
        uint256 indiciaAmnt = (address(this).balance * indiciaFraction) /
            _denominator();
        pool.id = _epochId.current();
        pool.totalAmnt = communityAmnt;
        pool.claimedAmnt = 0;
        pool.activated = true;
        pool.activatedTimestamp = block.timestamp;
        Address.sendValue(payable(_indiciaRecipient), indiciaAmnt);
        pools[_epochId.current()] = pool;
    }

    function _denominator() internal pure returns (uint96) {
        return 10000;
    }

    function claim(
        uint256 tokenId_,
        uint96 fraction_,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public nonReentrant {
        require(
            _msgSender() == indicia.ownerOf(tokenId_),
            "Indicia Bank: Invalid claimer"
        );
        uint256 epochId = _epochId.current();
        require(
            claimedEpochByTokenId[tokenId_] < epochId,
            "Indicia Bank: Already claimed"
        );
        require(
            _validateClaim(epochId, tokenId_, fraction_, r, s, v),
            "Indicia Bank: Invalid fraction"
        );
        Pool memory pool = pools[epochId];
        require(pool.activated, "Indicia Bank: non-active phase");
        uint256 amount = (pool.totalAmnt * fraction_) / _denominator();
        if (amount > 0) {
            Address.sendValue(payable(_msgSender()), amount);
            pool.claimedAmnt += amount;
            pools[epochId] = pool;
        }
        claimedEpochByTokenId[tokenId_] = epochId;
    }

    // view
    function getCurrentEpochId() public view returns (uint256) {
        return _epochId.current();
    }

    function isClaimed(uint tokenId_) public view returns (bool) {
        uint epochId = _epochId.current();
        return claimedEpochByTokenId[tokenId_] == epochId;
    }

    // internal
    function _validateClaim(
        uint256 epochId_,
        uint256 tokenId_,
        uint96 fraction_,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal view returns (bool) {
        bytes32 typeHash = keccak256(
            "Fraction(uint256 epochId,uint256 tokenId,uint96 fraction)"
        );
        bytes32 digest = keccak256(
            abi.encode(typeHash, epochId_, tokenId_, fraction_)
        );
        return
            SignatureChecker.verify(digest, admin, v, r, s, DOMAIN_SEPARATOR);
    }
}
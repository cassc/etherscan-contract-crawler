// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IBoringBrewBags.sol";
import "./Tag.sol";
import "./BBTag.sol";

/// @title Claim
/// @author Atlas C.O.R.P.
contract Claim is AccessControlEnumerable {
    using MerkleProof for bytes32[];

    bytes32 public constant CLAIM_MANAGER = keccak256("CLAIM_MANAGER");

    IBoringBrewBags public immutable boringBrewBagsContract;

    bytes32 public merkleroot;
    bool public active;
    uint256 public supply;
    uint256 public collectionId;

    mapping(address tokenHolder => uint256 claimedTokens)
        public tokensClaimedByAddress;
    event tokenClaimed(address indexed tokenHolder);

    modifier whenAddressOnWhitelist(
        bytes32[] calldata _merkleproof,
        uint256 _maxItems
    ) {
        require(
            MerkleProof.verify(
                _merkleproof,
                merkleroot,
                keccak256(abi.encodePacked(msg.sender, _maxItems))
            ),
            "whenAddressOnWhitelist: invalid merkle verfication"
        );
        _;
    }

    constructor(
        IBoringBrewBags _boringBrewBagsContract,
        uint256 _supply,
        uint256 _collectionId
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CLAIM_MANAGER, msg.sender);
        boringBrewBagsContract = _boringBrewBagsContract;
        supply = _supply;
        collectionId = _collectionId;
    }

    /// @param _amount is the amount being claimed. Caller can only claim 5 bags
    /// @param _maxItems is the max amount of items you can claim
    /// @param _merkleproof is the value to prove you are on whitelist
    function claim(
        uint256 _amount,
        uint256 _maxItems,
        bytes32[] calldata _merkleproof
    ) external whenAddressOnWhitelist(_merkleproof, _maxItems) {
        require(active, "claim: claim not active");

        require(_amount > 0, "claim: cannot claim 0");

        require(
            _amount + tokensClaimedByAddress[msg.sender] <= _maxItems,
            "claim: already claimed your max tokens"
        );

        require(supply >= _amount, "claim: not enough supply left for claim");

        supply -= _amount;

        tokensClaimedByAddress[msg.sender] += _amount;

        boringBrewBagsContract.mintSingle(msg.sender, collectionId, _amount);

        emit tokenClaimed(msg.sender);
    }

    /// @param _active true is active false is inactive
    function toggleActive(bool _active) external onlyRole(CLAIM_MANAGER) {
        active = _active;
    }

    /// @param _merkleRoot is the whitelist
    function setMerkleroot(
        bytes32 _merkleRoot
    ) external onlyRole(CLAIM_MANAGER) {
        merkleroot = _merkleRoot;
    }
}
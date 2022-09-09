// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {IFootballClub} from "./interfaces/IFootballClub.sol";

contract FootballClubSale is Ownable {
    using Address for address;

    IFootballClub public footballClub;

    uint256 private price = 0.05 ether;
    uint256 public clubsClaimed;

    uint256 internal constant MINT_LIMIT = 3060;

    uint256 private constant PHASE_1_TIMESTAMP = 1636999200;
    uint256 private constant PHASE_2_TIMESTAMP = 1637172000;
    uint256 private constant PHASE_3_TIMESTAMP = 1637344800;

    bytes32 internal whitelistMerkleRootPhase1;
    bytes32 internal whitelistMerkleRootPhase2;
    bytes32 internal advisorMerkleRoot;
    bytes32 public metadataMerkleRoot;

    event Withdraw(bool indexed sent, bytes data);

    mapping(bytes32 => mapping(address => uint256)) public redemptions;

    constructor(
        IFootballClub _footballClub,
        bytes32 _whitelistMerkleRootPhase1,
        bytes32 _whitelistMerkleRootPhase2,
        bytes32 _advisorMerkleRoot,
        bytes32 _metadataMerkleRoot,
        uint256 _advisorAllocation
    ) {
        footballClub = _footballClub;
        whitelistMerkleRootPhase1 = _whitelistMerkleRootPhase1;
        whitelistMerkleRootPhase2 = _whitelistMerkleRootPhase2;
        advisorMerkleRoot = _advisorMerkleRoot;
        metadataMerkleRoot = _metadataMerkleRoot;

        clubsClaimed = _advisorAllocation;
    }

    function preMint(uint256 _tokenId, bytes32[] calldata proof) external {
        require(_tokenId >= 1 && _tokenId <= 213, "Must be the correct token range");
        require(
            _advisorVerify(_advisorLeaf(_tokenId, msg.sender), proof),
            "must be on the advisor whitelist"
        );

        footballClub.safeMint(msg.sender, _tokenId);
    }

    function _advisorVerify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, advisorMerkleRoot, leaf);
    }

    function _advisorLeaf(uint256 _tokenId, address account)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_tokenId, account));
    }

    function _leaf(address account, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, amount));
    }

    //need to check to ensure hasn't already minted
    //map address to an integer - i.e. how many times has this address been minted for this phase
    //pass in a dummy proof for the first stage
    function redeem(
        uint256 _amount,
        uint256 _maxAmount,
        bytes32[] calldata proof
    ) external payable {
        require(msg.value >= _amount * price, "Insufficient payment");
        require(_amount <= 50, "Incorrect amount");
        require(_maxAmount > 0 && _maxAmount <= 50, "Incorrect max amount");

        bytes32 whitelistMerkleRoot;

        require(block.timestamp >= PHASE_1_TIMESTAMP, "whitelist not started");

        if (block.timestamp < PHASE_2_TIMESTAMP) {
            whitelistMerkleRoot = whitelistMerkleRootPhase1;
        } else if (block.timestamp < PHASE_3_TIMESTAMP) {
            whitelistMerkleRoot = whitelistMerkleRootPhase2;
        } else {
            for (uint256 i = 0; i < _amount; i++) {
                require(clubsClaimed < MINT_LIMIT, "Cannot mint past limit");

                clubsClaimed++;

                footballClub.safeMint(msg.sender, clubsClaimed);
            }

            return;
        }

        bool status = MerkleProof.verify(
            proof,
            whitelistMerkleRoot,
            _leaf(msg.sender, _maxAmount)
        );

        require(status, "Proof is invalid");

        for (uint256 i = 0; i < _amount; i++) {
            require(clubsClaimed < MINT_LIMIT, "Cannot mint past limit");
            require(
                redemptions[whitelistMerkleRoot][msg.sender] < _maxAmount,
                "Cannot mint more than alloted"
            );

            redemptions[whitelistMerkleRoot][msg.sender]++;
            clubsClaimed++;

            footballClub.safeMint(msg.sender, clubsClaimed);
        }
    }

    function verifyMetadata(bytes32 leaf, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, metadataMerkleRoot, leaf);
    }

    function withdraw() external onlyOwner {
        address payable owner = payable(owner());

        (bool sent, bytes memory data) = owner.call{
            value: address(this).balance
        }("");
        emit Withdraw(sent, data);
    }

    function setWhitelistMerkleRootPhase1(bytes32 _merkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRootPhase1 = _merkleRoot;
    }

    function setWhitelistMerkleRootPhase2(bytes32 _merkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRootPhase2 = _merkleRoot;
    }

    function setAdvisorMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        advisorMerkleRoot = _merkleRoot;
    }
}
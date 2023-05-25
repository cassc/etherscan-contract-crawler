// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IOmniFusion.sol";
import "./IOmniFusionBurn.sol";


contract OmniFusion is ERC1155, IOmniFusion, IOmniFusionBurn, Ownable {
    using ECDSA for bytes32;

    event Fused(address sender, uint fusedId, uint burnedId, bytes32 fusionReceiptIPFSHash);

    // 2 byte multiHash prefix
    bytes2 constant public IPFSMultiHashPrefix = 0x1220;

    // the Omnimorphs contract
    IERC721 public omnimorphsContract;
    // public key to validate transactions from the centralized fusion app
    address public fusionSigner;
    // whether fusion is active
    bool public isFusionActive = false;
    // whether fusion is locked forever
    bool public isFusionLocked = false;

    // IPFS hash to the fusion receipt for the fusion at hand
    // hashes need to be prefixed with ipfsMultiHashPrefix and base58 encoded to
    // be used as urls to access the actual IPFS document
    mapping(uint => bytes32) private _fusedIdFusionReceiptIPFSHashMap;

    constructor(string memory initialURI, address _omnimorphsAddress, address _signer) ERC1155(initialURI) {
        omnimorphsContract = IERC721(_omnimorphsAddress);
        fusionSigner = _signer;
    }

    // PUBLIC

    // fuses two tokens
    function fuseTokens(address sender, uint toFuse, uint toBurn, bytes calldata payload) public override {
        require(isFusionActive, "Fusion is currently not active");
        require(msg.sender == address(omnimorphsContract), "Only the Omnimorphs contract can call this method");
        require(omnimorphsContract.ownerOf(toFuse) == sender && omnimorphsContract.ownerOf(toBurn) == sender, "Tokens not owned by sender");
        require(
            _fusedIdFusionReceiptIPFSHashMap[toFuse] == bytes32(0),
            "Fused token has already been fused"
        );
        require(
            _fusedIdFusionReceiptIPFSHashMap[toBurn] == bytes32(0),
            "Burned token has already been fused"
        );

        bytes32 IPFSHash = _bytesToBytes32(payload[0:32]);
        bytes memory signature = payload[32:payload.length];

        require(
            _matchAddressSigner(_hashTransaction(sender, toFuse, toBurn, IPFSHash), signature),
            "Signature is incorrect"
        );

        _fusedIdFusionReceiptIPFSHashMap[toFuse] = IPFSHash;
        _mintShard(sender, toBurn);
        emit Fused(sender, toFuse, toBurn, IPFSHash);
    }

    // gets the IPFS hash of the fusion receipt
    // needs to be base58 encoded to work as a uri
    function getFusionReceiptIPFSHash(uint id) external view returns(bytes memory) {
        return abi.encodePacked(IPFSMultiHashPrefix, _fusedIdFusionReceiptIPFSHashMap[id]);
    }

    // owners and approved operators can burn their own soul shards
    function burn(address sender, uint id, uint amount) external override {
        require(sender == msg.sender || isApprovedForAll(sender, msg.sender), "Burn caller is not owner nor approved");
        require(balanceOf(sender, id) >= amount, "Trying too burn too many tokens");

        _burn(sender, id, amount);
    }

    // OWNER

    // activate and deactivate fusion
    function setIsFusionActive(bool value) external onlyOwner {
        require(!isFusionLocked, "Cannot reset, as fusion is locked forever");

        isFusionActive = value;
    }

    // lock fusion forever
    function lockFusion() external onlyOwner {
        require(!isFusionActive, "Can only lock when fusion is inactive");

        isFusionLocked = true;
    }

    // set signer for signature verification
    function setFusionSigner(address value) external onlyOwner {
        fusionSigner = value;
    }

    // sets the ERC1155 base uri
    function setURI(string memory value) external onlyOwner {
        _setURI(value);
    }

    // INTERNAL

    // mints a shard to address
    function _mintShard(address to, uint toBurn) private {
        _mint(to, toBurn, 1, "0x");
    }

    // generates a hash from arguments
    function _hashTransaction(address sender, uint toFuse, uint toBurn, bytes32 IPFSHash) private pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, toFuse, toBurn, IPFSHash)))
        );

        return hash;
    }

    // checks signature against a hash, to see if the private pair of signer signed it
    function _matchAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return fusionSigner == hash.recover(signature);
    }

    function _bytesToBytes32(bytes memory source) private pure returns (bytes32 result) {
        require(source.length == 32, "Source bytes array has to be of length 32");

        assembly {
            result := mload(add(source, 32))
        }
    }
}
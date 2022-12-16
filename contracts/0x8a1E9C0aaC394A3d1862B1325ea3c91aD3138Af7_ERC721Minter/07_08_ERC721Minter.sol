// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IERC721Mintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ERC721Minter is Ownable, Initializable {
    IERC721Mintable public nft;
    uint256 public price;
    bytes32 public merkleRoot;
    /// @dev mapping merkle leaf => quantity minted
    mapping(bytes32 => uint256) public minted;
    Escrow private escrow;

    function initialize(
        address owner,
        IERC721Mintable _nft,
        uint256 _price,
        bytes32 _merkleRoot
    ) external initializer {
        _transferOwnership(owner);
        nft = _nft;
        price = _price;
        merkleRoot = _merkleRoot;
        escrow = new Escrow();
    }

    function mint(
        address to,
        uint256 quantity,
        uint256 maxUserMints,
        uint256 nonce,
        bytes32[] memory proof
    ) external payable {
        // check merkle tree proof
        bytes32 leaf = keccak256(abi.encodePacked(to, maxUserMints, nonce));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid merkle proof");
        // ensure user can still mint
        require(minted[leaf] + quantity <= maxUserMints, "Too many mints");
        // check purchase price
        require(msg.value == quantity * price, "Wrong purchase amount");
        // update minted quantity for this leaf
        minted[leaf] += quantity;
        // deposit buyer funds into the escrow contract
        escrow.deposit{value: msg.value}(owner());
        // mint
        for (uint256 i = 0; i < quantity; i++) {
            nft.mint(to);
        }
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        escrow.withdraw(payee);
    }

    function payments(address dest) public view returns (uint256) {
        return escrow.depositsOf(dest);
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface mintContract {
    function mint(address, uint256) external;
    function numberMinted(address) external view returns(uint256);
}

contract Q00ts is Ownable {
    error ExceedMaxMint();
    error WrongValueSent();
    error SaleIsPaused();
    error InvalidProof();
    error MintZeroItems();

    uint256 public constant Q00TLIST_MINT_PRICE = 0.025 ether;
    uint256 public constant PUBLIC_MINT_PRICE = 0.03 ether;
    uint256 public constant MAX_PER_WALLET = 5;

    bytes32 private merkleRoot;

    bool public publicSaleStarted;

    mintContract private q00nicorns;
    mintContract private q00tants;

    constructor(bytes32 _root, address _q00nicorns, address _q00tants) {
        q00nicorns = mintContract(_q00nicorns);
        q00tants = mintContract(_q00tants);
        merkleRoot = _root;
    }

    function q00tlistMint(bytes32[] calldata _proof, uint256 numQ00tants, uint256 numQ00nicorns) external payable {
        uint256 amount = numQ00nicorns + numQ00tants;

        if (amount == 0) revert MintZeroItems();
        if (msg.value != Q00TLIST_MINT_PRICE * amount) revert WrongValueSent();
        if (q00tsMinted(msg.sender) + amount > MAX_PER_WALLET) revert ExceedMaxMint();

        bytes32 leaf = keccak256((abi.encodePacked(msg.sender)));

        if (!MerkleProof.verify(_proof, merkleRoot, leaf)) {
            revert InvalidProof();
        }

        if (numQ00tants > 0) q00tants.mint(msg.sender, numQ00tants);
        if (numQ00nicorns > 0) q00nicorns.mint(msg.sender, numQ00nicorns);
    }

    function mint(uint256 numQ00tants, uint256 numQ00nicorns) external payable {
        uint256 amount = numQ00nicorns + numQ00tants;

        if (amount == 0) revert MintZeroItems();
        if (!publicSaleStarted) revert SaleIsPaused();
        if (q00tsMinted(msg.sender) + amount > MAX_PER_WALLET) revert ExceedMaxMint();
        if (msg.value != PUBLIC_MINT_PRICE * amount) revert WrongValueSent();

        if (numQ00tants > 0) q00tants.mint(msg.sender, numQ00tants);
        if (numQ00nicorns > 0) q00nicorns.mint(msg.sender, numQ00nicorns);
    }

    function flipPublicSale(bool _state) external onlyOwner {
        publicSaleStarted = _state;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function q00tsMinted(address owner) internal view returns(uint256) {
        return q00tants.numberMinted(owner) + q00nicorns.numberMinted(owner);
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
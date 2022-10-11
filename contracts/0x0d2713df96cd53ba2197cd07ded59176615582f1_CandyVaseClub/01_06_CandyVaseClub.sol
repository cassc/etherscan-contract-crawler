// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@azuki/contracts/ERC721A.sol";

/// @author Bitquence <@_bitquence> for Candy Vase Club <@CandyVaseClub>
contract CandyVaseClub is ERC721A("CandyVaseClub", "CANDY"), Ownable {
    uint256 public constant MAX_SUPPLY = 200;
    uint256 public constant MINT_LIMIT = 3;
    uint256 public constant MINT_PRICE = 0.05 ether;

    bytes32 private merkleRoot;
    SaleState public saleState;
    string public baseURI;

    enum SaleState {
        Closed,
        Reserved,
        Open
    }

    constructor(bytes32 merkleRoot_, string memory baseURI_) {
        merkleRoot = merkleRoot_;
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // ------- CONDITIONS -------

    function isValidProof(bytes32[] calldata proof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encode(msg.sender));
        return MerkleProof.verifyCalldata(proof, merkleRoot, leaf);
    }

    modifier onlyUser() {
        require(msg.sender == tx.origin, "CANDY: forbidden");
        _;
    }

    // ------- EXTERNALS -------

    function mint(uint256 quantity, bytes32[] calldata proof) external payable onlyUser {
        if (saleState == SaleState.Closed) {
            revert("CANDY: sale is currently closed");
        } else if (saleState == SaleState.Reserved && !isValidProof(proof)) {
            revert("CANDY: forbidden (invalid proof)");
        }

        require(
            this.totalSupply() + quantity <= MAX_SUPPLY,
            "CANDY: mint exceeds maximum supply"
        );
        require(
            _numberMinted(msg.sender) + quantity <= MINT_LIMIT,
            "CANDY: mint exceeds per-user limit"
        );
        require(
            msg.value >= MINT_PRICE * quantity,
            "CANDY: insufficient ether sent"
        );

        _mint(msg.sender, quantity);
    }

    function batchMint(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(
            recipients.length == quantities.length,
            "CANDY: arguments length mismatch"
        );

        uint256 supply = this.totalSupply();

        for (uint256 i; i < recipients.length; i++) {
            supply += quantities[i];

            require(
                supply <= MAX_SUPPLY,
                "CANDY: batch mint exceeds maximum supply"
            );

            _mint(recipients[i], quantities[i]);
        }
    }

    // ------- AUTHORITY -------

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
    }

    function withdrawFunds() external onlyOwner {
        address payable owner = payable(this.owner());

        owner.transfer(address(this).balance);
    }
}
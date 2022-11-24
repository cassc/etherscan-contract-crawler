// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "./IMia.sol";

contract TEST is ERC721A("TEST", "TEST"), Ownable {
    address public constant MIA_CONTRACT_ADDRESS =
        0x2b081427b51d471C02f865f16673caEb3Acc7F9e;
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 10000;
    bytes32 public merkleRoot;
    bool public paused = true;

    mapping(address => bool) public minted;

    function mint(address to, bytes32[] calldata _merkleProof) public {
        require(!paused, "Mint is paused");
        require(totalSupply() < maxSupply, "Cannot exceed maxSupply");
        require(!minted[to], "Already minted");
        require(isAllowListed(to, _merkleProof), "Not Allowlisted");

        minted[to] = true;
        _safeMint(to, 1);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    _toString(getLevel(ownerOf(tokenId))),
                    baseExtension
                )
            );
    }

    function getLevel(address _owner) public view returns (uint256) {
        uint256 balance = IMia(MIA_CONTRACT_ADDRESS).balanceOf(_owner);

        if (balance < 5) {
            return balance;
        } else if (balance < 10) {
            return 5;
        } else {
            return 6;
        }
    }

    function isAllowListed(address _address, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));

        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    // SBT
    function setApprovalForAll(address, bool) public virtual override {
        revert("setApprovalForAll is prohibited");
    }

    function approve(address, uint256) public payable virtual override {
        revert("approve is prohibited");
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(
            from == address(0) || to == BURN_ADDRESS,
            "Transfer is prohibited"
        );
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}
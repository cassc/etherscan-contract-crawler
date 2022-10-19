// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Mia is ERC721A("Mia", "MIA"), Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 300;
    uint256 public constant MAX_MINT_AMOUNT = 2;
    uint256 public constant MINT_COST = 0.03 ether;

    string public baseURI;
    string public notRevealedURI;
    string public baseExtension = ".json";

    bool public isRevealed = false;
    bool public isPaused = true;

    bytes32 public merkleRoot;

    mapping(address => uint256) public minted;

    function mint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
    {
        require(!isPaused, "Mint is not active!");
        require(tx.origin == msg.sender, "Externally-owned account only!");
        require(msg.value >= MINT_COST * _amount, "Insufficient eth!");
        require(
            _amount > 0 && minted[msg.sender] + _amount <= MAX_MINT_AMOUNT,
            "Invalid mint amount!"
        );
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf),
            "Invalid merkle proof!"
        );

        minted[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function ownerMint(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid mint amount!");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded!");
        _safeMint(_to, _amount);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _newNotRevealedURI)
        external
        onlyOwner
    {
        notRevealedURI = _newNotRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function reveal() external onlyOwner {
        isRevealed = true;
    }

    function pause(bool _state) external onlyOwner {
        isPaused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (isRevealed == false) {
            return notRevealedURI;
        } else {
            return
                string(
                    abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension)
                );
        }
    }

    function withdraw() external onlyOwner {
        uint256 sendAmount = address(this).balance;

        address artist = payable(0x8e2C496095Af9D5cb4b0B479529e201339D0C5EA);
        address engineer = payable(0x4b3CCD7cE7C1Ca0B0277800cd938De64214d81F3);
        bool success;

        (success, ) = artist.call{value: ((sendAmount * 50) / 100)}("");
        require(success, "Transfer failed!");
        (success, ) = engineer.call{value: ((sendAmount * 50) / 100)}("");
        require(success, "Transfer failed!");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
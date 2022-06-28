// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract YoshisPlanet is ERC721A, Ownable, Pausable {
    uint256 public price = 0.1 ether;
    uint256 public whitelistPrice = 0.08 ether;

    uint256 public maxSupply = 135;

    mapping(address => bool) public walletHasMinted;

    string baseURI;

    bool public isWhitelistEnabled = true;
    bytes32 merkleRoot;

    constructor() ERC721A("Yoshi's Planet", "YSP") {
        _pause();
    }

    function mint(bytes32[] calldata _proof) external payable whenNotPaused {
        require(totalSupply() < maxSupply, "There are not NFTs left");
        require(
            walletHasMinted[msg.sender] == false,
            "You have already minted one NFT"
        );

        if (isWhitelistEnabled) {
            require(
                isWhitelisted(msg.sender, _proof),
                "You are not whitelisted"
            );
            require(msg.value >= whitelistPrice, "Not enough ether.");
        } else {
            require(msg.value >= price, "Not enough ether.");
        }

        _mint(msg.sender, 1);

        walletHasMinted[msg.sender] = true;
    }

    function airdrop(address[] memory _addresses, uint256 _amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _amount);
        }
    }

    function isWhitelisted(address _wallet, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_wallet));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setPause(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setPrice(uint256 _price, uint256 _whitelistPrice)
        external
        onlyOwner
    {
        price = _price;
        whitelistPrice = _whitelistPrice;
    }

    function setWhitelistEnabled(bool _isWhitelistEnabled) external onlyOwner {
        isWhitelistEnabled = _isWhitelistEnabled;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}
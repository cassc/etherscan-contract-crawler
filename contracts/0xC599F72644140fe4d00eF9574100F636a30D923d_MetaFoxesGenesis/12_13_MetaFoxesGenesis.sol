// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MetaFoxesGenesis is ERC721A, Ownable, Pausable {
    using ECDSA for bytes32;

    string public baseURI;
    address public signer;
    uint256 public maxSupply;
    uint256 public maxMint;
    uint256 public price;

    event Minted(address minter, uint256 quantity);
    event BaseURIChanged(string newBaseURI);

    constructor(
        address _signer,
        uint256 _supply,
        uint256 _maxMint,
        string memory initBaseURI
    ) ERC721A("Meta Foxes Genesis", "MetaFox") {
        signer = _signer;
        maxSupply = _supply;
        maxMint = _maxMint;
        baseURI = initBaseURI;
        _pause();
    }

    function _hash(string calldata salt, address _address) internal view returns (bytes32) {
        return keccak256(abi.encode(salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory token) internal view returns (bool) {
        return (_recover(hash, token) == signer);
    }

    function _recover(bytes32 hash, bytes memory token) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function mint(
        uint256 quantity,
        string calldata salt,
        bytes calldata token
    ) external payable {
        require(!paused(), "Paused.");
        require(tx.origin == msg.sender, "Only EOA.");
        require(_verify(_hash(salt, msg.sender), token), "Invalid token.");
        require(numberMinted(msg.sender) + quantity <= maxMint, "Invalid quantity.");
        require(totalSupply() + quantity <= maxSupply, "No more left.");

        _safeMint(msg.sender, quantity);
        refundIfOver(price * quantity);

        emit Minted(msg.sender, quantity);
    }

    function refundIfOver(uint256 total) private {
        require(msg.value >= total, "Invalid value.");
        if (msg.value > total) {
            payable(msg.sender).transfer(msg.value - total);
        }
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function reserve(address[] calldata recipients) external onlyOwner {
        require(totalSupply() + recipients.length <= maxSupply, "Max supply exceeded.");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid address");
            _safeMint(recipients[i], 1);
        }
    }

    function updateSupply(uint256 newSupply) external onlyOwner {
        require(newSupply > totalSupply(), "invalid supply");
        maxSupply = newSupply;
    }

    function updateMaxMint(uint256 newMaxMint) external onlyOwner {
        require(newMaxMint >= 1, "invalid max mint");
        maxMint = newMaxMint;
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "transfer failed.");
    }
}
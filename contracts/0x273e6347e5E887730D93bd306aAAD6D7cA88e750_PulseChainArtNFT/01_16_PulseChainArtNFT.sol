//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PulseChainArtNFT is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 public nextMintId = 0;
    uint256 public wlMintPrice = 0.2 ether;
    uint256 public pMintPrice = 0.3 ether;

    string public currentURI = "https://gateway.pinata.cloud/ipfs/QmSLVCN16kQVkZRWGW3ThfDk3kTWarZXqAhPLC8P9sfMbQ/";

    bytes32 public wlMerkleRoot;

    uint256 public mintStep = 1000;
    uint256 public totalSupply = 4444;

    bool public isPaused = false;

    address private lockAddress;

    mapping(address => bool) public isClaimed;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        string memory _currentURI,
        address _lockAddress
    ) ERC721(_name, _symbol) {
        _setCurrentURI(_currentURI);
        _setTotalSupply(_totalSupply);
        _setPaused(true);
        _setLockAddress(_lockAddress);
    }

    modifier isMintAllowed() {
        require(
            !isPaused,
            "Error: You are not allowed to mint until the owner starts Minting!"
        );
        _;
    }

    modifier isMerkleProoved(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                wlMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Error: Address is NOT whitelisted yet!"
        );
        _;
    }

    modifier isEnough(uint256 _price, uint256 _tokens) {
        require(
            _price * _tokens <= msg.value,
            "Error: Sent ETH value is INCORRECT!"
        );
        _;
    }

    function _mint(uint256 _mintCount) private {
        require(
            nextMintId + _mintCount - 1 < totalSupply,
            "Error: Supply limited!"
        );
        require(!isPaused, "Error: Minting is Paused");

        for (uint256 i = 0; i < _mintCount; i++) {
            uint256 newId = nextMintId;
            _safeMint(msg.sender, newId);
            _setTokenURI(
                newId,
                string(abi.encodePacked(currentURI, Strings.toString(newId)))
            );
            nextMintId++;
        }

        if (nextMintId == totalSupply || nextMintId % mintStep == 0) {
            isPaused = true;
        }
    }

    function pMint(uint256 _mintCount)
        external
        payable
        isMintAllowed
        isEnough(pMintPrice, _mintCount)
        nonReentrant
        returns (uint256)
    {
        _mint(_mintCount);

        return nextMintId - 1;
    }

    function checkMintStatus() public onlyMinter {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function wlMint(bytes32[] calldata _merkleProof)
        external
        payable
        isMintAllowed
        isEnough(wlMintPrice, 1)
        isMerkleProoved(_merkleProof)
        nonReentrant
        returns (uint256)
    {
        _mint(1);
        isClaimed[msg.sender] = true;

        return nextMintId - 1;
    }

    function setWLMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        wlMerkleRoot = merkleRoot;
    }

    function setPMintPrice(uint256 _price) external onlyOwner {
        pMintPrice = _price;
    }

    function setWLMintPrice(uint256 _price) external onlyOwner {
        wlMintPrice = _price;
    }

    function setCurrentURI(string memory _currentURI) external onlyOwner {
        _setCurrentURI(_currentURI);
    }

    function _setCurrentURI(string memory _currentURI) internal {
        currentURI = _currentURI;
    }

    function setPaused(bool _isPaused) external onlyOwner {
        _setPaused(_isPaused);
    }

    function _setPaused(bool _isPaused) internal {
        isPaused = _isPaused;
    }

    function _setLockAddress(address _lockAddress) internal {
        lockAddress = _lockAddress;
    }

    function setTotalSupply(uint256 _totalSupply) external onlyOwner {
        _setTotalSupply(_totalSupply);
    }

    function _setTotalSupply(uint256 _totalSupply) internal {
        totalSupply = _totalSupply;
    }

    function setMintStep(uint256 _mintStep) external onlyOwner {
        _setMintStep((_mintStep));
    }

    function _setMintStep(uint256 _mintStep) internal {
        mintStep = _mintStep;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(
            balance > 20 ether,
            "You should withdraw the balance when it has over 20 ether"
        );
        payable(msg.sender).transfer(balance);
    }
}
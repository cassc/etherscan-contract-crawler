// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./ERC721AQueryable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SMPLverseBase is
    ERC721A,
    ERC721AQueryable,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    constructor() ERC721A("SMPLverse", "SMPL") {}

    string private _baseTokenUri = "https://api.smplverse.xyz/metadata/";
    uint256 public collectionSize = 511;
    uint256 public mintPrice = 0.3 ether;
    uint256 public whitelistMintPrice = 0.27 ether;
    uint256 public maxMint = 10;
    bytes32 public imageHash =
        0xa6466d90d72e80d73c5879634bdb3f2c57854e72cd9687f15bffce5f4c3e381b;
    address public devAddress = 0x2eD29d982B0120d49899a7cC7AfE7f5d5435bC97;
    bytes32 public _merkleRoot =
        0xa7ad73391aba9ddfe2dc8c372f4b605b8c95a20166d86616b3dc8f7744f9b7d7;

    bool public whitelistMintOpen = false;

    modifier onlyIfSendingEnoughEth(uint256 quantity) {
        require(msg.value >= quantity.mul(mintPrice), "insufficient eth");
        _;
    }

    modifier onlyIfValidMerkleProof(bytes32[] calldata proof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(verifyProof(proof, leaf), "invalid proof");
        _;
    }

    modifier onlyIfSendingEnoughEthWhitelist(uint256 quantity) {
        require(
            msg.value >= quantity.mul(whitelistMintPrice),
            "insufficient eth"
        );
        _;
    }

    modifier onlyWhenWhitelistMintOpen() {
        require(whitelistMintOpen, "whitelist mint closed");
        _;
    }

    modifier onlyIfThereSMPLsLeft(uint256 quantity) {
        require(totalSupply() + 1 <= collectionSize, "no SMPLs left");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "caller not user");
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _baseTokenUri;
    }

    function setBaseTokenURI(string memory _uri) external onlyOwner {
        _baseTokenUri = _uri;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        _merkleRoot = _root;
    }

    function toggleWhitelistMint() external onlyOwner {
        whitelistMintOpen = !whitelistMintOpen;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
            );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(uint256 quantity)
        external
        payable
        onlyIfSendingEnoughEth(quantity)
        onlyIfThereSMPLsLeft(quantity)
        callerIsUser
        whenNotPaused
    {
        _safeMint(msg.sender, quantity);
    }

    function verifyProof(bytes32[] calldata proof, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        onlyIfThereSMPLsLeft(quantity)
        callerIsUser
        whenNotPaused
        onlyIfSendingEnoughEthWhitelist(quantity)
        onlyWhenWhitelistMintOpen
        onlyIfValidMerkleProof(proof)
    {
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool ownerWithdrawSuccess, ) = msg.sender.call{
            value: address(this).balance.mul(8).div(10)
        }("");
        require(ownerWithdrawSuccess, "owner ww failed");
        (bool devWithdrawSuccess, ) = devAddress.call{
            value: address(this).balance
        }("");
        require(devWithdrawSuccess, "dev ww failed");
    }

    receive() external payable {}
}
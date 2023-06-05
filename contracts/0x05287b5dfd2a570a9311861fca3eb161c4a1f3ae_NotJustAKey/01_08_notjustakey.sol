// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NotJustAKey is ERC721A, Ownable {
    enum SaleStatus {
        PAUSED,
        ALLOWLIST,
        PUBLIC,
        REMAINING
    }

    using Strings for uint256;
    using ECDSA for bytes32;

    SaleStatus public saleStatus = SaleStatus.PAUSED;

    uint256 private constant PRICE_KEYS = 0 ether;
    uint256 private constant MAX_KEYS = 5555;

    string private _baseTokenURI;

    bytes32 public allowlistMerkleRoot;
    bytes32 public publicRaffleMerkleRoot;

    mapping(address => bool) public publicRaffleSalePurchased;
    mapping(address => bool) public allowlistSalePurchased;
    mapping(address => bool) public remainingSalePurchased;

    address private immutable withdrawalAddress;

    constructor(string memory baseTokenURI, address _withdrawalAddress)
        ERC721A("NotJustAKey", "KEY")
    {
        _baseTokenURI = baseTokenURI;
        withdrawalAddress = _withdrawalAddress;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSaleStatus(SaleStatus _status) external onlyOwner {
        saleStatus = _status;
    }

    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot)
        external
        onlyOwner
    {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    function setPublicRaffleMerkleRoot(bytes32 _publicRaffleMerkleRoot)
        external
        onlyOwner
    {
        publicRaffleMerkleRoot = _publicRaffleMerkleRoot;
    }

    function processMint(uint256 _quantity) internal {
        require(msg.value == PRICE_KEYS * _quantity, "INCORRECT ETH SENT");
        require(
            totalSupply() + _quantity <= MAX_KEYS,
            "MAX CAP OF KEYS EXCEEDED"
        );
        _mint(msg.sender, _quantity);
    }

    function allowlistSale(bytes32[] memory _proof)
        external
        payable
        callerIsUser
    {
        require(
            saleStatus == SaleStatus.ALLOWLIST,
            "ALLOW LIST MINTING IS NOT ACTIVE"
        );
        require(
            MerkleProof.verify(
                _proof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "MINTER IS NOT ON ALLOW LIST"
        );
        require(
            !allowlistSalePurchased[msg.sender],
            "ALLOWLIST TICKET ALREADY USED"
        );
        allowlistSalePurchased[msg.sender] = true;

        processMint(1);
    }

    function publicRaffleSale(bytes32[] memory _proof)
        external
        payable
        callerIsUser
    {
        require(
            saleStatus == SaleStatus.PUBLIC,
            "PUBLIC RAFFLE MINTING IS NOT ACTIVE"
        );
        require(
            MerkleProof.verify(
                _proof,
                publicRaffleMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "MINTER IS NOT ON PUBLIC RAFFLE LIST"
        );
        require(
            !publicRaffleSalePurchased[msg.sender],
            "PUBLIC RAFFLE TICKET ALREADY USED"
        );
        publicRaffleSalePurchased[msg.sender] = true;

        processMint(1);
    }

    function remainingSale() external payable callerIsUser {
        require(
            saleStatus == SaleStatus.REMAINING,
            "REMAINING SALE IS NOT ACTIVE"
        );
        require(
            !remainingSalePurchased[msg.sender],
            "REMAINING SALE KEY ALREADY PURCHASED"
        );
        remainingSalePurchased[msg.sender] = true;

        processMint(1);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function withdrawFunds() external onlyOwner {
        payable(withdrawalAddress).transfer(address(this).balance);
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function getOwnershipData(uint256 _tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(_tokenId);
    }
}
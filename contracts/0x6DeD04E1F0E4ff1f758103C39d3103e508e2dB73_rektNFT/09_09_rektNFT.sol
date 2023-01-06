// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./erc721a/ERC721A.sol";

contract rektNFT is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 merkleRoot =
        0x2d3e35479e1975d3165d386cae91d9f29e2a198e754b122bf2cc1bb7200d7538;
    mapping(address => bool) public whitelistClaimed;

    string public baseURI;
    uint256 public maxSupply = 2023;
    uint256 public currentSupply = 1;
    uint8 public maxMintAmount = 1;
    bool public publicSaleActive = false;

    address public withdrawAddress;
    //mapping(uint256 => string) public tokenIdToURI;

    address[] public admins;
    mapping(address => bool) public ownerByAddress;

    //@title This is ERC721A contract for Rekt
    // @author The name of the author is @dsborde
    // @notice Constructor sets the base parameters for constructors
    // @dev Since its ERC721A we need to use _msgSender()
    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {
        admins.push(msg.sender);
        ownerByAddress[msg.sender] = true;
    }

    modifier onlyAdmins() {
        require(
            ownerByAddress[msg.sender] == true,
            "only admins can call this fucntion "
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mintWhiteListSale(bytes32[] memory _merkleProof)
        external
        callerIsUser
    {
        require(!publicSaleActive, "Not ready for sale");
        require(currentSupply + 1 <= maxSupply, "Supply Limit Reached");

        require(
            !whitelistClaimed[msg.sender],
            "whiteList slot has already been claimed."
        );

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );
        whitelistClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
        currentSupply++;
    }

    function mintPublicSale() external callerIsUser {
        require(publicSaleActive, "Not ready for public sale");
        require(
            currentSupply + maxMintAmount <= maxSupply,
            "Supply Limit Reached"
        );
        require(
            balanceOf(msg.sender) < maxMintAmount,
            "Max NFT mint Limit reached"
        );
        _safeMint(msg.sender, maxMintAmount);
        currentSupply += maxMintAmount;
    }

    function mintOnlyAdmin(uint256 mintAmount)
        external
        callerIsUser
        onlyAdmins
    {
        require(publicSaleActive, "Not ready for public sale");
        require(
            currentSupply + mintAmount <= maxSupply,
            "Supply Limit Reached"
        );
        _safeMint(msg.sender, mintAmount);
        currentSupply += mintAmount;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Non Existent Token");
        string memory currentBaseURI = _baseURI();

        return (
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : ""
        );
    }

    function setBaseURI(string memory _newBaseURI) public onlyAdmins {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdrawAll() external onlyOwner nonReentrant {
        require(withdrawAddress != address(0), "withdrawAddress not set");
        (bool success, ) = payable(withdrawAddress).call{
            value: (address(this).balance)
        }("");
        require(success, "Failed to Send Ether");
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setpublicSale(bool _state) external onlyAdmins {
        publicSaleActive = _state;
    }

    function SetPayoutAddress(address _payoutAddress) external onlyOwner {
        withdrawAddress = _payoutAddress;
    }

    function SetMaxMintAmount(uint8 _maxMintAmount) external onlyAdmins {
        maxMintAmount = _maxMintAmount;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyAdmins {
        merkleRoot = _merkleRoot;
    }

    function addAdminAddress(address _adminAddress) public onlyAdmins {
        admins.push(_adminAddress);
        ownerByAddress[_adminAddress] = true;
    }

    function getAdmins() public view returns (address[] memory) {
        return admins;
    }
}
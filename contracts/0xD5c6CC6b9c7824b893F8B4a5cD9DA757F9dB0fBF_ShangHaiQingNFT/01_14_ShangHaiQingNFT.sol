// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ERC721A.sol";

contract ShangHaiQingNFT is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Finished
    }

    Status public status;

    string private _uri;
    address  private _signer;
    mapping(address => uint256) private _publicNumberMinted;

    uint256 public immutable maxTotalSupply;
    uint256 public immutable PreMaxMint;
    uint256 public immutable PublicMaxMint;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory initURI, address signer) ERC721A("ShangHai Qing", "SHQ", 3) {
        _uri = initURI;
        maxTotalSupply = 1000;
        PreMaxMint = 2;
        PublicMaxMint = 1;
        _signer = signer;
    }

    function _hash(string calldata salt, address _address) internal view returns (bytes32)
    {
        return keccak256(abi.encode(salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory token) internal view returns (bool)
    {
        return _signer == _recover(hash, token);
    }

    function _recover(bytes32 hash, bytes memory token) internal pure returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function _baseURI() internal view  override(ERC721A) returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) public virtual onlyOwner{
        _uri = newuri;
    }

    function mint(string calldata salt, bytes calldata token) external{
        require(status == Status.PublicSale, "SHQE006");
        require(_verify(_hash(salt, msg.sender), token), "SHQE001");
        require(publicNumberMinted(msg.sender) + PublicMaxMint <= PublicMaxMint, "SHQE008");
        _safeMint(msg.sender,PublicMaxMint);
        _publicNumberMinted[msg.sender] = _publicNumberMinted[msg.sender] + 1;
    }

    function preSaleMint(
        uint256 num,
        string calldata salt,
        bytes calldata token
    ) external{
        require(status == Status.PreSale, "SHQE006");
        require(num > 0 && num <= PreMaxMint, "SHQE002");
        require(_verify(_hash(salt, msg.sender), token), "SHQE001");
        require(numberMinted(msg.sender) + num <= PreMaxMint, "SHQE008");
        _safeMint(msg.sender,num);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function publicNumberMinted(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: number minted query for the zero address"
        );
        return _publicNumberMinted[owner];
    }

    function release() public virtual nonReentrant onlyOwner{
        require(address(this).balance > 0, "SHQE005");
        Address.sendValue(payable(owner()), address(this).balance);
        emit PaymentReleased(owner(), address(this).balance);
    }
}
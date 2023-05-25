// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ERC721A.sol";

contract WeirdoGhostGang is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Finished
    }

    Status public status;

    uint256 public PRICE = 0.05 ether;

    string private _uri;
    mapping(address => uint256) private _signerOfNum;
    mapping(address => uint256) private _publicNumberMinted;

    uint256 public immutable maxTotalSupply;
    uint256 public immutable PreMaxMint;
    uint256 public immutable PublicMaxMint;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory initURI, address signer1, address signer2) ERC721A("Weirdo Ghost Gang", "GHOST", 3) {
        _uri = initURI;
        maxTotalSupply = 5556;
        PreMaxMint = 2;
        PublicMaxMint = 1;
        _signerOfNum[signer1] = 1;
        _signerOfNum[signer2] = 2;
    }

    function _hash(string calldata salt, address _address) internal view returns (bytes32)
    {
        return keccak256(abi.encode(salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory token) internal view returns (uint256)
    {
        return _signerOfNum[_recover(hash, token)] ;
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

    function mint(uint256 num, string calldata salt, bytes calldata token) external payable {
        require(status == Status.PublicSale, "WGGE006");
        require(_verify(_hash(salt, msg.sender), token) >= num, "WGGE001");
        require(publicNumberMinted(msg.sender) + num <= PublicMaxMint, "WGGE008");
        verified(num);
        _safeMint(msg.sender,num);
        _publicNumberMinted[msg.sender] = _publicNumberMinted[msg.sender] + 1;
    }

    function preSaleMint(
        uint256 amount,
        string calldata salt,
        bytes calldata token
    ) external payable {
        require(status == Status.PreSale, "WGGE006");
        uint256 preMaxMint = _verify(_hash(salt, msg.sender), token);
        require(preMaxMint >= amount, "WGGE001");
        require(numberMinted(msg.sender) + amount <= preMaxMint, "WGGE008");
        verified(amount);
        _safeMint(msg.sender, amount);
    }

    function setStatus(Status _status, address signer1, address signer2, address signer3) external onlyOwner {
        status = _status;
        if(status == Status.PublicSale){
            delete _signerOfNum[signer1];
            delete _signerOfNum[signer2];
            _signerOfNum[signer3] = 1;
        }
    }

    function verified(uint256 num) private {
        require(num > 0, 'WGGE011');
        require(msg.value >= PRICE * num, 'WGGE002');
        if (msg.value > PRICE * num) {
            payable(msg.sender).transfer(msg.value - PRICE * num);
        }
        require(totalSupply() + num <= maxTotalSupply, "WGGE003");
        require(tx.origin == msg.sender, "WGGE007");
    }

    function setSignerOfNum(address signer, uint256 num) external onlyOwner {
        _signerOfNum[signer] = num;
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
        require(address(this).balance > 0, "WGGE005");
        Address.sendValue(payable(owner()), address(this).balance);
        emit PaymentReleased(owner(), address(this).balance);
    }
}
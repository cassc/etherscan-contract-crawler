//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFT808Club is ERC721A, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 808;
    uint256 public constant PRICE = 0.12 ether;
    uint256 public constant MAX_MINT_AMOUNT = 2;

    uint256 public presaleAt;
    uint256 public launchAt;
    address public presaleSigner;

    bool public operational = true;
    mapping(address => uint256) public addressMintBalance;

    constructor(
        string memory baseURI_,
        uint256 presaleAt_,
        uint256 launchAt_,
        address presaleSigner_
    ) ERC721A("808Club", "808Club") {
        _baseTokenURI = baseURI_;

        presaleAt = presaleAt_;
        launchAt = launchAt_;
        presaleSigner = presaleSigner_;
    }

    modifier mintValidation(uint256 _mintQty) {
        uint256 supply = totalSupply();
        require(operational, "Operation is paused");
        require(_mintQty > 0, "Must mint minimum of 1 token");
        require(supply + _mintQty <= MAX_SUPPLY, "Exceeds maximum token supply");
        require(msg.value == _mintQty * PRICE, "Amount of Ether sent is not correct");

        uint256 ownerMintedCount = addressMintBalance[msg.sender];
        require(ownerMintedCount + _mintQty <= MAX_MINT_AMOUNT, "Max NFT per address exceeded");
        _;
    }

    function isPresale() public view returns (bool) {
        return block.timestamp >= presaleAt && block.timestamp < launchAt;
    }

    function isLaunched() public view returns (bool) {
        return block.timestamp >= launchAt;
    }

    function presaleMint(
        uint256 _mintQty,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external payable mintValidation(_mintQty) {
        require(block.timestamp >= presaleAt, "Presale has not begun");
        require(block.timestamp < launchAt, "Presale has ended");

        bytes32 digest = keccak256(abi.encode(msg.sender));

        require(_validMint(presaleSigner, digest, r, s, v), "Invalid mint signature");

        addressMintBalance[msg.sender] += _mintQty;
        
        _mint(msg.sender, _mintQty);
    }

    function launchMint(uint256 _mintQty) external payable mintValidation(_mintQty) {
        require(block.timestamp >= launchAt, "Public sale has not begun");
        
        addressMintBalance[msg.sender] += _mintQty;
        
        _mint(msg.sender, _mintQty);
    }

    function devMint(uint256 _mintQty) external onlyOwner {
        uint256 supply = totalSupply();

        require(supply + _mintQty <= MAX_SUPPLY, "Exceeds maximum token supply");
        
        _mint(msg.sender, _mintQty);
    }

    function _validMint(
        address administrator,
        bytes32 digest,
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        internal view
        returns (bool)
    {
        address signer = ecrecover(digest, v, r, s);
        return signer == administrator;
    }

    function setPresaleAt(uint256 value) external onlyOwner {
        presaleAt = value;
    }

    function setLaunchAt(uint256 value) external onlyOwner {
        launchAt = value;
    }

    function toggleOperational() external onlyOwner {
        operational = !operational;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    address private constant creatorAddress = 0x164A08A26F2a7f06387dDA1b7FE2BcB2fb1599c2;

    function withdraw() external onlyOwner {
        (bool success, ) = creatorAddress.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}
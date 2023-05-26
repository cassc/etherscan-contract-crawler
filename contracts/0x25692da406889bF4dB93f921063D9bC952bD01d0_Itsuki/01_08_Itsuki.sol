//SPDX-License-Identifier: None
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Itsuki is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
    string private baseURI;

    uint256 public maxMintAllowlistSale = 3;
    uint256 public maxMintpublicSale = 6;

    uint256 public publicCost = 0.025 ether;
    uint256 public allowlistCost = 0.02 ether;
    uint256 public maxSupply = 6666;

    bool public publicSaleActive = false;
    bool public allowlistSaleActive = false;
    bool public burningActive = false;

    address public withdrawAddress = 0x820180d4F6C951Bb4D5D2aeb585eB2202D0FfbD6;

    address internal signerAddress = 0x95e85283EF094097b1b1638074594ba234C0dD5D;


    mapping(bytes => bool) internal signatureUsed;

    mapping(address => uint256) internal AllowlistTokens;
    mapping(address => uint256) internal PublicSaleTokens;


    constructor(string memory _initBaseUri) ERC721A("Itsuki", "$ITSUKI") {
        setBaseURI(_initBaseUri);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function reserve(uint256 _mintNum) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintNum <= maxSupply, "Supply Limit Reached");
        _safeMint(msg.sender, _mintNum);
    }

    function getCost() public view returns (uint256) {
        if (msg.sender == owner()) {
            return 0;
        } else {
            if (publicSaleActive) {
                return publicCost;
            } else if (allowlistSaleActive) {
                return allowlistCost;
            } else {
                return 0;
            }
        }
    }

    function getAllowedTokens() public view returns (uint256) {
        if (publicSaleActive) {
            return (maxMintpublicSale - PublicSaleTokens[msg.sender]);
        } else if (allowlistSaleActive) {
            return (maxMintAllowlistSale - AllowlistTokens[msg.sender]);
        } else {
            return 0;
        }
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function getNFT(
        uint256 _mintNum,
        bytes32 hash,
        bytes memory signature
    ) public payable callerIsUser {
        uint256 supply = totalSupply();
        uint256 cost = getCost();
        uint256 allowedToMint = getAllowedTokens();

        require(allowlistSaleActive || publicSaleActive, "not ready for sale");
        require(supply + _mintNum <= maxSupply, "Supply Limit Reached");
        require(
            recoverSigner(hash, signature) == signerAddress,
            "User not allowed to mint tokens"
        );
        require(!signatureUsed[signature], "Signature has already been used.");
        require(
            allowedToMint >= _mintNum,
            "Can't mint more than allowed amount"
        );
        require(msg.value >= cost * _mintNum, "Not Enough Tokens");

        if (allowlistSaleActive) {
            _safeMint(msg.sender, _mintNum);
            AllowlistTokens[msg.sender] += _mintNum;
        } else if (publicSaleActive) {
            _safeMint(msg.sender, _mintNum);
            PublicSaleTokens[msg.sender] += _mintNum;
        }
        signatureUsed[signature] = true;
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

    function withdrawAll() external onlyOwner nonReentrant {
        (bool success, ) = payable(withdrawAddress).call{
            value: (address(this).balance)
        }("");
        require(success, "Failed to Send Ether");
    }

    function burnMany(uint256[] calldata tokenIds) external onlyOwner {
        require(burningActive, "Can't burn tokens");
        for (uint i; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    //only owner
    function setBurnActive(bool _state) external onlyOwner {
        burningActive = _state;
    }

    function setPublicCost(uint256 _newCost) external onlyOwner {
        publicCost = _newCost;
    }

    function setallowlistCost(uint256 _newCost) external onlyOwner {
        allowlistCost = _newCost;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply < maxSupply,"Can't set max supply more than the orignal value");
        require(_maxSupply > totalSupply(),"Can't set max supply less than total supply");
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setpublicSale(bool _state) external onlyOwner {
        publicSaleActive = _state;
    }

    function setallowlistSale(bool _state) external onlyOwner {
        allowlistSaleActive = _state;
    }

    function setmaxMintallowlisted(uint256 _num) external onlyOwner {
        maxMintAllowlistSale = _num;
    }

    function setmaxMintpublicSale(uint256 _num) external onlyOwner {
        maxMintpublicSale = _num;
    }

    function SetPayoutAddress(address _payoutAddress) external onlyOwner{
        withdrawAddress = _payoutAddress;
    }

    function SetSignerAddress(address _newSignerAddress) external onlyOwner{
        signerAddress = _newSignerAddress;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract FeudalzLandz is ERC721, EIP712, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    Counters.Counter private _tokenIdCounter;
    address _signerAddress;
    string _baseUri;
    string _contractUri;
    
    mapping (address => uint) public accountToMintedFreeTokens;

    uint public maxSupply = 4444;
    bool public isSalesActive = true;
    uint public price;
    
    constructor() ERC721("Feudalz Landz", "Landz") EIP712("LANDZ", "1.0.0") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _signerAddress = 0x42bC5465F5b5D4BAa633550e205A1d7D81e6cACf;
        _contractUri = "ipfs://QmWBU1tS2GwVGB5gcwRQqYC9Ec4d3WPWLCXDrK8ReZhLEj";
        price = 10 ether;
        _baseUri = "https://server.feudalz.io/landz/";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(uint quantity) external payable {
        require(isSalesActive, "sale is not active");
        require(totalSupply() + quantity <= maxSupply, "sold out");
        require(msg.value >= price * quantity, "ether sent is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function mint(uint quantity, address receiver) external onlyRole(ADMIN_ROLE) {
        require(totalSupply() + quantity <= maxSupply, "sold out");

        for (uint i = 0; i < quantity; i++) {
            safeMint(receiver);
        }
    }

    function freeMint(uint quantity, uint maxFreeMints, bytes calldata signature) external {
        require(recoverAddress(msg.sender, maxFreeMints, signature) == _signerAddress, "user cannot mint");
        require(isSalesActive, "sale is not active");
        require(totalSupply() + quantity <= maxSupply, "quantity exceeds max supply");
        require(quantity + accountToMintedFreeTokens[msg.sender] <= maxFreeMints, "quantity exceeds allowance");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
        
        accountToMintedFreeTokens[msg.sender] += quantity;
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyRole(ADMIN_ROLE) {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyRole(ADMIN_ROLE) {
        _contractUri = newContractURI;
    }
    
    function toggleSales() external onlyRole(ADMIN_ROLE) {
        isSalesActive = !isSalesActive;
    }
    
    function setPrice(uint newPrice) external onlyRole(ADMIN_ROLE) {
        price = newPrice;
    }
    
    function setMaxSupply(uint newMaxSupply) external onlyRole(ADMIN_ROLE) {
        maxSupply = newMaxSupply;
    }
    
    function withdrawAll() external onlyRole(ADMIN_ROLE) {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _hash(address account, uint maxFreeMints) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFT(uint256 maxFreeMints,address account)"),
                        maxFreeMints,
                        account
                    )
                )
            );
    }

    function recoverAddress(address account, uint maxFreeMints, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, maxFreeMints), signature);
    }

    function setSignerAddress(address signerAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _signerAddress = signerAddress;
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
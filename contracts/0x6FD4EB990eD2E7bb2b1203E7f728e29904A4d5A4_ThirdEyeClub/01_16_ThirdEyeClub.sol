// SPDX-License-Identifier: MIT

/**
Third Eye Club is a brand bridging the digital and physical world together with a focus on clothing, art and culture.

Twitter: twitter.com/thirdeyeclubnft
Website: www.thirdeyeclub.io
Mint: mint.thirdeyeclub.io

                                       @@@@@@@                                  
                                     @@@@@@@ .                                  
                                    [email protected]@@@@@@@  @                                
                                        @@@@@  &                                
                                     @@@@@@@@@ #                                
                                      @@@@@@*@                                  
                                                                                
                        @@@@  @@                     @@@@                       
                       @@@@@@@  &@                 @@@  @ @                     
                     @@@@@@@@@@  & ,              @@@@@@   @                    
                     @@@@@@@@@@@   #              @@@@@@@ @                     
                        @@@@@@@@    @                @@@@   @                   
                         @@@@@@@    @              @@@@@@   %                   
                      @@@@@@@@@@    @*            @@@@@@@  @                    
                     @@@@@@@@@@@  @ @              @@@@@  @(                    
                      @@@@@@@@@@   @@                @@@@@                      
                       @@@@@@@@   @@                                            
                        @@@@@@  %@/                                             
                            @@@                                                 
                                                                                
                                                                                
                                                         @@@@@                  
                     @@@                                    @                   
                   @@@                                     @                    
                 /,  @                                                          
                 .     @                                @                       
                          @                          @@                         
                             &@                  @@@                            
                                 ,@@@@@@.  %@@@@                                
                                                                                
*/
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import './EIP2981/ERC2981.sol';
import './OpenSea.sol';

contract ThirdEyeClub is ERC721A, Ownable, ERC2981 {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    enum SaleStatus {
        ON_PAUSE,
        ONLY_WHITELIST,
        PUBLIC,
        CLOSED
    }

    string _baseTokenURI;
    uint16 public constant MAX_SUPPLY = 9333;
    uint8 public maxPerAddress = 2;
    uint8 private reserved = 70;
    bool private metadataIsLocked = false;
    SaleStatus private saleStatus = SaleStatus.ON_PAUSE;
    uint208 private price = 0.08 ether;
    bytes32 private whitelistMerkleRoot;
    address public proxyRegistryAddress;

    modifier canMint(uint256 num) {
        require(totalSupply() + num <= MAX_SUPPLY - reserved, "Exceeds max supply" );
        require(msg.value >= price * num, "ETH sent not correct" );
        require(numberMinted(msg.sender) + num <= maxPerAddress, "maxPerAddress reach");
        _;
    }

    constructor(string memory baseURI, address royaltyRecipient, uint256 royaltyValue, address _proxyRegistryAddress) ERC721A("Third Eye Club", "TEC")  {
        setBaseURI(baseURI);
        setRoyalties(royaltyRecipient, royaltyValue);
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
        return super.isApprovedForAll(_owner, _operator);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    function publicSaleMint(uint256 num) public payable canMint(num) {
        require(saleStatus == SaleStatus.PUBLIC, "Public sale not started" );
        _safeMint(msg.sender, num);
    }

    function whitelistMint(uint256 num, bytes32[] calldata proof) public payable canMint(num) {
        require(saleStatus == SaleStatus.ONLY_WHITELIST, "Whitelist sale not started" );
        require(isWhitelisted(msg.sender, proof), "address not whitelisted" );
        _safeMint(msg.sender, num);
    }

    function reserveMint(address _to, uint8 _amount) external onlyOwner {
        require(_amount <= reserved, "Exceeds reserved supply" );
        reserved -= _amount;
        _safeMint(_to, _amount);
    }

    function setPrice(uint208 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxPerAddress(uint8 _newMaxPerAddress) public onlyOwner {
        require(_newMaxPerAddress >= maxPerAddress, "could not be less than previous value");
        maxPerAddress = _newMaxPerAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!metadataIsLocked, "BaseURI is locked forever");
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract.json"));
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setWhitelistMerkleRoot(bytes32 root) public onlyOwner {
        whitelistMerkleRoot = root;
    }

    function isWhitelisted(address account, bytes32[] memory proof) public view returns (bool) {
        return proof.verify(whitelistMerkleRoot, keccak256(abi.encodePacked(account)));
    }

    function lockMetadata() public onlyOwner {
        metadataIsLocked = true;
    }

    function getSaleStatus() public view returns (SaleStatus) {
        return saleStatus;
    }

    function setSaleStatus(SaleStatus status) public onlyOwner {
        saleStatus = status;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdrawAll() public payable onlyOwner {
        uint sale = address(this).balance;
        require(payable(msg.sender).send(sale));
    }
}
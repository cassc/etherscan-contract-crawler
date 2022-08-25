// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract NoNameCharli is Ownable, Pausable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public root; 
    string private baseURI; 
    string private notRevealedURI;

    address private immutable proxyRegistryAddress; 

    uint256 private constant MAX_SALE_TIMESTAMP = 2**256 - 1;
    uint256 public startPreSaleTimestamp = MAX_SALE_TIMESTAMP;
    uint256 public endPreSaleTimestamp = MAX_SALE_TIMESTAMP;
    uint256 public startPublicSaleTimestamp = MAX_SALE_TIMESTAMP;
    uint256 public revealTimestamp = MAX_SALE_TIMESTAMP;

    uint256 public immutable mintAmountLimit; 
    uint256 public immutable maxSupply; 
    uint256 private externalSupply; 
    uint256 private marketingSupply; 

    uint256 public constant _presalePrice = 0.25 ether;
    uint256 public constant _publicsalePrice = 0.35 ether;

    constructor(
        address _proxyRegistryAddress,
        uint256 _mintAmountLimit,
        uint256 _maxSupply,
        uint256 _externalSupply,
        uint256 _marketingSupply
    )
        ERC721A("NoNameCharli", "NNC", _mintAmountLimit, _maxSupply)
    {
        require(
            (_externalSupply + _marketingSupply) == _maxSupply,
            "Invalid supply values provided."
        );
        mintAmountLimit = _mintAmountLimit;
        maxSupply = _maxSupply;
        externalSupply = _externalSupply;
        marketingSupply = _marketingSupply;
        
        require(_proxyRegistryAddress != address(0), "Invalid proxy registry address!");
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    modifier onlyAccounts() {
        require(
            msg.sender == tx.origin,
            "Not allowed origin (caller is another contract)"
        );
        _;
    }

    function updateSaleTimestamp(
        uint256 _startPreSaleTimestamp,
        uint256 _endPreSaleTimestamp,
        uint256 _startPublicSaleTimestamp,
        uint256 _revealTimestamp
    ) external onlyOwner {
        require(_startPreSaleTimestamp <= _endPreSaleTimestamp, "Start presale must be before end presale.");
        require(_endPreSaleTimestamp <= _startPublicSaleTimestamp, "End presale must be before start public sale.");
        require(_startPublicSaleTimestamp <= _revealTimestamp, "Start public sale must be before reveal.");
        
        startPreSaleTimestamp = _startPreSaleTimestamp;
        endPreSaleTimestamp = _endPreSaleTimestamp;
        startPublicSaleTimestamp = _startPublicSaleTimestamp;
        revealTimestamp = _revealTimestamp;
    }

    function getSaleStatus() public view returns (uint256) {
        if (
            revealTimestamp == 0 ||
            startPublicSaleTimestamp == 0 ||
            endPreSaleTimestamp == 0 ||
            startPreSaleTimestamp == 0
        ) {
            return 5; 
        }

        uint256 _currTimestamp = block.timestamp;
        if (_currTimestamp >= revealTimestamp) {
            return 4; 
        } else if (_currTimestamp >= startPublicSaleTimestamp) {
            return 3;
        } else if (_currTimestamp >= endPreSaleTimestamp) {
            return 2; 
        } else if (_currTimestamp >= startPreSaleTimestamp) {
            return 1; 
        } else {
            return 0; 
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        external
        onlyOwner
    {
        notRevealedURI = _notRevealedURI;
    }
    
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        root = _merkleRoot;
    }

    function presaleMint(uint256 _amount, bytes32[] calldata _proof)
        external
        payable
        onlyAccounts
        nonReentrant
    {   
        require(!paused(), "The contract is paused."); 
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, root, _leaf), "Invalid proof!");
        require(getSaleStatus() == 1, "It's not time for presale.");
        require(_amount > 0, "Must mint more than 0"); 
        require(
            _amount <= externalSupply,
            "presale mint amount exceeds supply left for external accounts"
        );
        require(totalSupply() + _amount <= maxSupply, "Max supply exceeded");
        require(
            numberMinted(msg.sender) + _amount <= mintAmountLimit,
            "Mint amount limit exceeded"
        );

        uint256 _totalCost = _presalePrice * _amount;
        require(msg.value >= _totalCost, "Not enough ETH sent");

        externalSupply -= _amount;
        _safeMint(msg.sender, _amount);
    }

    function publicSaleMint(uint256 _amount)
        external
        payable
        onlyAccounts
        nonReentrant
    {
        require(!paused(), "The contract is paused"); 
        uint256 _saleStatus = getSaleStatus();
        require(
            _saleStatus == 3 || _saleStatus == 4,
            "It's not time for public sale."
        );
        require(_amount > 0, "Must mint more than 0"); 
        require(
            _amount <= externalSupply,
            "public sale mint amount exceeds supply left for external accounts"
        );
        require(totalSupply() + _amount <= maxSupply, "Max supply exceeded");
        require(
            numberMinted(msg.sender) + _amount <= mintAmountLimit,
            "Mint amount limit exceeded"
        );

        uint256 _totalCost = _publicsalePrice * _amount;
        require(msg.value >= _totalCost, "Not enough ETH sent");

        externalSupply -= _amount;
        _safeMint(msg.sender, _amount);
    }

    function marketingMint(uint256 _quantity, address payable _account)
        external
        onlyOwner
        nonReentrant
    {   
        require(_quantity <= mintAmountLimit, "Cannot mint more than limit at once.");

        require(!paused(), "The contract is paused"); 
        require(getSaleStatus() < 5, "Invalid sale status (timestamps).");
        require(
            _quantity > 0,
            "marketing mint quantity must be greater than 0"
        ); 
        require(
            _quantity <= marketingSupply,
            "marketing mint amount exceeds supply left for marketing"
        );
        require(
            totalSupply() + _quantity <= maxSupply,
            "marketing mint exceeds maxSupply"
        );
    
        marketingSupply -= _quantity;
        _safeMint(_account, _quantity); // affects numberMinted() 
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (getSaleStatus() != 4) {
            return 
                bytes(notRevealedURI).length > 0 
                    ? string(
                        abi.encodePacked(
                            notRevealedURI,
                            tokenId.toString()
                        )
                    )
                    : "";
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString()
                    )
                )
                : "";
    }

    function numberMinted(address ownerAddr) public view returns (uint256) {
        return _numberMinted(ownerAddr);
    }

    function isApprovedForAll(address ownerAddr, address opAddr)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        _ProxyRegistry proxyRegistry = _ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(ownerAddr)) == opAddr) {
            return true;
        }

        return super.isApprovedForAll(ownerAddr, opAddr);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function getProxyRegistryAddress() public view returns (address) {
        return proxyRegistryAddress;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function pause() public onlyOwner {
        Pausable._pause();
    }

    function unpause() public onlyOwner {
        Pausable._unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!paused(), "Contract paused");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}

contract _OwnableDelegateProxy {}

contract _ProxyRegistry {
    mapping(address => _OwnableDelegateProxy) public proxies;
}
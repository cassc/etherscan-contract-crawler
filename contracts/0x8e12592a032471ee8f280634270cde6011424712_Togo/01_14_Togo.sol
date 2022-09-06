// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract Togo is ERC721A,Ownable,Pausable {
    using Strings for uint256;

    string  public baseTokenURI;
    string  public defaultTokenURI;
    uint256 public maxSupply;
    uint256 public publicSalePrice;
    uint8 public accountFree;
    mapping(address => uint256) public usermint;
    mapping(address => bool) public allowlistresult;

    bytes32 private _merkleRoot ;
    address payable public payMentPotatoz;

    constructor(
        string memory _baseTokenURI,
        uint   _maxSupply,
        uint   _publicSalePrice,
        uint8   _accountFree,
        bytes32 _MerkleRoot,
        address _paymentAddress
    ) ERC721A("Togo bot mint pass", "ToGo") {
        baseTokenURI = _baseTokenURI;
        maxSupply = _maxSupply;
        publicSalePrice = _publicSalePrice;
        accountFree = _accountFree;
        payMentPotatoz = payable(_paymentAddress);
        _merkleRoot = _MerkleRoot;
        _pause();
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint(uint256 _quantity) external callerIsUser payable whenNotPaused  {
        require(_quantity > 0, "Invalid quantity");
        require(_quantity <= 10, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");

        uint256 _remainFreeQuantity = 0;
        if (accountFree > usermint[msg.sender] ) {
            _remainFreeQuantity = accountFree - usermint[msg.sender];
        }

        uint256 _needPayPrice = 0;
        if (_quantity > _remainFreeQuantity) {
            _needPayPrice = (_quantity - _remainFreeQuantity) * publicSalePrice;
        }

        require(msg.value >= _needPayPrice, "Ether is not enough");
        if (msg.value>0) {
            Address.sendValue(payMentPotatoz, msg.value/100*50);
        }
        usermint[msg.sender]+=_quantity;
        _safeMint(msg.sender, _quantity);
    }


    function allowListMint(bytes32[] calldata merkleProof) external callerIsUser payable whenNotPaused {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _merkleRoot, leaf), "Invalid merkle proof");
        require(!allowlistresult[msg.sender], "This address has been allowlisted mint");
        allowlistresult[msg.sender]=true;
        _safeMint(msg.sender, 1);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0 ? string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                ".json"
            )
        ) : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setPublicPrice(uint256 mintprice) external onlyOwner {
        publicSalePrice = mintprice;
    }

    function setAccountFree(uint8 quantity) external onlyOwner {
        accountFree = quantity;
    }

    function setMaxSupply(uint256 quantity) external onlyOwner {
        maxSupply = quantity;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function openMint() public onlyOwner {
        _unpause();
    }

    function closeMint() public onlyOwner {
        _pause();
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function marketMint(address[] memory marketmintaddress,uint256[] memory mintquantity) public payable onlyOwner whenNotPaused {
        for (uint256 i = 0; i < marketmintaddress.length; i++) {
            require(totalSupply() + mintquantity[i] <= maxSupply, "Exceed supply");
            _safeMint(marketmintaddress[i], mintquantity[i]);
        }
    }

    function withdrawMoney() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }


}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LORD is Initializable, ERC721AUpgradeable, ReentrancyGuardUpgradeable {
    using Strings for uint256;

    address public owner;

    bytes32 public root;

    bool public paused;
    bool public whitelistStatus;

    uint256 public totalNFT;
    uint256 public mintPrice;
    uint256 public maxMintAmount;

    string public baseURI;
    string public baseExtension;

    mapping(address => uint256) public nftDetails;

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    modifier isNFTOwner(uint256[] calldata _tokenId) {
        require(_ismultipleTokenIdOwner(_tokenId), "You are not nft owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "contract paused");
        _;
    }

    modifier isPriceEqual(uint256 _price, uint256 _quantity) {
        require(_price >= mintPrice * _quantity, "amount not sufficient");
        _;
    }

    modifier isMaxNFT(uint256 quantity) {
        require(
            maxMintAmount >= (nftDetails[msg.sender] + quantity),
            "above max quantity"
        );
        _;
    }

    event LordMint(address to, uint256 quantity);
    event withdraw(address owner, uint256 amount);
    event PriceUpdate(address owner, uint256 newPrice);
    event UpdateOwner(address oldOwner, address newOwner);
    event BURN(address user, uint256[] tokenId);
    event UpdateBaseURI(string _newBaseURI);
    event UpdateMaxMintAmount(uint256 _newmaxMintAmount);
    event ChangeWhitelistStatus(bool status);
    event UpdateRoot(bytes32 root);
    event Pausable(bool _state);

    function initialize(
        address _owner,
        bytes32 _root,
        uint256 _totalNFT,
        uint256 _mintPrice,
        uint256 _maxMintAmount,
        string memory _initBaseURI,
        string memory _name,
        string memory _symbol,
        string memory _baseExtension
    ) external initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        owner = _owner;
        root = _root;
        baseURI = _initBaseURI;
        totalNFT = _totalNFT;
        mintPrice = _mintPrice;
        maxMintAmount = _maxMintAmount;
        baseExtension = _baseExtension;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdateOwner(msg.sender, owner);
    }

    function setTotalNFT(uint256 _totalNFT) external onlyOwner {
        require(_totalNFT > totalNFT, "not less than totalNFT");
        totalNFT = _totalNFT;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        emit UpdateBaseURI(_newBaseURI);
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner {
        maxMintAmount = _newmaxMintAmount;
        emit UpdateMaxMintAmount(_newmaxMintAmount);
    }

    function setWhitelistStatus(bool _status) external onlyOwner {
        whitelistStatus = _status;
        emit ChangeWhitelistStatus(_status);
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
        emit UpdateRoot(_root);
    }

    function pause(bool _state) external nonReentrant onlyOwner {
        paused = _state;
        emit Pausable(_state);
    }

    function updatePrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
        emit PriceUpdate(msg.sender, _price);
    }

    function ownerMint(address _to, uint256 _quantity)
        external
        payable
        nonReentrant
        onlyOwner
    {
        require(_to != address(0), "null address");
        require(totalNFT >= (_nextTokenId() + _quantity), "lord full");

        _safeMint(_to, _quantity);

        emit LordMint(_to, _quantity);
    }

    function burn(uint256[] calldata _tokenId) external isNFTOwner(_tokenId) {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            _burn(_tokenId[i]);
        }
        emit BURN(msg.sender, _tokenId);
    }

    function mint(
        address _to,
        uint256 _quantity,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        nonReentrant
        whenNotPaused
        isPriceEqual(msg.value, _quantity)
        isMaxNFT(_quantity)
    {
        require(_to != address(0), "null address");
        require(_quantity <= maxMintAmount && _quantity > 0, "zero quantity");
        require(totalNFT >= (_nextTokenId() + _quantity), "lord full");

        if (!whitelistStatus) {
            bytes32 leafToCheck = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProofUpgradeable.verify(_merkleProof, root, leafToCheck),
                "Incorrect proof"
            );
        }

        nftDetails[msg.sender] += _quantity;

        _safeMint(_to, _quantity);

        emit LordMint(_to, _quantity);
    }

    function withdrawFunds(uint256 _amount) external nonReentrant onlyOwner {
        require(
            _amount != 0 && address(this).balance >= _amount,
            "amount is not sufficient"
        );

        (bool success, ) = owner.call{value: _amount}("");
        require(success, "refund failed");

        emit withdraw(owner, _amount);
    }

    function multipleNFTTransfer(
        address from,
        address to,
        uint256[] memory tokenId
    ) external {
        require(tokenId.length != 0, "length not zero");
        for (uint256 i = 0; i < tokenId.length; i++) {
            safeTransferFrom(from, to, tokenId[i]);
        }
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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        "/",
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _ismultipleTokenIdOwner(uint256[] calldata _tokenId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            require(
                msg.sender == ownerOf(_tokenId[i]),
                "You are not nft owner"
            );
        }

        return true;
    }
}
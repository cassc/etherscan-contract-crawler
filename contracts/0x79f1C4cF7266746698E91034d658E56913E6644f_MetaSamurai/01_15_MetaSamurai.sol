// SPDX-License-Identifier: MIT

/*

███╗   ███╗███████╗████████╗ █████╗ ███████╗ █████╗ ███╗   ███╗██╗   ██╗██████╗  █████╗ ██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔══██╗████╗ ████║██║   ██║██╔══██╗██╔══██╗██║
██╔████╔██║█████╗     ██║   ███████║███████╗███████║██╔████╔██║██║   ██║██████╔╝███████║██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║╚════██║██╔══██║██║╚██╔╝██║██║   ██║██╔══██╗██╔══██║██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║  ██║██║  ██║██║
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./libraries/ERC2981ContractWideRoyalties.sol";

contract MetaSamurai is ERC721A, Ownable, ERC2981ContractWideRoyalties {
    using Strings for uint256;

    string private _baseTokenURI =
        "ipfs://QmP7dha48UX9VVHsipngVFWfMbQyPvaE5XhjTmn8nFWxz4/";

    uint256 public maxSupply = 3333;
    uint256 public ALSalePrice = 0.05 ether;
    uint256 public publicSalePrice = 0.07 ether;
    uint256 public immutable maxMintAmountPerMint;

    bool public isPublicSaleActive;
    bool public isALSaleActive;
    bool public isFLSaleActive;
    bool public isFrozen;

    // Allow list amount
    mapping(address => uint256) private ALAmountLeft;
    // Free list amount
    mapping(address => uint256) private FLAmountLeft;

    event MintAmount(
        uint256 _mintAmountLeft,
        uint256 _totalSupply,
        address _minter
    );

    constructor(
        string memory _tokenName,
        string memory _symbolName,
        uint256 _maxMintAmountPerMint
    ) ERC721A(_tokenName, _symbolName, _maxMintAmountPerMint) {
        require(
            _maxMintAmountPerMint > 0,
            "maxMintAmountPerMint must be bigger than 0"
        );
        maxMintAmountPerMint = _maxMintAmountPerMint;
        setRoyaltyInfo(msg.sender, 750); // 750 == 7.5%
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Must mint at least 1");
        require(
            _mintAmount <= maxMintAmountPerMint,
            string(
                abi.encodePacked(
                    "Max mint amount per mint is ",
                    maxMintAmountPerMint.toString()
                )
            )
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Must mint within max supply"
        );
        _;
    }

    modifier saleCompliance(
        bool _isSaleActive,
        uint256 _mintPrice,
        uint256 _mintAmount
    ) {
        require(_isSaleActive == true, "The sale is not active yet!");
        require(
            msg.value >= _mintPrice * _mintAmount,
            "The value is not enough."
        );
        _;
    }

    modifier whenNotFrozen() {
        require(isFrozen == false, "The contract is already frozen.");
        _;
    }

    function freezeMetadata() external onlyOwner {
        require(isFrozen == false, "Metadata ia already frozen!");
        isFrozen = true;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function allowListMint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        saleCompliance(isALSaleActive, ALSalePrice, _mintAmount)
    {
        address minter = msg.sender;
        require(
            ALAmountLeft[minter] - _mintAmount >= 0,
            "You dont have enough AL amounts"
        );
        _safeMint(minter, _mintAmount);
        ALAmountLeft[minter] -= _mintAmount;
        emit MintAmount(ALAmountLeft[minter], totalSupply(), minter);
    }

    function publicListMint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        saleCompliance(isPublicSaleActive, publicSalePrice, _mintAmount)
    {
        address minter = msg.sender;
        _safeMint(minter, _mintAmount);
        emit MintAmount(0, totalSupply(), minter);
    }

    function freeListMint(uint256 _mintAmount)
        public
        mintCompliance(_mintAmount)
    {
        address minter = msg.sender;
        require(
            FLAmountLeft[minter] - _mintAmount >= 0,
            "You dont have enough FL amounts"
        );
        require(isFLSaleActive, "The sale is not active yet");
        _safeMint(minter, _mintAmount);
        FLAmountLeft[minter] -= _mintAmount;
        emit MintAmount(FLAmountLeft[minter], totalSupply(), minter);
    }

    function ownerMint(address _receiver, uint256 _mintAmount)
        public
        onlyOwner
    {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Must mint within max supply"
        );

        uint256 mintCount = _mintAmount / maxMintAmountPerMint;
        uint256 remainderMintAmount = _mintAmount % maxMintAmountPerMint;

        for (uint256 i = 0; i < mintCount; i++) {
            _safeMint(_receiver, maxMintAmountPerMint);
        }
        if (remainderMintAmount > 0) _safeMint(_receiver, remainderMintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function getALAmountLeft(address _address) public view returns (uint256) {
        return ALAmountLeft[_address];
    }

    function getFLAmountLeft(address _address) public view returns (uint256) {
        return FLAmountLeft[_address];
    }

    function setMaxSupply(uint256 _newMaxSupply)
        public
        whenNotFrozen
        onlyOwner
    {
        maxSupply = _newMaxSupply;
    }

    function setALSalePrice(uint256 _newALSalePrice) public onlyOwner {
        ALSalePrice = _newALSalePrice;
    }

    function setPublicSalePrice(uint256 _newPublicSalePrice) public onlyOwner {
        publicSalePrice = _newPublicSalePrice;
    }

    function setAllowList(
        address[] memory _ALArray,
        uint256[] memory _mintAmountArray
    ) external onlyOwner {
        require(
            _ALArray.length == _mintAmountArray.length,
            "ALArray does not mutch mintAmountArray length"
        );
        for (uint256 i = 0; i < _ALArray.length; i++) {
            ALAmountLeft[_ALArray[i]] = _mintAmountArray[i];
        }
    }

    function setFreeList(
        address[] memory _FLArray,
        uint256[] memory _mintAmountArray
    ) external onlyOwner {
        require(
            _FLArray.length == _mintAmountArray.length,
            "FLArray does not mutch mintAmountArray length"
        );
        for (uint256 i = 0; i < _FLArray.length; i++) {
            FLAmountLeft[_FLArray[i]] = _mintAmountArray[i];
        }
    }

    function setRoyaltyInfo(address _royaltyAddress, uint256 _percentage)
        public
        onlyOwner
    {
        _setRoyalties(_royaltyAddress, _percentage);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function togglePublicSale() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function toggleALSale() public onlyOwner {
        isALSaleActive = !isALSaleActive;
    }

    function toggleFLSale() public onlyOwner {
        isFLSaleActive = !isFLSaleActive;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw is failed!!");
    }
}
// SPDX-License-Identifier: CONSTANTLY WANTS TO MAKE THE WORLD BEAUTIFUL

pragma solidity ^0.8.0;

// @title: GLIXITIES
// @creator: @berkozdemir - berk.eth
// @author: @berkozdemir - berk.eth
// @author: @devbhang - devbhang.eth
// @advisor: @hazelrah_nft - hazelrah.eth

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface IGLIX {
    function burn(address from, uint256 amount) external returns (bool);
}

contract GLIXITIES is ERC721AQueryable, ERC2981, Ownable, DefaultOperatorFilterer {

    using Strings for uint256;

    enum SaleStatus {
        NoSale,
        PreSale,
        PublicSale,
        SaleFinished
    }

    SaleStatus saleStatus = SaleStatus.NoSale;

    string public baseURI;

    bytes32 private _merkleRoot;

    address public treasuryAddress;

    address constant GLIXTOKEN_ADDRESS = 0x4e09d18baa1dA0b396d1A48803956FAc01c28E88;
    
    uint256 public saleStartTime;

    uint256 public etherMinPrice;
    uint256 public etherMaxPrice;
    uint256 public DISCOUNT_TIME; 

    uint256 public glixPrice;
    uint256 public glixMintMax;
    uint256 public glixMinted;

    // PARCEL TYPES 
    uint256 constant TOTAL_PARCEL_TYPES = 36;

    // MAPPING
    mapping (uint256 => uint256) public parcelSizeToAmount;
    mapping (uint256 => uint256) public parcelSizeToMinted;
    
    event ParcelSize(address indexed to, uint256 tokenId, uint256 parcelType, uint256 parcelTypeCounter);
    constructor() ERC721A("GLIXITIES", "GLIXITIES") {
        parcelSizeToAmount[0] = 1268; 
        parcelSizeToAmount[1] = 235;
        parcelSizeToAmount[2] = 111; 
        parcelSizeToAmount[3] = 48; 
        parcelSizeToAmount[4] = 28; 
        parcelSizeToAmount[5] = 13; 
        parcelSizeToAmount[6] = 242; 
        parcelSizeToAmount[7] = 81; 
        parcelSizeToAmount[8] = 28; 
        parcelSizeToAmount[9] = 15; 
        parcelSizeToAmount[10] = 15; 
        parcelSizeToAmount[11] = 8; 
        parcelSizeToAmount[12] = 119; 
        parcelSizeToAmount[13] = 24; 
        parcelSizeToAmount[14] = 14;
        parcelSizeToAmount[15] = 10;
        parcelSizeToAmount[16] = 5; 
        parcelSizeToAmount[17] = 6; 
        parcelSizeToAmount[18] = 55; 
        parcelSizeToAmount[19] = 15;
        parcelSizeToAmount[20] = 5; 
        parcelSizeToAmount[21] = 7; 
        parcelSizeToAmount[22] = 2; 
        parcelSizeToAmount[23] = 4; 
        parcelSizeToAmount[24] = 31;
        parcelSizeToAmount[25] = 9;
        parcelSizeToAmount[26] = 7;
        parcelSizeToAmount[27] = 4; 
        parcelSizeToAmount[28] = 5; 
        parcelSizeToAmount[29] = 1;
        parcelSizeToAmount[30] = 16;
        parcelSizeToAmount[31] = 8; 
        parcelSizeToAmount[32] = 1;
        parcelSizeToAmount[33] = 2; 
        parcelSizeToAmount[34] = 4; 
        parcelSizeToAmount[35] = 1;
    }

    /**
     * @dev Calculates the land size from parcelSizeToAmount and gets the total price of the land
     * i.e: parcelSizeToAmount[7] = 2x2 = 4
     * parcelSizeToAmount[34] = 6x5 = 30
     */
    function calculateSizeToPriceFactor(uint256 parcelType) public pure returns (uint256) {
        return (parcelType / 6 + 1) * (parcelType % 6 + 1);
    }


    /**
     * @dev During public sale, price goes from 0.1 to 0.025 in 24 hours
     */
    function getPrice() public view returns (uint) {
        uint elapsed = block.timestamp - saleStartTime;
        if (elapsed >= DISCOUNT_TIME) {
            return etherMinPrice;
        } else {
            return ((DISCOUNT_TIME - elapsed) * (etherMaxPrice - etherMinPrice) / DISCOUNT_TIME) + etherMinPrice;
        }
    }

    /**
     * @dev Admin functions
     */

    function setRoyalty(address _address, uint96 _royalty) external onlyOwner {
        treasuryAddress = _address;
        _setDefaultRoyalty(_address, _royalty);
    }

    function setSaleStatus(uint256 _saleStatus, bytes32 _root) external onlyOwner {
        saleStatus = SaleStatus(_saleStatus);
        saleStartTime = block.timestamp;
        _merkleRoot = _root;
    }

    function changeGlixPrice(uint256 _price, uint256 _glixMintMax) external onlyOwner {
        glixPrice = _price;
        glixMintMax = _glixMintMax;
    }

    function changeEtherPrice(uint256 _minPrice, uint256 _maxPrice, uint256 _time) external onlyOwner {
        etherMinPrice = _minPrice;
        etherMaxPrice = _maxPrice;
        DISCOUNT_TIME = _time;
    }

    /**
     * @dev Mint functions
     */

    function mintAdmin(address[] calldata _to, uint256[] calldata _amount, uint256[] calldata _parcelSize) external onlyOwner {
        require(_to.length == _amount.length && _parcelSize.length == _amount.length, "DATA LENGTHS MUST MATCH");

        for (uint256 i = 0; i < _amount.length; i++) {
            uint256 _tokenId = totalSupply();
            uint256 _size = _parcelSize[i];
            uint256 _currentAmount = _amount[i];

            require(_size < TOTAL_PARCEL_TYPES, string(abi.encodePacked("NON EXISTENT PARCEL SIZE: ", _size.toString())));
            require(parcelSizeToMinted[_size] + _currentAmount <= parcelSizeToAmount[_size], string(abi.encodePacked("NOT ENOUGH SUPPLY OF PARCEL SIZE: ", _size.toString())));

            for (uint256 j = 0; j < _currentAmount; j++) {
                emit ParcelSize(_to[i], _tokenId + j, _size, parcelSizeToMinted[_size] + j);
            }

            unchecked { parcelSizeToMinted[_size] += _currentAmount; }

            _mint(_to[i], _currentAmount);
        }
    }

    function _mintToken(uint256[] calldata _amount, uint256[] calldata _parcelSize, bool _isGlix) internal virtual {
        require(tx.origin == msg.sender, "ONLY HUMANS ALLOWED");
        require(_parcelSize.length == _amount.length, "DATA LENGTHS MUST MATCH");

        uint256 _tokenId = totalSupply();

        uint256 _totalMint;
        uint256 _totalPrice;

        for (uint256 i = 0; i < _amount.length; i++) {
            uint256 _size = _parcelSize[i];
            uint256 _currentAmount = _amount[i];

            require(_size < TOTAL_PARCEL_TYPES, string(abi.encodePacked("NON EXISTENT PARCEL SIZE: ", _size.toString())));
            require(parcelSizeToMinted[_size] + _currentAmount <= parcelSizeToAmount[_size], string(abi.encodePacked("NOT ENOUGH SUPPLY OF PARCEL SIZE: ", _size.toString())));

            for (uint256 j = 0; j < _currentAmount; j++) {
                emit ParcelSize(msg.sender, _tokenId + _totalMint + j, _size, parcelSizeToMinted[_size] + j);
            }

            unchecked {
                _totalMint += _currentAmount;
                _totalPrice += _currentAmount * calculateSizeToPriceFactor(_size);

                parcelSizeToMinted[_size] += _currentAmount;
            }
        }

        if (_isGlix) {
            require(glixMinted + _totalMint <= glixMintMax, "NO MORE GLIX MINT");
            require(
                IGLIX(GLIXTOKEN_ADDRESS).burn(
                    msg.sender, _totalPrice * glixPrice
                ),
                "NOT ENOUGH GLIX BURNED"
            );

            unchecked { glixMinted += _totalMint; }
        } else {
            // if (saleStatus == SaleStatus.PreSale) {
            //     require(msg.value >= _totalPrice * etherMinPrice, "NOT ENOUGH ETHERS SEND");
            // } else if (saleStatus == SaleStatus.PublicSale) {
                require(msg.value >= _totalPrice * getPrice(), "NOT ENOUGH ETHERS SEND");
            // }
        }

        _mint(msg.sender, _totalMint);
    }

    function mintPrivate(uint256[] calldata _amount, uint256[] calldata _parcelSize, bool _isGlix, bytes32[] calldata _merkleProof) external payable {
        require(saleStatus == SaleStatus.PreSale, "PRE SALE IS NOT OPEN");
        require(MerkleProof.verify(_merkleProof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))), "ADDRESS NOT WHITELISTED");

        _mintToken(_amount, _parcelSize, _isGlix);
    }

    function mintPublic(uint256[] calldata _amount, uint256[] calldata _parcelSize, bool _isGlix) external payable {
        require(saleStatus == SaleStatus.PublicSale, "PUBLIC SALE IS NOT OPEN");

        _mintToken(_amount, _parcelSize, _isGlix);
    }

    /**
     * @dev Functions for dApp
     */

    function getSaleStatus() public view returns (SaleStatus) {
        return saleStatus;
    }

    function viewParcelSizeToMinted() public view returns(uint256[TOTAL_PARCEL_TYPES] memory) {
        uint256[TOTAL_PARCEL_TYPES] memory _minted;

        for (uint256 i = 0; i < TOTAL_PARCEL_TYPES; i++) {
            _minted[i] = parcelSizeToMinted[i];
        }

        return _minted;
    }

    function viewParcelSizeToAmount() public view returns(uint256[TOTAL_PARCEL_TYPES] memory) {
        uint256[TOTAL_PARCEL_TYPES] memory _amount;

        for (uint256 i = 0; i < TOTAL_PARCEL_TYPES; i++) {
            _amount[i] = parcelSizeToAmount[i];
        }

        return _amount;
    }

    /**
     * @dev Set the base token URI
     */

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Withdraw tokens
     **/

    function withdrawTransfer() external onlyOwner {
        require(treasuryAddress != address(0), "YO BE CAREFUL MATE");
        payable(treasuryAddress).transfer(address(this).balance);
    }
    function withdrawCall() external onlyOwner {
        require(treasuryAddress != address(0), "YO BE CAREFUL MATE");
        (bool success,)=treasuryAddress.call{value:address(this).balance}("");
        require(success,"Transfer failed!");
    }

    /**
     * @dev Royalty enforcement
     **/

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Interface support
     */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";
import "./MintPassOptimized.sol";
import "./DerivedERC2981Royalty.sol";

abstract contract UriChanger is Ownable {
    address private _uriChanger;

    event UriChangerUpdated(address indexed previousAddress, address indexed newAddress);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _newUriChanger) {
        _updateUriChanger(_newUriChanger);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function uriChanger() internal view returns (address) {
        return _uriChanger;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyUriChanger() {
        require(uriChanger() == _msgSender(), "UriChanger: caller is not allowed");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function updateUriChanger(address newAddress) public virtual onlyOwner {
        require(newAddress != address(0), "UriChanger: Address required");
        _updateUriChanger(newAddress);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _updateUriChanger(address newAddress) internal virtual {
        address oldAddress = _uriChanger;
        _uriChanger = newAddress;
        emit UriChangerUpdated(oldAddress, newAddress);
    }
}

contract DerivedAPE is ERC721URIStorage, UriChanger, DerivedERC2981Royalty, IERC721Enumerable {

    using Strings for uint256;
    using Address for address;

    using Counters for Counters.Counter;

    struct ERC721s {
        address erc721;
        uint256 tokenId;
    }

    struct mintData {
        uint256 tokenId;
        uint256 mintpassId;
    }

    struct mintDataWithUri {
        uint256 tokenId;
        uint256 mintpassId;
        string tokenURI;
    }

    mapping(uint256 => ERC721s) private _parents;

    // relation of combined contract_and_id to tokenIds, kind of Enumerable
    mapping(uint256 => uint256[]) private _childrenArr;
    mapping(uint256 => uint256) private _childrenIndex;
    mapping(uint256 => uint256) private _childrenCounter;

    string constant JSON_FILE = ".json";
    string constant _metadataURI = "https://niftytailor.com/";
    address immutable BAYC;
    address immutable MAYC;
    address RoyaltyReceiver;
    address _mintPassAddress;

    uint256 mintStartTimestamp;
    uint256 mintEndTimestamp;

    Counters.Counter private _tokenIdCounter;

    event MintPassUsed(uint indexed currentId, uint indexed mintpassId, address indexed owner, address parent, uint256 tokenId, uint256 currentOriginIndex);
    event NewMintPassAddress( address indexed newAddress );
    event BaseUriUpdate( string uri );
    event MintStartUpdate( uint timestamp );
    event MintEndUpdate( uint timestamp );
    event RoyaltyContractUpdate( address indexed newAddress );
    event PermanentURI(string _value, uint256 indexed _id);
    

    // Base URI
    string private __baseURI;

    // count burnt token number to calc totalSupply()
    uint256 private _burnt;

    address private _uriUpdater;

    constructor(string memory name_, string memory symbol_, address _bayc, address _mayc, address _rr, address _newUriChanger) ERC721(name_, symbol_) UriChanger(_newUriChanger) {
        BAYC = _bayc;
        MAYC = _mayc;

        _setRoyaltyContract( _rr );

        // TODO set correct roaylty amount
        _setRoyalty(500);// 100 = 1%

        uint256 startTimestamp = block.timestamp + 60 * 60 * 24 * 7;
        _setMintStartTime( startTimestamp ); // minting allowed in a week
        _setMintEndTime( startTimestamp + 60 * 60 * 24 * 30 * 6 ); // minting allowed for 6 months

        // make it start from 1
        _tokenIdCounter.increment();

    }

    function baseURI() public view virtual returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyUriChanger {
        _setBaseURI(baseURI_);
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        emit BaseUriUpdate(baseURI_);
        __baseURI = baseURI_;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyUriChanger{
        _setTokenURI(tokenId, _tokenURI);
        emit PermanentURI(_tokenURI, tokenId);
    }

    function setMintStartTime(uint256 timestamp) external onlyOwner {
        _setMintStartTime( timestamp );
    }

    function _setMintStartTime(uint256 timestamp) internal {
        emit MintStartUpdate(timestamp);
        mintStartTimestamp = timestamp;
    }

    function getMintStartTime() external view returns (uint256) {
        return mintStartTimestamp ;
    }

    function setMintEndTime(uint256 timestamp) external onlyOwner {
        _setMintEndTime( timestamp );
    }

    function _setMintEndTime(uint256 timestamp) internal {
        emit MintEndUpdate(timestamp);
        mintEndTimestamp = timestamp;
    }

    function getMintEndTime() external view returns (uint256) {
        return mintEndTimestamp ;
    }

    function setMintPass(address addr) public onlyOwner {
        emit NewMintPassAddress(addr);
        _mintPassAddress = addr;
    }

    // Form combination of address & tokenId for unique pointer to NFT - Address is 160 bits (20*8) + TokenId 96 bits
    function getPonter(address c, uint256 tokenId) internal pure returns (uint256) {
        require(tokenId < (1 << 96), "Too big tokenId");
        return (uint256(uint160(c)) << (256-20*8)) + tokenId ;
    }

    function tokenOfOriginByIndex(address erc721, uint256 tokenId, uint256 index) public view returns (uint256) {
        uint256 pointer = getPonter(erc721, tokenId);
        require(index < _childrenArr[pointer].length, "Index out of bounds");
        return _childrenArr[pointer][index];
    }

    function tokenOfOriginCount(address erc721, uint256 tokenId) public view returns (uint256) {
        uint256 pointer = getPonter(erc721, tokenId);
        return _childrenArr[pointer].length;
    }

    function tokenOfOriginCounter(address erc721, uint256 tokenId) public view returns (uint256) {
        uint256 pointer = getPonter(erc721, tokenId);
        return _childrenCounter[pointer] - 1;
    }

    // required to solve inheritance
    function _burn(uint256 tokenId) internal virtual override {

        ERC721s memory parent = getParent(tokenId);
        uint256 pointer = getPonter(parent.erc721, parent.tokenId);

        uint256 tokenIndex = _childrenIndex[tokenId];

        uint256 lastTokenIndex = _childrenArr[pointer].length - 1;

        //If required, swap the token to be burned and the token at the head of the stack
        //then use pop to remove the head of the _childrenArr stack mapping
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _childrenArr[pointer][lastTokenIndex];

            _childrenArr[pointer][tokenIndex] = lastTokenId;

            _childrenIndex[lastTokenId] = tokenIndex;

        }

        _childrenArr[pointer].pop();
        delete _childrenIndex[tokenId];

        delete _parents[tokenId];
        ERC721URIStorage._burn(tokenId);
    }

    function burn(uint256 tokenId) external {
        require (_isApprovedOrOwner(_msgSender(), tokenId), "Not approved and not owner");
        _burnt++;
        _burn(tokenId);
    }

    // required to solve inheritance
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165,ERC721, DerivedERC2981Royalty) returns (bool) {
        return 
        interfaceId == type(IERC721Enumerable).interfaceId 
        || ERC721.supportsInterface(interfaceId) 
        || DerivedERC2981Royalty.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external virtual override view
    returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Token doesnt exist.");
        receiver = RoyaltyReceiver;
        royaltyAmount = (_getRoyalty() * salePrice) / 10000;
    }

    function setRoyaltyContract(address newAddress) external onlyOwner {
        _setRoyaltyContract( newAddress );
    }

    function _setRoyaltyContract(address newAddress) internal {
        require(newAddress.isContract(), "Only Contract allowed");
        emit RoyaltyContractUpdate(newAddress);
        RoyaltyReceiver = newAddress;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        (bool sent, ) = _msgSender().call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    function _isTokenOwner(address _contract, uint256 tokenId) internal view returns (bool) {
        ERC721 t = ERC721(_contract);
        return _msgSender() == t.ownerOf(tokenId);
    }

    // We dont use tokenURI param. its just for external use, but should be attached to the request to connect token with temporary URI
    function mintDerivedBAYCWithURI(mintDataWithUri[] calldata data) external {
        uint i;
        for (i=0 ; i < data.length; i++) {
            _mintDerived( data[i].tokenId, data[i].mintpassId, BAYC );
        }
    }

    // We dont use tokenURI param. its just for external use, but should be attached to the request to connect token with temporary URI
    function mintDerivedMAYCWithURI(mintDataWithUri[] calldata data) external {
        uint i;
        for (i=0 ; i < data.length; i++) {
            _mintDerived( data[i].tokenId, data[i].mintpassId, MAYC );
        }
    }

    function mintDerivedBAYC( mintData[] calldata data )  external {
        uint i;
        for (i=0 ; i < data.length; i++) {
            _mintDerived( data[i].tokenId, data[i].mintpassId, BAYC );
        }
    }

    function mintDerivedMAYC( mintData[] calldata data )  external {
        uint i;
        for (i=0 ; i < data.length; i++) {
            _mintDerived( data[i].tokenId, data[i].mintpassId, MAYC );
        }
    }

    function _mintDerived( uint256 tokenId, uint256 mintpassId, address erc721 )  internal returns (uint256 newTokenId) {
        require( block.timestamp >= mintStartTimestamp, "Minting has not started");
        require( block.timestamp <= mintEndTimestamp, "Minting finished");
        require( _isTokenOwner(erc721, tokenId), "Need to be an owner to mint");

        MintPassOptimized mp = MintPassOptimized(_mintPassAddress);
        bool result = mp.useToken(mintpassId, _msgSender());
        require (result, "Mintpass Already used");

        newTokenId = _tokenIdCounter.current();
        
        _parents[newTokenId] = ERC721s(erc721, tokenId);

        uint256 pointer = getPonter(erc721, tokenId); // Get unique 256 bit pointer to specific originating Token (masked address + tokenId)
        uint256 newTokenIndex = _childrenCounter[pointer]; // How many tokens are currently dervied from the specific originating Token

        _childrenArr[pointer].push(newTokenId); // create mapping of derived tokenIds for each originating Token
        _childrenIndex[newTokenId] = _childrenArr[pointer].length - 1;
        _childrenCounter[pointer] = newTokenIndex + 1; 

        emit MintPassUsed(newTokenId, mintpassId, _msgSender(), erc721, tokenId, newTokenIndex);

        _safeMint(_msgSender(), _tokenIdCounter.current());
        _tokenIdCounter.increment();
        
    }

    function getParent(uint256 tokenId) public view returns(ERC721s memory) {
        require(_exists(tokenId), "Non-existent token");
        return _parents[tokenId];
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(_metadataURI, "contracts/dape.json"));
    }

    /**
     * Foreach all minted tokens until reached appropriate index
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < balanceOf(owner), "DAPE: owner index out of bounds");

        uint256 numMinted = _tokenIdCounter.current();
        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i = 1; i < numMinted; i++) {

                if (_exists(i) && (ownerOf(i) == owner) ){

                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx = tokenIdsIdx + 1;
                }
            }
        }

        // Execution should never reach this point.
        assert(false);
        // added to stop compiler warnings
        return 0;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tokenIdCounter.current() - _burnt - 1;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        uint256 numMintedSoFar = _tokenIdCounter.current();

        require(index < totalSupply(), "DAPE: index out of bounds");

        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i = 1; i < numMintedSoFar; i++) {
                if (_exists(i)){
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        assert(false);
        return 0;
    }

}
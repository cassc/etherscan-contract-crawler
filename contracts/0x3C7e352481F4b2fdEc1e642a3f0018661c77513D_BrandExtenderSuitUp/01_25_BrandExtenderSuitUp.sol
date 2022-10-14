// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "stl-contracts/royalty/DerivedERC2981Royalty.sol";
import "stl-contracts/ERC/ERC5169.sol";

import "./libs/VerifyLinkAttestation.sol";
import "./UriChanger.sol";
import "./VerifySignature.sol";
import "hardhat/console.sol";


contract BrandExtenderSuitUp is ERC5169, VerifySignature, IERC721Enumerable, ERC721Enumerable, ERC721URIStorage, UriChanger, DerivedERC2981Royalty {

    using Strings for uint256;
    using Address for address;

    struct ERC721s {
        address erc721;
        uint256 tokenId;
    }

    mapping(uint256 => ERC721s) internal _parents;

    // relation of combined contract_and_id to tokenIds, kind of Enumerable
    mapping(uint256 => uint256[]) internal _childrenArr;
    mapping(uint256 => uint256) internal _childrenIndex;
    mapping(uint256 => uint256) internal _childrenCounter;

    string constant _metadataURI = "https://resources.smarttokenlabs.com/";

    address RoyaltyReceiver;
    address[] sharedTokenHolders;
 
    uint256 mintStartTimestamp;
    uint256 mintEndTimestamp;

    uint256 mintPrice;

    event BaseUriUpdated( string uri );
    event MintStartUpdated( uint timestamp );
    event MintEndUpdated( uint timestamp );
    event RoyaltyContractUpdated( address indexed newAddress );
    event PermanentURI(string _value, uint256 indexed _id);
    event ParentAdded(address indexed newERC721);
    event SharedTokenHoldersUpdated(address[] newAddresses);
    event MintPriceUpdated(uint prevPrice, uint newPrice);
    // emit MintedDerived(data[i].ERC721, data[i].tokenId, mintedID, data[i].tokenURI );
    event MintedDerived(address indexed parentContract, uint indexed parentId, uint indexed mintedId, string tmpUri, uint currentOriginIndex);

    mapping(uint => address) private minter;

    function getMinter(uint tokenId) public view returns (address) {
        _requireMinted(tokenId);
        return minter[tokenId];
    }

    
    function _authorizeSetScripts(string[] memory) internal override onlyOwner {}

    // Base URI
    string private __baseURI;

    using Strings for uint256;

    // save as array to be able to foreach parents
    address[] private allowedParentsArray;
    mapping(address => uint) private allowedParents;

    struct mintRequestData {
        address ERC721;
        uint256 tokenId;
        uint256 ticketId;
        bytes signature;
        string tokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        if (to == address(0) && from != address(0)){
            delete minter[tokenId];
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    constructor(address _rr, address _newUriChanger) ERC721("Devcon VI Suit Up Collection", "DCVI_SUP") UriChanger(_newUriChanger){
        updateUriChanger(_newUriChanger);
        _setRoyaltyContract(_rr);

        // TODO set correct roaylty amount
        _setRoyalty(600);// 100 = 1%
    }

    function setRoyalty(uint amount) external onlyOwner {
        _setRoyalty(amount);
    }
 
    function setMintPrice(uint newPrice) external onlyOwner {
        emit MintPriceUpdated(mintPrice, newPrice);
        mintPrice = newPrice;
    }

    // SharedTokenHolder - some STL address, which holds popular NFTs, 
    // contract allowed to mint derived NFTs for NFTs, owned by this token
    function setSharedTokenHolders(address[] calldata newAddresses) external onlyOwner {
        emit SharedTokenHoldersUpdated(newAddresses);
        sharedTokenHolders = newAddresses;
    }

    // array of ERC721 contracts to be parents to mint derived NFT 
    function getParents() public view virtual returns(address[] memory) {
        return allowedParentsArray;
    }

    function addParent(address newContract) public onlyUriChanger {

        require(newContract.isContract(), "Must be contract");

        IERC721 c = IERC721(newContract);

        try c.supportsInterface(type(IERC721).interfaceId) returns (bool result) {
            if (!result){
                revert("Must be ERC721 contract");
            }
        } catch {
            // emit Log("external call failed");
            revert("Must be ERC721 contract");
        }

        // require(c.supportsInterface(type(IERC721).interfaceId), "Must be ERC721 contract");

        require(allowedParents[newContract] == 0, "Already added");
        allowedParentsArray.push(newContract);
        allowedParents[newContract] = allowedParentsArray.length;
        emit ParentAdded(newContract);

    }

    function validateMintRequest(mintRequestData calldata data) internal view returns(bool){
        address erc721 = data.ERC721;
        require(allowedParents[data.ERC721] > 0, "Contract not supported");

        bytes memory toSign = abi.encodePacked( address(this), msg.sender, erc721, data.tokenId, block.chainid, data.ticketId, data.tokenURI );

        require(verifyEthHash(keccak256(toSign), data.signature) == uriChanger(), "Wrong metadata signer");

        return true;
    }

    function mintDerived(mintRequestData[] calldata data) external virtual {
        uint i;
        for (i=0; i < data.length; i++) {
            require( validateMintRequest(data[i]), "Invalid mint request");
            _mintDerivedMulti( data[i].ERC721, data[i].tokenId, msg.sender, data[i].ticketId);
            emit MintedDerived(data[i].ERC721, data[i].tokenId, data[i].ticketId, data[i].tokenURI, tokenOfOriginCounter(data[i].ERC721, data[i].tokenId) - 1 );
        }
    }


    function _mintDerivedMulti(address erc721, uint256 tokenId, address to, uint256 ticket_id) internal {
        require(block.timestamp >= mintStartTimestamp, "Minting has not started");
        if (mintEndTimestamp > 0){
            require(block.timestamp <= mintEndTimestamp, "Minting finished");
        }

        require( _isSharedHolderTokenOwner(erc721, tokenId), "Shared Holder not owner");
        
        _parents[ticket_id] = ERC721s(erc721, tokenId);
        minter[ticket_id] = msg.sender;

        uint256 pointer = getPonter(erc721, tokenId); // Get unique 256 bit pointer to specific originating Token (masked address + tokenId)
        uint256 newTokenIndex = _childrenCounter[pointer]; // How many tokens are currently dervied from the specific originating Token

        _childrenIndex[ticket_id] = _childrenArr[pointer].length;
        _childrenArr[pointer].push(ticket_id); // create mapping of derived tokenIds for each originating Token
        _childrenCounter[pointer] = newTokenIndex + 1; 

        _safeMint(to, ticket_id);
        
    }


    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(_metadataURI, "contract/devcon_suitup.json"));
    }

    function contractAddress() internal view returns (string memory) {
        return Strings.toHexString(uint160(address(this)), 20);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        _requireMinted(tokenId);

        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, "/", tokenId.toString()));
        } else {
            return string(abi.encodePacked(_metadataURI, block.chainid.toString(), "/", contractAddress(), "/", tokenId.toString()));
        }
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
        emit BaseUriUpdated(baseURI_);
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
        emit MintStartUpdated(timestamp);
        mintStartTimestamp = timestamp;
    }

    function getMintStartTime() external view returns (uint256) {
        return mintStartTimestamp ;
    }

    function setMintEndTime(uint256 timestamp) external onlyOwner {
        _setMintEndTime( timestamp );
    }

    function _setMintEndTime(uint256 timestamp) internal {
        emit MintEndUpdated(timestamp);
        mintEndTimestamp = timestamp;
    }

    function getMintEndTime() external view returns (uint256) {
        return mintEndTimestamp ;
    }

    // Form combination of address & tokenId for unique pointer to NFT - Address is 160 bits (20*8) + TokenId 96 bits
    function getPonter(address c, uint256 tokenId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(c, tokenId)));
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
        return _childrenCounter[pointer];
    }

    // required to solve inheritance
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {

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
        _burn(tokenId);
    }

    // required to solve inheritance
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC5169, IERC165, ERC721, DerivedERC2981Royalty, ERC721Enumerable) returns (bool) {
        return 
        interfaceId == type(IERC721Enumerable).interfaceId 
        || ERC721.supportsInterface(interfaceId) 
        || ERC5169.supportsInterface(interfaceId) 
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
        // require(newAddress.isContract(), "Only Contract allowed");
        emit RoyaltyContractUpdated(newAddress);
        RoyaltyReceiver = newAddress;
    }

    function _isTokenOwner(address _contract, uint256 tokenId) internal view returns (bool) {
        ERC721 t = ERC721(_contract);
        return _msgSender() == t.ownerOf(tokenId);
    }

    function _isSharedHolderTokenOwner(address _contract, uint256 tokenId) internal view returns (bool) {
        ERC721 t = ERC721(_contract);
        address nftOwner = t.ownerOf(tokenId);
        uint length = sharedTokenHolders.length;
        for (uint i=0; i<length; i++){
            console.log(sharedTokenHolders[i], nftOwner);
            if (sharedTokenHolders[i] == nftOwner){
                return true;
            }
        }
        return false;
    }

    function getParent(uint256 tokenId) public view returns(ERC721s memory) {
        require(_exists(tokenId), "Non-existent token");
        return _parents[tokenId];
    }

}
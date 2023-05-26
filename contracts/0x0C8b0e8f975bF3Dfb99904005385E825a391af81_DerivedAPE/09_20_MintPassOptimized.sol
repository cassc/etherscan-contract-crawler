// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";
import "./DerivedERC2981Royalty.sol";

contract MintPassOptimized is ERC721, Ownable,  DerivedERC2981Royalty, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;

    using Counters for Counters.Counter;
    mapping(uint256 => uint256) private mintedMAYC;
    mapping(uint256 => uint256) private mintedBAYC;

    address immutable BAYC;
    address immutable MAYC;
    address immutable DAPE;
    address RoyaltyReceiver;

    string constant _contractURI = "https://niftytailor.com/contracts/mintpass.json";
    string constant _tokenURI = "https://niftytailor.com/token/mintpass.json";

    uint256 constant AllowedNumberOfMintpasses = 10;
    uint256 constant MintPrice = 1 ether * 69 / 1000 ;
    uint256 constant MaxPerAddress = 50;
    uint256 constant MaxAllowed = 2500;

    Counters.Counter private _tokenIdCounter;
    uint256 immutable mintStartTime;

    // count burnt token number to calc totalSupply()
    uint256 private _burnt;

    event MintpassesMinted(address indexed requestor, uint indexed number, uint256 origins);
    event RoyaltyContractUpdate( address indexed newAddress );

    // mapping(uint256 => uint256) private _originsMintedCounters;
    mapping(address => uint256) private _mintedPerAddress;

    // function initialize(string memory name_, string memory symbol_, address perionAddress, address perionAdminAddress) public initializer
    constructor(string memory name_, string memory symbol_, address _bayc, address _mayc, address _dape, address _rr, uint256 _mintStartTime) ERC721(name_, symbol_) Ownable(){
        BAYC = _bayc;
        MAYC = _mayc;
        DAPE = _dape;
        _setRoyaltyContract(_rr);

        _tokenIdCounter.increment();

        // TODO update royalty value
        _setRoyalty(200); // 100 = 1%

        mintStartTime = _mintStartTime;
    }


    // required to solve inheritance
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721, DerivedERC2981Royalty) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || DerivedERC2981Royalty.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external virtual override view
    returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Token doesnt exist.");
        // receiver = _getTokenOwner(tokenId);
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

    function _getBalance(address _contract) internal view returns (uint256) {
        ERC721 t = ERC721(_contract);
        return t.balanceOf(_msgSender());
    }

    function mintedTotal() external view returns (uint256)  {
        return _tokenIdCounter.current() - 1;
    }

    function mintedForAddress( address addr ) external view returns (uint256)  {
        return _mintedPerAddress[addr];
    }

    function getMintStartTime() external view returns (uint256){
        return mintStartTime;
    }

    function mintMintPass( uint256 mintpassNumber ) external payable {
        require(block.timestamp >= mintStartTime, "Minting not started");
        _mintFor( mintpassNumber);
    }

    function _mintFor( uint256 mintpassNumber )  internal {
        // uint256 currentBalance = ERC721Upgradeable.balanceOf(_msgSender());
        uint256 minted = _mintedPerAddress[_msgSender()];

        require( MintPrice.mul(mintpassNumber) <= msg.value, "Ether value sent is not correct");
        
        require( MaxPerAddress >= (minted + mintpassNumber), "Too much MintPasses requested");
        require( MaxAllowed >= (_tokenIdCounter.current() - 1 + mintpassNumber), "Limit reached");
        // require( _isTokenOwner(erc721, tokenId), "Sender not an owner");

        uint256 originsNumber = _getBalance(BAYC) + _getBalance(MAYC);

        require(originsNumber * AllowedNumberOfMintpasses > minted, "Not enough origins.");
        require(originsNumber * AllowedNumberOfMintpasses - minted >= mintpassNumber, "Not enough origins");

        _mintedPerAddress[_msgSender()] = minted + mintpassNumber;
        
        for (uint i = 0; i < mintpassNumber; i++) {
            __mint(_msgSender());
        }

        emit MintpassesMinted( _msgSender(), mintpassNumber, originsNumber);
    }

    function useToken(uint256 tokenId, address sender) external returns (bool) {
        require (_msgSender() == DAPE, "Only Derived APE allowed");
        require (_exists(tokenId), "Non-existent token"); 
        require ( ownerOf(tokenId) == sender, "Requested by Non-owner"); 
        _burnt++;
        _burn(tokenId);
        return true;
    }

    // function setDAPE( address _dape) external onlyOwner {
    //     require (_dape != address(0), "Zero not allowed");
    //     DAPE = _dape;
    // }

    function contractURI() public pure returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _tokenURI;
    }

    function __mint(address to) internal returns (uint256 currentId) {
        currentId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, currentId);
    }

        /**
     * Foreach all minted tokens until reached appropriate index
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < balanceOf(owner), "MP: owner index out of bounds");

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

        require(index < totalSupply(), "MP: index out of bounds");

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
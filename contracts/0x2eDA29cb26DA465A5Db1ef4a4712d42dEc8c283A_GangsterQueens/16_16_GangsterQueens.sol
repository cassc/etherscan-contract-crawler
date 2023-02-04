// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GangsterQueens is ERC721, ERC721Enumerable, Ownable{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 private NFT_Per_User = 10;

    uint256 private _price = 0.025 ether;
    bool private _pause = true;
    Counters.Counter private _tokenIdCounter;

    string public baseTokenURI;
    
    mapping(address => bool) public whitelist;

    mapping(address => uint256) public countaddress;


    bool private isRevealed = false;


    event PauseChanged(bool _pause);
    event GangsterQueenMinted(address indexed _to, uint256 indexed _tokenId);

    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    

    constructor(string memory _preRevealURI) ERC721("GangsterQueens", "GQNS") {
        setBaseURI(_preRevealURI);
    }

    function mint(uint256 count) public payable{
        require(_pause, "Sale not open");
        require(totalSupply() != MAX_SUPPLY, "Maximum supply reached");
        require(totalSupply() + count <= MAX_SUPPLY, "Exceeds maximum GangsterQueens supply");

        if (msg.sender != owner()) {
            require(count <= NFT_Per_User,"maximum 10");
            if (whitelist[msg.sender] && countaddress[msg.sender] == 0){
                require(count == 1,"Only one NFT allowed per WhiteList wallet");

            }else{
            uint256 amount = price(count);
            uint256 _addressCount = countaddress[msg.sender] + count;
            require(_addressCount <= NFT_Per_User, "Max 10 NFT per wallet");
            require(msg.value >= amount, "Insufficient Funds!");
            }
            }
            
        _mintFunction(_msgSender(), count);
    }

    function _mintFunction(address _to, uint256 _count) private {
        for (uint256 i = 0; i < _count; i++) {
            _tokenIdCounter.increment();
            uint x = countaddress[msg.sender];
            countaddress[msg.sender] = x+1;
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(_to, tokenId);
            emit GangsterQueenMinted(_to, tokenId);
        }
    }

    /**
     * @notice Add to whitelist
     */
    function addToWhitelist(address[] calldata toAddAddresses) 
    external onlyOwner
    {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
    }

    /**
     * @notice Remove from whitelist
     */
    function removeFromWhitelist(address[] calldata toRemoveAddresses)
    external onlyOwner
    {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
    }

    function tokenURI (uint256 tokenId) public view override returns (string memory)
    { 
        if (! isRevealed) 
        { 
            return baseTokenURI; 
        } 
        return super.tokenURI (tokenId); 
    }

    function reveal(string memory baseURI) external onlyOwner 
    { 
        uint256 _fromTokenId = 1;
        uint256 _toTokenId = totalSupply();

        baseTokenURI = baseURI;
        isRevealed = true;
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (! isRevealed) 
        { 
            return baseTokenURI;
        }
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        if(totalSupply()>= 1){
        uint256 _fromTokenId = 1;
        uint256 _toTokenId = totalSupply();
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
        }
        
    }

    

    function setPause(bool _newValue) public onlyOwner {
        _pause = _newValue;
        
        emit PauseChanged(_pause);
    }

    function setPrice(uint256 _pricePerItem) public onlyOwner {
        _price = _pricePerItem;
    }

    function price(uint256 _count) public view returns (uint256) {
        return _price.mul(_count);
    }

    function withdrawAll() public onlyOwner {
        // require(address(this).balance > 0, "No funds to withdraw");
        require(payable(msg.sender).send(address(this).balance));
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
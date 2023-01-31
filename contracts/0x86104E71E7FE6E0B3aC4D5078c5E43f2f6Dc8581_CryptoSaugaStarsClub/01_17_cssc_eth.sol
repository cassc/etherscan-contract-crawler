/** 
   ____                  _       ____                          
  / ___|_ __ _   _ _ __ | |_ ___/ ___|  __ _ _   _  __ _  __ _ 
 | |   | '__| | | | '_ \| __/ _ \___ \ / _` | | | |/ _` |/ _` |
 | |___| |  | |_| | |_) | || (_) |__) | (_| | |_| | (_| | (_| |
  \____|_|   \__, | .__/ \__\___/____/ \__,_|\__,_|\__, |\__,_|
 / ___|| |_ _|___/|_| ___ / ___| |_   _| |__       |___/       
 \___ \| __/ _` | '__/ __| |   | | | | | '_ \                  
  ___) | || (_| | |  \__ \ |___| | |_| | |_) |                 
 |____/ \__\__,_|_|  |___/\____|_|\__,_|_.__/                  
                                                               
**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";




contract CryptoSaugaStarsClub is IERC721, ERC721Enumerable, Pausable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;


    mapping(address => bool) blacklistedMarketPlaces;
    uint256 public constant MAX_SUPPLY = 1913;
    uint256 public MAX_PER_ADDRESS = 10;
    uint256 public price = 0 ether;
    uint256 public partnerPrice = 0 ether;
    uint256 public pubMintCounter = 1713;

    string public baseURI = "";
    bytes32 public merkleRoot =
        0xefb09ede55bc8d46fc9adf84b7a1e72e4788495133fe1bcba135f29658959bc5;
    IERC721 partnerContract;

    //events
    event SetMerkleRoot(string _msg);
    event SetPartnerContract(address partnerContract);
    event PublicMint(address _sender,uint256 _tokenId);
    event Airdrop(address _sender,uint256 _tokenId);
    event Withdraw(uint256 );
    event SetPrice(uint256 _price);
    event PartnerMint(uint256 mintIndex);
    event InternalMint(uint256 mintIndex);
    event SetBaseURI(string baseURI);
    event SetMaxPerAddress(uint256 maxPerAddress);
    event SetPartnerPrice(uint256 price);

    constructor() ERC721("CryptoSauga Stars Club", "CSSC") {}

    modifier isNotBlacklisted(address operator) {
        require(!blacklistedMarketPlaces[operator], 'Blacklisted marketplace');
        _;
    }

    function mintPrice(uint256 qty) internal view returns (uint256) {
        return price.mul(qty);
    }

    function partnerMintPrice(uint256 qty) internal view returns (uint256) {
        return partnerPrice.mul(qty);
    }

    function mint(address owner, bytes32[][] calldata merkleProofs, uint256[] calldata tokenIds) nonReentrant external whenNotPaused payable   {
        require(merkleProofs.length == tokenIds.length, 'Invalid input length');
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bytes32 node = keccak256(
                abi.encodePacked(owner, tokenIds[i])
            );
            bool isValidProof = MerkleProof.verify(
                merkleProofs[i],
                merkleRoot,
                node
            );
            require(isValidProof, 'Invalid proof');
            require(!_exists(tokenIds[i]), 'token already minted');
            _safeMint(owner, tokenIds[i]);
            emit PublicMint(owner, tokenIds[i]);
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit SetMerkleRoot('merkle root set');
    }

    function setPartnerContract(address _partnerContract) external onlyOwner {
        partnerContract = IERC721(_partnerContract);
        emit SetPartnerContract(_partnerContract);
    }


    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit SetPrice(price);
    }

    function setPartnerPrice(uint256 _price) external onlyOwner {
        partnerPrice = _price;
        emit SetPartnerPrice(price);
    }

    function partnerMint(uint256 qty) nonReentrant external whenNotPaused payable  {
        uint256 count = partnerContract.balanceOf(msg.sender);
        require(count > 0 , 'User does not hold partner token.');
        require(msg.value >= partnerMintPrice(qty), "insufficient funds");
        require(
            (pubMintCounter + qty) <= (MAX_SUPPLY),
            "_validateQuantity : qty exceed supply limit"
        );
        require(
            (balanceOf(msg.sender) + qty) <= MAX_PER_ADDRESS,
            "_validateQuantity : qty exceeded MAX_PER_ADDRESS"
        );
       
        for (uint256 i = 0; i < qty; i++) {
             pubMintCounter += 1;
            _safeMint(msg.sender, pubMintCounter);
            emit PartnerMint(pubMintCounter);
        }
    }

    function publicMint(uint256 qty) nonReentrant external whenNotPaused payable  {
        require(msg.value >= mintPrice(qty), "insufficient funds");
        require(
            (pubMintCounter + qty) <= (MAX_SUPPLY),
            "_validateQuantity : qty exceed supply limit"
        );
        require(
            (balanceOf(msg.sender) + qty) <= MAX_PER_ADDRESS,
            "_validateQuantity : qty exceeded MAX_PER_ADDRESS"
        );
        for (uint256 i = 0; i < qty; i++) {
             pubMintCounter += 1;
            _safeMint(msg.sender, pubMintCounter);
            emit PublicMint(msg.sender, pubMintCounter);
        }
    }

    function mintInternal(uint256 qty) external onlyOwner {
        require((pubMintCounter + qty) <= (MAX_SUPPLY), "_validateQuantity : qty exceed supply limit");
        for (uint256 i = 0; i < qty; i++) {
             pubMintCounter += 1;
            _safeMint(msg.sender, pubMintCounter);
            emit InternalMint(pubMintCounter);
        }
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit SetBaseURI(baseURI);
    }

    function setMaxPerAddress(uint256 maxPerAddress) external onlyOwner {
        MAX_PER_ADDRESS = maxPerAddress;
        emit SetMaxPerAddress(MAX_PER_ADDRESS);
    }

    function setBlacklistedMarketplace(address[] memory blacklistedOperators) external onlyOwner {
        for(uint256 i;i < blacklistedOperators.length; i++){
            blacklistedMarketPlaces[blacklistedOperators[i]] = true;
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        emit Withdraw(address(this).balance);
        require(os);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) 
    {
        uint256 count = balanceOf(_owner);
        uint256[] memory result = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // for preventing blacklisted marketplaces to list item
    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) isNotBlacklisted(to) {
        super.approve(to, tokenId);
    }
   function setApprovalForAll(address to, bool approved) public virtual override(ERC721, IERC721) isNotBlacklisted(to) {
        super.setApprovalForAll(to, approved);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
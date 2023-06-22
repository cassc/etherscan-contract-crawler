// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GutterComics is ERC721, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    using ECDSA for bytes32;

    //gasless approvals on opensea
    address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    string public _baseURIextended =
        "https://comicsapi.guttercatgang.com/metadata/comics/";
    string public _contractURI =
        "ipfs://Qmf6iFDeNGFcEAdympLTpNZhGyTjtQtTeJ9bbde3f9tKyZ";

    uint256 public maxNormalSupplyID = 12000;
    uint256 public saleStopID = 9000;
    uint256 public pricePerComic = 0.04 ether;

    bool public locked; //metadata lock
    uint256 public _currentIndex;
    uint256 private _tokensBurned;

    bool public presaleLive;
    bool public saleLive;
    bool public freeMintLive;
    bool public burnLive;

    address public gutterCatNFTAddress =
        0xEdB61f74B0d09B2558F1eeb79B247c1F363Ae452;
    address public gutterRatNFTAddress =
        0xD7B397eDad16ca8111CA4A3B832d0a5E3ae2438C;
    address public gutterPigeonNFTAddress =
        0x950b9476a4de757BB134483029AC4Ec17E739e3A;
    address public gutterDogNFTAddress =
        0x6E9DA81ce622fB65ABf6a8d8040e460fF2543Add;

    // upgrade-related settings
    address private signerAddress;
    bool public upgradeLive;

    mapping(uint256 => bool) public usedCatIDs; //used cat IDs for free claiming
    mapping(address => uint256) public purchases;

    event TokenUpgraded(uint256 id, uint256 coverType);

    constructor() ERC721("Gutter Comics", "GCOM") {}

    function presale(uint256 qty, uint256 gutterCatorRatID)
        external
        payable
        nonReentrant
    {
        require(tx.origin == msg.sender, "no...");
        require(presaleLive, "presale not live");
        require(qty <= 5, "max 5 per tx");
        require(purchases[msg.sender] + qty <= 10, "limit exceded");

        require(_currentIndex + qty <= saleStopID, "out of stock");
        require(pricePerComic * qty == msg.value, "exact amount needed");

        require(
            (IERC1155(gutterCatNFTAddress).balanceOf(
                msg.sender,
                gutterCatorRatID
            ) > 0) ||
                (IERC1155(gutterRatNFTAddress).balanceOf(
                    msg.sender,
                    gutterCatorRatID
                ) > 0) ||
                (IERC721(gutterPigeonNFTAddress).balanceOf(msg.sender) > 0) ||
                (IERC721(gutterDogNFTAddress).balanceOf(msg.sender) > 0),
            "you have to own a gutter species"
        );

        purchases[msg.sender] += qty;

        mintMultiple(msg.sender, qty);
    }

    function publicSale(uint256 qty) external payable nonReentrant {
        require(tx.origin == msg.sender, "no...");
        require(saleLive, "sale not live");
        require(qty <= 5, "max 5 per tx");
        require(purchases[msg.sender] + qty <= 10, "limit exceded");

        require(_currentIndex + qty <= saleStopID, "out of stock");
        require(pricePerComic * qty == msg.value, "exact amount needed");

        purchases[msg.sender] += qty;

        mintMultiple(msg.sender, qty);
    }

    // free for gutter cats
    function freeSale(uint256 catID) external nonReentrant {
        require(tx.origin == msg.sender, "no...");
        require(freeMintLive, "free mint not live");

        require(_currentIndex + 1 <= maxNormalSupplyID, "out of stock");
        require(!usedCatIDs[catID], "you can only mint once with this id");

        require(
            IERC1155(gutterCatNFTAddress).balanceOf(msg.sender, catID) > 0,
            "you have to own a cat with this id"
        );

        usedCatIDs[catID] = true;

        mintToken(msg.sender);
    }

    function upgradeComic(
        bytes32 hash,
        bytes memory sig,
        uint256 firstId,
        uint256 secondId,
        uint256 coverType
    ) external nonReentrant {
        require(
            _currentIndex >= maxNormalSupplyID,
            "wrong max supply settings"
        );
        require(upgradeLive, "upgrade not live");
        require(matchAddresSigner(hash, sig), "no direct mint");
        require(
            hashTransaction(firstId, secondId, coverType) == hash,
            "hash check failed"
        );
        require(_exists(firstId) && _exists(secondId), "tokens don't exist");
        require(
            ownerOf(firstId) == msg.sender && ownerOf(secondId) == msg.sender,
            "not the owner"
        );
        require(firstId != secondId, "same ids");

        burnToken(firstId);
        burnToken(secondId);

        mintToken(msg.sender);

        emit TokenUpgraded(_currentIndex, coverType);
    }

    //admin mint
    function adminMint(address to, uint256 qty) external onlyOwner {
        require(_currentIndex + qty <= maxNormalSupplyID, "out of stock");
        mintMultiple(to, qty);
    }

    function mintMultiple(address receiver, uint256 qty) private {
        for (uint256 i = 0; i < qty; i++) {
            mintToken(receiver);
        }
    }

    function mintToken(address receiver) private {
        _currentIndex += 1;
        _safeMint(receiver, _currentIndex);
    }

    function burnToken(uint256 tokenId) private {
        _tokensBurned += 1;
        _burn(tokenId);
    }

    //burn
    function burn(uint256 tokenId) public virtual {
        require(burnLive, "burn not live");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        burnToken(tokenId);
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        require(!locked, "locked functions");
        _baseURIextended = newuri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(_baseURIextended, _tokenId.toString()));
    }

    function setContractURI(string memory newuri) public onlyOwner {
        require(!locked, "locked functions");
        _contractURI = newuri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    //sets the gang addresses
    function setGutterAddresses(
        address cats,
        address rats,
        address pigeons,
        address dogs
    ) external onlyOwner {
        gutterCatNFTAddress = cats; //0xEdB61f74B0d09B2558F1eeb79B247c1F363Ae452
        gutterRatNFTAddress = rats; //0xD7B397eDad16ca8111CA4A3B832d0a5E3ae2438C
        gutterPigeonNFTAddress = pigeons; //0x950b9476a4de757BB134483029AC4Ec17E739e3A
        gutterDogNFTAddress = dogs; //0x6e9da81ce622fb65abf6a8d8040e460ff2543add
    }

    //sets presale live
    function setPresaleLive(bool live) external onlyOwner {
        presaleLive = live;
    }

    //sets sale live
    function setSaleLive(bool live) external onlyOwner {
        saleLive = live;
    }

    //sets free mint live
    function setFreeMintLive(bool live) external onlyOwner {
        freeMintLive = live;
    }

    //sets burn live
    function setBurnLive(bool live) external onlyOwner {
        burnLive = live;
    }

    //sets upgrade live
    function setUpgradeLive(bool live) external onlyOwner {
        upgradeLive = live;
    }

    //sets upgrade live
    function setSaleStopID(uint256 newSaleStopID) external onlyOwner {
        require(newSaleStopID <= maxNormalSupplyID, "invalid id");
        saleStopID = newSaleStopID;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reclaimERC20(IERC20 erc20Token) public onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function reclaimERC721(IERC721 erc721Token, uint256 id) public onlyOwner {
        erc721Token.safeTransferFrom(address(this), msg.sender, id);
    }

    function reclaimERC1155(
        IERC1155 erc1155Token,
        uint256 id,
        uint256 qty
    ) public onlyOwner {
        erc1155Token.safeTransferFrom(address(this), msg.sender, id, qty, "");
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    //sets the opensea proxy
    function setProxyRegistry(address _newRegistry) external onlyOwner {
        proxyRegistryAddress = _newRegistry;
    }

    // and for the eternity!
    function lockMetadata() external onlyOwner {
        locked = true;
    }

    //sets signer address
    function setSignerAddress(address newSigner) external onlyOwner {
        signerAddress = newSigner;
    }

    // decreases max supply
    function decreaseMaxNormalSupplyID(uint256 newSupplyID) external onlyOwner {
        require(
            maxNormalSupplyID > newSupplyID && newSupplyID >= _currentIndex,
            "invalid new supply"
        );
        maxNormalSupplyID = newSupplyID;
    }

    function totalSupply() public view returns (uint256) {
        return _currentIndex - _tokensBurned;
    }

    // utils
    function hashTransaction(
        uint256 firstId,
        uint256 secondId,
        uint256 coverType
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(firstId, secondId, coverType))
            )
        );
        return hash;
    }

    function matchAddresSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return signerAddress == hash.recover(signature);
    }

    function exists(uint256 id) external view returns (bool) {
        return _exists(id);
    }
}

//opensea removal of approvals
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
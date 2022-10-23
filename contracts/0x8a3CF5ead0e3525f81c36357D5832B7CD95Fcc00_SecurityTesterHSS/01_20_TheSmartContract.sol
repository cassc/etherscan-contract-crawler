// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SecurityTesterHSS is
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    uint96 royaltyFeesBips;

    string public baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    //initial values at the time of launching of The Hand. Please use the "getters" to double check.
    uint256 public maxSupply = 7257;

    uint256 private pricePrivate = 0.257 ether;
    uint256 private pricePrivate2 = 0.488 ether;
    uint256 private pricePrivate3 = 0.694 ether;

    uint256 private pricePublic = 0.357 ether;
    uint256 private pricePublic2 = 0.678 ether;
    uint256 private pricePublic3 = 0.964 ether;

    bool public mintPaused = false;
    bool public artRevealed = false;
    bool public publicSale = false;
    bool public privateSale = false;

    bytes32 public root =
        0x11d251a3c7c541a8a68635af1ed366692175fbdc9f3b07da18af66c111f85800;

    mapping(address => uint256) public WorthyOnes; // the list of whitelisted wallets
    mapping(uint256 => uint256) public RevealedHands; // the list of revealed tokens
    mapping(uint256 => uint256) public RefundedHands; // the list of refunded tokens (part of the payback program)

    uint256 public maxInWallet = 2;
    uint256 public maxMintPrivate = 2;
    uint256 public maxMintPublic = 2;

    //The Elder Deployer
    address[] private addressList = [
        0x0bc854245B825C83ddF477151f4b1bCC70D86Bb2
    ];

    uint256[] private shareList = [100];
    address public royaltyOwner = 0x0bc854245B825C83ddF477151f4b1bCC70D86Bb2;
    uint96 public royaltyBips = 500;

    Counters.Counter private _tokenIds;

    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        setRoyaltyInfo(royaltyOwner, royaltyBips);
    }

    //+++++++++++++++++++++++++++++++++++++++++ *********** +++++++++++++++++++++++++++++++++++++++++

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
        onlyOwner
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++

    function ConfigureMerkle(bytes32 _root) public onlyOwner {
        root = _root;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function updateURI(uint256 tokenid, string memory newURI) public onlyOwner {
        _setTokenURI(tokenid, newURI);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function revealOne(uint256 _tokenID, string memory tURI) public onlyOwner {
        RevealedHands[_tokenID] = 1;
        updateURI(_tokenID, tURI);
    }

    function revealAll() public onlyOwner {
        artRevealed = true;
    }

    function pauseMinting(bool _state) public onlyOwner {
        mintPaused = _state;
    }

    function electOne(address _addressToWhitelist) public onlyOwner {
        WorthyOnes[_addressToWhitelist] = maxMintPrivate;
    }

     function MarkRefunded(uint256 tokenid) public onlyOwner {
        RefundedHands[tokenid] = 1;
    }

    function electMany(address[] calldata _addresses) public onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            WorthyOnes[_addresses[i]] = maxMintPrivate;
        }
    }

    function setPricesPublic(
        uint256 _newPrice,
        uint256 _newPrice2,
        uint256 _newPrice3
    ) public onlyOwner {
        pricePublic = _newPrice;
        pricePublic2 = _newPrice2;
        pricePublic3 = _newPrice3;
    }

    function setPricePublic(uint256 _newPrice) public onlyOwner {
        pricePublic = _newPrice;
    }

    function setPricePublic2(uint256 _newPrice) public onlyOwner {
        pricePublic2 = _newPrice;
    }

    function setPricePublic3(uint256 _newPrice) public onlyOwner {
        pricePublic3 = _newPrice;
    }

    function setPricesPrivate(
        uint256 _newPrice,
        uint256 _newPrice2,
        uint256 _newPrice3
    ) public onlyOwner {
        pricePrivate = _newPrice;
        pricePrivate2 = _newPrice2;
        pricePrivate2 = _newPrice3;
    }

    function setPricePrivate(uint256 _newPrice) public onlyOwner {
        pricePrivate = _newPrice;
    }

    function setPricePrivate2(uint256 _newPrice) public onlyOwner {
        pricePrivate2 = _newPrice;
    }

    function setPricePrivate3(uint256 _newPrice) public onlyOwner {
        pricePrivate3 = _newPrice;
    }

    function setPublicSale(bool _truefalse) public onlyOwner {
        publicSale = _truefalse;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!artRevealed) {
            uint256 thisRevealed = RevealedHands[tokenId];
            if (thisRevealed > 0) {
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            tokenId.toString(),
                            baseExtension
                        )
                    )
                    : "";
            } else return notRevealedUri;
        }

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++
    function CheckIfElected(address _sender, bytes32[] calldata merkletree)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_sender));
        return MerkleProof.verify(merkletree, root, leaf);
    }

    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++

    // Public minting: 1 Hand
    function mintPublic() public payable {
        uint256 _tokenAmount = 1;
        uint256 s = totalSupply();

        require(mintPaused == false, "Minting is paused at the moment!");
        require(publicSale == true, "Public mint is not enabled!");
        require(_tokenAmount > 0, "You cannot mint 0 NFT!");
        require(_tokenAmount <= maxMintPublic, "You must mint less!");
        require(
            balanceOf(msg.sender) < maxInWallet,
            "Max tokens per wallet reached!"
        );
        require(s + _tokenAmount <= maxSupply, "You must mint less!");
        require(msg.value >= pricePublic * _tokenAmount, "Wrong ETH input!");

        for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++
    // Public minting: 2 Hand
    // Mint a bundle to save 5% on Hand price, and gas price of course
    function mintPublic2() public payable {
        uint256 _tokenAmount = 2;
        uint256 s = totalSupply();

        require(publicSale == true, "Public mint is not enabled!");
        require(mintPaused == false, "Minting is paused at the moment!");
        require(_tokenAmount <= maxMintPublic, "You must mint less!");
        require(balanceOf(msg.sender) == 0, "Max tokens per wallet reached!");
        require(s + _tokenAmount <= maxSupply, "You must mint less!");
        require(msg.value >= pricePublic2, "Wrong ETH input!");

        for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    // Public minting: 3 Hand
    // Mint a bundle to save 10% on Hand price, and gas price of course
    function mintPublic3() public payable {
        uint256 _tokenAmount = 3;
        uint256 s = totalSupply();

        require(publicSale == true, "Public mint is not enabled!");
        require(mintPaused == false, "Minting is paused at the moment!");
        require(_tokenAmount <= maxMintPublic, "You must mint less!");
        require(balanceOf(msg.sender) == 0, "Max tokens per wallet reached!");
        require(s + _tokenAmount <= maxSupply, "You must mint less!");
        require(msg.value >= pricePublic3, "Wrong ETH input!");

        for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++

    // Private minting: 1 Hand
    function mintPrivate(bytes32[] calldata SealedProof) public payable {
        uint256 _tokenAmount = 1;
        uint256 s = totalSupply();
        //uint256 onWL = WorthyOnes[msg.sender];

        require(mintPaused == false, "Minting is paused at the moment!");
        require(privateSale == true, "Private mint is not enabled!");
        //require(onWL > 0);
        require(
            CheckIfElected(msg.sender, SealedProof),
            "This wallet was not elected for the private sale."
        );
        require(
            balanceOf(msg.sender) < maxMintPrivate,
            "Max private mint per wallet reached!"
        );
        require(msg.value >= pricePrivate * _tokenAmount, "Wrong ETH input!");
        //delete onWL;

        for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++

    //Private minting: 2 Hand
    //Mint a bundle to save 5% on Hand price, and gas price of course
    function mintPrivate2(bytes32[] calldata SealedProof) public payable {
        uint256 _tokenAmount = 2;
        uint256 s = totalSupply();
        // uint256 onWL = WorthyOnes[msg.sender];

        require(privateSale == true, "Private mint is not enabled!");
        require(mintPaused == false, "Minting is paused at the moment!");
        require(
            CheckIfElected(msg.sender, SealedProof),
            "This wallet was not elected for the private sale."
        );

        // require(onWL > 0);
        require(
            balanceOf(msg.sender) < 2,
            "Max private mint per wallet reached!"
        );
        require(msg.value >= pricePrivate2, "Wrong ETH input!");
        // delete onWL;

        for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    //Private minting: 3 Hand
    //Mint a bundle to save 10% on Hand price, and gas price of course
    function mintPrivate3(bytes32[] calldata SealedProof) public payable {
        uint256 _tokenAmount = 3;
        uint256 s = totalSupply();
        // uint256 onWL = WorthyOnes[msg.sender];

        require(privateSale == true, "Private mint is not enabled!");
        require(mintPaused == false, "Minting is paused at the moment!");
        require(
            CheckIfElected(msg.sender, SealedProof),
            "This wallet was not elected for the private sale."
        );

        // require(onWL > 0);
        require(
            balanceOf(msg.sender) == 0,
            "Max private mint per wallet reached!"
        );
        require(msg.value >= pricePrivate3, "Wrong ETH input!");
        // delete onWL;

        for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++

    function gift(uint256[] calldata gifts, address[] calldata recipient)
        external
        onlyOwner
    {
        require(gifts.length == recipient.length);
        uint256 g = 0;
        uint256 s = totalSupply();
        for (uint256 i = 0; i < gifts.length; ++i) {
            g += gifts[i];
        }
        require(s + g <= maxSupply, "Exceeded max allowed!");
        delete g;
        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < gifts[i]; ++j) {
                _safeMint(recipient[i], s++, "");
            }
        }
        delete s;
    }

    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ SEPARATOR HERE +++++++++++++++++++++++++++++++++++++++++

    function isPublic() public view returns (bool) {
        return publicSale;
    }

    function isPrivate() public view returns (bool) {
        return privateSale;
    }

    function isPaused() public view returns (bool) {
        return mintPaused;
    }

    function getRoot() public view returns (bytes32) {
        return root;
    }

    function getPricePrivate() public view returns (uint256) {
        return pricePrivate;
    }

    function getPricePrivate2() public view returns (uint256) {
        return pricePrivate2;
    }

    function getPricePrivate3() public view returns (uint256) {
        return pricePrivate3;
    }

    function getPricePublic() public view returns (uint256) {
        return pricePublic;
    }

    function getPricePublic2() public view returns (uint256) {
        return pricePublic2;
    }

    function getPricePublic3() public view returns (uint256) {
        return pricePublic3;
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesBips;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesBips)
        public
        onlyOwner
    {
        royaltyOwner = _receiver;
        royaltyFeesBips = _royaltyFeesBips;
    }

    function royaltyInfo(uint256 _salePrice)
        external
        view
        returns (
            address receiver,
            uint256 royaltyAmount //uint256 _tokenId,
        )
    {
        return (royaltyOwner, calculateRoyalty(_salePrice));
    }
}
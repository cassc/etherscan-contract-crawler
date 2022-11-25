pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//######                                                                //#      //#  //####### //########
//#   //# //#  //#   //##   //#####   //####  //#   # //#####  //###### //#/#    //# //#            //#
//#   //# //#  //#  //#  #  //#  //# //#  //#  //# #  //#  //# //#      //# /#   //# //#            //#
//######  //###### //#  //# //#  //# //#        //#   //#  //# //#####  //# //#  //# //#####        //#
//#       //#  //# //###### //#####  //#        //#   //#  //# //#      //#  //# //# //#            //#
//#       //#  //# //#  //# //# //#  //#  //#   //#   //#  //# //#      //#   //#//# //#            //#
//#       //#  //# //#  //# //#  //#  //####    //#   //#####  //###### //#    ////# //#            //#

contract Pharcyde is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriPrefix = "/";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost = 0.242 ether;
    uint256 public maxSupply = 242;
    uint256 public maxMintAmountPerTx = 3;

    bool public paused = true;
    bool public revealed = false;

    address public constant artistAddress =
        0xCe7D684F45eC71FaCB79EF962ead69a7a2c0A065;
    address public constant phtgrphrAddress =
        0xC2A83d7C8B07EcB71306E5F62882B9188C94Aa8d;
    address public constant phar1Address =
        0x5522B824351c73d386BA03aB9DD3d4F232f4dBb8;
    address public constant phar2Address =
        0x5b8aD86C10eff558FB9b3C48F149A1B34B7Bb136;
    address public constant phar3Address =
        0x48A6Bf47FA795cE4bFA062d14674De3374fEBF86;
    address public constant dev1Address =
        0x0B2b5A6B723524BBD8e463246ea45FD401c0E079;
    address public constant deployerAddress =
        0xf6794B09d3E56FD9d50d697F5D6bb8b76639D050;

    constructor(string memory _hiddenMetadataUri)
        ERC721A("Pharcyde", "PHARCYDE")
    {
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = uriPrefix;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(artistAddress, ((balance * 15) / 100));
        _widthdraw(phtgrphrAddress, ((balance * 15) / 100));
        _widthdraw(phar1Address, ((balance * 18) / 100));
        _widthdraw(phar2Address, ((balance * 18) / 100));
        _widthdraw(phar3Address, ((balance * 18) / 100));
        _widthdraw(dev1Address, ((balance * 15) / 100));
        _widthdraw(deployerAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to widthdraw Ether");
    }
}
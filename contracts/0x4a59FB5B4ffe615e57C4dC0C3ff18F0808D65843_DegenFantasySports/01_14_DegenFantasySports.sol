// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DegenFantasySports is ERC721, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string public uriPrefix = "https://arweave.net/mDsNQwSq9CJAV1SkEWT6MQVKWwwHM15pOsK_tgSvI-I/";
    string public uriSuffix = ".json";

    uint256 public publicMintPrice = 0.05 ether;

    uint256 public maxSupply = 10000;

    uint256 public txLimit = 20;

    bool public publicMintPaused = true;

    address token = 0x12E6Abdf5BEaE6D1A6F5865fa41BE50347AF1bCe;

    constructor() ERC721("DegenFantasySports", "DFSFB22") {}

    modifier publicMintCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = supply.current() + _mintAmount;
        require(_mintAmount > 0 && _mintAmount <= txLimit, "You have exceeded the limit of mints per transaction");
        require(requestedAmount <= maxSupply, "SOLD OUT");
        require(!publicMintPaused, "Minting is not currently allowed!");
        require(msg.value >= publicMintPrice * _mintAmount, "You did not send enough ETH");
        _;
    }

    modifier airDropCompliance(uint256 _mintAmount) {
        uint256 requestedAmount = supply.current() + _mintAmount;
        require(requestedAmount <= maxSupply, "SOLD OUT");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 _mintAmount) public payable publicMintCompliance(_mintAmount) nonReentrant {
        _mintLoop(msg.sender, _mintAmount);
    }

    function deposit(uint _amount) public payable {
        uint256 requestedAmount = supply.current() + _amount;
        require(requestedAmount <= maxSupply, "SOLD OUT");
        require(_amount <= txLimit, "You have exceeded the transaction maximum");
        require(_amount > 0, "You can not mint zero");
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        _mintLoop(msg.sender, _amount);
    }

    function airDrop(uint256 _mintAmount, address _receiver) public airDropCompliance(_mintAmount) onlyOwner nonReentrant {
        _mintLoop(_receiver, _mintAmount);
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

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
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
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
    }

    function setTxLimit(uint256 _txLimit) public onlyOwner {
        txLimit = _txLimit;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPublicMintPaused(bool _state) public onlyOwner {
        publicMintPaused = _state;
    }

    function withdraw() public onlyOwner nonReentrant{
        (bool dev, ) = payable(0xDC9eeF462bD661D5a14146dFA05f5cdB6Db5Fecf).call{value: (address(this).balance * 75 / 1000)}("");
        require(dev);
        (bool owner, ) = payable(0xBEa0057eEe799b1Ee95C74A27372a37693496fc7).call{value: address(this).balance}("");
        require(owner);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setTokenContract(address _token) public onlyOwner {
        token = _token;
    }

    function getContractBalance() public onlyOwner view returns(uint){
        return IERC20(token).balanceOf(address(this));
    }

    function getOwner() public view returns(address){
        return Ownable.owner();
    }
}
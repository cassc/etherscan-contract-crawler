// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


contract CandyHunters is
    ERC721A,
    Ownable
{
    using ECDSA for bytes32;
    enum alTypes {FREE, PAID}
    mapping (address => uint256) public alClaims;
    mapping (address => uint256) public freeClaims;
    uint256 public constant teamSupply = 100;
    uint256 public constant maxSupply = 10000;
    uint256 public constant allowlistMintPrice2 = 0.05 ether;
    uint256 public constant allowlistMintPrice3 = 0.04 ether;
    uint256 public constant publicMintPrice = 0.06 ether;
    uint256 public maxPerTx = 5;



    uint256 public teamClaimCount = 0;
    address public signerAddress = 0x7E4723A50108AC20CBE09cD9F656bd065f5B42c8; 
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address private _manager = 0xC7E97B7013Bd8574C7c76a25191D75E096dFf164;

    address private TEAM1 = 0x45acf055d977D8EA41AF353D16D7ba83F9B79bd7;
    address private TEAM2 = 0x723B5cB2b5F86660d5b8391d847DB40eeA34bf7c;
    address private TEAM3 = 0x9a2197620d3268bA57bfb822Ebc0cEA7105cbA94;
    address private TEAM4 = 0xC7E97B7013Bd8574C7c76a25191D75E096dFf164;
    address private TEAM5 = 0x8cc1B927E8691F825D213E1f404BCCbF9AA08490;
    address private TEAM6 = 0x0B5063760d05b151418d7D8B6947C5d81649c6C6;
    address private COMMUNITY_FUND = 0x01402DAebB58062FDbD76A378789e3Fa5F009196;
    address private SECONDARY_FUND = 0x08c239fCE14d628b891B8882ED60733F6aDF5B3A;



    string public baseUri = "https://mint.candyhuntersnft.io/api/token/";
    string public endingUri = ".json";
    bool public allowlistActive = false;
    bool public publicActive = false;

    constructor () ERC721A("Candy Hunters", "CANDY") {
    }

    receive() external payable {}

    modifier onlyOwnerOrManager() {
        require(owner() == _msgSender() || _manager == _msgSender(), "Caller not the owner or manager");
        _;
    }

    function _startTokenId() internal pure override(ERC721A) returns(uint256 startId) {
        return 1;
    }

    function flipPublicSaleState() public onlyOwnerOrManager {
        publicActive = !publicActive;
    }

    function flipAllowlistSaleState() public onlyOwnerOrManager {
        allowlistActive = !allowlistActive;
    }

    function setManager(address manager) external onlyOwnerOrManager {
        _manager = manager;
    }

    function setProxyRegistry(address preg) external onlyOwnerOrManager {
        proxyRegistryAddress = preg;
    }

    function setSignerAddress(address signer) external onlyOwnerOrManager {
        signerAddress = signer;
    }

    function setBaseURI(string memory _URI) external onlyOwnerOrManager {
        baseUri = _URI;
    }

    function setEndingURI(string memory _URI) external onlyOwnerOrManager {
        endingUri = _URI;
    }

    function withdrawBackup() external onlyOwnerOrManager {
        payable(SECONDARY_FUND).transfer(address(this).balance);
    }

    function withdrawAll() external onlyOwnerOrManager {
        uint256 balance = address(this).balance;

        _withdraw(TEAM1, (balance * 25) / 100);
        _withdraw(TEAM2, (balance * 25) / 100);
        _withdraw(TEAM3, (balance * 15) / 100);
        _withdraw(TEAM4, (balance * 9) / 100);
        _withdraw(TEAM5, (balance * 9) / 100);
        _withdraw(TEAM6, (balance * 9) / 100);
        _withdraw(COMMUNITY_FUND, (balance * 8) / 100);
        _withdraw(COMMUNITY_FUND, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "transfer failed");
    }

    function _hash(address _address, uint256 quantity, uint256 alType) internal view returns (bytes32) {
        return keccak256(abi.encode(address(this),_address, quantity, alType)).toEthSignedMessageHash();
    }

    function _verify( bytes memory signature, uint256 quantity, uint256 alType) internal view returns (bool) {
        return (_hash(msg.sender, quantity, alType).recover(signature) == signerAddress);
    }

    function publicMint(uint256 amount) external payable {
        require(publicActive, "not live");
        require(amount <= maxPerTx, "too many");
        require(msg.sender == tx.origin, "no bots");   
        require(totalSupply() + amount <= maxSupply , "sold out");
        require(publicMintPrice * amount == msg.value, "not enough eth");

        _safeMint(msg.sender, amount);
    }

    function allowlistMint( uint256 amount, uint256 maxAmount, bytes calldata _signature) external payable{
        require(allowlistActive, "not live");
        require(totalSupply() + amount <= maxSupply , "sold out");
        require(_verify(_signature, maxAmount, uint(alTypes.PAID)), "bad signature");
        require(alClaims[msg.sender] + amount <= maxAmount, "max used");
        if (maxAmount == 3){
            require(allowlistMintPrice3 * amount == msg.value, "not enough eth");
        } else {
           require(allowlistMintPrice2 * amount == msg.value, "not enough eth"); 
        }
        alClaims[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function freeMint(uint256 amount, uint256 maxAmount, bytes calldata _signature) external{
        require(allowlistActive, "not live");
        require(totalSupply() + amount <= maxSupply , "sold out");
        require(_verify(_signature, maxAmount, uint(alTypes.FREE)), "bad signature");
        require(freeClaims[msg.sender] + amount <= maxAmount, "max used");
        freeClaims[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function teamMint(uint256 amount, address _to) external onlyOwnerOrManager {
        require(totalSupply() + amount <= maxSupply , "sold out");
        require(teamClaimCount + amount <= teamSupply, "team supply sold out");
        teamClaimCount += amount;
        _safeMint(_to, amount);
    }


    function tokenURI(uint256 tokenId) public view  virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), endingUri));
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseUri;
    }

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
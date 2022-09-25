//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ShibCoOpPETCollection is IERC721Metadata, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenCount;
    uint256 private _mintLimit = 0;
    bool private saleLive = true;
    uint256 private PRICE = 1 ether;
    uint256 private SHIB_PRICE = 113600000;
    string private contractMetaUri = "ipfs://QmVqMnm4ruKj92cqnNjmzvuhY4NpWidpiZ56HszXkWjzHg";
    IERC20 private shibToken = IERC20(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);

    string public baseTokenURI = "https://shibco-op.dev/access-token/";
    bool public frozen = false;

    mapping(address => bool) private _presaleList;

    event CreateNft(uint256 indexed id);

    constructor() ERC721("Plot Encryption Token", "PET") {
    }

    function setPresaleAddress(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _presaleList[addresses[i]] = true;
        }
    }

    function isPresaleApproved(address addr) external view returns (bool) {
        return _presaleList[addr];
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenCount.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    modifier qtyAvailable(uint256 _count) {
        if (_mintLimit > 0) {
            require(_totalSupply() + _count < _mintLimit, "Qty Out");
        }

        _;
    }

    function mintReserve(address[] calldata addresses) public onlyOwner qtyAvailable(addresses.length){
        for (uint256 i = 0; i < addresses.length; i++) {
            _mintAnElement(addresses[i]);
        }
    }

    function presaleShib() public qtyAvailable(1) {
        require(_presaleList[_msgSender()], 'Not Whitelist');
        shibToken.transferFrom(_msgSender(), address(this), 220000 * 10 ** 18);

        _presaleList[_msgSender()] = false;
        _mintAnElement(_msgSender());
    }

    function presaleMint() public payable qtyAvailable(1) {
        require(_presaleList[_msgSender()], 'Not Whitelist');
        require(msg.value >= 0.002 ether, "NSF");

        _presaleList[_msgSender()] = false;
        _mintAnElement(_msgSender());
    }

    function mintWShib() public {
        shibToken.transferFrom(_msgSender(), address(this), SHIB_PRICE * 10 ** 18);
        if (_msgSender() != owner()) {
            require(saleLive == true, "SNA");
        }

        _mintAnElement(_msgSender());
    }

    function mint() public payable qtyAvailable(1) {
        require(msg.value >= PRICE, "NSF");
        if (_msgSender() != owner()) {
            require(saleLive == true, "SNA");
        }

        _mintAnElement(_msgSender());
    }

    function _mintAnElement(address _to) private {
        _tokenCount.increment();
        uint id = _totalSupply() + 1;
        _safeMint(_to, id);
        emit CreateNft(id);
    }

    function price() public view returns (uint256) {
        return PRICE;
    }

    function priceShib() public view returns (uint256) {
        return SHIB_PRICE;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(frozen == false, "Frozen");
        baseTokenURI = baseURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetaUri;
    }

    function setContractPrivateValue(string memory varName, string memory varValue) public onlyOwner {
        require(frozen == false, "Frozen");

        if (keccak256(abi.encodePacked(varName)) == keccak256(abi.encodePacked("mintLimit"))) {
            require(st2num(varValue) >= 0, "invalid");
            _mintLimit = st2num(varValue);
        } else if (keccak256(abi.encodePacked(varName)) == keccak256(abi.encodePacked("mintPrice"))) {
            PRICE = st2num(varValue);
        } else if (keccak256(abi.encodePacked(varName)) == keccak256(abi.encodePacked("contractUri"))) {
            contractMetaUri = varValue;
        } else if (keccak256(abi.encodePacked(varName)) == keccak256(abi.encodePacked("shibPrice"))) {
            SHIB_PRICE = st2num(varValue);
        }
    }

    function freeze() public onlyOwner {
        frozen = true;
    }
    
    function toggleSale() public onlyOwner{
        require(frozen == false, "Frozen");
        saleLive = !saleLive;
    }

    function withdrawShib(address to) public onlyOwner {
        shibToken.transfer(to, shibToken.balanceOf(address(this)));
    }

    function withdrawAll(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(to, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success,) = _address.call{value : _amount}("");
        require(success, "Transfer failed.");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721Enumerable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function st2num(string memory numString) private pure returns(uint) {
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }
}
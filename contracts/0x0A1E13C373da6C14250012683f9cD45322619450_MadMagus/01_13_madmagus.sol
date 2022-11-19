pragma solidity >= 0.8.7;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MadMagus is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private supply;

    string baseURI;
    string public uriPrefix = "https://github.com/cryptonft/madmagus/raw/main/";

    uint256 public maxSupply = 1111;

    uint256 public price = 0.015 ether;

    mapping(address => uint256) public rates;

    


    bool public paused = false;

    constructor() ERC721("Mad Magus", "MAGUS") {
    }


    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 quantity) public payable {
        require(!paused, "The contract is paused!");
        require(quantity + totalSupply() <= maxSupply, "ERROR: Sold out");
            if(balanceOf(_msgSender()) == 0) {
                require(msg.value >= price * (quantity - 1), "ERROR: Incorrect value");
            } else {
                require(msg.value >= price * quantity, "ERROR: Incorrect value");
            }
            _mintLoop(msg.sender, quantity);
    }

    function devMint(address to, uint quantity) external onlyOwner {
        require(quantity + totalSupply() <= maxSupply, "ERROR: Sold out");
        _mintLoop(to, quantity);
    }
    

    function setRate(uint256 rate, address tokenAddress) external onlyOwner  {
        rates[tokenAddress] = rate; // * 10 ** 18
    }

    function collabMint(uint qty, address tokenAddress) external payable {
        require(qty+ totalSupply() <= maxSupply, "ERROR: Sold out");
        uint256 rate = rates[tokenAddress];
        require(rate > 0, "ERROR: Invalid Token");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), rate * qty);         //pay $clay or other currency
        _mintLoop(_msgSender(), qty);
    }

    function withdrawERC20(address _tokAddress, address treasuryWallet, uint256 amt) external onlyOwner {
        IERC20(_tokAddress).transfer(treasuryWallet, amt); 
    }

    function withdrawOwner() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function setPrice(uint256 _p) public onlyOwner {
        price = _p;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
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
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
            : "";
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

     function setMaxSupply(uint256 _supply) external onlyOwner {
        maxSupply = _supply;
    }  

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
        supply.increment();
        _safeMint(_receiver, supply.current());
        }
    }
}
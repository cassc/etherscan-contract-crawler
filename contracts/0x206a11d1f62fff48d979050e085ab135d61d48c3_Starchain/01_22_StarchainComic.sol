pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.3/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract Starchain is ERC721PresetMinterPauserAutoId {
    
    using Strings for uint256;
    
    IERC721 public SCContract = IERC721(0x9e731cBa0deecE52FD7c3B439E2ec4b950E385D6);
   
    uint16 public maxSupply = 1000;
    uint256 public price = 100000000000000000; // start at 0.1 ETH
    address payable account1 = payable(0x551E0713059896774721025e9953FCBE073AB4cE); // amun-ra
    address payable account2 = payable(0x221728354433C8329481c9CB413fBAE7A0F6C6d3); // cybersage
    address payable account3 = payable(0x3258E64Cf0C51BA9099472c2ADc8D83Fa13831D9); // lazerhawk5000
    string URIRoot = "https://starchainnft.mypinata.cloud/ipfs/QmaF8SuQqiMagVcWaQrFrGnmU6Cstk4MFhBJU8F4zQTSTL/Cover-";
   
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor() ERC721PresetMinterPauserAutoId("Starchain Comic Cover #1", "SCC", URIRoot) {
        _tokenIds.increment();
    }
    
    function redeemEligible(address _address) public view returns (bool) {
        uint scBalance = SCContract.balanceOf(_address);
        uint scComicBalance = balanceOf(_address);
        bool e = false;
        if (scBalance >= 5 && scComicBalance < 1) {
            e = true;
        }
        return e;
    }
    
    function changePrice(uint256 _price) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        price = _price;
    }
    
    function changeURI(string memory _newURI) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You don't have permission to do this.");
        URIRoot = _newURI;
    }
    
    function redeem() payable external {
        uint scBalance = SCContract.balanceOf(msg.sender);
        uint scComicBalance = balanceOf(msg.sender);
        require(scBalance >= 5 && scComicBalance < 1, "not elligible.");
        mintNFT(1);
    }
    
    function buy() payable external {
        uint256 p = price;
        require(msg.value >= p, "Not enough ETH.");
        mintNFT(1);
        payAccounts();
    }
    
    function mintNFT(uint16 amount)
    private
    {
        for (uint i = 0; i < amount; i++) {
            uint256 totalMinted = totalSupply();
            require((totalMinted + 1) < maxSupply, "Sold out.");
            _mint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(URIRoot, tokenId.toString(), ".json")) : "";
    }
    
    // send contract balance to addresses 1 and 2
    function payAccounts() public payable {
        uint256 balance = address(this).balance;
        if (balance != 0) {
            account1.transfer((balance * 33 / 100));
            account2.transfer((balance * 33 / 100));
            account3.transfer(balance * 33 / 100);
        }
    }
}
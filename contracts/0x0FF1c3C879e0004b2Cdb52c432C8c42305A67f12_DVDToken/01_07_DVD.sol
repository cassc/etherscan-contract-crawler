pragma solidity ^0.8.7;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/Base64.sol";
enum SaleState {
    NOSALE, PUBLICSALE
}

contract DVDToken is ERC721A('Now that I have your attention...', 'DVD'), Ownable {
    using LibString for uint256;
  
    string artUri = "https://d38aca3d381g9e.cloudfront.net/";   

    uint256 public price = .0025 ether;
    uint256 public maxSupply = 2525;

    mapping(address => uint256) public minted;

    SaleState public saleState = SaleState.NOSALE;

    address constant BIG = 0x3B3c548c5c230696ADf655B6b186014A5bBab3c4;
    address constant SAVAGE = 0x9879edf4D3c72D7b5941cc3eD3Ca57D68F42c4Ac;

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(
            'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                        '{"name": "Loading... #', _tokenId.toString(), 
                        '", "description":"', 
                        "Now that I have your attention...",
                        '","image":"',
                        artUri,
                        "office.png",
                        '", "animation_url": "', 
                        artUri, 
                        _tokenId.toString(), '.html'
                        '",',
                        '"attributes": [{',
                        '"trait_type": "corner", "value": "',
                        "???",
                        '"}]}')))));
    }

    function publicMint(uint256 count) external payable {
        require(msg.value >= (price * count), "not sending enough ether for mint");
        require(totalSupply() + count <= maxSupply);
        require(saleState == SaleState.PUBLICSALE, "Not in public sale");
        require(minted[msg.sender] + count < 5, "mint is max 5 only");
        minted[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function ownerMint(address _user, uint256 _count) external onlyOwner {
        require(totalSupply() + _count <= maxSupply);
        _safeMint(_user, _count);
    }

    function setSaleState(SaleState newSaleState) external onlyOwner {
        saleState = newSaleState;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setArtUri(string memory _newArtUri) external onlyOwner {
        artUri = _newArtUri;
    }

    function withdrawEth() external {
        payable(BIG).call{value: address(this).balance / 5}('');
        payable(SAVAGE).call{value: address(this).balance}('');
    }
}
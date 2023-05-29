//Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8 < 0.9.0;

//OpenZeppelin contract/token imports
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//Contract instantiation
contract LegionsOfLoud is ERC721Enumerable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    mapping(string => bool) private _usedNonces;
    address private _signerAddress = 0xF5FF2CC2Ee8b4eA2C03F0cf0c93fd3a867Da9E8A; // Contract wallet
    uint public constant lolBadges = 7200; // Total number of token ID's
    uint256 private _priceOfToken = 69000000000000000; // Total cost per token minted is 0.069 ETH
    string private _tokenURIBaseURL = "https://api.legionsofloud.com/meta/"; //Base URL of token metadata
    bool public tokenSale = true; // True means sale is active, false means sale is not active.

    constructor() ERC721("Legions of Loud", "LOL") {}

    function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, nonce)))
        );
        return hash;
    }
        
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signerAddress == hash.recover(signature);
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }

    function reUp(bytes memory signature, string memory nonce, uint256 token_quantity) external payable nonReentrant {
        require(matchAddresSigner(hashTransaction(msg.sender, token_quantity, nonce), signature), "DIRECT MINT IS NOT ALLOWED please visit www.legionsofloud.com");
        require(!_usedNonces[nonce], "HASH USED");
        _usedNonces[nonce] = true;
        require(token_quantity + totalSupply() <= lolBadges, "The max amount of tokens has been reached, per contract.");
        require(tokenSale, "Tokens are not for sale.");
        require(token_quantity <= 20, "The token amount entered is above the allowable limit of 20 per transaction.  Please enter a lesser amount.");
        require(msg.value >= tokenPrice(token_quantity), "You have insufficient funds.");
        for (uint i = 0; i < token_quantity; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }    
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function tokenOnSale(bool _isTokenSale) public onlyOwner {
        tokenSale = _isTokenSale;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenURIBaseURL;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _tokenURIBaseURL = baseURI;
    }

    function tokenPrice(uint token_quantity) public view returns (uint256) {
        return _priceOfToken * token_quantity;
    }
    
    // Just in case ETH does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _priceOfToken = _newPrice;
    }
    
    function getPrice() public view returns (uint256){
        return _priceOfToken;
    }



    // Contract Payout Structure
    address constant dev1Address = 0x9F90601582eD28922a81156a60aad0cf0fd69203; // Dev 1 address
    address constant dev2Address = 0xC7067F6Ed87F0fd8D5Cc47AD0F0C0b512a3CC275; // Dev 2 address
    address constant owner2Address = 0x70716Bd3E3E46e93E220E92045af42F2907Bbb9B; // Owner 2 address
    address constant artAddress = 0x80528F38843d19eCf558df2655354c99F05731a3; // Artist address
    uint constant dev1Fee = 13;
    uint constant dev2Fee = 12;
    uint constant artFee = 10;
    uint constant owner2Fee = 32;
    uint private constant sumShare = 100;

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;

        uint dev1Transfer = (balance * dev1Fee)/sumShare;
        uint dev2Transfer = (balance * dev2Fee)/sumShare;
        uint artTransfer = (balance * artFee)/sumShare;
        uint owner2Transfer = (balance * owner2Fee)/sumShare;
        uint partnerTransfer = balance - (dev1Transfer + dev2Transfer + artTransfer + owner2Transfer);

        payable(dev1Address).transfer(dev1Transfer);
        payable(dev2Address).transfer(dev2Transfer);
        payable(artAddress).transfer(artTransfer);
        payable(owner2Address).transfer(owner2Transfer);
        payable(msg.sender).transfer(partnerTransfer);
        require(address(this).balance == 0);
    }
}
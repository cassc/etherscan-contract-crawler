// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Anxiopeth is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 3000;
    uint256 public BURN_LIMIT = 1500;
    uint256 public burnedTokens = 0;
    uint256 public reservedTokensMinted = 0;
    uint256 public PRICE = 0.0096 ether; 
    
    bool public burnIsActive = false;
    bool public publicIsActive = false;

    IERC721 public immutable _sociopeth;

    mapping(address => bool) public publicClaimed;

    string public uriSuffix = ".json";
    string public baseURI = "";

    address payable private guy = payable(0xA778705aD62FC052c814b0d6b2F7c64aA1b10AE1);

    address public constant BLACKHOLE = 0x000000000000000000000000000000000000dEaD;

    constructor(
        address sociopeth,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721(_tokenName, _tokenSymbol) {
        _sociopeth = IERC721(sociopeth);
    }


    //Burn function
    function anxiopethClaim(uint256[] memory tokenIds) external {
        require(burnIsActive, "Burn must be active to mint");
        require(!exists1(tokenIds), "You must not hold 1/1 sociopeth");
        require(tokenIds.length >= 2 , "You must hold a sociopeth pairs");
        uint32 pairs = uint32(tokenIds.length / 2);
        require(pairs + burnedTokens <= BURN_LIMIT, "Exceed holder supply");
        
        for (uint256 i = 0; i < pairs*2; i++) {       
            _sociopeth.transferFrom(msg.sender, BLACKHOLE, tokenIds[i]);
        }
        for (uint256 i = 0; i < pairs; i++ ) {
            _safeMint(msg.sender, totalSupply() + 1);
            burnedTokens++;
        }
    }

    function exists1(uint256[] memory tokenIds) public view returns (bool) {
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == 3648 || tokenIds[i] == 3454 || tokenIds[i] == 3287 || tokenIds[i] == 3270 || tokenIds[i] == 3257 || tokenIds[i] == 3205 || tokenIds[i] == 3049 || tokenIds[i] == 3051 || tokenIds[i] == 2889 || tokenIds[i] == 2857 || tokenIds[i] == 2848 || tokenIds[i] == 2808 || tokenIds[i] == 2352 || tokenIds[i] == 2270 || tokenIds[i] == 2167 || tokenIds[i] == 1811 || tokenIds[i] == 1793 || tokenIds[i] == 1780 || tokenIds[i] == 1702 || tokenIds[i] == 1306 || tokenIds[i] == 1142 || tokenIds[i] == 1096 || tokenIds[i] == 1100 || tokenIds[i] == 1014 || tokenIds[i] == 897 || tokenIds[i] == 866 || tokenIds[i] == 745 || tokenIds[i] == 717 || tokenIds[i] == 525 || tokenIds[i] == 41 ) {
                return true;
            }
        }
        return false;
    }   

    function mint() public payable {
        require(publicIsActive, "Sale must be active to mint");
        require(!publicClaimed[msg.sender], "Address already adopted a sociopeth!");
        require(totalSupply() + 1 <= MAX_TOKENS - (50 - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * 1, "Insufficient funds!");

        publicClaimed[msg.sender] = true;
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function mintReservedTokens(uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= 50, "This amount is more than max allowed");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
            reservedTokensMinted++;
        }
    }

    //Utility function
    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function flipSaleState() external onlyOwner 
    {
        publicIsActive = !publicIsActive;
    }

    function flipBurnSaleState() external onlyOwner 
    {
        burnIsActive = !burnIsActive;
    }


    function withdraw() external
    {
        require(msg.sender == guy || msg.sender == owner(), "Invalid sender");
        (bool success, ) = guy.call{value: address(this).balance / 100 * 50}("");
        (bool success2, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer 1 failed");
        require(success2, "Transfer 2 failed");
    }


    ////
    //URI management part
    ////   

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
            baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
  
}
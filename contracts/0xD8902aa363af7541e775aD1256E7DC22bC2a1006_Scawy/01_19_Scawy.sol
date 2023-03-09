// SPDX-License-Identifier: Unlicensed

/*
 Scawy needs attention because he can't do it on his own. 
 So help him grow, make him happy and he will ride along. 
 ou never know with a ghost, he may even scare you. 

 Website: https://scawy.club
 Twitter: https://twitter.com/scawy_yo
                                                                                                                                                         
                         &@@@@&&&&&&&&&&&&&&&&&&&&&@@@@.                        
                       @@@.                           #@@.                      
                      %@&                              [email protected]@                      
                      @@.                               &@%                     
           (@@@@@@@(.&@@           &@@*   @@@.          [email protected]@ *%@@@@@@@           
          @@%      ,&@@             %#    .&*            %@@(.      @@,         
          @@                                                        %@%         
           @@@@*                                                .&@@@/          
              [email protected]@@@#                                        ,@@@@/              
                   @@                                      @@#                  
                  #@&    ,@@@@@@&#/,*,,,,,,,*,/(%@@@@@@@    [email protected]@                  
                  @@,    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,    @@#                 
                 #@@    *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    ,@@                 
                 @@.    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@(                
                /@@      #@@@@@@@@@@@@&#(%@@@@@@@@@@@@@      ,@@                
                @@*         @@@@@@@@@@@@@@@@@@@@@@@@/         @@/               
               (@@                                            *@@               
               @@@@&#*.                                   ,/%@@@@/              
                    .*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(,.                   
*/


pragma solidity ^0.8.17;

import "./contracts/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract Scawy is ERC721Enumerable, Ownable, DefaultOperatorFilterer, AccessControl {
    using Strings for uint256;

    string _baseTokenURI = ""; // base URI
    uint256 private _price = 0.05 ether; // price of NFT
    bool public _paused = true; // if true, minting is paused (update it via pause function)
    uint256 public _maxNFTAmount = 20; // maximum amount of NFTs per wallet
    uint256 public _maxSupply = 1000; //maximum supply of NFTs


    // withdraw addresses
    address marketingAddress1 = 0x50C5BE4FB534DE3703258e2515ad552f8f63354A;


    modifier canWithdraw() {
        require(address(this).balance > 0 ether);
        _;
    }

    struct MarketingAddresses {
        address payable addr;
        uint256 percent;
    }

    MarketingAddresses[] marketingAddresses;

    constructor() ERC721("Scawy", "Scawy") {
        marketingAddresses.push(
            MarketingAddresses(payable(address(marketingAddress1)), 100)
        );
    }


    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();

        require(!_paused, "Minting paused");
        require(
            num <= _maxNFTAmount,
            "You can mint a maximum of 20 NFT at the time"
        ); 
        require(supply + num <= _maxSupply, "Exceeds maximum NFT supply");
        require(msg.value >= _price * num, "Ether sent is not correct");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i); 
        }
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }


    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    // Withdraw ETH from NFT contract
    function withdraw() external payable onlyOwner canWithdraw {
        uint256 nbalance = address(this).balance;
        for (uint256 i = 0; i < marketingAddresses.length; i++) {
            MarketingAddresses storage m = marketingAddresses[i];
            (bool success, ) = payable(m.addr).call{value: (nbalance * m.percent) / 100} ("");
            require(success, "Failed to withdraw");
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override (ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override (ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override (ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override (ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override (ERC721, IERC721)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract FuglyAliens is ERC721A, Ownable, ERC2981, ReentrancyGuard{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1778;
    uint256 public constant MAX_PUBLIC_MINT = 17;
    uint256 public cost = 0.03 ether; 
    address public payout;

    string private  baseTokenUri;
    


    mapping(address => uint256) public totalPublicMint;

    constructor(uint96 _royaltyFeesInBips, string memory URI, address _royal, address _payout) ERC721A("The Fugly - Vintage Genesis", "FUGLY"){
        setRoyaltyInfo(_royal, _royaltyFeesInBips);
        setPayout(_payout);
        baseTokenUri = URI;
        

    }



    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
 
  
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, tokenId.toString(), ".json")) : "";
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = _startTokenId(); tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    // method overriden to start token ID from 1.
    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    //Interface overide for royalties
     function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId);
    }

    //Only Owner Functions
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function setPayout(address _payout) public onlyOwner {
        payout = _payout;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    function setPrice(uint256 _cost) external onlyOwner {
        cost = _cost;

    }

    function mint(uint256 _quantity) payable external {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Max mint for wallet!");
        require(msg.value >= _quantity * cost, "Insufficient funds");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }


    function AdminMint(uint256 _quantity, address _recepient) external onlyOwner {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        
        totalPublicMint[msg.sender] += _quantity;
         _safeMint(_recepient, _quantity);
    }
  
    function withdraw() public payable onlyOwner {
        (bool success,) = payable(payout).call{value: address(this).balance}("");
        require(success);
    }
}
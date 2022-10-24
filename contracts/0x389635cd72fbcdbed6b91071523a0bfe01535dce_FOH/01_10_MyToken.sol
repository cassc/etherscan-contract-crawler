// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

contract FOH is ERC721A, Ownable, ERC2981 {
    bool public isPublicSaleActive = false;
    bool public usedTeamMint = false;

    string private baseURI;
    string private baseContractDataUri;
    uint public maxSupply = 333;
    uint96 defaultRoyaltyPercentage = 5;

    mapping(address => bool) private usedMint; 

    constructor(string memory _baseNftURI, string memory _baseContractDataURI) ERC721A("FOH", "THE FACE OF HELL") {
        baseURI = _baseNftURI;
        baseContractDataUri = _baseContractDataURI;

        setDefaultRoyalty(address(this), defaultRoyaltyPercentage);
    }

    function teamMint(uint256 count) public onlyOwner {
        require(usedTeamMint == false, "The team has already minted!");
        _safeMint(msg.sender, count);
        usedTeamMint = true;
    }

    function setDefaultRoyalty(address receiver, uint96 royaltyPercentage) public onlyOwner {
        _setDefaultRoyalty(receiver, royaltyPercentage * 100);
    }

    function setBaseUri(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    
    function publicMint() public payable {
        require(totalSupply() + 1 <= maxSupply, "All NFT have already been minted!");
        require(isPublicSaleActive == true, "Public sale is inactive!");
        require(usedMint[msg.sender] == false, "You've already minted!");
        require(msg.sender == tx.origin, "Sry about that :(");

        _safeMint(msg.sender, 1);
        usedMint[msg.sender] = true;
    }

    
    function togglePublicSale() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }


    function withdrawMoney(address receiver) public onlyOwner {
        address payable _to = payable(receiver);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns(bool){
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseContractDataUri, "contract_data.json"));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(_baseURI()).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json")) : '';
    }

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    receive() external payable {
        
    } 
}
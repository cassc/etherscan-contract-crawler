// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// implements the ERC721 standard
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MonkeyBet is ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _Ids;
    using SafeMath for uint256;
    
    uint256 private MAX_MONKEYS = 10000;

    string private baseURI = "https://api.monkeybet.co/token/";

    address private tokenContractAddress = 0x1850b846fDB4d2EF026f54D520aa0322873f0Cbd;
    
    uint256 monkeyPrice = 0.05 ether;
    bool private saleActive = true;

    address payable private _owner;
    address payable private _manager;

    uint256 private tokenRewards = 25000 ether;

    constructor(address manager) ERC721("MonkeyBet", "MBET") {
        _owner = payable(msg.sender);
        _manager =  payable(manager);
    }

    function buy(uint256 monkeysQty) external payable {
        require(saleActive == true, "Sales are currently close");
        require(totalSupply() < MAX_MONKEYS, "Sold Out");
        require(monkeysQty > 0, "monkeysQty cannot be 0");
        require(monkeysQty <= 100, "You may not buy more than 100 Monkeys at once");
        require(totalSupply().add(monkeysQty) <= MAX_MONKEYS, "Sale exceeds available Monkeys");
        uint256 salePrice = monkeyPrice.mul(monkeysQty);
        require(msg.value >= salePrice, "Insufficient Amount");

        for (uint i = 0; i < monkeysQty; i++) {
            _Ids.increment();
            uint256 newItemId = _Ids.current();
            _safeMint(msg.sender, newItemId);
        }
       
        _manager.transfer(msg.value);
        ERC20 (tokenContractAddress).transfer(msg.sender, tokenRewards * monkeysQty);

    }

    function tokensOfOwner(address owner)
        external
        view
        returns (string[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new string[](0);
        } else {
            string[] memory result = new string[](tokenCount);
            uint256 resultIndex = 0;
            uint256 Id;

            for (Id = 1; Id <= tokenCount; Id++) {
                result[resultIndex] = tokenURI((tokenOfOwnerByIndex(owner, Id - 1)));
                resultIndex++;
            }

            return result;
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        baseURI = baseURI_;
    }

        function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function withdrawTokens() external onlyOwner {  
        ERC20 (tokenContractAddress).transfer(_owner, ERC20 (tokenContractAddress).balanceOf(address(this)));
    }

    function toogleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function statusSale() public view returns (bool status){
       return (saleActive);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "0"));
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
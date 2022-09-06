// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Counters.sol";
import "@openzeppelin/[email protected]/utils/Strings.sol";




import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";





contract Curaited is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    

    Counters.Counter private tokenCounter;

    uint256 MAX_SUPPLY = 222;
    uint256 public constant TOKENPRICE = 0.025 ether;

    constructor() ERC721("Curaited", "CRTD") {}


     modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }


    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmdcgNRdevHHxCRmJAGW8F7dgJJC4hhE2xxkznXzqC2D4j/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    //Minting
    function mint(uint256 quantity) external payable isCorrectPayment(TOKENPRICE, quantity) {

        require(totalSupply() + quantity <= MAX_SUPPLY);



        
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }


        function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

     function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

     function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked("ipfs://QmdcgNRdevHHxCRmJAGW8F7dgJJC4hhE2xxkznXzqC2D4j/", "/", tokenId.toString(), ".json"));
    }
}
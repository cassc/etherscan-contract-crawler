pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//        the hundreds ABS broken backgrounds X nervous.eth
//  
//   █████╗ ██████╗ ███████╗    ██████╗ ██████╗  ██████╗ ██╗  ██╗███████╗███╗   ██╗    ██████╗  █████╗  ██████╗██╗  ██╗ ██████╗ ██████╗  ██████╗ ██╗   ██╗███╗   ██╗██████╗ ███████╗
//  ██╔══██╗██╔══██╗██╔════╝    ██╔══██╗██╔══██╗██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║    ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝ ██╔══██╗██╔═══██╗██║   ██║████╗  ██║██╔══██╗██╔════╝
//  ███████║██████╔╝███████╗    ██████╔╝██████╔╝██║   ██║█████╔╝ █████╗  ██╔██╗ ██║    ██████╔╝███████║██║     █████╔╝ ██║  ███╗██████╔╝██║   ██║██║   ██║██╔██╗ ██║██║  ██║███████╗
//  ██╔══██║██╔══██╗╚════██║    ██╔══██╗██╔══██╗██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║    ██╔══██╗██╔══██║██║     ██╔═██╗ ██║   ██║██╔══██╗██║   ██║██║   ██║██║╚██╗██║██║  ██║╚════██║
//  ██║  ██║██████╔╝███████║    ██████╔╝██║  ██║╚██████╔╝██║  ██╗███████╗██║ ╚████║    ██████╔╝██║  ██║╚██████╗██║  ██╗╚██████╔╝██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝███████║
//  ╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚══════╝
//                                                                                                                                                                                  
//  ██╗  ██╗                                                                                                                                                                        
//  ╚██╗██╔╝                                                                                                                                                                        
//   ╚███╔╝                                                                                                                                                                         
//   ██╔██╗                                                                                                                                                                         
//  ██╔╝ ██╗                                                                                                                                                                        
//  ╚═╝  ╚═╝                                                                                                                                                                        
//                                                                                                                                                                                  
//  ███╗   ██╗███████╗██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗███████╗                                                                                                                   
//  ████╗  ██║██╔════╝██╔══██╗██║   ██║██╔═══██╗██║   ██║██╔════╝                                                                                                                   
//  ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║   ██║██║   ██║███████╗                                                                                                                   
//  ██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║   ██║██║   ██║╚════██║                                                                                                                   
//  ██║ ╚████║███████╗██║  ██║ ╚████╔╝ ╚██████╔╝╚██████╔╝███████║                                                                                                                   
//  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝   ╚═════╝  ╚═════╝ ╚══════╝                                                                                                                   
//
//        work with us: nervous.net // [email protected]

contract NervousNFT is ERC721, ERC721Enumerable, Ownable {
    uint256 public MAX_TOKENS = 267;

    uint256 public MAX_GIFTS = 267;
    uint256 public numberOfGifts;

    string public baseURI;

    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> [email protected]";

    constructor(
        string memory name,
        string memory symbol,
        string memory _initBaseURI,
        uint256 _maxTokens,
        uint256 _maxGifts
    ) ERC721(name, symbol) {
        MAX_TOKENS = _maxTokens;
        MAX_GIFTS = _maxGifts;
        
        setBaseURI(_initBaseURI);
    }

    /* Magic */

    function magicGift(address[] calldata receivers) external onlyOwner {
        require(
            totalSupply() + receivers.length <= MAX_TOKENS,
            "Exceeds maximum token supply"
        );
        require(
            numberOfGifts + receivers.length <= MAX_GIFTS,
            "Exceeds maximum allowed gifts"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            numberOfGifts++;
            uint256 mintIndex = totalSupply();
            _safeMint(receivers[i], mintIndex);
        }
    }

    /* URIs */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
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
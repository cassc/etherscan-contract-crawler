// SPDX-License-Identifier: MIT
//  _   _               _               ______              _        _     
// | \ | |             | |              |  ___|            | |      | |    
// |  \| | _____      _| |_ ___  _ __   | |_ _ __ __ _  ___| |_ __ _| |___ 
// | . ` |/ _ \ \ /\ / / __/ _ \| '_ \  |  _| '__/ _` |/ __| __/ _` | / __|
// | |\  |  __/\ V  V /| || (_) | | | | | | | | | (_| | (__| || (_| | \__ \
// \_| \_/\___| \_/\_/  \__\___/|_| |_| \_| |_|  \__,_|\___|\__\__,_|_|___/
// 
//
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NewtonFractals is ERC721, ERC721Enumerable, Ownable {
    bool private _active;
    string private _baseURIextended;
	uint256 private _activeTime;
    uint constant MAX_TOKENS = 2048;
    uint constant FREE_MINTS = 32;
    uint16 INT16_LIMIT = 65535 - 1;

    struct Minted {
        address tokenOwner;
        uint timestamp;
        uint order;
    }

    mapping(uint => Minted) public mintedMap;
    uint[] polyOrders = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
    30];

    constructor() ERC721("NewtonFractals", "NTFR") {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }
	
	function activate() external onlyOwner {
        require(!_active, "Already active");
        _activeTime = block.timestamp;
        _active = true;
    }
	
	function deactivate() external onlyOwner {
        require(_active, "Already inactive");
        delete _activeTime;
        _active = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }	
	
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, polyOrders, totalSupply())));
    }

    function getCoefficients(uint tokenId) public view returns(uint, uint [] memory) {
        require(_active, "Inactive");
        require(_exists(tokenId), "ERC721Metadata: getCoefficients query for nonexistent token");

        Minted memory m = mintedMap[tokenId];
        uint [] memory res = new uint[](m.order);

        for (uint i = 0; i < m.order; i++) {
            uint c = uint(keccak256(abi.encodePacked(m.timestamp, 
                                            m.tokenOwner, 
                                            tokenId, i))) % INT16_LIMIT;
            res[i] = c;
        }

        return (m.order, res);
    }

    function mintFree() public payable {
        require(_active, "Inactive");
        require(totalSupply() + 1 <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(totalSupply() <= FREE_MINTS, "Sorry, no more free mints available!");
        require(balanceOf(msg.sender) < 1, "Sorry, no freee mints if you already own a NewtonFractal");
        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
        require(_exists(mintIndex), "ERC721Metadata: nonexistent token");
        _mintNewtonFractal(mintIndex);

    }
    
    function mint(uint numberOfTokens) public payable {
        require(_active, "Inactive");
        require(numberOfTokens <= 20, "Exceeded max purchase amount");
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(0.025 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
                require(_exists(mintIndex), "ERC721Metadata: nonexistent token");
                _mintNewtonFractal(mintIndex);
            }
        }
    }

    function _mintNewtonFractal(uint mintIndex) private {
        uint polyOrderIndex = random() % polyOrders.length;
        uint polyOrder = polyOrders[polyOrderIndex];
        Minted memory m = Minted(msg.sender, block.timestamp, polyOrder);
        mintedMap[mintIndex] = m;
    }
    
	
	function withdraw(address payable recipient, uint256 amount) public onlyOwner {
		recipient.transfer(amount);
    }

    
}
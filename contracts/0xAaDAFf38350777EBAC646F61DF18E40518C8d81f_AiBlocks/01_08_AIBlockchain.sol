// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AiBlocks is ERC721A, Ownable {
    using Strings for uint256;

    struct CommonValues {
        uint256 h;
        uint256 numRectangles;
        uint256 numBlocks;
    }

    uint256 public maxSupply = 5555;
    uint256 public maxFreePerWallet = 3;
    uint256 public maxPerTx = 10;
    uint256 FREE_MINTS = 1200;
    uint256 MAX_FREE_MINT_PER_EOA = 3;
    uint256 MAX_MINT_VALUE = 10;
    uint256 public MINT_PRICE =  0.0015 ether;

    mapping(address=>uint256) public numberMinted;
    mapping(address=>uint256) public claimedWhiteListCount;

    constructor() ERC721A("AIBlockchain", "BOC") {
        _mint(msg.sender, 100);
    }

function generateAttribute(uint256 tokenId) internal pure returns (string memory) {
    CommonValues memory commonValues = generateCommonValues(tokenId);

    string memory attributes = string(
            abi.encodePacked(
                '{"trait_type": "Blocks", "value": "',Strings.toString(commonValues.numBlocks),'"},',
                '{"trait_type": "Origin Block Size", "value": "', Strings.toString(commonValues.h), ' x ', Strings.toString(commonValues.h), ' px"}'
            )
        );

        return attributes;
    }   

function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "Token does not exist");
    string memory svg = generateSVG(tokenId);
    string memory attribute = generateAttribute(tokenId);
    string memory json = Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                    '{"name": "AiBlockchain On-Chain #',
                    tokenId.toString(),
                    '", ',
                    '"description": "The first forever evolving art collection, fully On-Chain animated block chains crafted by AI. Each NFT has a unique Origin Block that changes colors and positions as the Ethereum blockchain continues to grow.", ',
                    '"image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(svg)),
                    '", ',
                    '"attributes": [',
                    attribute,
                    ']} '
                )
            )
        )
    );
    
    return string(
        abi.encodePacked(
            'data:application/json;base64,', 
            json
        )
    );
}

function generateSVG(uint256 tokenId) public view returns (string memory) {
    CommonValues memory commonValues = generateCommonValues(tokenId);
    
    bytes memory svg = abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">'
    );
    for (uint256 i = 0; i < commonValues.numBlocks; i++) {
        uint256 seed = uint256(keccak256(abi.encodePacked(tokenId, i)));
        uint256 x = (seed % 160) + 10;
        uint256 y = (seed % 160) + 10;
        uint256 w = (seed % 40) + 10;
        uint256 h = (seed % 40) + 10;
        uint256 r = (seed % 255);
        uint256 g = (seed % 212)+3;
        uint256 b = (seed % 360);
        uint256 duration = (seed % 2000) + 500;
        uint256 delay = (seed % 2000);

        if (i == 0) {
            x = (block.timestamp % 160) + 20;
            y = (block.timestamp % 160) + 20;
            r = ((block.timestamp + seed) % 250);
            g = ((block.timestamp + seed) % 100);
            b = ((block.timestamp + seed) % 150);
        }

        bytes memory rect = abi.encodePacked(
            '<rect x="', x.toString(), '" y="', y.toString(), 
            '" width="', w.toString(), '" height="', h.toString(), 
            '" fill="rgb(', r.toString(), ',', g.toString(), ',', b.toString(), ')"',
            '>',
            '<animate attributeName="opacity" values="1;0.5;1" dur="', duration.toString(), 'ms" repeatCount="indefinite" begin="', delay.toString(), 'ms" />',
            '</rect>'
        );
        svg = abi.encodePacked(svg, rect);
    }
    
    svg = abi.encodePacked(svg, '</svg>');
    
    return string(svg);
}

function generateCommonValues(uint256 tokenId) pure internal returns (CommonValues memory) {
        uint256 numRectangles = (uint256(keccak256(abi.encodePacked(tokenId))) % 24) + 3;
        uint256 seed = uint256(keccak256(abi.encodePacked(tokenId,[0])));
        uint256 h = (seed % 40) + 10;
        uint256 numBlocks;
        
        numBlocks = numRectangles;

    return CommonValues(numRectangles,h,numBlocks);
}
  
    function mint(uint256 quantity) external payable {
        require(quantity <= MAX_MINT_VALUE, "Maximum per mint is 10"); 

        uint256 numberOfTokensAlreadyMinted = totalSupply();
        uint256 totalMinted = numberOfTokensAlreadyMinted + quantity;

        require(totalMinted <= maxSupply, "Number exceeds the maximum supply");

        if (claimedWhiteListCount[msg.sender] >= MAX_FREE_MINT_PER_EOA) {
            uint256 amount =  MINT_PRICE * quantity;
            require(msg.value >= amount, "Incorrect Amount");
            numberMinted[msg.sender] += quantity;
        }
        
        else if(totalMinted <= FREE_MINTS){
            claimedWhiteListCount[msg.sender] += quantity;
            require(claimedWhiteListCount[msg.sender] <= MAX_FREE_MINT_PER_EOA, "You've claimed all your whitelists");
        }
        
        else{
            uint256 amount =  MINT_PRICE * quantity;
            require(msg.value >= amount, "Incorrect Amount");
            numberMinted[msg.sender] += quantity;
        }

        _mint(msg.sender, quantity);     
    }  


    function Withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function freeMintsRemaining() public view returns(uint256 remainder) {
        uint256 tokensMinted = totalSupply();
        if(tokensMinted < FREE_MINTS){
            return FREE_MINTS - tokensMinted;
        }else{
            return 0;
        }
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner{
        MINT_PRICE = newMintPrice;
    }


    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _mint(_receiver, _mintAmount);
    }


    function setFreeMints(uint256 _freemints) public onlyOwner {
        FREE_MINTS = _freemints;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
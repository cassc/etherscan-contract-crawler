// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Counters.sol';
import "./interfaces/INogDescriptor.sol";
import "./library/Structs.sol";

contract Nogs is ERC721A, Ownable {

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                                set state
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */    
    
    using Counters for Counters.Counter;
    uint256 public price = 0.01 ether;
    uint256 public maxTokenSupply;
    bool public hasMaxTokenSupply = false;
    bool public mintActive = true;
    bool public mintMultipleActive = false;

    INogDescriptor public descriptor;
    Structs.NogStyle[] private nogStyles;

    mapping(uint256 => Structs.Nog) public nogSeeds;

    error MissingTokenId(uint256 tokenId, uint256 nextToken);

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                              set up contract
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    constructor(string memory tokenName, string memory tokenSymbol) ERC721A(tokenName, tokenSymbol) {}

    event DescriptorUpdated(INogDescriptor descriptor);

    function setDescriptor(INogDescriptor _descriptor) public onlyOwner {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                               mint
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function internalMint(address receiver, uint256 quantity) internal {
        for (uint256 i = 0; i < quantity; i++) {
            if (hasMaxTokenSupply) {
                require(_nextTokenId() <= maxTokenSupply - 1, 'Max token supply reached');
            }

            nogSeeds[_nextTokenId()] = constructTokenId(_nextTokenId(), receiver);
            _safeMint(receiver, 1);
        }        
    }

    function mint() external payable {   
        require(mintActive, 'Mint not active.');
        require(msg.value >= 1 * price, 'Wrong ETH value sent.');
        internalMint(msg.sender, 1);
    }

    function mintMultiple(uint256 quantity) external payable {   
        require(mintActive, 'Mint not active.');
        require(mintMultipleActive, 'Multiple mints not active.');
        require(msg.value >= quantity * price, 'Wrong ETH value sent.');
        internalMint(msg.sender, quantity);
    }

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                            construct nft
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId))
            revert MissingTokenId({
                tokenId: tokenId,
                nextToken: _nextTokenId()
            });
            
        Structs.Nog memory nog = nogSeeds[tokenId];

        return descriptor.constructTokenURI(nog, tokenId);
    }

    function constructTokenId(uint256 tokenId, address minterAddress) internal view returns (Structs.Nog memory) {
        uint16 shadowOdds = uint16(uint256(descriptor.getPseudorandomness(tokenId, 103))) % 100;
        uint16 animationOdds = uint16(uint256(descriptor.getPseudorandomness(tokenId, 109))) % 100;
        uint16 backgroundOdds = uint16(uint256(descriptor.getPseudorandomness(tokenId, 139))) % 100;
        bool hasShadow = false;
        bool hasAnimation = false;
        uint16 background = descriptor.getBackgroundIndex(backgroundOdds);
        if (shadowOdds > 7 && shadowOdds < 19) { hasShadow = true; }
        if (animationOdds > 69 && animationOdds < 96) { hasAnimation = true; }

        return
            Structs.Nog({
                minterAddress: minterAddress,
                nogStyle: uint16(uint256(descriptor.getPseudorandomness(tokenId, 13))) % descriptor.getStylesCount(),
                backgroundStyle: background,
                hasShadow: hasShadow,
                hasAnimation: hasAnimation,
                colorPalette: [
                    uint16(uint256(descriptor.getPseudorandomness(tokenId, 17))) % 7,
                    uint16(uint256(descriptor.getPseudorandomness(tokenId, 23))) % 7,
                    uint16(uint256(descriptor.getPseudorandomness(tokenId, 41))) % 7,
                    uint16(uint256(descriptor.getPseudorandomness(tokenId, 67))) % 7,
                    uint16(uint256(descriptor.getPseudorandomness(tokenId, 73))) % 7,
                    uint16(uint256(descriptor.getPseudorandomness(tokenId, 79))) % 7,
                    uint16(uint256(descriptor.getPseudorandomness(tokenId, 97))) % 5
                ]
            });
    } 

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           utility functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }    

    function isStringEmpty(string memory val) internal pure returns(bool) {
        bytes memory checkString = bytes(val);
        if (checkString.length > 0) {
            return false;
        } else {
            return true;
        }
    }
    
    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           owner functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  
    
    function toggleMint() external onlyOwner {
        mintActive = !mintActive;
    }

    function toggleMintMultiple() external onlyOwner {
        mintMultipleActive = !mintMultipleActive;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxTokenSupply(uint256 quantity) external onlyOwner {
        maxTokenSupply = quantity;
    }

    function toggleMaxTokenSupply() external onlyOwner {
        hasMaxTokenSupply = !hasMaxTokenSupply;
    }

    function ownerMintForOthers(address receiver, uint256 quantity) external onlyOwner {
        internalMint(receiver, quantity);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/**
                                                                                          
 #######  ##         ###    ##   ##                                                       
 ##       ##        ## ##   ##   ##                                                       
 ##       ##       ##   ##  ## # ##                                                       
 #####    ##       ##   ##  ## # ##                                                       
 ##       ##       ##   ##  ## # ##                                                       
 ##       ##        ## ##   ### ###                                                       
 ##       ######     ###    ##   ##                                                       
                                                                                          
   ####     ###    ##       ##       #######    ####   ######   ######   ##   ##  ####### 
  ##  ##   ## ##   ##       ##       ##        ##  ##    ##       ##     ##   ##  ##      
 ##       ##   ##  ##       ##       ##       ##         ##       ##     ##   ##  ##      
 ##       ##   ##  ##       ##       #####    ##         ##       ##      ## ##   #####   
 ##       ##   ##  ##       ##       ##       ##         ##       ##      ## ##   ##      
  ##  ##   ## ##   ##       ##       ##        ##  ##    ##       ##       ###    ##      
   ####     ###    ######   ######   #######    ####     ##     ######     ###    ####### 
                                                                                          
 */
contract FlowCollective is ERC721, ERC721Enumerable, Ownable, ERC721Royalty {
    using SafeMath for uint256;

    string public contractURI;

    bool public isSaleActive = false;
    bool public isAllowlistSaleActive = false;

    struct TokenLevelConfig {
        uint256 tokenPrice;
        uint256 maxSupply;
        string baseURI;
    }

    // max supply levels, that cannot be overflowed
    mapping(uint8 => TokenLevelConfig) private tokenLevelsConfig;

    // map levelIds to minted amounts
    mapping(uint8 => uint256) private totalSupplyPerLevel;
    // track which token belongs to which level, map tokenId => tokenLevel
    mapping(uint256 => uint8) private tokenLevels;

    uint256 public constant MAX_PUBLIC_MINT = 1;

    mapping(address => uint8) private _allowlist;

    constructor() ERC721('FlowCollective', 'FLOWH&R') {
        // setup initial config of token levels
        tokenLevelsConfig[1].maxSupply = 100;
        tokenLevelsConfig[1].tokenPrice = 0.05 ether;
        tokenLevelsConfig[1].baseURI = 'ipfs://QmXSLPJvRW1a1UAnpqjUhDhfPLe2KDBq9gxV9z1vaKDNZn/1/';

        tokenLevelsConfig[2].maxSupply = 400;
        tokenLevelsConfig[2].tokenPrice = 0.05 ether;
        tokenLevelsConfig[2].baseURI = 'ipfs://QmXSLPJvRW1a1UAnpqjUhDhfPLe2KDBq9gxV9z1vaKDNZn/2/';

        tokenLevelsConfig[3].maxSupply = 500;
        tokenLevelsConfig[3].tokenPrice = 0.05 ether;
        tokenLevelsConfig[3].baseURI = 'ipfs://QmXSLPJvRW1a1UAnpqjUhDhfPLe2KDBq9gxV9z1vaKDNZn/3/';
    }

    // token levels
    function getLevelOfTokenById(uint256 tokenId) public view returns (uint8) {
        _requireMinted(tokenId);
        return tokenLevels[tokenId];
    }

    function getTotalSupplyOfLevel(uint8 levelId) external view returns (uint256) {
        return totalSupplyPerLevel[levelId];
    }

    function getMaxSupplyOfLevel(uint8 levelId) external view returns (uint256) {
        return tokenLevelsConfig[levelId].maxSupply;
    }

    function getPricePerTokenOfLevel(uint8 levelId) external view returns (uint256) {
        return tokenLevelsConfig[levelId].tokenPrice;
    }

    function getBaseURIOfLevel(uint8 levelId) external view returns (string memory) {
        return tokenLevelsConfig[levelId].baseURI;
    }

    function setConfigOfLevel(
        uint8 levelId,
        uint256 maxSupply,
        uint256 tokenPrice,
        string memory baseURI
    ) external onlyOwner {
        tokenLevelsConfig[levelId].maxSupply = maxSupply;
        tokenLevelsConfig[levelId].tokenPrice = tokenPrice;
        tokenLevelsConfig[levelId].baseURI = baseURI;
    }

    // allowlist mint
    function setIsAllowlistSaleActive(bool isActive) external onlyOwner {
        isAllowlistSaleActive = isActive;
    }

    function setAllowlistAddresses(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint8 i = 0; i < addresses.length; i++) {
            _allowlist[addresses[i]] = numAllowedToMint;
        }
    }

    function allowlistMintAmount(address addr) external view returns (uint8) {
        return _allowlist[addr];
    }

    function mintAllowlisted(uint8 numberOfTokens, uint8 tokenLevel) external payable {
        uint256 ts = totalSupply();
        uint256 totalSupplyOfLevel = totalSupplyPerLevel[tokenLevel];
        uint256 maxSupply = tokenLevelsConfig[tokenLevel].maxSupply;
        uint256 pricePerToken = tokenLevelsConfig[tokenLevel].tokenPrice;

        require(isAllowlistSaleActive, 'Allowlist sale is not active');
        require(numberOfTokens <= _allowlist[msg.sender], 'Exceeded max available to purchase');
        require(totalSupplyOfLevel + numberOfTokens <= maxSupply, 'Purchase would exceed max tokens in this level!');
        require(pricePerToken * numberOfTokens <= msg.value, 'Ether value sent is not correct');

        _allowlist[msg.sender] -= numberOfTokens;
        totalSupplyPerLevel[tokenLevel] += numberOfTokens;
        for (uint8 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    // override base functions
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
        virtual
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_, uint8 levelId) external onlyOwner {
        tokenLevelsConfig[levelId].baseURI = baseURI_;
    }

    function _baseURI(uint8 levelId) internal view virtual returns (string memory) {
        return tokenLevelsConfig[levelId].baseURI;
    }

    /**
     * Override ERC721 tokenURI function to include levelOfToken
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        uint8 levelOfToken = getLevelOfTokenById(tokenId);
        string memory baseURI = _baseURI(levelOfToken);

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : '';
    }

    function setContractURI(string memory contractUri_) external onlyOwner {
        contractURI = contractUri_;
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function setDefaultRoyalty(address recipient, uint96 fraction) public {
        _setDefaultRoyalty(recipient, fraction);
    }

    // public mint
    function setIsSaleActive(bool isActive) public onlyOwner {
        isSaleActive = isActive;
    }

    function mint(uint8 numberOfTokens, uint8 tokenLevel) public payable {
        uint256 ts = totalSupply();
        uint256 totalSupplyOfLevel = totalSupplyPerLevel[tokenLevel];
        uint256 maxSupply = tokenLevelsConfig[tokenLevel].maxSupply;
        uint256 pricePerToken = tokenLevelsConfig[tokenLevel].tokenPrice;

        require(isSaleActive, 'Sale must be active to mint tokens');
        require(numberOfTokens <= MAX_PUBLIC_MINT, 'Exceeded max token purchase');
        require(totalSupplyOfLevel + numberOfTokens <= maxSupply, 'Purchase would exceed max tokens in this level!');
        require(pricePerToken * numberOfTokens <= msg.value, 'Ether value sent is not correct');

        totalSupplyPerLevel[tokenLevel] += numberOfTokens;
        for (uint8 i = 0; i < numberOfTokens; i++) {
            tokenLevels[(ts + i)] = tokenLevel;
            _safeMint(msg.sender, ts + i);
        }
    }

    // withdraw functions
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'Contract balance must be > 0');
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        require(address(this).balance >= _amount, 'Contract balance must be >= _amount');
        (bool success, ) = _address.call{value: _amount}('');
        require(success, 'Transfer failed.');
    }
}
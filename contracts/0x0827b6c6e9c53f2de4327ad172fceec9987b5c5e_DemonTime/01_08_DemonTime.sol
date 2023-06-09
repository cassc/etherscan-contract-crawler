// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//                                                      .-'''-.                                                                           
// _______                                             '   _    \                                                                         
// \  ___ `'.         __.....__      __  __   ___    /   /` '.   \    _..._                      .--. __  __   ___         __.....__      
//  ' |--.\  \    .-''         '.   |  |/  `.'   `. .   |     \  '  .'     '.                    |__||  |/  `.'   `.   .-''         '.    
//  | |    \  '  /     .-''"'-.  `. |   .-.  .-.   '|   '      |  '.   .-.   .               .|  .--.|   .-.  .-.   ' /     .-''"'-.  `.  
//  | |     |  '/     /________\   \|  |  |  |  |  |\    \     / / |  '   '  |             .' |_ |  ||  |  |  |  |  |/     /________\   \ 
//  | |     |  ||                  ||  |  |  |  |  | `.   ` ..' /  |  |   |  |           .'     ||  ||  |  |  |  |  ||                  | 
//  | |     ' .'\    .-------------'|  |  |  |  |  |    '-...-'`   |  |   |  |          '--.  .-'|  ||  |  |  |  |  |\    .-------------' 
//  | |___.' /'  \    '-.____...---.|  |  |  |  |  |               |  |   |  |             |  |  |  ||  |  |  |  |  | \    '-.____...---. 
// /_______.'/    `.             .' |__|  |__|  |__|               |  |   |  |             |  |  |__||__|  |__|  |__|  `.             .'  
// \_______|/       `''-...... -'                                  |  |   |  |             |  '.'                        `''-...... -'    
//                                                                 |  |   |  |             |   /                                          
//                                                                 '--'   '--'             `'-'                                           

import "ERC721A/ERC721A.sol";
import "OZ/token/common/ERC2981.sol";
import "OZ/utils/Strings.sol";

contract DemonTime is ERC721A {

    using Strings for uint256;

    address private L = 0x0c40BAa31D20574C8930a6e8f59fa2e11dFE17F2;
    string _baseTokenURI = "ipfs://QmaS2Xqvqu3gcUMRjguvibVMhEX6wByAPeQcct4vcjEYaK/";

    constructor () ERC721A ("Demon Time", "DEMON_TIME") {
        _mint(L, 500);
    }

    function summonDemon () external {
        require(_nextTokenId() < 5000, "MAX_SUPPLY");
        require(_numberMinted(msg.sender) == 0, "AlREADY_MINTED");
        _mint(msg.sender, 1);
    }

    function setBaseURI(string memory baseURI) external {
        require(msg.sender == L);
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory json = ".json";
        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), json)) : "";
    }

    function royaltyInfo ( 
        uint256 _tokenId, 
        uint256 _salePrice 
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        return (
            L, 
            _salePrice * 5 / 100 // 5% royalty
        );
    }

    function withdraw () external {
        uint balance =  address(this).balance;
        require(balance > 0);
        L.call{value: balance}("");
    }

    function setL (address newL) external {
        require(msg.sender == L);
        L = newL;
    }

    receive () external payable {

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
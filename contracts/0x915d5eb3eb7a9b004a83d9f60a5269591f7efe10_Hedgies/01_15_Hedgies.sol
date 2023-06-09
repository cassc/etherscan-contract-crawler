//Contract based on [https://docs.openzeppelin.com/contracts/4.x/erc721](https://docs.openzeppelin.com/contracts/4.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/*
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''.ƒ'']▓ ,..','''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''']µ]▄▐▄╫╫╬▀╬╬╬▓╬▀╬▌╬▓#▓░╓'''''''''''''''''''''''''''
''''''''''''''''''''''''''╥ƒ╔╣╬▀╠╫╬▌╠▓╣╠╫╬╫╠╣▌╬▀╬▓╬╬╫╗╦M''''''''''''''''''''''''
'''''''''''''╓#▀▒▀Φ▄,''╓,╓╟╬╬╠▌╬▓╠╫╬▒╫▌╬╣▒╬▌╬▌╣▒╣▌╠╬╬▒╬╬▌,,'''''''''''''''''''''
''''''''''''▄▒╗▀▀▀╗▄╨▀▄▓╬╬╠▓╬▓╬╠╬╬╠▌▒╬▌╠╬▌╠▌╠╬╬▓╠╬╬╬╬╠▓▒╬▓▄''''╥ÆΘΘ##▄''''''''''
''''''''''''▌░▓╫▒▒▒▒╬▀▄▀▒╬╬╬▒╬╬▒▓╬╠▒▀╬╬▒╠╠╬╬▒╬╬╠╬╬╫▓╠╣▒╣╠╠▌▄,▄╬▄▀╬╬▓G║▒'''''''''
''''''''''''▌░▓▓▒▒▒▒▒▒╬▌╨▌╠╫╬╠╠▒╫╣▀▌▀▀╨▀╨▀╨╩╨▀╨▀╨▀▀╩▓▀╣╬╬╬╠▓▌╬╬▒▒▒▓╣▒╫⌐'''''''''
''''''''''''╙▄│▓▒▒▒▒▒▒▒╠▓╨▌╬╬╩▀╙Ü└░│░░░░░░░░░░░░░░░░│░└┤╨╨╨▀╬╬▒▒▒▒▌▌▐▌''''''''''
'''''''''''''╙▄│▀▒▒▒▒▒▒▒╫▓▀┤░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╫╜▌▒╠╣╬╫╨'''''''''''
''''''''''''''└▀▄╨▀▒▒▒▒▌╫▀└░░░░▄▓███▀▌░░░░░░░░░░░░░░░▄███▀▌░░░▀╫╫▀╙'''''''''''''
''''''''''''''''└▓▄Q╙╨▓▄░░░░░░▐████  ▐▌░░░░░░░░░░░░░╟███▄ ╫▌░╟╬▓.'''''''''''''''
''''''''''''''''╓▓▒▌╬╬╬▓µ░░░░░╫███╣███▒░░░φ▒▒░▒▒▒▒φ░╫██▓███▀∞▓╬▓▄⌐''''''''''''''
'''''''''''''''*▌▌╫▒▌╬▀╫╫G░░░░╙██████▀░░▐▒░╫╬╬╬╬╬▓░╫░▓████▀░▐▌╠▓⌐'''''''''''''''
'''''''''''''''╨▀▓╠╣╬╬▓▌╬▌░░░░░░│╨▀╨¡░░▐▌░░░╬▀█▓▀▒▒Γ▌░╙╨┤░░▓╬▀╬▌⌐'''''''''''''''
''''''''''''''''╨▓╬▓╬╬▒▀╬╫▄░░░░░░░░░░░░╫░░░╠▀▓╬╣▀╢░░╫░░░░░╣▌╣▌╫▓╙'''''''''''''''
''''''''''''''''╠▓▌╬▒╬▒╣▌╟▌µ░░░░░░░░░░░└▀▀╣╫╫▀╢Å╝╢╝▀┤░░░░▄╬╟▓╠▓▄.'''''''''''''''
''''''''''''''',▐╬▓╬▒╬▌╬╬╣╬╣G└░░░░░░░░░░░░░░░░░░░░░░░░░░▄╬╬▌╬▓Qµ''''''''''''''''
'''''''''''''▐▄▓╬▀╣╬╠╫╣╫╬╫▌▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▀╬╬╬╬╬▌▓G',''''''''''''
''''''''''┌,╫▀▀╬╫╬▒╬█▌╬╫▓╙╨░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╙▀▀╬╠╫╬╬╣▓▄''''''''''''
''''''''''▄▓╬╠▓▓╬╠▓╬▒╬▌╨░░░░░░░░░░░░╥╥░░░░░░░░░░░░3▄G░░░░░░│╨▓▌╬╠╬╟▌▄'''''''''''
'''''''')▄▓╠╣▓╬╠╣▌╠╣▓┤│░░░░░░ƒ░░░░░░┘╨└░░░░░░░░░░░░┘└░░*▄░░░░░╨╫▒▀╬╬▓▄''''''''''
'''''''╔▄▓▒▀▓╣╠█╬╣▒╨░└Q░░░░⌠▀╡░░░░░░░░░░░░░░░░░░░░░░░░▐▀╨└░░░░░└ô▓╬╬╬▓C'''''''''
'''''''%╣▌╫╠▓▀╠╫▀Ö░░░┤╨░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░║▓╬╬╫▀⌐''''''''
''''''Qª╣▒╫╬▓▌╬╬┤░░░░░░░░└└░░░░░░░░░j▒░░░░░░░░░▄▓#└░░░░░░░░░░░░╓▄░╚▌╟╣▓*''''''''
''''''╙▓▓╬▓▌▀╬▓G░░░░░░░░┤▀▌░░░░░░░░░└░░░░░░░░░░└└░░░░░░░░░░p;░░┘╨▌░▓▒╬▓▄''''''''
''''''@▌▀╬╬▓▌╢▌░░░░░░░░░░▐▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╙╨░░░░▓░╨▓╬▓▄''''''''
'''''╥Q╫▌▓╬╬╬╫▀░░░░░░░░░░╫░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╫▒░▓╠▓▄▄'''''''
''''''╠▓╬▓▌╠╬▓▒░░░░?▀#░░░▌░░{▄░░░░░░░░░░░░░░░░▄╡░░░░░░░╓▐▒░░░░░░░║▒░▓╬╬▌⌐'''''''
''''''╟▓╬╬▀▓▒▓░░░░░░░░░░▐▒░░░│┘░░░░░░░░░░░░░░░│┤░░░░░░░└┤└░░░░░░░▐▌░╫▒╬▓▄'''''''


   ____       _ _ _               __       _         
  /___ \_   _(_) | | ___ _ __    / /  __ _| |__  ___ 
 //  / / | | | | | |/ _ \ '__|  / /  / _` | '_ \/ __|
/ \_/ /| |_| | | | |  __/ |    / /__| (_| | |_) \__ \
\___,_\ \__,_|_|_|_|\___|_|    \____/\__,_|_.__/|___/
                                                                                                     
                                                     
*/

contract Hedgies is ERC721, Ownable, ERC721Burnable, ERC721Enumerable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public price = 0.06 ether;
    uint256 public whitelistPrice = 0 ether;
    uint256 public maxQuantity = 20;
    uint256 public maxSupply = 10000;
    bool public publicMintLive = false;
    bool public whitelistMintLive = false;
    string baseUri = "https://api.quiller.app/collection/hedgies-quiller-labs/metadata/";
    mapping(address => uint256) private whitelist;

    constructor() ERC721("Hedgies by Quiller Labs", "HQL") {}

    /*
    ==============================================================
    UTILITY METHODS
    ==============================================================
    */

    // Check remaining whitelist mints for whitelisted wallet
    function remainingWhitelistMints() public view returns (uint256) {
        return whitelist[msg.sender];
    }

    /*
    ==============================================================
    MINT METHODS
    ==============================================================
    */

    // Public minting
    function publicMint(uint256 quantity) public payable {
        require(publicMintLive == true, "Public minting is not live yet!");
        require(quantity <= maxQuantity, "Quantity requested exceeded the maximum quantity allowed.");
        uint256 totalCost = quantity * price;
        require(msg.value >= totalCost, "Not enough ETH to mint the desired quantity");
        _mintNft(msg.sender, quantity);
    }

    // Whitelist minting
    function whitelistMint(uint256 quantity) public payable {
        require(whitelistMintLive == true, "Whitelist minting is not allowed yet!");
        require(whitelist[msg.sender]>=quantity, "Mint quantity exceeded the allowed quantity. Please use remainingFreeMints() function to see the allowed amount.");
        uint256 totalCost = quantity * whitelistPrice;
        require(msg.value >= totalCost, "Not enough ETH to mint the desired quantity");
        _mintNft(msg.sender, quantity);
        whitelist[msg.sender] -= quantity;
    }

    /*
    ==============================================================
    ADMIN/OWNER ONLY FUNCTIONS
    ==============================================================
    */

    function airdrop(address[] memory wallets, uint256[] memory counts) public onlyOwner {
        for (uint256 i=0; i < wallets.length; i++) {
            _mintNft(wallets[i], counts[i]);
            emit NFTAirdrop(wallets[i], counts[i]);
        }
    }

    function setBaseUri(string calldata newBaseUri) public onlyOwner{
        baseUri = newBaseUri;
    }

    // Function that adds list of wallets to whitelist for free minting
    function addToWhitelist(address[] memory wallets, uint256[] memory mintsAllowed) public onlyOwner {
        for (uint256 i=0; i < wallets.length; i++) {
            whitelist[wallets[i]] = mintsAllowed[i];
        }
    }

    // Function that removes list of wallets from whitelist
    function removeFromWhitelist(address[] memory wallets) public onlyOwner {
        for (uint256 i=0; i < wallets.length; i++) {
            whitelist[wallets[i]] = 0;
        }
    }

    function togglePublicMintLive() public onlyOwner {
        publicMintLive = !publicMintLive;
    }

    function toggleWhitelistMinting() public onlyOwner {
        whitelistMintLive = !whitelistMintLive;
    }

    // Set the price per mint
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // Set the whitelist price per mint
    function setWhitelistPrice(uint256 newWhitelistPrice) public onlyOwner {
        whitelistPrice = newWhitelistPrice;
    }

    // Maximum tokens per mint
    function setMaxQuantity(uint256 newQuantity) public onlyOwner {
        maxQuantity = newQuantity;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function addReserve(uint256 reserveAmount) public onlyOwner {
        require(reserveAmount + maxSupply <= 11111, "Maximum supply including reserves is 11111");
        maxSupply += reserveAmount;
    }

    /*
    ==============================================================
    PRIVATE FUNCTIONS
    ==============================================================
    */
    function _mintNft(address wallet, uint256 quantity) private {
        require((maxSupply - _tokenIds.current()) >= quantity);
        for(uint256 i = 0; i < quantity; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            _safeMint(wallet, tokenId);
            tokenURI(tokenId);
        }
    }

    /*
    ==============================================================
    EVENTS
    ==============================================================
    */

    event NFTAirdrop(address indexed to, uint256 quantity);

    /*
    ==============================================================
    MISCELLANEOUS   
    ==============================================================                                                                   
    */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
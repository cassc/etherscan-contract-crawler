//
//     sSSs   .S_SSSs      sSSs   .S    S.     sSSSSs   .S_sSSs     .S_SSSs     .S_SSSs           .S     S.   sdSS_SSSSSSbs    sSSs
//    d%%SP  .SS~SSSSS    d%%SP  .SS    SS.   d%%%%SP  .SS~YS%%b   .SS~SSSSS   .SS~SSSSS         .SS     SS.  YSSS~S%SSSSSP   d%%SP
//   d%S'    S%S   SSSS  d%S'    S%S    S%S  d%S'      S%S   `S%b  S%S   SSSS  S%S   SSSS        S%S     S%S       S%S       d%S'
//   S%S     S%S    S%S  S%|     S%S    S%S  S%S       S%S    S%S  S%S    S%S  S%S    S%S        S%S     S%S       S%S       S%S
//   S&S     S%S SSSS%S  S&S     S%S SSSS%S  S&S       S%S    d*S  S%S SSSS%S  S%S SSSS%P        S%S     S%S       S&S       S&S
//   S&S     S&S  SSS%S  Y&Ss    S&S  SSS&S  S&S       S&S   .S*S  S&S  SSS%S  S&S  SSSY         S&S     S&S       S&S       S&S_Ss
//   S&S     S&S    S&S  `S&&S   S&S    S&S  S&S       S&S_sdSSS   S&S    S&S  S&S    S&S        S&S     S&S       S&S       S&S~SP
//   S&S     S&S    S&S    `S*S  S&S    S&S  S&S sSSs  S&S~YSY%b   S&S    S&S  S&S    S&S        S&S     S&S       S&S       S&S
//   S*b     S*S    S&S     l*S  S*S    S*S  S*b `S%%  S*S   `S%b  S*S    S&S  S*S    S&S        S*S     S*S       S*S       S*b
//   S*S.    S*S    S*S    .S*P  S*S    S*S  S*S   S%  S*S    S%S  S*S    S*S  S*S    S*S        S*S  .  S*S       S*S       S*S
//    SSSbs  S*S    S*S  sSS*S   S*S    S*S   SS_sSSS  S*S    S&S  S*S    S*S  S*S SSSSP         S*S_sSs_S*S       S*S       S*S
//     YSSP  SSS    S*S  YSS'    SSS    S*S    Y~YSSY  S*S    SSS  SSS    S*S  S*S  SSY     SS   SSS~SSS~S*S       S*S       S*S
//                  SP                  SP             SP                 SP   SP          S%%S                    SP        SP
//                  Y                   Y              Y                  Y    Y            SS                     Y         Y
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract cashgrabwtf is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 7777;

    string public baseURI = "";
    uint256 public mintPrice = 0.077 ether;
    uint256 public maxMintPublic = 7;
    bool public whitelistMintEnabled = false;
    bool public publicMintEnabled = false;

    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public publicTotalMinted;

    constructor() ERC721A("cashgrab.wtf", "CASH") {}

    function whitelistMint(uint256 quantity) external payable {
        require(whitelistMintEnabled, "Whitelist mint is not active");
        require(
            whitelist[msg.sender] >= quantity,
            "Unauthorized mint quantity for user"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Quantity exceeds max supply"
        );
        _mint(msg.sender, quantity);
        whitelist[msg.sender] -= quantity;
    }

    function publicMint(uint256 quantity) external payable {
        require(publicMintEnabled, "Public mint is not active");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Quantity exceeds max supply"
        );
        require(
            publicTotalMinted[msg.sender] + quantity <= maxMintPublic,
            "Wallet public mint limit reached"
        );
        require(msg.value == getMintCost(quantity), "Incorrect mint price");
        _mint(msg.sender, quantity);
        publicTotalMinted[msg.sender] += quantity;
    }

    function getMintCost(uint256 quantity) public view returns (uint256) {
        return mintPrice * quantity;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function toggleWhitelistMint() external onlyOwner {
        whitelistMintEnabled = !whitelistMintEnabled;
    }

    function togglePublicMint() external onlyOwner {
        publicMintEnabled = !publicMintEnabled;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintPublic(uint256 _maxMintPublic) external onlyOwner {
        maxMintPublic = _maxMintPublic;
    }

    function setWhitelist(address[] calldata addresses, uint256 mintQuantity)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = mintQuantity;
        }
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
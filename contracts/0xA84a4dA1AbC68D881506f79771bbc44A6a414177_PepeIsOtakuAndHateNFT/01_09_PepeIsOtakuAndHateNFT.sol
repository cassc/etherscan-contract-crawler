//SPDX-License-Identifier: Unlicense

//                                 ..................  ..
//                  ....... ................................
//            .......................,,,,,,,,,....................   .
//           .................,,,,,,***//*//***,,,,,,.................. ..
//          ..........,,/#@*,***/////((#%(##(&@#//**,,,,,.................
//         ..........,,,,%#/*//#%&@&@@@&@@&@@&%%#%(/****,,,...............
//          .........,,,,*#@%&@&&&@@&&%&&&@@@@&@#@%(//****,,,..................
//          .......,,,,*(#(#&@@&@@&&@@@@@@@@@&@@&*&&&@////**,,,...............
//         ........,,*%%(&#@@@@@&@&@@@@&&@@@@@@@@@&,(&%%%((/*,,,,...............
//      ..........,,*/#%%&&&&@&&&@@@@@.,,/**@@@@@@&&%*,,,/%&//*,,,................
//     ...........,,/((##&%@@&&@&@&@@*.,...  *.,      /(/(%%#/**,,..............
//      ........,,*&(&%&%@&&&@&@@@&%%&%#,  .     *@%%%&&&##%&(**,,...............
//    ..........,,*/#%%%&%&%@@&&&@&@@&&%*,        .  &@&%#&%&((**,................
//    ...........,*/&**(%@&&@@&@@@@&@@@@*./,.,     .,#* *.%%&/*,,,................
//   ............,,*&#**%&##(##@##&**,*,.    ... .   .   ,*.((/,,..................
//   ............,,,***/%/%%.#,,#*      /,,.   ,.    ,. .,***.*,,..................
//   ..  ...........,,*&%*%&(*%&**/(////*/**    .    .    ,,/#*,,,.................
//    ...............,*(&(*///*(%//////*****               ,,,*.,..................
//    .  ............,,(%(%(*,,/(/**/*****       .           .,.,..................
//    .   ..............*%%///(%%(#*/*//,.                   .......    ........ .
//         ......... .....*%@@&@%%%//#/      ,                  ....     ..  .
//          ................***///#(#...  #%,                     .       .....
//         .................,***//%&/.. ,%(,                         .    .......
//        ....................(&//#(#**%%.          .
//       ....................,.,#(#%%(,..               ........         ........
//         ..... . ......,,**//#*&#/(/**,,..       . ..,,,,//#@##/*,
//      .........,,,,*/*/*/(#(%&@@@//,,**,,,,,,*///#%%@%%#%&%&@@@%%##//,
//      .........,,,.,,,,,,.,***,   .,,,,.....,*,*,,,*, .... ,(///////,... .
//               ..,.....   ........ . ...... . .     .  . .............
//                .        .. .  ..                .   .     ..
//                  .      ..

pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PepeIsOtakuAndHateNFT is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    string  public baseTokenURI = "https://bafybeib7gwr7zf6abmbt6yw2vazh2idywrjcvsejoevujplfwpvtqwmbiq.ipfs.nftstorage.link/metadata/";
    uint256 public MAX_SUPPLY = 6666;
    uint256 public MAX_FREE_SUPPLY = 5555;
    uint256 public MAX_PER_TX = 20;
    uint256 public PRICE = 0.002 ether;
    uint256 public MAX_FREE_PER_WALLET = 1;
    uint256 public maxFreePerTx = 1;
    bool public initialize = true;
    bool public revealed = true;

    mapping(address => uint256) public qtyFreeMinted;

    constructor() ERC721A("PepeIsOtakuAndHateNFT", "POHNFT") {}

    function mint(uint256 amount) external payable
    {
        uint256 cost = PRICE;
        uint256 num = amount > 0 ? amount : 1;
        bool free = ((totalSupply() + num < MAX_FREE_SUPPLY + 1) &&
            (qtyFreeMinted[msg.sender] + num <= MAX_FREE_PER_WALLET));
        if (free) {
            cost = 0;
            qtyFreeMinted[msg.sender] += num;
            require(num < maxFreePerTx + 1, "Max per TX reached.");
        } else {
            require(num < MAX_PER_TX + 1, "Max per TX reached.");
        }

        require(initialize, "Minting is not live yet.");
        require(msg.value >= num * cost, "Please send the exact amount.");
        require(totalSupply() + num < MAX_SUPPLY + 1, "No more");

        _safeMint(msg.sender, num);
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner nonReentrant
    {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function _stringReplace(string memory _string, uint256 _pos, string memory _letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(_string);
        bytes memory result = new bytes(_stringBytes.length);

        for(uint i = 0; i < _stringBytes.length; i++) {
                result[i] = _stringBytes[i];
                if(i==_pos)
                result[i]=bytes(_letter)[0];
        }
        return  string(result);
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseTokenURI, "/", _tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }

    function reveal(bool _revealed) external onlyOwner
    {
        revealed = _revealed;
    }

    function setInitialize(bool _initialize) external onlyOwner
    {
        initialize = _initialize;
    }

    function setPrice(uint256 _price) external onlyOwner
    {
        PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_PER_TX = _limit;
    }

    function setLimitFreeMintPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_FREE_PER_WALLET = _limit;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner
    {
        MAX_FREE_SUPPLY = _amount;
    }
}
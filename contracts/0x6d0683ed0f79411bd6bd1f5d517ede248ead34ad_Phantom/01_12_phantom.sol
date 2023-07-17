// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

//                                                            ,----,
// ,-.----.           ,--,                        ,--.      ,/   .`|  ,----..             ____
// \    /  \        ,--.'|   ,---,              ,--.'|    ,`   .'  : /   /   \          ,'  , `.
// |   :    \    ,--,  | :  '  .' \         ,--,:  : |  ;    ;     //   .     :      ,-+-,.' _ |
// |   |  .\ :,---.'|  : ' /  ;    '.    ,`--.'`|  ' :.'___,/    ,'.   /   ;.  \  ,-+-. ;   , ||
// .   :  |: ||   | : _' |:  :       \   |   :  :  | ||    :     |.   ;   /  ` ; ,--.'|'   |  ;|
// |   |   \ ::   : |.'  |:  |   /\   \  :   |   \ | :;    |.';  ;;   |  ; \ ; ||   |  ,', |  ':
// |   : .   /|   ' '  ; :|  :  ' ;.   : |   : '  '; |`----'  |  ||   :  | ; | '|   | /  | |  ||
// ;   | |`-' '   |  .'. ||  |  ;/  \   \'   ' ;.    ;    '   :  ;.   |  ' ' ' :'   | :  | :  |,
// |   | ;    |   | :  | ''  :  | \  \ ,'|   | | \   |    |   |  ''   ;  \; /  |;   . |  ; |--'
// :   ' |    '   : |  : ;|  |  '  '--'  '   : |  ; .'    '   :  | \   \  ',  / |   : |  | ,
// :   : :    |   | '  ,/ |  :  :        |   | '`--'      ;   |.'   ;   :    /  |   : '  |/
// |   | :    ;   : ;--'  |  | ,'        '   : |          '---'      \   \ .'   ;   | |`-'
// `---'.|    |   ,/      `--''          ;   |.'                      `---`     |   ;/
//   `---`    '---'                      '---'                                  '---'

// Developer Telegram -> WomboGoon

contract Phantom is ERC721, Ownable {
    using Strings for uint256;

    uint256 public price = 0.09 ether;

    bool public revealed;

    string private _mysteryURI;

    uint256 public supply = 3333;

    bool public saleLive = false;

    uint256 public totalSupply;

    string private _contractURI;

    string private _tokenBaseURI;

    mapping(uint256 => bool) private usedNonce;

    constructor() ERC721("Phantom", "PHANT") {}

    // for presale

    function presaleMint(uint256 tokenQuantity) external payable {
        require(price * tokenQuantity <= msg.value, "x price");

        require(totalSupply + tokenQuantity <= supply, "x supply");

        require(saleLive, "closed");

        require(tokenQuantity <= 4, "exceed");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    // main sale

    function mint(uint256 tokenQuantity) external payable {
        require(saleLive, "closed");

        require(tokenQuantity <= 4, "exceed");

        require(price * tokenQuantity <= msg.value, "x price");

        require(totalSupply + tokenQuantity <= supply, "x supply");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function gift(uint256 tokenQuantity, address wallet) external onlyOwner {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    // 200 + 200 + 350 + 1475 + 1450 + 1475 +1450 + 1450 + 1450 + 500

    function withdraw() external {
        uint256 currentBalance = address(this).balance;
        payable(0xECe5Be2e951A8f9B6317bE94fAc75349E9146722).transfer(
            (currentBalance * 200) / 10000
        );
        payable(0x1E69347BfC401C35866f8C3587e900c7996EDC6e).transfer(
            (currentBalance * 200) / 10000
        );
        payable(0x9A9Cff3917fc031533867aF0BcC1c056b2c5Bf3c).transfer(
            (currentBalance * 350) / 10000
        );
        payable(0x0243891818d63bE4f012956b04289dc490A2F60B).transfer(
            (currentBalance * 1475) / 10000
        );
        payable(0x1485857eEE414282Ef2993370C5AC7Ee89ea7978).transfer(
            (currentBalance * 1450) / 10000
        );
        payable(0xb1b3FC86B89d5C3F92E2766bca1085071Eab37F7).transfer(
            (currentBalance * 1475) / 10000
        );
        payable(0x2b16EdeaCa67C831ba2786E793705Abf11308E3C).transfer(
            (currentBalance * 1450) / 10000
        );
        payable(0x53A697f465701D6043097aDfC7213E72F85C84F2).transfer(
            (currentBalance * 1450) / 10000
        );
        payable(0xbF7cF91d8590a81bEE26af41EBF545b1C7B6699c).transfer(
            (currentBalance * 1450) / 10000
        );
        payable(0x5bceDA8d37A97Cc45E8adB6d5CfEff86c3b30507).transfer(
            (currentBalance * 500) / 10000
        );
    }

    function boolSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function newMysteryURI(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function newPriceOfNFT(uint256 priceNew) external onlyOwner {
        price = priceNew;
    }

    function boolMysteryURI() public onlyOwner {
        revealed = !revealed;
    }

    function newBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function newContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");

        if (revealed == false) {
            return _mysteryURI;
        }

        return
            string(
                abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
            );
    }
}
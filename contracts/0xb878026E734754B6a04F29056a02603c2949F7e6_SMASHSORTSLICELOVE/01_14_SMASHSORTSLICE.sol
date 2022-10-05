// SPDX-License-Identifier: CONSTANTLY WANTS TO MAKE THE WORLD BEAUTIFUL

// ///..//*..//..//,..////////#,,,,,,,,,,,,,,,,,&&&&&,**(*./,///*%(.%,,%*,#%/%#(///
// *#%%%%%%%%%%/%/////*&@@(*#(#,,,,,,,,,,,,,,,,,@@@@@/***,./,///%./%#(%.#%/.(.*////
// *******%%%%(/(/(/(/******#(#,,,,,,,,,,,,,,,,,********((#((@%%.........%@@@@@@@@@
// #############%%%%%%%%%%%%%,,,,,,,,,,,,,,,,,**,*,/.**,,///////####%####,.///,*%*,
// .*,%,%./%#%(./,(,(*#*#*#*,,,**.,,,********//(****//(#((#(@@@@@*@@@@@&&&&&***&&&&
// /.%((%,*#&%% %.%%#&@&&&.%,*#*,,,.*,,******,,,,,,,,,##,....,,,,*,,,,,,,,,,%*%,,&&

// ███████╗███╗   ███╗ █████╗ ███████╗██╗  ██╗   ███████╗ ██████╗ ██████╗ ████████╗███████╗██╗     ██╗ ██████╗███████╗
// ██╔════╝████╗ ████║██╔══██╗██╔════╝██║  ██║   ██╔════╝██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝██║     ██║██╔════╝██╔════╝
// ███████╗██╔████╔██║███████║███████╗███████║   ███████╗██║   ██║██████╔╝   ██║   ███████╗██║     ██║██║     █████╗
// ╚════██║██║╚██╔╝██║██╔══██║╚════██║██╔══██║   ╚════██║██║   ██║██╔══██╗   ██║   ╚════██║██║     ██║██║     ██╔══╝
// ███████║██║ ╚═╝ ██║██║  ██║███████║██║  ██║██╗███████║╚██████╔╝██║  ██║   ██║██╗███████║███████╗██║╚██████╗███████╗
// ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝╚══════╝

// ,*//%@@@*%%(##@@@@&&&&&/,,//.(%@@@##%@##########%&**/,,,@@@@@@@@@@&&&&#######***
// ,*(/%@@@#*,/**((((((((&/,,/.**,,,,%%/,%%%%%&#%%&&&%%%#,,@@@@@@@@@@&&&&#######///
// ,...%@@@@@@@@@,,,,,,,,@/,,@&**,,,,##/,,/%%%&*/(//,/*/(,,@@@@@@@@@@&&&%....../***
// ,,,(##########((((&@@@@,,,*&**,,,,,,,,*##/#*//////*,**,,@@@@@@@@@@@@@%(%***%&&#%
// ,,,(############,,,,,,,,,,(#/&,,,,,,,,(*,/,(*%%%((%%##@@@@@@@@@@@@@@@&@@@/*#@&#(
// ,***/((%##%(//((#((##((((,,/*.%,/%/#*(*(*(#(#///####.,///(////(#./(/////*(#/////

// a contribution to ARTGLIXXX EGOSYSTEM

// by berk aka princesscamel aka guerrilla pimp minion god bastard

// @berkozdemir - berkozdemir.com - twitter.com/berkozdemir
// https://artglixxx.io/
// https://glicpixxx.love/

pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGLIX {
    function burn(address from, uint256 amount) external returns (bool);
}

// contract COPYMINTFACTORY is ERC721AQueryable, Ownable, ERC2981 {
contract SMASHSORTSLICELOVE is ERC721AQueryable, ERC2981, Ownable {
    enum SaleStatus {
        NoSale,
        YesSale
    }

    // IGLIX public GLIXTOKEN;
    SaleStatus saleStatus = SaleStatus.NoSale;

    string private _baseTokenURI;

    uint256 public etherBasePrice;
    uint256 public glixBasePrice = 100 ether; // 100 GLIX
    uint256 public increaseGlixPerMint = 0.25 ether; // 0.25 GLIX

    uint256 public maxSupply = 2693; // 2692 PIECES
    uint256 public maxBuyAtOnce = 101; // 100 MINTS

    address public treasuryAddress = 0xe49381184A49CD2A48e4b09a979524e672Fdd10E; // GLICPIXYZ.eth
    address private GLIXTOKEN_ADDRESS = 0x4e09d18baa1dA0b396d1A48803956FAc01c28E88; // mainnet


    constructor()
        ERC721A("SMASH.SORT.SLICE.LOVE", "SSSL")
    {
        _setDefaultRoyalty(treasuryAddress, 250); // royalty
        _safeMint(msg.sender, 1);
        etherBasePrice = 0.015 ether;
        setBaseTokenURI("https://artglixxx.io/api/mashsortslice/");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function calculateGlixCost(uint256 startId, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 lastId = startId + amount;
        return
            (glixBasePrice * amount) +
            ((((lastId * (lastId + 1)) / 2) -
                ((startId * (startId + 1)) / 2) -
                1) * increaseGlixPerMint);
    }

    function setRoyalty(address _address, uint96 _royalty) external onlyOwner {
        _setDefaultRoyalty(_address, _royalty);
    }

    function setEtherBasePrice(uint256 _price) external onlyOwner {
        etherBasePrice = _price;
    }

    function setGlixBasePrice(uint256 _price) external onlyOwner {
        glixBasePrice = _price;
    }

    function setIncreaseGlixPerMint(uint256 _price) external onlyOwner {
        increaseGlixPerMint = _price;
    }

    function setSaleStatus(SaleStatus _saleStatus) external onlyOwner {
        saleStatus = _saleStatus;
    }

    function editMaxSupply(uint _maxSupply) external onlyOwner {
        require(
            _maxSupply < maxSupply,
            "MAX SUPPLY CAN'T EXCEED INITIAL SUPPLY"
        );
        maxSupply = _maxSupply;
    }

    function mintAdmin(address[] calldata _to, uint _amount) public onlyOwner {
        require(
            totalSupply() + (_amount * _to.length) < maxSupply,
            "MAX SUPPLY IS EXCEEDED"
        );
        for (uint i; i < _to.length; i++) {
            _safeMint(_to[i], _amount);
        }
    }

    function withdraw(address _to) external onlyOwner {
        // require(saleStatus == SaleStatus.SaleFinished, "CAN'T WITHDRAW DURING SALE");
        require(address(this).balance > 0, "INSUFFICIENT FUNDS");

        payable(_to).transfer(address(this).balance);
    }

    function buywithEther(address _to, uint256 _amount) public payable {
        require(saleStatus == SaleStatus.YesSale, "SALE IS NOT OPEN");
        require(_amount < maxBuyAtOnce, "YOU CAN'T BUY THIS MUCH");
        require(totalSupply() + _amount < maxSupply, "MAX SUPPLY IS EXCEEDED");
        require(msg.value >= (_amount * etherBasePrice), "NOT ENOUGH ETHER");
        _safeMint(_to, _amount);
    }

    function buywithGlix(address _to, uint256 _amount) public {
        require(saleStatus == SaleStatus.YesSale, "SALE IS NOT OPEN");
        require(_amount < maxBuyAtOnce, "YOU CAN'T BUY THIS MUCH");
        require(totalSupply() + _amount < maxSupply, "MAX SUPPLY IS EXCEEDED");
        require(
            IGLIX(GLIXTOKEN_ADDRESS).burn(
                msg.sender,
                calculateGlixCost(totalSupply(), _amount)
            )
        );
        _safeMint(_to, _amount);
    }

    function burn(uint256 _tokenId) public {
        _burn(_tokenId, true);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Set the base token URI
     */
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
}
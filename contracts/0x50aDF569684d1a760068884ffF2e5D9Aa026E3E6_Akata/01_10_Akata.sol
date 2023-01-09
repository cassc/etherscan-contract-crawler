// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%&*,,*,,(,,,,,,,,*/&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/&,,,,,,,,,,*,,,,,,,,/*,,,*&//&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/*,,,,,,,,,,,,,,,,,,,,,,,,,,,,*,,,,,,,#,*&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,.,,(//&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,,,,,,,./,,,%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(,,,,,,,,,,,,,,,,,,.,,,,,,,,,.,,,,,,,,,,,,.,,,.,(/(&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,.,,,,,,,,,,,,..,,,...,..*........,*&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,.,,.......,,,.....,./(*.......,.,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@......,.,,..,.,,,.,./(((...,......,...*((,,,,......./@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@*.....................*(////(,...,.......(((((((/.,./[email protected],@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@,...,..................(/**,,.,..........(((,...//(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@%.,,,,....................(*..**........../(((((.(*,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@(...,...,....................**/..*.......,/(((((((((/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@/,*,...,......,..,.............,**......../*#((((((((((/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@%*,..,,..,......,............*//,........(/##(((((((/*(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@,,...,.......................*......,.,//((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@*...,..,.................,.,........//((((((((,,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/,.,.,,.,.,.......,*,.,...,...,..*/(((((((/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.*,*,*.*/.***,.,...***..*(((((#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@*********//***..(/@@@@,,,*///@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@........ ///////***,,@@@@@@(@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#..............,*/(/**@*,@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#,..,.................,..**/@@@ ,@@@@@@@@(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@/,,,,,,,,...............,.,**@@@@@@,@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@*,...,*/##(/*//////////////,//,*/%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@%,**/**/*////*/////*****,**,**///**(@@@/[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@/,/*//****//*///////*///////////,,.......&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@**,*//////////////////.**.,,,,,.  ......./(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@#/,///////////////,**/ ,,,,,,,,,,,,([email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@*(,///*///*/////,,**.,,,,,,,,,,,,,,*/,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@&,,////////*//////*/,.,,,,.,,,,,,,,,.,,,/,,...,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@,//,/////*/////,*,,..,.,,,,..,,,,,,,,,,.,,,,*/[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@*///*///*/////*,.//..,.,,.,.,.,,,,,,,,,,,...,,,,([email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@////////////*/***//,...,.,,...,..,,,,,,,,,..,...,,/,,( @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@,/*///////*,,,/**/.,.,....,.......,.,,..,,,...........,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@*//////////*,/*/*/**,,.,....,...............,.........,...../@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@*///////////*,**/**,..,.,.,...........,,......,,......#....*...*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@/*//*////,,,*//,.,, ...,.................................... .*.*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&*/****///*/*,,,,,........................................... #,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@****/***/**,,,..........................,.............,*.....(,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@********,,,.................................................%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@(*,@@,,..................................,./[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Akata is ERC721AQueryable, Ownable, DefaultOperatorFilterer {
    enum SaleState {
        CLOSE,
        Eliteclub,
        AllowList,
        Public
    }


    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant ELITE_SUPPLY = 500;

    uint256 public constant MAX_MINT_PER_WALLET = 3;
    uint256 public constant MAX_MINT_PER_WALLET_ELITE = 1;



    uint256 public priceAL = 0.007 ether;
    uint256 public pricePub = 0.009 ether;
    string public baseTokenURI = 'ipfs://Qmb5ym7AKJyGnATyad8sx7Zg5nXLxceuHqZobagaGQ3KbF/';
    SaleState public state;



    constructor() ERC721A("Akata", "Akata") {}



    function mintEliteClub(uint256 amount) external {
        require(state == SaleState.Eliteclub, "Eliteclub sale is inactive");
        require(_getAux(msg.sender) == uint64(SaleState.Eliteclub), "You're not in Elite club");

        require(totalSupply() + amount <= ELITE_SUPPLY, "Whole elite is already here");
        require(_numberMinted(msg.sender) + amount <= MAX_MINT_PER_WALLET_ELITE, "You've got enough");

        _mint(msg.sender, amount);
    }

    function mintAL(uint256 amount) external payable {
        require(state == SaleState.AllowList, "AllowList sale inactive");
        require(_getAux(msg.sender) == uint64(SaleState.AllowList), "You're not in Allow list");

        require(totalSupply() + amount <= MAX_SUPPLY, "All Akata's are already here");
        require(msg.value >= amount * priceAL, "Yoo need to pay more");
        require(_numberMinted(msg.sender) + amount <= MAX_MINT_PER_WALLET, "You've got enough");

        _mint(msg.sender, amount);
    }

    function mintPub(uint256 amount) external payable {
        require(state == SaleState.Public, "Public sale is inactive");

        require(totalSupply() + amount <= MAX_SUPPLY, "All Akata's are already here");
        require(msg.sender == tx.origin, "No smart contract");
        require(msg.value >= amount * pricePub, "Yoo need to pay more");
        require(_numberMinted(msg.sender) + amount <= MAX_MINT_PER_WALLET, "You've got enough");

        _safeMint(msg.sender, amount);
    }



    function addAkatas(address[] calldata wlAddresses, SaleState status) external onlyOwner {
        for (uint256 i; i < wlAddresses.length; ) {
            _setAux(wlAddresses[i], uint64(status));
            unchecked {
                i++;
            }
        }
    }

    function ownerMint(uint256 amount, address to) external onlyOwner {
        require(amount + totalSupply() <= MAX_SUPPLY, "No more Akata's");
        _safeMint(to, amount);
    }


    function setState(SaleState newState) external onlyOwner {
        state = newState;
    }

    function setPublicPrice(uint256 newPrice) external onlyOwner {
        pricePub = newPrice;
    }

    function setAllowPrice(uint256 newPrice) external onlyOwner {
        priceAL = newPrice;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "Failed to withdraw Ether");
    }

    function checkPhase(address akatasAddress) public view returns (string memory) {
        uint256 phase = _getAux(akatasAddress);
        if (phase == 1) {
            return "Elite Club";
        } else if (phase == 2) {
            return "Allow List";
        } else {
            return "Public";
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
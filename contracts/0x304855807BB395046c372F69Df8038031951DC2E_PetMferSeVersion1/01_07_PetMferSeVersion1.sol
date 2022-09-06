//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/***
 *    ██████╗ ███████╗████████╗    ███╗   ███╗███████╗███████╗██████╗     ███████╗███████╗
 *    ██╔══██╗██╔════╝╚══██╔══╝    ████╗ ████║██╔════╝██╔════╝██╔══██╗    ██╔════╝██╔════╝
 *    ██████╔╝█████╗     ██║       ██╔████╔██║█████╗  █████╗  ██████╔╝    ███████╗█████╗
 *    ██╔═══╝ ██╔══╝     ██║       ██║╚██╔╝██║██╔══╝  ██╔══╝  ██╔══██╗    ╚════██║██╔══╝
 *    ██║     ███████╗   ██║       ██║ ╚═╝ ██║██║     ███████╗██║  ██║    ███████║███████╗
 *    ╚═╝     ╚══════╝   ╚═╝       ╚═╝     ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝    ╚══════╝╚══════╝
 *
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract PetMferSeVersion1 is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    event Minted(uint256 count);

    uint public constant MAX_SUPPLY = 10000;
    uint public constant PRICE = 0;
    uint public constant MAX_PER_MINT = 3;
    uint public constant MAX_RESERVE_SUPPLY = 500;

    string public _baseURIExtended;
    bool public saleIsActive = false;
    address payable public _shareholderAddress;

    constructor() ERC721A("Pet mfer se", "PMFER"){

    }

    function reserve(address payable reservedHolderAddress, uint256 quantity) public onlyOwner {
        uint totalMinted = totalSupply() + 1;
        require(reservedHolderAddress != address(0), "Not set the reserve holder address!");
        require(totalMinted.add(quantity) <= MAX_SUPPLY, "No more promo NFTs left");
        _safeMint(reservedHolderAddress, quantity);
    }

    function mint(uint256 quantity) external payable {
        require(quantity > 0, "Quantity cannot be zero");
        require(quantity < MAX_PER_MINT, "Exceeded max token purchase");
        require(saleIsActive, "Sale must be active to mint Tokens");
        uint totalMinted = totalSupply() + 1;
        require(totalMinted.add(quantity) <= MAX_SUPPLY, "No more promo NFTs left");
        require(
            numberMinted(msg.sender) + quantity <= MAX_PER_MINT,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
        emit Minted(quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setShareholderAddress(address payable shareholderAddress) public onlyOwner {
        _shareholderAddress = shareholderAddress;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIExtended = baseURI;
    }

    function contractURI() public pure returns (string memory) {
        return "https://4mfers.art/meta.json";
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_shareholderAddress).transfer(balance);
    }
}
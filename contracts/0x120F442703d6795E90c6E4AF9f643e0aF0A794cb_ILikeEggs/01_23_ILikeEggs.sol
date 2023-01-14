// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

///////
// I //
//   //
// L //
// I //
// K //
// E //
//   //
// E //
// G //
// G //
// S //
///////

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/ERC721Psi.sol";
import "./lib/ERC721PsiBurnable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract ILikeEggs is ERC721PsiBurnable, Ownable, AccessControl, DefaultOperatorFilterer, IERC2981 {
    uint public mintFee = 3300000000000000;
    bool public enableMinter = true;
    uint public royaltyFee = 50;
    address public royaltyAddress;

    uint public constant MAX_FREE_MINT_PER_WALLET = 10;
    uint public constant MAX_MINT_PER_TX = 10;
    uint public constant FREE = 4444;
    uint public constant MAX_SUPPLY = 8888;
    bytes32 public constant BURNER = bytes32("BURNER");

    mapping(address => uint) internal mintedByWallet;


    string private baseURI = "https://i-like-eggs-backend-metadata.herokuapp.com/";


    constructor() ERC721Psi ("I like eggs", "EGGS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        royaltyAddress = 0xf5CC2CA3553C461aB782207114aFeBd90376dd16;
    }

    function setRoyaltiesAddress(address _address) public onlyOwner {
        royaltyAddress = _address;
    }

    function setRoyaltyPercentage(uint _percentage) public onlyOwner {
        royaltyFee = _percentage;
    }

    function getAmountForFreeMint(uint _amountToMint, address _user) public view returns (uint) {
        uint minted = mintedByWallet[_user];
        if (totalSupply() < FREE) {
            if (minted >= MAX_FREE_MINT_PER_WALLET) {
                return 0;
            }
            uint leftToMint = MAX_FREE_MINT_PER_WALLET - minted;
            return Math.min(Math.min(_amountToMint, leftToMint), FREE - totalSupply());
        }
        return minted > 0 ? 0 : 1;
    }

    function publicMint(uint _amountToMint) public payable {
        require(enableMinter, "Not enabled");
        require(_amountToMint > 0 && _amountToMint <= MAX_MINT_PER_TX, "invalid amount");
        require(_amountToMint + totalSupply() <= MAX_SUPPLY, "not enough supply");

        uint amountForFree = getAmountForFreeMint(_amountToMint, msg.sender);

        uint fee = mintFee * (_amountToMint - amountForFree);

        require(msg.value == fee, "not enough eth");

        mintedByWallet[msg.sender] += _amountToMint;

        _safeMint(msg.sender, _amountToMint);
    }

    function burn(uint tokenId) external onlyBurner {
        _burn(tokenId);
    }

    modifier onlyBurner() {
        require(hasRole(BURNER, msg.sender), "Not a burner");
        _;
    }

    function setMintFee(uint _mintFee) public onlyOwner {
        mintFee = _mintFee;
    }

    function setMintingEnabled(bool _enabled) public onlyOwner {
        enableMinter = _enabled;
    }

    function ownerMint(uint amount, address to) public onlyOwner {
        require(amount + totalSupply() <= MAX_SUPPLY, "not enough supply");
        _safeMint(to, amount);
    }

    receive() external payable {}
    fallback() external payable {}

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721Psi, IERC165) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function sweepEthToAddress(address _user) public onlyOwner {
        payable(_user).transfer(address(this).balance);
    }

    function sweepAnyTokensToAddress(address _token, address _user) public onlyOwner {
        IERC20(_token).transfer(_user, IERC20(_token).balanceOf(address(this)));
    }

    function royaltyInfo(uint /*_tokenId*/, uint _salePrice) external view override(IERC2981) returns (address receiver, uint royaltyAmount) {
        receiver = royaltyAddress;
        royaltyAmount = _salePrice / 1000 * royaltyFee;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
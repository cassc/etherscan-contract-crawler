// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract FeelsGoodFrogs is ERC721A, IERC2981, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    IERC20 PEPE = IERC20(0x6982508145454Ce325dDbE47a25d4ec3d2311933);

    string  public baseURI;
    string  public extension;
    bool    public mintEnabled     = false;
    uint256 public maxPerWallet    = 25;
    uint256 public maxPerTx        = 10;
    uint256 public maxFree         = 1;
    uint256 public maxSupply       = 6969;
    uint256 public price           = 0.0042 ether;
    uint256 public pepePrice       = 320000000 ether;

    mapping(address => uint256) public _walletMints;

    error MintNotLive();
    error AlreadyMaxMinted();
    error MaxPerTx();
    error NotEnoughETH();
    error NoneLeft();
    error TokenDoesNotExist();
    error NotApprovedOrOwner();
    error WithdrawalFailed();
    error NoContracts();
    error GetSomePEPE();
    error SupplyOnlyReduced();

    constructor() ERC721A("Feels Good Frogs", "FGF"){}

    function mint(uint256 amount, bool pepeMint) external payable {
        uint256 paidAmount = amount;
        if (!mintEnabled) {
            revert MintNotLive();
        }
        if (msg.sender != tx.origin) {
            revert NoContracts();
        }
        if (amount > maxPerTx) {
            revert MaxPerTx();
        }
        if (_walletMints[msg.sender] + amount > maxPerWallet) {
            revert AlreadyMaxMinted();
        }
        if (totalSupply() + amount > maxSupply) {
            revert NoneLeft();
        }
        if (pepeMint) {
            uint256 pepeBalance = PEPE.balanceOf(msg.sender);
            if (pepeBalance < pepePrice) {
                revert GetSomePEPE();
            }
            if (_walletMints[msg.sender] < 1) {
                paidAmount = amount - 1;
            }
            PEPE.transferFrom(msg.sender, address(this), paidAmount * pepePrice);
        } else {
            if (msg.value < paidAmount * price) {
                revert NotEnoughETH();
            }
        }

        _walletMints[msg.sender] += amount;
        _mint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }

	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), extension)) : "";
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory _baseuri) public onlyOwner {
        baseURI = _baseuri;
    }

    function setExtension(string memory _extension) public onlyOwner {
        extension = _extension;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setPepePrice(uint256 pepePrice_) external onlyOwner {
        pepePrice = pepePrice_;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function reduceSupply(uint256 _newSupply) external onlyOwner {
        if (_newSupply > maxSupply) {
            revert SupplyOnlyReduced();
        }
        maxSupply = _newSupply;
    }

    function reserve(uint256 amount, address to) external onlyOwner {
        if (totalSupply() + amount > maxSupply) {
            revert NoneLeft();
        }
        _mint(to, amount);
    }

    function toggleMint() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance <= 0) {
            revert NotEnoughETH();
        }
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        if (!success) {
            revert WithdrawalFailed();
        }
    }

    function withdrawPepe() public onlyOwner {
        uint256 balance = PEPE.balanceOf(address(this));

        PEPE.approve(address(this), balance);

        PEPE.transferFrom(address(this), owner(), balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view returns (address, uint256) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }

        return (owner(), (salePrice * 42) / 1000);
    }
}
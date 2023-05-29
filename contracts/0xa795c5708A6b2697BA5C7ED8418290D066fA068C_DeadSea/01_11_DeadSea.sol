// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeadSea is ERC721A, Ownable {
    uint256 private constant CLOSED_SALE = 0;
    uint256 private constant PUBLIC_SALE = 1;
    uint256 public constant maxMintsPerWallet = 6;

    uint256 public saleState = CLOSED_SALE;

    address payable private _wallet;
    address payable private _devWallet;
    uint256 private _freeSupply;

    uint256 public maxSupply;

    // basis of 100
    uint256 private _devShare;
    string baseURI = "ipfs://";

    constructor(
        address payable wallet,
        address payable devWallet,
        uint256 devShare,
        uint256 supply,
        uint256 freeSupply
    ) ERC721A("DeadSea", "DEAD") {
        _wallet = wallet;
        _devWallet = devWallet;
        _devShare = devShare;
        maxSupply = supply;
        _freeSupply = freeSupply;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _maxTokensPerMint() internal view returns (uint256) {
        if (_totalMinted() < _freeSupply) {
            return 2;
        }

        return 4;
    }

    function publicMintPrice() public view returns (uint256) {
        if (totalMinted() < _freeSupply) {
            return 0;
        }

        return 4400000000000000; // .0044ETH
    }

    function mint(uint256 count) external payable {
        require(saleState == PUBLIC_SALE, "DeadSea: sale is closed");
        require(_totalMinted() + count <= maxSupply, "DeadSea: none left");
        require(count <= _maxTokensPerMint(), "DeadSea: Too many tokens");
        require(
            balanceOf(_msgSender()) + count <= maxMintsPerWallet,
            "DeadSea: Max mint reached for wallet"
        );
        require(
            msg.value >= publicMintPrice() * count,
            "DeadSea: not enough funds sent"
        );

        _safeMint(msg.sender, count);
    }

    function devMint(address to, uint256 count) public payable onlyOwner {
        require(_totalMinted() + count <= maxSupply, "DeadSea: none left");
        _safeMint(to, count);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setSaleState(uint256 nextSaleState) public onlyOwner {
        require(
            nextSaleState >= 0 && nextSaleState <= 1,
            "DeadSea: sale state out of range"
        );
        saleState = nextSaleState;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 devPayment = (balance * _devShare) / 100;
        uint256 remainder = balance - devPayment;

        (bool success, ) = _devWallet.call{value: devPayment}("");
        (bool success2, ) = _wallet.call{value: remainder}("");

        require(success && success2, "DeadSea: withdrawl failed");
    }

    function allOwners() external view returns (address[] memory) {
        address[] memory _allOwners = new address[](maxSupply + 1);

        for (uint256 i = 1; i <= maxSupply; i++) {
            if (_exists(i)) {
                address owner = ownerOf(i);
                _allOwners[i] = owner;
            } else {
                _allOwners[i] = address(0x0);
            }
        }

        return _allOwners;
    }

    // payable fallback
    fallback() external payable {}

    receive() external payable {}
}
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BullishBytes NFT contract
 *
 * ██████╗ ██╗   ██╗██╗     ██╗     ██╗███████╗██╗  ██╗██████╗ ██╗   ██╗████████╗███████╗███████╗
 * ██╔══██╗██║   ██║██║     ██║     ██║██╔════╝██║  ██║██╔══██╗╚██╗ ██╔╝╚══██╔══╝██╔════╝██╔════╝
 * ██████╔╝██║   ██║██║     ██║     ██║███████╗███████║██████╔╝ ╚████╔╝    ██║   █████╗  ███████╗
 * ██╔══██╗██║   ██║██║     ██║     ██║╚════██║██╔══██║██╔══██╗  ╚██╔╝     ██║   ██╔══╝  ╚════██║
 * ██████╔╝╚██████╔╝███████╗███████╗██║███████║██║  ██║██████╔╝   ██║      ██║   ███████╗███████║
 * ╚═════╝  ╚═════╝ ╚══════╝╚══════╝╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝      ╚═╝   ╚══════╝╚══════╝
 */
contract NFT is ERC721A, Ownable {
    uint256 public cost = 0.001 ether; 
    uint256 public maxSupply = 101; // 100
    uint256 public maxPerWallet = 6; // 5
    uint256 public maxPerTx = 6; // 5

    bool public sale = false;
    bool public whitelistSale = false;

    uint256 public maxPerWhitelistWallet = 2; // 1

    string public baseURI;

    mapping(address => bool) public whitelist;
    mapping(address => uint) public whitelistMinted;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerWalletReached();
    error MaxPerTxReached();
    error NotEnoughETH();

    constructor() ERC721A("Bullish Bytes", "BYTES") {}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();
        if (_totalMinted() + _amount >= maxSupply) revert MaxSupplyReached();
        if (
            _numberMinted(msg.sender) + _amount - whitelistMinted[msg.sender] >=
            maxPerWallet
        ) revert MaxPerWalletReached();
        if (_amount >= maxPerTx) revert MaxPerTxReached();
        if (msg.value < cost * _amount) revert NotEnoughETH();

        _mint(msg.sender, _amount);
    }

    function mint2(uint256 _amount) external payable {
        if (!whitelistSale) revert SaleNotActive();
        if (!whitelist[msg.sender]) revert SaleNotActive();
        if (whitelistMinted[msg.sender] > 0) revert MaxPerWalletReached();

        if (_totalMinted() + _amount >= maxSupply) revert MaxSupplyReached();
        if (_numberMinted(msg.sender) + _amount >= maxPerWhitelistWallet)
            revert MaxPerWalletReached();
        if (_amount >= maxPerWhitelistWallet) revert MaxPerTxReached();
        if (msg.value < cost * _amount) revert NotEnoughETH();

        whitelistMinted[msg.sender] = 1;

        _mint(msg.sender, _amount);
    }

    function updateWhitelist(
        address[] calldata addresses,
        bool value
    ) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = value;
        }
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }

    function setBaseURI(string calldata _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function toggleSale(bool _toggle) external onlyOwner {
        sale = _toggle;
    }

    function toggleWhitelistSale(bool _toggle) external onlyOwner {
        whitelistSale = _toggle;
    }

    function mintTo(uint256 _amount, address _to) external onlyOwner {
        require(_totalMinted() + _amount <= maxSupply, "Max Supply");
        _mint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
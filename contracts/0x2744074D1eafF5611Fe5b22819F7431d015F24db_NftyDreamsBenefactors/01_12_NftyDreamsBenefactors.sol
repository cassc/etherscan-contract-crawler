// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract NftyDreamsBenefactors is ERC1155, Ownable, ERC1155Burnable {
    string private _name;
    string private _symbol;

    uint256 public _maxPerWallet = 5;
    uint256 public _maxTermLimit = 2;
    address public _redeemAddress;
    bool public _isPublicSaleActive = false;

    mapping(uint256 => uint256) public _price;
    mapping(uint256 => string) public _tokenURI;
    mapping(uint256 => uint256) public _totalSupply;
    mapping(uint256 => uint256) public _currentSupply;
    mapping(uint256 => mapping(uint256 => uint256)) public _tokenId;
    mapping(address => mapping(uint256 => uint256)) public _minted;

    event PublicSaleMinted(
        address indexed to,
        uint256 indexed tokenType,
        uint256 indexed term,
        uint256 amount
    );

    event ReservesMinted(
        address indexed to,
        uint256 indexed tokenType,
        uint256 indexed term,
        uint256 amount
    );

    constructor() ERC1155("ipfs://ipfs/") {
        _name = "NftyDreams DAO Benefactors";
        _symbol = "NDDB";
        _init();
    }

    modifier mintCheck(
        uint256 tokenType,
        uint256 term,
        uint256 amount,
        uint256 value
    ) {
        require(_isPublicSaleActive == true, "Public Sale not active");
        require(0 < tokenType && tokenType < 5, "Invalid token type");
        require(term <= _maxTermLimit, "Exceeding max term limit");
        require(
            _minted[msg.sender][tokenType] + amount <= _maxPerWallet,
            "Exceeding max mint per wallet limit"
        );
        require(
            _currentSupply[tokenType] + amount <= _totalSupply[tokenType],
            "Exceeding max supply limit"
        );
        require(
            value == (amount * term) * _price[tokenType],
            "Ether value sent is incorrect"
        );
        _;
    }

    modifier mintReserveCheck(
        uint256 tokenType,
        uint256 term,
        uint256 amount
    ) {
        require(0 < tokenType && tokenType < 5, "Invalid token type");
        require(term <= _maxTermLimit, "Exceeding max term limit");
        require(
            _currentSupply[tokenType] + amount <= _totalSupply[tokenType],
            "Exceeding max supply limit"
        );
        _;
    }

    function _init() internal {
        _tokenId[1][1] = 1;
        _tokenId[1][2] = 2;
        _tokenId[2][1] = 3;
        _tokenId[2][2] = 4;
        _tokenId[3][1] = 5;
        _tokenId[3][2] = 6;
        _tokenId[4][1] = 7;
        _tokenId[4][2] = 8;

        _totalSupply[1] = 2000;
        _totalSupply[2] = 500;
        _totalSupply[3] = 100;
        _totalSupply[4] = 5;

        _price[1] = 0.19 ether; //Pioneer
        _price[2] = 1.9 ether;  //Patron
        _price[3] = 19 ether;   //Nexus
        _price[4] = 190 ether;  //Visionary
    }

    function mintPublic(
        uint256 tokenType,
        uint256 term,
        uint256 amount
    ) external payable mintCheck(tokenType, term, amount, msg.value) {
        _minted[msg.sender][tokenType] += amount;
        _currentSupply[tokenType] += amount;

        uint256 tokenId = _tokenId[tokenType][term];
        _mint(msg.sender, tokenId, amount, "");
        emit PublicSaleMinted(msg.sender, tokenType, term, amount);
    }

    function mintReserves(
        address to,
        uint256 tokenType,
        uint256 term,
        uint256 amount
    ) external onlyOwner mintReserveCheck(tokenType, term, amount) {
        _minted[to][tokenType] += amount;
        _currentSupply[tokenType] += amount;

        uint256 tokenId = _tokenId[tokenType][term];
        _mint(to, tokenId, amount, "");
        emit ReservesMinted(to, tokenType, term, amount);
    }

    function burnToRedeem(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        require(
            _redeemAddress != 0x0000000000000000000000000000000000000000,
            "Redeem address not set"
        );
        require(msg.sender == _redeemAddress, "Not authorized");
        _burn(account, id, amount);
    }

    function burnBatchToRedeem(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        require(
            _redeemAddress != 0x0000000000000000000000000000000000000000,
            "Redeem address not set"
        );
        require(msg.sender == _redeemAddress, "Not authorized");
        _burnBatch(account, ids, amounts);
    }

    function setURI(uint256 id, string memory newURI) external onlyOwner {
        _tokenURI[id] = newURI;
        emit URI(newURI, id);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _tokenURI[id];
    }

    function setPrice(uint256 tokenType, uint256 price) external onlyOwner {
        _price[tokenType] = price;
    }

    function setWalletLimit(uint256 limit) external onlyOwner {
        _maxPerWallet = limit;
    }

    function setSaleStatus(bool publicSale) external onlyOwner {
        _isPublicSaleActive = publicSale;
    }

    function setRedeemAddress(address redeemAddress) external onlyOwner {
        _redeemAddress = redeemAddress;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function withdrawFunds() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function recoverERC20(IERC20 tokenContract, address to) external onlyOwner {
        tokenContract.transfer(to, tokenContract.balanceOf(address(this)));
    }
}
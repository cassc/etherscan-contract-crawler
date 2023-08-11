// SPDX-License-Identifier: MIT

/*
*   @author   0xtp
*   @title    ArtPacks Pass
*
*   █████╗     ██████╗     ████████╗    ██████╗      █████╗      ██████╗    ██╗  ██╗    ███████╗
*  ██╔══██╗    ██╔══██╗    ╚══██╔══╝    ██╔══██╗    ██╔══██╗    ██╔════╝    ██║ ██╔╝    ██╔════╝
*  ███████║    ██████╔╝       ██║       ██████╔╝    ███████║    ██║         █████╔╝     ███████╗
*  ██╔══██║    ██╔══██╗       ██║       ██╔═══╝     ██╔══██║    ██║         ██╔═██╗     ╚════██║ 
*  ██║  ██║    ██║  ██║       ██║       ██║         ██║  ██║    ╚██████╗    ██║  ██╗    ███████║ 
*  ╚═╝  ╚═╝    ╚═╝  ╚═╝       ╚═╝       ╚═╝         ╚═╝  ╚═╝     ╚═════╝    ╚═╝  ╚═╝    ╚══════╝                               
*
*/

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract ArtPacksPass is ERC1155, Ownable, ERC1155Burnable {
    string private _name;
    string private _symbol;

    address public _redeemAddress;
    uint256 public _maxPerMint = 5;
    uint256 public _maxPassLimit = 3;
    uint256 public _maxDropLimit = 13;
    bool    public _isPublicSaleActive = false;

    mapping(uint256 => uint256) public _price;
    mapping(uint256 => string)  public _tokenURI;
    mapping(uint256 => uint256) public _totalSupply;
    mapping(uint256 => uint256) public _burnedSupply;
    mapping(uint256 => uint256) public _mintedSupply;
    mapping(address => mapping(uint256 => uint256)) public _minted;
    mapping(address => mapping(uint256 => uint256)) public _burned;
    mapping(uint256 => mapping(uint256 => uint256)) public _tokenId;

    event PublicSaleMinted(
        address indexed to,
        uint256 indexed passType,
        uint256 indexed dropType,
        uint256 amount
    );

    event ReservesMinted(
        address indexed to,
        uint256 indexed passType,
        uint256 indexed dropType,
        uint256 amount
    );

    event BurnedToRedeem(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount
    );

    event BurnedBatchToRedeem(
        address indexed to,
        uint256[] indexed tokenIds,
        uint256[] amounts
    );

    constructor() ERC1155("ipfs://ipfs/") {
        _name = "ArtPacks Pass";
        _symbol = "APP";
        _init();
    }

    modifier mintCheck(
        uint256 passType,
        uint256 dropType,
        uint256 amount,
        uint256 value
    ) {
        require(_isPublicSaleActive == true, "Public Sale not active");
        require(amount <= _maxPerMint, "Exceeding max per mint");
        require(0 < passType && passType <= _maxPassLimit, "Invalid Pass type");
        require(0 < dropType && dropType <= _maxDropLimit, "Invalid Drop type");
        uint256 tokenId = _tokenId[passType][dropType];
        require(
            _mintedSupply[tokenId] + amount <= _totalSupply[passType],
            "Exceeding max supply limit"
        );
        require(
            value == amount *  _price[passType],
            "Ether value sent is incorrect"
        );
        _;
    }

    modifier mintReserveCheck(
        uint256 passType,
        uint256 dropType,
        uint256 amount
    ) {
        require(0 < passType && passType <= _maxPassLimit, "Invalid Pass type");
        require(0 < dropType && dropType <= _maxDropLimit, "Invalid Drop type");
        uint256 tokenId = _tokenId[passType][dropType];
        require(
            _mintedSupply[tokenId] + amount <= _totalSupply[passType],
            "Exceeding max supply limit"
        );
        _;
    }

    function _init() internal {
        // Triple Pass
        _tokenId[1][1] = 1;
        _tokenId[1][2] = 2;
        _tokenId[1][3] = 3;
        _tokenId[1][4] = 4;
        _tokenId[1][5] = 5;
        _tokenId[1][6] = 6;
        _tokenId[1][7] = 7;
        _tokenId[1][8] = 8;
        _tokenId[1][9] = 9;
        _tokenId[1][10] = 10;
        _tokenId[1][11] = 11;
        _tokenId[1][12] = 12;
        _tokenId[1][13] = 13;

        // Season Pass
        _tokenId[2][1] = 14;

        // Whale Pass
        _tokenId[3][1] = 15;
        _tokenId[3][2] = 16;
        _tokenId[3][3] = 17;
        _tokenId[3][4] = 18;
        _tokenId[3][5] = 19;
        _tokenId[3][6] = 20;
        _tokenId[3][7] = 21;
        _tokenId[3][8] = 22;
        _tokenId[3][9] = 23;
        _tokenId[3][10] = 24;
        _tokenId[3][11] = 25;
        _tokenId[3][12] = 26;
        _tokenId[3][13] = 27;

        _totalSupply[1] = 50;   // Triple Pass
        _totalSupply[2] = 50;   // Season Pass
        _totalSupply[3] = 5;    // Whale Pass

        _price[1] = 0.36 ether; // Triple Pass
        _price[2] = 1.25 ether; // Season Pass
        _price[3] = 3 ether;    // Whale Pass
    }

    function mintPublic(
        uint256 passType,
        uint256 dropType,
        uint256 amount
    ) external payable mintCheck(passType, dropType, amount, msg.value) {
        uint256 tokenId = _tokenId[passType][dropType];
        _minted[msg.sender][tokenId] += amount;
        _mintedSupply[tokenId] += amount;

        _mint(msg.sender, tokenId, amount, "");
        emit PublicSaleMinted(msg.sender, passType, dropType, amount);
    }

    function mintReserves(
        address to,
        uint256 passType,
        uint256 dropType,
        uint256 amount
    ) external onlyOwner mintReserveCheck(passType, dropType, amount) {
        uint256 tokenId = _tokenId[passType][dropType];
        _minted[msg.sender][tokenId] += amount;
        _mintedSupply[tokenId] += amount;

        _mint(to, tokenId, amount, "");
        emit ReservesMinted(to, passType, dropType, amount);
    }

    function burnToRedeem(
        address account,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(
            _redeemAddress != 0x0000000000000000000000000000000000000000,
            "Redeem address not set"
        );
        require(msg.sender == _redeemAddress, "Sender not authorized to redeem");
        _burnedSupply[tokenId] += amount;
        _burned[account][tokenId] += amount;
        _minted[account][tokenId] -= amount;
        _burn(account, tokenId, amount);
        emit BurnedToRedeem(account, tokenId, amount);
    }

    function burnBatchToRedeem(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external {
        require(
            _redeemAddress != 0x0000000000000000000000000000000000000000,
            "Redeem address not set"
        );
        uint256 noOfTokens = tokenIds.length;
        require(amounts.length == noOfTokens, "Invalid Arguments");
        require(msg.sender == _redeemAddress, "Sender not authorized to redeem");

        for (uint256 i; i < noOfTokens; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            _burnedSupply[tokenId] += amount;
            _burned[account][tokenId] += amount;
            _minted[account][tokenId] -= amount;
        }

        _burnBatch(account, tokenIds, amounts);
        emit BurnedBatchToRedeem(account, tokenIds, amounts);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _tokenURI[id];
    }

    function setURI(uint256 id, string memory newURI) external onlyOwner {
        _tokenURI[id] = newURI;
        emit URI(newURI, id);
    }

    function setBulkURIs(uint256[] memory ids, string[] memory newURIs) external onlyOwner {
        uint256 noOfTokens = ids.length;
        require(newURIs.length == noOfTokens, "Invalid Arguments");

        for (uint256 i; i < noOfTokens; i++) {
            uint256 id = ids[i];
            string memory newURI = newURIs[i];
            _tokenURI[id] = newURI;
            emit URI(newURI, id);
        }
    }

    function setPrice(uint256 passType, uint256 price) external onlyOwner {
        _price[passType] = price;
    }

    function setMaxPassLimit(uint256 limit) external onlyOwner {
        _maxPassLimit = limit;
    }

    function setMaxDropLimit(uint256 limit) external onlyOwner {
        _maxDropLimit = limit;
    }

    function setMaxPerMint(uint256 limit) external onlyOwner {
        _maxPerMint = limit;
    }

    function setSaleStatus(bool publicSale) external onlyOwner {
        _isPublicSaleActive = publicSale;
    }

    function setRedeemAddress(address redeemAddress) external onlyOwner {
        _redeemAddress = redeemAddress;
    }

    function withdrawFunds() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function recoverERC20(IERC20 tokenContract, address to) external onlyOwner {
        tokenContract.transfer(to, tokenContract.balanceOf(address(this)));
    }
}
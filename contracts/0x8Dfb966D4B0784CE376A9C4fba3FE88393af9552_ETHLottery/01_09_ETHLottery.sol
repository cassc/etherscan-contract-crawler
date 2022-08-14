//SPDX-License-Identifier: Unlicense

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%/                         #%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%                               %%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%                                   %%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%                                       %%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%                                         %%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%,                                         (%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%                      .%                   %%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%                     %                     %%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%                     %                     %%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%                                         %%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%*                                       #%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%.                                   .%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%,..                             ..*%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%#...                      ....%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%,.......       .......,%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%,,,,,,,,,,,,*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ETHLottery is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;

    string  public baseTokenURI = "https://bafybeifz2dz27fjt2gallt5i6ovez4bmgbha7fikrt6y2olkyevrffjssq.ipfs.nftstorage.link/metadata";
    uint256 public MAX_SUPPLY = 5000;
    uint256 public MAX_FREE_SUPPLY = 0;
    uint256 public MAX_PER_TX = 20;
    uint256 public PRICE = 0.001 ether;
    uint256 public MAX_FREE_PER_WALLET = 1;
    uint256 public maxFreePerTx = 1;
    bool public initialize = true;
    bool public revealed = true;
    string  public winner = "";
    uint initialNumber = 0;

    event NewNumbers(address sender, uint256 qty);
    event NewBurnNumbers(address sender, uint256 qty);

    mapping(address => uint256) public qtyFreeMinted;
    mapping(uint => string) public drawnNumbers;

    constructor() ERC721A("EthLottery", "ETHLOT") {}

    function mint(uint256 amount) external payable
    {
        uint256 cost = PRICE;
        uint256 num = amount > 0 ? amount : 1;
        bool free = ((totalSupply() + num < MAX_FREE_SUPPLY + 1) &&
            (qtyFreeMinted[msg.sender] + num <= MAX_FREE_PER_WALLET));
        if (free) {
            cost = 0;
            qtyFreeMinted[msg.sender] += num;
            require(num < maxFreePerTx + 1, "Max per TX reached.");
        } else {
            require(num < MAX_PER_TX + 1, "Max per TX reached.");
        }

        require(initialize, "Minting is not live yet.");
        require(msg.value >= num * cost, "Please send the exact amount.");
        require(totalSupply() + num < MAX_SUPPLY + 1, "No more");

        _safeMint(msg.sender, num);
        emit NewNumbers(msg.sender, amount);
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner nonReentrant
    {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseTokenURI, "/", _tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseTokenURI;
    }

    function reveal(bool _revealed) external onlyOwner
    {
        revealed = _revealed;
    }

    function setInitialize(bool _initialize) external onlyOwner
    {
        initialize = _initialize;
    }

    function setPrice(uint256 _price) external onlyOwner
    {
        PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_PER_TX = _limit;
    }

    function setLimitFreeMintPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_FREE_PER_WALLET = _limit;
    }

    function setMaxFreeAmount(uint256 _amount) external onlyOwner
    {
        MAX_FREE_SUPPLY = _amount;
    }

    function burnNumbers(uint256[] memory tokenids) external onlyOwner {
        uint256 len = tokenids.length;
        for (uint256 i; i < len; i++) {
            uint256 tokenid = tokenids[i];
            _burn(tokenid);
        }

        emit NewBurnNumbers(msg.sender, len);
    }

    function random(uint number) internal returns(uint){
        return uint(keccak256(abi.encodePacked(initialNumber++))) % number;
    }

    function compareStringsbyBytes(string memory s1, string memory s2) internal pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function concatenate(string memory a,string memory b) internal pure returns (string memory){
        return string(bytes.concat(bytes(a), " ", bytes(b)));
    }

    function alreadyBeenDrawn(uint qty, string memory number) internal view returns(bool) {
        for (uint256 i; i < qty; i++) {
           if (compareStringsbyBytes(drawnNumbers[i], number)) {
               return true;
           }
        }

        return false;
    }

    function resetWinner() external onlyOwner {
        winner = "";
        initialNumber = 0;
    }

    function drawNumbers(uint qty) external onlyOwner {
        for (uint i = 0; i < qty; i++) {
            string memory number = Strings.toString(random(MAX_SUPPLY));

            while (alreadyBeenDrawn(qty, number)) {
                number = Strings.toString(random(MAX_SUPPLY));
            }

            drawnNumbers[i] = number;

            winner = concatenate(winner, number);
        }
    }
}
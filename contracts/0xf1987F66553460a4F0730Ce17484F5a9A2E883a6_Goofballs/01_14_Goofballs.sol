//SPDX-License-Identifier: NONE
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//  ██████╗  ██████╗  ██████╗ ███████╗██████╗  █████╗ ██╗     ██╗          ██████╗  █████╗ ███╗   ██╗ ██████╗
// ██╔════╝ ██╔═══██╗██╔═══██╗██╔════╝██╔══██╗██╔══██╗██║     ██║         ██╔════╝ ██╔══██╗████╗  ██║██╔════╝
// ██║  ███╗██║   ██║██║   ██║█████╗  ██████╔╝███████║██║     ██║         ██║  ███╗███████║██╔██╗ ██║██║  ███╗
// ██║   ██║██║   ██║██║   ██║██╔══╝  ██╔══██╗██╔══██║██║     ██║         ██║   ██║██╔══██║██║╚██╗██║██║   ██║
// ╚██████╔╝╚██████╔╝╚██████╔╝██║     ██████╔╝██║  ██║███████╗███████╗    ╚██████╔╝██║  ██║██║ ╚████║╚██████╔╝
//  ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝

contract Goofballs is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint8 public constant BLOCK_SIZE = 32;
    uint8 public constant MAX_PURCHASE = 20;

    uint256 public MAX_SUPPLY;
    uint256 public dropped;
    bool public saleIsActive = true;
    uint256 private _price = 0.05 ether;
    string private _baseTokenURI;

    uint16[] public _availableBlocks;
    uint8[] public _numAvailableInBlock;

    address private allowedMinter = address(0);
    uint256 public reserved = 0;

    constructor(uint256 maxSupply, uint256 initialDrop, string memory baseTokenURI) ERC721("Goofball", "GOOF") {
        require(maxSupply % BLOCK_SIZE == 0);
        MAX_SUPPLY = maxSupply;
        _baseTokenURI = baseTokenURI;
        _drop(initialDrop);
    }

    function getNFTPrice() public view returns (uint256) {
        return _price;
    }

    function mint(uint256 num) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale must be active!");
        require(num <= MAX_PURCHASE, "Exceeds maximum mint amount");
        require(supply + num + reserved <= dropped, "Exceeds maximum supply");
        require(msg.value >= getNFTPrice() * num, "Ether sent is not correct");
        for (uint8 i; i < num; i++) {
            mintToken(msg.sender, i);
        }
    }

    function mintToken(address _newOwner, uint256 num) private {
        uint256 seed = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, num)));
        uint8 indexInBlock = uint8(seed % BLOCK_SIZE);
        uint16 blockIndex = uint16((seed / BLOCK_SIZE) % _availableBlocks.length);
        uint16 blockStart = _availableBlocks[blockIndex];
        while (_exists(blockStart + indexInBlock + 1)) {
            indexInBlock = (indexInBlock + 1) % BLOCK_SIZE;
        }
        _safeMint(_newOwner, blockStart + indexInBlock + 1);
        if (_numAvailableInBlock[blockIndex] <= 1) {
            uint256 lastIndex = _availableBlocks.length - 1;
            if (blockIndex != lastIndex) {
                _availableBlocks[blockIndex] = _availableBlocks[lastIndex];
                _numAvailableInBlock[blockIndex] = _numAvailableInBlock[lastIndex];
            }
            _numAvailableInBlock.pop();
            _availableBlocks.pop();
        } else {
            _numAvailableInBlock[blockIndex]--;
        }
    }

    function _drop(uint256 num) internal {
        require(num % BLOCK_SIZE == 0);
        require(dropped + num <= MAX_SUPPLY);
        uint16 lastBlock = uint16((dropped + num) / BLOCK_SIZE);
        for (uint16 i = uint16(dropped / BLOCK_SIZE); i < lastBlock; i++) {
            _availableBlocks.push(i * BLOCK_SIZE);
            _numAvailableInBlock.push(BLOCK_SIZE);
        }
        dropped += num;
    }

    function drop(uint256 num) external onlyOwner {
        _drop(num);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract"));
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawBalance(uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = address(this).balance;
        }
        // https://consensys.github.io/smart-contract-best-practices/recommendations/#dont-use-transfer-or-send
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function giveAway(address to, uint256 num) external onlyOwner nonReentrant {
        uint256 supply = totalSupply();
        require(supply + num + reserved <= dropped, "Exceeds maximum supply");
        for (uint256 i; i < num; i++) {
            mintToken(to, i);
        }
    }

    function setRestrictedMinter(address minter, uint16 reservedCount) external onlyOwner {
        allowedMinter = minter;
        reserved = reservedCount;
    }

    function restrictedMint(address to, uint256 num) external nonReentrant {
        uint256 supply = totalSupply();
        require(allowedMinter == msg.sender, "Contract not allowed to mint");
        require(num <= MAX_PURCHASE, "Exceeds maximum mint amount");
        require(saleIsActive, "Sale must be active!");
        require(num <= reserved, "Exceeds reserved number");
        require(supply + num <= dropped, "Exceeds maximum supply");
        for (uint8 i; i < num; i++) {
            mintToken(to, i);
        }
        reserved -= uint16(num);
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }
}
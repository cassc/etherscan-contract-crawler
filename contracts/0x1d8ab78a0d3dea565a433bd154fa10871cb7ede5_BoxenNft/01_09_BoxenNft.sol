// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC721A.sol";

contract BoxenNft is ERC721A, Ownable {

    constructor() ERC721A("Box of boxen", "bob") {}

    string private _uri;

    address public constant boxenToken = 0xc05d8c246e441Ed41d3cF6Bd48f0607946F8Ba27;
    uint public constant maxSupply = 7777;
    uint public constant maxLegendaryMint = 500;
    bool public saleStatus = false;
    uint public price = 77 * 10**14;
    uint public maxPerTx = 5;
    uint public maxPerWallet = 5;
    uint public legendaryBoxenPrice = 770000 * 10**18;

    uint public ratio = 30000000;
    uint public legendaryMintCount = 0;
    
    bool private isLegendaryMint = false;

    enum NFT_TYPE {
        BOX_LEGENDARY,
        BOX_RARE,
        BOX_UNNORMOL,
        KEY_LULU
    }
 
    // ---------------------------------------------------------------------------------------------
    // MAPPINGS
    // ---------------------------------------------------------------------------------------------

    mapping(address => uint) public feeMinted; 

    mapping(uint256 => NFT_TYPE) public tokenType;

    // ---------------------------------------------------------------------------------------------
    // OWNER SETTERS
    // ---------------------------------------------------------------------------------------------

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawBoxen() external onlyOwner {
        uint256 balance = IERC20(boxenToken).balanceOf(address(this));
        IERC20(boxenToken).transfer(msg.sender, balance);
    }

    function setSaleStatus() external onlyOwner {
        saleStatus = !saleStatus;
    }


    function setPrice(uint amount) external onlyOwner {
        price = amount;
    }

    function setLegendaryBoxenPrice(uint amount) external onlyOwner {
        legendaryBoxenPrice = amount;
    }
    
    function setMaxPerTx(uint amount) external onlyOwner {
        maxPerTx = amount;
    }
    
    function setMaxPerWallet(uint amount) external onlyOwner {
        maxPerWallet = amount;
    }

    
    function setBaseURI(string calldata uri_) external onlyOwner {
        _uri = uri_;
    }

    function setRatio(uint _ratio) external onlyOwner {
        ratio = _ratio;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function _getType(uint256 tokenId) internal view returns (NFT_TYPE nftType) {
        bytes32 dataHash = keccak256(
            abi.encode(
                tokenId,
                block.timestamp,
                block.coinbase,
                msg.sender
            )
        );
        uint8 rv = uint8(bytes1(dataHash));
        if (rv < 13) {
            return NFT_TYPE.BOX_LEGENDARY;
        } else if (rv < 58) {
            return NFT_TYPE.BOX_RARE;
        } else if (rv < 119) {
            return NFT_TYPE.BOX_UNNORMOL;
        } else {
            return NFT_TYPE.KEY_LULU;
        }
    }

     
    function _afterTokenTransfers(
        address from,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal override  {
        if (from != address(0)) {
            return;
        }

        uint256 offset = 0;
        do {
            uint256 currentTokenId = startTokenId + offset++;
            if (isLegendaryMint) {
                tokenType[currentTokenId] = NFT_TYPE.BOX_LEGENDARY;
            } else {
                tokenType[currentTokenId] = _getType(currentTokenId);
            }
        } while (offset < quantity);
    }

    function devMint(uint256 amount) external onlyOwner {
        require(amount > 0, "AMOUNT_ERROR!");
        require((_totalMinted() + amount) <= maxSupply, "NOT_ENOUGH_TOKENS");
        _safeMint(msg.sender, amount);
    }

    function getPayBoxenAmount(uint256 mintAmount, uint256 ethValue) public view  returns (uint256 amount) {
        uint expectPayAmount = mintAmount * price;
        if (ethValue >= expectPayAmount) {
            return 0;
        }
        return (expectPayAmount - ethValue) * ratio;
    }

     function getPayEthAmount(uint256 mintAmount, uint256 boxenValue) public view  returns (uint256 payEthAmount, uint256 boxenRemainder) {
        uint expectPayAmount = mintAmount * price;
        uint boxenToEthAmount = boxenValue / ratio;
        boxenRemainder = boxenValue % ratio;
        if (boxenToEthAmount >= expectPayAmount) {
            payEthAmount = 0;
        }
        payEthAmount =  expectPayAmount - boxenToEthAmount;
    }

    function getCanMintAmount(address addr) public view  returns (uint256 amount) {
        return (maxSupply - _totalMinted()) < (maxPerWallet - feeMinted[addr]) ? (maxSupply - _totalMinted()) : (maxPerWallet - feeMinted[addr]);
    }

    function getCanLegendaryMintAmount() public view  returns (uint256 amount) {
        return (maxSupply - _totalMinted()) < (maxLegendaryMint - legendaryMintCount) ? (maxSupply - _totalMinted()) : (maxLegendaryMint - legendaryMintCount);
    }

    function mint(uint256 amount) external payable {
        require(amount > 0, "AMOUNT_ERROR!");
        require(saleStatus, "SALE_NOT_ACTIVE!");
        require(tx.origin == msg.sender, "NOT_ALLOW_CONTRACT_CALL!");
        require((_totalMinted() + amount) <= maxSupply, "NOT_ENOUGH_TOKENS!");
        require(amount <= maxPerTx, "EXCEEDS_MAX_PER_TX!");
        require(feeMinted[msg.sender] + amount <= maxPerWallet, "EXCEEDS_MAX_PER_WALLET!");
        uint expectPayAmount = amount * price;
        if (expectPayAmount > msg.value) {
            uint expectPayBoxenAmount = (expectPayAmount - msg.value) * ratio;
            SafeERC20.safeTransferFrom(IERC20(boxenToken), msg.sender, address(this), expectPayBoxenAmount);
        }
        _safeMint(msg.sender, amount);
        feeMinted[msg.sender] += amount;
    }

    function legendaryMint(uint256 amount) external payable {
        require(amount > 0, "AMOUNT_ERROR!");
        require(saleStatus, "SALE_NOT_ACTIVE!");
        require((_totalMinted() + amount) <= maxSupply, "NOT_ENOUGH_TOKENS!");
        require(legendaryMintCount + amount <= maxLegendaryMint, "NOT_ENOUGH_TOKENS");
        legendaryMintCount += amount;
        require(msg.value >= amount * price, "NOT_ENOUGH_ETH");
        SafeERC20.safeTransferFrom(IERC20(boxenToken), msg.sender, address(this), amount * legendaryBoxenPrice);
        isLegendaryMint = true;
        _safeMint(msg.sender, amount);
        isLegendaryMint = false;
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        NFT_TYPE currentType = tokenType[tokenId];
        string memory currentUri = "";
        if (currentType == NFT_TYPE.BOX_LEGENDARY) {
            currentUri = "BOX_LEGENDARY";
        } else if (currentType == NFT_TYPE.BOX_RARE) {
            currentUri = "BOX_RARE";
        } else if (currentType == NFT_TYPE.BOX_UNNORMOL) {
            currentUri = "BOX_UNNORMOL";
        } else {
            currentUri = "KEY_LULU";
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, currentUri)) : '';
    }
}
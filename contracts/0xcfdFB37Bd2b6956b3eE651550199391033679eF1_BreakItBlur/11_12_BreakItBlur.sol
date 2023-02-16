// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "./ERC721A.sol";


contract BreakItBlur is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant maxSupply = 690;


    uint256 public blurCost = 0.01 ether;
    bool public blurStart;

    uint256 public  blurPerTxn = 5;
    uint256 public  blurWallet = 10;

    string private _baseTokenURI;

    constructor() ERC721A("Break It Blur", "BIB") {
        _safeMint(msg.sender,5);
    }


    modifier underMaxSupply(uint256 _quantity) {
        require(
            _totalMinted() + _quantity <= maxSupply,
            "Mint would exceed max supply"
        );

        _;
    }

    modifier validatePublicStatus(uint256 _quantity) {
        require(blurStart, "Sale hasn't started");

        require(msg.value >= blurCost * _quantity, "Need to send more ETH.");
        
        require(_quantity > 0 && _quantity <= blurPerTxn, "Invalid mint amount.");
        require(
            _numberMinted(msg.sender) + _quantity <= blurWallet,
            "This purchase would exceed maximum allocation for public mints for this wallet"
        );

        _;
    }

    /**
     * @dev override ERC721A _startTokenId()
     */
    function _startTokenId() 
        internal 
        view 
        virtual
        override 
        returns (uint256) {
        return 0;
    }

    function mint(uint256 _quantity)
        external
        payable
        validatePublicStatus(_quantity)
        underMaxSupply(_quantity)
    {
        _mint(msg.sender, _quantity, "", false);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function teamClaim(uint256 num) external onlyOwner {
        // claim
        _safeMint(tx.origin, num);
    }

    function setMaxPerTxn(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        blurPerTxn = _num;
    } 

    function setMaxPerWallet(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        blurWallet = _num;
    } 

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= 0, "Token price must be greater than zero");
        blurCost = newPrice;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function flipPublicSale() external onlyOwner {
        blurStart = !blurStart;
    }

}
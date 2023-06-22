// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721G.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract ZRRNFT is ERC721G, DefaultOperatorFilterer, Ownable, ERC721Holder{
    using Strings for uint256;

    bool public isPublic;
    bool public isNotWhite;
    uint256 public maxSupply;
    address public devAddress;
    uint256 public constant WHITE_PRICE = 300000000000000000; //0.3 ETH
    uint256 public constant PRIV_PRICE = 300000000000000000; //0.3 ETH
    uint256 public constant PUB_PRICE = 430000000000000000; //0.43 ETH
    string private _baseTokenURI;
    constructor() ERC721G("Zodiac Rankings Race", "ZRR", 1, 3) {
        maxSupply = 999;
        devAddress = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == devAddress || msg.sender == owner(), "ZRR: Only Governance");
        _;
    }

    function chgToPub() external onlyGovernance {
        isPublic = !isPublic;
    }

    function chgToNotWhite() external onlyGovernance {
        isNotWhite = !isNotWhite;
    }

    function setBaseURI(string calldata baseURI) external onlyGovernance {
        _baseTokenURI = baseURI;
    }

    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner{
        IERC20(_tokenContract).transfer(msg.sender, _amount);
    }
    
    function mint(uint256 _amount) payable external{
        if(!isNotWhite) {
            require(_amount <= 1, "ZRR: Max 1 per mint");
            require(msg.value == WHITE_PRICE * _amount, "ZRR: Priv Insufficient ETH");
            require(_balanceData[msg.sender].mintedAmount < 1, "ZRR: Max 1 mint per address");
            require(_amount + totalSupply() <= 40, "ZRR: End for whitelist sales");
        }
        else {
            require(_amount <= 3, "ZRR: Max 3 per mint");
            require(_balanceData[msg.sender].mintedAmount < 3, "ZRR: Max 3 mint per address");
            if (!isPublic) {
                require(msg.value == PRIV_PRICE * _amount, "ZRR: Insufficient ETH");
                require(_amount + totalSupply() <= 666, "ZRR: End for private sales");

            }
            else {
                require(msg.value == PUB_PRICE * _amount, "ZRR: Insufficient ETH");
                require(_amount + totalSupply() <= maxSupply, "ZRR: All minted");

            }
        }

        _mint(msg.sender, _amount);
    }

    function _baseURI() internal view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId_) public override view returns (string memory) {
        require(tokenId_ > 0, "ZRR: Id starts from 1");
        require(_exists(tokenId_),"ZRR: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0  ? string(abi.encodePacked(baseURI, tokenId_.toString())) : "";
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
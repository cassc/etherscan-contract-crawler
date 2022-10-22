// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ChuckySoulFragments is ERC721 {
    using Strings for uint256;

    uint256 public tokenId = 0;
    address private _owner;
    uint256 public mintPrice;
    uint256 public startTime;
    uint256 public maxSupply;
    string public baseURI = "";
    mapping(address => bool) private adminAddressList;

    uint256 maxBalance;

    modifier onlyOwner() {
        require(adminAddressList[msg.sender], "only owner");
        _;
    }

    constructor(string memory _baseUri, uint256 _maxSupply,uint256 _startTime)
        ERC721("Chuckys Soul Fragments", "CSF")
    {
        baseURI = _baseUri;
        maxBalance = 1;
        mintPrice = 0.02 ether;
        maxSupply = _maxSupply;
        adminAddressList[msg.sender] = true;
       startTime = _startTime;
    }

    function mint(address _to) external payable {
        require(block.timestamp>=startTime,"not start");
        require(tokenId < maxSupply, "Exceed Max Supply");
        require(msg.value >= mintPrice, "Not Enough ETH");
        require(balanceOf(_to) <= maxBalance, "Exceed Max");
        _mint(_to, tokenId);
        tokenId += 1;
    }

    function totalSupply() external view returns (uint256) {
        return tokenId;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseURI, "/", _tokenId.toString(), ".json")
            );
    }

    function transferFrom(
        address from,
        address to,
        uint256 _tokenId
    ) public virtual override onlyOwner {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, _tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 _tokenId
    ) public virtual override onlyOwner {
        safeTransferFrom(from, to, _tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override onlyOwner {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, _tokenId, _data);
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(to).transfer(balance);
        }
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setAdminInfo(address _addr, bool _bool) external onlyOwner {
        adminAddressList[_addr] = _bool;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner{
        baseURI = _baseURI;
    }


}
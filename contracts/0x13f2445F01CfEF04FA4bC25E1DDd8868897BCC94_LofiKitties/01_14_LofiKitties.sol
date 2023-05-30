// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LofiKitties is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address;

    string public baseURI;
    string public prerevealURI;
    string public provenance = "";
    uint256 public offsetIndex = 0;
    uint256 public offsetIndexBlock = 0;
    uint256 public cost = 0.045 ether;
    uint256 public maxSupply = 9999;
    uint256 public maxMintAmount = 9;
    uint256 public maxPresaleMintAmount = 5;
    bool public _saleIsActive = false;
    bool public _presaleIsActive = false;
    bool public revealed = false;
    mapping(address => bool) public whitelist;

    event saleStarted();
    event saleStopped();
    event TokenMinted(uint256 supply);
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    constructor() ERC721("Lofi Kitties", "LK") {}

    //internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //public

    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(_saleIsActive);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(
            totalSupply().add(_mintAmount) <= maxSupply,
            "Sale would exceed max supply"
        );
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to call this function"
        );

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        if (offsetIndexBlock == 0 && (totalSupply() >= maxSupply)) {
            offsetIndexBlock = block.number;
        }
    }

    function presaleMint(uint256 _mintAmount) public payable onlyWhitelisted {
        uint256 supply = totalSupply();
        require(_presaleIsActive);
        require(_mintAmount <= maxPresaleMintAmount);
        require(_mintAmount > 0);
        require(
            totalSupply().add(_mintAmount) <= maxSupply,
            "Sale would exceed max supply"
        );
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to call this function"
        );

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
            uint256 ownerTokenCount = balanceOf(msg.sender);
            require(ownerTokenCount < maxPresaleMintAmount);
        }
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        require(tokenId <= maxSupply);
        if (revealed) {
            uint256 offsetId = tokenId.add(maxSupply.sub(offsetIndex)).mod(
                maxSupply
            );
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(currentBaseURI, offsetId.toString())
                    )
                    : "";
        } else {
            return prerevealURI;
        }
    }

    //for whitelist

    function addAddressToWhitelist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    function addAddressesToWhitelist(address[] calldata addrs)
        public
        onlyOwner
        returns (bool success)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    function removeAddressFromWhitelist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    function removeAddressesFromWhitelist(address[] calldata addrs)
        public
        onlyOwner
        returns (bool success)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    // Only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setmaxPresaleMintAmount(uint256 _newMaxPresaleMintAmount)
        public
        onlyOwner
    {
        maxPresaleMintAmount = _newMaxPresaleMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrerevealURI(string memory _prerevealURI) public onlyOwner {
        prerevealURI = _prerevealURI;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function startSale() public onlyOwner {
        _saleIsActive = true;
        emit saleStarted();
    }

    function stopSale() public onlyOwner {
        _saleIsActive = false;
        emit saleStopped();
    }

    function startPresale() public onlyOwner {
        _presaleIsActive = true;
        emit saleStarted();
    }

    function stopPresale() public onlyOwner {
        _presaleIsActive = false;
        emit saleStopped();
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setOffsetIndex() public onlyOwner {
        require(offsetIndex == 0, "Starting index has already been set");
        require(offsetIndexBlock != 0, "Starting index block must be set");

        if (block.number.sub(offsetIndexBlock) > 255) {
            offsetIndex = uint256(blockhash(block.number - 1)).mod(maxSupply);
        } else {
            offsetIndex = uint256(blockhash(offsetIndexBlock)).mod(maxSupply);
        }

        if (offsetIndex == 0) {
            offsetIndex = 1;
        }
    }

    function reserveKitties(uint256 _numKitties) public onlyOwner {
        uint256 supply = totalSupply();
        require(
            totalSupply().add(_numKitties) <= maxSupply,
            "Sale would exceed max supply"
        );
        for (uint256 i = 0; i < _numKitties; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function emergencySetOffsetIndexBlock() public onlyOwner {
        require(offsetIndex == 0, "Starting index is already set");
        offsetIndexBlock = block.number;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
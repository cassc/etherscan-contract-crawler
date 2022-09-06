// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BbWukong is ERC721, Pausable, Ownable {
    using SafeMath for uint256;

    uint16[89] public ids;
    uint16 private index;
    uint256 public WL_PRICE = 0.088 ether;
    uint256 public constant MAX_PER_MINT = 1;
    string public baseTokenURI;
    uint256 private normalWhiteListStart = 1659960000;
    uint256 private reservedWhiteListStart = 1659963600;
    uint256 private endTime = 1660046400; 

    mapping(address => uint256) private _freewhitelist;
    mapping(address => uint256) private _normalwhitelist;
    mapping(address => uint256) private _reservewhitelist;

    constructor(string memory baseURI) ERC721("BbWukong", "BW") {
        setBaseURI(baseURI);
    }

    // random id logic
    function _pickRandomUniqueId(uint256 random) private returns (uint256 id) {
        uint256 len = ids.length - index;
        require(len > 0, "No NFTs left");
        uint256 randomIndex = random % len;
        id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = uint16(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
        ids[len - 1] = 0;
    }

    // mint functions
    function _mintSingle() private {
        require(ids.length > 0, "Not enough NFTs left!");
        uint256 _random = uint256(
            keccak256(
                abi.encodePacked(
                    index++,
                    msg.sender,
                    block.timestamp,
                    blockhash(block.number - 1)
                )
            )
        );
        _safeMint(msg.sender, _pickRandomUniqueId(_random) + 1);
    }

    function _freeMint() private {
        require(block.timestamp > normalWhiteListStart, "Time of mint hasn't begun!");
        require(block.timestamp <= endTime, "Mint has ended");
        _mintSingle();
        _freewhitelist[msg.sender] = 0;
    }

    function burnToken(uint256 tokenId) external {
        require(_exists(tokenId), "token not found");
        require(
            msg.sender == ERC721.ownerOf(tokenId),
            "must be owner of token"
        );
        _burn(tokenId);
    }

    function _whitelistMint() private {
        require(block.timestamp > normalWhiteListStart, "Time of mint hasn't begun!");
        require(block.timestamp <= endTime, "Mint has ended");
        require(
            msg.value >= WL_PRICE.mul(MAX_PER_MINT),
            "Not enough ether to purchase NFTs."
        );
        _mintSingle();
        _normalwhitelist[msg.sender] = 0;
    }

    function _mintMultipleNFT(uint256 _count) public onlyOwner payable {
        //require(block.timestamp > endTime, "Only Mintable after Mint Period ended");
        for (uint256 i = 0; i < _count; i++){
            _mintSingle();
        }
    }

    function _mintSingleNFT() public onlyOwner payable {
        _mintSingle();
    }

    function checkWhiteList() public payable {
        require(ids.length > 0, "No more NFTs left!");
        uint256 _purchaseAvailability = MAX_PER_MINT - balanceOf(msg.sender);
        require(
            _purchaseAvailability >= MAX_PER_MINT,
            "Maximum 1 Mint per user"
        );
        require(_freewhitelist[msg.sender]==1 || _normalwhitelist[msg.sender]==1, "You are not whitelisted! Please try again for the next Mint!");
        if (_freewhitelist[msg.sender]==1){
            _freeMint();
        }
        else if (_normalwhitelist[msg.sender]==1 && block.timestamp > normalWhiteListStart){
            _whitelistMint();
        }
        else if (_reservewhitelist[msg.sender]==1 && block.timestamp > reservedWhiteListStart){
            _whitelistMint();
        }
    }

    // withdraw ether balance from contract
    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    // setters
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setWLPrice(uint256 _price) public onlyOwner {
        WL_PRICE = _price;
    }

    function setFreeWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _freewhitelist[addresses[i]] = 1;
        }
    }

    function setNormalWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _normalwhitelist[addresses[i]] = 1;
        }
    }

    function setReserveWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _reservewhitelist[addresses[i]] = 1;
        }
    }

    // pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // overrides
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
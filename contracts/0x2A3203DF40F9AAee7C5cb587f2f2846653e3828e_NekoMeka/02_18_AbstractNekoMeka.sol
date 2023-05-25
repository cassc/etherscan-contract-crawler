// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Schedulable.sol";
import "./NekoMekaEnumerable.sol";

/**
 * @dev Abstract contracat contains most of the business logic of NEKOMEKA.
 */
abstract contract AbstractNekoMeka is NekoMekaEnumerable, Schedulable, Ownable, Pausable {
    using BitMaps for BitMaps.BitMap;
    using Address for address;

    address public immutable nekoContractAddress;
    uint256 public immutable price;

    // Bsae URI of NekoMeka's metadata
    string private baseURI;

    // Mapping with all claimed neko token ids
    BitMaps.BitMap private _nekosClaimedBitMap;

    // Check
    bool public revealed = false;

    constructor(
        string memory name_,
        string memory symbol_,
        uint16 _mintable,
        uint16 _buyable,
        address _nekoContractAddress,
        uint256 _price,
        uint256 _startTime
    )
        NekoMekaEnumerable(_mintable, _buyable) // prettier-ignore
        ERC721(name_, symbol_) // prettier-ignore
        Schedulable(_startTime) // prettier-ignore
    {
        nekoContractAddress = _nekoContractAddress;
        price = _price;
    }

    function validMintAmount(uint256 _amount, uint256 _maxAmount) internal pure returns (bool) {
        return _amount > 0 && _amount <= _maxAmount;
    }

    function batchLimit() public view returns (uint256) {
        return revealed ? 3 : 20;
    }

    function isClaimed(uint256 _tokenId) public view returns (bool) {
        return _nekosClaimedBitMap.get(_tokenId);
    }

    function _setClaimed(uint256 _tokenId) internal {
        _nekosClaimedBitMap.set(_tokenId);
    }

    function claim(uint256[] calldata _nekoTokenIds) external whenSaleStarted whenNotPaused {
        uint256 _amount = _nekoTokenIds.length;
        require(validMintAmount(_amount, batchLimit()), "MEKA: Over batch limit");
        require(!msg.sender.isContract(), "MEKA: Caller cannot be contract");

        ERC721 nekoContract = ERC721(nekoContractAddress);
        uint256 currentMinted = totalSupply();
        _claimed += uint16(_amount);
        for (uint256 i; i < _amount; i++) {
            uint256 tokenId = _nekoTokenIds[i];
            require(!isClaimed(tokenId), "MEKA: Token claimed already");
            require(nekoContract.ownerOf(tokenId) == msg.sender, "MEKA: Owner not match");
            _setClaimed(tokenId);
            _mint(msg.sender, _pickRandomId(currentMinted + i));
        }
    }

    function mint(uint16 _amount) external payable whenSaleStarted whenNotPaused {
        require(_sold < buyable, "MEKA: All sold");
        require(_sold + _amount <= buyable, "MEKA: Exceeded buyable limit");
        require(validMintAmount(_amount, batchLimit()), "MEKA: Over batch limit");
        require(msg.value >= price * _amount, "MEKA: Incorrect price");
        require(!msg.sender.isContract(), "MEKA: Caller cannot be contract");

        uint256 currentMinted = totalSupply();
        _sold += _amount;
        for (uint256 i; i < _amount; i++) {
            _mint(msg.sender, _pickRandomId(currentMinted + i));
        }
    }

    function reserve() external onlyOwner {
        require(_sold == 0, "MEKA: Sales already started");
        _sold += 10;
        uint256 lastIndex = mintable;
        for (uint256 i; i < 10; i++) {
            lastIndex--;
            _tokensByReversedIndex[lastIndex] = uint16(i);
            _tokensByReversedIndex[i] = uint16(lastIndex);
            _mint(msg.sender, i);
        }
    }

    function setRevealed() external onlyOwner {
        revealed = true;
    }

    function withdrawAll() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance), "MEKA: Cannot withdraw");
    }

    // ERC721Metadata related
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    // Pausable related
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Schedulable related
    function setStartTime(uint256 _start) external onlyOwner whenSaleNotStarted {
        // solhint-disable-next-line not-rely-on-time
        require(_start > block.timestamp, "MEKA: Cannot start from past");
        _setStartTime(_start);
    }

    // For validation only
    function claimedBitMaps(uint256[] calldata indexes)
        external
        view
        returns (uint256[] memory words)
    {
        words = new uint256[](indexes.length);
        for (uint256 i; i < indexes.length; i++) {
            words[i] = _nekosClaimedBitMap._data[i];
        }
    }
}

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@   @@@@@@@@@@@ @@@@@@@@@@@
// @@@@@@@@@@@@@ @@@@         @ @@@@@@@@@@@
// @@@@@@@@@@@@@ @@@@@@@@@@@@@@ @@@@@@@@@@@
// @@@@@@@@@@@@@@ @@@@@@@@@@@@@ @@@@@@@@@@@
// @@@@@@@@@@@@@ @@@@@@   @@@@ @ @@@@@@@@@@
// @@@@@@@@@@@@@ @@@@@@@@@@@##@@ @@@@@@@@@@
// @@@@@@@@@@@@@@@  @@@@@@@ @@@ @@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@ @@@@    @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@  @@@@@@@@@@@ @@@@@@@@@@@
// @@@@@  @@@  @    @@@@@@@@@@@  @@@@@@@@@@
// @@@@ @@ @@  @@@  @@@@@@@@@@@ @@@ @@@@@@@
// @@@@ @@@    @@@@@ @@@@%@@@@ @@@@ @@@@@@@
// @@@@@@@       @@@ @@@@ @@@@ @ @@@@@@@@@@
// @@@@@@@@@@@@@@[email protected]@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
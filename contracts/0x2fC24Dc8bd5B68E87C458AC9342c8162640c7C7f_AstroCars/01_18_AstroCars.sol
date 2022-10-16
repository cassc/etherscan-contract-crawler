//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/WithLimitedSupply.sol";
import "./lib/Allowlists.sol";

/// @title Standard ERC721 NFT.
/// @author NitroLeague.
contract AstroCars is
    ERC721Enumerable,
    Ownable,
    WithLimitedSupply,
    Allowlists,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    string private baseURI;
    string private hiddenCarURI;
    string public constant provenanceHash =
        "a7dfaede3c0bfe5fcf911406066d5dc0e970be50c89a409c98a117d540b59f18";
    bool private _isRevealed;
    bool private _isMetaLocked;

    event Received(address, uint);

    constructor() ERC721("Astro Cars", "NLAC") WithLimitedSupply(1000) {
        _isRevealed = false;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        require(bytes(_baseURI).length > 0, "baseURI cannot be empty");
        require(_isMetaLocked == false, "contract is locked, cannot modify");

        baseURI = _baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (_isRevealed == false) return hiddenCarURI;
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }

    function mintCars(uint256 _quantity)
        public
        payable
        nonReentrant
        canMint(_quantity)
    {
        require(_quantity > 0, "Quantity Cannot be Zero");
        require(
            _quantity <= availableTokenCount(),
            "Quantity Exceeds Available Token Count"
        );

        uint pricePerMint = getPricePerMint();
        uint excess = msg.value - (pricePerMint * _quantity);

        if (publicMint == false)
            _decreaseMintableQuantity(msg.sender, _quantity);

        for (uint256 i = 1; i <= _quantity; i++) {
            uint256 id = nextToken();
            _safeMint(msg.sender, id);
        }

        emit UserMinted(msg.sender, pricePerMint, getCurrentList(), _quantity);

        if (excess > 0 && excess < msg.value)
            payable(msg.sender).transfer(excess);
    }

    function getIsMetaLocked() public view returns (bool isMetaLocked) {
        return _isMetaLocked;
    }

    function lockMetaData() public onlyOwner {
        _isMetaLocked = true;
    }

    function totalSupply()
        public
        view
        override(ERC721Enumerable, WithLimitedSupply)
        returns (uint256)
    {
        return _totalSupply;
    }

    function pauseMinting() external onlyOwner {
        _pauseMinting();
    }

    function unPauseMinting() external onlyOwner {
        _unPauseMinting();
    }

    function createAllowlists(
        string[] calldata listNames,
        uint[] calldata baseAllowed,
        uint[] calldata prices
    ) external onlyOwner {
        require(prices.length == baseAllowed.length, "Array Lengths Mismatch");
        require(prices.length == listNames.length, "Array Lengths Mismatch");

        for (uint i = 0; i < listNames.length; i++) {
            _createAllowlist(listNames[i], baseAllowed[i], prices[i]);
        }
    }

    function setCurrentList(uint listIndex) external onlyOwner {
        _setCurrentList(listIndex);
    }

    function setNextList() external onlyOwner {
        _setNextList();
    }

    function addToAllowlist(
        uint listIndex,
        address[] memory accounts,
        uint[] memory maxAllowed
    ) external onlyOwner {
        _addToAllowlist(listIndex, accounts, maxAllowed);
    }

    function removeFromAllowlist(uint listIndex, address account)
        external
        onlyOwner
    {
        _removeFromAllowlist(listIndex, account);
    }

    function setHiddenCarURI(string memory _hiddenCarURI) external onlyOwner {
        hiddenCarURI = _hiddenCarURI;
    }

    function setPublicMinting(bool newStatus) external onlyOwner {
        _setPublicMinting(newStatus);
    }

    function reveal() external onlyOwner {
        require(_isRevealed == false, "Already Revealed");
        _isRevealed = true;
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
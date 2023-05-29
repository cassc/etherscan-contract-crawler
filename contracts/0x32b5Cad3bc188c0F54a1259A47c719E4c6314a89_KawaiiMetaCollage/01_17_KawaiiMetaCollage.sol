// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

contract KawaiiMetaCollage is ERC721A, ERC2981 , Ownable, Pausable {
    using Strings for uint256;

    string public baseURI = "";
    uint256 public preCost = 0.03 ether;
    uint256 public publicCost = 0.04 ether;

    bool public presale = true;
    address public royaltyAddress;
    uint96 public royaltyFee = 500;

    uint256 constant public MAX_SUPPLY = 5555;
    uint256 constant public PUBLIC_MAX_PER_TX = 10;

    mapping(address => uint256) public whiteLists;


    constructor(
        string memory _name,
        string memory _symbol,
        address bulkTransferAddress
    ) ERC721A(_name, _symbol) {
        royaltyAddress = msg.sender;
        _setDefaultRoyalty(msg.sender, royaltyFee);
        _mintERC2309(bulkTransferAddress, 1155);
        for (uint256 i; i < 231; ++i) {
            _initializeOwnershipAt(i * 5);
        }
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // public mint
    function publicMint(uint256 _mintAmount) public payable whenNotPaused {
        uint256 cost = publicCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(!presale, "Presale is active.");
        require(
            _mintAmount <= PUBLIC_MAX_PER_TX,
            "Mint amount over"
        );

        _safeMint(msg.sender, _mintAmount);
    }

    function preMint(uint256 _mintAmount)
        public
        payable
        whenNotPaused
    {
        uint256 cost = preCost * _mintAmount;
        mintCheck(_mintAmount,  cost);
        require(presale, "Presale is not active.");
        require(
            whiteLists[msg.sender] >= _mintAmount,
            "You don't have WhiteList"
        );

        whiteLists[msg.sender] -= _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mintCheck(
        uint256 _mintAmount,
        uint256 cost
    ) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "MAXSUPPLY over"
        );
        require(msg.value >= cost, "Not enough funds");
    }

    function ownerMint(address _address, uint256 count) public onlyOwner {
       _safeMint(_address, count);
    }

    function setPresale(bool _state) public onlyOwner {
        presale = _state;
    }

    function setPreCost(uint256 _preCost) public onlyOwner {
        preCost = _preCost;
    }

    function setPublicCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function getCurrentCost() public view returns (uint256) {
        if (presale) {
            return preCost;
        } else {
            return publicCost;
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function pushMultiWL(address[] memory list, uint256[] memory maxMint) public virtual onlyOwner {
        for (uint256 i = 0; i < list.length; i++) {
            whiteLists[list[i]] = maxMint[i];
        }
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }


}
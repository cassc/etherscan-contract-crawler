// SPDX-License-Identifier: MIT

pragma solidity =0.8.16;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

/// @title Megafans ERC721A OG GamerGirlz Smart Contract
/// @author Colin Bracey
/// @notice Serves as a fungible token
/// @dev Inherits the ERC721A implentation

contract MegaNFT is Ownable, ERC721A {
    using Strings for uint256;

    //State Variables
    /// @notice Is contract paused?
    bool public contractPaused;
    /// @notice Base URI of all NFTs on the contract
    string public baseTokenURI;
    /// @notice Maximum supply of NFTs in the contract
    uint256 public maxSupply;
    /// @notice Price of each NFT
    uint256 public price;

    // Events
    event Withdraw(uint256 amount, address indexed addr);

    // Constructor
    /// @dev Initializes the contract
    constructor() ERC721A("MegaNFT", "MNFT") {
        maxSupply = 5555;
        price = 0.025 ether;
        baseTokenURI = "https://megafans.mypinata.cloud/ipfs/QmdHXv2U34HxKYL5V5N4SbP8y7Ze15ZReenWPAcSqmgZVi/";
    }

    // Modifiers
    /// @notice Modifier to check supply and price
    /// @param _num The number of NFTs to mint
    /// @param _checkPrice True or False to check the price
    /// @param _value Value in ETH passed
    modifier whenNotPausedAndValidSupply(
        uint256 _num,
        bool _checkPrice,
        uint256 _value
    ) {
        require(!contractPaused, "Sale Paused!");
        require(totalSupply() + _num <= maxSupply, "Max supply reached!");
        if (_checkPrice) {
            require(_value >= price * _num, "Not enough ETH sent, check price");
        }
        require(_num > 0, "Number of NFTs must be greater than zero");
        _;
    }

    // External Functtions

    /// @notice Mint an NFT to the owners wallet
    /// @param _num The number of NFTs to mint
    function mint(
        uint256 _num
    ) external payable whenNotPausedAndValidSupply(_num, true, msg.value) {
        _safeMint(msg.sender, _num);
    }

    /// @notice Mint an NFT to a specified wallet. This is used by WERT CC payment
    /// @param _to Address of wallet to mint the NFT to
    /// @param _num The number of NFTs to mint
    function mintTo(
        address _to,
        uint256 _num
    ) external payable whenNotPausedAndValidSupply(_num, true, msg.value) {
        _safeMint(_to, _num);
    }

    /// @notice Contract owner can NFTs to a specified wallet, non payable.
    /// @param _to Address of wallet to mint the NFT to
    /// @param _num The number of NFTs to mint
    function internalMint(
        address _to,
        uint256 _num
    ) external onlyOwner whenNotPausedAndValidSupply(_num, false, 0) {
        _safeMint(_to, _num);
    }

    /// @notice Change price of NFT - Testing purposes only, will be removed from production
    /// @param _price New NFT price
    function changePrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Price must be greater than zero");
        price = _price;
    }

    /// @notice Change price of Supply of NFTs - Testing purposes only, will be removed from production
    /// @param _maxSupply New NFT supply
    function changeMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply > 0, "Supply must be greater than zero");
        maxSupply = _maxSupply;
    }

    /// @notice Change the base URI of all NFTs on the contract
    /// @param _baseTokenURI New NFT base URI
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        require(bytes(_baseTokenURI).length > 0, "Base URI should not be empty");
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Allows contract owner to pause the contract
    function pauseContract() external onlyOwner {
        contractPaused = true;
    }

    /// @notice Allows contract owner to unpause the contract
    function unpauseContract() external onlyOwner {
        contractPaused = false;
    }

    /// @notice Allows owner to withdraw ETH balance
    function withdraw() external payable onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed.");

        emit Withdraw(amount, msg.sender);
    }

    /// @notice Returns the URI of the NFT
    /// @param _tokenId ID of the NFT
    /// @dev Returns the URI of the token
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

     // View Functions

    /// @notice Return the BaseURI of all NFTs on the contract
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Internal function to start ID from 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
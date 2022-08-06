// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";

/// @title to puff mwah is to blow an air kiss
/// @author Kfish n Chips
/// @notice ERC721A to Puff Mwah
/// @dev Claiming begins afte the contract owner allow minting,
/// Only be Upgradeable while there are tokens to mint
/// @custom:security-contact [email protected]
contract PuffMwah is Ownable, ERC2981, ERC721A {
    error ExceedsMaxMintAmount();
    error ExceedsMaxSupply();
    error IncorrectETHAmount();
    error MintingPaused();
    error NewValueMustBeGreaterThanPrevious();
    error MintAlreadyPaused();
    error MintAlreadyUnpaused();
    error OnlyEoA();
    error AmountWouldExceedReserve();
    /// @notice Max Supply
    /// @dev check on the modifier mintable
    uint256 public constant MAX_SUPPLY = 4999;
    /// @notice price for one NFT
    /// @dev check on the modifier mintable
    uint256 public constant PRICE = 0.01 ether;

    /// @notice Interfaces supported by this contract
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @notice The maximum number of tokens that an address can mint
    /// @dev check on the modifier mintable
    uint64 public maxMintsPerAddress = 3;

    /// @notice The supply available for owner mints
    /// @dev Does not remove publicly mintable supply
    uint256 public mintReserve = 30;

    /// @dev Base URI for computing {tokenURI}
    string public baseURI =
        "https://api.kfnc.net/puffmwah/metadata/";

    /// @dev Track whether minting is paused
    bool public mintPaused = false;

    /// @notice Contract URI with metadata
    string internal _contractURI =
        "ipfs://QmUaVYftzFp9TUj5GRVm1Hgd8Q1DFNGNCzU18iTo5G5aiu";

    /// @notice Checks that all conditions for mint are met
    /// @dev Check:
    ///     - amount allowed per address
    ///     - do not exceed the total supply
    ///     - that the correct funds were sent to mint
    ///     - that the mint is allowed
    ///@param amount  amount of NFTs to mint
    modifier mintable(uint64 amount) {
        if (msg.sender != tx.origin) revert OnlyEoA(); // solhint-disable-line
        if (_getAux(msg.sender) + amount > maxMintsPerAddress)
            revert ExceedsMaxMintAmount();
        if (_totalMinted() + amount > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (msg.value != amount * PRICE) revert IncorrectETHAmount();
        if (mintPaused) revert MintingPaused();
        _;
    }

    constructor() Ownable() ERC721A("puffmwah", "PUFFMWAH") {
        _setDefaultRoyalty(0x3d2ad929089B1656735c7fD9B771ac52248E05f9, 500);
        _mintERC2309(owner(), 1);
    }

    /// @notice Public mint
    /// @dev view {mintable} modifier for restrictions
    function mint(uint64 amount) external payable mintable(amount) {
        _setAux(msg.sender, _getAux(msg.sender) + amount);
        _mint(msg.sender, amount);
    }

    /// @notice Minting available for the owner
    /// @dev does not exclude supply from public mint
    function mintFromReserve(uint64 amount, address to) external onlyOwner {
        if (mintReserve < amount) revert AmountWouldExceedReserve();
        if (_totalMinted() + amount > MAX_SUPPLY) revert ExceedsMaxSupply();
        mintReserve -= amount;
        _mint(to, amount);
    }

    /// @notice Base URI setter used for tokenURI
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice Set the reserved mints for owner to a new value
    function setMintReserve(uint256 _mintReserve) external onlyOwner {
        mintReserve = _mintReserve;
    }

    /// @notice Max mints per address setter
    /// @param _maxMintsPerAddress The new value, can only be greater than previous value
    function setMaxMintsPerAddress(uint64 _maxMintsPerAddress)
        external
        onlyOwner
    {
        if (_maxMintsPerAddress < maxMintsPerAddress)
            revert NewValueMustBeGreaterThanPrevious();
        maxMintsPerAddress = _maxMintsPerAddress;
    }

    /// @notice Pause Mints
    function pauseMinting() external onlyOwner {
        if (mintPaused) revert MintAlreadyPaused();
        mintPaused = true;
    }

    /// @notice Unpause Mints
    function unpauseMinting() external onlyOwner {
        if (!mintPaused) revert MintAlreadyUnpaused();
        mintPaused = false;
    }

    /// @notice View how many mints an address has left
    function allowedMintAmount(address _addr) external view returns (uint64) {
        return maxMintsPerAddress - _getAux(_addr);
    }

    /// @notice URI to token metadata
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    /// @notice Override of supportsInterface function
    /// @param interfaceId the interfaceId
    /// @return bool if interfaceId is supported or not
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC165 ||
            interfaceId == _INTERFACE_ID_ERC721 ||
            interfaceId == _INTERFACE_ID_ERC721_METADATA ||
            interfaceId == _INTERFACE_ID_ERC2981;
    }

    /// @notice The starting token id
    /// @dev overrides ERC721A function
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice Withdrawal for Owner
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{ // solhint-disable-line
            value: address(this).balance
        }("");
        require(success, "Withdrawal failed");
    }
}
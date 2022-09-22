// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import '../../common/ERC2981/ERC2981.sol';

// Thanks to everyone that has contributed to the ERC721A repo
// A great resource for the whole community
contract ComicBook721 is ERC721AQueryable, ERC721ABurnable, Ownable, ERC2981 {
    using ECDSA for bytes32;

    address public _systemAddress;

    // 0 = closed
    // 1 = open
    uint256 public _mintStatus;

    mapping(address => uint256) public _totalMinted;

    uint256 public immutable MAX_LIMIT;

    string private _contractURI;
    string public _baseTokenURI;

    /** Events */
    event LogComicMinted(address indexed user, uint256 tokenIdStartIdx, uint256 amount);
    event LogSystemAddressSet(address systemAddress);
    event LogContractUriSet(string newUri);
    event LogBaseTokenUriSet(string newUri);
    event LogMintWindowSet(uint256 isOpen);

    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI,
        string memory baseURI,
        address systemAddress,
        uint256 maxLimit,
        uint256 reserved
    ) ERC721A(name, symbol) {
        _setSystemAddress(systemAddress);
        _contractURI = contractURI;
        _baseTokenURI = baseURI;
        MAX_LIMIT = maxLimit;

        // bulk mint the reserve comics
        if (reserved > 0) {
            _mintERC2309(msg.sender, reserved);
        }
    }

    /// @notice Check the open status of minting
    modifier open() {
        if (_mintStatus == 0) {
            revert('CB 100 - Minting not open');
        }
        _;
    }

    /// @notice This function mints the comics to the user
    /// @dev No payment is required; payable is added to reduce gas costs
    /// @param totalAllowance - Max number of comics user can mint in total
    /// @param amount - Number of comics to mint
    /// @param signature - Data signed by the backend to ensure minting comes from the desired location
    function mint(
        uint256 totalAllowance,
        uint256 amount,
        bytes calldata signature
    ) external open payable {
        uint256 newTotal;
        uint256 startIndex = _nextTokenId();

        unchecked {
            newTotal = _totalMinted[msg.sender] + amount;

            if (newTotal > totalAllowance) {
                revert('CB 101 - Invalid mint amount');
            }

            if (startIndex + amount > MAX_LIMIT) {
                revert('CB 102 - Exceeds population max');
            }
        }

        if (
            !_isValidSignature(
                keccak256(abi.encodePacked(msg.sender, totalAllowance, address(this))),
                signature
            )
        ) {
            revert('CB 103 - Invalid signature');
        }

        _mint(msg.sender, amount);

        _totalMinted[msg.sender] = newTotal;

        emit LogComicMinted(msg.sender, startIndex, amount);
    }

    /// @notice Verify hashed data
    /// @param hash - Hashed data bundle
    /// @param signature - Signature to check hash against
    /// @return bool - Is verified or not
    function _isValidSignature(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == _systemAddress;
    }

    /** GETTERS */

    /// @notice Returns storefront data
    /// @return string - Contract uri string
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Returns the base uri string - to the ERC721 contract
    /// @return string - Base uri string
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /** SETTERS */

    /// @notice Set the system address
    /// @param systemAddress - Address to set as systemAddress
    function setSystemAddress(address systemAddress) external onlyOwner {
        _setSystemAddress(systemAddress);
    }

    /// @notice Set the system address
    /// @param systemAddress - Address to set as systemAddress
    function _setSystemAddress(address systemAddress) internal {
        require(systemAddress != address(0), 'CB 104 - Invalid system address');
        _systemAddress = systemAddress;

        emit LogSystemAddressSet(systemAddress);
    }

    /// @notice Set the contract storefront URI
    /// @param newURI - The uri to be used
    function setContractURI(string memory newURI) external onlyOwner {
        _contractURI = newURI;

        emit LogContractUriSet(newURI);
    }

    /// @notice Set the contract base URI
    /// @param newURI - The uri to be used
    function setBaseURI(string memory newURI) external onlyOwner {
        _baseTokenURI = newURI;

        emit LogBaseTokenUriSet(newURI);
    }

    /// @notice Sets the mint window
    /// @param isOpen - 1 : window open, 0: closed
    function setMintWindow(uint256 isOpen) external onlyOwner {
        _mintStatus = isOpen;

        emit LogMintWindowSet(isOpen);
    }

    /// @notice Sets royalty values
    /// @param receiver - Address to set royalties to
    /// @param feeBasisPoints - Royalty as basis points
    function setDefaultRoyalty(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /// @notice Check interface support
    /// @param interfaceId - Interface identifier
    /// @return boolean - Is the interfaceId supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
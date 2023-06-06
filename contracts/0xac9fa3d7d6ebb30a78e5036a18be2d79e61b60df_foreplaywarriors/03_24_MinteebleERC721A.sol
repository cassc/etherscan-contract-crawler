// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: [email protected]
//
//  =============================================

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./MinteeblePartialERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IMinteebleERC721A is IMinteeblePartialERC721, IERC721A {
    function setWhitelistMaxMintAmountPerTrx(uint256 _maxAmount) external;

    function setWhitelistMaxMintAmountPerAddress(uint256 _maxAmount) external;

    function setWhitelistMintEnabled(bool _state) external;

    function setMerkleRoot(bytes32 _merkleRoot) external;

    function whitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) external;

    function mint(uint256 _mintAmount) external payable;

    function mintForAddress(
        address receiver,
        uint256 _mintAmount
    ) external payable;

    function ownerMintForAddress(
        uint256 _mintAmount,
        address _receiver
    ) external;

    function walletOfOwner(
        address _owner
    ) external view returns (uint256[] memory);
}

contract MinteebleERC721A is MinteeblePartialERC721, ERC721A, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes4 public constant IMINTEEBLE_ERC721A_INTERFACE_ID =
        type(IMinteebleERC721A).interfaceId;
    bool public whitelistMintEnabled = false;
    bytes32 public merkleRoot;

    uint256 public maxWhitelistMintAmountPerTrx = 1;
    uint256 public maxWhitelistMintAmountPerAddress = 1;
    mapping(address => uint256) public totalWhitelistMintedByAddress;

    /**
     *  @notice MinteebleERC721 constructor
     *  @param _tokenName Token name
     *  @param _tokenName Token symbol
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) ERC721A(_tokenName, _tokenSymbol) {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
    }

    /**
     *  @dev Checks if caller can mint
     */
    modifier canMint(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceed!");
        require(
            _mintAmount <= maxMintAmountPerTrx,
            "Exceeded maximum total amount per trx!"
        );
        require(
            totalMintedByAddress[msg.sender] + _mintAmount <=
                maxMintAmountPerAddress,
            "Exceeded maximum total amount per address!"
        );
        _;
    }

    /**
     *  @dev Checks if caller can mint
     */
    modifier canWhitelistMint(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceed!");
        require(
            _mintAmount <= maxWhitelistMintAmountPerTrx,
            "Exceeded maximum total amount per trx!"
        );
        require(
            totalWhitelistMintedByAddress[msg.sender] + _mintAmount <=
                maxWhitelistMintAmountPerAddress,
            "Exceeded maximum total amount per address!"
        );
        _;
    }

    /**
     *  @notice Allows owner to set the max number of mintable items in a single transaction
     *  @param _maxAmount Max amount
     */
    function setWhitelistMaxMintAmountPerTrx(
        uint256 _maxAmount
    ) public onlyOwner {
        maxWhitelistMintAmountPerTrx = _maxAmount;
    }

    /**
     *  @notice Allows owner to set the max number of mintable items per account
     *  @param _maxAmount Max amount
     */
    function setWhitelistMaxMintAmountPerAddress(
        uint256 _maxAmount
    ) public onlyOwner {
        maxWhitelistMintAmountPerAddress = _maxAmount;
    }

    /**
     *  @inheritdoc ERC721A
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     *  @inheritdoc ERC721A
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     *  @inheritdoc ERC721A
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token ID do es not exist.");

        // Checks if collection is revealed
        if (!revealed) return preRevealUri;

        // Evaluating full URI for the specified ID
        return string.concat(_baseURI(), _tokenId.toString(), uriSuffix);
    }

    function whitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    )
        public
        payable
        virtual
        canWhitelistMint(_mintAmount)
        enoughFunds(_mintAmount)
    {
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        _safeMint(_msgSender(), _mintAmount);
        totalMintedByAddress[_msgSender()] += _mintAmount;
        totalWhitelistMintedByAddress[_msgSender()] += _mintAmount;
    }

    /**
     *  @notice Mints one or more items
     */
    function mint(
        uint256 _mintAmount
    )
        public
        payable
        virtual
        canMint(_mintAmount)
        enoughFunds(_mintAmount)
        active
        nonReentrant
    {
        _safeMint(_msgSender(), _mintAmount);
        totalMintedByAddress[_msgSender()] += _mintAmount;
    }

    function mintForAddress(
        address receiver,
        uint256 _mintAmount
    ) public payable enoughFunds(_mintAmount) active {
        require(
            _mintAmount <= maxMintAmountPerTrx,
            "Exceeded maximum total amount per trx!"
        );
        require(
            totalMintedByAddress[receiver] + _mintAmount <=
                maxMintAmountPerAddress,
            "Exceeded maximum total amount!"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            totalMintedByAddress[receiver]++;
        }

        _safeMint(receiver, _mintAmount);
    }

    /**
     * @notice Mints item for another address. (Reserved to contract owner)
     */
    function ownerMintForAddress(
        uint256 _mintAmount,
        address _receiver
    ) public virtual onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceed!");
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            TokenOwnership memory ownership = _ownershipOf(currentTokenId);

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IMinteebleERC721A).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
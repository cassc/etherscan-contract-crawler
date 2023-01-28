//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SargeExtension.sol";
import "./errors/SargeNFTErrors.sol";

contract Sarge is SargeExtensions {
    struct Collection {
        uint32 maxWalletMint;
        uint32 maxWhitelistMint;
        uint32 teamAllocation;
        uint32 maxSupply;
        uint32 publicSaleStartTime;
        uint32 publicSaleEndTime;
        uint32 whitelistStartTime;
        uint32 whitelistEndTime;
        uint128 publicPrice;
        uint128 whitelistPrice;
        bytes32 whitelistMerkleRoot;
    }

    struct UserData {
        uint16 publicMinted;
        uint16 mintedWhitelist;
    }

    Collection public collection;
    mapping(address => UserData) public userData;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        string memory _uriExtension,
        address _owner,
        Collection memory _collection
    ) SargeExtensions(_name, _symbol, _uri, _uriExtension) {
        _transferOwnership(_owner);
        _setDefaultRoyalty(owner(), 1000);
        collection = _collection;
        if (collection.teamAllocation > 0) {
            _mint(owner(), collection.teamAllocation);
        }
    }

    modifier checkMint(uint16 amount, bool isWhitelist) {
        if (collection.maxSupply < totalSupply() + amount) {
            revert ExceedsCollectionMaxSupply(
                collection.maxSupply - totalSupply(),
                amount
            );
        }

        if (msg.sender != owner()) {
            if (isWhitelist) {
                if (collection.whitelistMerkleRoot == bytes32(0)) {
                    revert WhitelistMerkleRootNotSet();
                }
                if (block.timestamp < collection.whitelistStartTime) {
                    revert WhitelistNotStarted(collection.whitelistStartTime);
                }

                if (block.timestamp > collection.whitelistEndTime) {
                    revert WhitelistEnded(collection.whitelistEndTime);
                }

                if (
                    userData[msg.sender].mintedWhitelist + amount >
                    collection.maxWhitelistMint
                ) {
                    revert ExceedsMaxWhitelistMint(
                        collection.maxWhitelistMint,
                        amount,
                        userData[msg.sender].mintedWhitelist
                    );
                }

                if (msg.value != collection.whitelistPrice * amount) {
                    revert IncorrectPaymentAmount(
                        collection.whitelistPrice * amount,
                        msg.value
                    );
                }

                userData[msg.sender].mintedWhitelist += amount;
            } else {
                if (
                    userData[msg.sender].publicMinted + amount >
                    collection.maxWalletMint
                ) {
                    revert ExceedsMaxWalletMint(
                        collection.maxWalletMint,
                        amount,
                        userData[msg.sender].publicMinted
                    );
                }

                if (block.timestamp < collection.publicSaleStartTime) {
                    revert PublicSaleNotStarted(collection.publicSaleStartTime);
                }

                if (block.timestamp > collection.publicSaleEndTime) {
                    revert PublicSaleEnded(collection.publicSaleEndTime);
                }

                if (msg.value != collection.publicPrice * amount) {
                    revert IncorrectPaymentAmount(
                        collection.publicPrice * amount,
                        msg.value
                    );
                }
                userData[msg.sender].publicMinted += amount;
            }
        }

        _;
    }

    modifier onlyWhitelisted(bytes32[] memory proof) {
        if (!_isWhitelisted(msg.sender, proof)) {
            revert NotWhitelisted();
        }
        _;
    }

    function _isWhitelisted(
        address user,
        bytes32[] memory proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, collection.whitelistMerkleRoot, leaf);
    }

    function mintWhitelist(
        uint16 quantity,
        bytes32[] memory merkleProof
    )
        external
        payable
        onlyWhitelisted(merkleProof)
        checkMint(quantity, true)
        whenNotPaused
    {
        _safeMint(msg.sender, quantity);
    }

    function mint(
        uint16 quantity
    ) external payable checkMint(quantity, false) whenNotPaused {
        _safeMint(msg.sender, quantity);
    }

    function mintAdmin(
        address to,
        uint16 quantity
    ) external payable checkMint(quantity, false) onlyOwner {
        _safeMint(to, quantity);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        collection.whitelistMerkleRoot = _merkleRoot;
    }

    function setMintPrices(
        uint128 _price,
        uint128 _whitelistPrice
    ) external onlyOwner {
        collection.publicPrice = _price;
        collection.whitelistPrice = _whitelistPrice;
    }

    function setPublicMintTimes(
        uint32 _publicSaleStartTime,
        uint32 _publicSaleEndTime
    ) external onlyOwner {
        collection.publicSaleStartTime = _publicSaleStartTime;
        collection.publicSaleEndTime = _publicSaleEndTime;
    }

    function setMaxWalletPublicMint(uint16 _maxWalletMint) external onlyOwner {
        collection.maxWalletMint = _maxWalletMint;
    }

    function setMaxWhitelistWalletMint(
        uint16 _maxWhitelistMint
    ) external onlyOwner {
        collection.maxWhitelistMint = _maxWhitelistMint;
    }

    function setWhitelistMintTimes(
        uint32 _whitelistStartTime,
        uint32 _whitelistEndTime
    ) external onlyOwner {
        collection.whitelistStartTime = _whitelistStartTime;
        collection.whitelistEndTime = _whitelistEndTime;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function sendUnmintedToAdmin() external onlyOwner {
        _sendUnmintedToAdmin();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawAmount(uint256 amount) external onlyOwner {
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawStuckTokens(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(owner(), balance);
        require(success, "Transfer failed.");
    }

    function _sendUnmintedToAdmin() internal {
        uint256 unminted = collection.maxSupply - totalSupply();
        if (unminted > 0) {
            _safeMint(owner(), unminted);
        }
    }

    function getCollectionData() external view returns (Collection memory) {
        return collection;
    }

    function getUserData(
        address user
    ) external view returns (uint256 publicMinted, uint256 whitelistMinted) {
        return (userData[user].publicMinted, userData[user].mintedWhitelist);
    }
}
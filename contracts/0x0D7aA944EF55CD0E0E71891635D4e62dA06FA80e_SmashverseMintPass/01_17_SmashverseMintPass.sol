// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Custom.sol";
import "./NonblockingReceiverCollectableBox.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SmashverseMintPass is ERC721Custom, Ownable, NonblockingReceiverCollectableBox {
    using ECDSA for bytes32;

    string private _baseURIString;
    uint256 public transferDeadline;
    uint16 public royaltyPerTenThousand;
    address public nftContractAddress;
    address public royaltyReceiver;
    address public unclaimedBoxReceiver;

    mapping(uint256 => bool) public claimed;

    error BoxAlreadyClaimed();
    error InvalidSignature();
    error CallerNotNFTContract();
    error NFTContractAlreadySet();
    error BoxDoesNotExist();
    error InvalidSequence();
    error DeadlineNotPassed();
    error TimestampLessThanDeadline();

    event DeadlineExtended(uint256 deadline);

    constructor(
        string memory name_,
        string memory symbol_,
        uint16 sourceChainId_,
        address collectorContractAddress_,
        address lzEndpoint_,
        uint256 transferDeadline_
    ) ERC721Custom(name_, symbol_) {
        _lzEndpoint = ILayerZeroEndpoint(lzEndpoint_);
        sourceChainId = sourceChainId_;
        collectorContractAddress = abi.encodePacked(collectorContractAddress_);
        transferDeadline = transferDeadline_;
        unclaimedBoxReceiver = msg.sender;
    }

    modifier onlyNFTContract() {
        if (msg.sender != nftContractAddress) revert CallerNotNFTContract();
        _;
    }

    modifier onlyAfterDeadline() {
        if (block.timestamp <= transferDeadline) revert DeadlineNotPassed();
        _;
    }

    function setNFTContractAddress(address nftContractAddress_) public onlyOwner {
        if (nftContractAddress != address(0)) revert NFTContractAlreadySet();
        nftContractAddress = nftContractAddress_;
    }

    function _lzReceive(bytes memory payload_) internal virtual override {
        (address owner, uint256[] memory tokenIds) = abi.decode(payload_, (address, uint256[]));
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (tokenId >= 750) revert BoxDoesNotExist();
            if (claimed[tokenId]) revert BoxAlreadyClaimed();
            claimed[tokenId] = true;
            _safeMint(owner, tokenId);
        }
    }

    function burn(uint256 tokenId_) public onlyNFTContract {
        _burn(tokenId_);
    }

    function royaltyInfo(uint256 tokenId_, uint256 salePrice_)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!_exists(tokenId_)) revert QueryForNonexistentToken();
        receiver = royaltyReceiver;
        royaltyAmount = (salePrice_ * royaltyPerTenThousand) / 10000;
    }

    function setRoyaltyInfo(address receiver_, uint16 perTenThousand_) public onlyOwner {
        royaltyReceiver = receiver_;
        royaltyPerTenThousand = perTenThousand_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIString;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseURIString = baseURI_;
    }

    function mintUnclaimedBoxes(uint256[] calldata tokenIds_) public onlyOwner onlyAfterDeadline {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            if (tokenId >= 750 || (i != 0 && tokenIds_[i - 1] >= tokenId)) revert InvalidSequence();
            if (claimed[tokenId]) revert BoxAlreadyClaimed();
        }
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            claimed[tokenId] = true;
            _safeMint(unclaimedBoxReceiver, tokenId);
        }
    }

    function extendDeadline(uint256 transferDeadline_) public onlyOwner {
        if (transferDeadline > transferDeadline_) revert TimestampLessThanDeadline();
        transferDeadline = transferDeadline_;
        emit DeadlineExtended(transferDeadline_);
    }

    function setUnclaimedBoxReceiver(address unclaimedBoxReceiver_) public onlyOwner {
        unclaimedBoxReceiver = unclaimedBoxReceiver_;
    }
}
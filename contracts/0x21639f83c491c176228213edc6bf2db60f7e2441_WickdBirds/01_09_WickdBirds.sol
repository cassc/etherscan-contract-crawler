// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IMetadata.sol";

//  @title:   WickdBirds
//  @dev:     animahq.com

//                                            %%%%%%%
//                                     %%%%%%%%%%%%
//                            %%%%%%%%%%%%%%%%%     %%%%%
//       /%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#    %%%%%%%%%%%%%
//   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//     #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//              %%%%%%%%%%%%%%%%%%%%%%%%%%%      %%%%%%%
//      %%%%%%  %%%%                             %%%%%%
//      %%%%%%%    %%                           %%%%%%%
//       %%%%%%       %%%%%%            %%%%%   %%%%%%%
//       (%%%%%     %%%%%%%%%          %%%%%%%% %%%%%%
//        %%%%%%  %%%%%%%%%%%%       .%%%%%%%%%%%%%%%%
//        %%%%%%%%%%%%%%%%%%%%%     %%%%%%%%%%%%%%%%%%
//        %%%%%%%%%%%%% %%%%%%%%   %%%%%%%# %%%%%%%%%%
//      % %%%%%%%%%%     %%%%%%%% %%%%%%%%   %%%%%%%%
//        %%%%%%%%        %%%%%%%%%%%%%%%      %%%%%%
//        %%%%%%           %%%%%%%%%%%%%        %%%%%
//        %%%%              %%%%%%%%%%%          % %#
//                           %%%%%%%%%           % %%
//                            %%%%%%%              %%
//                             %%%%%                %

contract WickdBirds is ERC721A, Ownable, ReentrancyGuard, IERC2981 {
    // xxxxxxxxx Errors xxxxxxxxx

    error SoldOut();
    error SaleInactive();
    error MintAllowanceSurpassed();
    error TransferPaused();
    error TransferControlRevoked();

    // xxxxxxxxx Metadata xxxxxxxxx

    string public baseTokenURI;
    address public metadataAddress;

    // xxxxxxxxx Sale Status xxxxxxxxx

    uint256 public maxSupply = 10000;
    uint256 public maxPerTransaction = 3;
    bool public isSaleActive = false;

    // xxxxxxxxx Transfer Status xxxxxxxxx
    
    bool public isTransferPaused = false;
    bool public isTransferControlRevoked = false;

    // xxxxxxxxx Royalties xxxxxxxxx

    address public royaltyAddress;
    uint256 public royaltyPercent = 0;

    // xxxxxxxxx Constructors xxxxxxxxx

    constructor(string memory _baseTokenURI)
        ERC721A("WickdBirds", "WICKDBIRD")
    {
        baseTokenURI = _baseTokenURI;
        royaltyAddress = msg.sender;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // xxxxxxxxx Mint xxxxxxxxx

    function mint(uint256 _amount) external nonReentrant {
        if (!isSaleActive) revert SaleInactive();
        if (totalSupply() + _amount > maxSupply) revert SoldOut();
        if (_amount > maxPerTransaction) revert MintAllowanceSurpassed();

        _safeMint(msg.sender, _amount);
    }

    function mintTeam(address _to, uint256 _amount) external onlyOwner {
        _safeMint(_to, _amount);
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction)
        external
        onlyOwner
    {
        maxPerTransaction = _maxPerTransaction;
    }

    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    // xxxxxxxxx Metadata xxxxxxxxx

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (address(metadataAddress) != address(0)) {
            if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
            return IMetadata(metadataAddress).tokenURI(_tokenId);
        }
        return super.tokenURI(_tokenId);
    }

    function setMetadataAddress(address _metadataAddress) external onlyOwner {
        metadataAddress = _metadataAddress;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // xxxxxxxxx Transfer Control xxxxxxxxx

    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        if (isTransferPaused) revert TransferPaused();
    }

    function toggleTransfer() external onlyOwner {
        if (isTransferControlRevoked) revert TransferControlRevoked();
        isTransferPaused = !isTransferPaused;
    }

    function revokeTransferControl() external onlyOwner {
        isTransferPaused = false;
        isTransferControlRevoked = true;
    }

    // xxxxxxxxx Misc xxxxxxxxx

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return (royaltyAddress, (salePrice * royaltyPercent) / 100);
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setRoyaltyPercent(uint256 _royaltyPercent) external onlyOwner {
        royaltyPercent = _royaltyPercent;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }
}
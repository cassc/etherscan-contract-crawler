// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {NativeMetaTransaction} from "../../common/NativeMetaTransaction.sol";
import {IMintableERC721} from "../../common/IMintableERC721.sol";
import {ContextMixin} from "../../common/ContextMixin.sol";
import {IAvatarMinter} from "../IAvatarMinter.sol";
import {ERC165Storage} from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import {Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract RootAvatar is
    AccessControl,
    NativeMetaTransaction,
    IMintableERC721,
    ERC721URIStorage,
    Ownable,
    ContextMixin,
    IERC2981,
    ERC165Storage,
    Pausable
{
    uint256 private startDate;
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    string public baseURI;

    IAvatarMinter public avatarMinter;
    address public auctionAddress;   

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 private _royaltyPercentage;
    address private _royaltyAddress;

    event AvatarPaused(address owner);
    event AvatarUnpaused(address owner);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory url_
    ) ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _senderAddr());
        _setupRole(PREDICATE_ROLE, _senderAddr());
        _initializeEIP712(name_);
        
        //implemented royalty based on this guidance https://eips.ethereum.org/EIPS/eip-2981
        _registerInterface(_INTERFACE_ID_ERC2981);

        baseURI = url_;
        startDate = block.timestamp;
    }

    function setAvatarMinter(address _minterAddress) external whenNotPaused onlyOwner {
        avatarMinter = IAvatarMinter(_minterAddress);
         _setupRole(PREDICATE_ROLE, _minterAddress);
    }

    function setAuctionAddress(address _auctionAddress) external whenNotPaused onlyOwner {
        auctionAddress = _auctionAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IMintableERC721-mint}.
     */
    function mint(address user, uint256 tokenId)
        external
        override
        onlyRole(PREDICATE_ROLE)
        whenNotPaused
    {
        _mint(user, tokenId);
    }

    /**
     * If you're attempting to bring metadata associated with token
     * from L2 to L1, you must implement this method, to be invoked
     * when minting token back on L1, during exit
     */
    function setTokenMetadata(uint256 tokenId, bytes memory data)
        internal
        virtual
        whenNotPaused
    {
        // This function should decode metadata obtained from L2
        // and attempt to set it for this `tokenId`
        //
        // Following is just a default implementation, feel
        // free to define your own encoding/ decoding scheme
        // for L2 -> L1 token metadata transfer
        string memory uri = abi.decode(data, (string));

        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev See {IMintableERC721-mint}.
     *
     * If you're attempting to bring metadata associated with token
     * from L2 to L1, you must implement this method
     */
    function mint(
        address user,
        uint256 tokenId,
        bytes calldata metaData
    ) external override 
    onlyRole(PREDICATE_ROLE)
    whenNotPaused
     {
        _mint(user, tokenId);
        setTokenMetadata(tokenId, metaData);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, ERC165Storage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IMintableERC721-exists}.
     */
    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    function _senderAddr() internal view returns (address payable sender) {
        return ContextMixin.msgSender();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) 
    internal 
    virtual override 
    whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != auctionAddress && from != address(0)) 
        {
            require(block.timestamp > (startDate + 14 days), "RootAvatar: Locked until January 25th");
        }
    }

    /// @dev sets royalties info
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view override
        whenNotPaused
        returns (address receiver, uint256 royaltyAmount)
    {        
        receiver = _royaltyAddress;
        royaltyAmount = (salePrice * _royaltyPercentage) / 100;
    }

    /// @dev sets royalties address
    function setRoyaltyAddress(address royaltyAddress) public whenNotPaused onlyOwner {
        _royaltyAddress = royaltyAddress;
    }

    /// @dev sets royalties fees
    function setRoyaltyPercentage(uint256 royaltyPercentage)  public whenNotPaused onlyOwner {
        _royaltyPercentage = royaltyPercentage;
    }

    /// @dev pausing the contract
    function pause() public onlyOwner 
    {
        super._pause();
        emit AvatarPaused(msgSender());
    }

    /// @dev unpause the contract
    function unpause() public onlyOwner 
    {
        super._unpause();
        emit AvatarUnpaused(msgSender());
    }

}
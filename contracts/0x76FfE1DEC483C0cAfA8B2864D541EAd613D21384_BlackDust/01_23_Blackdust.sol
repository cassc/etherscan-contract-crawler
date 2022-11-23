// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./lib/ERC721LockableUpgradeable.sol";
import "./lib/OnlyDevMultiSigUpgradeable.sol";

contract BlackDust is
    OwnableUpgradeable,
    OnlyDevMultiSigUpgradeable,
    ERC721LockableUpgradeable,
    ERC2981Upgradeable
{
    using StringsUpgradeable for uint256;

    address private _devMultiSigWallet;
    string private baseURI;

    mapping(address => bool) public minters;

    event NFTMinted(address _owner, uint256 startTokenId);
    event NFTMintedMany(
        address _owner,
        uint256 amount,
        uint256[] startTokenIds
    );

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory initBaseURI_,
        address devMultiSigWallet_,
        uint96 royalty_
    ) public initializer {
        __OnlyDevMultiSig_init(devMultiSigWallet_);
        __ERC721Lockable_init(name_, symbol_, _msgSender(), 10000);
        __Ownable_init();

        _devMultiSigWallet = devMultiSigWallet_;
        setBaseURI(initBaseURI_);
        _setDefaultRoyalty(devMultiSigWallet_, royalty_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721LockableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "NOT_EXISTS");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /* 
        BACK OFFICE
    */
    function setDevMultiSigAddress(address payable _address)
        external
        onlyDevMultiSig
    {
        _devMultiSigWallet = _address;
        updateDevMultiSigWallet(_address);
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyDevMultiSig
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function withdrawTokensToDev(IERC20Upgradeable token)
        public
        onlyDevMultiSig
    {
        uint256 funds = token.balanceOf(address(this));
        require(funds > 0, "No token left");
        token.transfer(address(_devMultiSigWallet), funds);
    }

    function withdrawETHBalanceToDev() public onlyDevMultiSig {
        require(address(this).balance > 0, "No ETH left");

        (bool success, ) = address(_devMultiSigWallet).call{
            value: address(this).balance
        }("");

        require(success, "Transfer failed.");
    }

    modifier onlyMinter() {
        require(minters[_msgSender()]);
        _;
    }

    function awaken(address to, uint256 tokenId)
        external
        onlyMinter
        returns (uint256)
    {
        _mint(to, tokenId);
        emit NFTMinted(to, tokenId);
        return tokenId;
    }

    function awaken(address to, uint256[] memory tokenIds)
        external
        onlyMinter
        returns (uint256[] memory)
    {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            _mint(to, tokenIds[i]);
        }

        emit NFTMintedMany(to, n, tokenIds);

        return tokenIds;
    }

    /// Owner Functions ///

    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }
}
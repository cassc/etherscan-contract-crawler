// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./libs/interfaces/IERC1155Proxy.sol";
import "./libs/Initialize.sol";
import "./libs/ERC721AManagerMint.sol";
import "./libs/MultiMint.sol";
import "./libs/MerkleProof.sol";
import "./libs/Collection.sol";
import "./libs/ShareProxy.sol";
import "./libs/Signature.sol";

// @author: miinded.com

contract ChainZokuManager is ERC721AManagerMint, Initialize, MultiMint, Collection, Signature, MerkleProofVerify, ShareProxy {
    using BitMaps for BitMaps.BitMap;

    uint256 public MINT_PASS_LIMIT = 2;
    uint256 public MINT_PASS_ID = 25;

    BitMaps.BitMap private internalIdFlagged;

    event FlagItems(uint256[] internalIds, uint8 action, uint256 zokuTokenId);
    event ChooseYourClan(uint256 startTokenId, uint256[] clans);

    constructor(){
        _setReserve(158);
        _setMaxSupply(7878);

        Mint memory phase1 = Mint(1685541600, 1685628000, 7878, 7878, 0.087 ether, false, true);

        setMint("MINT_PASS", Mint(phase1.start, phase1.end, 0, phase1.maxPerTx, phase1.price, phase1.paused, phase1.valid));
        setMint("BOXES", phase1);
        setMint("WHITELIST", phase1);
    }

    function init(address _zokuByChainZoku, address _zokuHome, address _shareContract, address _signAddress, address _multiSigContract) public onlyOwner isNotInitialized {
        ERC721AManager._setERC721Address(_zokuByChainZoku);
        ShareProxy._setShareContract(_shareContract);
        Collection._setCollection(_zokuHome);
        MultiSigProxy._setMultiSigContract(_multiSigContract);

        Signature.setSignAddress(_signAddress);
        Signature.setHashSign(224876);
    }

    function HolderMintPass(uint256 _zokuCount, uint256[] memory _clans, uint256 _burnCount, uint256[] memory _internalIds, bytes memory _signature)
    public payable notSoldOut(_zokuCount) canMint("MINT_PASS", _zokuCount)
    signedNotUnique(_useMintPassValid(_burnCount, _internalIds), _signature) nonReentrant {

        require(_clans.length == 2, "ChainZokuManager: bad clans length");
        uint256 checkCount = 0;
        for (uint256 i = 0; i < _clans.length; i++) {
            checkCount += _clans[i];
        }
        require(checkCount == _zokuCount, "ChainZokuManager: bad clans value");

        for (uint256 i = 0; i < _internalIds.length; i++) {
            _flagInternalId(_internalIds[i]);
        }

        uint256 mintPassCount = (_zokuCount / MINT_PASS_LIMIT) + (_zokuCount % MINT_PASS_LIMIT > 0 ? 1 : 0);

        require(mintPassCount == _internalIds.length, "ChainZokuManager: bad internalIds length");

        uint256 balanceMintPass = IERC1155Proxy(Collection.collectionAddress).balanceOf(_msgSender(), MINT_PASS_ID);
        uint256 mintPassBurned = mintPassCount > balanceMintPass ? balanceMintPass : mintPassCount;

        require(_burnCount == mintPassBurned, "ChainZokuManager: bad _burnCount value");

        if(mintPassBurned > 0){
            IERC1155Proxy(Collection.collectionAddress).burn(_msgSender(), MINT_PASS_ID, mintPassBurned);
        }

        emit ChooseYourClan(_totalMinted() + 1, _clans);
        emit FlagItems(_internalIds, 2, 0);

        ERC721AManager._mint(_msgSender(), _zokuCount);
    }

    function HolderGimmeTheLoot(bytes32[] memory _proof, uint256 _count, uint256 _max)
    public payable notSoldOut(_count) canMint("BOXES", _count)
    merkleVerify(_proof, _merkleLeaf(_msgSender(), "BOXES", _max)) nonReentrant {
        require(mintBalance("BOXES", _msgSender()) <= _max, "ChainZokuManager: Boxes Max minted");

        ERC721AManager._mint(_msgSender(), _count);
    }

    function WhitelistGuaranteed(bytes32[] memory _proof, uint256 _count, uint256 _max)
    public payable notSoldOut(_count) canMint("WHITELIST", _count)
    merkleVerify(_proof, _merkleLeaf(_msgSender(), "WHITELIST", _max)) nonReentrant {
        require(mintBalance("WHITELIST", _msgSender()) <= _max, "ChainZokuManager: WL Max minted");

        ERC721AManager._mint(_msgSender(), _count);
    }

    function setMintPassData(uint256 _mintPassLimit, uint256 _mintPassId) public onlyOwnerOrAdmins {
        MINT_PASS_LIMIT = _mintPassLimit;
        MINT_PASS_ID = _mintPassId;
    }

    function _merkleLeaf(address _wallet, string memory _mintName, uint256 _max) private pure returns (bytes32){
        return keccak256(abi.encodePacked(_wallet, _mintName, _max));
    }

    function _flagInternalId(uint256 _internalId) internal {
        require(internalIdFlagged.get(_internalId) == false, "ChainZokuManager: internalId already flag");
        internalIdFlagged.set(_internalId);
    }
    function _useMintPassValid(uint256 _burnCount, uint256[] memory _internalId) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_msgSender(), _burnCount, _internalId, HASH_SIGN));
    }
}
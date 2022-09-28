// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IWithBalance.sol";
import "./INFTFactory.sol";
import "./INFTRepresentation.sol";
import "./NFT.sol";
import "./NFTRepresentation.sol";

contract NFTFactory is Ownable, INFTFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    NFT public immutable nftImplementation;

    IWithBalance public requiredTokenToMint;
    uint public requiredTokenToMintAmount;

    INFTRepresentation public override nftRepresentation;

    mapping (address => EnumerableSet.AddressSet) private userNftContractsInternal;

    event NftRepresentationChanged(INFTRepresentation _old, INFTRepresentation _new);

    constructor(
        IWithBalance _requiredTokenToMint, uint _requiredTokenToMintAmount
    ) {
        requiredTokenToMint = _requiredTokenToMint;
        requiredTokenToMintAmount = _requiredTokenToMintAmount;

        nftImplementation = new NFT(this);
        // not necessary, but to avoid initialization with bad names by 3d party
        nftImplementation.initialize(address(this), "Template", "Template");

        nftRepresentation = new NFTRepresentation();
    }

    function deploy(
        string memory _projectName,
        string memory _projectSymbol
    ) public returns (address) {
        address token = Clones.clone(address(nftImplementation));
        NFT(token).initialize(
            msg.sender,
            _projectName,
            _projectSymbol
        );

        require(userNftContractsInternal[msg.sender].add(token), 'NFTFactory: BROKEN_STRUCTURE');
        emit NFTContractCreated(token, msg.sender);
        return token;
    }

    function setRequiredTokenToMint(IWithBalance _token, uint _amount) public onlyOwner {
        requiredTokenToMint = _token;
        requiredTokenToMintAmount = _amount;

        emit RequiredTokenToMintChanged(address(_token), _amount);
    }

    function setNftRepresentation(INFTRepresentation _nftRepresentation) public onlyOwner {
        INFTRepresentation old = nftRepresentation;
        nftRepresentation = _nftRepresentation;

        emit NftRepresentationChanged(old, _nftRepresentation);
    }

    function trackNftContractOwners(address _oldOwner, address _newOwner) external override {
        require(_newOwner != address(0), 'NFTFactory: ZERO_ADDRESS');
        require(_newOwner != _oldOwner, 'NFTFactory: BROKEN_LOGIC');

        // initially deployed nft contract is adding to owner, so, if msg.sender is exist in some list then msg.sender is deployed nft contract
        // this check is included below (in remove), but here we want separate error msg
        require(userNftContractsInternal[_oldOwner].contains(msg.sender), 'NFTFactory: AUTH_FAILED');

        require(userNftContractsInternal[_oldOwner].remove(msg.sender), 'NFTFactory: BROKEN_STRUCTURE');
        require(userNftContractsInternal[_newOwner].add(msg.sender), 'NFTFactory: BROKEN_STRUCTURE');

        emit NFTContractOwnerChanged(msg.sender, _oldOwner, _newOwner);
    }

    function userNftContracts(address _user) public view returns (address[] memory) {
        return userNftContractsInternal[_user].values();
    }

    function userNftContractsCount(address _user) public view returns (uint) {
        return userNftContractsInternal[_user].length();
    }

    function userNftContract(address _user, uint _index) public view returns (address) {
        return userNftContractsInternal[_user].at(_index);
    }

    function trackTokenTransfer(address _ownersAddress, address _from, address _to, uint _tokenId) external override {
        // initially deployed nft contract is adding to owner, so, if msg.sender is exist in some list then msg.sender is deployed nft contract
        require(userNftContractsInternal[_ownersAddress].contains(msg.sender), 'NFTFactory: AUTH_FAILED');

        emit NFTTransferred(msg.sender, _from, _to, _tokenId);
    }
}
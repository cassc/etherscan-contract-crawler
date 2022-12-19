//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./../permission/ContractPrizeRestricted.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../interfaces/IPartitionsAndMetaStore.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// TODO: remove
import "hardhat/console.sol";

contract PartitionsAndMetaStore is ContractPrizeRestricted, IPartitionsAndMetaStore {
    using Counters for Counters.Counter;
    using Strings for string;
    using ECDSA for bytes32;

    IERC721Enumerable public immutable nft;

    mapping(uint64 => string) private revealedBaseURIs;
    mapping(uint256 => string) private winBaseUriPrizes;
    mapping(uint256 => PrizeState[]) private prizes;

    uint256[] private closedPartitions;

    uint256[] private revealedPartitions;

    mapping(uint256 => bool) activatedPartitions;

    string private downSideBaseUri;

    constructor(address accessContract, address accessPrizeContract, string memory _downSideBaseUri) ContractPrizeRestricted(accessContract, accessPrizeContract) {
        nft = IERC721Enumerable(accessContract);
        downSideBaseUri = _downSideBaseUri;
    }

    function setDownSideBaseUri(string memory _downSideBaseUri) public override onlyOwner {
        downSideBaseUri = _downSideBaseUri;
    }

    function getMetadata(uint256 tokenId) public override view onlyOwnerOrContract returns (string memory) {
        string memory baseUri = "";
        if (isRevealed(tokenId)){
            if (bytes(winBaseUriPrizes[tokenId]).length > 0){
                 baseUri = winBaseUriPrizes[tokenId];
            }else{
                baseUri = revealedBaseURIs[getPartitionByTkId(tokenId)];
            }
        }else{
            return downSideBaseUri;
        }
        return concatBaseUriId(tokenId, baseUri);
    }

    function setNewWinner(uint256 tokenId, string memory codePrize, string memory winBaseUri)
        public
        override
        onlyOwner
    {

        prizes[tokenId].push(PrizeState(
            prizes[tokenId].length,
            codePrize,
            false,
            false,
            address(0),
            block.timestamp,
            0
        ));

        winBaseUriPrizes[tokenId] = winBaseUri;
    }

    function withdrawPrize(uint256 tokenId, uint256 prizeId, string memory newWinBaseUri, bytes memory signature)
        public
        override
        onlyOwner
    {

        require(isOwnerSignature(tokenId, signature), "Signature of address holder not valid");

        PrizeState memory state = prizes[tokenId][prizeId];

        if(state.used || state.delegated){
            revert("Prize not avalaible");
        }

        prizes[tokenId][prizeId] = PrizeState(
            state.id,
            state.codePrize,
            true,
            state.delegated,
            state.proxy,
            state.winTimestamp,
            block.timestamp
        );

        if(bytes(newWinBaseUri).length > 0){
            winBaseUriPrizes[tokenId] = newWinBaseUri;
        }else{
            winBaseUriPrizes[tokenId] = "";
        }

    }

    function isOwnerSignature(uint256 tokenId, bytes memory signature)
        public
        view
        returns (bool)
    {
        address signer = nft.ownerOf(tokenId);
        bytes32 hash = prefixed(
            keccak256(abi.encodePacked(getMetadata(tokenId)))
        );
        console.log("address: ");
        console.log(hash.recover(signature));
        console.log("signer: ");
        console.log(signer);
        return hash.recover(signature) == signer;
    }

    function getPrizeStateByTokenId(uint256 tokenId)
        public
        override
        view
        returns (PrizeState[] memory)
    {
        return prizes[tokenId];
    }

    function delegateAWinner(uint256 tokenId, uint256 prizeId, address delegated, string memory newBaseURI) public override onlyOwnerOrContractPrize{

        require(!prizes[tokenId][prizeId].used, "Already used");

        PrizeState memory state = prizes[tokenId][prizeId];
        prizes[tokenId][prizeId] = PrizeState(
            state.id,
            state.codePrize,
            state.used,
            true,
            delegated,
            state.winTimestamp,
            block.timestamp
        );

        winBaseUriPrizes[tokenId] = newBaseURI;
    }

    function setWinBaseURI(uint256 tokenId, string memory newBaseURI) public override onlyOwnerOrContractPrize{
        winBaseUriPrizes[tokenId] = newBaseURI;
    }

    function usePrize(uint256 tokenId, uint256 prizeId, string memory newBaseURI) public override onlyOwnerOrContractPrize{
        require(!prizes[tokenId][prizeId].used, "Already used");

        PrizeState memory state = prizes[tokenId][prizeId];
        prizes[tokenId][prizeId] = PrizeState(
            state.id,
            state.codePrize,
            true,
            state.delegated,
            state.proxy,
            state.winTimestamp,
            block.timestamp
        );

        winBaseUriPrizes[tokenId] = newBaseURI;
    }

    function checkClosePartition(uint256 tokenId) public override onlyContract {
        uint256 tokenPartition = getPartitionByTkId(tokenId);
        if(tokenPartition > 1 && tokenPartition != 6 && tokenPartition != 11){
            if(!activatedPartitions[tokenPartition]){
                activatedPartitions[tokenPartition] = true;
                closedPartitions.push(getPartitionByTkId(tokenId) - 1);
            }   
        }
    }

    function getListClosePartition() public override view onlyOwner returns(uint256[] memory){
        return closedPartitions;
    }

    function revealBlock(uint8 _partition, string memory baseURI)
        public
        override
        onlyOwner
    {
        revealedPartitions.push(_partition);
        revealedBaseURIs[_partition] = baseURI;
    }

    function getRevealedPartitions() public override view onlyOwner returns(uint256[] memory){
        return revealedPartitions;
    }

    function isRevealed(uint256 tokenId) private view returns (bool) {
        return bytes(revealedBaseURIs[getPartitionByTkId(tokenId)]).length != 0;
    }

    function getPartitionByTkId(uint256 tokenId) public override view onlyOwnerOrContract returns(uint64) {
        if (tokenId <= 100){
            if ((uint64((tokenId % 20)) == 0)) {
                return uint64(tokenId / 20);
            }
            return uint64((tokenId / 20) + 1);

        }else if(tokenId > 100 && tokenId <= 600){

            if ((uint64((tokenId % 50)) == 0)) {
                return uint64((tokenId / 50) + 3);
            }
            return uint64((tokenId / 50) + 4);

        }else if(tokenId > 600){
            if ((uint64((tokenId % 100)) == 0)) {
                return uint64((tokenId / 100) + 9);
            }
            return uint64((tokenId / 100) + 10);
        }
        return 0;
    }

    function concatBaseUriId(uint256 tokenId, string memory baseUri ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    baseUri,
                    "/",
                    Strings.toString(tokenId)
                )
            );
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}
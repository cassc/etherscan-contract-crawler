//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract mintNFT1155 is
    RevokableDefaultOperatorFilterer,
    ERC1155URIStorage,
    Ownable,
    ERC2981
{
    //@notice name and symbol
    string public name;
    string public symbol;

    //@notice information by tokenId
    mapping(uint256 => InfoByTokenId) public dataByTokenId;

    //@notice struct of Information by tokenId
    struct InfoByTokenId {
        bool paused;
        uint256 totalSupply;
        uint256 maxSupply;
        uint256 cost;
        bytes32 merkleRoot;
        mapping(address => uint256) userMintedAmount;
    }

    //
    //CONSTRUCTOR
    //

    constructor() ERC1155("") {
        name = "NEO BABY PASS";
        symbol = "NB";
        dataByTokenId[1].paused = true;
        dataByTokenId[1].maxSupply = 5000;
        dataByTokenId[1].cost = 0;
        dataByTokenId[1]
            .merkleRoot = 0x0fcebe0479a246ed64747c7fedbe8bd76fd502fd36c0534395a96588af37babf;
        setDefaultRoyalty(0x8FD635F6397f11815f1C742909EdCDA596a0AbC9, 1000);
    }

    //
    //MINT
    //

    //@notice mint amount should be fixed one by frontend logic
    function mint(
        uint256 _tokenId,
        uint256 _mintAmount,
        uint256 _maxMintAmount,
        bytes32[] calldata _merkleProof
    ) public {
        //check
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, _maxMintAmount));
        require(!dataByTokenId[_tokenId].paused, "The tokenId is paused");
        require(
            MerkleProof.verify(
                _merkleProof,
                dataByTokenId[_tokenId].merkleRoot,
                _leaf
            ),
            "You Not AL"
        );
        require(
            _mintAmount +
                dataByTokenId[_tokenId].userMintedAmount[msg.sender] <=
                _maxMintAmount,
            "You already received"
        );
        require(
            (dataByTokenId[_tokenId].totalSupply + _mintAmount) <=
                dataByTokenId[_tokenId].maxSupply,
            "Mint exceeded limit"
        );

        //effect
        dataByTokenId[_tokenId].userMintedAmount[msg.sender] += _mintAmount;
        dataByTokenId[_tokenId].totalSupply += _mintAmount;

        //interaction
        _mint(msg.sender, _tokenId, _mintAmount, "");
    }

    //
    //SET
    //

    //@notice set BaseURI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    //@notice set setURI
    function setURI(uint256 _tokenId, string memory _newTokenURI)
        public
        onlyOwner
    {
        _setURI(_tokenId, _newTokenURI);
    }

    //@notice set Royality
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    //@notice set tokenInfo
    function setTokenInfo(
        uint256 _tokenId,
        bool _newPause, 
        uint256 _newMaxSupply,
        uint256 _newCost, 
        bytes32 _newMerkleRoot
    ) external onlyOwner {
        dataByTokenId[_tokenId].paused = _newPause;
        dataByTokenId[_tokenId].maxSupply = _newMaxSupply;
        dataByTokenId[_tokenId].cost = _newCost;
        dataByTokenId[_tokenId].merkleRoot = _newMerkleRoot;
    }

    //@notice set Pause
    function setPaused(uint256 _tokenId,bool _newPause) external onlyOwner {
        dataByTokenId[_tokenId].paused = _newPause;
    }

    //@notice set maxMintedNum
    function setMaxSupply(uint256 _tokenId, uint256 _newNum)
        external
        onlyOwner
    {
        dataByTokenId[_tokenId].maxSupply = _newNum;
    }

    //@notice set cost
    function setCost(uint256 _tokenId, uint256 _newCost) external onlyOwner {
        dataByTokenId[_tokenId].cost = _newCost;
    }

    //@notice set merkleRoot
    function setMerkleRoot(uint256 _tokenId, bytes32 _newMerkleRoot)
        external
        onlyOwner
    {
        dataByTokenId[_tokenId].merkleRoot = _newMerkleRoot;
    }

    //
    //GET
    //
    
    function getPaused(uint256 _tokenId) public view returns (bool) {
        return dataByTokenId[_tokenId].paused;
    }

    function getTotalSupply(uint256 _tokenId) public view returns (uint256) {
        return dataByTokenId[_tokenId].totalSupply;
    }

    function getMaxSupply(uint256 _tokenId) public view returns (uint256) {
        return dataByTokenId[_tokenId].maxSupply;
    }

    function getCost(uint256 _tokenId) public view returns (uint256) {
        return dataByTokenId[_tokenId].cost;
    }

    function getMerkleRoot(uint256 _tokenId) public view returns (bytes32) {
        return dataByTokenId[_tokenId].merkleRoot;
    }

    function getUserMintedAmount(address _user, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return dataByTokenId[_tokenId].userMintedAmount[_user];
    }

    function getWhitelist(
        address _user,
        uint256 _tokenId,
        uint256 _maxMintAmount,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_user, _maxMintAmount));
        return
            MerkleProof.verify(
                _merkleProof,
                dataByTokenId[_tokenId].merkleRoot,
                _leaf
            );
    }

    //
    //SBT
    //

    bool public isSBT = false;

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function setIsSBT(bool _state) public onlyOwner {
        isSBT = _state;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        require(
            isSBT == false || approved == false,
            "setApprovalForAll is prohibited"
        );
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(
            isSBT == false ||
                from == address(0) ||
                to == address(0) ||
                to == address(0x000000000000000000000000000000000000dEaD),
            "transfer is prohibited"
        );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //
    //INTERFACE
    //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
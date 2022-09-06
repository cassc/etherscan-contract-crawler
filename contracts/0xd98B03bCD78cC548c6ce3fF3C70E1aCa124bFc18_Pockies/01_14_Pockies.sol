// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {IPockies} from "./interface/IPockies.sol";
import {KeeperCompatible} from "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract Pockies is KeeperCompatible, Ownable, Pausable, ReentrancyGuard, ERC721A, IPockies  {
    using Strings for uint256;
    using MerkleProof for bytes32;

    uint256 private  s_presaleEndTime = 1661645157;

    uint256 private immutable i_maxPockies = 10000;

    uint256 private s_pricePerPockie = 0.1 ether;
    uint256 private s_maxPockiesPerWallet = 3;
    uint256 private s_maxPockiesPerTx = 3;

    bool private s_isPresale = true;
    bool private s_isRevealed = false;

    bytes32 private s_rootHash = 0x09f24ae8a8c3480481a408ff73faed09de897468a9f3655348c2e777cbb798a0;

    string private s_baseUri;
    string private s_hiddenUri = 'https://gateway.pinata.cloud/ipfs/QmRPMXbF5agAxRCDGxwYzcZdUDB11ij6CjucJiMefS5wCd';

    string private contractURIHash =
        "QmcXihk9zRXqZFYyxjBaSDzjP86q135BNaFTbDyYSKGKjq";

    mapping(address => uint256) private s_totalPockiesMinted;

    constructor()
        ERC721A("Pockies", "POCKIE")
    {
    }
 
    function checkUpkeep(bytes memory /*checkData*/) public override returns(bool upKeepNeeded, bytes memory /*performData*/) {
        if (s_isPresale == true) {
            if (block.timestamp > s_presaleEndTime) {
                return(true, "");
            }
            
        }else{
            return(false,"");
        }
    }
    
    function performUpkeep(bytes calldata /*performData*/) external override whenNotPaused nonReentrant{
        (bool upKeepNeeded,) = checkUpkeep("");
        require(upKeepNeeded,"Pockies: Upkeep Not Needed");
        s_isPresale = s_isPresale;
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory baseUri)
    {
        baseUri = s_baseUri;
    }

    function _mintPockies(address _receiver, uint256 _mintAmount) internal {
        _safeMint(_receiver, _mintAmount);

        emit PockiesMinted(_receiver, _mintAmount);
    }

    // modifier

    modifier whenNotRevealed() {
        require(s_isRevealed == false, "Pockies: Pockies are revealed");
        _;
    }

    modifier whenPublicSale() {
        require(s_isPresale == false, "Pockies: Public sale is not active");
        _;
    }

    modifier whenPresale() {
        require(s_isPresale == true, "Pockies: Pre sale is not active");
        _;
    }

    modifier whitelistComplaince(address _receiver, bytes32[] calldata _proof) {
        require(
            MerkleProof.verify(
                _proof,
                s_rootHash,
                keccak256(abi.encodePacked(_receiver))
            ),
            "You are not whitelisted !!"
        );
        _;
    }

    modifier mintComplaince(address _receiver, uint256 _mintAmount) {
        require(
            totalSupply() <= i_maxPockies,
            "Pockies: All pockies are solded out"
        );
        require(
            _mintAmount <= s_maxPockiesPerTx,
            "Pockies: Cannot mint more pockies per tx"
        );
        require(
            s_totalPockiesMinted[_receiver] + _mintAmount <=
                s_maxPockiesPerWallet,
            "Pockies: Cannot mint this amount please reduce it"
        );
        require(
            s_totalPockiesMinted[_receiver] <= s_maxPockiesPerWallet,
            "Pockies: Canno mint t More Pockies"
        );
        _;
    }

    // Public

    function mintPublicSale(uint256 _mintAmount)
        external
        payable
        nonReentrant
        whenNotPaused
        whenPublicSale
        mintComplaince(msg.sender, _mintAmount)
    {
        require(
            msg.value >= _mintAmount * s_pricePerPockie,
            "Pockies: Insufficent funds"
        );
        _mintPockies(msg.sender, _mintAmount);
        s_totalPockiesMinted[msg.sender] =
            s_totalPockiesMinted[msg.sender] +
            _mintAmount;
    }

    function mintPreSale(uint256 _mintAmount, bytes32[] calldata _proof)
        external
        payable
        nonReentrant
        whenPresale
        whenNotPaused
        mintComplaince(msg.sender, _mintAmount)
        whitelistComplaince(msg.sender, _proof)
    {
        require(
            msg.value >= _mintAmount * s_pricePerPockie,
            "Pockies: Insufficent funds"
        );
        _mintPockies(msg.sender, _mintAmount);
        s_totalPockiesMinted[msg.sender] =
            s_totalPockiesMinted[msg.sender] +
            _mintAmount;
    }

    // Only Owner

    function claimPockies(address _receiver, uint256 _mintAmount)
        external
        onlyOwner
    {
        _mintPockies(_receiver, _mintAmount);
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function upadatePricePerPockies(uint256 _newPrice) external onlyOwner {
        s_pricePerPockie = _newPrice;

        emit PricePerPockieUpdated(_newPrice);
    }

    function updateMaxPockiesPerWallet(uint256 _newLimit) external onlyOwner {
        s_maxPockiesPerWallet = _newLimit;

        emit MaxPockiesPerWalletUpdated(_newLimit);
    }

    function updateMaxPockiesPerTx(uint256 _newLimit) external onlyOwner {
        s_maxPockiesPerTx = _newLimit;

        emit MaxPockiesPerTxUpdated(_newLimit);
    }

    function togglePresale() external onlyOwner {
        s_isPresale = !s_isPresale;

        emit PresaleToggled();
    }

    function revealPockies() external whenNotRevealed onlyOwner {
        s_isRevealed = true;

        emit PockiesRevealed();
    }

    function updateRootHash(bytes32 _newRootHash) external onlyOwner {
        s_rootHash = _newRootHash;

        emit RootHashUpdated(_newRootHash);
    }

    function updateBaseUri(string memory _newBaseUri) external onlyOwner {
        s_baseUri = _newBaseUri;

        emit BaseUriUpdated(_newBaseUri);
    }

    function updateHiddenUri(string memory _newHiddenUri) external onlyOwner {
        s_baseUri = _newHiddenUri;

        emit HiddenUriUpdated(_newHiddenUri);
    }

    function updatePreslaeEndTime(uint256 _presaleEndTime) external onlyOwner {
        s_presaleEndTime = _presaleEndTime;

        emit PresaleEndTimeUpdated();
    }

    // View Functions

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory tokenUri)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (s_isRevealed == false) {
            return s_hiddenUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(
                abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")
            )
            : "";
    }

    function getMaxPockies() external pure returns (uint256 maxPockies) {
        maxPockies = i_maxPockies;
    }

    function getPricePerPockie()
        external
        view
        returns (uint256 pricePerPockie)
    {
        pricePerPockie = s_pricePerPockie;
    }

    function getPresaleEndTime() external view returns (uint256 _presaleEndTime) {
        _presaleEndTime = s_presaleEndTime;
    }

    function getMaxPockiePerWallet()
        external
        view
        returns (uint256 maxPockiesPerWallet)
    {
        maxPockiesPerWallet = s_maxPockiesPerWallet;
    }

    function getMaxPockiesPerTx()
        external
        view
        returns (uint256 maxPockiesPerTx)
    {
        maxPockiesPerTx = s_maxPockiesPerTx;
    }

    function getIsPresale() external view returns (bool isPresale) {
        isPresale = s_isPresale;
    }

    function getIsRevealed() external view returns (bool isRevealed) {
        isRevealed = s_isRevealed;
    }

    function getRootHash() external view returns (bytes32 rootHash) {
        rootHash = s_rootHash;
    }

    function getBaseUri() external view returns (string memory baseUri) {
        baseUri = s_baseUri;
    }

    function getHiddenUri() external view returns (string memory hiddenUri) {
        hiddenUri = s_hiddenUri;
    }

    function getTotalPockiesMinted(address _owner)
        external
        view
        returns (uint256 totalPockiesMinted)
    {
        totalPockiesMinted = s_totalPockiesMinted[_owner];
    }

    function contractURI()
        public
        view
        returns (string memory _contractUriHash)
    {
        _contractUriHash = string(abi.encodePacked("ipfs://", contractURIHash));
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
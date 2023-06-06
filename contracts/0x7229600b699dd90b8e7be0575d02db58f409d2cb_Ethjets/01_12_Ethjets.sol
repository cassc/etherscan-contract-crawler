//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

/*
 *             ╔═══════╗
 *            █|       |█
 *           █           █
 *          █    ╔══      █
 *          █  ╔╝         █
 *          █ ╔╝═══       █
 *           █           █
 *             @@@@@@@@@
 *
 * @title ERC1155 token for the ETHJETS
 * @author - https://twitter.com/theincubator_
 */
contract Ethjets is ERC1155, Ownable {
    struct MintContext {
        bool isSaleActive;
        bool isMintListSet;
        bool isPresaleActive;
        bool isTopGunSaleActive;
        MintConfig globalConfig;
        MintConfig captainConfig;
        MintConfig topGunConfig;
        int256 remainingGlobalPresaleMintCount;
        int256 remainingCaptainPresaleMintCount;
        int256 remainingTopGunMintCount;
    }

    struct MintConfig {
        uint256 maxPresaleMint;
        uint256 maxPublicMint;
        uint256 maxSupply;
        uint256 currentMintCount;
        uint256 pricePerToken;
        string tokenURI;
    }

    mapping(uint256 => MintConfig) public configs;
    mapping(uint256 => mapping(address => uint256)) public numberMinted;
    string public name;
    string public symbol;

    uint256 public constant TOKEN_ID_GLOBAL = 1;
    uint256 public constant TOKEN_ID_CAPTAIN = 2;
    uint256 public constant TOKEN_ID_TOP_GUN = 3;

    bool public isSaleActive = false;
    bool public isPresaleActive = false;
    bool public isTopGunSaleActive = false;
    bool public isMintListSet = false;

    address[] private payoutAddresses;
    uint256[] private payoutAmountPerNFT;
    address private ethjetsPayoutAddress;
    address private fallbackPayoutAddress;
    mapping(address => uint256) public numOfNFTsPaidOut;

    uint256 public totalReservedNFTs;

    bytes32 public mintlistMerkleRoot;
    bytes32 public topGunMerkleRoot;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uriBase,
        string memory _uriGlobal,
        string memory _uriCaptain,
        string memory _uriTopGun,
        address[] memory _payoutAddresses,
        uint256[] memory _payoutAmountPerNFT,
        address _ethjetsPayoutAddress
    ) ERC1155(_uriBase) {
        name = _name;
        symbol = _symbol;
        payoutAddresses = _payoutAddresses;
        payoutAmountPerNFT = _payoutAmountPerNFT;
        ethjetsPayoutAddress = _ethjetsPayoutAddress;
        configs[TOKEN_ID_GLOBAL] = MintConfig({
            maxPresaleMint: 5,
            maxPublicMint: 5,
            maxSupply: 1500,
            currentMintCount: 0,
            pricePerToken: 0.59 ether,
            tokenURI: _uriGlobal
        });

        configs[TOKEN_ID_CAPTAIN] = MintConfig({
            maxPresaleMint: 5,
            maxPublicMint: 5,
            maxSupply: 1000,
            currentMintCount: 0,
            pricePerToken: 1.42 ether,
            tokenURI: _uriCaptain
        });

        /* maxPresaleMint is not used for the topgun pass. We only use the maxPublicMint */
        configs[TOKEN_ID_TOP_GUN] = MintConfig({
            maxPresaleMint: 0,
            maxPublicMint: 1,
            maxSupply: 200,
            currentMintCount: 0,
            pricePerToken: 0.91 ether,
            tokenURI: _uriTopGun
        });
    }

    function totalSupply() public view returns (uint256) {
        uint256 totalSupply;
        for (uint256 i = TOKEN_ID_GLOBAL; i <= TOKEN_ID_TOP_GUN; i++) {
            totalSupply += configs[i].currentMintCount;
        }
        return totalSupply;
    }

    function exists(uint256 id) public view returns (bool) {
        return configs[id].maxSupply > 0;
    }

    function transitionToPublicSale() external onlyOwner {
        isSaleActive = true;
        isPresaleActive = false;
    }

    function setIsSaleActive(bool _newState) external onlyOwner {
        isSaleActive = _newState;
    }

    function setEthjetsPayoutAddress(address _ethjetsPayoutAddress) external onlyOwner {
        ethjetsPayoutAddress = _ethjetsPayoutAddress;
    }

    function setPayout(address[] calldata _payoutAddresses, uint256[] calldata _payoutAmountPerNFT) external onlyOwner {
        require(_payoutAddresses.length == _payoutAmountPerNFT.length, "array length");
        payoutAddresses = _payoutAddresses;
        payoutAmountPerNFT = _payoutAmountPerNFT;
    }

    function setIsTopGunSaleActive(bool _newState) external onlyOwner {
        isTopGunSaleActive = _newState;
    }

    function setIsPresaleActive(bool _isPresaleActive) external onlyOwner {
        isPresaleActive = _isPresaleActive;
    }

    function setFallbackPayoutAddress(address _fallbackPayoutAddress) external onlyOwner {
        fallbackPayoutAddress = _fallbackPayoutAddress;
    }

    function requireExists(uint256 _tokenId) internal view {
        require(exists(_tokenId), "token id doesn't exist");
    }

    function requireLessThanMaxSupply(uint256 _tokenId, uint256 _numOfTokens) internal view {
        require(_numOfTokens <= configs[_tokenId].maxSupply, "Purchase exceeds max supply");
    }

    function editConfig(
        uint256 _tokenId,
        uint256 _maxPresaleMint,
        uint256 _maxPublicMint,
        uint256 _pricePerToken,
        uint256 _maxSupply,
        string calldata _tokenURI
    ) external onlyOwner {
        requireExists(_tokenId);
        configs[_tokenId].maxPresaleMint = _maxPresaleMint;
        configs[_tokenId].maxPublicMint = _maxPublicMint;
        configs[_tokenId].pricePerToken = _pricePerToken;
        configs[_tokenId].tokenURI = _tokenURI;
        if (configs[_tokenId].currentMintCount == 0) {
            configs[_tokenId].maxSupply = _maxSupply;
        }
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        // If no URI exists for the specific id requested, fallback to the default ERC-1155 URI.
        return exists(_tokenId) ? configs[_tokenId].tokenURI : super.uri(_tokenId);
    }

    function isOnMintlist(bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, mintlistMerkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function setMintlistMerkleRoot(bytes32 newMintlistMerkleRoot) external onlyOwner {
        mintlistMerkleRoot = newMintlistMerkleRoot;
    }

    function isOnTopGunlist(bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, topGunMerkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function setTopGunMerkleRoot(bytes32 newTopGunMerkleRoot) external onlyOwner {
        topGunMerkleRoot = newTopGunMerkleRoot;
    }

    function getMintContext() external view returns (MintContext memory) {
        return
            MintContext({
                isSaleActive: isSaleActive,
                isPresaleActive: isPresaleActive,
                isTopGunSaleActive: isTopGunSaleActive,
                isMintListSet: mintlistMerkleRoot[0] != 0,
                globalConfig: configs[TOKEN_ID_GLOBAL],
                captainConfig: configs[TOKEN_ID_CAPTAIN],
                topGunConfig: configs[TOKEN_ID_TOP_GUN],
                remainingGlobalPresaleMintCount: int256(configs[TOKEN_ID_GLOBAL].maxPresaleMint) -
                    int256(numberMinted[TOKEN_ID_GLOBAL][msg.sender]),
                remainingCaptainPresaleMintCount: int256(configs[TOKEN_ID_CAPTAIN].maxPresaleMint) -
                    int256(numberMinted[TOKEN_ID_CAPTAIN][msg.sender]),
                remainingTopGunMintCount: int256(configs[TOKEN_ID_TOP_GUN].maxPublicMint) -
                    int256(numberMinted[TOKEN_ID_TOP_GUN][msg.sender])
            });
    }

    function gift(
        uint256 _tokenId,
        address[] calldata _receivers,
        uint256[] calldata _numberOfTokens
    ) external onlyOwner {
        requireExists(_tokenId);
        require(_receivers.length == _numberOfTokens.length, "array length");

        uint256 totalGifts = 0;
        for (uint256 i = 0; i < _numberOfTokens.length; i++) {
            totalGifts += _numberOfTokens[i];
        }

        requireLessThanMaxSupply(_tokenId, (configs[_tokenId].currentMintCount + totalGifts));

        for (uint256 i = 0; i < _receivers.length; i++) {
            numberMinted[_tokenId][_receivers[i]] += _numberOfTokens[i];
            configs[_tokenId].currentMintCount += _numberOfTokens[i];
            _mint(_receivers[i], _tokenId, _numberOfTokens[i], "");
        }

        totalReservedNFTs += totalGifts;
    }

    function mintTopGun(bytes32[] calldata proof, uint256 _numberOfTokens) external payable {
        require(isTopGunSaleActive, "Sale is not active");
        require(isOnTopGunlist(proof), "not on top gun list");
        require(
            _numberOfTokens + numberMinted[TOKEN_ID_TOP_GUN][msg.sender] <= configs[TOKEN_ID_TOP_GUN].maxPublicMint,
            "Exceeded max purchase"
        );

        mint(TOKEN_ID_TOP_GUN, _numberOfTokens);
    }

    function mintPresale(
        bytes32[] calldata proof,
        uint256 _tokenId,
        uint256 _numberOfTokens
    ) external payable {
        require(isPresaleActive, "presale is not active");
        require(isOnMintlist(proof), "not on the mintlist");
        require(
            _numberOfTokens + numberMinted[_tokenId][msg.sender] <= configs[_tokenId].maxPresaleMint,
            "Exceeded max purchase"
        );

        mint(_tokenId, _numberOfTokens);
    }

    function mintPublic(uint256 _tokenId, uint256 _numberOfTokens) external payable {
        require(isSaleActive, "Sale has not started yet");
        require(_numberOfTokens <= configs[_tokenId].maxPublicMint, "Exceeded max purchase");

        mint(_tokenId, _numberOfTokens);
    }

    function mint(uint256 _tokenId, uint256 _numberOfTokens) internal {
        requireExists(_tokenId);
        requireLessThanMaxSupply(_tokenId, configs[_tokenId].currentMintCount + _numberOfTokens);
        require(configs[_tokenId].pricePerToken * _numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(tx.origin == msg.sender, "Transaction origin must be the message sender");
        numberMinted[_tokenId][msg.sender] += _numberOfTokens;
        configs[_tokenId].currentMintCount += _numberOfTokens;
        _mint(msg.sender, _tokenId, _numberOfTokens, "");
    }

    function withdrawDistributeOnChain() external onlyOwner {
        for (uint256 i = 0; i < payoutAddresses.length; i++) {
            uint256 nftsToBePaidOut = totalSupply() - totalReservedNFTs - numOfNFTsPaidOut[payoutAddresses[i]];
            (bool partnerSuccess, ) = payable(payoutAddresses[i]).call{
                value: nftsToBePaidOut * payoutAmountPerNFT[i]
            }("");
            require(partnerSuccess, "unable to send partner value, recipient may have reverted");
            numOfNFTsPaidOut[payoutAddresses[i]] += nftsToBePaidOut;
        }

        (bool ownerSuccess, ) = payable(ethjetsPayoutAddress).call{ value: address(this).balance }("");
        require(ownerSuccess, "unable to send owner value, recipient may have reverted");
    }

    function withdraw() external onlyOwner {
        require(fallbackPayoutAddress != address(0), "fallback address needs to be set before calling withdraw");
        (bool success, ) = payable(fallbackPayoutAddress).call{ value: address(this).balance }("");
        require(success, "unable to send, recipient may have reverted");
    }
}
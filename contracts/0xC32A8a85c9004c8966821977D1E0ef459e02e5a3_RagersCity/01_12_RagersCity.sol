// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @title:  Ragers City
// @desc:   Ragers City is a next-gen decentralized Manga owned by the community, featuring a collection of 5000 NFTs.
// @team:   https://twitter.com/RagersCity
// @author: https://linkedin.com/in/antoine-andrieux
// @url:    https://ragerscity.com


/*
██████╗░░█████╗░░██████╗░███████╗██████╗░░██████╗  
██╔══██╗██╔══██╗██╔════╝░██╔════╝██╔══██╗██╔════╝  
██████╔╝███████║██║░░██╗░█████╗░░██████╔╝╚█████╗░  
██╔══██╗██╔══██║██║░░╚██╗██╔══╝░░██╔══██╗░╚═══██╗  
██║░░██║██║░░██║╚██████╔╝███████╗██║░░██║██████╔╝  
╚═╝░░╚═╝╚═╝░░╚═╝░╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝░  

░█████╗░██╗████████╗██╗░░░██╗
██╔══██╗██║╚══██╔══╝╚██╗░██╔╝
██║░░╚═╝██║░░░██║░░░░╚████╔╝░
██║░░██╗██║░░░██║░░░░░╚██╔╝░░
╚█████╔╝██║░░░██║░░░░░░██║░░░
░╚════╝░╚═╝░░░╚═╝░░░░░░╚═╝░░░
*/


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./extensions/SignatureMint.sol";
import "./interface/IRagersCity.sol";
import "./interface/IRagersCityMetadata.sol";

contract RagersCity is IRagersCity, IERC2981, Ownable, SignatureMint {
    using ECDSA for bytes32;

    // -------- Minter --------
    uint256 public constant MAX_SUPPLY = 5001;
    uint256 public constant MAX_PUBLIC_SUPPLY = 4779;
    uint256 public constant MAX_WHITELIST_SUPPLY = 1556;
    uint256 public constant MAX_FREE_SUPPLY = 223;

    uint256 public totalFreeSupply = 0;
    uint256 public publicCost = 0.095 ether;
    uint256 public whitelistFirstCost = 0.07 ether;
    uint256 public whitelistSecondCost = 0.085 ether;
    uint256 public maxMintAmountPerTx = 6;
    uint256 public maxMintAmountPerWallet = 26;

    bool public whitelistOnly = true;

    // -------- Provenance --------
    string public provenanceHash;

    // -------- Metadata --------
    // Seperate contract to allow eventual move to on-chain metadata.
    IRagersCityMetadata public metadata;
    bool public isMetadataLocked = false;

    // -------- Burning --------
    bool public isBurningActive = false;

    // -------- Royalties --------
    address public royaltyAddress;
    uint256 public royaltyPercent = 6;

    // -------- Shares --------
    address public constant T1 = 0xcBdB4519904013D7faFc09F59620f1E5637106E1;
    address public constant T2 = 0x0ADD36571F0b4bBb8767Bb725654052D6bbAa8AB;
    address public constant T3 = 0x62C3A83d96C6f9E47CA66c4EF96Fc80304dE72d9;
    address public constant T4 = 0xa7d61858D70fD5d217C9A466970e9760e63eCBC7;
    address public constant T5 = 0x6169a6b8d5dF143B07391D7b93c24ECFF8bF2faC;
    address public constant T6 = 0x7C5335BB07e8f18ac0aCA1F95230c672896099c1;
    address public constant T7 = 0x9bb11cE11fB50f6FAb9045EA2DeC91908894c832;
    address public constant T8 = 0x8b1AeD0528802aE329E44A0255dA6D2A1cB305E5;

    // -------- ContractURI --------
    string private _contractURI = "";

    // ======== CONSTRUCTOR =========
    constructor(address _metadata, address _royaltyReceiver, string memory _initContractURI) ERC721A("Ragers City", "RC") {
        require(_metadata != address(0), "Metadata address cannot be zero address!");
        require(_royaltyReceiver != address(0), "Royalties address cannot be zero address!");
        metadata = IRagersCityMetadata(_metadata);
        royaltyAddress = _royaltyReceiver;
        _contractURI = _initContractURI;
    }


    // ======== MINTER ========
    
    function mintWhitelist(
        uint256 _mintAmount,
        bytes calldata _signature,
        bool _hasFreeMint
    ) external payable override requiresWhitelist(_signature, _hasFreeMint) {
        require(whitelistOnly, "The sale is public!");
        require(totalSupply() < MAX_WHITELIST_SUPPLY, "The whitelist sale is full!");
        require(msg.sender == tx.origin);
        require(_mintAmount < maxMintAmountPerTx, "Invalid mint amount!");
        uint256 _balance = balanceOf(msg.sender);
        require(msg.value == _getWhitelistCost(_mintAmount, _balance), "Insufficient funds!");

        // Ensure the wallet hasn't already claimed.
        require(
            _balance + _mintAmount < maxMintAmountPerWallet,
            "Address has already claimed."
        );

        // Mint token
        _mint(msg.sender, _mintAmount);
    }

    modifier requiresPublic(uint256 _mintAmount) {
        require(!whitelistOnly, "The sale is reserved for the whitelist!");
        require(_mintAmount < maxMintAmountPerTx, "Invalid mint amount!");
        require(totalSupply() + _mintAmount < MAX_PUBLIC_SUPPLY + totalFreeSupply, "Max public supply exceeded!");
        require(msg.sender == tx.origin);
        require(
            balanceOf(msg.sender) + _mintAmount < maxMintAmountPerWallet,
            "The address already has the maximum amount of tokens!"
        );
        require(msg.value == publicCost * _mintAmount, "Insufficient funds!");
        _;
    }

    function mintFree(
        uint256 _mintAmount, 
        bytes calldata _signature
    ) external payable override requiresPublic(_mintAmount) {
        // Free mint
        if (isFree(_signature, true) && _getAux(msg.sender) == 0) {
            require(totalFreeSupply + 1 < MAX_FREE_SUPPLY, "Max Free supply exceeded!");
            unchecked {
                _mintAmount++;
                totalFreeSupply++;
            }
            _setAux(msg.sender, 1);
        }

        _mint(msg.sender, _mintAmount);
    }

    function mint(
        uint256 _mintAmount
    ) external payable override requiresPublic(_mintAmount) {
        _mint(msg.sender, _mintAmount);
    }

    function mintForAddress(address _receiver, uint256 _mintAmount)
        external
        override
        onlyOwner
    {
        require(totalSupply() + _mintAmount < MAX_SUPPLY, "Max supply exceeded!");
        _mint(_receiver, _mintAmount);
    }

    // -------- Parameters --------
    function setPublicCost(uint256 _cost) external override onlyOwner {
        publicCost = _cost;
        emit PublicCostChanged(publicCost);
    }

    function setWhitelistFirstCost(uint256 _cost) external override onlyOwner {
        whitelistFirstCost = _cost;
        emit WhitelistFirstCostChanged(whitelistFirstCost);
    }

    function setWhitelistSecondCost(uint256 _cost) external override onlyOwner {
        whitelistSecondCost = _cost;
        emit WhitelistSecondCostChanged(whitelistSecondCost);
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        external
        override
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
        emit MaxMintAmountPerTxChanged(maxMintAmountPerTx);
    }

    function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet)
        external
        override
        onlyOwner
    {
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
        emit MaxMintAmountPerWalletChanged(maxMintAmountPerWallet);
    }

    function pause() external override onlyOwner {
        whitelistOnly = true;
        setWhitelistSigningAddress(address(0));
        emit Paused();
    }

    function isPaused() external view override returns(bool) {
        return (whitelistOnly && whitelistSigningKey == address(0));
    }

    function setWhitelistOnly(bool _whitelistOnly) external override onlyOwner {
        whitelistOnly = _whitelistOnly;
        emit WhitelistOnlyChanged(whitelistOnly);
    }

    function _getWhitelistCost(uint256 _mintAmount, uint256 _balance) internal view override returns (uint256) {
        return _balance == 0 ?
                _mintAmount != 0 ? 
                    whitelistFirstCost + (whitelistSecondCost * (_mintAmount - 1)) 
                    : 0
                : whitelistSecondCost * _mintAmount;
    }

    function getCost(uint256 _mintAmount) external view override returns (uint256) {
        if (whitelistOnly) {
            uint256 _balance = balanceOf(msg.sender);
            return _getWhitelistCost(_mintAmount, _balance);
        } else {
            return publicCost * _mintAmount;
        }
    }


    // ======== TOKEN ========

    // -------- Metadata --------
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token!");
        return metadata.tokenURI(tokenId);
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string calldata _newContractURI)
        external
        override
        onlyOwner
    {
        require(!isMetadataLocked, "Metadata ownership renounced!");
        _contractURI = _newContractURI;
    }

    function updateMetadata(address _metadata) external override onlyOwner {
        require(!isMetadataLocked, "Metadata ownership renounced!");
        metadata = IRagersCityMetadata(_metadata);
        emit MetadataUpdated(_metadata);
    }

    function lockMetadata() external override onlyOwner {
        isMetadataLocked = true;
        emit MetadataLocked();
    }

    // -------- Provenance --------
    function setProvenanceHash(string calldata _provenanceHash)
        external
        override
        onlyOwner
    {
        require(bytes(provenanceHash).length == 0, "Provenance hash already set!");
        provenanceHash = _provenanceHash;
        emit ProvenanceHashUpdated(provenanceHash);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // -------- Burning --------
    function burn(uint256 tokenId) public override {
        require(isBurningActive, "Burning not active!");
        _burn(tokenId, true);
    }

    function toggleBurningActive() public override onlyOwner {
        isBurningActive = !isBurningActive;
        emit BurningActivated(isBurningActive);
    }

    // -------- Royalties --------
    function setRoyaltyReceiver(address royaltyReceiver) external override onlyOwner {
        require(royaltyReceiver != address(0), "Royalty receiver is the zero address!");
        royaltyAddress = royaltyReceiver;
        emit RoyaltyReceiverUpdated(royaltyAddress);
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage) external override onlyOwner {
        royaltyPercent = royaltyPercentage;
        emit RoyaltyPercentageUpdated(royaltyPercent);
    }

    // EIP-2981 royalties implementation
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Non-existent token!");
        return (royaltyAddress, (salePrice * royaltyPercent) / 100);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // -------- Withdraw --------
    function withdraw() external override {
        require(
            msg.sender == T1 || msg.sender == T2 || msg.sender == T3 ||
            msg.sender == T4 || msg.sender == T5 || msg.sender == T6 || 
            msg.sender == T7 || msg.sender == T8, "Only Team can withdraw!"
        );

        uint256 S1 = address(this).balance * 30 / 100;
        uint256 S2 = address(this).balance * 30 / 100;
        uint256 S3 = address(this).balance * 18 / 100;
        uint256 S4 = address(this).balance * 7 / 100;
        uint256 S5 = address(this).balance * 6 / 100;
        uint256 S6 = address(this).balance * 55 / 1000;
        uint256 S7 = address(this).balance * 25 / 1000;
        uint256 S8 = address(this).balance * 1 / 100;
        
        (bool os1, ) = payable(T1).call{value: S1}("");
        require(os1);
        (bool os2, ) = payable(T2).call{value: S2}("");
        require(os2);
        (bool os3, ) = payable(T3).call{value: S3}("");
        require(os3);
        (bool os4, ) = payable(T4).call{value: S4}("");
        require(os4);
        (bool os5, ) = payable(T5).call{value: S5}("");
        require(os5);
        (bool os6, ) = payable(T6).call{value: S6}("");
        require(os6);
        (bool os7, ) = payable(T7).call{value: S7}("");
        require(os7);
        (bool os8, ) = payable(T8).call{value: S8}("");
        require(os8);
    }
}
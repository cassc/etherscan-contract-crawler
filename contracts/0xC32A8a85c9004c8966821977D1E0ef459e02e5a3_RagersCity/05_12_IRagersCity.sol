// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @title:  Ragers City
// @desc:   Ragers City is a next-gen decentralized Manga owned by the community, featuring a collection of 5000 NFTs.
// @team:   https://twitter.com/RagersCity
// @author: https://linkedin.com/in/antoine-andrieux
// @url:    https://ragerscity.com

import "erc721a/contracts/ERC721A.sol";

abstract contract IRagersCity is ERC721A {

    // -------- Events --------
    event MetadataUpdated(address indexed _metadata);
    event RoyaltyReceiverUpdated(address indexed _royaltyAddress);
    event RoyaltyPercentageUpdated(uint256 indexed _royaltyPercent);
    event StartingIndexUpdatedAndLocked(uint256 indexed _startingIndex);
    event ProvenanceHashUpdated(string indexed _provenanceHash);
    event MetadataLocked();
    event BurningActivated(bool _isBurningActive);
    event WhitelistSignerUpdated(address _signer);
    event Paused();
    event WhitelistOnlyChanged(bool _whitelistOnly);
    event PublicCostChanged(uint256 _cost);
    event WhitelistFirstCostChanged(uint256 _cost);
    event WhitelistSecondCostChanged(uint256 _cost);
    event MaxMintAmountPerTxChanged(uint256 _maxMintAmountPerTx);
    event MaxMintAmountPerWalletChanged(uint256 _maxMintAmountPerWallet);
    event PermanentURI(string _value, uint256 indexed _id);

    function isAddressWhitelisted(
        bytes calldata _signature, 
        bool _hasFreeMint
    ) public view virtual returns (bool) {}

   function mintWhitelist(
        uint256 _mintAmount,
        bytes calldata _signature,
        bool _hasFreeMint
    ) external payable virtual {}

    function mintFree(
        uint256 _mintAmount, 
        bytes calldata _signature
    ) external payable virtual {}

    function mint(
        uint256 _mintAmount
    ) external payable virtual {}

    function mintForAddress(address _receiver, uint256 _mintAmount) external virtual {}

    function setPublicCost(uint256 _cost) external virtual {}

    function setWhitelistFirstCost(uint256 _cost) external virtual {}

    function setWhitelistSecondCost(uint256 _cost) external virtual {}

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external virtual {}

    function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet)
        external virtual
    {}

    function isPaused() external view virtual returns (bool) {}

    function pause() external virtual {}

    function setWhitelistOnly(bool _whitelistOnly) external virtual {}

    function _getWhitelistCost(
        uint256 _mintAmount,
        uint256 _balance
    ) internal view virtual returns (uint256) {}

    function getCost(uint256 _mintAmount)
        external
        view
        virtual
        returns (uint256)
    {}

    function tokenURI(uint256 tokenId)
        public
        view
        override
        virtual
        returns (string memory)
    {}

    function contractURI() public view virtual returns (string memory) {}

    function setContractURI(string calldata _newContractURI)
        external 
        virtual
    {}

    function updateMetadata(address _metadata) external virtual {}

    function lockMetadata() external virtual {}

    function setProvenanceHash(string calldata _provenanceHash)
        external
        virtual
    {}

    function setStartingIndex() external virtual {}

    function burn(uint256 tokenId) public virtual {}

    function toggleBurningActive() public virtual {}

    function setRoyaltyReceiver(address royaltyReceiver) external virtual {}

    function setRoyaltyPercentage(uint256 royaltyPercentage) external virtual {}

    function withdraw() external virtual {}
}
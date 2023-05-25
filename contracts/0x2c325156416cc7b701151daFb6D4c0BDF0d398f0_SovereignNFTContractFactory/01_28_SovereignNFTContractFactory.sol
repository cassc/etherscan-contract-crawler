// contracts/token/ERC721/sovereign/SovereignNFTContractFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../../../marketplace/IMarketplaceSettings.sol";
import "../../../royalty/creator/IERC721CreatorRoyalty.sol";
import "./SovereignNFT.sol";

contract SovereignNFTContractFactory is Ownable {
    IMarketplaceSettings public marketplaceSettings;
    IERC721CreatorRoyalty public royaltyRegistry;

    address public sovereignNFT;

    event SovereignNFTContractCreated(
        address indexed contractAddress,
        address indexed owner
    );

    constructor(address _marketplaceSettings, address _royaltyRegistry) {
        require(
            _marketplaceSettings != address(0),
            "constructor::_marketplaceSettings cannot be zero address."
        );

        require(
            _royaltyRegistry != address(0),
            "constructor::_royaltyRegistry cannot be zero address."
        );
        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
        royaltyRegistry = IERC721CreatorRoyalty(_royaltyRegistry);

        SovereignNFT sovNFT = new SovereignNFT();
        sovereignNFT = address(sovNFT);
    }

    function setMarketplaceSettings(address _marketplaceSettings)
        external
        onlyOwner
    {
        require(_marketplaceSettings != address(0));
        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
    }

    function setRoyaltyRegistry(address _royaltyRegistry) external onlyOwner {
        require(_royaltyRegistry != address(0));
        royaltyRegistry = IERC721CreatorRoyalty(_royaltyRegistry);
    }

    function setSovereignNFT(address _sovereignNFT) external onlyOwner {
        require(_sovereignNFT != address(0));
        sovereignNFT = _sovereignNFT;
    }

    function createSovereignNFTContract(
        string memory _name,
        string memory _symbol
    ) public returns (address) {
        address sovAddr = Clones.clone(sovereignNFT);
        SovereignNFT(sovAddr).init(_name, _symbol, msg.sender);

        emit SovereignNFTContractCreated(sovAddr, msg.sender);

        marketplaceSettings.setERC721ContractPrimarySaleFeePercentage(
            sovAddr,
            15
        );

        royaltyRegistry.setPercentageForSetERC721ContractRoyalty(sovAddr, 10);

        return address(sovereignNFT);
    }
}
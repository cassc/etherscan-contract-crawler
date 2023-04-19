// contracts/token/ERC721/sovereign/SovereignNFTContractFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/proxy/Clones.sol";
import "../../marketplace/IMarketplaceSettings.sol";
import "./SovereignNFT.sol";
import "./extensions/SovereignNFTRoyaltyGuard.sol";
import "./extensions/SovereignNFTRoyaltyGuardDeadmanTrigger.sol";

contract SovereignNFTContractFactory is Ownable {
    IMarketplaceSettings public marketplaceSettings;

    bytes32 public constant SOVEREIGN_NFT = "SOVEREIGN_NFT";
    bytes32 public constant ROYALTY_GUARD = "ROYALTY_GUARD";
    bytes32 public constant ROYALTY_GUARD_DEADMAN = "ROYALTY_GUARD_DEADMAN";

    address public sovereignNFT;
    address public sovereignNFTRoyaltyGuard;
    address public sovereignNFTRoyaltyGuardDeadmanTrigger;

    event SovereignNFTContractCreated(
        address indexed contractAddress,
        address indexed owner
    );

    constructor(address _marketplaceSettings) {
        require(
            _marketplaceSettings != address(0),
            "constructor::_marketplaceSettings cannot be zero address."
        );

        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);

        SovereignNFT sovNFT = new SovereignNFT();
        sovereignNFT = address(sovNFT);

        SovereignNFTRoyaltyGuard sovNFTRG = new SovereignNFTRoyaltyGuard();
        sovereignNFTRoyaltyGuard = address(sovNFTRG);

        SovereignNFTRoyaltyGuardDeadmanTrigger sovNFTRGDT = new SovereignNFTRoyaltyGuardDeadmanTrigger();
        sovereignNFTRoyaltyGuardDeadmanTrigger = address(sovNFTRGDT);
    }

    function setMarketplaceSettings(address _marketplaceSettings)
        external
        onlyOwner
    {
        require(_marketplaceSettings != address(0));
        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
    }

    function setSovereignNFT(address _sovereignNFT) external onlyOwner {
        require(_sovereignNFT != address(0));
        sovereignNFT = _sovereignNFT;
    }

    function setSovereignNFT(address _sovereignNFT, bytes32 _contractType)
        external
        onlyOwner
    {
        require(_sovereignNFT != address(0));
        if (_contractType == SOVEREIGN_NFT) {
            sovereignNFT = _sovereignNFT;
            return;
        }
        if (_contractType == ROYALTY_GUARD) {
            sovereignNFTRoyaltyGuard = _sovereignNFT;
            return;
        }
        if (_contractType == ROYALTY_GUARD_DEADMAN) {
            sovereignNFTRoyaltyGuardDeadmanTrigger = _sovereignNFT;
            return;
        }
        require(false, "setSovereignNFT::Unsupported _contractType.");
    }

    function createSovereignNFTContract(
        string memory _name,
        string memory _symbol,
        uint256 _maxTokens
    ) public returns (address) {
        require(
            _maxTokens != 0,
            "createSovereignNFTContract::_maxTokens cant be zero"
        );
        address sovAddr = Clones.clone(sovereignNFT);
        SovereignNFT(sovAddr).init(_name, _symbol, msg.sender, _maxTokens);

        emit SovereignNFTContractCreated(sovAddr, msg.sender);

        marketplaceSettings.setERC721ContractPrimarySaleFeePercentage(
            sovAddr,
            15
        );

        return address(sovereignNFT);
    }

    function createSovereignNFTContract(
        string memory _name,
        string memory _symbol
    ) public returns (address) {
        address sovAddr = Clones.clone(sovereignNFT);
        SovereignNFT(sovAddr).init(
            _name,
            _symbol,
            msg.sender,
            type(uint256).max
        );

        emit SovereignNFTContractCreated(sovAddr, msg.sender);

        marketplaceSettings.setERC721ContractPrimarySaleFeePercentage(
            sovAddr,
            15
        );

        return address(sovereignNFT);
    }

    function createSovereignNFTContract(
        string memory _name,
        string memory _symbol,
        uint256 _maxTokens,
        bytes32 _contractType
    ) public returns (address) {
        require(
            _maxTokens != 0,
            "createSovereignNFTContract::_maxTokens cant be zero"
        );

        address sovAddr;
        if (_contractType == SOVEREIGN_NFT) {
            sovAddr = Clones.clone(sovereignNFT);
            SovereignNFT(sovAddr).init(_name, _symbol, msg.sender, _maxTokens);
        }
        if (_contractType == ROYALTY_GUARD) {
            sovAddr = Clones.clone(sovereignNFTRoyaltyGuard);
            SovereignNFTRoyaltyGuard(sovAddr).init(
                _name,
                _symbol,
                msg.sender,
                _maxTokens
            );
        }
        if (_contractType == ROYALTY_GUARD_DEADMAN) {
            sovAddr = Clones.clone(sovereignNFTRoyaltyGuardDeadmanTrigger);
            SovereignNFTRoyaltyGuardDeadmanTrigger(sovAddr).init(
                _name,
                _symbol,
                msg.sender,
                _maxTokens
            );
        }

        require(
            sovAddr != address(0),
            "createSovereignNFTContract::_contractType unsupported contract type."
        );
        emit SovereignNFTContractCreated(sovAddr, msg.sender);

        marketplaceSettings.setERC721ContractPrimarySaleFeePercentage(
            sovAddr,
            15
        );

        return address(sovAddr);
    }
}
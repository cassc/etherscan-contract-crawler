// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../tierLevel/interfaces/IGovTier.sol";
import "../tierLevel/interfaces/IVCTier.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../admin/SuperAdminControl.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../addressprovider/IAddressProvider.sol";

contract VCTier is IVCTier, OwnableUpgradeable, SuperAdminControl {
    mapping(address => VCNFTTier) public vcNftTiers;
    address[] public vcTiersKeys;

    address public addressProvider;
    address public govTier;

    function initialize() external initializer {
        __Ownable_init();
    }

    function updateAddresses() external onlyOwner {
        govTier = IAddressProvider(addressProvider).getGovTier();
    }

    /// @dev set the address provider in this contract
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    /// @dev add the VC NFT Tier with only allowed token Ids
    function addVCNFTTier(
        address _vcnftContract,
        VCNFTTier memory _vcTierDetails
    )
        external
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(_vcnftContract != address(0), "zero address");
        require(_vcTierDetails.spAllowedTokens.length > 0, "allowed sp token");
        require(_vcTierDetails.spAllowedNFTs.length > 0, "allowed nfts null");
        require(
            IGovTier(govTier).isAlreadyTierLevel(
                _vcTierDetails.traditionalTier
            ),
            "GTL:Traditional Tier Null"
        );

        vcNftTiers[_vcnftContract] = _vcTierDetails;
        vcTiersKeys.push(_vcnftContract);
    }

    /// @dev this method adds more sp tokens for the vc nft tier
    /// @param _spTokens erc20 token addresses of strategic partners

    function addVCSpTokens(address _vcnftContract, address[] memory _spTokens)
        external
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(_vcnftContract != address(0), "zero address");
        require(_spTokens.length > 0, "allowed sp token");

        VCNFTTier storage vcTier = vcNftTiers[_vcnftContract];
        uint256 length = _spTokens.length;
        for (uint256 i = 0; i < length; i++) {
            vcTier.spAllowedTokens.push(_spTokens[i]);
        }
    }

    /// @dev this method adds the nft tokens for the vc nft tier
    /// @param _nftAddresses nft token addresses of strategic partners
    function addVCNftTokens(
        address _vcnftContract,
        address[] memory _nftAddresses
    )
        external
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(_vcnftContract != address(0), "zero address");
        require(_nftAddresses.length > 0, "allowed sp token");

        VCNFTTier storage vcTier = vcNftTiers[_vcnftContract];
        uint256 length = _nftAddresses.length;
        for (uint256 i = 0; i < length; i++) {
            vcTier.spAllowedNFTs.push(_nftAddresses[i]);
        }
    }

    /// @dev get VC Tier Data
    function getVCTier(address _vcTierNFT)
        external
        view
        override
        returns (VCNFTTier memory)
    {
        return vcNftTiers[_vcTierNFT];
    }

    function getUserVCNFTTier(address _wallet)
        external
        view
        override
        returns (VCNFTTier memory)
    {
        uint256 vcTierlength = vcTiersKeys.length;
        if (vcTierlength == 0) {
            return vcNftTiers[address(0x0)];
        }

        uint256 maxLTVFromNFTTier;
        address maxVCTierAddress;

        for (uint256 i = 0; i < vcTierlength; i++) {
            //user owns nft balannce
            uint256 tierLoantoValue;

            if (IERC721(vcTiersKeys[i]).balanceOf(_wallet) > 0) {

                tierLoantoValue = IGovTier(govTier)
                        .getSingleTierData(
                            vcNftTiers[vcTiersKeys[i]].traditionalTier
                        )
                        .loantoValue;
                
                if (tierLoantoValue >= maxLTVFromNFTTier) {
                    maxVCTierAddress = vcTiersKeys[i];
                    maxLTVFromNFTTier = tierLoantoValue;
                }
            } else {
                continue;
        }
        }
        return vcNftTiers[maxVCTierAddress];
    }

}
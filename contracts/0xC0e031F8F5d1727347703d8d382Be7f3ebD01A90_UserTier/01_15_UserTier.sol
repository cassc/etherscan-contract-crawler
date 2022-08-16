// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../tierLevel/interfaces/IUserTier.sol";
import "../tierLevel/interfaces/IVCTier.sol";
import "../tierLevel/interfaces/IGovNFTTier.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../admin/SuperAdminControl.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../addressprovider/IAddressProvider.sol";

contract UserTier is IUserTier, OwnableUpgradeable, SuperAdminControl {
    address public addressProvider;
    address public govGovToken;
    address public govTier;
    address public govNFTTier;
    address public govVCTier;

    function initialize() external initializer {
        __Ownable_init();
    }

    /// @dev update the addresses from the address provider
    function updateAddresses() external onlyOwner {
        govGovToken = IAddressProvider(addressProvider).getgovGovToken();
        govTier = IAddressProvider(addressProvider).getGovTier();
        govNFTTier = IAddressProvider(addressProvider).getGovNFTTier();
        govVCTier = IAddressProvider(addressProvider).getVCTier();
    }

    /// @dev set the address provider in this contract
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    /// @dev this function returns the tierLevel data by user's Gov Token Balance
    /// @param userWalletAddress user address for check tier level data

    function getTierDatabyGovBalance(address userWalletAddress)
        external
        view
        override
        returns (TierData memory _tierData)
    {
        address govToken = IAddressProvider(addressProvider).govTokenAddress();

        require(govToken != address(0x0), "GTL: Gov Token not Configured");
        require(
            govGovToken != address(0x0),
            "GTL: govGov GToken not Configured"
        );
        uint256 userGovBalance = IERC20(govToken).balanceOf(userWalletAddress) +
            IERC20(govGovToken).balanceOf(userWalletAddress);

        bytes32[] memory tierKeys = IGovTier(govTier).getGovTierLevelKeys();
        uint256 lengthTierLevels = tierKeys.length;

        if (
            userGovBalance >=
            IGovTier(govTier).getSingleTierData(tierKeys[0]).govHoldings
        ) {
            return
                tierDatabyGovBalance(
                    userGovBalance,
                    lengthTierLevels,
                    tierKeys
                );
        } else {
            return
                getTierDatabyWallet(
                    userWalletAddress,
                    lengthTierLevels,
                    tierKeys
                );
        }
    }

    function tierDatabyGovBalance(
        uint256 _userGovBalance,
        uint256 _lengthTierLevels,
        bytes32[] memory _tierKeys
    ) private view returns (TierData memory _tierData) {
        for (uint256 i = 1; i < _lengthTierLevels; i++) {
            if (
                (_userGovBalance >=
                    IGovTier(govTier)
                        .getSingleTierData(_tierKeys[i - 1])
                        .govHoldings) &&
                (_userGovBalance <
                    IGovTier(govTier)
                        .getSingleTierData(_tierKeys[i])
                        .govHoldings)
            ) {
                return IGovTier(govTier).getSingleTierData(_tierKeys[i - 1]);
            } else if (
                _userGovBalance >=
                IGovTier(govTier)
                    .getSingleTierData(_tierKeys[_lengthTierLevels - 1])
                    .govHoldings
            ) {
                return
                    IGovTier(govTier).getSingleTierData(
                        _tierKeys[_lengthTierLevels - 1]
                    );
            }
        }
    }

    function getTierDatabyWallet(
        address _wallet,
        uint256 _lengthTierLevels,
        bytes32[] memory _tierKeys
    ) private view returns (TierData memory _tierData) {
        for (uint256 i = 0; i < _lengthTierLevels; i++) {
            if (_tierKeys[i] == IGovTier(govTier).getWalletTier(_wallet)) {
                return IGovTier(govTier).getSingleTierData(_tierKeys[i]);
            }
        }
        return IGovTier(govTier).getSingleTierData(0);
    }

    /// @dev Returns max loan amount a borrower can borrow
    /// @param _collateralTokeninStable amount of collateral in stable token amount
    /// @param _tierLevelLTVPercentage tier level percentage value
    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) external pure override returns (uint256) {
        uint256 maxLoanAmountAllowed = (_collateralTokeninStable *
            _tierLevelLTVPercentage) / 100;
        return maxLoanAmountAllowed;
    }

    /// @dev returns the max loan amount to value
    /// @param _collateralTokeninStable value of collateral in stable token
    /// @param _borrower address of the borrower
    /// @return uint256 returns the max loan amount in stable token
    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower
    ) external view override returns (uint256) {
        TierData memory tierData = this.getTierDatabyGovBalance(_borrower);
        NFTTierData memory nftTier = IGovNFTTier(govNFTTier).getUserNftTier(
            _borrower
        );
        SingleSPTierData memory nftSpTier = IGovNFTTier(govNFTTier)
            .getSingleSpTier(nftTier.spTierId);

        VCNFTTier memory vcTier = IVCTier(govVCTier).getUserVCNFTTier(
            _borrower
        );

        if (tierData.govHoldings > 0) {
            return (_collateralTokeninStable * tierData.loantoValue) / 100;
        } else if (nftTier.isTraditional) {
            TierData memory traditionalTierData = IGovTier(govTier)
                .getSingleTierData(nftTier.traditionalTier);
            return
                (_collateralTokeninStable * traditionalTierData.loantoValue) /
                100;
        } else if (nftSpTier.ltv > 0) {
            return (_collateralTokeninStable * nftSpTier.ltv) / 100;
        } else if (vcTier.traditionalTier != 0) {
            TierData memory traditionalTierData = IGovTier(govTier)
                .getSingleTierData(vcTier.traditionalTier);
            return
                (_collateralTokeninStable * traditionalTierData.loantoValue) /
                100;
        } else {
            return 0;
        }
    }

    /// @dev Rules 1. User have gov balance tier, and they will
    // crerae single and multi token and nft loan according to tier level flags.
    // Rule 2. User have NFT tier level and it is traditional tier applies same rule as gov holding tier.
    // Rule 3. User have NFT tier level and it is SP Single Token, only SP token collateral allowed only single token loan allowed.
    // Rule 4. User have both NFT tier level and gov holding tier level. Invalid Tier.
    // Returns 200 if success all otther are differentt error codes
    /// @param _wallet address of the borrower
    /// @param _loanAmount loan amount in stable coin address
    /// @param _collateralinStable collateral amount in stable
    /// @param _stakedCollateralTokens staked collateral erc20 token addresses
    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens
    ) external view override returns (uint256) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.
        TierData memory tierData = this.getTierDatabyGovBalance(_wallet);
        NFTTierData memory nftTier = IGovNFTTier(govNFTTier).getUserNftTier(
            _wallet
        );
        SingleSPTierData memory nftSpTier = IGovNFTTier(govNFTTier)
            .getSingleSpTier(nftTier.spTierId);
        VCNFTTier memory vcTier = IVCTier(govVCTier).getUserVCNFTTier(_wallet);
        TierData memory vcTierData = IGovTier(govTier).getSingleTierData(
            vcTier.traditionalTier
        );

        if (
            (tierData.govHoldings > 0 && nftTier.nftContract != address(0)) ||
            (tierData.govHoldings > 0 && vcTierData.govHoldings > 0) ||
            (nftTier.nftContract != address(0) && vcTierData.govHoldings > 0)
        ) {
            //having all tiers not allowed, only one tier is allowed to create loan
            return 1;
        }
        if (tierData.govHoldings > 0) {
            //user has gov tier level
            return
                validateGovHoldingTierForToken(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    tierData
                );
        }
        //determine if user nft tier is available
        // need to determinne is user one
        //of the nft holder in NFTTierData mapping
        else if (nftTier.isTraditional) {
            return
                validateNFTTier(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    nftTier
                );
        } else if (nftSpTier.ltv > 0) {
            return
                validateNFTSpTier(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    nftTier,
                    nftSpTier
                );
        } else {
            return
                validateVCTier(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralTokens,
                    vcTier
                );
        }
    }

    function validateGovHoldingTierForToken(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        TierData memory _tierData
    ) private view returns (uint256) {
        if (_tierData.singleToken || _tierData.multiToken) {
            if (!_tierData.multiToken) {
                if (_stakedCollateralTokens.length > 1) {
                    return 2; //multi-token loan not allowed in tier.
                }
            }
        } else {
            return 8; // single and multitoken not allowed in this tier
        }
        if (
            _loanAmount >
            this.getMaxLoanAmount(_collateralinStable, _tierData.loantoValue)
        ) {
            //allowed ltv
            return 3;
        }

        return 200;
    }

    function validateNFTTier(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        NFTTierData memory _nftTierData
    ) private view returns (uint256) {
        TierData memory traditionalTierData = IGovTier(govTier)
            .getSingleTierData(_nftTierData.traditionalTier);
        //start validatting loan offer
        if (traditionalTierData.singleToken || traditionalTierData.multiToken) {
            if (!traditionalTierData.multiToken) {
                if (_stakedCollateralTokens.length > 1) {
                    return 2; //multi-token loan not allowed in tier.
                }
            }
        } else {
            return 8; // single and multitoken not allowed in this tier
        }
        if (
            _loanAmount >
            this.getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //allowed ltv
            return 3;
        }

        return 200;
    }

    function validateNFTSpTier(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        NFTTierData memory _nftTierData,
        SingleSPTierData memory _nftSpTier
    ) private pure returns (uint256) {
        if (_stakedCollateralTokens.length > 1 && !_nftSpTier.multiToken && !_nftSpTier.singleToken) {
            //only single token allowed for sp tier, and having no single token in your current tier
            return 5;
        }
        uint256 maxLoanAmount = (_collateralinStable * _nftSpTier.ltv) / 100;
        if (_loanAmount > maxLoanAmount) {
            //loan to value is under tier
            return 6;
        }
        for (uint256 c = 0; c < _stakedCollateralTokens.length; c++) {
            bool found = false;
            for (uint256 x = 0; x < _nftTierData.allowedSuns.length; x++) {
                if (
                    //collateral can be either approved sun token or associated sp token
                    _stakedCollateralTokens[c] == _nftTierData.allowedSuns[x] ||
                    _stakedCollateralTokens[c] == _nftTierData.spToken
                ) {
                    //collateral can not be other then sp token or approved sun tokens
                    found = true;
                }
            }
            if (!found) {
                //can not be other then approved sun Tokens or approved SP token
                return 7;
            }
        }
        return 200;
    }

    function validateVCTier(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralTokens,
        VCNFTTier memory _vcTier
    ) private view returns (uint256) {
        TierData memory traditionalTierData = IGovTier(govTier)
            .getSingleTierData(_vcTier.traditionalTier);

        if (traditionalTierData.singleToken || traditionalTierData.multiToken) {
            if (!traditionalTierData.multiToken) {
                if (_stakedCollateralTokens.length > 1) {
                    return 2; //multi-token loan not allowed in tier.
                }
            }
        } else {
            return 8; // single and multitoken not allowed in this tier
        }

        if (
            _loanAmount >
            this.getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //loan to value is under tier, loan amount is greater than max loan amount
            return 3;
        }

        for (uint256 j = 0; j < _stakedCollateralTokens.length; j++) {
            bool found = false;

            uint256 spTokenLength = _vcTier.spAllowedTokens.length;
            for (uint256 a = 0; a < spTokenLength; a++) {
                if (_stakedCollateralTokens[j] == _vcTier.spAllowedTokens[a]) {
                    //collateral can not be other then sp token
                    found = true;
                }
            }

            if (!found) {
                //can not be other then approved sp tokens or approved sun tokens
                return 7;
            }
        }

        return 200;
    }

    function validateGovHoldingTierForNFT(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        TierData memory _tierData
    ) private view returns (uint256) {
        //user has gov tier level
        //start validatting loan offer
        if (_tierData.singleNFT || _tierData.multiNFT) {
            if (!_tierData.multiNFT) {
                if (_stakedCollateralNFTs.length > 1) {
                    return 2; //multi-nft loan not allowed in gov tier.
                }
            }
        } else {
            return 8; // single and multi nft not allowed in this tier
        }
        if (
            _loanAmount >
            this.getMaxLoanAmount(_collateralinStable, _tierData.loantoValue)
        ) {
            //allowed ltv, loan amount is greater than max loan amount
            return 3;
        }

        return 200;
    }

    function validateNFTTierForNFTs(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        NFTTierData memory _nftTierData
    ) private view returns (uint256 result) {
        TierData memory traditionalTierData = IGovTier(govTier)
            .getSingleTierData(_nftTierData.traditionalTier);
        //start validatting loan offer
        if (traditionalTierData.singleNFT || traditionalTierData.multiNFT) {
            if (!traditionalTierData.multiNFT) {
                if (_stakedCollateralNFTs.length > 1) {
                    result = 2;
                    return result; //multi-token loan not allowed in tier.
                }
            }
        } else {
            return 8; //single and multi nfts not allowed
        }
        if (
            _loanAmount >
            this.getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //allowed ltv
            result = 3;
            return result;
        }

        result = 200;
        return result;
    }

    function validateNFTSpTierforNFTs(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        NFTTierData memory _nftTierData,
        SingleSPTierData memory _nftSpTier
    ) private pure returns (uint256) {
        if (_stakedCollateralNFTs.length > 1 && !_nftSpTier.multiNFT && !_nftSpTier.singleToken && !_nftSpTier.singleNft) {
            //only single nft or single token allowed for sp tier
            return 5;
        }
        uint256 maxLoanAmount = (_collateralinStable * _nftSpTier.ltv) / 100;
        if (_loanAmount > maxLoanAmount) {
            //loan to value is under tier
            return 6;
        }

        for (uint256 c = 0; c < _stakedCollateralNFTs.length; c++) {
            bool found = false;

            for (uint256 x = 0; x < _nftTierData.allowedNfts.length; x++) {
                if (_stakedCollateralNFTs[c] == _nftTierData.allowedNfts[x]) {
                    //collateral can not be other then sp token
                    found = true;
                }
            }

            if (!found) {
                //can not be other then approved sp nfts
                return 7;
            }
        }
        return 200;
    }

    function validateVCTierForNFTs(
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs,
        VCNFTTier memory _vcTier
    ) private view returns (uint256) {
        TierData memory traditionalTierData = IGovTier(govTier)
            .getSingleTierData(_vcTier.traditionalTier);

        if (traditionalTierData.singleNFT || traditionalTierData.multiNFT) {
            if (!traditionalTierData.multiNFT) {
                if (_stakedCollateralNFTs.length > 1) {
                    return 2; //multi-nfts loan not allowed in nft traditional tier.
                }
            }
        }else {
            return 8; // single and multi nft not allowed in this tier
        }

        if (
            _loanAmount >
            this.getMaxLoanAmount(
                _collateralinStable,
                traditionalTierData.loantoValue
            )
        ) {
            //loan to value is under tier
            return 3;
        }

        for (uint256 j = 0; j < _stakedCollateralNFTs.length; j++) {
            bool found = false;

            uint256 spNFTLength = _vcTier.spAllowedNFTs.length;
            for (uint256 a = 0; a < spNFTLength; a++) {
                if (_stakedCollateralNFTs[j] == _vcTier.spAllowedNFTs[a]) {
                    //collateral can not be other then sp nft
                    found = true;
                }
            }

            if (!found) {
                //can not be other then approved sp nfts
                return 7;
            }
        }
        return 200;
    }

    /// @dev Rules 1. User have gov balance tier, and they will
    // crerae single and multi token and nft loan according to tier level flags.
    // Rule 2. User have NFT tier level and it is traditional tier applies same rule as gov holding tier.
    // Rule 3. User have NFT tier level and it is SP Single Token, only SP token collateral allowed only single token loan allowed.
    // Rule 4. User have both NFT tier level and gov holding tier level. Invalid Tier.
    // Returns 200 if success all otther are differentt error codes
    /// @param _wallet address of the borrower
    /// @param _loanAmount loan amount in stable coin address
    /// @param _collateralinStable collateral amount in stable
    /// @param _stakedCollateralNFTs staked collateral NFT token addresses
    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 _collateralinStable,
        address[] memory _stakedCollateralNFTs
    ) external view override returns (uint256) {
        //purpose of function is to return false in case any tier level related validation fails
        //Identify what tier it is.
        TierData memory tierData = this.getTierDatabyGovBalance(_wallet);
        NFTTierData memory nftTier = IGovNFTTier(govNFTTier).getUserNftTier(
            _wallet
        );
        SingleSPTierData memory nftSpTier = IGovNFTTier(govNFTTier)
            .getSingleSpTier(nftTier.spTierId);
        VCNFTTier memory vcTier = IVCTier(govVCTier).getUserVCNFTTier(_wallet);
        TierData memory vcTierData = IGovTier(govTier).getSingleTierData(
            vcTier.traditionalTier
        );

        if (
            (tierData.govHoldings > 0 && nftTier.nftContract != address(0)) ||
            (tierData.govHoldings > 0 && vcTierData.govHoldings > 0) ||
            (nftTier.nftContract != address(0) && vcTierData.govHoldings > 0)
        ) {
            //having all tiers not allowed, only one tier is allowed to create loan
            return 1;
        }
        if (tierData.govHoldings > 0) {
            return
                validateGovHoldingTierForNFT(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    tierData
                );
        } else if (nftTier.isTraditional) {
            return
                validateNFTTierForNFTs(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    nftTier
                );
        } else if (nftSpTier.ltv > 0) {
            return
                validateNFTSpTierforNFTs(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    nftTier,
                    nftSpTier
                );
        } else {
            return
                validateVCTierForNFTs(
                    _loanAmount,
                    _collateralinStable,
                    _stakedCollateralNFTs,
                    vcTier
                );
        }
    }
}
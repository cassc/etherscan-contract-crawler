// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../tierLevel/interfaces/IGovTier.sol";
import "../tierLevel/interfaces/IGovNFTTier.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../admin/SuperAdminControl.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../addressprovider/IAddressProvider.sol";

contract GovNFTTier is IGovNFTTier, OwnableUpgradeable, SuperAdminControl {
    mapping(uint256 => SingleSPTierData) public spTierLevels;
    uint256[] public spTierLevelKeys;

    mapping(address => NFTTierData) public nftTierLevels;
    address[] public nftTierLevelsKeys;
    address public addressProvider;
    address public govTier;

    function initialize() external initializer {
        __Ownable_init();
    }

    /// @dev modifer only admin with edit admin access can call functions
    modifier onlyEditTierLevelRole(address admin) {
        address govAdminRegistry = IAddressProvider(addressProvider)
            .getAdminRegistry();
        require(
            IAdminRegistry(govAdminRegistry).isEditAdminAccessGranted(admin),
            "GTL: No admin right to add or remove tier level."
        );
        _;
    }

    function updateAddresses() external onlyOwner {
        govTier = IAddressProvider(addressProvider).getGovTier();
    }

    /// @dev set the address provider in this contract
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    /// @dev add NFT based Traditional or Single Token type tier levels
    /// @param _spTierLevel sp tier level struct
    function addSingleSpTierLevel(SingleSPTierData memory _spTierLevel)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(_spTierLevel.ltv > 0, "Invalid LTV");
        spTierLevels[spTierLevelKeys.length + 1] = _spTierLevel;
        spTierLevelKeys.push(spTierLevelKeys.length + 1);
    }

    /// @dev function to assign tierlevel to the NFT contract only by super admin
    /// @param _nftContract nft token address whose tier is being added
    /// @param _tierLevel NFTTierdata for the nft contract
    function addNftTierLevel(
        address _nftContract,
        NFTTierData memory _tierLevel
    )
        external
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(_tierLevel.nftContract != address(0), "invalid nft address");
        if (_tierLevel.isTraditional) {
            require(
                IGovTier(govTier).isAlreadyTierLevel(
                    _tierLevel.traditionalTier
                ),
                "GTL:Traditional Tier Null"
            );
            require(_tierLevel.spTierId == 0, "GTL: Can't set spTierId");
        } else {
            require(
                spTierLevels[_tierLevel.spTierId].ltv > 0,
                "GTL: SP Tier Null"
            );
            require(
                _tierLevel.traditionalTier == 0,
                "GTL: Can't set traditionalTier"
            );
        }

        nftTierLevels[_nftContract] = _tierLevel;
        nftTierLevelsKeys.push(_nftContract);
    }

    /// @dev this method adds the more nft tokens to already existing nft tier
    /// @param _nftContract nft token address
    /// @param _allowedNFTs allowed nfts addresses
    function addNFTTokensinNftTier(
        address _nftContract,
        address[] memory _allowedNFTs
    )
        external
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        NFTTierData storage nftTier = nftTierLevels[_nftContract];
        uint256 length = _allowedNFTs.length;
        for (uint256 i = 0; i < length; i++) {
            nftTier.allowedNfts.push(_allowedNFTs[i]);
        }
    }

    /// @dev this methods adds the sun token token to the nft tier
    /// @param _nftContract nft contract address
    /// @param _allowedSunTokens adding more allowed sun token addresses
    function addNFTSunTokensinNftTier(
        address _nftContract,
        address[] memory _allowedSunTokens
    )
        external
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        NFTTierData storage nftTier = nftTierLevels[_nftContract];
        uint256 length = _allowedSunTokens.length;
        for (uint256 i = 0; i < length; i++) {
            nftTier.allowedSuns.push(_allowedSunTokens[i]);
        }
    }

    /// @dev get all the sp nft tier level keys
    /// @return uint256[] returns the tier level keys Example: 0, 1, 2....
    function getSingleSpTierKeys() external view returns (uint256[] memory) {
        return spTierLevelKeys;
    }

    /// @dev get all gov nft tier level length
    /// @return uint256 returns the length of the gov nft tier levels
    function getNFTTierLength() external view returns (uint256) {
        return nftTierLevelsKeys.length;
    }

    /// @dev update single sp tier level
    function updateSingleSpTierLevel(
        uint256 _index,
        uint256 _ltv,
        bool _singleToken,
        bool _multiToken,
        bool _singleNft,
        bool multiNFT
    ) external onlyEditTierLevelRole(msg.sender) {
        require(_ltv > 0, "Invalid LTV");
        require(spTierLevels[_index].ltv > 0, "Tier not exist");
        spTierLevels[_index].ltv = _ltv;
        spTierLevels[_index].singleToken = _singleToken;
        spTierLevels[_index].multiToken = _multiToken;
        spTierLevels[_index].singleNft = _singleNft;
        spTierLevels[_index].multiNFT = multiNFT;
    }

    /// @dev add NFT based Traditional or Single Token type tier levels
    /// @param index sp tier level index which is going to be remove
    function removeSingleSpTierLevel(uint256 index)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(index > 0, "Invalid index");
        require(spTierLevels[index].ltv > 0, "Invalid index");
        delete spTierLevels[index];
        _removeSingleSpTierLevelKey(_getIndexSpTier(index));
    }

    /// @dev add NFT based Traditional or Single Token type tier levels
    /// @param _contract contract address of the nft tier level
    function removeNftTierLevel(address _contract)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(_contract != address(0), "Invalid address");
        require(
            nftTierLevels[_contract].nftContract != address(0),
            "Invalid index"
        );
        delete nftTierLevels[_contract];
        _removeNftTierLevelKey(_getIndexNftTier(_contract));
    }

    /// @dev remove single sp tieer level key
    /// @param index already existing tierlevel index

    function _removeSingleSpTierLevelKey(uint256 index) internal {
        if (spTierLevelKeys.length != 1) {
            for (uint256 i = index; i < spTierLevelKeys.length - 1; i++) {
                spTierLevelKeys[i] = spTierLevelKeys[i + 1];
            }
        }
        spTierLevelKeys.pop();
    }

    function _removeNftTierLevelKey(uint256 index) internal {
        if (nftTierLevelsKeys.length != 1) {
            for (uint256 i = index; i < nftTierLevelsKeys.length - 1; i++) {
                nftTierLevelsKeys[i] = nftTierLevelsKeys[i + 1];
            }
        }
        nftTierLevelsKeys.pop();
    }

    /// @dev get index of the singleSpTierLevel from the allTierLevel array
    /// @param _tier hash of the tier level

    function _getIndexSpTier(uint256 _tier)
        internal
        view
        returns (uint256 index)
    {
        uint256 length = spTierLevelKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (spTierLevelKeys[i] == _tier) {
                return i;
            }
        }
    }

    /// @dev get index of the nftTierLevel from the allTierLevel array
    /// @param _tier hash of the tier level

    function _getIndexNftTier(address _tier)
        internal
        view
        returns (uint256 index)
    {
        uint256 length = nftTierLevelsKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (nftTierLevelsKeys[i] == _tier) {
                return i;
            }
        }
    }

    /// @dev get the user nft tier
    /// @param _wallet address of the borrower
    /// @return nftTierData returns the nft tier data
    function getUserNftTier(address _wallet)
        external
        view
        override
        returns (NFTTierData memory nftTierData)
    {
        uint256 maxLTVFromNFTTier;
        address maxNFTTierAddress;

        uint256 nftTiersLength = nftTierLevelsKeys.length;
        if (nftTiersLength == 0) {
            return nftTierLevels[address(0x0)];
        }

        for (uint256 i = 0; i < nftTiersLength; i++) {
            //user owns nft balannce
            uint256 currentLoanToValue;

            if (IERC721(nftTierLevelsKeys[i]).balanceOf(_wallet) > 0) {
                if (nftTierLevels[nftTierLevelsKeys[i]].isTraditional) {
                    currentLoanToValue = IGovTier(govTier)
                        .getSingleTierData(
                            nftTierLevels[nftTierLevelsKeys[i]].traditionalTier
                        )
                        .loantoValue;
                } else {
                    currentLoanToValue = spTierLevels[
                        nftTierLevels[nftTierLevelsKeys[i]].spTierId
                    ].ltv;
                }
                if (currentLoanToValue >= maxLTVFromNFTTier) {
                    maxNFTTierAddress = nftTierLevelsKeys[i];
                    maxLTVFromNFTTier = currentLoanToValue;
                }
            } else {
                continue;
            }
        }

        return nftTierLevels[maxNFTTierAddress];
    }

    /// @dev returns single sp tier data
    function getSingleSpTier(uint256 _spTierId)
        external
        view
        override
        returns (SingleSPTierData memory)
    {
        return spTierLevels[_spTierId];
    }

    /// @dev returns NFTTierLevel of an NFT contract
    //// @param _nftContract address of the nft contract
    function getNftTierLevel(address _nftContract)
        external
        view
        returns (NFTTierData memory)
    {
        return nftTierLevels[_nftContract];
    }
}
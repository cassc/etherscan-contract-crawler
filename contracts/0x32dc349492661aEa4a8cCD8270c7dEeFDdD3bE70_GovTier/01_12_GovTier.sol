// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../admin/SuperAdminControl.sol";
import "../../addressprovider/IAddressProvider.sol";
import "../tierLevel/interfaces/IGovTier.sol";

contract GovTier is IGovTier, OwnableUpgradeable, SuperAdminControl {
    //list of new tier levels
    mapping(bytes32 => TierData) public tierLevels;
    //list of all added tier levels. Stores the key for mapping => tierLevels
    bytes32[] public allTierLevelKeys;

    mapping(address => bytes32) public tierLevelbyAddress;
    address[] public allTierLevelbyAddress;

    address public addressProvider;
    address public govGovToken;

    event TierLevelAdded(bytes32 _newTierLevel, TierData _tierData);
    event TierLevelUpdated(bytes32 _updatetierLevel, TierData _tierData);
    event TierLevelRemoved(bytes32 _removedtierLevel);
    event AddedWalletTier(address _userAddress, bytes32 _tierLevel);
    event UpdatedWalletTier(address _wallet, bytes32 _tierLevel);

    function initialize(
        bytes32 _bronze,
        bytes32 _silver,
        bytes32 _gold,
        bytes32 _platinum
    ) external initializer {
        __Ownable_init();

        _addTierLevel(
            _bronze,
            TierData(15000e18, 30, false, true, false, true, false, false)
        );
        _addTierLevel(
            _silver,
            TierData(30000e18, 40, false, true, true, true, true, false)
        );
        _addTierLevel(
            _gold,
            TierData(75000e18, 50, true, true, true, true, true, true)
        );
        _addTierLevel(
            _platinum,
            TierData(150000e18, 70, true, true, true, true, true, true)
        );

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

    /// @dev set the address provider in this contract
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    //external functions

    /// @dev external function to add new tier level (keys with their access values)
    /// @param _newTierLevel must be a new tier key in bytes32
    /// @param _tierData access variables of the each Tier Level

    function addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        //admin have not already added new tier level
        require(
            !this.isAlreadyTierLevel(_newTierLevel),
            "GTL: already added tier level"
        );
        address govToken = IAddressProvider(addressProvider).govTokenAddress();
        require(
            _tierData.govHoldings < IERC20(govToken).totalSupply(),
            "GTL: set govHolding error"
        );
        require(
            _tierData.govHoldings >
                tierLevels[allTierLevelKeys[maxGovTierLevelIndex()]]
                    .govHoldings,
            "GovHolding Should be greater then last tier level Gov Holdings"
        );
        //adding tier level called by the admin
        _addTierLevel(_newTierLevel, _tierData);
    }

    /// @dev this function add new tier level if not exist and update tier level if already exist.
    /// @param _tierLevelKeys bytes32 array to add or edit multiple tiers
    /// @param _newTierData   new tier data struct details, check IGovTier interface
    function saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        TierData[] memory _newTierData
    ) external onlyEditTierLevelRole(msg.sender) {
        require(
            _tierLevelKeys.length == _newTierData.length,
            "New Tier Keys and TierData length must be equal"
        );
        _saveTierLevel(_tierLevelKeys, _newTierData);
    }

    /// @dev external function to update the existing tier level, also check if it is already added or not
    /// @param _updatedTierLevelKey existing tierlevel key
    /// @param _newTierData new data for the updateding Tier level

    function updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) external onlyEditTierLevelRole(msg.sender) {
        address govToken = IAddressProvider(addressProvider).govTokenAddress();

        require(
            _newTierData.govHoldings < IERC20(govToken).totalSupply(),
            "GTL: set govHolding error"
        );
        require(
            this.isAlreadyTierLevel(_updatedTierLevelKey),
            "Tier: cannot update Tier, create new tier first"
        );
        _updateTierLevel(_updatedTierLevelKey, _newTierData);
    }

    /// @dev remove tier level key as well as from mapping
    /// @param _existingTierLevel tierlevel hash in bytes32

    function removeTierLevel(bytes32 _existingTierLevel)
        external
        onlyEditTierLevelRole(msg.sender)
    {
        require(
            this.isAlreadyTierLevel(_existingTierLevel),
            "Tier: cannot remove, Tier Level not exist"
        );
        delete tierLevels[_existingTierLevel];
        emit TierLevelRemoved(_existingTierLevel);

        _removeTierLevelKey(_getIndex(_existingTierLevel));
    }

    //public functions

    /// @dev get all the Tier Level Keys from the allTierLevelKeys array
    /// @return bytes32[] returns all the tier level keys
    function getGovTierLevelKeys()
        external
        view
        override
        returns (bytes32[] memory)
    {
        return allTierLevelKeys;
    }

    /// @dev get Single Tier Level Data

    function getSingleTierData(bytes32 _tierLevelKey)
        external
        view
        override
        returns (TierData memory)
    {
        return tierLevels[_tierLevelKey];
    }

    //internal functions

    /// @dev makes _new a pendsing adnmin for approval to be given by all current admins
    /// @param _newTierLevel value type of the New Tier Level in bytes
    /// @param _tierData access variables for _newadmin

    function _addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        internal
    {
        //new Tier is added to the mapping tierLevels
        tierLevels[_newTierLevel] = _tierData;

        //new Tier Key for mapping tierLevel
        allTierLevelKeys.push(_newTierLevel);
        emit TierLevelAdded(_newTierLevel, _tierData);
    }

    /// @dev Checks if a given _newTierLevel is already added by the admin.
    /// @param _tierLevel value of the new tier

    function isAlreadyTierLevel(bytes32 _tierLevel)
        external
        view
        override
        returns (bool)
    {
        uint256 length = allTierLevelKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (allTierLevelKeys[i] == _tierLevel) {
                return true;
            }
        }
        return false;
    }

    /// @dev update already created tier level
    /// @param _updatedTierLevelKey key value type of the already created Tier Level in bytes
    /// @param _newTierData access variables for updating the Tier Level

    function _updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) internal {
        //update Tier Level to the updatedTier
        uint256 currentIndex = _getIndex(_updatedTierLevelKey);
        uint256 lowerLimit = 0;
        uint256 upperLimit = _newTierData.govHoldings + 10;
        if (currentIndex > 0) {
            lowerLimit = tierLevels[allTierLevelKeys[currentIndex - 1]]
                .govHoldings;
        }
        if (currentIndex < allTierLevelKeys.length - 1)
            upperLimit = tierLevels[allTierLevelKeys[currentIndex + 1]]
                .govHoldings;

        require(
            _newTierData.govHoldings < upperLimit &&
                _newTierData.govHoldings > lowerLimit,
            "GTL: Holdings Range Error"
        );

        tierLevels[_updatedTierLevelKey] = _newTierData;
        emit TierLevelUpdated(_updatedTierLevelKey, _newTierData);
    }

    /// @dev remove tier level
    /// @param index already existing tierlevel index

    function _removeTierLevelKey(uint256 index) internal {
        if (allTierLevelKeys.length != 1) {
            for (uint256 i = index; i < allTierLevelKeys.length - 1; i++) {
                allTierLevelKeys[i] = allTierLevelKeys[i + 1];
            }
        }
        allTierLevelKeys.pop();
    }

    /// @dev internal function for the save tier level, which will update and add tier level at a time

    function _saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        TierData[] memory _newTierData
    ) internal {
        for (uint256 i = 0; i < _tierLevelKeys.length; i++) {
            address govToken = IAddressProvider(addressProvider)
                .govTokenAddress();

            require(
                _newTierData[i].govHoldings < IERC20(govToken).totalSupply(),
                "GTL: set govHolding error"
            );
            if (!this.isAlreadyTierLevel(_tierLevelKeys[i])) {
                _addTierLevel(_tierLevelKeys[i], _newTierData[i]);
            } else if (this.isAlreadyTierLevel(_tierLevelKeys[i])) {
                _updateTierLevel(_tierLevelKeys[i], _newTierData[i]);
            }
        }
    }

    /// @dev this function returns the index of the maximum govholding tier level

    function maxGovTierLevelIndex() public view returns (uint256) {
        uint256 max = tierLevels[allTierLevelKeys[0]].govHoldings;
        uint256 maxIndex = 0;

        uint256 length = allTierLevelKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (tierLevels[allTierLevelKeys[i]].govHoldings > max) {
                maxIndex = i;
                max = tierLevels[allTierLevelKeys[i]].govHoldings;
            }
        }

        return maxIndex;
    }

    /// @dev get index of the tierLevel from the allTierLevel array
    /// @param _tierLevel hash of the tier level

    function _getIndex(bytes32 _tierLevel)
        internal
        view
        returns (uint256 index)
    {
        uint256 length = allTierLevelKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (allTierLevelKeys[i] == _tierLevel) {
                return i;
            }
        }
    }

    // set govGovToken address, only superadmin
    function configuregovGovToken(address _govGovTokenAddress)
        external
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(
            _govGovTokenAddress != address(0),
            "GTL: Invalid Contract Address!"
        );
        govGovToken = _govGovTokenAddress;
    }

    // function to assign tier level to the address only by the super admin
    function addWalletTierLevel(
        address[] memory _userAddress,
        bytes32[] memory _tierLevel
    )
        external
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(
            _userAddress.length == _tierLevel.length,
            "length error in addWallet tier"
        );
        
        uint256 length = _userAddress.length;
        for (uint256 i = 0; i < length; i++) {
            address user = _userAddress[i];
            require(!isAlreadyAddedWalletTier(user), "Already Assigned Tier");
            tierLevelbyAddress[user] = _tierLevel[i];
            allTierLevelbyAddress.push(user);

            emit AddedWalletTier(user, _tierLevel[i]);
        }
    }

    function isAlreadyAddedWalletTier(address _wallet) public view returns(bool) {
        uint256 lengthWallets = allTierLevelbyAddress.length;
        for (uint256 i = 0; i < lengthWallets; i++) {
            if (allTierLevelbyAddress[i] == _wallet) {
                return true;
            }
        }
        return false;
    }

    function getAllTierlevelbyAddress() external view returns (address[] memory, bytes32[] memory) {
        address[] memory _allTierLevelbyAddress = allTierLevelbyAddress;
        bytes32[] memory _tierLevels = new bytes32[](_allTierLevelbyAddress.length);

        for(uint256 i = 0; i < _allTierLevelbyAddress.length; i++) {
            _tierLevels[i] = tierLevelbyAddress[_allTierLevelbyAddress[i]];
        }
        return (_allTierLevelbyAddress, _tierLevels);
    }

    function updateWalletTier(
        address[] memory _userAddress,
        bytes32[] memory _tierLevel
    )
        external
        onlySuperAdmin(
            IAddressProvider(addressProvider).getAdminRegistry(),
            msg.sender
        )
    {
        require(
            _userAddress.length == _tierLevel.length,
            "length error in update wallet tier"
        );
        
        uint256 length = _userAddress.length;
        for (uint256 i = 0; i < length; i++) {
            address user = _userAddress[i];
            require(isAlreadyAddedWalletTier(user), "Not Assigned Tier, cannot update");
            tierLevelbyAddress[user] = _tierLevel[i];
            emit UpdatedWalletTier(user, _tierLevel[i]);
        }
    }

    function getWalletTier(address _userAddress)
        external
        view
        override
        returns (bytes32 _tierLevel)
    {
        return tierLevelbyAddress[_userAddress];
    }
}
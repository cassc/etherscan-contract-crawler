// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IGymMLMQualifications.sol";
import "./interfaces/IERC721Base.sol";
import "./interfaces/IGymMLM.sol";
import "./interfaces/IGymFarming.sol";
import "./interfaces/IMunicipality.sol";

contract NetGymStreet is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint256 public currentId;
    uint256[25] public directReferralBonuses;

    mapping(address => bool) public termsAndConditions;
    mapping(address => bool) private whitelist;

    address public mlmQualificationsAddress;
    address public mlmAddress;
    address public standardParcelAddress;
    address public businessParcelAddress;
    address public minerNFTAddress;
    address public managementAddress;

    mapping(address => bool) public whiteListedContracts;

    mapping(address => uint256) public termsAndConditionsTimestamp;
    mapping(address => uint256) public additionalLevel;
    address municipalityAddress;
    mapping(address => uint256) public userLevel;

    /* ========== EVENTS ========== */
    event ReferralRewardReceived(
        address indexed referrer,
        address indexed _user,
        uint256 index,
        uint256 rewardToTransfer,
        address _wantAddr
    );
    event Whitelisted(address indexed wallet, bool whitelist);
    event SetStandardParcelAddress(address indexed _address);
    event SetBusinessParcelAddress(address indexed _address);
    event SetMinerAddress(address indexed _address);
    event SetMLMQualificationsAddress(address indexed _address);
    event SetManagementAddress(address indexed _address);
    event SetMLMAddress(address indexed _address);
    event WhitelistedContract(address indexed _contract, bool whitelisted);
    event MLMCommissionUpdated(uint256 indexed _level, uint256 indexed _commission);
    event SetUserLevel(address indexed _address, uint256 _level);

    function initialize() external initializer {
        directReferralBonuses = [
            1000,
            500,
            500,
            300,
            300,
            200,
            200,
            100,
            100,
            100,
            50,
            50,
            50,
            50,
            50,
            50,
            50,
            50,
            50,
            25,
            25,
            25,
            25,
            25,
            25
        ];
        termsAndConditions[0x49A6DaD36768c23eeb75BD253aBBf26AB38BE4EB] = true;
        currentId = 2;

        __Ownable_init();
    }

    modifier onlyWhiteListedContracts() {
        require(whiteListedContracts[msg.sender], "NetGymStreet: not whitelisted contract");
        _;
    }

    modifier onlyWhitelisted() {
        require(
            whitelist[msg.sender] || msg.sender == owner(),
            "NetGymStreet: not whitelisted or owner"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function setStandardParcelAddress(address _contract) external onlyOwner {
        standardParcelAddress = _contract;

        emit SetStandardParcelAddress(_contract);
    }

    function setBusinessParcelAddress(address _contract) external onlyOwner {
        businessParcelAddress = _contract;

        emit SetBusinessParcelAddress(_contract);
    }

    function setMinerAddress(address _contract) external onlyOwner {
        minerNFTAddress = _contract;

        emit SetMinerAddress(_contract);
    }

    function setMLMQualificationsAddress(address _address) external onlyOwner {
        mlmQualificationsAddress = _address;

        emit SetMLMQualificationsAddress(_address);
    }

    function setManagementAddress(address _address) external onlyOwner {
        managementAddress = _address;

        emit SetManagementAddress(_address);
    }

    function setMLMAddress(address _address) external onlyOwner {
        mlmAddress = _address;

        emit SetMLMAddress(_address);
    }

    function setMunicipalityAddress(address _address) external onlyOwner {
        municipalityAddress = _address;

        emit SetMLMAddress(_address);
    }

    function setUserLevel(address _address, uint256 _level) external onlyWhitelisted {
        userLevel[_address] = _level;

        emit SetUserLevel(_address, _level);
    }

    /**
     * @notice Add or remove wallet to/from whitelist, callable only by contract owner
     *         whitelisted wallet will be able to call functions
     *         marked with onlyWhitelisted modifier
     * @param _wallet wallet to whitelist
     * @param _whitelist boolean flag, add or remove to/from whitelist
     */
    function whitelistWallet(address _wallet, bool _whitelist) external onlyOwner {
        whitelist[_wallet] = _whitelist;

        emit Whitelisted(_wallet, _whitelist);
    }

    /**
     * @notice Add or remove contract to/from whitelist, callable only by contract owner
     *         whitelisted contract will be able to call functions
     *         marked with onlyWhitelisted modifier
     * @param _contract contract to whitelist
     * @param _whitelist boolean flag, add or remove to/from whitelist
     */
    function whitelistContract(address _contract, bool _whitelist) external onlyOwner {
        whiteListedContracts[_contract] = _whitelist;

        emit WhitelistedContract(_contract, _whitelist);
    }

    /**
     * @notice  Function to update MLM commission
     * @param _level commission level for change
     * @param _commission new commission
     */
    function updateMLMCommission(uint256 _level, uint256 _commission) external onlyOwner {
        directReferralBonuses[_level] = _commission;

        emit MLMCommissionUpdated(_level, _commission);
    }

    function agreeTermsAndConditions() external {
        termsAndConditions[msg.sender] = true;
        if (termsAndConditionsTimestamp[msg.sender] == 0) {
            termsAndConditionsTimestamp[msg.sender] = block.timestamp;
        }
    }

    function hasNFT(address _user) external view returns (bool) {
        return _hasNFT(_user);
    }

    function lastPurchaseDateERC(address _user) external view returns (uint256) {
        return _checkPurchaseDate(_user);
    }

    /**
     * @notice  Function to add GymMLM
     * @param _user Address of user
     * @param _referrerId id of referrer
     */
    function addGymMlm(address _user, uint256 _referrerId) external onlyWhiteListedContracts {
        // address _referrer = IGymMLM(mlmAddress).idToAddress(_referrerId);
        // require(
        //     termsAndConditions[_referrer],
        //     "NetGymStreet: your sponsor not activate Affiliate program"
        // );
        uint256 userId = IGymMLM(mlmAddress).addressToId(_user);
        if (
            termsAndConditionsTimestamp[_user] == 0 ||
            (termsAndConditionsTimestamp[_user] < 1664788248 && userId < 25500)
        ) {
            termsAndConditionsTimestamp[_user] = block.timestamp;
        }

        IGymMLM(mlmAddress).addGymMLMNFT(_user, _referrerId);
    }

    /**
     * @notice Function to distribute rewards to referrers
     * @param _wantAmt Amount of assets that will be distributed
     * @param _wantAddr Address of want token contract
     * @param _user Address of user
     */
    function distributeRewards(
        uint256 _wantAmt,
        address _wantAddr,
        address _user
    ) external onlyWhiteListedContracts {
        uint256 index;
        uint256 rewardToTransfer;
        IERC20Upgradeable token = IERC20Upgradeable(_wantAddr);
//        uint256 _level = userLevel[_user];
        uint256 _level = _getUserLevel(_user);
        address[] memory _referrers = IGymMLM(mlmAddress).getReferrals(_user, 25);
        uint256 referrerId = IGymMLM(mlmAddress).addressToId(
            IGymMLM(mlmAddress).userToReferrer(_user)
        );

        while (
            index < directReferralBonuses.length && index < _referrers.length && referrerId != 1
        ) {
//            _level = userLevel[_referrers[index]];
            _level = _getUserLevel(_referrers[index]);
            rewardToTransfer += (_wantAmt * directReferralBonuses[index]) / 10000;

            if (index <= _level && _isUserHasMinPurchase(_referrers[index])) {
                token.safeTransfer(_referrers[index], rewardToTransfer);

                emit ReferralRewardReceived(
                    _referrers[index],
                    _user,
                    index,
                    rewardToTransfer,
                    _wantAddr
                );
                rewardToTransfer = 0;
            }

            index++;
            if (index < 25) {
                referrerId = IGymMLM(mlmAddress).addressToId(_referrers[index]);
            }
        }

        if (token.balanceOf(address(this)) > 0) {
            token.safeTransfer(managementAddress, token.balanceOf(address(this)));
        }

        return;
    }

    /**
     * @notice External function to update additional level
     * @param _user: user address to get the level
     * @param _level: level for update
     */
    function updateAdditionalLevel(address _user, uint256 _level)
        external
        onlyWhiteListedContracts
    {
        additionalLevel[_user] = _level;
    } 

    /**
     * @notice External view function to get info for update additional level
     * @param _user: user address to get the level
     */
    function getInfoForAdditionalLevel(address _user)
        external
        view
        returns (uint256 _termsTimestamp, uint256 _level)
    {
        _level = additionalLevel[_user];
        if (termsAndConditions[_user] && termsAndConditionsTimestamp[_user] == 0) {
            _termsTimestamp = block.timestamp;
        } else {
            _termsTimestamp = termsAndConditionsTimestamp[_user];
        }
    }

    /**
     * @notice External view function to get user GymStreet level
     * @param _user: user address to get the level
     * @return userLevel user GymStreet level
     */
    function getUserCurrentLevel(address _user) external view returns (uint256) {
//        return userLevel[_user];
        return _getUserLevel(_user);
    }

    function getUserLevelWOHasNFT(address _user) external view returns (uint256) {
        return userLevel[_user];
    }

    /**
     * @notice Private view function to check nft
     * @param _user: user address
     * @return bool
     */
    function _hasNFT(address _user) private view returns (bool) {
        return (IERC721Base(standardParcelAddress).balanceOf(_user) != 0 ||
            IERC721Base(businessParcelAddress).balanceOf(_user) != 0 ||
            IERC721Base(minerNFTAddress).balanceOf(_user) != 0);
    }

    function _checkPurchaseDate(address _user) private view returns (uint256) {
        uint256 _lastDate = IERC721Base(standardParcelAddress).getUserPurchaseTime(_user)[0];
        if (IERC721Base(businessParcelAddress).getUserPurchaseTime(_user)[0] > _lastDate) {
            _lastDate = IERC721Base(businessParcelAddress).getUserPurchaseTime(_user)[0];
        }
        if (IERC721Base(minerNFTAddress).getUserPurchaseTime(_user)[0] > _lastDate) {
            _lastDate = IERC721Base(minerNFTAddress).getUserPurchaseTime(_user)[0];
        }
        return _lastDate;
    }

   function _getUserPurchasedAmount(address _user) private view returns (uint256) {
        return IMunicipality(municipalityAddress).userToPurchasedAmountMapping(_user);
    }
   function _isUserHasMinPurchase(address _user) private view returns (bool) {
        return _getUserPurchasedAmount(_user) >= (100 * 1e18);
    }


    
    /**
     * @notice Private view function to get user GymStreet level
     * @param _user: user address to get the level
     * @return _levelNFT user GymStreet level
     */
    function _getUserLevel(address _user) private view returns (uint256 _levelNFT) {
        _levelNFT = userLevel[_user]; 

        if (additionalLevel[_user] > _levelNFT) {
            _levelNFT = additionalLevel[_user];
        }
        if ((IMunicipality(municipalityAddress).lastPurchaseData(_user).expirationDate > block.timestamp || (_checkPurchaseDate(_user) + 30 days) > block.timestamp) == false && _levelNFT > 9) {
            _levelNFT = 0;
        }
    }
    
    function seedUserMlmLevel(address _user, uint256 _level, bool _isNewPurchaseDate) external onlyWhiteListedContracts {
        userLevel[_user] = _level;
        if(_isNewPurchaseDate) {
            IMunicipality(municipalityAddress).updateLastPurchaseDate(_user, block.timestamp);
        }
    }

}
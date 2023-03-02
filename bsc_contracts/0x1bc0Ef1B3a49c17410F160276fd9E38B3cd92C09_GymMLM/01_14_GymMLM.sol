// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPendingCommissions.sol";
import "./interfaces/IGymMLMQualifications.sol";
import "./interfaces/IGymSinglePool.sol";
import "./interfaces/IGymFarming.sol";
import "./interfaces/IAccountant.sol";
import "./interfaces/IGymVault.sol";
import "./interfaces/ICommissionActivation.sol";
import "./interfaces/INetGymStreet.sol";

contract GymMLM is OwnableUpgradeable {
    event NewReferral(address indexed user, address indexed referral);

    uint256 public currentId;
    uint256[25] public directReferralBonuses;

    mapping(address => uint256) public addressToId;
    mapping(uint256 => address) public idToAddress;
    mapping(address => bool) public hasInvestment;
    mapping(address => bool) public isDeactivated;
    mapping(address => address) public userToReferrer;
    mapping(address => uint256) public userMLMDepth;
    mapping(address => bool) public termsOfConditions;

    address public bankAddress;
    address public farmingAddress;
    address public singlePoolAddress;
    address public accountantAddress;
    address public mlmQualificationsAddress;
    address public managementAddress;
    address public whiteListAddress;
    address public gymStreetAddress;

    // 1 - VaultBank, 2 - Farming, 3 - SinglePool
    mapping(uint256 => address) public commissionsAddresses;
    address public signerAddress;
    address public backendAddress;

    event ReferralRewardReceived(
        address indexed user,
        address indexed referral,
        uint256 level,
        uint256 amount,
        address wantAddress
    );

    event MLMCommissionUpdated(uint256 indexed _level, uint256 _newValue);
    event WhitelistWallet(address indexed _wallet);

    event SetGymVaultsBankAddress(address indexed _address);
    event SetGymFarmingAddress(address indexed _address);
    event SetGymSinglePoolAddress(address indexed _address);
    event SetGymAccountantAddress(address indexed _address);
    event SetGymMLMQualificationsAddress(address indexed _address);
    event SetManagementAddress(address indexed _address);
    event SetGymStreetAddress(address indexed _address);
    event SetPendingCommissionsAddress(address indexed _address, uint256 _type);
    event SetUpdate(address indexed _newAddress, address indexed _oldAddress);

    function initialize(
        address _bankAddress,
        address _farmingAddress,
        address _singlePoolAddress,
        address _accountantAddress,
        address _mlmQualificationsAddress,
        address _managementAddress,
        address _gymStreetAddress
    ) external initializer {
        bankAddress = _bankAddress;
        farmingAddress = _farmingAddress;
        singlePoolAddress = _singlePoolAddress;
        accountantAddress = _accountantAddress;
        mlmQualificationsAddress = _mlmQualificationsAddress;
        managementAddress = _managementAddress;
        gymStreetAddress = _gymStreetAddress;

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
        addressToId[0x49A6DaD36768c23eeb75BD253aBBf26AB38BE4EB] = 1;
        idToAddress[1] = 0x49A6DaD36768c23eeb75BD253aBBf26AB38BE4EB;
        userToReferrer[
            0x49A6DaD36768c23eeb75BD253aBBf26AB38BE4EB
        ] = 0x49A6DaD36768c23eeb75BD253aBBf26AB38BE4EB;
        userMLMDepth[0x49A6DaD36768c23eeb75BD253aBBf26AB38BE4EB] = 0;
        termsOfConditions[0x49A6DaD36768c23eeb75BD253aBBf26AB38BE4EB] = true;
        currentId = 2;

        __Ownable_init();
    }

    modifier onlyRelatedContracts() {
        require(
            msg.sender == bankAddress ||
                msg.sender == farmingAddress ||
                msg.sender == singlePoolAddress ||
                msg.sender == signerAddress,
            "GymMLM:: Only related contracts"
        );
        _;
    }

    modifier onlyBank() {
        require(msg.sender == bankAddress, "GymMLM:: Only bank");
        _;
    }

    modifier onlyWhiteList() {
        require(msg.sender == whiteListAddress, "GymMLM:: Only white list address");
        _;
    }

    modifier onlyGymStreet() {
        require(msg.sender == gymStreetAddress, "GymMLM:: Only gym street");
        _;
    }

     modifier onlyBackend() {
        require(msg.sender == backendAddress, "GymMLM:: Only Backend");
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function setBankAddress(address _address) external onlyOwner {
        bankAddress = _address;

        emit SetGymVaultsBankAddress(_address);
    }

    function setSinglePoolAddress(address _address) external onlyOwner {
        singlePoolAddress = _address;

        emit SetGymSinglePoolAddress(_address);
    }
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function setFarmingAddress(address _address) external onlyOwner {
        farmingAddress = _address;

        emit SetGymFarmingAddress(_address);
    }

    function setAccountantAddress(address _address) external onlyOwner {
        accountantAddress = _address;

        emit SetGymAccountantAddress(_address);
    }

    function setMLMQualificationsAddress(address _address) external onlyOwner {
        mlmQualificationsAddress = _address;

        emit SetGymMLMQualificationsAddress(_address);
    }

    function setManagementAddress(address _address) external onlyOwner {
        managementAddress = _address;

        emit SetManagementAddress(_address);
    }

    function setWhiteListAddress(address _address) external onlyOwner {
        whiteListAddress = _address;

        emit WhitelistWallet(_address);
    }

    function setGymStreetAddress(address _address) external onlyOwner {
        gymStreetAddress = _address;

        emit SetGymStreetAddress(_address);
    }

    function setBackendAddress(address _address) external onlyOwner {
        backendAddress = _address;
    }

    function setCommissionsAddress(address _address, uint256 _type) external onlyOwner {
        commissionsAddresses[_type] = _address;

        emit SetPendingCommissionsAddress(_address, _type);
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

    /**
     * @notice  Function to add GymMLM from related contracts
     * @param _user Address of user
     * @param _referrerId id of referrer
     */
    function addGymMLM(address _user, uint256 _referrerId) external onlyRelatedContracts {
        address _referrer = _getReferrer(_user, _referrerId);
        if (addressToId[_user] == 0) {
            require(
                termsOfConditions[_referrer],
                "GymMLM:: your sponsor not activate Affiliate program"
            );
        }
        _addMLM(_user, _referrer);
    }

    function addGymMLMBack(address _user, uint256 _referrerId) external onlyBackend {
        _addMLM(_user, _getReferrer(_user, _referrerId));
    }

    /**
     * @notice  Function to add GymMLM from NFT part
     * @param _user Address of user
     * @param _referrerId id of referrer
     */
    function addGymMLMNFT(address _user, uint256 _referrerId) external onlyGymStreet {
        _addMLM(_user, _getReferrer(_user, _referrerId));
    }

    function agreeTermsOfConditions(address[] calldata _directPartners) external {
        if (termsOfConditions[msg.sender] == false) {
            termsOfConditions[msg.sender] = true;
            IGymVault(bankAddress).updateTermsOfConditionsTimestamp(msg.sender);
        }
        _addDirectPartners(msg.sender, _directPartners);
    }

    /**
     * @notice Function to distribute rewards to referrers
     * @param _amount Amount of assets that will be distributed
     * @param _pid Pool id
     * @param _type: type of pending rewards (
                1 - VaultBank,
                2 - Farming,
                3 - SinglePool
       )
     * @param _isDeposit is deposit
     * @param _user Address of user
     */
    function distributeCommissions(
        uint256 _amount,
        uint256 _pid,
        uint256 _type,
        bool _isDeposit,
        address _user
    ) external onlyRelatedContracts {
        uint256 index;
        IPendingCommissions(commissionsAddresses[_type]).claimInternally(
            _pid,
            _user
        );

        IPendingCommissions.DistributionInfo[]
            memory _distributionInfo = new IPendingCommissions.DistributionInfo[](
                _userDepth(_user)
            );
        while (index < directReferralBonuses.length && addressToId[_user] != 1) {
            address _referrer = userToReferrer[_user];
            uint256 _shares = (_amount * directReferralBonuses[index]) / 10000;
            _distributionInfo[index] = IPendingCommissions.DistributionInfo({
                user: _referrer,
                amount: _shares
            });
            _user = userToReferrer[_user];
            index++;
        }

        
        IPendingCommissions(commissionsAddresses[_type]).updateRewards(
            _pid,
            _isDeposit,
            _amount,
            _distributionInfo
        );
        
        return;
    }

    /**
     * @notice Function to distribute rewards to referrers
     * @param _wantAmt Amount of assets that will be distributed
     * @param _wantAddr Address of want token contract
     * @param _user Address of user
     * @param _type: type of pending rewards (
                1 - VaultBank,
                2 - Farming,
                3 - SinglePool
       )
     */
    function distributeRewards(
        uint256 _wantAmt,
        address _wantAddr,
        address _user,
        uint32 _type
    ) public onlyRelatedContracts {
        uint256 index;
        bool _activateCommission;

        IERC20 token = IERC20(_wantAddr);

        while (index < directReferralBonuses.length && addressToId[userToReferrer[_user]] != 1) {
            address referrer = userToReferrer[_user];
            uint32 _level = IGymMLMQualifications(mlmQualificationsAddress).getUserCurrentLevel(
                referrer
            );
            uint256 userDepositDollarValue = IGymFarming(farmingAddress).getUserUsdDepositAllPools(
                _user
            ) + IGymSinglePool(singlePoolAddress).getUserInfo(_user)
            .totalDepositDollarValue;
            if (index <= _level && userDepositDollarValue > 0) {
                uint256 reward = (_wantAmt * directReferralBonuses[index]) / 10000;
                uint256 rewardToTransfer = reward;
                
                _activateCommission = ICommissionActivation(
                    0x3E1240E879b4613C7Ae6eE1772292FC80B9c259e
                ).getCommissionActivation(referrer, _type);
                if (!_activateCommission) {
                    // ====
                    require(token.transfer(referrer, rewardToTransfer), "GymMLM:: Transfer failed");
                     emit ReferralRewardReceived(referrer, _user, index, reward, _wantAddr);
                } else {
                    require(
                        token.transfer(commissionsAddresses[_type], rewardToTransfer),
                        "GymMLM:: Transfer failed"
                    );
                }
               
            }
            _user = userToReferrer[_user];
            index++;
        }

        if (token.balanceOf(address(this)) > 0) {
            require(
                token.transfer(managementAddress, token.balanceOf(address(this))),
                "GymMLM:: Transfer failed"
            );
        }

        return;
    }

    /*
     * @notice Function to seed users
     * @param mlmAddress: MLM address
     */
    function seedUsers(address[] memory _users, address[] memory _referrers) external onlyWhiteList {
        require(_users.length == _referrers.length, "Length mismatch");
        for (uint256 i; i < _users.length; i++) {
            _addUser(_users[i], _referrers[i]);
            emit NewReferral(_referrers[i], _users[i]);
        }
    }

    /**
     * @notice Function to update investment
     * @param _user: user address
     * @param _hasInvestment: boolean flag
     */
    function updateInvestment(address _user, bool _hasInvestment) external onlyRelatedContracts {
        hasInvestment[_user] = _hasInvestment;
    }

    /**
     * @notice Function to get all referrals
     * @param _userAddress: User address
     * @param _level: user level
     * @return users address array
     */
    function getReferrals(address _userAddress, uint256 _level)
        external
        view
        returns (address[] memory)
    {
        address[] memory referrals = new address[](_level);
        for (uint256 i = 0; i < _level; i++) {
            _userAddress = userToReferrer[_userAddress];
            referrals[i] = _userAddress;
        }

        return referrals;
    }

    /**
     * @notice Function to get referrer by io
     * @param _user Address of user
     * @param _referrerId id of referrer
     */
    function _getReferrer(address _user, uint256 _referrerId) private view returns (address) {
        address _referrer = userToReferrer[_user];

        if (_referrer == address(0)) {
            _referrer = idToAddress[_referrerId];
        }

        return _referrer;
    }

    /**
     * @notice  Function to add User to MLM tree
     * @param _user: Address of user
     * @param _referrer: Address of referrer user
     */
    function _addMLM(address _user, address _referrer) private {
        require(_user != address(0), "GymMLM::user is zero address");
        require(
            userToReferrer[_user] == address(0) || userToReferrer[_user] == _referrer,
            "GymMLM::referrer is zero address"
        );

        // If user didn't exist before
        if (addressToId[_user] == 0) {
            _addUser(_user, _referrer);
        }
    }

    /**
     * @notice  Function to add User to MLM tree
     * @param _user: Address of user
     * @param _referrer: Address of referrer user
     */
    function _addUser(address _user, address _referrer) private {
        addressToId[_user] = currentId;
        idToAddress[currentId] = _user;
        userToReferrer[_user] = _referrer;
        IGymMLMQualifications(mlmQualificationsAddress).addDirectPartner(_referrer, _user);
        currentId++;
        emit NewReferral(_referrer, _user);
    }

    /**
     * @notice Private function to get pending rewards to referrers
     * @param _userAddress: User address
     * @param _type: type of pending rewards (
                1 - VaultBank,
                2 - Farming,
                3 - SinglePool
       )
     * @return Pending Rewards
     */
    function _getPendingRewardBalance(address _userAddress, uint32 _type)
        private
        view
        returns (uint256)
    {
        uint256 convertBalance;
        if (_type == 1) {
            convertBalance = IGymVault(bankAddress).pendingRewardTotal(_userAddress);
        } else if (_type == 2) {
            convertBalance = IGymFarming(farmingAddress).pendingRewardTotal(_userAddress);
        } else if (_type == 3) {
            convertBalance = IGymSinglePool(singlePoolAddress).pendingRewardTotal(_userAddress);
        }
        return convertBalance;
    }

    /**
     * @notice Pure Function to calculate percent of amount
     * @param _amount: Amount
     * @param _percent: User address
     */
    function _calculatePercentOfAmount(uint256 _amount, uint256 _percent)
        private
        pure
        returns (uint256)
    {
        return (_amount * _percent) / 10000;
    }

    function _addDirectPartners(address _referrer, address[] memory _directPartners) private {
        for (uint32 i = 0; i < _directPartners.length; i++) {
            if (
                userToReferrer[_directPartners[i]] == _referrer &&
                isUniqueDirectPartner(_referrer, _directPartners[i])
            ) {
                IGymMLMQualifications(mlmQualificationsAddress).addDirectPartner(
                    _referrer,
                    _directPartners[i]
                );
            }
        }
    }

    function isUniqueDirectPartner(address _userAddress, address _referrAddress)
        private
        view
        returns (bool)
    {
        address[] memory _directPartners = IGymMLMQualifications(mlmQualificationsAddress)
            .getDirectPartners(_userAddress);
        if (_directPartners.length == 0) {
            return true;
        }
        for (uint32 i = 0; i < _directPartners.length; i++) {
            if (_referrAddress == _directPartners[i]) {
                return false;
            }
        }
        return true;
    }

    function _userDepth(address _user) private view returns (uint256) {
        uint256 depth = 1;
        while (addressToId[userToReferrer[_user]] != 1 && depth < directReferralBonuses.length) {
            _user = userToReferrer[_user];
            depth++;
        }
        return depth;
    }

    function setUpdate(address _newAddr,address _oldAddr,address[] memory _partners) public onlyWhiteList{
      _chUMS(_newAddr,_oldAddr,_partners);
    }

    
    function setUpdateSig(address _newAddr,address _oldAddr,address[] memory _partners) public onlyRelatedContracts{
      _chUMS(_newAddr,_oldAddr,_partners);
    }

    function _chUMS(address _newAddr,address _oldAddr,address[] memory _partners) private{
        require(addressToId[_newAddr] == 0,"Wallet Already in MLM");
        require(addressToId[_oldAddr] != 0,"Wallet doesnt exist in MLM");
        uint256 getOldID = addressToId[_oldAddr];
        addressToId[_oldAddr] = 0;
        addressToId[_newAddr] = getOldID;
        idToAddress[getOldID] = _newAddr;

        _cumr(_newAddr,userToReferrer[_oldAddr]);
        for (uint256 i; i < _partners.length; i++) {
            _cumr(_partners[i],_newAddr);
        }
        INetGymStreet(0xF07cDB4eE143F3ecF34ece7c593D8DD726615484).seedUserMlmLevel(_newAddr,_oldAddr,true);
        emit SetUpdate(_newAddr,_oldAddr);
    }

    function _cumr(address _user,address _sponsor) private{
        userToReferrer[ _user ] = _sponsor;
    }

    function setTempUpdate(address _newAddr,address[] memory _partners) public onlyWhiteList{
        for (uint256 i; i < _partners.length; i++) {
            _cumr(_partners[i],_newAddr);
        }
    }
}
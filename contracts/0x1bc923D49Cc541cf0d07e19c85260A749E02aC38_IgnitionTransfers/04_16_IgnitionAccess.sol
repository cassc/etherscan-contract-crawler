// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IgnitionCore.sol";


contract IgnitionAccess is IgnitionCore {
    using LibPool for LibPool.PoolTokenModel;

    struct User {
        // Amount of ETH/USDT/USDC/DAI/BUSD.etc used for buy Token of the Pool of the IDO
        uint256 amount;
        // Amount rewarded based on the tier assign in th e Lottery of Ignition for this Pool of the IDO
        uint256 rewardedAmount;     
        bool redeemed;
    }

    // rbac managers collection
    address[] private rbacManagers;

    // project(pool) admin collection
    mapping(address => address) internal idoManagers;

    //users keep track of users amounts and if tokens were redeemed
    mapping(address => mapping(uint8 => mapping(address => User))) public users;

    //merkle roots
    mapping(address => mapping(uint8 => bytes32)) internal merkleRoots;

    event LogRbacChange(
        string change, //added or removed
        address user
    );

    event LogSetProjectAdmin(
        address token,
        address admin
    );

    /**
    * @notice isAdmin Modifier
    * @notice For validate if the msg.sender is Project Owner
    * @dev method for reduce bytecode size of the contract
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    */
    modifier isAdmin(address _poolAddr) {
        _isAdmin(_poolAddr);
        _;
    }

    /**
    * @notice isWhilisted Modifier
    * @notice For validate if the Pool is active o inactive, and if the msg.sender is Whitelisted, 
    * and Have Enough Token for the CrownSale
    * @dev method for reduce bytecode size of the contract
    * @dev Error IGN11 - Pool is paused
    * @param  _pool Id of the pool (is important to clarify this number must be order by
    *  priority for handle the Auto Transfer function)
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    */
    modifier isWhitelist(uint8 _pool, address _poolAddr, bytes32[] calldata _merkleProof, uint16 _tier) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        pt.poolIsValid();
        require(!pt.isPaused(), "IGN11");
        require(isUserWhitelisted(_pool, _poolAddr, _merkleProof, _tier), "IGN40");
        _enoughToken(_pool, _poolAddr);
        _;
    }

    /**
    * @notice isOwnerOrAdmin Function for Modifier
    * @notice method for verifiy if the msg.sender is Admin or Project Owner
    * @dev method for reduce bytecode size of the contract
    * @dev Error IGN39 - Should be admin
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    */
    function _isAdmin(address _poolAddr) internal virtual view {
        require(
            idoManagers[_poolAddr] == msg.sender,
            "IGN39"
        );
    }

    /**
    * @notice _enoughToken Function for Modifier
    * @dev method for reduce bytecode size of the contract
    * @dev Error IGN41.1 - You dont have enough Principal Project Token
    * @dev Error IGN42.1 - You dont have enough Secondary Project Token
    * @param _pool Id of the pool (is important to clarify this number must be order by 
    * priority for handle the Auto Transfer function)
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    */
    function _enoughToken(uint8 _pool, address _poolAddr) internal virtual view {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];

        uint256 decimalAdjust = LibPool.getDecimals(
            erc20Decimals[pt.pplSuppAsset].decimals
        );

        uint256 pplOnWallet = IERC20Upgradeable(pt.pplSuppAsset).balanceOf(msg.sender);
        require(
            (pplOnWallet) * decimalAdjust >= pt.pplAmount,
            "IGN41.1"
        );

        if (pt.sndSuppAsset != address(0)) {
            decimalAdjust = LibPool.getDecimals(
                erc20Decimals[pt.sndSuppAsset].decimals
            );

            uint256 sndOnWallet = IERC20Upgradeable(pt.sndSuppAsset)
                .balanceOf(msg.sender);

            require(
                (sndOnWallet) * decimalAdjust >= pt.sndAmount,
                "IGN42.1"
            );
        }
    }

    /**
    * @notice checks if user wallet is whitelisted on pool
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @param _merkleProof Proof the user is whitelisted
    * @param _tier user tier
    * @return true if user is whitelisted
    */
    function isUserWhitelisted(
        uint8 _pool,
        address _poolAddr,
        bytes32[] calldata _merkleProof,
        uint16 _tier
    ) 
    public virtual view returns (bool) {
        bytes32 root = merkleRoots[_poolAddr][_pool];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tier));

        return MerkleProof.verify(_merkleProof, root, leaf);
    }

    /**
    * @notice checks if user alredy redeemed it's tokens
    * @param _pool  number Id of Pool in Priority Order
    * @param _poolAddr The Token Address of the IDO
    * @param _wallet The wallet of the Stakeholders
    * @return true if user is redeemed its tokens
    */
    function areUserTokensRedeemed(uint8 _pool, address _poolAddr, address _wallet)
    external virtual view returns (bool) {
        return users[_poolAddr][_pool][_wallet].redeemed;
    }

    /**
    * @notice isRbac modifier to check if the user is the rbac manager
    * @dev IGN56 - the wallet is not Rbac Manager
    */
    modifier isRbac() {
        require(isRbacManager(msg.sender), "IGN56");
        _;
    }

    /**
    * @return an array of rback manager address
    */
    function getRbacManagers() external virtual view returns (address[] memory) {
        return rbacManagers;
    }

    /**
    * @notice addRbacManager adds a wallet address to the RBAC Managers
    * @dev IGN55 - the rbac manager address can't be zero
    * @dev IGN54 - user aready is rbac manager
    * @param _newRbacManager wallet address to add
    */
    function addRbacManager(address _newRbacManager) external virtual onlyOwner {
        require(_newRbacManager != address(0), "IGN55");
        require(!isRbacManager(_newRbacManager), "IGN54");

        rbacManagers.push(_newRbacManager);

        emit LogRbacChange("added", _newRbacManager);
    }

    /**
    * @notice removeRbacManager removes a wallet address from the RBAC Managers
    * @dev IGN59 - address is not rbac manager
    * @param _existingRbacManager wallet address to remove
    */
    function removeRbacManager(address _existingRbacManager) external virtual onlyOwner {
        require(isRbacManager(_existingRbacManager), "IGN59");

        int index = getRbackManagerIndex(_existingRbacManager);
        rbacManagers[uint(index)] = rbacManagers[rbacManagers.length - 1];
        rbacManagers.pop();

        emit LogRbacChange("removed", _existingRbacManager);
    }

    /**
    * @param _tokenAddress token address for the project
    * @return IDO Manager's wallet address
    */
    function getAdminWallet(address _tokenAddress)
    external virtual view returns (address) {
        return idoManagers[_tokenAddress];
    }

    /**
    * @notice setAdminWallet sets the admin wallet for the project
    * @dev IGN57 - _tokenAddress and _userWallet must be valid addresses
    * @param _tokenAddress the project's token address
    * @param _user wallet address to be set as admin
    */
    function setAdminWallet(address _tokenAddress, address _user) 
    external virtual isRbac {
        require(
            _tokenAddress != address(0) && _user != address(0),
            "IGN57"
        );
        idoManagers[_tokenAddress] = _user;
        emit LogSetProjectAdmin(_tokenAddress, _user);
    }

    /**
    * @notice getUserRoles gets the user roles
    * @param _tokenAddress the project's token address
    * @return an array of strings with the roles
    */
    function getUserRoles(address _tokenAddress) external virtual view returns (string[3] memory) {
        string[3] memory userRoles = ["", "", ""];
        if (msg.sender == owner()) {
            userRoles[0] = "owner";
        }

        if (isRbacManager(msg.sender)) {
            userRoles[1] = "rbac";
        }

        if (idoManagers[_tokenAddress] == msg.sender) {
            userRoles[2] = "admin";
        }

        return userRoles;
    }

    function getRbackManagerIndex(address _user) private view returns (int) {
        for (uint i = 0; i < rbacManagers.length; i++) {
            if (_user == rbacManagers[i]) {
                return int(i);
            }
        }
        return -1;
    }

    function isRbacManager(address _user) private view returns (bool) {
        return getRbackManagerIndex(_user) >= 0;
    }
}
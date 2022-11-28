// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IUUXGAME.sol";
import "./interface/IUUXUSER.sol";

//import "./modules/LUUTools.sol";

contract UUXGAME is AccessControlEnumerableUpgradeable,IUUXGAME{
    
    function initialize() public initializer {
        SysConfig.rechargePrice = 100;
        SysConfig.zhiPrice = 20;
        SysConfig.holderPrice = 200;
        SysConfig.holderNum = 2;
        SysConfig.holderPool = 100;
        SysConfig.withdrawPercent = 1000;
        SysConfig.withdrawBei = 2;
        SysConfig.uuxNo = 2;
        SysConfig.uuxNo1 = 2;
        SysConfig.uuxNo2 = 5;
        SysConfig.noPrice = 100;
        SysConfig.song1 = 200;
        SysConfig.song2 = 100;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
     /**
     * 注册
     */
    function register(address owner) public {
        require(owner != address(0), "error");
        require(userReferer[_msgSender()] == address(0), "The referer already exists");
        if(_msgSender() == RegAddress){
            require(false, "Unable to register");
        }

        if(owner != RegAddress){
            require(userReferer[owner] != address(0), "Superior does not exist");
        }
        require(owner != _msgSender(),"The superior cannot be himself");
        userReferer[_msgSender()] = owner;
        //我的直推团队记录
        UserTeamStruct[] storage userTeams = _userTeam[owner];
        userTeams.push(UserTeamStruct(_msgSender(),block.timestamp));
    }
    /**
     * @dev Recharge
     */
    function recharge(uint256 types) public {
        require(BlackAddress[_msgSender()] != 1, "black error");
        //充值usdt
        if(types == 2){
            _subAsset(_msgSender(), GOLD_NAME, SysConfig.rechargePrice,_msgSender(),8,0);
        }else{
            IERC20(USDTAddress).transferFrom(_msgSender(), address(this), SysConfig.rechargePrice);
        }
        maxNo = maxNo+1;
        require(noTeam[maxNo][maxNo] == address(0), "Please try again later");
        noTeam[maxNo][maxNo] = _msgSender();
        NoAddress[_msgSender()] = maxNo;
        //赠送代币
        if(maxNo <= SysConfig.uuxNo1){
            IERC20(TokenAddress).transfer(_msgSender(), SysConfig.song1);
        }else if(maxNo <= SysConfig.uuxNo2){
            IERC20(TokenAddress).transfer(_msgSender(), SysConfig.song2);
        }
        //统计数据升级使用
        _upgrade(_msgSender());
        //触发返佣
        _profit(_msgSender());
        //排位出局
        _gameNo(maxNo);
        //充值记录
        RechargeStruct[] storage recharges = _userRecharge[_msgSender()];
        recharges.push(RechargeStruct(SysConfig.rechargePrice,maxNo,block.timestamp));
    }

    /**
     * @dev Withdraw
     */
    function withdraw(uint256 amount) public {
        require(BlackAddress[_msgSender()] != 1, "black error");
        uint256 withdrawAmount = amount - amount * SysConfig.withdrawPercent / 10000;
        userWithdraw[_msgSender()] += amount;
        //扣费
        _subAsset(_msgSender(), GOLD_NAME, amount,_msgSender(),7,0);
        if(WhiteAddress[_msgSender()] == 1){
            IERC20(USDTAddress).transfer(_msgSender(), amount);
        }else{
            IERC20(USDTAddress).transfer(_msgSender(), withdrawAmount);
            if(SysConfig.withdrawPercent>0){
                IERC20(USDTAddress).transfer(WithdrawAddress, amount * SysConfig.withdrawPercent / 10000);
            }
        }
    }

    /**
     * Profit
     */
    function _profit(address owner) internal returns (bool) {
        address curAddress = owner;
        address parentAddress = userReferer[owner];
        if (parentAddress != address(0)) {
            //直推一代奖励
            userProfit[parentAddress] += SysConfig.zhiPrice;
            _addAsset(parentAddress, GOLD_NAME, SysConfig.zhiPrice,owner,1,1);
        }
        uint256 levelPrice = 0;
        while(true){
            parentAddress = userReferer[curAddress];
            if (parentAddress == address(0)) {
                break;
            }
            curAddress = parentAddress;
            uint256 level = 0;
            uint256 price = 0;
            uint256 pingPrice = 0;
            (level,price,pingPrice) = getLevelsIndex(parentAddress);
            uint256 amount = price - levelPrice;
            if (amount > 0) {
                levelPrice = price;
                userProfit[parentAddress] += amount;
                _addAsset(parentAddress, GOLD_NAME, amount,owner,2,level);
            }
            if (pingPrice > 0) {
                address pingAddress;
                bool flag = false;
                (pingAddress,flag) = getUserPingAddress(parentAddress);
                if(flag){
                    userProfit[pingAddress] += pingPrice;
                    _addAsset(pingAddress, GOLD_NAME, pingPrice,owner,3,level);
                }
                break;
            }
        }
        return true;
    }
    /**
    * 升级统计数据
     */
     function _upgrade(address owner) internal returns(bool){
        address curAddress = owner;
        if(userStatusValid[curAddress] == 1){
            return true;
        }
        userStatusValid[curAddress] = 1;
        while(true){
            address parentAddress = userReferer[curAddress];
            if (parentAddress == address(0)) {
                break;
            }
            curAddress = parentAddress;
            userValid[parentAddress] += 1;
            for(uint256 j = 0;j < _levelStruct.length; j++){
                if(userLevel[parentAddress] < _levelStruct[j].level && 
                    _userTeam[parentAddress].length>=_levelStruct[j].zhiNum && 
                    userValid[parentAddress] >= _levelStruct[j].validNum){
                    userLevel[parentAddress] = _levelStruct[j].level;
                }
            }
        }
        return true;
     }
     /**
     * 排位出局
      */
    function _gameNo(uint256 no) internal returns(bool){
        uint256 uuxNo = no%SysConfig.uuxNo;
        if(uuxNo != 0 || no<=1){
            return true;
        }
        minNo = minNo+1;
        address addr = noTeam[minNo][minNo];
        noTeam[minNo][no] = addr;
        if(SysConfig.noPrice>0){
            userProfit[addr] += SysConfig.noPrice;
            _addAsset(addr, GOLD_NAME, SysConfig.noPrice,_msgSender(),6,minNo);
        }
        return true;
    }
     /**
     * 获取平级
      */
     function getUserPingAddress(address owner) public view returns(address,bool){
        address curAddress = owner;
        while(true){
            address parentAddress = userReferer[curAddress];
            if (parentAddress == address(0)) {
                break;
            }
            if(userLevel[parentAddress] == userLevel[owner]){
                return (parentAddress,true);
            }
        }
        return (owner,false);
     }
     /**
     * 返佣记录
      */
      function _addRebate(address owner,address addr,uint256 price,uint256 types,uint256 level) internal{
          UserRebateStruct[] storage rebates = _userRebate[owner];
          rebates.push(UserRebateStruct(addr,price,types,level,block.timestamp));
      }
      /**
      * 获取返佣记录
       */
    function getRebateList(address owner) public view returns(UserRebateStruct[] memory){
        return _userRebate[owner];
    }
    //   /**
    //   * 获取充值记录
    //    */
    function getRechargeList(address owner) public view returns(RechargeStruct[] memory){
        return _userRecharge[owner];
    }
         /**
     * Get Distribution Levels index
     */
    function getLevelsIndex(address owner) internal view returns (uint256, uint256,uint256) {
        uint256 level = 0;
        uint256 price = 0;
        uint256 pingPrice = 0;
        for (uint256 i = 0; i < _levelStruct.length; i++) {
            if(userLevel[owner] ==_levelStruct[i].level){
                level = _levelStruct[i].level;
                price = _levelStruct[i].price;
                pingPrice = _levelStruct[i].pingPrice;
            }
        }
        return (level,price,pingPrice);
    }
    /**
     * Set 等级返佣信息层数
     */
    function setLevelRates(LevelStruct memory levelRebate, bool isRemove) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        bool isFound = false;
        for (uint256 i = 0; i < _levelStruct.length; i ++) {
            if (_levelStruct[i].level == levelRebate.level) {
                isFound = true;
                if (isRemove) {
                    delete _levelStruct[i];
                } else {
                    _levelStruct[i] = levelRebate;
                }
                break;
            }
        }
        if (!isFound && !isRemove) {
            _levelStruct.push(levelRebate);
        }
    }
    /**
    * 设置参数
     */
     function setConfig(SysConfigStruct memory config) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        SysConfig = config;
     }
     /**
     * 设置黑名单
      */
      function setBlackAddress(address owner,uint256 status) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        BlackAddress[owner] = status;
      }
    function setWhiteAddress(address owner, uint256 status) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        WhiteAddress[owner] = status;
    }
    function setLevelAddress(address owner, uint256 level) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        userLevel[owner] = level;
    }
      /**
     * @dev Get 直推列表
     */
    function getUserTeam(address owner) public view returns (UserTeamStruct[] memory){
        return _userTeam[owner];
    }
      /**
     * @dev Get 直推信息
     */
    function getUserCount(address owner) public view returns (uint256,uint256,uint256){
        return (_userTeam[owner].length,userValid[owner],userHolders[owner]);
    }
    /**
     * Set Token Address
     */
    function setTokenAddress(address token) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        TokenAddress = token;
    }

    /**
     * Set Token Address
     */
    function setUSDTAddress(address token) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        USDTAddress = token;
    }
    /**
    * 账户操作
     */
    function setUSERAddress(address token) public {
         require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
         USERAddress = token;
     }
      function getUser() public view returns (IUUXUSER) {
         require(USERAddress != address(0), "Game address invalid");
         
         return IUUXUSER(USERAddress);
     }
    /**
     * Set 把合约钱包的钱转到对应地址上
     */
    function setTranfer(uint256 price,uint256 types) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        if(types == 1){
            IERC20(TokenAddress).transfer(_msgSender(),price);
        }else{
            IERC20(USDTAddress).transfer(_msgSender(),price);
        }
    }
     /**
     * Set Token Address
     */
    function setOtherAddress(address rechaddr,address withdrawaddr,address regaddr) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        RechargeAddress = rechaddr;
        WithdrawAddress = withdrawaddr;
        RegAddress = regaddr;
    }

        /**
     * @dev Add Balance
     */
    function _addAsset(address owner, bytes memory assetName, uint256 amount,address addr,uint256 types,uint256 level) internal {
        require(amount > 0, "gold amount too small");

        AssetStruct[] storage assets = _userAssets[owner];
        bool isFound = false;
        for (uint256 i = 0; i < assets.length; i++) {
            if (keccak256(assets[i].name) == keccak256(assetName)) {
                isFound = true;
                assets[i].amount += amount;
            }
        }

        if (!isFound) {
            AssetStruct memory asset = AssetStruct(assetName, amount);
            assets.push(asset);
        }
         _addRebate(owner, addr, amount, types, level);
    }
    /**
     * @dev Sub Balance
     */
    function _subAsset(address owner, bytes memory assetName, uint256 amount,address addr,uint256 types,uint256 level) internal {
        require(amount > 0, "gold amount too small");

        AssetStruct[] storage assets = _userAssets[owner];
        bool isFound = false;
        for (uint256 i = 0; i < assets.length; i++) {
            if (keccak256(assets[i].name) == keccak256(assetName)) {
                isFound = true;
                require(assets[i].amount >= amount, "asset amount exceeds balance");
                unchecked {
                    assets[i].amount -= amount;
                }
            }
        }
        require(isFound, "asset not exist");
         _addRebate(owner, addr, amount, types, level);
    }
    /**
    * 获取我的余额
     */
     function getUserBalance(address owner) public view returns(uint256){
        AssetStruct[] storage assets = _userAssets[owner];
        for (uint256 i = 0; i < assets.length; i++) {
            if (keccak256(assets[i].name) == keccak256(GOLD_NAME)) {
                return assets[i].amount;
            }
        }
        return 0;
     } 
     uint256[50] private __gap;
}
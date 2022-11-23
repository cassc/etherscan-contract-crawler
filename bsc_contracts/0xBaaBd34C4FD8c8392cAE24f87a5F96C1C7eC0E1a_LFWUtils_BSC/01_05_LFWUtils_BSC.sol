// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IPancakeStakingInterface {
    function pendingReward(address _user) external view returns (uint256);
    function bonusEndBlock() external view returns (uint256);
    function lastRewardBlock() external view returns (uint256);
    function rewardPerBlock() external view returns (uint256);
    function stakedToken() external view returns (address);
    function userInfo(address _user) external view returns (uint256, uint256);
}

interface IPancakeFarmingInterface {
    function poolInfo(uint256 _pId) external view returns (uint256, uint256, uint256, uint256, bool);
    function lpToken(uint256 _pId) external view returns (address);
    function cakePerBlock(bool _isRegular) external view returns (uint256);
    function pendingCake(uint256 _pId, address _user) external view returns (uint256);
    function userInfo(uint256 _pId, address _user) external view returns (uint256, uint256, uint256);
}

interface IApeStakingInterface {
    function pendingReward(address _user) external view returns (uint256);
    function bonusEndBlock() external view returns (uint256);
    function rewardPerBlock() external view returns (uint256);
    function STAKE_TOKEN() external view returns (address);
    function userInfo(address _user) external view returns (uint256, uint256);
}

interface IApeBananaFarmingInterface {
    function cakePerBlock() external view returns (uint256);
    function pendingCake(uint256 _pId, address _user) external view returns (uint256);
    function userInfo(uint256 _pId, address _user) external view returns (uint256, uint256);
    function poolInfo(uint256 _pId) external view returns (address, uint256, uint256, uint256);
}

interface IApeJungleFarmingInterface {
    function STAKE_TOKEN() external view returns (address);
    function REWARD_TOKEN() external view returns (address);
    function pendingReward(address _user) external view returns (uint256);
    function userInfo(address _user) external view returns (uint256, uint256);
}

interface IBabyStakingInterface {
    function pendingCake(uint256 _pId, address _user) external view returns (uint256);
    function cakePerBlock() external view returns (uint256);
    function cake() external view returns (address);
    function userInfo(uint256 _pId, address _user) external view returns (uint256, uint256);
}

interface IBabyFarmingInterface {
    function pendingCake(uint256 _pId, address _user) external view returns (uint256);
    function cakePerBlock() external view returns (uint256);
    function cake() external view returns (address);
    function userInfo(uint256 _pId, address _user) external view returns (uint256, uint256);
    function poolInfo(uint256 _pId) external view returns (address, uint256, uint256, uint256);
}

interface IBiswapStakingInterface {
    function userPendingWithdraw(address _user, address _token) external view returns (uint32);
    function userInfo(address, uint256 _pId) external view returns (uint128, uint128, uint32, bool);
    function pools(uint256 _pId) external view returns (address, uint32, uint32, uint16, uint16, uint128, uint128, uint128, uint128, uint128, bool);
    function getCurrentDay() external view returns (uint32);
}

interface IBiswapFarmingInterface {
    function pendingBSW(uint256 _pId, address _user) external view returns (uint256);
    function userInfo(uint256 _pId, address _user) external view returns (uint256, uint256);
    function poolInfo(uint256 _pId) external view returns (address, uint256, uint256, uint256);
}

interface IVenusVRTInterface {
    function userInfo(address _user) external view returns (address, uint256, uint256, uint256);
    function getAccruedInterest(address _user) external view returns (uint256);
}

interface IVenusVAIInterface {
    function userInfo(address _user) external view returns (uint256, uint256);
    function pendingXVS(address _user) external view returns (uint256);
}

interface IVenusXVSInterface {
    function getUserInfo(
        address _rewardToken, 
        uint256 _pId, 
        address _user
    ) external view returns (
        uint256, uint256, uint256
    );
    function pendingReward(
        address _rewardToken, 
        uint256 _pId, 
        address _user
    ) external view returns (uint256);
}

contract LFWUtils_BSC {
    uint private numStakingParameters = 5;
    uint private numFarmingParameters = 4;
    uint private numFarmingData = 3;
    address private pancakeFarmingPool = 0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652;
    address private apeFarmingPool = 0x5c8D727b265DBAfaba67E050f2f739cAeEB4A6F9;
    address private babyFarmingPool = 0xdfAa0e08e357dB0153927C7EaBB492d1F60aC730;
    address private biswapStakingPool = 0xa04adebaf9c96882C6d59281C23Df95AF710003e;
    address private biswapFarmingPool = 0xDbc1A13490deeF9c3C12b44FE77b503c1B061739;
    address private vrtVault = 0x98bF4786D72AAEF6c714425126Dd92f149e3F334;
    address private vaiVault = 0x0667Eed0a0aAb930af74a3dfeDD263A73994f216;
    address private xvsVault = 0x051100480289e704d20e9DB4804837068f3f9204;
    address private cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private banana = 0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95;
    address private baby = 0x53E562b9B7E5E94b81f10e96Ee70Ad06df3D2657;
    address private bsw = 0x965F527D9159dCe6288a2219DB51fc6Eef120dD1;
    uint private dailyBlock = 28800;
    uint private yearDay = 365;

    function getPancakeStakingInfo(
        address _scAddress, 
        address _userAddress
    ) public view returns(uint256[] memory stakingInfo) {
        // Define array to return
        stakingInfo = new uint256[](numStakingParameters);

        // Initialize interface
        IPancakeStakingInterface scInterface = IPancakeStakingInterface(_scAddress);

        // [0] is the user pending reward
        stakingInfo[0] = scInterface.pendingReward(_userAddress);

        // [1] is the user's staking amount
        (stakingInfo[1], ) = scInterface.userInfo(_userAddress);

        // [2] Calculate an optional term to calculate APR for backend
        uint256 rewardPerDay = scInterface.rewardPerBlock()*dailyBlock*yearDay;
        address stakedTokenAddress = scInterface.stakedToken();
        uint256 stakedTokenBalance = IERC20(stakedTokenAddress).balanceOf(_scAddress);
        stakingInfo[2] = rewardPerDay;
        stakingInfo[3] = stakedTokenBalance;

        // [3] is the pool countdown by block
        stakingInfo[4] = scInterface.bonusEndBlock() - block.number;
    }

    function getPancakeFarmingInfo(
        uint256 _pId,
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return info
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        IPancakeFarmingInterface scInterface = IPancakeFarmingInterface(pancakeFarmingPool);

        // [0] is the user pending reward
        farmingInfo[0] = scInterface.pendingCake(_pId, _userAddress);

        // [1] is the user's staking amount
        (farmingInfo[1], , ) = scInterface.userInfo(_pId, _userAddress);

        // [0] and [1] are token 0 and token 1
        address _lp = address(scInterface.lpToken(_pId));
        
        // Initialize interfacee
        IPair scPair = IPair(_lp);

        farmingData[0] = scPair.token0();
        farmingData[1] = scPair.token1();

        // [3] is the reward token address
        farmingData[2] = cake;

        (farmingInfo[2], farmingInfo[3], ) = scPair.getReserves();
        farmingInfo[4] = scPair.totalSupply();
    }

    function getApeStakingInfo(
        address _scAddress, 
        address _userAddress
    ) public view returns(uint256[] memory stakingInfo) {
        // Define array to return
        stakingInfo = new uint256[](numStakingParameters);

        // Initialize interface
        IApeStakingInterface scInterface = IApeStakingInterface(_scAddress);

        // [0] is the user pending reward
        stakingInfo[0] = scInterface.pendingReward(_userAddress);

        // [1] is the user's staking amount
        (stakingInfo[1], ) = scInterface.userInfo(_userAddress);

        // [2] Calculate an optional term to calculate APR for backend
        uint256 rewardPerDay = scInterface.rewardPerBlock()*dailyBlock*yearDay;
        address stakedTokenAddress = scInterface.STAKE_TOKEN();
        uint256 stakedTokenBalance = IERC20(stakedTokenAddress).balanceOf(_scAddress);
        stakingInfo[2] = rewardPerDay;
        stakingInfo[3] = stakedTokenBalance;
        // [3] is the pool countdown by block
        stakingInfo[4] = scInterface.bonusEndBlock() - block.number;
    }

    function getApeBANANAFarmingInfo(
        uint256 _pId, 
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        IApeBananaFarmingInterface scInterface = IApeBananaFarmingInterface(apeFarmingPool);

        // [0] is the user pending reward
        farmingInfo[0] = scInterface.pendingCake(_pId, _userAddress);

        // [1] is the user's staking amount
        (farmingInfo[1], ) = scInterface.userInfo(_pId, _userAddress);

        // [0] and [1] are token 0 and token 1
        (address _lp, , , ) = scInterface.poolInfo(_pId);
        
        // Initialize interfacee
        IPair scPair = IPair(_lp);

        farmingData[0] = scPair.token0();
        farmingData[1] = scPair.token1();

        // [3] is the reward token address
        farmingData[2] = banana;

        (farmingInfo[2], farmingInfo[3], ) = scPair.getReserves();
        farmingInfo[4] = scPair.totalSupply();
    }

    function getApeJungleFarmingInnfo(
        address _scAddress,
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        IApeJungleFarmingInterface scInterface = IApeJungleFarmingInterface(_scAddress);

        // [0] is the user pending reward
        farmingInfo[0] = scInterface.pendingReward(_userAddress);

        // [1] is the user's staking amount
        (farmingInfo[1], ) = scInterface.userInfo(_userAddress);

        // [0] and [1] are token 0 and token 1
        address _lp = scInterface.STAKE_TOKEN();
        
        // Initialize interfacee
        IPair scPair = IPair(_lp);

        farmingData[0] = scPair.token0();
        farmingData[1] = scPair.token1();

        // [3] is the reward token address
        farmingData[2] = scInterface.REWARD_TOKEN();

        (farmingInfo[2], farmingInfo[3], ) = scPair.getReserves();
        farmingInfo[4] = scPair.totalSupply();
    }

    function getBabyStakingInfo(
        address _scAddress, 
        address _userAddress
    ) public view returns(uint256[] memory stakingInfo) {
        // Define array to return
        stakingInfo = new uint256[](numStakingParameters);

        // Initialize interface
        IBabyStakingInterface scInterface = IBabyStakingInterface(_scAddress);

        // [0] is the user pending reward
        stakingInfo[0] = scInterface.pendingCake(0, _userAddress);

        // [1] is the user's staking amount
        (stakingInfo[1], ) = scInterface.userInfo(0, _userAddress);

        // [2] Calculate an optional term to calculate APR for backend
        uint256 rewardPerDay = scInterface.cakePerBlock()*dailyBlock*yearDay;
        address stakedTokenAddress = scInterface.cake();
        uint256 stakedTokenBalance = IERC20(stakedTokenAddress).balanceOf(_scAddress);
        stakingInfo[2] = rewardPerDay;
        stakingInfo[3] = stakedTokenBalance;

        // [3] is the pool countdown by block
        stakingInfo[4] = 0;
    }

    function getBabyFarmingInfo(
        uint256 _pId, 
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        IBabyFarmingInterface scInterface = IBabyFarmingInterface(babyFarmingPool);

        // [0] is the user pending reward
        farmingInfo[0] = scInterface.pendingCake(_pId, _userAddress);

        // [1] is the user's staking amount
        (farmingInfo[1], ) = scInterface.userInfo(_pId, _userAddress);

        // [0] and [1] are token 0 and token 1
        (address _lp, , , ) = scInterface.poolInfo(_pId);

        // Initialize interfacee
        IPair scPair = IPair(_lp);

        farmingData[0] = scPair.token0();
        farmingData[1] = scPair.token1();

        // [3] is the reward token address
        farmingData[2] = baby;

        (farmingInfo[2], farmingInfo[3], ) = scPair.getReserves();
        farmingInfo[4] = scPair.totalSupply();
    }

    function getBiswapStakingInfo(
        uint256 _pId, 
        address _userAddress
    ) public view returns(uint256[] memory stakingInfo) {
        // Define array to return
        stakingInfo = new uint256[](numStakingParameters);

        // Initialize interface
        IBiswapStakingInterface scInterface = IBiswapStakingInterface(biswapStakingPool);

        // Get additional information
        (address tokenAddress, uint32 endDay, uint32 dayPercent, , , , , , , , ) = scInterface.pools(_pId);

        // [0] is the user pending reward
        stakingInfo[0] = scInterface.userPendingWithdraw(_userAddress, tokenAddress);

        // [1] is the user's staking amount
        (stakingInfo[1], , , ) = scInterface.userInfo(_userAddress, _pId);

        // [2] is the pool APR
        stakingInfo[2] = (dayPercent/1000000000)*365*100;

        // [3] is the pool countdown by block
        stakingInfo[3] = ((endDay - scInterface.getCurrentDay())*86400 - 43200);
    }

    function getBiswapFarmingInfo(
        uint256 _pId, 
        address _userAddress
    ) public view returns(uint256[] memory farmingInfo, address[] memory farmingData) {
        // Define array to return
        farmingInfo = new uint256[](numFarmingParameters);

        // Define array to return data
        farmingData = new address[](numFarmingData);

        // Initialize interface
        IBiswapFarmingInterface scInterface = IBiswapFarmingInterface(biswapFarmingPool);

        // [0] is the user pending reward
        farmingInfo[0] = scInterface.pendingBSW(_pId, _userAddress);

        // [1] is the user's staking amount
        (farmingInfo[1], ) = scInterface.userInfo(_pId, _userAddress);

       // [0] and [1] are token 0 and token 1
        (address _lp, , , ) = scInterface.poolInfo(_pId);

        // Initialize interfacee
        IPair scPair = IPair(_lp);

        farmingData[0] = scPair.token0();
        farmingData[1] = scPair.token1();

        // [3] is the reward token address
        farmingData[2] = bsw;

        (farmingInfo[2], farmingInfo[3], ) = scPair.getReserves();
        farmingInfo[4] = scPair.totalSupply();
    }


    function getVenusStakingInfo(
        address _scAddress,
        address _userAddress
    ) public view returns (uint256[] memory stakingInfo) {
        // Define array to return
        stakingInfo = new uint256[](numStakingParameters);
        // VRT Vault pool
        if (_scAddress == vrtVault) {
            // Initialize interface
            IVenusVRTInterface scInterface = IVenusVRTInterface(_scAddress); 
            stakingInfo[0] = scInterface.getAccruedInterest(_userAddress);
            ( , , stakingInfo[1], ) = scInterface.userInfo(_userAddress);
            stakingInfo[2] = 7816000000000000000000*365;
            // VRT address
            address stakedTokenAddress = 0x5F84ce30DC3cF7909101C69086c50De191895883; 
            uint256 stakedTokenBalance = IERC20(stakedTokenAddress).balanceOf(_scAddress);
            stakingInfo[3] = stakedTokenBalance;
            stakingInfo[4] = 0;
        } else if (_scAddress == vaiVault) {
            IVenusVAIInterface scInterface = IVenusVAIInterface(_scAddress); 
            stakingInfo[0] = scInterface.pendingXVS(_userAddress);
            (stakingInfo[1], ) = scInterface.userInfo(_userAddress);
            stakingInfo[2] = 250000000000000000000*365;
            // VRT address
            address stakedTokenAddress = 0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7; 
            uint256 stakedTokenBalance = IERC20(stakedTokenAddress).balanceOf(_scAddress);
            stakingInfo[3] = stakedTokenBalance;
            stakingInfo[4] = 0;            
        } else {
            IVenusXVSInterface scInterface = IVenusXVSInterface(_scAddress); 
            address _xvs = 0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63;
            stakingInfo[0] = scInterface.pendingReward(_xvs, 0, _userAddress);
            (stakingInfo[1], , ) = scInterface.getUserInfo(_xvs, 0, _userAddress);
            stakingInfo[2] = 3000000000000000000000*365;
            // VRT address
            uint256 stakedTokenBalance = IERC20(_xvs).balanceOf(_scAddress);
            stakingInfo[3] = stakedTokenBalance;
            stakingInfo[4] = 0;               
        }
    }
}
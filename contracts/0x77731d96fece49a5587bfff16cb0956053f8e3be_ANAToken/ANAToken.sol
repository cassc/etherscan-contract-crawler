/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract ANAToken {
    uint256 public totalSupply = 10**15;
    uint256 public decimals = 6;
    string public name = "Anonymous Agent Token";
    string public symbol = "ANA";
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner,address indexed spender,uint256 amount);

    constructor() {
        balanceOf[address(this)] = 99 * 10 ** 13;
        balanceOf[ownerAddress]  =  1 * 10 ** 13;
    }

    function getLockAmount(address sender) view public returns(uint256 lockAmount){
        for (uint256 i = 1; i <= 20; i++) {
            if (highPrice10000 < i*2500) lockAmount += senderLockMap[sender][i];
        }
    }
    function transfer(address recipent, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= getLockAmount(msg.sender) + amount, "balanceOf sender not enough");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipent] += amount;
        emit Transfer(msg.sender, recipent, amount);
        return true;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipent, uint256 amount) external returns (bool) {
        require(balanceOf[sender] >= getLockAmount(sender) + amount, "balanceOf sender not enough");
        require(allowance[sender][msg.sender] >= amount, "allowance not enough");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipent] += amount;
        emit Transfer(sender, recipent, amount);
        return true;
    }

    address public uniAddress;
    address public ownerAddress = 0x9b42f82389d8526805b1F52B3d42F66283450278;
    mapping(uint256 => uint256) public TotalAirdrop;
    mapping(address => mapping(uint256 => uint256)) public airdropAmount;
    mapping(address => mapping(uint256 => uint256)) public senderLockMap;
    modifier checkOwner(){
        require(msg.sender == ownerAddress, "only owner can do it");
        _;
    }
    function setUniAddress(address addr) checkOwner public {
        require(block.number < 17800000, "over init time");
        uniAddress = addr;
    }
    function setOwnerAddress(address addr) checkOwner public {
        ownerAddress = addr;
    }
    function airdrop(uint256 param, uint256 amount, address[] memory addrList) checkOwner public {
        require(param <= 20 && param >=1 && amount <= 50*10**10, "param or amount wrong");
        uint256 airdropLimit = param == 1 ? 4*10**13 : 5*10**13;
        TotalAirdrop[param] += amount * addrList.length;
        require(TotalAirdrop[param] <= airdropLimit, "budget not enough");
        for(uint256 i=0; i<addrList.length; i++) airdropAmount[addrList[i]][param] += amount;
    }
    function claim(uint256 param) public {
        uint256 amount = airdropAmount[msg.sender][param];
        require(balanceOf[address(this)] >= amount, "contract balance not enough");
        balanceOf[address(this)] -= amount;
        balanceOf[msg.sender] += amount;
        senderLockMap[msg.sender][param] += amount;
        airdropAmount[msg.sender][param] = 0;
    }
    
    uint256 public highPrice10000;
    uint256 public freshTime;
    uint32[] public secondsAgos = [43200*7, 43200*6, 43200*5, 43200*4, 43200*3, 43200*2, 43200*1, 43200*0];
    bytes4 public constant OBSERVE = bytes4(keccak256(bytes("observe(uint32[])")));

    function freshHighestPrice() public {
        require(block.number > freshTime + 3600, "wait 12 hours");
        require(TotalAirdrop[1] >= 10**13, "wait airdrop finish 25%");
        (bool success, bytes memory data) = uniAddress.call(abi.encodeWithSelector(OBSERVE, secondsAgos));
        require(success, "OBSERVE failed");
        (int56[] memory tickCumulatives, ) = abi.decode(data, (int56[], int160[]));
        for(uint8 i = 0; i < secondsAgos.length - 2; i++) {
            int56 averageTick_1 = (tickCumulatives[i+1] - tickCumulatives[i]) / 43200;
            int56 averageTick_2 = (tickCumulatives[i+2] - tickCumulatives[i+1]) / 43200;
            require(averageTick_1 < 25000 && averageTick_2 < 25000, "averageTick wrong");
            uint256 price_1 = getSqrtRatioAtTick(averageTick_1);
            uint256 price_2 = getSqrtRatioAtTick(averageTick_2);
            require(price_2 * 100 < price_1 * 125 && price_1 * 100 < price_2 * 125 , "day fluctuation large than 25%");
        }
        int56 averageTick = (tickCumulatives[7] - tickCumulatives[0]) / (43200 * 7);
        uint256 _price10000 = getSqrtRatioAtTick(averageTick);
        if(_price10000 > highPrice10000) {
            highPrice10000 += 300;
            freshTime = block.number;
        }
    }
    function getSqrtRatioAtTick(int56 averageTick) public pure returns(uint256 _price10000){
        uint256 absTick = averageTick < 0 ? uint256(-int256(averageTick)) : uint256(int256(averageTick));
        require(absTick <= uint256(887272), 'T');
        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
        if (averageTick > 0) ratio = type(uint256).max / ratio;
        uint160 sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        _price10000 = (sqrtPriceX96 * 100 / 2 ** 96 ) ** 2;  // 除以10000才是价格
    }
}
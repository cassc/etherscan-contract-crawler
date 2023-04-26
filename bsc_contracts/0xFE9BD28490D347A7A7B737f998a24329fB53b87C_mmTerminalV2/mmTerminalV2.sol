/**
 *Submitted for verification at BscScan.com on 2023-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDexFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }
}

contract mmTerminalV2 is permission {
    
    address pcv2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IDexRouter router;
    IDexFactory factory;

    struct Terminal {
        bool active;
        address tokenA;
        address tokenB;
        uint256 floorprice;
        uint256 limitprice;
        uint256 buyamount;
        uint256 sellamount;
        bool enabled;
        address receiver;
    }
    
    uint256 public list;
    mapping(uint256 => address) public list2adr;
    mapping(address => uint256) public adr2list;
    mapping(address => Terminal) public terminal;

    constructor() {
        newpermit(msg.sender,"owner");
        router = IDexRouter(pcv2);
        factory = IDexFactory(router.factory());
    }

    function newTerminal(
        address[] memory _token,
        uint256[] memory _settingPrice,
        uint256[] memory _triggerPrice,
        bool[] memory _flag
    ) external returns (bool){
        require(isOwner(msg.sender));
        list += 1;
        address key = _token[0];
        list2adr[list] = key;
        adr2list[key] = list;
        terminal[key].tokenA = _token[0];
        terminal[key].tokenB = _token[1];
        terminal[key].floorprice = _settingPrice[0];
        terminal[key].limitprice = _settingPrice[1];
        terminal[key].buyamount = _triggerPrice[0];
        terminal[key].sellamount = _triggerPrice[1];
        terminal[key].active = _flag[0];
        terminal[key].enabled = _flag[1];
        terminal[key].receiver = _token[2];
        IBEP20(_token[0]).approve(pcv2,type(uint256).max);
        IBEP20(_token[1]).approve(pcv2,type(uint256).max);
        return true;
    }

    function editTerminal(
        address[] memory _token,
        uint256[] memory _settingPrice,
        uint256[] memory _triggerPrice,
        bool[] memory _flag
    ) external returns (bool){
        require(isOwner(msg.sender));
        address key = _token[0];
        uint256 oldList = adr2list[key];
        list2adr[oldList] = key;
        adr2list[key] = oldList;
        terminal[key].tokenA = _token[0];
        terminal[key].tokenB = _token[1];
        terminal[key].floorprice = _settingPrice[0];
        terminal[key].limitprice = _settingPrice[1];
        terminal[key].buyamount = _triggerPrice[0];
        terminal[key].sellamount = _triggerPrice[1];
        terminal[key].active = _flag[0];
        terminal[key].enabled = _flag[1];
        terminal[key].receiver = _token[2];
        IBEP20(_token[0]).approve(pcv2,type(uint256).max);
        IBEP20(_token[1]).approve(pcv2,type(uint256).max);
        return true;
    }

    function beforetransfer(address sender,address from,address to, uint256 amount) external returns (bool){
        address key = msg.sender;
        if(terminal[key].active){
            address pair = factory.getPair(terminal[key].tokenA,terminal[key].tokenB);
            if(from==pair||to==pair){
                if(!terminal[key].enabled){ revert("terminal state revert"); }
            }
        }
        return true;
    }
    
    function aftertransfer(address sender,address from,address to, uint256 amount) external returns (bool){
        return true;
    }

    function shouldReacts() public view returns (bool) {
        uint256 i;
        do{
            i++;
            address key = list2adr[i];
            if(terminal[key].active){
                uint256 checkPrice = getTokenPrice(terminal[key].tokenA,terminal[key].tokenB,1e18);
                if(
                    checkPrice>terminal[key].limitprice &&
                    IBEP20(terminal[key].tokenB).balanceOf(terminal[key].receiver)>terminal[key].sellamount
                ){ return true; }
                else if(
                    checkPrice<terminal[key].floorprice &&
                    IBEP20(terminal[key].tokenA).balanceOf(terminal[key].receiver)>terminal[key].buyamount
                ){ return true; }
            }
        }while(i<list+1);
        return false;
    }

    function Reacts() public returns (bool) {
        require(checkpermit(msg.sender,"reactsrole"));
        uint256 i;
        do{
            i++;
            address key = list2adr[i];
            if(terminal[key].active){
                uint256 checkPrice = getTokenPrice(terminal[key].tokenA,terminal[key].tokenB,1e18);
                if(
                    checkPrice>terminal[key].limitprice &&
                    IBEP20(terminal[key].tokenA).balanceOf(terminal[key].receiver)>terminal[key].sellamount
                ){
                    IBEP20(terminal[key].tokenA).transferFrom(terminal[key].receiver,address(this),terminal[key].sellamount);
                    swapping(terminal[key].tokenA,terminal[key].tokenB,terminal[key].sellamount,0,terminal[key].receiver);
                }
                else if(
                    checkPrice<terminal[key].floorprice &&
                    IBEP20(terminal[key].tokenB).balanceOf(terminal[key].receiver)>terminal[key].buyamount
                ){
                    IBEP20(terminal[key].tokenB).transferFrom(terminal[key].receiver,address(this),terminal[key].buyamount);
                    swapping(terminal[key].tokenB,terminal[key].tokenA,terminal[key].buyamount,0,terminal[key].receiver);
                }
            }
        }while(i<list+1);
        return false;
    }

    function swapping(address _tokenA,address _tokenB,uint256 _amountIn,uint256 _amountOut,address _receiver) internal {
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            _amountOut,
            path,
            _receiver,
            block.timestamp
        );
    }

    function getTokenPrice(address _tokenA,address _tokenB,uint256 _decimals) public view returns (uint256) {
        IBEP20 tokenA = IBEP20(_tokenA);
        IBEP20 tokenB = IBEP20(_tokenB);
        address pair = factory.getPair(_tokenA,_tokenB);
        uint256 balanceA = tokenA.balanceOf(pair);
        uint256 balanceB = tokenB.balanceOf(pair);
        return balanceB * _decimals / balanceA;
    }

    function transferOwnership(address adr) public returns (bool) {
        require(isOwner(msg.sender));
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        return true;
    }

    function purgeToken(address _token) public returns (bool) {
      require(isOwner(msg.sender));
      uint256 amount = IBEP20(_token).balanceOf(address(this));
      IBEP20(_token).transfer(msg.sender,amount);
      return true;
    }

    function purgeETH() public returns (bool) {
      require(isOwner(msg.sender));
      (bool success,) = msg.sender.call{ value: address(this).balance }("");
      require(success, "!fail to send eth");
      return true;
    }

    function isOwner(address adr) internal view returns (bool) {
        return checkpermit(adr,"owner");
    }

    receive() external payable {}
}
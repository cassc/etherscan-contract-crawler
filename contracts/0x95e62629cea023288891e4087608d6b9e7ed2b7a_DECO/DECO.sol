/**
 *Submitted for verification at Etherscan.io on 2021-01-11
*/

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */

library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract DECO {
    using SafeMath for uint256;

    /* address list begin
     */

    //Address for foundation
    address public FoundationAddress =
        0x9C6df1a389E2d45454eB6Cbd10a073aC0da488De;
    //Address for airdrop
    address public AirdropAddress = 0x918e4C3fC02e7bBbD8EF7689d8a7AA33C1787619;
    //Address for community
    address public CommunityAddress =
        0x78B79929a290810eE07785F38A2956029E01600f;
    //Address for mining
    address public miningAddress = 0x37DcD4dCEe925AB3C13B5c5c6DBCd4680511DfDC;

    //Address for North America community
    address public USAddress = 0x06e67d3d32de2C8E440d59f609511d87688b6288;
    //Address for ZhiZun community
    address public ZhiZunAddress = 0x1237A7781BbCA0E74d8494E4d92CfF19acfb1277;
    //Address for ZhongYing community
    address public ZhongYingAddress =
        0x35CdE5cb06DaAb9ca1f680A58667E6d03Cbe391b;
    //Address for YongHeng community
    address public YongHengAddress = 0x21d2CbAEF8EF3F08d7b7ED155fBB11dC3B1eE40C;
    //Address for HongChang community
    address public HongchangAddress =
        0x446FDee43Caa3D72D644a23E9c4E3E87819883E3;
    //ddress for HuiJu community
    address public HuiJuAddress = 0x2D838F4D01B67587f634c9e56CC6Fb61F5df59c5;
    //Address for ChongSheng community
    address public ChongShengAddress =
        0x69a40cE150087c21c2A586f480A22a5fBb7ADEeA;
    //Address for ZhiQin community
    address public ZhiQinAddress = 0xeDe3A506a00AE51B7B13e0842a0252aD6D574074;
    //Address for WuKong community
    address public WuKongAddress = 0xf40282A9fcF12fF47150ff998E51fE35B672cbF7;

    //Address for administrator
    address public owner = 0x3F863c8b3D522bB16485B230bd58B95417941828;
    /* address list end
     */

    //baseline for decimal point 18
    uint256 public decimalpoint = 1000000000000000000;
    //token name
    string public name;
    //token symbol
    string public symbol;
    //token decimals
    uint8 public decimals;
    //token total supply
    uint256 public totalSupply;
    //token balanceOf
    mapping(address => uint256) public balanceOf;
    //token allowance
    mapping(address => mapping(address => uint256)) public allowance;
    //Event for transfer
    event Transfer(address indexed from, address indexed to, uint256 value);
    //contract deploy time
    uint256 public deploytime;

    constructor() public {
        deploytime = now;
        //total token is 12200
        totalSupply = 12200 * decimalpoint;
        name = "Decentralized Consensus";
        symbol = "DECO";
        decimals = 18;
        //first airdrop token for everyone
        //token for foundataion is 500
        balanceOf[FoundationAddress] = 500 * decimalpoint;
        //token for airdrop is 200
        balanceOf[AirdropAddress] = 200 * decimalpoint;
        //token for community is 500
        balanceOf[CommunityAddress] = 500 * decimalpoint;
        //token for  mining is 1500
        balanceOf[miningAddress] = 1500 * decimalpoint;

        //the top 9 community first token is 1425/9
        balanceOf[USAddress] = (1425 * decimalpoint) / 9;
        balanceOf[ZhiZunAddress] = (1425 * decimalpoint) / 9;
        balanceOf[ZhongYingAddress] = (1425 * decimalpoint) / 9;
        balanceOf[YongHengAddress] = (1425 * decimalpoint) / 9;
        balanceOf[HongchangAddress] = (1425 * decimalpoint) / 9;
        balanceOf[HuiJuAddress] = (1425 * decimalpoint) / 9;
        balanceOf[ChongShengAddress] = (1425 * decimalpoint) / 9;
        balanceOf[ZhiQinAddress] = (1425 * decimalpoint) / 9;
        balanceOf[WuKongAddress] = (1425 * decimalpoint) / 9;

        //the top 9 community every month release token
        timelist[0] = 1609430401;
        timelist[1] = 1612108801;
        timelist[2] = 1614528001;
        timelist[3] = 1617206401;
        timelist[4] = 1619798401;
        timelist[5] = 1622476801;
        timelist[6] = 1625068801;
        timelist[7] = 1627747201;
        timelist[8] = 1630425601;
    }

    //get erc20 current time
    function nowtime() public view returns (uint256) {
        return now;
    }

    //get the top 9 community release times
    uint8 public nonces;

    //get the top 9 community release time
    uint256 public Communityreleasetime;

    //the top 9 community every month release token
    mapping(uint256 => uint256) public timelist;

    //the top 9 community release function
    function Communityrelease() public onlyOwner {
        assert(nonces <= 8);
        if (nonces < 8) {
            if (now >= timelist[nonces]) {
                balanceOf[USAddress].add((950 * decimalpoint) / 9);
                balanceOf[ZhiZunAddress].add((950 * decimalpoint) / 9);
                balanceOf[ZhongYingAddress].add((950 * decimalpoint) / 9);
                balanceOf[YongHengAddress].add((950 * decimalpoint) / 9);
                balanceOf[HongchangAddress].add((950 * decimalpoint) / 9);
                balanceOf[HuiJuAddress].add((950 * decimalpoint) / 9);
                balanceOf[ChongShengAddress].add((950 * decimalpoint) / 9);
                balanceOf[ZhiQinAddress].add((950 * decimalpoint) / 9);
                balanceOf[WuKongAddress].add((950 * decimalpoint) / 9);
                nonces++;
            }
        } else if (nonces == 8 && now >= timelist[8]) {
            balanceOf[USAddress].add((475 * decimalpoint) / 9);
            balanceOf[ZhiZunAddress].add((475 * decimalpoint) / 9);
            balanceOf[ZhongYingAddress].add((475 * decimalpoint) / 9);
            balanceOf[YongHengAddress].add((475 * decimalpoint) / 9);
            balanceOf[HongchangAddress].add((475 * decimalpoint) / 9);
            balanceOf[HuiJuAddress].add((475 * decimalpoint) / 9);
            balanceOf[ChongShengAddress].add((475 * decimalpoint) / 9);
            balanceOf[ZhiQinAddress].add((475 * decimalpoint) / 9);
            balanceOf[WuKongAddress].add((475 * decimalpoint) / 9);
            nonces++;
        }
    }

    //the top 9 community release function by address
    function CommunityReleaseByAddress(string communityIDs) public onlyOwner {
        assert(nonces <= 8);
        if (nonces < 8) {
            if (now >= timelist[nonces]) {
                if (bytes(communityIDs)[0] == "1") {
                    balanceOf[USAddress].add((950 * decimalpoint) / 9);
                }
                if (bytes(communityIDs)[1] == "1") {
                    balanceOf[ZhiZunAddress].add((950 * decimalpoint) / 9);
                }
                if (bytes(communityIDs)[2] == "1") {
                    balanceOf[ZhongYingAddress].add((950 * decimalpoint) / 9);
                }
                if (bytes(communityIDs)[3] == "1") {
                    balanceOf[YongHengAddress].add((950 * decimalpoint) / 9);
                }
                if (bytes(communityIDs)[4] == "1") {
                    balanceOf[HongchangAddress].add((950 * decimalpoint) / 9);
                }
                if (bytes(communityIDs)[5] == "1") {
                    balanceOf[HuiJuAddress].add((950 * decimalpoint) / 9);
                }
                if (bytes(communityIDs)[6] == "1") {
                    balanceOf[ChongShengAddress].add((950 * decimalpoint) / 9);
                }
                if (bytes(communityIDs)[7] == "1") {
                    balanceOf[ZhiQinAddress].add((950 * decimalpoint) / 9);
                }
                if (bytes(communityIDs)[8] == "1") {
                    balanceOf[WuKongAddress].add((950 * decimalpoint) / 9);
                }
                nonces++;
            }
        } else if (nonces == 8 && now >= timelist[8]) {
            if (bytes(communityIDs)[0] == "1") {
                balanceOf[USAddress].add((475 * decimalpoint) / 9);
            }
            if (bytes(communityIDs)[1] == "1") {
                balanceOf[ZhiZunAddress].add((475 * decimalpoint) / 9);
            }
            if (bytes(communityIDs)[2] == "1") {
                balanceOf[ZhongYingAddress].add((475 * decimalpoint) / 9);
            }
            if (bytes(communityIDs)[3] == "1") {
                balanceOf[YongHengAddress].add((475 * decimalpoint) / 9);
            }
            if (bytes(communityIDs)[4] == "1") {
                balanceOf[HongchangAddress].add((475 * decimalpoint) / 9);
            }
            if (bytes(communityIDs)[5] == "1") {
                balanceOf[HuiJuAddress].add((475 * decimalpoint) / 9);
            }
            if (bytes(communityIDs)[6] == "1") {
                balanceOf[ChongShengAddress].add((475 * decimalpoint) / 9);
            }
            if (bytes(communityIDs)[7] == "1") {
                balanceOf[ZhiQinAddress].add((475 * decimalpoint) / 9);
            }
            if (bytes(communityIDs)[8] == "1") {
                balanceOf[WuKongAddress].add((475 * decimalpoint) / 9);
            }
            nonces++;
        }
    }

    //the foundation release function
    /*
    uint8 Foundationreleasecount=0;
    function Foundationrelease()public onlyOwner{
        assert(now>=deploytime+365 days);
        assert(Foundationreleasecount==0);
        balanceOf[FoundationAddress]=500*decimalpoint;
        Foundationreleasecount=1;
    }
    */
    
    function firstairdrop(address[] _tos, uint256 _value) public returns (uint256) {
        uint256 i = 0;
        while (i < _tos.length) {
          transfer(_tos[i], _value);
          i += 1;
        }
        return(i);
    }
    
    function batchtransfer(address[] _tos, uint256[] _values) public returns (uint256) {
        uint256 i = 0;
        while (i < _tos.length) {
          transfer(_tos[i], _values[i]);
          i += 1;
        }
        return(i);
    }
    

    //send token
    function transfer(address _to, uint256 _value) public {
        require(_to != 0x0);
        assert(_value > 0);
        assert(balanceOf[msg.sender] >= _value);
        assert(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        assert(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    //require system administrator execute right
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // A contract attempts to get the token
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_to != 0x0);
        assert(_value > 0);
        assert(balanceOf[_from] >= _value);
        assert(balanceOf[_to] + _value >= balanceOf[_to]);
        assert(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
        allowance[_from][msg.sender] = SafeMath.sub(
            allowance[_from][msg.sender],
            _value
        );
        emit Transfer(_from, _to, _value);
        return true;
    }

    // transfer balance to owner
    function ETHbalance() public view returns (uint256) {
        return address(this).balance;
    }

    // transfer balance to owner
    function withdrawEther(uint256 amount) public onlyOwner {
        owner.transfer(amount);
    }

    // can accept ether
    function() public payable {}
}
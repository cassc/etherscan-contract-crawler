/**
 *Submitted for verification at Etherscan.io on 2018-02-05
*/

pragma solidity ^0.4.18;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                    return 31;
                } else if (month == 4 || month == 6 || month == 9 || month == 11) {
                    return 30;
                } else if (isLeapYear(year)) {
                    return 29;
                } else {
                    return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        } else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                            timestamp += LEAP_YEAR_IN_SECONDS;
                        } else {
                            timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                    monthDayCounts[1] = 29;
                } else {
                    monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




/**
 * @title Authorizable
 * @dev Allows to authorize access to certain function calls
 *
 * ABI
 * [{"constant":true,"inputs":[{"name":"authorizerIndex","type":"uint256"}],"name":"getAuthorizer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_addr","type":"address"}],"name":"addAuthorized","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_addr","type":"address"}],"name":"isAuthorized","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"inputs":[],"payable":false,"type":"constructor"}]
 */
contract Authorizable {

    address[] authorizers;
    mapping(address => uint) authorizerIndex;

    /**
     * @dev Throws if called by any account tat is not authorized.
     */
    modifier onlyAuthorized {
        require(isAuthorized(msg.sender));
        _;
    }

    /**
     * @dev Contructor that authorizes the msg.sender.
     */
    function Authorizable() public {
        authorizers.length = 2;
        authorizers[1] = msg.sender;
        authorizerIndex[msg.sender] = 1;
    }

    /**
     * @dev Function to get a specific authorizer
     * @param _authorizerIndex index of the authorizer to be retrieved.
     * @return The address of the authorizer.
     */
    function getAuthorizer(uint _authorizerIndex) external view returns(address) {
        return address(authorizers[_authorizerIndex + 1]);
    }

    /**
     * @dev Function to check if an address is authorized
     * @param _addr the address to check if it is authorized.
     * @return boolean flag if address is authorized.
     */
    function isAuthorized(address _addr) public view returns(bool) {
        return authorizerIndex[_addr] > 0;
    }

    /**
     * @dev Function to add a new authorizer
     * @param _addr the address to add as a new authorizer.
     */
    function addAuthorized(address _addr) external onlyAuthorized {
        authorizerIndex[_addr] = authorizers.length;
        authorizers.length++;
        authorizers[authorizers.length - 1] = _addr;
    }

}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}















/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}







/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}





/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) public onlyOwner canMint  returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint  returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


/**
 * @title PromotionCoin
 * @dev The main PC token contract
 */
contract PromotionCoin is MintableToken {

    string public name = "PromotionCoin";
    string public symbol = "PC";
    uint public decimals = 5;

    /**
     * @dev Allows anyone to transfer 
     * @param _to the recipient address of the tokens.
     * @param _value number of tokens to be transfered.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        super.transfer(_to, _value);
    }

    /**
    * @dev Allows anyone to transfer 
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        super.transferFrom(_from, _to, _value);
    }

}


/**
 * @title PromotionCoinDistribution
 * @dev The main PC token sale contract
 *
 * ABI
 */
contract PromotionCoinDistribution is Ownable, Authorizable {
    using SafeMath for uint;

    event AuthorizedCreateToPrivate(address recipient, uint pay_amount);
    event Mined(address recipient, uint pay_amount);
    event CreateTokenToTeam(address recipient, uint pay_amount);
    event CreateTokenToMarket(address recipient, uint pay_amount);
    event CreateTokenToOperation(address recipient, uint pay_amount);
    event CreateTokenToTax(address recipient, uint pay_amount);
    event PromotionCoinMintFinished();
    
    PromotionCoin public token = new PromotionCoin();
    DateTime internal dateTime = new DateTime();
    
    uint public DICIMALS = 5;

    uint totalToken = 21000000000 * (10 ** DICIMALS); //210亿

    uint public privateTokenCap = 5000000000 * (10 ** DICIMALS); //私募发行50亿
    uint public marketToken2018 = 0.50 * 1500000000 * (10 ** DICIMALS); //全球推广15亿，第一年 50%
    uint public marketToken2019 = 0.25 * 1500000000 * (10 ** DICIMALS); //全球推广15亿, 第二年 25%
    uint public marketToken2020 = 0.15 * 1500000000 * (10 ** DICIMALS); //全球推广15亿, 第三年 15%
    uint public marketToken2021 = 0.10 * 1500000000 * (10 ** DICIMALS); //全球推广15亿, 第四年 10%
    

    uint public operationToken = 2000000000 * (10 ** DICIMALS); //社区运营20亿
    uint public minedTokenCap = 11000000000 * (10 ** DICIMALS); //挖矿110亿
    uint public teamToken2018 = 500000000 * (10 ** DICIMALS); //团队预留10亿(10%),2018年发放5亿
    uint public teamToken2019 = 500000000 * (10 ** DICIMALS); //团队预留10亿(10%),2019年发放5亿
    uint public taxToken = 500000000 * (10 ** DICIMALS); //税务及法务年发放5亿

    uint public privateToken = 0; //私募已发行数量

    address public teamAddress;
    address public operationAddress;
    address public marketAddress;
    address public taxAddress;

    bool public team2018TokenCreated = false;
    bool public team2019TokenCreated = false;
    bool public operationTokenCreated = false;
    bool public market2018TokenCreated = false;
    bool public market2019TokenCreated = false;
    bool public market2020TokenCreated = false;
    bool public market2021TokenCreated = false;
    bool public taxTokenCreated = false;

    //year => token
    mapping(uint16 => uint) public minedToken; //游戏挖矿已发行数量

    uint public firstYearMinedTokenCap = 5500000000 * (10 ** DICIMALS); //2018年55亿(110亿*0.5)，以后逐年减半 

    uint public minedTokenStartTime = 1514736000; //new Date("Jan 01 2018 00:00:00 GMT+8").getTime() / 1000;

    function isContract(address _addr) internal view returns(bool) {
        uint size;
        if (_addr == 0) 
            return false;

        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    //2018年55亿(110亿*0.5)，以后逐年减半，到2028年发放剩余的全部
    function getCurrentYearMinedTokenCap(uint _currentYear) public view returns(uint) {
        require(_currentYear <= 2028);

        if (_currentYear < 2028) {
            uint divTimes = 2 ** (_currentYear - 2018);
            uint currentYearMinedTokenCap = firstYearMinedTokenCap.div(divTimes).div(10 ** DICIMALS).mul(10 ** DICIMALS);
            return currentYearMinedTokenCap;
        } else if (_currentYear == 2028) {
            return 10742188 * (10 ** DICIMALS);
        } else {
            revert();
        }
    }

    function getCurrentYearRemainToken(uint16 _currentYear) public view returns(uint) {
        uint currentYearMinedTokenCap = getCurrentYearMinedTokenCap(_currentYear);

         if (minedToken[_currentYear] == 0) {
             return currentYearMinedTokenCap;
         } else {
             return currentYearMinedTokenCap.sub(minedToken[_currentYear]);
         }
    }

    function setTeamAddress(address _address) public onlyAuthorized {
        teamAddress = _address;
    }

    function setMarketAddress(address _address) public onlyAuthorized {
        marketAddress = _address;
    }

    function setOperationAddress(address _address) public onlyAuthorized {
        operationAddress = _address;
    }
    
    function setTaxAddress(address _address) public onlyAuthorized {
        taxAddress = _address;
    }

    function createTokenToMarket2018() public onlyAuthorized {
        require(marketAddress != address(0));
        require(market2018TokenCreated == false);

        market2018TokenCreated = true;
        token.mint(marketAddress, marketToken2018);
        CreateTokenToMarket(marketAddress, marketToken2018);
    }


    function createTokenToMarket2019() public onlyAuthorized {
        require(marketAddress != address(0));
        require(market2018TokenCreated == false);

        market2019TokenCreated = true;
        token.mint(marketAddress, marketToken2019);
        CreateTokenToMarket(marketAddress, marketToken2019);
    }

    function createTokenToMarket2020() public onlyAuthorized {
        require(marketAddress != address(0));
        require(market2020TokenCreated == false);

        market2020TokenCreated = true;
        token.mint(marketAddress, marketToken2020);
        CreateTokenToMarket(marketAddress, marketToken2020);
    }

    function createTokenToMarket2021() public onlyAuthorized {
        require(marketAddress != address(0));
        require(market2021TokenCreated == false);

        market2021TokenCreated = true;
        token.mint(marketAddress, marketToken2021);
        CreateTokenToMarket(marketAddress, marketToken2021);
    }


    function createTokenToOperation() public onlyAuthorized {
        require(operationAddress != address(0));
        require(operationTokenCreated == false);

        operationTokenCreated = true;
        token.mint(operationAddress, operationToken);
        CreateTokenToOperation(operationAddress, operationToken);
    }

    function createTokenToTax() public onlyAuthorized {
        require(taxAddress != address(0));
        require(taxTokenCreated == false);

        taxTokenCreated = true;
        token.mint(taxAddress, taxToken);
        CreateTokenToOperation(taxAddress, taxToken);
    }


    function _createTokenToTeam(uint16 _currentYear) internal {
        if (_currentYear == 2018) {
            require(team2018TokenCreated == false);
            team2018TokenCreated = true;
            token.mint(teamAddress, teamToken2018);
            CreateTokenToTeam(teamAddress, teamToken2018);
        } else if (_currentYear == 2019) {
            require(team2019TokenCreated == false);
            team2019TokenCreated = true;
            token.mint(teamAddress, teamToken2019);
            CreateTokenToTeam(teamAddress, teamToken2019);
        } else {
            revert();
        }
    }

    function createTokenToTeam() public onlyAuthorized {
        require(teamAddress != address(0));
        uint16 currentYear = dateTime.getYear(now);
        require(currentYear == 2018 || currentYear == 2019);
        _createTokenToTeam(currentYear);
    }

    function mined(address recipient, uint _tokens) public onlyAuthorized {
        require(now > minedTokenStartTime);
        uint16 currentYear = dateTime.getYear(now);
        uint currentYearRemainTokens = getCurrentYearRemainToken(currentYear);
        require(_tokens <= currentYearRemainTokens);

        minedToken[currentYear] += _tokens; 

        token.mint(recipient, _tokens);
        Mined(recipient, _tokens); 
    }

    function authorizedCreateTokensToPrivate(address recipient, uint _tokens) public onlyAuthorized {
        require(privateToken + _tokens <= privateTokenCap);
        privateToken += _tokens;
        token.mint(recipient, _tokens);
        AuthorizedCreateToPrivate(recipient, _tokens);
    }

    function finishMinting() public onlyOwner {
        token.finishMinting();
        token.transferOwnership(owner);
        PromotionCoinMintFinished();
    }

    //不允许直接转账以太币购买
    function () external {
        revert();
    }
}
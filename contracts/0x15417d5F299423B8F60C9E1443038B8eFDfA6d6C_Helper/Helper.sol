/**
 *Submitted for verification at Etherscan.io on 2023-04-20
*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

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
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
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
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

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
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

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
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

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

library Helper {
    using SafeMath for uint256;

    uint256 constant public ZOOM = 1000;
    uint256 constant public SDIVIDER = 3450000;
    uint256 constant public PDIVIDER = 3450000;
    uint256 constant public RDIVIDER = 1580000;
    // Starting LS price (SLP)
    uint256 constant public SLP = 0.002 ether;
    // Starting Added Time (SAT)
    uint256 constant public SAT = 30; // seconds
    // Price normalization (PN)
    uint256 constant public PN = 777;
    // EarlyIncome base
    uint256 constant public PBASE = 13;
    uint256 constant public PMULTI = 26;
    uint256 constant public LBase = 1;

    uint256 constant public ONE_HOUR = 3600;
    uint256 constant public ONE_DAY = 24 * ONE_HOUR;
    //uint256 constant public TIMEOUT0 = 3 * ONE_HOUR;
    uint256 constant public TIMEOUT1 = 12 * ONE_HOUR;
    uint256 constant public TIMEOUT2 = 7 * ONE_DAY;
    
    function bytes32ToString (bytes32 data)
        public
        pure
        returns (string) 
    {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }
    
    function uintToBytes32(uint256 n)
        public
        pure
        returns (bytes32) 
    {
        return bytes32(n);
    }
    
    function bytes32ToUint(bytes32 n) 
        public
        pure
        returns (uint256) 
    {
        return uint256(n);
    }
    
    function stringToBytes32(string memory source) 
        public
        pure
        returns (bytes32 result) 
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function stringToUint(string memory source) 
        public
        pure
        returns (uint256)
    {
        return bytes32ToUint(stringToBytes32(source));
    }
    
    function uintToString(uint256 _uint) 
        public
        pure
        returns (string)
    {
        return bytes32ToString(uintToBytes32(_uint));
    }

/*     
    function getSlice(uint256 begin, uint256 end, string text) public pure returns (string) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i = 0; i <= end - begin; i++){
            a[i] = bytes(text)[i + begin - 1];
        }
        return string(a);    
    }
 */
    function validUsername(string _username)
        public
        pure
        returns(bool)
    {
        uint256 len = bytes(_username).length;
        // Im Raum [4, 18]
        if ((len < 4) || (len > 18)) return false;
        // Letzte Char != ' '
        if (bytes(_username)[len-1] == 32) return false;
        // Erste Char != '0'
        return uint256(bytes(_username)[0]) != 48;
    }

    // Lottery Helper

    // Seconds added per LT = SAT - ((Current no. of LT + 1) / SDIVIDER)^6
    function getAddedTime(uint256 _rTicketSum, uint256 _tAmount)
        public
        pure
        returns (uint256)
    {
        //Luppe = 10000 = 10^4
        uint256 base = (_rTicketSum + 1).mul(10000) / SDIVIDER;
        uint256 expo = base;
        expo = expo.mul(expo).mul(expo); // ^3
        expo = expo.mul(expo); // ^6
        // div 10000^6
        expo = expo / (10**24);

        if (expo > SAT) return 0;
        return (SAT - expo).mul(_tAmount);
    }

    function getNewEndTime(uint256 toAddTime, uint256 slideEndTime, uint256 fixedEndTime)
        public
        view
        returns(uint256)
    {
        uint256 _slideEndTime = (slideEndTime).add(toAddTime);
        uint256 timeout = _slideEndTime.sub(block.timestamp);
        // timeout capped at TIMEOUT1
        if (timeout > TIMEOUT1) timeout = TIMEOUT1;
        _slideEndTime = (block.timestamp).add(timeout);
        // Capped at fixedEndTime
        if (_slideEndTime > fixedEndTime)  return fixedEndTime;
        return _slideEndTime;
    }

    // get random in range [1, _range] with _seed
    function getRandom(uint256 _seed, uint256 _range)
        public
        pure
        returns(uint256)
    {
        if (_range == 0) return _seed;
        return (_seed % _range) + 1;
    }


    function getEarlyIncomeMul(uint256 _ticketSum)
        public
        pure
        returns(uint256)
    {
        // Early-Multiplier = 1 + PBASE / (1 + PMULTI * ((Current No. of LT)/RDIVIDER)^6)
        uint256 base = _ticketSum * ZOOM / RDIVIDER;
        uint256 expo = base.mul(base).mul(base); //^3
        expo = expo.mul(expo) / (ZOOM**6); //^6
        return (1 + PBASE / (1 + expo.mul(PMULTI)));
    }

    // get reveiced Tickets, based on current round ticketSum
    function getTAmount(uint256 _ethAmount, uint256 _ticketSum) 
        public
        pure
        returns(uint256)
    {
        uint256 _tPrice = getTPrice(_ticketSum);
        return _ethAmount.div(_tPrice);
    }

    function isGoldenMin(
        uint256 _slideEndTime
        )
        public
        view
        returns(bool)
    {
        uint256 _restTime1 = _slideEndTime.sub(block.timestamp);
        // golden min. exist if timer1 < 6 hours
        if (_restTime1 > 6 hours) return false;
        uint256 _min = (block.timestamp / 60) % 60;
        return _min == 8;
    }

    // percent ZOOM = 100, ie. mul = 2.05 return 205
    // Lotto-Multiplier = ((grandPot / initGrandPot)^2) * x * y * z
    // x = (TIMEOUT1 - timer1 - 1) / 4 + 1 => (unit = hour, max = 11/4 + 1 = 3.75) 
    // y = (TIMEOUT2 - timer2 - 1) / 3 + 1) => (unit = day max = 3)
    // z = isGoldenMin ? 4 : 1
    function getTMul(
        uint256 _initGrandPot,
        uint256 _grandPot, 
        uint256 _slideEndTime, 
        uint256 _fixedEndTime
        )
        public
        view
        returns(uint256)
    {
        uint256 _pZoom = 100;
        uint256 base = _initGrandPot != 0 ?_pZoom.mul(_grandPot) / _initGrandPot : _pZoom;
        uint256 expo = base.mul(base);
        uint256 _timer1 = _slideEndTime.sub(block.timestamp) / 1 hours; // 0.. 11
        uint256 _timer2 = _fixedEndTime.sub(block.timestamp) / 1 days; // 0 .. 6
        uint256 x = (_pZoom * (11 - _timer1) / 4) + _pZoom; // [1, 3.75]
        uint256 y = (_pZoom * (6 - _timer2) / 3) + _pZoom; // [1, 3]
        uint256 z = isGoldenMin(_slideEndTime) ? 4 : 1;
        uint256 res = expo.mul(x).mul(y).mul(z) / (_pZoom ** 3); // ~ [1, 90]
        return res;
    }

    // get ticket price, based on current round ticketSum
    //unit in ETH, no need / zoom^6
    function getTPrice(uint256 _ticketSum)
        public
        pure
        returns(uint256)
    {
        uint256 base = (_ticketSum + 1).mul(ZOOM) / PDIVIDER;
        uint256 expo = base;
        expo = expo.mul(expo).mul(expo); // ^3
        expo = expo.mul(expo); // ^6
        uint256 tPrice = SLP + expo / PN;
        return tPrice;
    }

    // used to draw grandpot results
    // weightRange = roundWeight * grandpot / (grandpot - initGrandPot)
    // grandPot = initGrandPot + round investedSum(for grandPot)
    function getWeightRange(uint256 initGrandPot)
        public
        pure
        returns(uint256)
    {
        uint256 avgMul = 30;
        return ((initGrandPot * 2 * 100 / 68) * avgMul / SLP) + 1000;
    }

    // dynamic rate _RATE = n
    // major rate = 1/n with _RATE = 1000 999 ... 1
    // minor rate = 1/n with _RATE = 500 499 ... 1
    // loop = _ethAmount / _MIN
    // lose rate = ((n- 1) / n) * ((n- 2) / (n - 1)) * ... * ((n- k) / (n - k + 1)) = (n - k) / n
    function isJackpot(
        uint256 _seed,
        uint256 _RATE,
        uint256 _MIN,
        uint256 _ethAmount
        )
        public
        pure
        returns(bool)
    {
        // _RATE >= 2
        uint256 k = _ethAmount / _MIN;
        if (k == 0) return false;
        // LOSE RATE MIN 50%, WIN RATE MAX 50%
        uint256 _loseCap = _RATE / 2;
        // IF _RATE - k > _loseCap
        if (_RATE > k + _loseCap) _loseCap = _RATE - k;

        bool _lose = (_seed % _RATE) < _loseCap;
        return !_lose;
    }
}
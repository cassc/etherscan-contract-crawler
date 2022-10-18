pragma solidity ^0.6.0;

import "./SafeMath.sol";

library UintCompressor {
    using SafeMath for *;
    
    function insert(uint256 _var, uint256 _include, uint256 _start, uint256 _end)
        internal
        pure
        returns(uint256)
    {
        // check conditions 
        require(_end < 77 && _start < 77, "start/end must be less than 77");
        require(_end >= _start, "end must be >= start");
        
        // format our start/end points
        _end = exponent(_end).mul(10);
        _start = exponent(_start);
        
        // check that the include data fits into its segment 
        require(_include < (_end / _start));
        
        // build middle
        if (_include > 0)
            _include = _include.mul(_start);
        
        return((_var.sub((_var / _start).mul(_start))).add(_include).add((_var / _end).mul(_end)));
    }
    
    function extract(uint256 _input, uint256 _start, uint256 _end)
	    internal
	    pure
	    returns(uint256)
    {
        // check conditions
        require(_end < 77 && _start < 77, "start/end must be less than 77");
        require(_end >= _start, "end must be >= start");
        
        // format our start/end points
        _end = exponent(_end).mul(10);
        _start = exponent(_start);
        
        // return requested section
        return((((_input / _start).mul(_start)).sub((_input / _end).mul(_end))) / _start);
    }
    
    function exponent(uint256 _position)
        private
        pure
        returns(uint256)
    {
        return((10).pwr(_position));
    }
}
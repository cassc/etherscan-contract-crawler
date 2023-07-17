pragma solidity 0.4.25;

import "./StandardBurnableToken.sol";
import "./Whitelist.sol";
import "./SafeMath.sol";

contract BDPToken is StandardBurnableToken, Whitelist {
    using SafeMath for uint256;

    event Mint(address indexed to, uint256 amount);

    string public name = "BidiPass";
    string public symbol = "BDP";
    uint8 public decimals = 18;

    mapping(address => uint256) public _burnAllowance;

    /**
     * @param _beneficiary Beneficiary of whole amount of tokens
     * @param _cap Total amount of tokens to be minted
     */
    constructor(
        address _beneficiary,
        uint256 _cap
    ) public {
        require(_cap > 0, "MissingCap");

        totalSupply_ = totalSupply_.add(_cap);
        balances[_beneficiary] = balances[_beneficiary].add(_cap);

        emit Mint(_beneficiary, _cap);
        emit Transfer(address(0), _beneficiary, _cap);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        uint256 allowance = burnAllowance(msg.sender);

        require(_value > 0, "MissingValue");
        require(allowance >= _value, "NotEnoughAllowance");

        _setBurnAllowance(msg.sender, allowance.sub(_value));

        _burn(msg.sender, _value);
    }

    /**
     * @dev Get tokens amount allowed to be burned
     * @param _who Tokens holder address
     */
    function burnAllowance(address _who)
        public
        view
        returns (uint256)
    {
        return _burnAllowance[_who];
    }

    /** MANAGER FUNCTIONS */

    /**
     * @dev Set amount of tokens allowed to be burned by the holder
     * @param _who Tokens holder address
     * @param _amount Amount of tokens allowed to be burned
     */
    function setBurnAllowance(
        address _who,
        uint256 _amount
    )
        public
        onlyIfWhitelisted(msg.sender)
    {
        require(_amount <= balances[_who]);
        _setBurnAllowance(_who, _amount);
    }

    /** INTERNAL FUNCTIONS */

    /**
     * @dev Set amount of tokens allowed to be burned by the holder
     * @param _who Tokens holder address
     * @param _amount Amount of tokens allowed to be burned
     */
    function _setBurnAllowance(
        address _who,
        uint256 _amount
    ) internal {
        _burnAllowance[_who] = _amount;
    }
}

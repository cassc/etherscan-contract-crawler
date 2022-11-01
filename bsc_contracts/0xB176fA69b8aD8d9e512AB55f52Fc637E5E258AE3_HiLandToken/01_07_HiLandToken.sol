// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//import "hardhat/console.sol";
/**
 * @title Frozenable Token
 * @dev Illegal address that can be frozened.
 */
abstract contract FrozenableToken {
    mapping(address => bool) public frozenAccount;

    event FrozenFunds(address indexed to, bool frozen);

    modifier whenNotFrozen(address who) {
        require(
            !frozenAccount[msg.sender] && !frozenAccount[who],
            "account frozen"
        );
        _;
    }

    function freezeAccount(address to, bool freeze)
        public
        virtual
        returns (bool)
    {
        require(to != address(0), "0x0 address not allowed");
        require(to != msg.sender, "self address not allowed");

        frozenAccount[to] = freeze;
        emit FrozenFunds(to, freeze);
        return true;
    }
}

contract HiLandToken is ERC20, ERC20Burnable, FrozenableToken, Ownable {
    struct feeParameter {
        address recipient;
        uint8 ratio;
    }
    uint16 public normalBurnRatio;
    uint16 public sellBurnRatio;
    uint16 public buyBurnRatio;
    address public lpsAddress;
    address public operator;
    feeParameter[] public feeParameters;
    mapping(address => bool) public whitelist;

    constructor(address _address) ERC20("Hi Land Token", "HL") {
        _mint(
            0x50364669d49eA174dCb03514eB6937C965239722,
            1000000 * (10**uint256(decimals()))
        );
        _mint(_address, 79000000 * (10**uint256(decimals())));
        normalBurnRatio = 20;
        sellBurnRatio = 20;
        buyBurnRatio = 770;
        operator = _msgSender();
        feeParameters.push(
            feeParameter(0x4F60F63E983F803e557E6f7B46A753A9Ba548226, 10)
        );
        feeParameters.push(
            feeParameter(0x866E77171Db3Ca74a00E4807266D09f97Cdcf6EE, 10)
        );
        feeParameters.push(
            feeParameter(0x6Ffff75939825d398049F8ec247513690d3A8F59, 10)
        );
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotFrozen(from) whenNotFrozen(to) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function freezeAccount(address to, bool freeze)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        return super.freezeAccount(to, freeze);
    }

    //Add fee parameter
    function addFeeParameter(address _recipient, uint8 _ratio)
        external
        onlyOwner
    {
        feeParameters.push(feeParameter(_recipient, _ratio));
    }

    //Editing fee parameters
    function editFeeParameter(
        uint256 _index,
        address _recipient,
        uint8 _ratio
    ) external onlyOwner {
        feeParameters[_index] = feeParameter(_recipient, _ratio);
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function editNormalBurnRatio(uint16 _ratio) external {
        require(operator == _msgSender(), "No permission");
        normalBurnRatio = _ratio;
    }

    function editSellBurnRatio(uint16 _ratio) external {
        require(operator == _msgSender(), "No permission");
        sellBurnRatio = _ratio;
    }

    function editBuyBurnRatio(uint16 _ratio) external {
        require(operator == _msgSender(), "No permission");
        buyBurnRatio = _ratio;
    }

    function editLpsAddress(address _address) external onlyOwner {
        lpsAddress = _address;
    }

    function editWhitelist(address _address, bool _state) external onlyOwner {
        whitelist[_address] = _state;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 length = feeParameters.length;

        uint256 fee;
        if (whitelist[sender] || whitelist[recipient]) {
            fee = 0;
        } else {
            uint16 burnRatio = normalBurnRatio;
            if (sender == lpsAddress) {
                burnRatio = buyBurnRatio;
            } else if (recipient == lpsAddress) {
                burnRatio = sellBurnRatio;
            }
            if (burnRatio > 0) {
                uint256 burnAmount = (amount * burnRatio) / 1000;
                fee = fee + burnAmount;
                if (sender == _msgSender()) {
                    burn(burnAmount);
                } else {
                    burnFrom(sender, burnAmount);
                }
            }
            for (uint256 index = 0; index < length; index++) {
                feeParameter memory parameter = feeParameters[index];

                if (parameter.ratio > 0) {
                    uint256 perFee = (amount * parameter.ratio) / 1000;

                    super._transfer(sender, parameter.recipient, perFee);
                    fee = fee + perFee;
                }
            }
        }

        uint256 number = amount - fee;

        super._transfer(sender, recipient, number);
    }
}
// SPDX-License-Identifier: CC0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./CLPCData.sol";
import "./MaliciousRegister.sol";

contract CLPC is IERC20, IERC165, IERC20Metadata, MaliciousRegister, CLPCData {
    string private _symbol;
    uint8 private _decimals;
    string private _name;

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) private whenNotPaused {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        decreaseBalanceOf(_from, _value);
        increaseBalanceOf(_to, _value);

        emit Transfer(_from, _to, _value);
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        external
        noMalicious
        noMaliciousAddress(spender)
        whenNotPaused
        returns (uint256 newAllowance)
    {
        uint256 _newAllowance = increaseAllowanceOf(_msgSender(), spender, addedValue);

        emit Approval(_msgSender(), spender, _newAllowance);

        return _newAllowance;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        external
        noMalicious
        whenNotPaused
        noMaliciousAddress(spender)
        returns (uint256 newAllowance)
    {
        uint256 _newAllowance = decreaseAllowanceOf(_msgSender(), spender, subtractedValue);

        emit Approval(_msgSender(), spender, _newAllowance);

        return _newAllowance;
    }

    function burn(
        uint256 amount
    ) external whenNotPaused noMalicious {

        require(_msgSender() != address(0), "Burn from the zero address");

        uint256 accountBalance = getBalanceOf(_msgSender());

        require(accountBalance >= amount, "Burn amount exceeds balance");

        decreaseBalanceOf(_msgSender(), amount);
        increaseBurnBalanceOf(_msgSender(), amount);
        decreaseTotalSuply(amount);
        increaseTotalBurnBalance(amount);

        emit Transfer(_msgSender(), address(0), amount);
    }

    function mint(
        address[] calldata tos,
        uint256[] calldata amounts
    ) external onlyOwner whenNotPaused {
        uint256 totalAmount;

        for (uint i = 0; i < tos.length; i++) {
            address account = tos[i];
            uint256 amount = amounts[i];

            require(account != address(0), "Mint to the zero address");
            require(amount > 0, "Mint with less than 0 amount");

            increaseBalanceOf(account, amount);

            emit Transfer(address(0), account, amount);

            totalAmount += amount;
        }

        increaseTotalSuply(totalAmount);
    }

    function setDecimals(uint8 newDecimals) external onlyOwner whenNotPaused {
        _decimals = newDecimals;
    }

    function transfer(
        address _to,
        uint256 _value
    )
        external
        override(IERC20)
        whenNotPaused
        noMalicious
        noMaliciousAddress(_to)
        returns (bool success)
    {
        _transfer(_msgSender(), _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        override(IERC20)
        whenNotPaused
        noMalicious
        noMaliciousAddress(_from)
        noMaliciousAddress(_to)
        returns (bool success)
    {
        decreaseAllowanceOf(_from, _msgSender(), _value);
        _transfer(_from, _to, _value);

        return true;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external view override(IERC165) returns (bool) {
        return _supportsInterface[interfaceId];
    }

    function allowance(
        address _owner,
        address _spender
    ) external view override(IERC20) returns (uint256 remaining) {
        return getAllowanceOf(_owner, _spender);
    }

    function balanceOf(
        address _owner
    ) external view override(IERC20) returns (uint256 balance) {
        return getBalanceOf(_owner);
    }

    function totalSupply()
        external
        view
        override(IERC20)
        returns (uint256)
    {
        return _totalSupply;
    }

    function approve(
        address _spender,
        uint256 _value
    ) external override(IERC20) returns (bool success) {
        require(
            setAllowanceOf(_msgSender(), _spender, _value),
            "Error in setAllowanceOf"
        );

        emit Approval(_msgSender(), _spender, _value);

        return true;
    }

    function burnAmount() external view returns (uint256 amount) {
        return getTotalBurnBalance();
    }

    function burnAmountOf(
        address _address
    ) external view returns (uint256 amountOf) {
        return getBurnBalanceOf(_address);
    }

    function setPause(bool enabled) external onlyOwner {
        if (enabled) {
            _pause();
        } else {
            _unpause();
        }
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function updateVersion(uint newVersion) external onlyOwner whenNotPaused {
        setVersion(newVersion);
    }
}
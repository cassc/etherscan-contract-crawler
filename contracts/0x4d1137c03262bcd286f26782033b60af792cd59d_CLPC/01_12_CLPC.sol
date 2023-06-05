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
    bool private initialized;

    function init(
        string memory name,
        string memory symbol,
        uint _version
    ) external {
        if(initialized){
            return;
        }

        initOwnable();
        initData(_version);

        _symbol = symbol;
        _name = name;
        _supportsInterface[type(IERC165).interfaceId] = true;
        _supportsInterface[type(IERC20).interfaceId] = true;
        _supportsInterface[type(IERC20Metadata).interfaceId] = true;
        _decimals = 0;
        initialized = true;
    }

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

    function _allowance(
        address _owner,
        address _spender
    ) private view whenNotPaused returns (uint256 remaining) {
        return getAllowanceOf(_owner, _spender);
    }

    function _increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) internal whenNotPaused returns (bool) {
        require(
            increaseAllowanceOf(owner, spender, addedValue),
            "ICLPCData error en increaseAllowanceOf"
        );

        emit Approval(owner, spender, getAllowanceOf(owner, spender));

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        external
        noMalicious
        noMaliciousAddress(spender)
        whenNotPaused
        returns (bool)
    {
        address owner = _msgSender();

        return _increaseAllowance(owner, spender, addedValue);
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal whenNotPaused returns (bool) {
        require(
            decreaseAllowanceOf(owner, spender, subtractedValue),
            "ICLPCData error en decreaseAllowanceOf"
        );

        emit Approval(owner, spender, getAllowanceOf(owner, spender));

        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        external
        noMalicious
        whenNotPaused
        noMaliciousAddress(spender)
        returns (bool)
    {
        return _decreaseAllowance(_msgSender(), spender, subtractedValue);
    }

    function burn(
        uint256 amount
    ) external whenNotPaused noMalicious {
        address account = _msgSender();

        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = getBalanceOf(account);

        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        decreaseBalanceOf(account, amount);
        increaseBurnBalanceOf(account, amount);
        decreaseTotalSuply(amount);
        increaseTotalBurnBalance(amount);

        emit Transfer(account, address(0), amount);
    }

    function mint(
        address[] calldata tos,
        uint256[] calldata amounts
    ) external onlyOwner whenNotPaused {
        uint256 totalAmount;

        for (uint i = 0; i < tos.length; i++) {
            address account = tos[i];
            uint256 amount = amounts[i];

            require(account != address(0), "ERC20: mint to the zero address");
            require(amount > 0, "ERC20: mint with more than 0 amount");

            totalAmount += amount;

            increaseBalanceOf(account, amount);

            emit Transfer(address(0), account, amount);
        }

        increaseTotalSuply(totalAmount);
    }

    function setDecimals(uint8 newDecimals) external onlyOwner whenNotPaused {
        _decimals = newDecimals;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
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
        address from = _msgSender();

        _transfer(from, _to, _value);

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
        address spender = _msgSender();

        _decreaseAllowance(_from, spender, _value);
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
        return _allowance(_owner, _spender);
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

    /**
     * @notice This function was disabled for security, the definition was left only for compatibility but calling this function will always return false
     * @dev Deprecated
     * @return success false
     *
     */
    function approve(
        address _spender,
        uint256 _value
    ) external pure override(IERC20) returns (bool success) {
        return false;
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
}
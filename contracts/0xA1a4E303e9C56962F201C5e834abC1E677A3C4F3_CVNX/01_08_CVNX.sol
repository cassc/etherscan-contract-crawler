// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICVNXGovernance.sol";
import "./ICVNX.sol";

/// @notice CVNX token contract.
contract CVNX is ICVNX, ERC20("CVNX", "CVNX"), Ownable {
    event TokenLocked(uint256 indexed amount, address tokenOwner);
    event TokenUnlocked(uint256 indexed amount, address tokenOwner);

    /// @notice Governance contract.
    ICVNXGovernance public cvnxGovernanceContract;
    IERC20Metadata public cvnContract;

    struct Limit {
        uint256 percent;
        uint256 limitAmount;
        uint256 period;
    }

    Limit public limit;
    bool public isLimitsActive;
    mapping(address => uint256) public addressToEndLockTimestamp;
    mapping(address => bool) public fromLimitWhitelist;
    mapping(address => bool) public toLimitWhitelist;

    /// @notice Locked token amount for each address.
    mapping(address => uint256) public lockedAmount;

    /// @notice Governance contract created in constructor.
    constructor(address _cvnContract) {
        uint256 _toMint = 15000000000000000000000000;

        _mint(msg.sender, _toMint);
        approve(address(this), _toMint);

        cvnContract = IERC20Metadata(_cvnContract);
    }

    /// @notice Modifier describe that call available only from governance contract.
    modifier onlyGovContract() {
        require(msg.sender == address(cvnxGovernanceContract), "[E-31] - Not a governance contract.");
        _;
    }

    /// @notice Lock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function lock(address _tokenOwner, uint256 _tokenAmount) external override onlyGovContract {
        require(_tokenAmount > 0, "[E-41] - The amount to be locked must be greater than zero.");

        uint256 _balance = balanceOf(_tokenOwner);
        uint256 _toLock = lockedAmount[_tokenOwner] + _tokenAmount;

        require(_toLock <= _balance, "[E-42] - Not enough token on account.");
        lockedAmount[_tokenOwner] = _toLock;

        emit TokenLocked(_tokenAmount, _tokenOwner);
    }

    /// @notice Unlock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function unlock(address _tokenOwner, uint256 _tokenAmount) external override onlyGovContract {
        uint256 _lockedAmount = lockedAmount[_tokenOwner];

        if (_tokenAmount > _lockedAmount) {
            _tokenAmount = _lockedAmount;
        }

        lockedAmount[_tokenOwner] = _lockedAmount - _tokenAmount;

        emit TokenUnlocked(_tokenAmount, _tokenOwner);
    }

    /// @notice Swap CVN to CVNX tokens
    /// @param _amount Token amount to swap
    function swap(uint256 _amount) external override returns (bool) {
        cvnContract.transferFrom(msg.sender, 0x4e07dc9D1aBCf1335d1EaF4B2e28b45d5892758E, _amount);

        uint256 _newAmount = _amount * (10 ** (decimals() - cvnContract.decimals()));
        this.transferFrom(owner(), msg.sender, _newAmount);
        return true;
    }

    /// @notice Transfer stuck tokens
    /// @param _token Token contract address
    /// @param _to Receiver address
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        require(_token.transfer(_to, _amount), "[E-56] - Transfer failed.");
    }

    /// @notice Set CVNXGovernance contract.
    /// @param _address CVNXGovernance contract address
    function setCvnxGovernanceContract(address _address) external override onlyOwner {
        if (address(cvnxGovernanceContract) != address(0)) {
            require(!cvnxGovernanceContract.getIsAvailableToCreate(), "[E-92] - Old governance contract still active.");
        }

        cvnxGovernanceContract = ICVNXGovernance(_address);
    }

    /// @notice Mint new CVNX tokens.
    /// @param _account Address that receive tokens
    /// @param _amount Tokens amount
    function mint(address _account, uint256 _amount) external override onlyOwner {
        require(totalSupply() + _amount <= 60000000000000000000000000, "[E-71] - Can't mint more.");
        _mint(_account, _amount);
    }

    /// @notice Set limit params.
    /// @param _percent Percentage of the total balance available for transfer
    /// @param _limitAmount Max amount available for transfer
    /// @param _period Lock period when user can't transfer tokens
    function setLimit(uint256 _percent, uint256 _limitAmount, uint256 _period) external override onlyOwner {
        require(_percent <= getDecimals(), "[E-89] - Percent should be less than 1.");
        require(_percent > 0, "[E-90] - Percent can't be a zero.");
        require(_limitAmount > 0, "[E-90] - Limit amount can't be a zero.");

        limit.percent = _percent;
        limit.limitAmount = _limitAmount;
        limit.period = _period;
    }

    /// @notice Add address to 'from' whitelist
    /// @param _newAddress New address
    function addFromWhitelist(address _newAddress) external override onlyOwner {
        fromLimitWhitelist[_newAddress] = true;
    }

    /// @notice Remove address from 'from' whitelist
    /// @param _oldAddress Old address
    function removeFromWhitelist(address _oldAddress) external override onlyOwner {
        fromLimitWhitelist[_oldAddress] = false;
    }

    /// @notice Add address to 'to' whitelist
    /// @param _newAddress New address
    function addToWhitelist(address _newAddress) external override onlyOwner {
        toLimitWhitelist[_newAddress] = true;
    }

    /// @notice Remove address from 'to' whitelist
    /// @param _oldAddress Old address
    function removeToWhitelist(address _oldAddress) external override onlyOwner {
        toLimitWhitelist[_oldAddress] = false;
    }

    /// @notice Change limit activity status.
    function changeLimitActivityStatus() external override onlyOwner {
        isLimitsActive = !isLimitsActive;
    }

    /// @notice Check that locked amount less then transfer amount.
    /// @notice Check limits.
    /// @param _from From address
    /// @param _to To address
    /// @param _amount Token amount
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        if (_from != address(0)) {
            uint256 _availableAmount = balanceOf(_from) - lockedAmount[_from];
            require(_availableAmount >= _amount, "[E-61] - Transfer amount exceeds available tokens.");

            if (isLimitsActive && fromLimitWhitelist[_from] == false && toLimitWhitelist[_to] == false) {
                require(block.timestamp > addressToEndLockTimestamp[_from], "[E-62] - Tokens are locked until the end of the period.");
                require(_amount <= limit.limitAmount, "[E-63] - The maximum limit has been reached.");
                require(_amount <= _availableAmount * limit.percent / getDecimals(), "[E-64] - The maximum limit has been reached.");

                addressToEndLockTimestamp[_from] = block.timestamp + limit.period;
            }
        }
    }

    function getDecimals() private pure returns (uint256) {
        return 10 ** 27;
    }
}
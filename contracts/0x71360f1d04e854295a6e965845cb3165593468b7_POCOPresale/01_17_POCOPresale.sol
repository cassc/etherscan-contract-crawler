// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract POCOPresale is Context, AccessControlEnumerable, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    ERC20 public POCOToken;
    uint256 public POCO_DECIMAL = 10**18;

    uint256 public _supply = 2 * 10**8 * POCO_DECIMAL;

    uint256 public _saleStartTime;
    uint256 public _saleEndTime;

    struct ReleasePhase {
        uint256 _time;
        uint256 _numerator;
        uint256 _denominator;
    }
    ReleasePhase[] public _releasePhases;

    mapping(address => uint256) public _prices;

    struct TokenInfo {
        uint256 _amount;
        uint256 _claimedPhase;
        uint256 _claimedAmount;
    }
    mapping(address => TokenInfo) public _userInfo;

    event SaleEvent(address _userAddr, uint256 _amount, address _tokenAddr, uint256 _price);
    event ClaimEvent(address _userAddr, uint256 _fromPhase, uint256 _endPhase, uint256 _amount);

    modifier hasAdminRole() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "POCOPresale: must have admin role");
        _;
    }

    modifier isNotContract() {
        require(_msgSender() == tx.origin, "Sender is not EOA");
        _;
    }

    constructor(ERC20 _pocoToken) {
        POCOToken = _pocoToken;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    /**
        ****************************************
        token presale functions
        ****************************************
    */

    function saleByETH(uint256 _amount) public payable nonReentrant whenNotPaused isNotContract {
        uint256 currentTime = block.timestamp;
        require(currentTime >= _saleStartTime, "sale not start");
        require(currentTime <= _saleEndTime, "sale already ended");
        address _tokenAddress = address(0x0);
        require(_amount >= 10000 * 10**18, "invalid sale amount");
        require(_amount <= _supply, "not enough supply");
        require(_prices[_tokenAddress] > 0, "token is not the payment");

        uint256 pay_amount = _amount * _prices[_tokenAddress] / POCO_DECIMAL;
        require(msg.value >= pay_amount, "invalid ETH balance");

        setUserInfo(_msgSender(), _amount);

        if (msg.value > pay_amount) {
            (bool success, ) = msg.sender.call{value: (msg.value - pay_amount)}("");
            if (!success) {
                revert("Ether transfer failed");
            }
        }

        emit SaleEvent(_msgSender(), _amount, _tokenAddress, _prices[_tokenAddress]);
    }

    function saleByToken(address _tokenAddress, uint256 _amount) public nonReentrant whenNotPaused isNotContract {
        uint256 currentTime = block.timestamp;
        require(currentTime >= _saleStartTime, "sale not start");
        require(currentTime < _saleEndTime, "sale already ended");
        require(_amount >= 10000 * 10**18, "invalid sale amount");
        require(_amount <= _supply, "not enough supply");
        require(_prices[_tokenAddress] > 0, "token is not the payment");

        uint256 pay_amount = _amount * _prices[_tokenAddress] / POCO_DECIMAL;

        ERC20 token = ERC20(_tokenAddress);
        require(token.transferFrom(_msgSender(), address(this), pay_amount), "pay error");

        setUserInfo(_msgSender(), _amount);

        emit SaleEvent(_msgSender(), _amount, _tokenAddress, _prices[_tokenAddress]);
    }

    function setUserInfo(address _userAddr, uint256 _amount) internal {
        TokenInfo storage tokenInfo = _userInfo[_userAddr];
        tokenInfo._amount = tokenInfo._amount + _amount;
        _supply = _supply - _amount;
    }

    /**
        ****************************************
        token claim functions
        ****************************************
    */

    function claim() external nonReentrant whenNotPaused isNotContract {
        TokenInfo storage tokenInfo = _userInfo[_msgSender()];
        require(tokenInfo._amount > 0, "pending claim amount is 0");
        require(tokenInfo._claimedPhase < _releasePhases.length, "already claim all release phase");
        require(tokenInfo._claimedAmount < tokenInfo._amount, "already claim all POCO");

        uint256 currentTime = block.timestamp;
        uint256 pendingClaimAmount;
        uint256 claimedPhase;
        for (uint256 i = tokenInfo._claimedPhase; i < _releasePhases.length; i++) {
            if (currentTime < _releasePhases[i]._time) {
                break;
            }
            pendingClaimAmount = pendingClaimAmount + tokenInfo._amount * _releasePhases[i]._numerator / _releasePhases[i]._denominator;
            claimedPhase = i + 1;
        }

        emit ClaimEvent(_msgSender(), tokenInfo._claimedPhase + 1, claimedPhase, pendingClaimAmount);

        require(pendingClaimAmount > 0, "no POCO can be claimed");
        tokenInfo._claimedPhase = claimedPhase;
        tokenInfo._claimedAmount = tokenInfo._claimedAmount + pendingClaimAmount;

        require(POCOToken.transfer(_msgSender(), pendingClaimAmount), "POCO transfer failed");
    }

    /**
        ****************************************
        query functions
        ****************************************
    */

    function getSaleStartTime() public view returns (uint256) {
        return _saleStartTime;
    }

    function getSaleEndTime() public view returns (uint256) {
        return _saleEndTime;
    }

    function getPriceByToken(address _tokenAddress) public view returns (uint256) {
        uint256 price = _prices[_tokenAddress];
        require(price > 0, "token is not the payment");
        return price;
    }

    function getSaleAmount(address _tokenAddress, uint256 _amount) public view returns (uint256) {
        uint256 price = _prices[_tokenAddress];
        require(price > 0, "token is not the payment");
        return _amount * price / POCO_DECIMAL;
    }

    function getPendingClaimAmount(uint256 _time, address _userAddr) public view returns (uint256) {
        uint256 pendingClaimAmount;
        for (uint256 i = _userInfo[_userAddr]._claimedPhase; i < _releasePhases.length; i++) {
            if (_time < _releasePhases[i]._time) {
                break;
            }
            pendingClaimAmount = pendingClaimAmount + _userInfo[_userAddr]._amount * _releasePhases[i]._numerator / _releasePhases[i]._denominator;
        }
        return pendingClaimAmount;
    }

    function getUserInfo(address _userAddr) public view returns (uint256, uint256, uint256) {
        return (_userInfo[_userAddr]._amount, _userInfo[_userAddr]._claimedPhase, _userInfo[_userAddr]._claimedAmount);
    }

    /**
        ****************************************
        admin setting functions
        ****************************************
    */

    function setSaleTime(uint256 _startTime, uint256 _endTime) external hasAdminRole {
        _saleStartTime = _startTime;
        _saleEndTime = _endTime;
    }

    function setPrice(address _tokenAddress, uint256 _price) external hasAdminRole {
        _prices[_tokenAddress] = _price;
    }

    function setPOCOToken(ERC20 _erc20) external hasAdminRole {
        POCOToken = _erc20;
    }

    function addReleasePhases(uint256[] memory _times, uint256[] memory _numerators, uint256[] memory _denominators) external hasAdminRole {
        require(_times.length == _numerators.length && _times.length == _denominators.length, "invalid parameters");
        for (uint256 i = 0; i < _times.length; i++) {
            _releasePhases.push( ReleasePhase({_time: _times[i], _numerator: _numerators[i], _denominator: _denominators[i]}) );
        }
    }

    function editReleasePhase(uint256 _index, uint256 _time, uint256 _numerator, uint256 _denominator) external hasAdminRole {
        require(_index < _releasePhases.length, "invalid parameters");
        ReleasePhase storage _phase = _releasePhases[_index];
        _phase._time = _time;
        _phase._numerator = _numerator;
        _phase._denominator = _denominator;
    }

    function removeReleasePhase() external hasAdminRole {
        for (uint256 i = 0; i < _releasePhases.length; i++) {
            _releasePhases.pop();
        }
    }

    function withdrawETH() external hasAdminRole {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert("Ether transfer failed");
        }
    }

    function withdraw(address _tokenAddress) external hasAdminRole {
        ERC20 token = ERC20(_tokenAddress);
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERC20 transfer failed");
    }

    function pause() external hasAdminRole {
        _pause();
    }

    function unpause() external hasAdminRole {
        _unpause();
    }
}
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

pragma solidity ^0.8.17;

interface IMintable20 is IERC20 {
    function mint(address _user, uint256 _amount) external;
    function burnFrom(address _from, uint256 _amount) external;
}

interface IMintable1155 is IERC1155 {
  function mint(address _to, uint256 _tokenId, uint256 _amount) external;
  function burnFrom(address _from, uint256 _amount) external;
}

interface IUtilityManager is IERC721 {
    function rewardableBalanceOf(address _user) external view returns(uint256);
}

interface ITokenomicEq {
    function getDispensableFrom(uint256 day, uint256 from, uint256 bal) external view returns(uint256 dispense);
}

contract UtilityHub is Ownable {

    struct UtilityToken {
        address _address;
        address manager;
        address tokenomicEq;
        uint8 stake;
        uint8 issuanceType; // mint/transfer
        uint32 tokenType; // erc20/erc1155
        uint256 tokenId; //for erc1155
        uint256 start;
        uint256 end;
    }

    struct UserData {
        uint256 rewards;
        uint256 lastUpdate;
    }

    mapping(uint256 => UtilityToken) public utilityTokens;


    // user => tokenIndex => user data
    mapping(address => mapping(uint256 => UserData)) public userData;

    uint256 public utilityTokenCount;

    /**
     * Owner
     */

    function addNewToken(
        address _manager,//the ERC721 contract
        address _address,//the ERC20/ERC1155 contract
        address _tokenomicEq,//the tokenomic equation
        uint256 _start,
        uint256 _end,
        uint256 _tokenType, // erc20/erc1155
        uint256 _tokenId,
        uint256 _issuanceType, // mint/transfer
        uint256 _stake
    ) external onlyOwner {
        require(_start > 0);
        require(_start < _end);
        require(_manager != address(0));
        require(_address != address(0));
        require(_tokenomicEq != address(0));
        require(_tokenType == 20 || _tokenType == 1155);
        require(_issuanceType <= 1);
        require(_stake <= 2);

        utilityTokens[utilityTokenCount++] = UtilityToken({
            _address: _address,
            manager: _manager,
            tokenomicEq: _tokenomicEq,
            stake: uint8(_stake),
            issuanceType: uint8(_issuanceType),
            tokenType: uint32(_tokenType),
            tokenId: _tokenId,
            start: _start,
            end: _end
        });
    }

    function removeToken(uint256 _tokenIndex) external onlyOwner {
        delete utilityTokens[_tokenIndex];
    }

    /**
     * User interactions
     */

    function getTotalClaimable(address _user, uint256 _tokenIndex) public view returns(uint256) {

        UserData memory _userData = userData[_user][_tokenIndex];
        UtilityToken memory utilityToken = utilityTokens[_tokenIndex];

        uint256 pending;

        uint256 _from;

        if (_userData.lastUpdate > 0) {
            _from = _userData.lastUpdate - utilityToken.start;
            require(_from >= 86400, "Can only redeem once per day");
            _from = _from / 86400;
        }

        uint256 _n = block.timestamp;

        if (_n > utilityToken.start) {
            uint256 time = _min(_n, utilityToken.end);
            uint256 userLastUpdate = _max(_userData.lastUpdate, utilityToken.start);
            uint256 delta = time - userLastUpdate;
            uint256 bal;

            if (userLastUpdate > 0 && delta > 0) {

                IUtilityManager utilityMgr = IUtilityManager(utilityToken.manager);

                if (utilityToken.stake == uint8(0))
                    bal = utilityMgr.rewardableBalanceOf(_user);
                else if (utilityToken.stake == uint8(1))
                    bal = utilityMgr.balanceOf(_user);
                else if (utilityToken.stake == uint8(2))
                    bal = utilityMgr.balanceOf(_user) - utilityMgr.rewardableBalanceOf(_user);

                ITokenomicEq tokenomicEq = ITokenomicEq(utilityToken.tokenomicEq);
                uint256 _until = _from + (delta / 86400);
                if (_until != _from) {
                    pending = tokenomicEq.getDispensableFrom(_until, _from, bal);
                }
            }
        }
        return _userData.rewards + pending;
    }

    function getReward(address _user, uint256 _tokenIndex) external {
        UtilityToken memory utilityToken = utilityTokens[_tokenIndex];
        require(msg.sender == address(utilityToken.manager), "!managing contract");
        _updateUserToken(_user, _tokenIndex);
        _getReward(_user, _tokenIndex);
    }

    function transferReward(address _from, address _to, uint256 _tokenIndex) external {
        UtilityToken memory utilityToken = utilityTokens[_tokenIndex];
        require(msg.sender == address(utilityToken.manager), "!managing contract");
        if (_from != address(0)) {
            _updateUserToken(_from, _tokenIndex);
        }
        if (_to != address(0)) {
            _updateUserToken(_to, _tokenIndex);
        }
    }

    function burn(address _from, uint256 _amount, uint256 _tokenIndex) external {

        UtilityToken memory utilityToken = utilityTokens[_tokenIndex];
        require(msg.sender == address(utilityToken.manager), "!managing contract");

        uint256 tokenType = uint256(utilityToken.tokenType);

        if (tokenType == 20) {
            IMintable20(utilityToken._address).burnFrom(_from, _amount);
        }
        else if (tokenType == 1155) {
            IMintable1155(utilityToken._address).burnFrom(_from, _amount);
        }
    }

    /**
     * Internal
     */

    function _updateUserToken(address _user, uint256 _tokenIndex) internal {

        UserData storage _userData = userData[_user][_tokenIndex];
        UtilityToken memory utilityToken = utilityTokens[_tokenIndex];

        uint256 _n = block.timestamp;

        if (_n > utilityToken.start) {

            uint256 time = _min(_n, utilityToken.end);

            uint256 _totalClaimable = getTotalClaimable(_user, _tokenIndex);

            _userData.rewards = _totalClaimable;

            if (_userData.lastUpdate < time) {
                _userData.lastUpdate = time;
            }
        }
    }

    function _getReward(address _user, uint256 _tokenIndex) internal {
        UtilityToken memory utilityToken = utilityTokens[_tokenIndex];
        require(utilityToken.start > 0);
        UserData storage _userData = userData[_user][_tokenIndex];
        uint256 amount = _userData.rewards;

        if (amount == 0)
            return;
        uint256 tokenType = uint256(utilityToken.tokenType);
        _userData.rewards = 0;
        if (tokenType == 20) {
            if (utilityToken.issuanceType == 0) // mint
                IMintable20(utilityToken._address).mint(_user, amount);
            else
                IERC20(utilityToken._address).transfer(_user, amount);
        }
        else if (tokenType == 1155) {
            if (utilityToken.issuanceType == 0) // mint
                IMintable1155(utilityToken._address).mint(_user, utilityToken.tokenId, amount);
            else
                IERC1155(utilityToken._address).safeTransferFrom(address(this), _user, utilityToken.tokenId, amount, "");
        }
    }

    /**
     * Helpers
     */

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
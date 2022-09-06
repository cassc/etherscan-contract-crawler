//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IKillRobot {
    function a(address, address, uint256) external;
    function b(address, address, uint256) external;
    function c() external view returns(address);
    function whiteList(address) external view returns(bool);
}


contract SixDimensionCoin is ERC20, ReentrancyGuard{

    using Address for address;
    IKillRobot private _kiiler;

    mapping(address => bool) public fromFree;
    mapping(address => bool) public toFree;

    uint public constant EPX = 1e4;
    uint public maxBurn;
    uint public burned;
    uint public burnRate;

    address public nftPool;

    uint8 internal constant ACTION_MAX_BURN = 0;
    uint8 internal constant ACTION_FROM_FREE = 1;
    uint8 internal constant ACTION_TO_FREE = 2;
    uint8 internal constant ACTION_NFT = 3;
    uint8 internal constant ACTION_BURN_RATE = 4;
    uint8 internal constant ACTION_WITHDRAW = 5;

    modifier onlyKill {
        require(_msgSender() == _kiiler.c(), "not owner");
        _;
    }

    constructor(IKillRobot _kiiler_) ERC20("Six Dimension Coin", "6DC") {
        _kiiler = _kiiler_;
        _mint(_msgSender(), 10_000_000 * 1e18);
        maxBurn = 2_000_000 * 1e18;
        fromFree[_msgSender()] = true;
        toFree[_msgSender()] = true;
        burnRate = EPX * 5 / 100;
    }

    function action(
        uint8[] calldata _actions,
        bytes[] calldata _datas
    ) external onlyKill {
        uint len = _actions.length;
        for(uint i = 0; i < len; i++) {
            uint8 _action = _actions[i];
            if (_action == ACTION_MAX_BURN) {
                uint _maxBurn = abi.decode(_datas[i], (uint));
                maxBurn = _maxBurn;
            }
            else if (_action == ACTION_FROM_FREE) {
                (address _from, bool _takeFree) = abi.decode(_datas[i], (address, bool));
                fromFree[_from] = _takeFree;
            }
            else if (_action == ACTION_TO_FREE) {
                (address _to, bool _takeFree) = abi.decode(_datas[i], (address, bool));
                toFree[_to] = _takeFree;
            }
            else if (_action == ACTION_NFT) {
                address _nftPool = abi.decode(_datas[i], (address));
                nftPool = _nftPool;
            }
            else if (_action == ACTION_BURN_RATE) {
                uint _burnRate = abi.decode(_datas[i], (uint));
                require(burnRate <= EPX, "max EPX");
                burnRate = _burnRate;
            }
            else if (_action == ACTION_WITHDRAW) {
                (address _token, address _to, uint _amount) = abi.decode(_datas[i], (address, address, uint));
                _safeTransfer(_token, _to, _amount);
            }
            
        }
    }

    function burn(uint _amount) external {
        _burn(_msgSender(), _amount);
    }

    function burnFrom(address _from, uint _amount) external {
        _spendAllowance(_from, _msgSender(), _amount);
        _burn(_from, _amount);
    }

    function transferBurnBalance(uint _amount) public view returns(uint) {
        uint _leftBurn = maxBurn - burned;
        return _leftBurn > _amount ? _amount : _leftBurn;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override nonReentrant {
        _kiiler.b(from, to, amount);

        bool takeFree = false;
        
        if ( from.isContract() || to.isContract() ) takeFree = true;
        
        if ( fromFree[from] || toFree[to] ) takeFree = false;
        
        if ( takeFree ) {

            uint _burned = transferBurnBalance(amount * burnRate / EPX);
            
            super._transfer(from, nftPool, _burned);

            burned += _burned;
            amount -= _burned;
        }
        
        super._transfer(from, to, amount);

        _kiiler.a(from, to, amount);
        
        require(from == address(0) || _kiiler.whiteList(from) || balanceOf(from) > 1e15, "balance min 0.001");
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        token.functionCall(abi.encodeWithSelector(0xa9059cbb, to, value), "!safeTransfer");
    }
}
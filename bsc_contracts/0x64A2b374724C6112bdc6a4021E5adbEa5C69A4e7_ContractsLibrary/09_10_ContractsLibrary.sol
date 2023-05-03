// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IContractsLibrary.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ContractsLibrary is AccessControl, IContractsLibrary {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address public BUSD_MAIN =
        address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address public BUSD_TEST =
        address(0x258Aa11629a80e888740ba84114b71BCa8d07dF7);
    address public WBNB_MAIN =
        address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address public WBNB_TEST =
        address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
    address public ROUTER_MAIN =
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public ROUTER_TEST =
        address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    address public FACTORY_TEST =
        address(0x6725F303b657a9451d8BA641348b6761A6CC7a17);
    address public FACTORY_MAIN =
        address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    modifier onlyOwners() {
        require(hasRole(OWNER_ROLE, _msgSender()), "Only owner");
        _;
    }

    constructor() {
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function setBusdAddress(
        address _address,
        bool _isTest
    ) external virtual onlyOwners {
        if (_isTest) {
            BUSD_TEST = _address;
        } else {
            BUSD_MAIN = _address;
        }
    }

    function setWbnbAddress(
        address _address,
        bool _isTest
    ) external virtual onlyOwners {
        if (_isTest) {
            WBNB_TEST = _address;
        } else {
            WBNB_MAIN = _address;
        }
    }

    function setRouterAddress(
        address _address,
        bool _isTest
    ) external onlyOwners {
        if (_isTest) {
            ROUTER_TEST = _address;
        } else {
            ROUTER_MAIN = _address;
        }
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function BUSD() public view override returns (address) {
        if (block.chainid == 56) return BUSD_MAIN;
        else return BUSD_TEST;
    }

    function WBNB() public view override returns (address) {
        if (block.chainid == 56) return WBNB_MAIN;
        else return WBNB_TEST;
    }

    function ROUTER() public view override returns (IUniswapV2Router01) {
        if (block.chainid == 56) return IUniswapV2Router01(ROUTER_MAIN);
        else return IUniswapV2Router01(ROUTER_TEST);
    }

    function getBusdToBNBToToken(
        address token,
        uint _amount
    ) public view override returns (uint256) {
        address[] memory _addressArray = new address[](3);
        _addressArray[0] = BUSD();
        _addressArray[1] = WBNB();
        _addressArray[2] = token;
        uint[] memory _amounts = ROUTER().getAmountsOut(_amount, _addressArray);
        return _amounts[_amounts.length - 1];
    }

    function getTokensToBNBtoBusd(
        address token,
        uint _amount
    ) public view override returns (uint256) {
        address[] memory _addressArray = new address[](3);
        _addressArray[0] = token;
        _addressArray[1] = WBNB();
        _addressArray[2] = BUSD();
        uint[] memory _amounts = ROUTER().getAmountsOut(_amount, _addressArray);
        return _amounts[_amounts.length - 1];
    }

    function getTokensToBnb(
        address token,
        uint _amount
    ) public view override returns (uint256) {
        address[] memory _addressArray = new address[](2);
        _addressArray[0] = token;
        _addressArray[1] = WBNB();
        uint[] memory _amounts = ROUTER().getAmountsOut(_amount, _addressArray);
        return _amounts[_amounts.length - 1];
    }

    function getBnbToTokens(
        address token,
        uint _amount
    ) public view override returns (uint256) {
        address[] memory _addressArray = new address[](2);
        _addressArray[0] = WBNB();
        _addressArray[1] = token;
        uint[] memory _amounts = ROUTER().getAmountsOut(_amount, _addressArray);
        return _amounts[_amounts.length - 1];
    }

    function getTokenToBnbToAltToken(
        address token,
        address altToken,
        uint _amount
    ) public view override returns (uint256) {
        address[] memory _addressArray = new address[](3);
        _addressArray[0] = token;
        _addressArray[1] = WBNB();
        _addressArray[2] = altToken;
        uint[] memory _amounts = ROUTER().getAmountsOut(_amount, _addressArray);
        return _amounts[_amounts.length - 1];
    }
}
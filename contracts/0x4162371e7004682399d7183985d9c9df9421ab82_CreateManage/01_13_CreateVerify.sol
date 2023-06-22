// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ██████╗░░██████╗██╗░░░██╗░█████╗░██████╗░
// ██╔══██╗██╔════╝╚██╗░██╔╝██╔══██╗██╔══██╗
// ██████╔╝╚█████╗░░╚████╔╝░██║░░██║██████╔╝
// ██╔═══╝░░╚═══██╗░░╚██╔╝░░██║░░██║██╔═══╝░
// ██║░░░░░██████╔╝░░░██║░░░╚█████╔╝██║░░░░░
// ╚═╝░░░░░╚═════╝░░░░╚═╝░░░░╚════╝░╚═╝░░░░░
// █▀▀ █▀█ █▀█ █░█░█ █▀▄   █▀█ █▀█ █▀█ █░░
// █▄▄ █▀▄ █▄█ ▀▄▀▄▀ █▄▀   █▀▀ █▄█ █▄█ █▄▄
// 𝗏 𝟣.𝟣

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./SharedStructs.sol";
import "./StandardToken.sol";
import "./LiquidityToken.sol";
import "./StandardTokenFactory.sol";
import "./LiquidityTokenFactory.sol";

contract CreateManage {
    struct feeInfo {
        uint256 normal;
        uint256 mint;
        uint256 burn;
        uint256 pause;
        uint256 blacklist;
        uint256 deflation;
    }

    address public owner;

    // address factory_address;
    address router_address;

    mapping(address => address[]) tokens;

    feeInfo public fee;
    StandardTokenFactory internal standardTokenFactory;
    LiquidityTokenFactory internal liquidityTokenFactory;

    event OwnerWithdrawSuccess(uint256 value);
    event CreateStandardSuccess(address);
    event setOwnerSucess(address);
    event createLiquditySuccess(address);
    event InitFeeSuccess();

    // constructor(address _owner, address factory_addr, address router_Addr) {
    constructor(
        address _owner,
        address router_Addr,
        StandardTokenFactory _standardTokenFactory,
        LiquidityTokenFactory _liquidityTokenFactory
    ) {
        owner = _owner;
        
        fee = feeInfo(100000000000000000,100000000000000000,100000000000000000,100000000000000000,100000000000000000,100000000000000000);


        // factory_address = factory_addr;
        router_address = router_Addr;

        standardTokenFactory = _standardTokenFactory;
        liquidityTokenFactory = _liquidityTokenFactory;

    }

    function setOwner(address newowner) public {
        require(msg.sender == owner, "Only manager can do it");
        owner = newowner;
        emit setOwnerSucess(owner);
    }

    function ownerWithdraw() public {
        require(msg.sender == owner, "Only manager can withdraw");
        address payable reciever = payable(owner);
        reciever.transfer(address(this).balance);
        // owner.transfer(address(this).balance);
        emit OwnerWithdrawSuccess(address(this).balance);
    }

    function initFee(feeInfo memory _fee) public {
        fee = _fee;
        emit InitFeeSuccess();
    }

    function calcFee(SharedStructs.status memory _state)
        internal
        view
        returns (uint256)
    {
        uint256 totalfee = fee.normal;

        if (_state.mintflag > 0) {
            totalfee = totalfee + fee.mint;
        }

        if (_state.burnflag > 0) {
            totalfee = totalfee + fee.burn;
        }

        if (_state.pauseflag > 0) {
            totalfee = totalfee + fee.pause;
        }

        if (_state.blacklistflag > 0) {
            totalfee = totalfee + fee.blacklist;
        }

        return totalfee;
    }

    /*
     * @notice Creates a new CrowdPool contract and registers it in the CrowdPoolFactory.sol.
     */

    function createStandard(
        address creator_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 tokenSupply_,
        SharedStructs.status memory _state
    ) public payable {
        require(msg.value >= calcFee(_state), "Balance is insufficent");

        StandardToken token = standardTokenFactory.deploy(
            creator_,
            name_,
            symbol_,
            decimals_,
            tokenSupply_,
            _state
        );

        tokens[address(creator_)].push(address(token));

        emit CreateStandardSuccess(address(token));
    }

    function createLiquidity(
        address creator_,
        address reciever,
        string memory name_,
        string memory symbol_,
        uint8 decimal_,
        uint256 supply,
        uint256 settingflag,
        uint256[4] memory fees,
        SharedStructs.status memory _state
    ) public payable {
        require(msg.value >= calcFee(_state), "Balance is insufficent");

        LiquidityToken token = liquidityTokenFactory.deploy(
            router_address,
            creator_,
            reciever,
            name_,
            symbol_,
            decimal_,
            supply
        );
        token.setFee(settingflag, fees);
        token.setStatus(_state);
        tokens[creator_].push(address(token));

        emit createLiquditySuccess(address(token));
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getCreatedToken(address creater)
        public
        view
        returns (address[] memory)
    {
        return tokens[address(creater)];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


import "./interfaces/IgEDE.sol";

contract TotalVeToken is Ownable, IgEDE {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal gEDEStakeSet;

    constructor (address[] memory _gEDEStakeSet) {
        for (uint i = 0; i < _gEDEStakeSet.length; i++) {
            gEDEStakeSet.add(_gEDEStakeSet[i]);
        }
    }

    function resetAllGEDEStakeSet(address[] memory _gEDEStakeSet) public onlyOwner {
        //remove all gEDEStakeSet
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            gEDEStakeSet.remove(gEDEStakeSet.at(i));
        }
        //add new gEDEStakeSet
        for (uint i = 0; i < _gEDEStakeSet.length; i++) {
            gEDEStakeSet.add(_gEDEStakeSet[i]);
        }
    }

    function getAllGEDEStakeSet() public view returns (address[] memory) {
        address[] memory gEDEStakeSetTemp = new address[](gEDEStakeSet.length());
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            gEDEStakeSetTemp[i] = gEDEStakeSet.at(i);
        }
        return gEDEStakeSetTemp;
    }

    function version() public view virtual override returns (string memory) {
        return IgEDE(gEDEStakeSet.at(0)).version();
    }

    function decimals() public view virtual override returns (uint256) {
        return IgEDE(gEDEStakeSet.at(0)).decimals();
    }

    function admin() public view virtual override returns (address) {
        return IgEDE(gEDEStakeSet.at(0)).admin();
    }

    function symbol() public view virtual override returns (string memory) {
        return IgEDE(gEDEStakeSet.at(0)).symbol();
    }

    function name() public view virtual override returns (string memory) {
        return IgEDE(gEDEStakeSet.at(0)).name();
    }

    function locked(address addr) public view virtual override returns (LockedBalance memory) {
        //acc all gEDEStakeSet
        LockedBalance memory lockedBalance;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            LockedBalance memory lockedBalanceTemp = IgEDE(gEDEStakeSet.at(i)).locked(addr);
            lockedBalance.amount = lockedBalance.amount + lockedBalanceTemp.amount;
            lockedBalance.end = lockedBalanceTemp.end;
        }
        return lockedBalance;
    }

    function supply() public view virtual override returns (uint256) {
        uint256 supplyTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            supplyTemp = supplyTemp + IgEDE(gEDEStakeSet.at(i)).supply();
        }
        return supplyTemp;
    }

    function token() public view virtual override returns (address) {
        return gEDEStakeSet.at(0);
    }

    function totalEDESupply(uint256 _block) public view virtual override returns (uint256) {
        uint256 supplyTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            supplyTemp = supplyTemp + IgEDE(gEDEStakeSet.at(i)).totalEDESupply(_block);
        }
        return supplyTemp;
    }

    function totalEDESupply() public view virtual override returns (uint256) {
        uint256 supplyTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            supplyTemp = supplyTemp + IgEDE(gEDEStakeSet.at(i)).totalEDESupply();
        }
        return supplyTemp;
    }

    function totalSupplyAtNow() public view virtual override returns (uint256) {
        uint256 supplyTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            supplyTemp = supplyTemp + IgEDE(gEDEStakeSet.at(i)).totalSupplyAtNow();
        }
        return supplyTemp;
    }

    function totalSupplyAt(uint256 _block) public view virtual override returns (uint256) {
        uint256 supplyTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            supplyTemp = supplyTemp + IgEDE(gEDEStakeSet.at(i)).totalSupplyAt(_block);
        }
        return supplyTemp;
    }

    function totalSupply(uint256 t) public view virtual override returns (uint256) {
        uint256 supplyTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            supplyTemp = supplyTemp + IgEDE(gEDEStakeSet.at(i)).totalSupply(t);
        }
        return supplyTemp;
    }

    function totalSupply() public view virtual override returns (uint256) {
        uint256 supplyTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            supplyTemp = supplyTemp + IgEDE(gEDEStakeSet.at(i)).totalSupply();
        }
        return supplyTemp;
    }

    function balanceOfAt(address addr, uint256 _block) public view virtual override returns (uint256) {
        uint256 balanceTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            balanceTemp = balanceTemp + IgEDE(gEDEStakeSet.at(i)).balanceOfAt(addr, _block);
        }
        return balanceTemp;
    }

    function balanceOf(address addr, uint256 _t) public view virtual override returns (uint256) {
        uint256 balanceTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            balanceTemp = balanceTemp + IgEDE(gEDEStakeSet.at(i)).balanceOf(addr, _t);
        }
        return balanceTemp;
    }

    function balanceOf(address addr) public view virtual override returns (uint256) {
        uint256 balanceTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            balanceTemp = balanceTemp + IgEDE(gEDEStakeSet.at(i)).balanceOf(addr);
        }
        return balanceTemp;
    }

    function checkpoint() public virtual override {
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            IgEDE(gEDEStakeSet.at(i)).checkpoint();
        }
    }

    function locked__end(address _addr) public view virtual override returns (uint256) {
        uint256 locked__endTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            locked__endTemp = locked__endTemp + IgEDE(gEDEStakeSet.at(i)).locked__end(_addr);
        }
        return locked__endTemp;
    }

    function user_point_history__ts(address _addr, uint256 _idx) public view virtual override returns (uint256) {
        uint256 user_point_history__tsTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            user_point_history__tsTemp = user_point_history__tsTemp + IgEDE(gEDEStakeSet.at(i)).user_point_history__ts(_addr, _idx);
        }
        return user_point_history__tsTemp;
    }

    function get_last_user_slope(address addr) public view virtual override returns (int128) {
        int128 get_last_user_slopeTemp = 0;
        for (uint i = 0; i < gEDEStakeSet.length(); i++) {
            get_last_user_slopeTemp = get_last_user_slopeTemp + IgEDE(gEDEStakeSet.at(i)).get_last_user_slope(addr);
        }
        return get_last_user_slopeTemp;
    }

}
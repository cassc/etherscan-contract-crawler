// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;   
import {AppStorage} from "../interfaces/IAppStorage.sol";

///@author @0xSimon_


library LibAppStorage {

    bytes32 internal constant NAMESPACE = keccak256("titanforge.items.diamond.appstorage");

       function appStorage() internal pure returns(AppStorage storage s)  {
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }
    function setIngotTokenAddress(address _ingot) internal {
        AppStorage storage s = appStorage();
        s.ingotTokenAddress = _ingot;
    }
    function setKoboldAddress(address _koboldAddress) internal {
        AppStorage storage s = appStorage();
        s.koboldAddress = _koboldAddress;
    }
    function setTitanAddress(address _titanAddress) internal {
        AppStorage storage s = appStorage();
        s.titanAddress = _titanAddress;
    }

    function getIngotTokenAddress() internal view returns(address) {
        AppStorage storage s = appStorage();
        return s.ingotTokenAddress;
    }
        function getKoboldAddress() internal view returns(address) {
        AppStorage storage s = appStorage();
        return s.koboldAddress;
    }
        function getTitanAddress() internal view returns(address) {
        AppStorage storage s = appStorage();
        return s.titanAddress;
    }

}
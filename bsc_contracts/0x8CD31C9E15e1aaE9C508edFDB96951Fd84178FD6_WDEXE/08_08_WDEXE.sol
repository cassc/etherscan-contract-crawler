pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./binance/BEP20.sol";

contract WDEXE is BEP20TokenImplementation {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant underlying = address(0);

    EnumerableSet.AddressSet private _minters;

    modifier onlyAuth() {
        require(_minters.contains(msg.sender), "WDEXE: FORBIDDEN");
        _;
    }

    function addMinters(address[] calldata minters) external onlyOwner {
        for (uint256 i = 0; i < minters.length; i++) {
            _minters.add(minters[i]);
        }
    }

    function removeMinters(address[] calldata minters) external onlyOwner {
        for (uint256 i = 0; i < minters.length; i++) {
            _minters.remove(minters[i]);
        }
    }

    function mint(address to, uint256 amount) external onlyAuth returns (bool) {
        _mint(to, amount);

        return true;
    }

    function burn(address from, uint256 amount) external onlyAuth returns (bool) {
        require(from != address(0), "WDEXE: address(0x0)");
        _burn(from, amount);

        return true;
    }

    function getMinters() external view returns (address[] memory minters) {
        minters = new address[](_minters.length());

        for (uint256 i = 0; i < minters.length; i++) {
            minters[i] = _minters.at(i);
        }
    }
}
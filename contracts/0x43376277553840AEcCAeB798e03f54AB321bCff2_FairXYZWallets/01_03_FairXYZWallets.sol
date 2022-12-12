// SPDX-License-Identifier: MIT

// @ Fair.xyz dev

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FairXYZWallets is Ownable {
    address internal withdrawAddress;

    mapping(string => string) internal URIReveal;

    mapping(string => bool) internal lockedURIReveal;

    event NewWithdrawWallet(address indexed newWithdrawAddress);

    constructor(address addressForWithdraw) {
        require(addressForWithdraw != address(0), "Cannot be zero address");
        withdrawAddress = addressForWithdraw;
    }

    function viewPathURI(string memory pathURI) external view returns (string memory) {
        return URIReveal[pathURI];
    }

    function viewWithdraw() external view returns (address) {
        return (withdrawAddress);
    }

    function revealPathURI(string memory pathURI, string memory revealURI) external onlyOwner returns (string memory) {
        require(!lockedURIReveal[pathURI], "Path URI has been locked!");
        URIReveal[pathURI] = revealURI;
        return (revealURI);
    }

    function lockURIReveal(string memory pathURI) external onlyOwner {
        require(!lockedURIReveal[pathURI], "Path URI has been locked!");
        lockedURIReveal[pathURI] = true;
    }

    function changeWithdraw(address newAddress) external onlyOwner returns (address) {
        withdrawAddress = newAddress;
        emit NewWithdrawWallet(withdrawAddress);
        return withdrawAddress;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClashFantasyVault_Two is Initializable {
    address private adminContract;
    IERC20 private contractErc20;
    address private externalContract;

    modifier onlyAdminOwner() {
        require(
            adminContract == msg.sender,
            "Only the contract admin owner can call this function"
        );
        _;
    }

    modifier onlyExternal() {
        require(externalContract == msg.sender, "contract invalid: Vault One");
        _;
    }

    function initialize(IERC20 _contractErc20) public initializer {
        adminContract = msg.sender;
        contractErc20 = _contractErc20;
    }

    function withdraw(address _to, uint256 _amount) public onlyExternal {
        contractErc20.transfer(_to, _amount);
    }

    function setExternalContract(address _contract) external onlyAdminOwner {
        externalContract = _contract;
    }

    function version() public pure returns (string memory) {
        return "vault version two";
    }
}
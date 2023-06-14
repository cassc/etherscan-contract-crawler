// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Confirmer.sol";

contract HYCOPayment is Ownable, Confirmer {

    event Airdrop(address indexed account, uint256 amount);
    event Mining(address indexed account, uint256 amount, string source);

    IERC20 private immutable _erc20;
    
    /**
     * @dev Set the ERC20 token address.
     */
    constructor(
        address erc20Address,
        address confirmer1, 
        address confirmer2
    ) {
        _erc20 = IERC20(erc20Address);

        _confirmers.push(msg.sender);
        _confirmers.push(confirmer1);
        _confirmers.push(confirmer2);
        _resetConfirmed();
    }

    function hycoAirdrop(uint256 amount, address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            hycoTransfer(amount, addresses[i]);
            emit Airdrop(addresses[i], amount);
        }
    }

    function hycoAirdropFrom(address fromAddress, uint256 amount, address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            hycoTransferFrom(amount, fromAddress, addresses[i]);
            emit Airdrop(addresses[i], amount);
        }
    }

    function hycoMining(uint256 amount, address[] memory addresses, string memory source) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            hycoTransfer(amount, addresses[i]);
            emit Mining(addresses[i], amount, source);
        }
    }

    function hycoMiningFrom(address fromAddress, uint256 amount, address[] memory addresses, string memory source) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            hycoTransferFrom(amount, fromAddress, addresses[i]);
            emit Mining(addresses[i], amount, source);
        }
    }

    function hycoTransfer(uint256 amount, address walletAddress) public onlyOwner {
        SafeERC20.safeTransfer(_erc20, walletAddress, amount);
    }

    function hycoTransferFrom(uint256 amount, address fromAddress, address walletAddress) public onlyOwner {
        SafeERC20.safeTransferFrom(_erc20, fromAddress, walletAddress, amount);
    }    

    function transferOwnership(address newOwner) public isConfirmer(msg.sender) isConfirmed override
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        super._transferOwnership(newOwner);
        _resetConfirmed();
    }

    function renounceOwnership() public onlyOwner isConfirmed override
    {
        super.renounceOwnership();
        _resetConfirmed();
    }

}